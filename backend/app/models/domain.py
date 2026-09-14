# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - DOMAIN ORM MODELS
# ==============================================================================
# Section Purpose: Defines SQLAlchemy ORM database models representing tables,
# Tufting production fields, user accounts, and Admin control flags (is_blocked).
# ==============================================================================

from datetime import datetime, date
from sqlalchemy import (
    Column, Integer, String, Float, Boolean, DateTime, Date, Text, ForeignKey, Enum as SQLEnum
)
from sqlalchemy.orm import relationship
import enum

from app.database.session import Base


class EntryStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    SUBMITTED = "SUBMITTED"
    PENDING_APPROVAL = "PENDING_APPROVAL"
    REJECTED = "REJECTED"
    APPROVED = "APPROVED"


class ERPSyncStatus(str, enum.Enum):
    ERP_SYNC_PENDING = "ERP_SYNC_PENDING"
    ERP_SYNCED = "ERP_SYNCED"
    ERP_SYNC_FAILED = "ERP_SYNC_FAILED"


class Permission(Base):
    __tablename__ = "permissions"

    permission_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    code = Column(String(100), unique=True, nullable=False, index=True)
    name = Column(String(150), nullable=False)
    description = Column(String(255), nullable=True)
    category = Column(String(50), nullable=False, default="GENERAL")


class RolePermission(Base):
    __tablename__ = "role_permissions"

    role_id = Column(Integer, ForeignKey("roles.role_id"), primary_key=True)
    permission_id = Column(Integer, ForeignKey("permissions.permission_id"), primary_key=True)


class Role(Base):
    __tablename__ = "roles"

    role_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    role_name = Column(String(50), unique=True, nullable=False)
    description = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    users = relationship("User", back_populates="role")
    permissions = relationship("Permission", secondary="role_permissions")


class User(Base):
    __tablename__ = "users"

    user_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    username = Column(String(50), unique=True, nullable=False, index=True)
    email = Column(String(100), unique=True, nullable=True)
    hashed_password = Column(String(255), nullable=False)
    full_name = Column(String(100), nullable=False)
    role_id = Column(Integer, ForeignKey("roles.role_id"), nullable=False)
    is_active = Column(Boolean, default=True)
    is_blocked = Column(Boolean, default=False) # Admin user block/unblock flag
    is_deleted = Column(Boolean, default=False) # Soft deletion flag
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    role = relationship("Role", back_populates="users")
    production_entries = relationship("ProductionEntry", foreign_keys="ProductionEntry.worker_id", back_populates="worker")


class SystemAuditLog(Base):
    __tablename__ = "system_audit_logs"

    log_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    username = Column(String(50), nullable=False)
    role_name = Column(String(50), nullable=False)
    action = Column(String(100), nullable=False) # LOGIN, USER_CREATE, USER_EDIT, ROLE_UPDATE, EXCEL_EXPORT, EXCEL_IMPORT, etc.
    resource = Column(String(100), nullable=True)
    details = Column(Text, nullable=True)
    ip_address = Column(String(45), nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow, index=True)

    user = relationship("User")


class Process(Base):
    __tablename__ = "processes"

    process_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    process_code = Column(String(20), unique=True, nullable=False)
    process_name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    machines = relationship("Machine", back_populates="process", cascade="all, delete-orphan")


class Machine(Base):
    __tablename__ = "machines"

    machine_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    process_id = Column(Integer, ForeignKey("processes.process_id"), nullable=False)
    machine_code = Column(String(30), unique=True, nullable=False)
    machine_name = Column(String(100), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    process = relationship("Process", back_populates="machines")


class Shift(Base):
    __tablename__ = "shifts"

    shift_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    shift_name = Column(String(50), unique=True, nullable=False)
    start_time = Column(String(20), nullable=False)
    end_time = Column(String(20), nullable=False)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class Customer(Base):
    __tablename__ = "customers"

    customer_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    customer_code = Column(String(30), unique=True, nullable=False)
    customer_name = Column(String(150), nullable=False)
    country = Column(String(100), default="India")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class Order(Base):
    __tablename__ = "orders"

    order_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    order_number = Column(String(50), unique=True, nullable=False) # S.O.
    po_number = Column(String(50), nullable=True)                  # P.O.
    customer_id = Column(Integer, ForeignKey("customers.customer_id"), nullable=False)
    base_material = Column(String(100), default="Natural")
    pile_height = Column(String(50), default="15 MM")
    target_quantity = Column(Float, default=500.0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    customer = relationship("Customer")


class Product(Base):
    __tablename__ = "products"

    product_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    product_code = Column(String(30), unique=True, nullable=False)
    product_name = Column(String(150), nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class Material(Base):
    __tablename__ = "materials"

    material_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    material_code = Column(String(30), unique=True, nullable=False)
    material_name = Column(String(100), nullable=False)
    unit_of_measure = Column(String(20), default="KG")
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)


class ProductionEntry(Base):
    __tablename__ = "production_entries"

    entry_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    entry_number = Column(String(30), unique=True, nullable=False, index=True) # e.g. DFT-797
    entry_date = Column(Date, nullable=False, index=True)
    tufted_date = Column(Date, nullable=False, default=date.today)
    shift_id = Column(Integer, ForeignKey("shifts.shift_id"), nullable=False)
    process_id = Column(Integer, ForeignKey("processes.process_id"), nullable=False)
    machine_id = Column(Integer, ForeignKey("machines.machine_id"), nullable=False, index=True)
    order_id = Column(Integer, ForeignKey("orders.order_id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("customers.customer_id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.product_id"), nullable=True)
    worker_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)

    status = Column(SQLEnum(EntryStatus), default=EntryStatus.DRAFT, nullable=False, index=True)
    erp_sync_status = Column(SQLEnum(ERPSyncStatus), default=ERPSyncStatus.ERP_SYNC_PENDING, nullable=False)
    erp_reference_no = Column(String(100), nullable=True)
    erp_sync_message = Column(Text, nullable=True)
    erp_synced_at = Column(DateTime, nullable=True)

    rejection_reason = Column(Text, nullable=True)
    supervisor_remarks = Column(Text, nullable=True)
    approved_by_user_id = Column(Integer, ForeignKey("users.user_id"), nullable=True)
    approved_at = Column(DateTime, nullable=True)
    last_edited_by_user_id = Column(Integer, ForeignKey("users.user_id"), nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    shift = relationship("Shift")
    process = relationship("Process")
    machine = relationship("Machine")
    order = relationship("Order")
    customer = relationship("Customer")
    product = relationship("Product")
    worker = relationship("User", foreign_keys=[worker_id], back_populates="production_entries")
    approved_by = relationship("User", foreign_keys=[approved_by_user_id])
    last_edited_by = relationship("User", foreign_keys=[last_edited_by_user_id])
    details = relationship("ProductionDetail", back_populates="entry", uselist=False, cascade="all, delete-orphan")
    audit_logs = relationship("AuditLog", back_populates="entry", cascade="all, delete-orphan")


class ProductionDetail(Base):
    __tablename__ = "production_details"

    detail_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    entry_id = Column(Integer, ForeignKey("production_entries.entry_id"), unique=True, nullable=False)

    base = Column(String(100), default="Natural")
    pile_height = Column(String(50), default="15 MM")
    sales_order_no = Column(String(50), nullable=False) # S.O.
    customer_code = Column(String(50), nullable=False)  # Cust. Code
    po_number = Column(String(50), nullable=False)       # P.O.
    roll_number = Column(String(100), nullable=False)

    start_time = Column(String(20), nullable=False)
    end_time = Column(String(20), nullable=False)
    length_meters = Column(Float, nullable=False)
    width_meters = Column(Float, nullable=False)

    target_qty = Column(Float, default=500.0)
    actual_qty = Column(Float, nullable=False)  # Actual SQM (Length x Width)
    variation = Column(Float, nullable=False)   # Actual - Target Qty
    balance_qty = Column(Float, nullable=False) # Target Qty - Actual
    belt_speed = Column(String(50), default="Normal")

    defects_a_yarn = Column(Integer, default=0)
    defects_b_pvc = Column(Integer, default=0)
    defects_c_tufting = Column(Integer, default=0)
    defects_d_stripe = Column(Integer, default=0)
    defects_e_others = Column(Integer, default=0)

    machine_stop_minutes = Column(Integer, default=0)
    machine_stop_reason = Column(String(255), nullable=True)

    round_weight_left = Column(Float, default=0.0)
    round_weight_center = Column(Float, default=0.0)
    round_weight_right = Column(Float, default=0.0)

    quality_remarks = Column(Text, nullable=True)
    factory_labour_count = Column(Integer, default=1)
    contract_labour_count = Column(Integer, default=0)

    shift_machine_incharge = Column(String(100), nullable=True)
    shift_quality_controller = Column(String(100), nullable=True)
    shift_supervisor_name = Column(String(100), nullable=True)
    tufting_head = Column(String(100), nullable=True)
    creel_stand = Column(String(100), nullable=True)

    total_running_meter = Column(Float, default=0.0)
    total_sqm = Column(Float, default=0.0)
    comments = Column(Text, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    entry = relationship("ProductionEntry", back_populates="details")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    log_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    entry_id = Column(Integer, ForeignKey("production_entries.entry_id"), nullable=False, index=True)
    changed_by_user_id = Column(Integer, ForeignKey("users.user_id"), nullable=False)
    action = Column(String(50), nullable=False)
    field_name = Column(String(100), nullable=True)
    old_value = Column(Text, nullable=True)
    new_value = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    entry = relationship("ProductionEntry", back_populates="audit_logs")
    changed_by = relationship("User")
