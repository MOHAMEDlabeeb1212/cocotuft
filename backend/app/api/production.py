# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - DAILY TUFTING PRODUCTION CONTROLLER
# ==============================================================================
# Section Purpose: Primary production API controller managing Daily Tufting records.
# Handles worker entries, supervisor confirmation, audit diff logging, and Admin
# super-user overrides (Admin can edit and update ANY record at any stage).
# ==============================================================================

from datetime import datetime, date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.models.domain import ProductionEntry, ProductionDetail, AuditLog, EntryStatus, User, Process
from app.schemas.schemas import (
    ProductionEntryCreate, ProductionEntryUpdate, ProductionEntryOut,
    ApprovalRequest, RejectionRequest, AuditLogOut
)
from app.core.security import get_current_user, RoleChecker
from app.services.calculation_service import CalculationService
from app.services.audit_service import AuditService
from app.services.erp_service import ERPIntegrationService

router = APIRouter(prefix="/production", tags=["Tufting Production Management"])


def _generate_tufting_entry_number(db: Session) -> str:
    """
    Generates sequential Tufting document numbers like DFT-797, DFT-798.
    """
    count = db.query(ProductionEntry).count()
    return f"DFT-{(count + 797):03d}"


def _format_entry_out(entry: ProductionEntry) -> ProductionEntryOut:
    return ProductionEntryOut(
        entry_id=entry.entry_id,
        entry_number=entry.entry_number,
        entry_date=entry.entry_date,
        tufted_date=entry.tufted_date,
        shift_id=entry.shift_id,
        shift_name=entry.shift.shift_name if entry.shift else None,
        process_id=entry.process_id,
        process_name=entry.process.process_name if entry.process else None,
        machine_id=entry.machine_id,
        machine_name=entry.machine.machine_name if entry.machine else None,
        order_id=entry.order_id,
        order_number=entry.order.order_number if entry.order else None,
        customer_id=entry.customer_id,
        customer_name=entry.customer.customer_name if entry.customer else None,
        product_id=entry.product_id,
        product_name=entry.product.product_name if entry.product else None,
        worker_id=entry.worker_id,
        worker_name=entry.worker.full_name if entry.worker else None,
        status=entry.status,
        erp_sync_status=entry.erp_sync_status,
        erp_reference_no=entry.erp_reference_no,
        rejection_reason=entry.rejection_reason,
        supervisor_remarks=entry.supervisor_remarks,
        approved_by_name=entry.approved_by.full_name if entry.approved_by else None,
        approved_at=entry.approved_at,
        last_edited_by_name=entry.last_edited_by.full_name if entry.last_edited_by else None,
        created_at=entry.created_at,
        updated_at=entry.updated_at,
        details=entry.details
    )


@router.post("", response_model=ProductionEntryOut)
def create_production_entry(
    payload: ProductionEntryCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Section Purpose: Creates Daily Tufting Production Entry.
    Computes Actual Qty, Variation, Balance Qty, and Running Meter.
    """
    det_in = payload.details
    metrics = CalculationService.compute_tufting_metrics(
        length_meters=det_in.length_meters,
        width_meters=det_in.width_meters,
        target_qty=det_in.target_qty
    )

    initial_status = EntryStatus.PENDING_APPROVAL if payload.is_submit else EntryStatus.DRAFT
    entry_no = _generate_tufting_entry_number(db)

    entry = ProductionEntry(
        entry_number=entry_no,
        entry_date=payload.entry_date,
        tufted_date=payload.tufted_date,
        shift_id=payload.shift_id,
        process_id=payload.process_id,
        machine_id=payload.machine_id,
        order_id=payload.order_id,
        customer_id=payload.customer_id,
        product_id=payload.product_id,
        worker_id=current_user.user_id,
        status=initial_status
    )
    db.add(entry)
    db.flush()

    detail = ProductionDetail(
        entry_id=entry.entry_id,
        base=det_in.base,
        pile_height=det_in.pile_height,
        sales_order_no=det_in.sales_order_no,
        customer_code=det_in.customer_code,
        po_number=det_in.po_number,
        roll_number=det_in.roll_number,
        start_time=det_in.start_time,
        end_time=det_in.end_time,
        length_meters=det_in.length_meters,
        width_meters=det_in.width_meters,
        target_qty=det_in.target_qty,
        actual_qty=metrics["actual_qty"],
        variation=metrics["variation"],
        balance_qty=metrics["balance_qty"],
        belt_speed=det_in.belt_speed,
        defects_a_yarn=det_in.defects_a_yarn,
        defects_b_pvc=det_in.defects_b_pvc,
        defects_c_tufting=det_in.defects_c_tufting,
        defects_d_stripe=det_in.defects_d_stripe,
        defects_e_others=det_in.defects_e_others,
        machine_stop_minutes=det_in.machine_stop_minutes,
        machine_stop_reason=det_in.machine_stop_reason,
        round_weight_left=det_in.round_weight_left,
        round_weight_center=det_in.round_weight_center,
        round_weight_right=det_in.round_weight_right,
        quality_remarks=det_in.quality_remarks,
        factory_labour_count=det_in.factory_labour_count,
        contract_labour_count=det_in.contract_labour_count,
        shift_machine_incharge=det_in.shift_machine_incharge,
        shift_quality_controller=det_in.shift_quality_controller,
        shift_supervisor_name=det_in.shift_supervisor_name,
        tufting_head=det_in.tufting_head,
        creel_stand=det_in.creel_stand,
        total_running_meter=metrics["running_meter"],
        total_sqm=metrics["actual_qty"],
        comments=det_in.comments
    )
    db.add(detail)
    db.commit()
    db.refresh(entry)

    AuditService.log_action(db, entry.entry_id, current_user.user_id, "CREATED", "Status", None, initial_status.value)
    return _format_entry_out(entry)


@router.get("", response_model=List[ProductionEntryOut])
def list_production_entries(
    status_filter: Optional[str] = Query(None, alias="status"),
    from_date: Optional[date] = Query(None, alias="from_date"),
    to_date: Optional[date] = Query(None, alias="to_date"),
    date_from: Optional[date] = Query(None, alias="date_from"),
    date_to: Optional[date] = Query(None, alias="date_to"),
    start_date: Optional[date] = Query(None, alias="start_date"),
    end_date: Optional[date] = Query(None, alias="end_date"),
    filter_date: Optional[date] = Query(None, alias="filter_date"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Section Purpose: Lists production entries. Workers see own records; Supervisors & Admins see all.
    Supports filtering by status and date range (from_date to to_date).
    """
    query = db.query(ProductionEntry)
    user_role = current_user.role.role_name.upper() if current_user.role else "WORKER"

    if user_role == "WORKER":
        query = query.filter(ProductionEntry.worker_id == current_user.user_id)

    if status_filter and status_filter != "All":
        query = query.filter(ProductionEntry.status == status_filter)

    eff_from = from_date or date_from or start_date or filter_date
    eff_to = to_date or date_to or end_date or filter_date

    if eff_from:
        query = query.filter(ProductionEntry.entry_date >= eff_from)
    if eff_to:
        query = query.filter(ProductionEntry.entry_date <= eff_to)

    entries = query.order_by(ProductionEntry.entry_date.desc(), ProductionEntry.created_at.desc()).all()
    return [_format_entry_out(e) for e in entries]


@router.get("/{entry_id}", response_model=ProductionEntryOut)
def get_production_entry(entry_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    entry = db.query(ProductionEntry).filter(ProductionEntry.entry_id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Production entry not found.")
    return _format_entry_out(entry)


@router.put("/{entry_id}", response_model=ProductionEntryOut)
def update_production_entry(
    entry_id: int,
    payload: ProductionEntryUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Section Purpose: Updates entry fields. Admin can update ANY entry at any status stage!
    Supervisors can update pending entries; Workers can update drafts/rejected.
    """
    entry = db.query(ProductionEntry).filter(ProductionEntry.entry_id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Production entry not found.")

    user_role = current_user.role.role_name.upper() if current_user.role else "WORKER"

    # Enforce Role Rules (Admin bypasses all restriction checks)
    if user_role == "WORKER" and entry.status in [EntryStatus.APPROVED, EntryStatus.PENDING_APPROVAL]:
        raise HTTPException(status_code=403, detail="Workers cannot edit entries awaiting or granted approval.")

    old_state = {
        "length_meters": entry.details.length_meters if entry.details else None,
        "width_meters": entry.details.width_meters if entry.details else None,
        "actual_qty": entry.details.actual_qty if entry.details else None,
    }

    if payload.entry_date:
        entry.entry_date = payload.entry_date
    if payload.tufted_date:
        entry.tufted_date = payload.tufted_date
    if payload.shift_id:
        entry.shift_id = payload.shift_id
    if payload.machine_id:
        entry.machine_id = payload.machine_id
    if payload.order_id:
        entry.order_id = payload.order_id
    if payload.supervisor_remarks:
        entry.supervisor_remarks = payload.supervisor_remarks

    entry.last_edited_by_user_id = current_user.user_id

    if payload.details and entry.details:
        det = entry.details
        det_data = payload.details.model_dump()

        new_len = det_data.get("length_meters", det.length_meters)
        new_wid = det_data.get("width_meters", det.width_meters)
        new_tgt = det_data.get("target_qty", det.target_qty)

        metrics = CalculationService.compute_tufting_metrics(new_len, new_wid, new_tgt)

        for k, v in det_data.items():
            setattr(det, k, v)

        det.actual_qty = metrics["actual_qty"]
        det.variation = metrics["variation"]
        det.balance_qty = metrics["balance_qty"]
        det.total_running_meter = metrics["running_meter"]
        det.total_sqm = metrics["actual_qty"]

    if payload.is_submit:
        entry.status = EntryStatus.PENDING_APPROVAL

    db.commit()
    db.refresh(entry)

    new_state = {
        "length_meters": entry.details.length_meters if entry.details else None,
        "width_meters": entry.details.width_meters if entry.details else None,
        "actual_qty": entry.details.actual_qty if entry.details else None,
    }
    AuditService.log_field_changes(db, entry.entry_id, current_user.user_id, old_state, new_state, action="EDITED")

    return _format_entry_out(entry)


@router.post("/{entry_id}/approve", response_model=ProductionEntryOut)
def approve_production_entry(
    entry_id: int,
    payload: ApprovalRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(RoleChecker(["SUPERVISOR", "ADMIN"]))
):
    """
    Section Purpose: Supervisor or Admin confirms/approves production entry.
    """
    entry = db.query(ProductionEntry).filter(ProductionEntry.entry_id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Production entry not found.")

    old_status = entry.status.value
    entry.status = EntryStatus.APPROVED
    entry.approved_by_user_id = current_user.user_id
    entry.approved_at = datetime.utcnow()
    if payload.supervisor_remarks:
        entry.supervisor_remarks = payload.supervisor_remarks

    db.commit()
    AuditService.log_action(db, entry.entry_id, current_user.user_id, "APPROVED", "Status", old_status, "APPROVED")
    ERPIntegrationService.sync_approved_production(db, entry.entry_id)

    db.refresh(entry)
    return _format_entry_out(entry)


@router.post("/{entry_id}/reject", response_model=ProductionEntryOut)
def reject_production_entry(
    entry_id: int,
    payload: RejectionRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(RoleChecker(["SUPERVISOR", "ADMIN"]))
):
    """
    Section Purpose: Supervisor or Admin rejects entry back to worker.
    """
    entry = db.query(ProductionEntry).filter(ProductionEntry.entry_id == entry_id).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Production entry not found.")

    old_status = entry.status.value
    entry.status = EntryStatus.REJECTED
    entry.rejection_reason = payload.rejection_reason
    db.commit()

    AuditService.log_action(db, entry.entry_id, current_user.user_id, "REJECTED", "Status", old_status, f"REJECTED: {payload.rejection_reason}")
    db.refresh(entry)
    return _format_entry_out(entry)


@router.get("/{entry_id}/history", response_model=List[AuditLogOut])
def get_entry_audit_history(entry_id: int, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    logs = db.query(AuditLog).filter(AuditLog.entry_id == entry_id).order_by(AuditLog.created_at.asc()).all()
    return [
        AuditLogOut(
            log_id=log.log_id,
            entry_id=log.entry_id,
            changed_by_username=log.changed_by.username if log.changed_by else "Unknown",
            changed_by_fullname=log.changed_by.full_name if log.changed_by else "Unknown",
            action=log.action,
            field_name=log.field_name,
            old_value=log.old_value,
            new_value=log.new_value,
            created_at=log.created_at
        ) for log in logs
    ]
