# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - EXCEL API CONTROLLER
# ==============================================================================
# Section Purpose: REST endpoints for Excel Export and Excel Import operations.
# Connects frontend requests to export/import services with security permissions checks.
# ==============================================================================

from typing import List, Optional
from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Response, status
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.models.domain import User
from app.core.security import PermissionChecker, log_system_activity
from app.schemas.schemas import (
    ExcelExportFilterParams, ExportPreviewResponse,
    ImportUploadResponse, ImportMappingRequest, ImportValidateResponse,
    ImportExecuteRequest, ImportResultOut
)
from app.services.export_service import (
    query_export_records, generate_excel_workbook, _extract_field_value, ALL_EXPORT_COLUMNS
)
from app.services import import_service

router = APIRouter(prefix="/excel", tags=["Excel Export & Import"])


# ------------------------------------------------------------------------------
# EXCEL EXPORT ENDPOINTS
# ------------------------------------------------------------------------------
@router.post("/export/preview", response_model=ExportPreviewResponse)
def preview_export(
    params: ExcelExportFilterParams,
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("excel_export"))
):
    """
    Section Purpose: Calculates matching record count and returns top 5 preview rows.
    """
    records = query_export_records(
        db, current_user,
        start_date=params.start_date,
        end_date=params.end_date,
        shift_ids=params.shift_ids,
        worker_ids=params.worker_ids,
        status=params.status or "ALL",
        machine_id=params.machine_id
    )

    cols = params.columns or list(ALL_EXPORT_COLUMNS.keys())
    preview_rows = []
    for entry in records[:5]:
        r_dict = {}
        for col_key in cols:
            if col_key in ALL_EXPORT_COLUMNS:
                header_title = ALL_EXPORT_COLUMNS[col_key][0]
                r_dict[header_title] = str(_extract_field_value(entry, col_key))
        preview_rows.append(r_dict)

    return ExportPreviewResponse(
        total_matching_count=len(records),
        preview_rows=preview_rows,
        columns_selected=cols
    )


@router.post("/export/download")
def download_export_excel(
    params: ExcelExportFilterParams,
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("excel_export"))
):
    """
    Section Purpose: Downloads generated .xlsx spreadsheet binary stream.
    """
    records = query_export_records(
        db, current_user,
        start_date=params.start_date,
        end_date=params.end_date,
        shift_ids=params.shift_ids,
        worker_ids=params.worker_ids,
        status=params.status or "ALL",
        machine_id=params.machine_id
    )

    filter_summary = {
        "start_date": params.start_date.strftime("%Y-%m-%d") if params.start_date else "All",
        "end_date": params.end_date.strftime("%Y-%m-%d") if params.end_date else "All",
        "shifts": f"{len(params.shift_ids)} selected" if params.shift_ids else "All",
        "status": params.status or "ALL"
    }

    excel_bytes = generate_excel_workbook(
        db, current_user, records,
        selected_columns=params.columns,
        filter_summary=filter_summary
    )

    log_system_activity(
        db, current_user.user_id, current_user.username, current_user.role.role_name if current_user.role else "WORKER",
        "EXCEL_EXPORT", "production_entries", f"Exported {len(records)} records to Excel"
    )

    filename = f"Cocotuft_Production_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.xlsx"
    return StreamingResponse(
        io.BytesIO(excel_bytes),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


# ------------------------------------------------------------------------------
# EXCEL IMPORT ENDPOINTS
# ------------------------------------------------------------------------------
import io

@router.get("/import/template")
def download_import_template(
    current_user: User = Depends(PermissionChecker("excel_import"))
):
    """
    Section Purpose: Downloads baseline Excel template (.xlsx) with standard fields & sample rows.
    """
    template_bytes = import_service.generate_import_template()
    filename = "Cocotuft_Production_Import_Template.xlsx"
    return StreamingResponse(
        io.BytesIO(template_bytes),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={filename}"}
    )


@router.post("/import/upload", response_model=ImportUploadResponse)
async def upload_import_excel(
    file: UploadFile = File(...),
    current_user: User = Depends(PermissionChecker("excel_import"))
):
    """
    Section Purpose: Step 1 of import wizard: uploads file, parses worksheets & column headers.
    """
    if not file.filename.endswith((".xlsx", ".xls")):
        raise HTTPException(status_code=400, detail="Only Excel files (.xlsx) are supported.")

    file_bytes = await file.read()
    temp_id = import_service.store_temp_file(file_bytes)
    parsed = import_service.parse_uploaded_excel(file_bytes)

    return ImportUploadResponse(
        temp_file_id=temp_id,
        sheets=parsed["sheets"],
        detected_headers=parsed["detected_headers"],
        sample_rows=parsed["sample_rows"]
    )


@router.post("/import/validate", response_model=ImportValidateResponse)
def validate_import_request(
    req: ImportMappingRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("excel_import"))
):
    """
    Section Purpose: Step 2 of import wizard: runs comprehensive validation dry-run.
    """
    file_bytes = import_service.get_temp_file(req.temp_file_id)
    if not file_bytes:
        raise HTTPException(status_code=404, detail="Uploaded temporary file expired or not found. Please upload again.")

    val_res = import_service.validate_import(
        db, current_user, file_bytes,
        sheet_name=req.sheet_name,
        mode=req.mode,
        column_mapping=req.column_mapping,
        default_date=req.default_date,
        default_shift_id=req.default_shift_id
    )

    return ImportValidateResponse(
        temp_file_id=req.temp_file_id,
        is_valid=val_res["is_valid"],
        total_rows_processed=val_res["total_rows_processed"],
        total_errors_count=val_res["total_errors_count"],
        records_to_create_count=val_res["records_to_create_count"],
        records_to_update_count=val_res["records_to_update_count"],
        row_errors=val_res["row_errors"],
        preview_records=val_res["preview_records"]
    )


@router.post("/import/execute", response_model=ImportResultOut)
def execute_import_request(
    req: ImportExecuteRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("excel_import"))
):
    """
    Section Purpose: Step 3 of import wizard: atomically commits verified records to database.
    """
    file_bytes = import_service.get_temp_file(req.temp_file_id)
    if not file_bytes:
        raise HTTPException(status_code=404, detail="Uploaded temporary file expired or not found. Please upload again.")

    try:
        res = import_service.execute_import(
            db, current_user, file_bytes,
            sheet_name=req.sheet_name,
            mode=req.mode,
            column_mapping=req.column_mapping,
            default_date=req.default_date,
            default_shift_id=req.default_shift_id
        )
        return ImportResultOut(
            success=True,
            message=res["message"],
            created_count=res["created_count"],
            updated_count=res["updated_count"],
            timestamp=res["timestamp"]
        )
    except ValueError as ve:
        raise HTTPException(status_code=400, detail=str(ve))
    except RuntimeError as re:
        raise HTTPException(status_code=500, detail=str(re))
