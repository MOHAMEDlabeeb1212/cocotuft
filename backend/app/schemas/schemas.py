# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - PYDANTIC SCHEMAS
# ==============================================================================
# Section Purpose: Pydantic DTO validation schemas for Daily Tufting details,
# Admin User Management (Create, Edit, Reset Password, Block/Unblock), and Tufting Summary.
# ==============================================================================

from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict
from app.models.domain import EntryStatus, ERPSyncStatus


# ------------------------------------------------------------------------------
# User & Admin Management Schemas
# ------------------------------------------------------------------------------
class LoginRequest(BaseModel):
    username: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    username: str
    full_name: str
    role_name: str
    permissions: List[str] = []


class SetupAdminRequest(BaseModel):
    username: str = Field(..., min_length=3)
    password: str = Field(..., min_length=4)
    full_name: str = Field(..., min_length=2)
    email: Optional[str] = None


class PermissionOut(BaseModel):
    permission_id: int
    code: str
    name: str
    description: Optional[str] = None
    category: str

    model_config = ConfigDict(from_attributes=True)


class RoleOut(BaseModel):
    role_id: int
    role_name: str
    description: Optional[str] = None
    created_at: Optional[datetime] = None
    user_count: int = 0
    permissions: List[PermissionOut] = []

    model_config = ConfigDict(from_attributes=True)


class RoleCreate(BaseModel):
    role_name: str = Field(..., min_length=2)
    description: Optional[str] = None
    permission_ids: List[int] = []


class RoleUpdate(BaseModel):
    role_name: Optional[str] = None
    description: Optional[str] = None
    permission_ids: Optional[List[int]] = None


class UserCreate(BaseModel):
    username: str = Field(..., min_length=3, description="Username for login")
    password: str = Field(..., min_length=4, description="User password")
    full_name: str = Field(..., min_length=2, description="User full name")
    email: Optional[str] = None
    role_name: str = Field(..., description="WORKER, SUPERVISOR, or ADMIN")


class UserUpdate(BaseModel):
    full_name: Optional[str] = None
    email: Optional[str] = None
    role_name: Optional[str] = None
    password: Optional[str] = None
    is_active: Optional[bool] = None
    is_blocked: Optional[bool] = None


class UserOut(BaseModel):
    user_id: int
    username: str
    email: Optional[str] = None
    full_name: str
    role_name: str
    is_active: bool
    is_blocked: bool
    is_deleted: bool = False
    permissions: List[str] = []
    created_at: Optional[datetime] = None

    model_config = ConfigDict(from_attributes=True)


class SystemAuditLogOut(BaseModel):
    log_id: int
    user_id: Optional[int] = None
    username: str
    role_name: str
    action: str
    resource: Optional[str] = None
    details: Optional[str] = None
    ip_address: Optional[str] = None
    timestamp: datetime

    model_config = ConfigDict(from_attributes=True)


# ------------------------------------------------------------------------------
# Master Data Schemas
# ------------------------------------------------------------------------------
class ProcessOut(BaseModel):
    process_id: int
    process_code: str
    process_name: str
    description: Optional[str] = None
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class MachineOut(BaseModel):
    machine_id: int
    process_id: int
    machine_code: str
    machine_name: str
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class ShiftOut(BaseModel):
    shift_id: int
    shift_name: str
    start_time: str
    end_time: str
    is_active: bool

    model_config = ConfigDict(from_attributes=True)


class CustomerOut(BaseModel):
    customer_id: int
    customer_code: str
    customer_name: str
    country: str

    model_config = ConfigDict(from_attributes=True)


class OrderOut(BaseModel):
    order_id: int
    order_number: str
    po_number: Optional[str] = None
    customer_id: int
    base_material: str
    pile_height: str
    target_quantity: float

    model_config = ConfigDict(from_attributes=True)


class ProductOut(BaseModel):
    product_id: int
    product_code: str
    product_name: str
    description: Optional[str] = None

    model_config = ConfigDict(from_attributes=True)


# ------------------------------------------------------------------------------
# Production Details Schemas (Daily Tufting Details)
# ------------------------------------------------------------------------------
class ProductionDetailCreate(BaseModel):
    base: str = Field("Natural", description="Base type: Natural, PVC, Latex")
    pile_height: str = Field("15 MM", description="Pile Height")
    sales_order_no: str = Field(..., description="S.O. Number e.g. PCT-298")
    customer_code: str = Field(..., description="Cust. Code e.g. TESCO")
    po_number: str = Field(..., description="P.O. Number e.g. PRDOT-446")
    roll_number: str = Field(..., description="Roll No.")

    start_time: str = Field("06:00 AM", description="Start Time")
    end_time: str = Field("07:20 AM", description="End Time")
    length_meters: float = Field(..., gt=0, description="Length (m)")
    width_meters: float = Field(..., gt=0, description="Width (m)")

    target_qty: float = Field(500.0, description="Target Qty")
    belt_speed: Optional[str] = "Normal"

    defects_a_yarn: int = Field(0, ge=0)
    defects_b_pvc: int = Field(0, ge=0)
    defects_c_tufting: int = Field(0, ge=0)
    defects_d_stripe: int = Field(0, ge=0)
    defects_e_others: int = Field(0, ge=0)

    machine_stop_minutes: int = Field(0, ge=0)
    machine_stop_reason: Optional[str] = None

    round_weight_left: float = Field(0.0, ge=0)
    round_weight_center: float = Field(0.0, ge=0)
    round_weight_right: float = Field(0.0, ge=0)

    quality_remarks: Optional[str] = None
    factory_labour_count: int = Field(1, ge=0)
    contract_labour_count: int = Field(0, ge=0)

    shift_machine_incharge: Optional[str] = None
    shift_quality_controller: Optional[str] = None
    shift_supervisor_name: Optional[str] = None
    tufting_head: Optional[str] = None
    creel_stand: Optional[str] = None
    comments: Optional[str] = None


class ProductionDetailOut(ProductionDetailCreate):
    detail_id: int
    entry_id: int
    actual_qty: float
    variation: float
    balance_qty: float
    total_running_meter: float
    total_sqm: float
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ProductionEntryCreate(BaseModel):
    entry_date: date
    tufted_date: date
    shift_id: int
    process_id: int
    machine_id: int
    order_id: int
    customer_id: int
    product_id: Optional[int] = None
    is_submit: bool = Field(False, description="True if submitting to supervisor")

    details: ProductionDetailCreate


class ProductionEntryUpdate(BaseModel):
    entry_date: Optional[date] = None
    tufted_date: Optional[date] = None
    shift_id: Optional[int] = None
    machine_id: Optional[int] = None
    order_id: Optional[int] = None
    customer_id: Optional[int] = None
    product_id: Optional[int] = None
    is_submit: Optional[bool] = None

    details: Optional[ProductionDetailCreate] = None
    supervisor_remarks: Optional[str] = None


class ApprovalRequest(BaseModel):
    supervisor_remarks: Optional[str] = None


class RejectionRequest(BaseModel):
    rejection_reason: str = Field(..., min_length=3)


class AuditLogOut(BaseModel):
    log_id: int
    entry_id: int
    changed_by_username: str
    changed_by_fullname: str
    action: str
    field_name: Optional[str] = None
    old_value: Optional[str] = None
    new_value: Optional[str] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class ProductionEntryOut(BaseModel):
    entry_id: int
    entry_number: str
    entry_date: date
    tufted_date: date
    shift_id: int
    shift_name: Optional[str] = None
    process_id: int
    process_name: Optional[str] = None
    machine_id: int
    machine_name: Optional[str] = None
    order_id: int
    order_number: Optional[str] = None
    customer_id: int
    customer_name: Optional[str] = None
    product_id: Optional[int] = None
    product_name: Optional[str] = None
    worker_id: int
    worker_name: Optional[str] = None

    status: EntryStatus
    erp_sync_status: ERPSyncStatus
    erp_reference_no: Optional[str] = None
    rejection_reason: Optional[str] = None
    supervisor_remarks: Optional[str] = None
    approved_by_name: Optional[str] = None
    approved_at: Optional[datetime] = None
    last_edited_by_name: Optional[str] = None

    created_at: datetime
    updated_at: datetime
    details: Optional[ProductionDetailOut] = None

    model_config = ConfigDict(from_attributes=True)


# ------------------------------------------------------------------------------
# Tufting Production Summary Report Schemas
# ------------------------------------------------------------------------------
class TuftingSummaryRow(BaseModel):
    sales_order_no: str
    machine_name: str
    pile_height: str
    width_meters: float
    length_meters: float
    target_qty: float
    actual_qty: float
    variation: float
    balance_qty: float
    running_meter: float


class ProductionSummaryOut(BaseModel):
    filter_date: Optional[date] = None
    filter_machine: Optional[str] = "All"
    filter_shift: Optional[str] = "All"
    filter_status: Optional[str] = "APPROVED"

    rows: List[TuftingSummaryRow]
    total_entries: int
    grand_total_target_qty: float
    grand_total_actual_qty: float
    grand_total_variation: float
    grand_total_balance_qty: float
    grand_total_running_meter: float


class WorkerDashboardOut(BaseModel):
    todays_entries_count: int
    pending_approval_count: int
    approved_today_count: int
    total_sqm_produced_today: float
    recent_entries: List[ProductionEntryOut]


class SupervisorDashboardOut(BaseModel):
    pending_approvals_count: int
    approved_today_count: int
    rejected_today_count: int
    todays_total_sqm: float
    pending_entries: List[ProductionEntryOut]


# ------------------------------------------------------------------------------
# Excel Export Schemas
# ------------------------------------------------------------------------------
class ExcelExportFilterParams(BaseModel):
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    shift_ids: Optional[List[int]] = None
    worker_ids: Optional[List[int]] = None
    status: Optional[str] = "ALL"
    machine_id: Optional[int] = None
    columns: Optional[List[str]] = None


class ExportPreviewResponse(BaseModel):
    total_matching_count: int
    preview_rows: List[dict]
    columns_selected: List[str]


# ------------------------------------------------------------------------------
# Excel Import Schemas
# ------------------------------------------------------------------------------
class ImportUploadResponse(BaseModel):
    temp_file_id: str
    sheets: List[str]
    detected_headers: List[str]
    sample_rows: List[dict]


class ImportMappingRequest(BaseModel):
    temp_file_id: str
    sheet_name: str
    mode: str = Field("CREATE_NEW", description="CREATE_NEW or UPDATE_EXISTING")
    column_mapping: dict = Field(..., description="Map app_field_code -> excel_header_name")
    default_date: Optional[date] = None
    default_shift_id: Optional[int] = None
    selected_row_indices: Optional[List[int]] = None


class ImportRowError(BaseModel):
    excel_row_number: int
    field_code: str
    error_message: str


class ImportValidateResponse(BaseModel):
    temp_file_id: str
    is_valid: bool
    total_rows_processed: int
    total_errors_count: int
    records_to_create_count: int
    records_to_update_count: int
    row_errors: List[ImportRowError]
    preview_records: List[dict]


class ImportExecuteRequest(BaseModel):
    temp_file_id: str
    sheet_name: str
    mode: str = "CREATE_NEW"
    column_mapping: dict
    default_date: Optional[date] = None
    default_shift_id: Optional[int] = None


class ImportResultOut(BaseModel):
    success: bool
    message: str
    created_count: int
    updated_count: int
    timestamp: datetime

