# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - PYTHON DB SEED INITIALIZER
# ==============================================================================
# Section Purpose: Seeds SQLite/MySQL database on startup with default roles,
# demo accounts (worker01, supervisor01, admin01), Tufting machines, orders,
# and initial reference entry DFT-797 matching the ERP screenshot.
# ==============================================================================

from sqlalchemy.orm import Session
from datetime import datetime, date

from app.models.domain import (
    Role, User, Process, Machine, Shift, Customer, Order, Product,
    ProductionEntry, ProductionDetail, AuditLog, EntryStatus, ERPSyncStatus,
    Permission, RolePermission
)
from app.core.security import get_password_hash


def init_db_seed(db: Session):
    """
    Section Purpose: Checks if database tables are populated, and seeds baseline data if empty.
    """
    # Check if permissions exist
    if db.query(Permission).count() == 0:
        permissions_data = [
            ("view_production", "View Production Entries", "Access production entries list & details", "PRODUCTION"),
            ("create_production_entry", "Create Production Entry", "Create shop-floor production records", "PRODUCTION"),
            ("edit_own_entry", "Edit Own Entries", "Edit own draft/rejected entries", "PRODUCTION"),
            ("supervisor_review", "Supervisor Review Queue", "Access supervisor review workspace", "SUPERVISOR"),
            ("supervisor_edit", "Supervisor Record Edit", "Edit worker submitted entries with audit log", "SUPERVISOR"),
            ("supervisor_approve", "Approve Production Records", "Approve & confirm production entries", "SUPERVISOR"),
            ("supervisor_reject", "Reject Production Records", "Reject entries back to worker", "SUPERVISOR"),
            ("view_summary", "View Production Summary", "Access read-only aggregate summary reports", "SUMMARY"),
            ("excel_export", "Excel Data Export", "Export operational records to Excel (.xlsx)", "EXCEL"),
            ("excel_import", "Excel Data Import", "Import operational records from Excel (.xlsx)", "EXCEL"),
            ("admin_user_mgmt", "User Management", "Create, edit, block, and manage user accounts", "ADMIN"),
            ("admin_role_mgmt", "Role & Permission Mgmt", "Create and configure custom roles & permissions", "ADMIN"),
            ("admin_activity_view", "System Activity Audit", "View full operational & system activity audit logs", "ADMIN"),
        ]
        perms_dict = {}
        for code, name, desc, cat in permissions_data:
            p = Permission(code=code, name=name, description=desc, category=cat)
            db.add(p)
            db.flush()
            perms_dict[code] = p

        # Query baseline roles if existing or create them
        r_worker = db.query(Role).filter(Role.role_name == "WORKER").first()
        if not r_worker:
            r_worker = Role(role_id=1, role_name="WORKER", description="Shop-floor worker entering production details")
            db.add(r_worker)
        r_supervisor = db.query(Role).filter(Role.role_name == "SUPERVISOR").first()
        if not r_supervisor:
            r_supervisor = Role(role_id=2, role_name="SUPERVISOR", description="Supervisor confirming and reviewing entries")
            db.add(r_supervisor)
        r_admin = db.query(Role).filter(Role.role_name == "ADMIN").first()
        if not r_admin:
            r_admin = Role(role_id=3, role_name="ADMIN", description="Super administrator with full edit & user management power")
            db.add(r_admin)
        db.flush()

        # Map Worker permissions
        worker_codes = ["view_production", "create_production_entry", "edit_own_entry", "view_summary"]
        for c in worker_codes:
            if c in perms_dict:
                db.add(RolePermission(role_id=r_worker.role_id, permission_id=perms_dict[c].permission_id))

        # Map Supervisor permissions
        supervisor_codes = ["view_production", "create_production_entry", "edit_own_entry", "supervisor_review", "supervisor_edit", "supervisor_approve", "supervisor_reject", "view_summary", "excel_export", "excel_import"]
        for c in supervisor_codes:
            if c in perms_dict:
                db.add(RolePermission(role_id=r_supervisor.role_id, permission_id=perms_dict[c].permission_id))

        # Map Admin permissions (All)
        for p in perms_dict.values():
            db.add(RolePermission(role_id=r_admin.role_id, permission_id=p.permission_id))

        db.commit()

    # Check if users exist
    if db.query(User).count() > 0:
        return

    # 1. Roles
    r_worker = db.query(Role).filter(Role.role_name == "WORKER").first()
    if not r_worker:
        r_worker = Role(role_id=1, role_name="WORKER", description="Shop-floor worker entering production details")
        db.add(r_worker)

    r_supervisor = db.query(Role).filter(Role.role_name == "SUPERVISOR").first()
    if not r_supervisor:
        r_supervisor = Role(role_id=2, role_name="SUPERVISOR", description="Supervisor confirming and reviewing entries")
        db.add(r_supervisor)

    r_admin = db.query(Role).filter(Role.role_name == "ADMIN").first()
    if not r_admin:
        r_admin = Role(role_id=3, role_name="ADMIN", description="Super administrator with full edit & user management power")
        db.add(r_admin)

    db.commit()

    # 2. Users (Password: Demo@123)
    pwd_hash = get_password_hash("Demo@123")
    u_worker = User(user_id=1, username="worker01", email="worker01@cocotuft.com", hashed_password=pwd_hash, full_name="Rajesh Kumar (Worker)", role_id=r_worker.role_id, is_active=True, is_blocked=False)
    u_supervisor = User(user_id=2, username="supervisor01", email="supervisor01@cocotuft.com", hashed_password=pwd_hash, full_name="Thomas Joseph (Supervisor)", role_id=r_supervisor.role_id, is_active=True, is_blocked=False)
    u_admin = User(user_id=3, username="admin01", email="admin01@cocotuft.com", hashed_password=pwd_hash, full_name="System Administrator (Super User)", role_id=r_admin.role_id, is_active=True, is_blocked=False)
    db.add_all([u_worker, u_supervisor, u_admin])
    db.commit()

    # 3. Processes (TUFTING)
    p_tufting = Process(process_id=1, process_code="DFT", process_name="TUFTING", description="Daily Tufting details recording process")
    db.add(p_tufting)
    db.commit()

    # 4. Machines (Tufting Machines 1, 2, 3)
    m1 = Machine(machine_id=1, process_id=1, machine_code="TFT-M01", machine_name="Tufting Machine - 1")
    m2 = Machine(machine_id=2, process_id=1, machine_code="TFT-M02", machine_name="Tufting Machine - 2")
    m3 = Machine(machine_id=3, process_id=1, machine_code="TFT-M03", machine_name="Tufting Machine - 3")
    db.add_all([m1, m2, m3])
    db.commit()

    # 5. Shifts
    s1 = Shift(shift_id=1, shift_name="Shift 1", start_time="06:00:00", end_time="14:00:00")
    s2 = Shift(shift_id=2, shift_name="Shift 2", start_time="14:00:00", end_time="22:00:00")
    s3 = Shift(shift_id=3, shift_name="Shift 3", start_time="22:00:00", end_time="06:00:00")
    db.add_all([s1, s2, s3])
    db.commit()

    # 6. Customers & Orders (TESCO - PCT-298)
    c1 = Customer(customer_id=1, customer_code="TESCO", customer_name="TESCO Stores International", country="United Kingdom")
    c2 = Customer(customer_id=2, customer_code="IKEA", customer_name="IKEA Global Sourcing", country="Sweden")
    db.add_all([c1, c2])
    db.commit()

    o1 = Order(order_id=1, order_number="PCT-298", po_number="PRDOT-446", customer_id=1, base_material="Natural", pile_height="15 MM", target_quantity=500.0)
    o2 = Order(order_id=2, order_number="PCT-305", po_number="PO-IKEA-9842", customer_id=2, base_material="PVC", pile_height="12 MM", target_quantity=300.0)
    db.add_all([o1, o2])
    db.commit()

    # 7. Products
    prd1 = Product(product_id=1, product_code="PRDOT-446", product_name="PVC TUFTED NATURAL PLAIN MATTING", description="TESCO 2.18 X 50 M X 15 MM Matting")
    db.add(prd1)
    db.commit()

    # 8. Reference Production Entry (DFT-797 Matching ERP Screenshot)
    entry = ProductionEntry(
        entry_id=1,
        entry_number="DFT-797",
        entry_date=date(2026, 8, 5),
        tufted_date=date(2026, 8, 5),
        shift_id=1,
        process_id=1,
        machine_id=3,
        order_id=1,
        customer_id=1,
        product_id=1,
        worker_id=1,
        status=EntryStatus.APPROVED,
        erp_sync_status=ERPSyncStatus.ERP_SYNCED,
        erp_reference_no="ERP-REF-20260805-0001",
        approved_by_user_id=2,
        approved_at=datetime(2026, 8, 5, 8, 35, 0)
    )
    db.add(entry)
    db.flush()

    detail = ProductionDetail(
        entry_id=entry.entry_id,
        base="Natural",
        pile_height="15 MM",
        sales_order_no="PCT-298",
        customer_code="TESCO",
        po_number="PRDOT-446",
        roll_number="TF-3/1113/N15/05-08-2026/F1",
        start_time="06:00 AM",
        end_time="07:20 AM",
        length_meters=13.50,
        width_meters=1.95,
        target_qty=500.00,
        actual_qty=26.33,
        variation=-473.67,
        balance_qty=473.67,
        belt_speed="Normal",
        defects_a_yarn=0,
        defects_b_pvc=0,
        defects_c_tufting=0,
        defects_d_stripe=0,
        defects_e_others=0,
        machine_stop_minutes=5,
        machine_stop_reason="Tension adjustment",
        round_weight_left=14.00,
        round_weight_center=14.50,
        round_weight_right=14.00,
        quality_remarks="Passed quality inspection",
        factory_labour_count=4,
        contract_labour_count=2,
        shift_machine_incharge="K. Ramesh",
        shift_quality_controller="P. Shaji",
        shift_supervisor_name="Thomas Joseph",
        tufting_head="Head A",
        creel_stand="Creel 03",
        total_running_meter=13.50,
        total_sqm=26.33,
        comments="Production completed cleanly"
    )
    db.add(detail)

    log1 = AuditLog(entry_id=1, changed_by_user_id=1, action="CREATED", field_name="Status", old_value=None, new_value="SUBMITTED")
    log2 = AuditLog(entry_id=1, changed_by_user_id=2, action="APPROVED", field_name="Status", old_value="PENDING_APPROVAL", new_value="APPROVED")
    db.add_all([log1, log2])

    db.commit()
