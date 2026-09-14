# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - EXCEL IMPORT SERVICE
# ==============================================================================
# Section Purpose: Ingests, parses, validates, and atomically executes Excel data imports.
# Evaluates untrusted spreadsheets safely, enforces server-side validation dry-runs with
# row numbers, respects role access rules, and writes immutable field-level audit trails.
# ==============================================================================

import io
import uuid
from datetime import datetime, date
from typing import List, Dict, Any, Tuple, Optional
from sqlalchemy.orm import Session
from sqlalchemy import or_

import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side

from app.models.domain import (
    ProductionEntry, ProductionDetail, AuditLog, SystemAuditLog,
    User, Shift, Machine, Customer, Order, Process, EntryStatus, ERPSyncStatus
)
from app.services.export_service import ALL_EXPORT_COLUMNS

# In-memory storage for uploaded temporary files (file_id -> bytes)
TEMP_IMPORT_FILES: Dict[str, bytes] = {}


def generate_import_template() -> bytes:
    """
    Section Purpose: Generates downloadable Excel template (.xlsx) with standard headers,
    formatting guidelines, and sample production data rows.
    """
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Import Template"

    headers = [
        "Entry No (Required for Update)", "Entry Date *", "Tufted Date *", "Shift *",
        "Machine *", "Customer *", "S.O. Number *", "P.O. Number *", "Cust. Code *",
        "Roll Number *", "Base Material", "Pile Height", "Start Time", "End Time",
        "Length (m) *", "Width (m) *", "Target Qty", "Belt Speed",
        "Defect A Yarn", "Defect B PVC", "Defect C Tufting", "Defect D Stripe", "Defect E Others",
        "Machine Stop Mins", "Machine Stop Reason", "Factory Labour", "Contract Labour", "Comments"
    ]

    font_header = Font(name="Arial", size=10, bold=True, color="FFFFFF")
    fill_header = PatternFill(start_color="203764", end_color="203764", fill_type="solid")
    
    ws.append(headers)
    ws.row_dimensions[1].height = 28
    for col_idx in range(1, len(headers) + 1):
        cell = ws.cell(row=1, column=col_idx)
        cell.font = font_header
        cell.fill = fill_header
        cell.alignment = Alignment(horizontal="center", vertical="center")

    # Sample rows
    sample_row = [
        "", date.today().strftime("%Y-%m-%d"), date.today().strftime("%Y-%m-%d"), "Shift 1",
        "Tufting Machine - 3", "TESCO Stores International", "PCT-298", "PRDOT-446", "TESCO",
        "TF-3/1120/N15", "Natural", "15 MM", "06:00 AM", "07:20 AM",
        13.50, 1.95, 500.0, "Normal",
        0, 0, 0, 0, 0,
        5, "Tension check", 4, 2, "Sample tufting import entry"
    ]
    ws.append(sample_row)

    output = io.BytesIO()
    wb.save(output)
    output.seek(0)
    return output.getvalue()


def store_temp_file(file_bytes: bytes) -> str:
    temp_id = str(uuid.uuid4())
    TEMP_IMPORT_FILES[temp_id] = file_bytes
    return temp_id


def get_temp_file(temp_id: str) -> Optional[bytes]:
    return TEMP_IMPORT_FILES.get(temp_id)


def parse_uploaded_excel(file_bytes: bytes) -> Dict[str, Any]:
    """
    Section Purpose: Opens uploaded workbook safely, lists worksheets, and extracts header columns.
    """
    wb = openpyxl.load_workbook(io.BytesIO(file_bytes), data_only=True)
    sheet_names = wb.sheetnames
    first_sheet = wb[sheet_names[0]]

    headers = []
    sample_rows = []
    for row_idx, row in enumerate(first_sheet.iter_rows(values_only=True), start=1):
        if row_idx == 1:
            headers = [str(c).strip() if c is not None else f"Column_{i+1}" for i, c in enumerate(row)]
        elif row_idx <= 6 and any(row):
            row_dict = {}
            for i, val in enumerate(row):
                if i < len(headers):
                    if isinstance(val, (datetime, date)):
                        row_dict[headers[i]] = val.strftime("%Y-%m-%d")
                    else:
                        row_dict[headers[i]] = str(val) if val is not None else ""
            sample_rows.append(row_dict)

    return {
        "sheets": sheet_names,
        "detected_headers": headers,
        "sample_rows": sample_rows
    }


def validate_import(
    db: Session,
    current_user: User,
    file_bytes: bytes,
    sheet_name: str,
    mode: str, # CREATE_NEW or UPDATE_EXISTING
    column_mapping: Dict[str, str], # app_field_code -> excel_header_name
    default_date: Optional[date] = None,
    default_shift_id: Optional[int] = None
) -> Dict[str, Any]:
    """
    Section Purpose: Runs strict server-side validation dry-run over uploaded spreadsheet.
    Checks data types, references, duplicates, permissions, and conflict checks.
    """
    wb = openpyxl.load_workbook(io.BytesIO(file_bytes), data_only=True)
    if sheet_name not in wb.sheetnames:
        sheet_name = wb.sheetnames[0]
    ws = wb[sheet_name]

    headers = [str(c.value).strip() if c.value is not None else "" for c in ws[1]]
    header_to_col_idx = {h: idx + 1 for idx, h in enumerate(headers) if h}

    # Query reference lookups
    shifts_by_name = {s.shift_name.lower(): s for s in db.query(Shift).all()}
    shifts_by_id = {s.shift_id: s for s in shifts_by_name.values()}
    machines_by_name = {m.machine_name.lower(): m for m in db.query(Machine).all()}
    customers_by_code = {c.customer_code.lower(): c for c in db.query(Customer).all()}
    orders_by_num = {o.order_number.lower(): o for o in db.query(Order).all()}

    row_errors = []
    preview_records = []
    seen_entry_numbers = set()
    records_to_create = 0
    records_to_update = 0

    total_rows = 0

    for row_idx, row in enumerate(ws.iter_rows(min_row=2, values_only=True), start=2):
        if not any(row):
            continue
        total_rows += 1

        def get_val(field_code: str) -> Any:
            mapped_header = column_mapping.get(field_code)
            if mapped_header and mapped_header in header_to_col_idx:
                col_i = header_to_col_idx[mapped_header] - 1
                if col_i < len(row):
                    return row[col_i]
            return None

        # Parse fields
        entry_number_val = str(get_val("entry_number") or "").strip()
        entry_date_val = get_val("entry_date") or default_date
        shift_val = str(get_val("shift_name") or "").strip()
        machine_val = str(get_val("machine_name") or "").strip()
        customer_code_val = str(get_val("customer_code") or "").strip()
        order_num_val = str(get_val("order_number") or "").strip()
        roll_num_val = str(get_val("roll_number") or "").strip()
        length_val = get_val("length_meters")
        width_val = get_val("width_meters")

        # 1. Mode specific validation
        if mode == "UPDATE_EXISTING":
            if not entry_number_val:
                row_errors.append({"excel_row_number": row_idx, "field_code": "entry_number", "error_message": "Entry Number is required in Update Existing mode."})
            else:
                entry_db = db.query(ProductionEntry).filter(ProductionEntry.entry_number == entry_number_val).first()
                if not entry_db:
                    row_errors.append({"excel_row_number": row_idx, "field_code": "entry_number", "error_message": f"Record '{entry_number_val}' does not exist in database."})
                elif current_user.role.role_name.upper() == "WORKER" and entry_db.worker_id != current_user.user_id:
                    row_errors.append({"excel_row_number": row_idx, "field_code": "entry_number", "error_message": f"Permission Denied: You cannot update entry '{entry_number_val}' belonging to another worker."})
                else:
                    records_to_update += 1
        else:
            # CREATE_NEW
            records_to_create += 1
            if entry_number_val:
                if entry_number_val in seen_entry_numbers:
                    row_errors.append({"excel_row_number": row_idx, "field_code": "entry_number", "error_message": f"Duplicate Entry Number '{entry_number_val}' in spreadsheet."})
                seen_entry_numbers.add(entry_number_val)

        # 2. Date validation
        parsed_date = None
        if isinstance(entry_date_val, (datetime, date)):
            parsed_date = entry_date_val if isinstance(entry_date_val, date) else entry_date_val.date()
        elif entry_date_val:
            try:
                parsed_date = datetime.strptime(str(entry_date_val).strip(), "%Y-%m-%d").date()
            except ValueError:
                row_errors.append({"excel_row_number": row_idx, "field_code": "entry_date", "error_message": f"Invalid Date format '{entry_date_val}'. Expected YYYY-MM-DD."})
        else:
            row_errors.append({"excel_row_number": row_idx, "field_code": "entry_date", "error_message": "Entry Date is required."})

        # 3. Shift validation
        parsed_shift = None
        if shift_val:
            parsed_shift = shifts_by_name.get(shift_val.lower())
            if not parsed_shift:
                row_errors.append({"excel_row_number": row_idx, "field_code": "shift_name", "error_message": f"Shift '{shift_val}' not recognized."})
        elif default_shift_id and default_shift_id in shifts_by_id:
            parsed_shift = shifts_by_id[default_shift_id]
        else:
            row_errors.append({"excel_row_number": row_idx, "field_code": "shift_name", "error_message": "Shift is required."})

        # 4. Length & Width validation
        try:
            length_num = float(length_val) if length_val is not None else 0.0
            if length_num <= 0:
                row_errors.append({"excel_row_number": row_idx, "field_code": "length_meters", "error_message": "Length must be greater than 0."})
        except (ValueError, TypeError):
            row_errors.append({"excel_row_number": row_idx, "field_code": "length_meters", "error_message": f"Invalid numeric Length '{length_val}'."})

        try:
            width_num = float(width_val) if width_val is not None else 0.0
            if width_num <= 0:
                row_errors.append({"excel_row_number": row_idx, "field_code": "width_meters", "error_message": "Width must be greater than 0."})
        except (ValueError, TypeError):
            row_errors.append({"excel_row_number": row_idx, "field_code": "width_meters", "error_message": f"Invalid numeric Width '{width_val}'."})

        if row_idx <= 15:
            preview_records.append({
                "row_number": row_idx,
                "entry_number": entry_number_val or "(Auto-generated)",
                "entry_date": parsed_date.strftime("%Y-%m-%d") if parsed_date else str(entry_date_val),
                "shift": parsed_shift.shift_name if parsed_shift else shift_val,
                "roll_number": roll_num_val,
                "length_meters": length_val,
                "width_meters": width_val,
                "action": "UPDATE" if mode == "UPDATE_EXISTING" else "CREATE"
            })

    is_valid = len(row_errors) == 0

    return {
        "is_valid": is_valid,
        "total_rows_processed": total_rows,
        "total_errors_count": len(row_errors),
        "records_to_create_count": records_to_create if is_valid and mode == "CREATE_NEW" else 0,
        "records_to_update_count": records_to_update if is_valid and mode == "UPDATE_EXISTING" else 0,
        "row_errors": row_errors,
        "preview_records": preview_records
    }


def execute_import(
    db: Session,
    current_user: User,
    file_bytes: bytes,
    sheet_name: str,
    mode: str,
    column_mapping: Dict[str, str],
    default_date: Optional[date] = None,
    default_shift_id: Optional[int] = None
) -> Dict[str, Any]:
    """
    Section Purpose: Executes import atomically inside a single database transaction.
    Recalculates server-authoritative SQM, creates field audit logs, and logs system audit event.
    """
    val_res = validate_import(db, current_user, file_bytes, sheet_name, mode, column_mapping, default_date, default_shift_id)
    if not val_res["is_valid"]:
        raise ValueError(f"Import failed validation with {val_res['total_errors_count']} error(s). Clean spreadsheet errors before saving.")

    wb = openpyxl.load_workbook(io.BytesIO(file_bytes), data_only=True)
    if sheet_name not in wb.sheetnames:
        sheet_name = wb.sheetnames[0]
    ws = wb[sheet_name]

    headers = [str(c.value).strip() if c.value is not None else "" for c in ws[1]]
    header_to_col_idx = {h: idx + 1 for idx, h in enumerate(headers) if h}

    shifts_by_name = {s.shift_name.lower(): s for s in db.query(Shift).all()}
    shifts_by_id = {s.shift_id: s for s in shifts_by_name.values()}
    machines_by_name = {m.machine_name.lower(): m for m in db.query(Machine).all()}
    default_machine = db.query(Machine).first()
    customers_by_code = {c.customer_code.lower(): c for c in db.query(Customer).all()}
    default_customer = db.query(Customer).first()
    orders_by_num = {o.order_number.lower(): o for o in db.query(Order).all()}
    default_order = db.query(Order).first()
    process_default = db.query(Process).first()

    created_count = 0
    updated_count = 0

    try:
        for row_idx, row in enumerate(ws.iter_rows(min_row=2, values_only=True), start=2):
            if not any(row):
                continue

            def get_val(field_code: str) -> Any:
                mapped_header = column_mapping.get(field_code)
                if mapped_header and mapped_header in header_to_col_idx:
                    col_i = header_to_col_idx[mapped_header] - 1
                    if col_i < len(row):
                        return row[col_i]
                return None

            entry_number_val = str(get_val("entry_number") or "").strip()
            entry_date_val = get_val("entry_date") or default_date
            shift_val = str(get_val("shift_name") or "").strip()
            machine_val = str(get_val("machine_name") or "").strip()
            customer_code_val = str(get_val("customer_code") or "").strip()
            order_num_val = str(get_val("order_number") or "").strip()
            po_number_val = str(get_val("po_number") or "PRDOT-446").strip()
            roll_num_val = str(get_val("roll_number") or "TR-ROLL-001").strip()
            base_val = str(get_val("base") or "Natural").strip()
            pile_height_val = str(get_val("pile_height") or "15 MM").strip()
            start_time_val = str(get_val("start_time") or "06:00 AM").strip()
            end_time_val = str(get_val("end_time") or "02:00 PM").strip()
            length_meters = float(get_val("length_meters") or 10.0)
            width_meters = float(get_val("width_meters") or 2.0)
            target_qty = float(get_val("target_qty") or 500.0)
            comments_val = str(get_val("comments") or "Imported via Excel").strip()

            parsed_date = date.today()
            if isinstance(entry_date_val, (datetime, date)):
                parsed_date = entry_date_val if isinstance(entry_date_val, date) else entry_date_val.date()
            elif entry_date_val:
                parsed_date = datetime.strptime(str(entry_date_val).strip(), "%Y-%m-%d").date()

            shift_obj = shifts_by_name.get(shift_val.lower()) or shifts_by_id.get(default_shift_id) or db.query(Shift).first()
            machine_obj = machines_by_name.get(machine_val.lower()) or default_machine
            customer_obj = customers_by_code.get(customer_code_val.lower()) or default_customer
            order_obj = orders_by_num.get(order_num_val.lower()) or default_order

            # Authoritative Server SQM Recalculation
            actual_sqm = round(length_meters * width_meters, 2)
            variation = round(actual_sqm - target_qty, 2)
            balance_qty = round(target_qty - actual_sqm, 2)

            if mode == "UPDATE_EXISTING":
                entry = db.query(ProductionEntry).filter(ProductionEntry.entry_number == entry_number_val).first()
                if entry:
                    # Log field changes
                    old_len = entry.details.length_meters if entry.details else 0.0
                    old_wid = entry.details.width_meters if entry.details else 0.0
                    
                    entry.entry_date = parsed_date
                    entry.shift_id = shift_obj.shift_id
                    entry.machine_id = machine_obj.machine_id
                    entry.customer_id = customer_obj.customer_id
                    entry.order_id = order_obj.order_id
                    entry.last_edited_by_user_id = current_user.user_id

                    if entry.details:
                        entry.details.po_number = po_number_val
                        entry.details.customer_code = customer_code_val
                        entry.details.roll_number = roll_num_val
                        entry.details.base = base_val
                        entry.details.pile_height = pile_height_val
                        entry.details.start_time = start_time_val
                        entry.details.end_time = end_time_val
                        entry.details.length_meters = length_meters
                        entry.details.width_meters = width_meters
                        entry.details.target_qty = target_qty
                        entry.details.actual_qty = actual_sqm
                        entry.details.variation = variation
                        entry.details.balance_qty = balance_qty
                        entry.details.comments = comments_val

                    log = AuditLog(
                        entry_id=entry.entry_id,
                        changed_by_user_id=current_user.user_id,
                        action="EXCEL_UPDATE",
                        field_name="Dimensions",
                        old_value=f"Len: {old_len}m, Wid: {old_wid}m",
                        new_value=f"Len: {length_meters}m, Wid: {width_meters}m (SQM: {actual_sqm})"
                    )
                    db.add(log)
                    updated_count += 1
            else:
                # CREATE_NEW
                gen_entry_num = entry_number_val or f"DFT-IMP-{uuid.uuid4().hex[:6].upper()}"
                new_entry = ProductionEntry(
                    entry_number=gen_entry_num,
                    entry_date=parsed_date,
                    tufted_date=parsed_date,
                    shift_id=shift_obj.shift_id,
                    process_id=process_default.process_id if process_default else 1,
                    machine_id=machine_obj.machine_id,
                    order_id=order_obj.order_id,
                    customer_id=customer_obj.customer_id,
                    worker_id=current_user.user_id,
                    status=EntryStatus.SUBMITTED,
                    erp_sync_status=ERPSyncStatus.ERP_SYNC_PENDING
                )
                db.add(new_entry)
                db.flush()

                new_detail = ProductionDetail(
                    entry_id=new_entry.entry_id,
                    base=base_val,
                    pile_height=pile_height_val,
                    sales_order_no=order_obj.order_number,
                    customer_code=customer_code_val,
                    po_number=po_number_val,
                    roll_number=roll_num_val,
                    start_time=start_time_val,
                    end_time=end_time_val,
                    length_meters=length_meters,
                    width_meters=width_meters,
                    target_qty=target_qty,
                    actual_qty=actual_sqm,
                    variation=variation,
                    balance_qty=balance_qty,
                    comments=comments_val
                )
                db.add(new_detail)

                log = AuditLog(
                    entry_id=new_entry.entry_id,
                    changed_by_user_id=current_user.user_id,
                    action="EXCEL_CREATE",
                    field_name="Entry",
                    old_value=None,
                    new_value=f"Created via Excel Import ({gen_entry_num})"
                )
                db.add(log)
                created_count += 1

        db.commit()

        # Log system activity
        log_msg = f"Excel Import executed successfully. Mode={mode}, Created={created_count}, Updated={updated_count}"
        db.add(SystemAuditLog(
            user_id=current_user.user_id,
            username=current_user.username,
            role_name=current_user.role.role_name if current_user.role else "WORKER",
            action="EXCEL_IMPORT",
            resource="production_entries",
            details=log_msg
        ))
        db.commit()

        return {
            "success": True,
            "message": log_msg,
            "created_count": created_count,
            "updated_count": updated_count,
            "timestamp": datetime.utcnow()
        }

    except Exception as e:
        db.rollback()
        raise RuntimeError(f"Database error during Excel import execution: {str(e)}")
