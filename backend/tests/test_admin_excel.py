# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - BACKEND E2E TEST SUITE
# ==============================================================================
# Section Purpose: Automated pytest suite testing Admin RBAC, Safety rules, Role &
# Permission management, System activity logging, Excel export, and Excel import.
# ==============================================================================

import pytest
import io
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.database.session import Base, get_db
from app.main import app
from app.seed import init_db_seed

# Use in-memory SQLite database for isolated test execution
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


app.dependency_overrides[get_db] = override_get_db
client = TestClient(app)


@pytest.fixture(autouse=True)
def setup_database():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    init_db_seed(db)
    db.close()
    yield
    Base.metadata.drop_all(bind=engine)


def get_auth_header(username: str = "admin01", password: str = "Demo@123"):
    response = client.post("/api/auth/login", json={"username": username, "password": password})
    assert response.status_code == 200
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_auth_login_returns_permissions():
    response = client.post("/api/auth/login", json={"username": "worker01", "password": "Demo@123"})
    assert response.status_code == 200
    data = response.json()
    assert "permissions" in data
    assert "create_production_entry" in data["permissions"]


def test_admin_user_crud_and_safety_protection():
    headers = get_auth_header("admin01")

    # 1. List Users
    res = client.get("/api/admin/users", headers=headers)
    assert res.status_code == 200
    users = res.json()
    assert len(users) >= 3

    # 2. Create User
    new_user_data = {
        "username": "newworker99",
        "password": "Password123",
        "full_name": "Test Worker 99",
        "email": "w99@cocotuft.com",
        "role_name": "WORKER"
    }
    res = client.post("/api/admin/users", json=new_user_data, headers=headers)
    assert res.status_code == 200
    created_id = res.json()["user_id"]

    # 3. Prevent Deactivating/Deleting Last Active Admin
    # Create a secondary admin account then test demotion/blocking on it
    second_admin = client.post("/api/admin/users", json={
        "username": "secondadmin",
        "password": "Password123",
        "full_name": "Second Admin",
        "role_name": "ADMIN"
    }, headers=headers).json()
    second_admin_id = second_admin["user_id"]

    # Block second admin so only 1 active admin remains
    client.put(f"/api/admin/users/{second_admin_id}/block", headers=headers)

    # Attempt to demote second_admin while blocked -> blocked by last active admin rule
    res_demote = client.put(f"/api/admin/users/{second_admin_id}", json={"role_name": "WORKER"}, headers=headers)
    assert res_demote.status_code == 400
    assert "last active Admin" in res_demote.json()["detail"]

    # Attempt to deactivate admin01 (user 3) -> blocked by last active admin rule
    res_deact = client.put("/api/admin/users/3", json={"is_active": False}, headers=headers)
    assert res_deact.status_code == 400
    assert "last active Admin" in res_deact.json()["detail"]

    # 4. Soft Delete user
    res_del = client.delete(f"/api/admin/users/{created_id}", headers=headers)
    assert res_del.status_code == 200


def test_roles_and_permissions_crud():
    headers = get_auth_header("admin01")

    # 1. List Permissions
    res_p = client.get("/api/admin/permissions", headers=headers)
    assert res_p.status_code == 200
    perms = res_p.json()
    assert len(perms) >= 10

    # 2. Create Custom Role
    role_payload = {
        "role_name": "QUALITY_INSPECTOR",
        "description": "Quality control team role",
        "permission_ids": [perms[0]["permission_id"], perms[1]["permission_id"]]
    }
    res_r = client.post("/api/admin/roles", json=role_payload, headers=headers)
    assert res_r.status_code == 200
    r_data = res_r.json()
    assert r_data["role_name"] == "QUALITY_INSPECTOR"


def test_excel_export_flow():
    headers = get_auth_header("supervisor01")

    # 1. Preview
    prev_payload = {"status": "ALL"}
    res_p = client.post("/api/excel/export/preview", json=prev_payload, headers=headers)
    assert res_p.status_code == 200
    assert res_p.json()["total_matching_count"] >= 1

    # 2. Download
    res_d = client.post("/api/excel/export/download", json=prev_payload, headers=headers)
    assert res_d.status_code == 200
    assert res_d.headers["content-type"] == "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    assert len(res_d.content) > 1000


def test_excel_import_flow():
    headers = get_auth_header("supervisor01")

    # 1. Download Template
    res_tmpl = client.get("/api/excel/import/template", headers=headers)
    assert res_tmpl.status_code == 200
    template_bytes = res_tmpl.content

    # 2. Upload Template
    files = {"file": ("test_template.xlsx", template_bytes, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")}
    res_up = client.post("/api/excel/import/upload", files=files, headers=headers)
    assert res_up.status_code == 200
    temp_id = res_up.json()["temp_file_id"]

    # 3. Validate Dry Run
    val_payload = {
        "temp_file_id": temp_id,
        "sheet_name": "Import Template",
        "mode": "CREATE_NEW",
        "column_mapping": {
            "entry_date": "Entry Date *",
            "tufted_date": "Tufted Date *",
            "shift_name": "Shift *",
            "machine_name": "Machine *",
            "customer_code": "Cust. Code *",
            "order_number": "S.O. Number *",
            "po_number": "P.O. Number *",
            "roll_number": "Roll Number *",
            "length_meters": "Length (m) *",
            "width_meters": "Width (m) *"
        }
    }
    res_val = client.post("/api/excel/import/validate", json=val_payload, headers=headers)
    assert res_val.status_code == 200
    assert res_val.json()["is_valid"] is True

    # 4. Execute Import
    res_exec = client.post("/api/excel/import/execute", json=val_payload, headers=headers)
    assert res_exec.status_code == 200
    assert res_exec.json()["created_count"] >= 1
