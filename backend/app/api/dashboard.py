# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - DASHBOARD KPI API ENDPOINTS
# ==============================================================================
# Section Purpose: REST API delivering real-time KPI card metrics and active queue lists
# for Worker Dashboard and Supervisor Review Dashboard.
# ==============================================================================

from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from sqlalchemy import func

from app.database.session import get_db
from app.models.domain import ProductionEntry, ProductionDetail, EntryStatus, User
from app.schemas.schemas import WorkerDashboardOut, SupervisorDashboardOut
from app.api.production import _format_entry_out
from app.core.security import get_current_user, RoleChecker

router = APIRouter(prefix="/dashboard", tags=["Dashboards"])


@router.get("/worker", response_model=WorkerDashboardOut)
def get_worker_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Section Purpose: Delivers Worker KPI metrics (Today's entries, Pending approvals,
    Approved today count, and SQM produced today).
    """
    today = date.today()

    # Worker specific query
    base_query = db.query(ProductionEntry).filter(ProductionEntry.worker_id == current_user.user_id)

    todays_entries = base_query.filter(ProductionEntry.entry_date == today).count()
    pending_count = base_query.filter(ProductionEntry.status == EntryStatus.PENDING_APPROVAL).count()
    approved_today = base_query.filter(
        ProductionEntry.entry_date == today,
        ProductionEntry.status == EntryStatus.APPROVED
    ).count()

    # Total SQM produced today by worker
    sqm_today = db.query(
        func.coalesce(func.sum(ProductionDetail.actual_qty), 0.0)
    ).join(
        ProductionEntry, ProductionDetail.entry_id == ProductionEntry.entry_id
    ).filter(
        ProductionEntry.worker_id == current_user.user_id,
        ProductionEntry.entry_date == today
    ).scalar()

    # Fetch recent entries
    recent = base_query.order_by(ProductionEntry.created_at.desc()).limit(10).all()

    return WorkerDashboardOut(
        todays_entries_count=todays_entries,
        pending_approval_count=pending_count,
        approved_today_count=approved_today,
        total_sqm_produced_today=round(float(sqm_today), 2),
        recent_entries=[_format_entry_out(e) for e in recent]
    )


@router.get("/supervisor", response_model=SupervisorDashboardOut)
def get_supervisor_dashboard(
    from_date: Optional[date] = Query(None, description="Start date filter"),
    to_date: Optional[date] = Query(None, description="End date filter"),
    db: Session = Depends(get_db),
    current_user: User = Depends(RoleChecker(["SUPERVISOR", "ADMIN"]))
):
    """
    Section Purpose: Delivers Supervisor KPI metrics (Pending approvals queue,
    Approved count, Rejected count, and total shop-floor SQM).
    Optionally filtered by from_date and to_date; defaults to today for daily stats.
    """
    today = date.today()
    start = from_date or today
    end = to_date or today

    pending_query = db.query(ProductionEntry).filter(ProductionEntry.status == EntryStatus.PENDING_APPROVAL)
    if from_date:
        pending_query = pending_query.filter(ProductionEntry.entry_date >= from_date)
    if to_date:
        pending_query = pending_query.filter(ProductionEntry.entry_date <= to_date)
    pending_count = pending_query.count()

    approved_query = db.query(ProductionEntry).filter(
        ProductionEntry.entry_date >= start,
        ProductionEntry.entry_date <= end,
        ProductionEntry.status == EntryStatus.APPROVED
    )
    approved_count = approved_query.count()

    rejected_query = db.query(ProductionEntry).filter(
        ProductionEntry.entry_date >= start,
        ProductionEntry.entry_date <= end,
        ProductionEntry.status == EntryStatus.REJECTED
    )
    rejected_count = rejected_query.count()

    # Total SQM across factory for selected period
    sqm_query = db.query(
        func.coalesce(func.sum(ProductionDetail.actual_qty), 0.0)
    ).join(
        ProductionEntry, ProductionDetail.entry_id == ProductionEntry.entry_id
    ).filter(
        ProductionEntry.entry_date >= start,
        ProductionEntry.entry_date <= end
    )
    sqm_period = sqm_query.scalar()

    # Fetch pending entries awaiting review
    pending_list = pending_query.order_by(ProductionEntry.created_at.asc()).all()

    return SupervisorDashboardOut(
        pending_approvals_count=pending_count,
        approved_today_count=approved_count,
        rejected_today_count=rejected_count,
        todays_total_sqm=round(float(sqm_period), 2),
        pending_entries=[_format_entry_out(e) for e in pending_list]
    )
