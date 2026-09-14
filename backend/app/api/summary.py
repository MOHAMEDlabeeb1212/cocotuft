# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - TUFTING SUMMARY API CONTROLLER
# ==============================================================================
# Section Purpose: Calculates Tufting Production Summary report metrics:
# Production Order No., Pile, Width, Length, Target Qty, Actual Qty, Variation,
# Balance Qty, and Running Meter.
# ==============================================================================

from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database.session import get_db
from app.models.domain import ProductionEntry, ProductionDetail, Machine, Process, Shift, User
from app.schemas.schemas import ProductionSummaryOut, TuftingSummaryRow
from app.core.security import get_current_user

router = APIRouter(prefix="/summary", tags=["Tufting Summary"])


@router.get("", response_model=ProductionSummaryOut)
def get_tufting_summary(
    filter_date: Optional[date] = Query(None, description="Filter summary by date"),
    filter_machine: Optional[str] = Query("All", description="Filter by machine name"),
    filter_shift: Optional[str] = Query("All", description="Filter by shift name"),
    filter_status: Optional[str] = Query("APPROVED", description="Filter status (APPROVED, All)"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Section Purpose: Dynamic Tufting Production Summary matching paper report columns:
    Production Order No, Machine, Pile Height, Width, Length, Target Qty, Actual Qty,
    Variation, Balance Qty, Running Meter.
    """
    query = db.query(ProductionEntry).join(
        ProductionDetail, ProductionEntry.entry_id == ProductionDetail.entry_id
    ).join(
        Machine, ProductionEntry.machine_id == Machine.machine_id
    ).outerjoin(
        Shift, ProductionEntry.shift_id == Shift.shift_id
    )

    if filter_date:
        query = query.filter(ProductionEntry.entry_date == filter_date)
    if filter_machine and filter_machine != "All":
        query = query.filter(Machine.machine_name == filter_machine)
    if filter_shift and filter_shift != "All":
        query = query.filter(Shift.shift_name == filter_shift)
    if filter_status and filter_status != "All":
        query = query.filter(ProductionEntry.status == filter_status)

    entries = query.order_by(ProductionEntry.created_at.desc()).all()

    rows = []
    tot_target = 0.0
    tot_actual = 0.0
    tot_variation = 0.0
    tot_balance = 0.0
    tot_running = 0.0

    for e in entries:
        d = e.details
        if not d:
            continue
        row = TuftingSummaryRow(
            sales_order_no=d.sales_order_no,
            machine_name=e.machine.machine_name if e.machine else "Tufting Machine",
            pile_height=d.pile_height,
            width_meters=d.width_meters,
            length_meters=d.length_meters,
            target_qty=d.target_qty,
            actual_qty=d.actual_qty,
            variation=d.variation,
            balance_qty=d.balance_qty,
            running_meter=d.total_running_meter,
        )
        rows.append(row)
        tot_target += d.target_qty
        tot_actual += d.actual_qty
        tot_variation += d.variation
        tot_balance += d.balance_qty
        tot_running += d.total_running_meter

    return ProductionSummaryOut(
        filter_date=filter_date,
        filter_machine=filter_machine,
        filter_shift=filter_shift,
        filter_status=filter_status,
        rows=rows,
        total_entries=len(rows),
        grand_total_target_qty=round(tot_target, 2),
        grand_total_actual_qty=round(tot_actual, 2),
        grand_total_variation=round(tot_variation, 2),
        grand_total_balance_qty=round(tot_balance, 2),
        grand_total_running_meter=round(tot_running, 2),
    )
