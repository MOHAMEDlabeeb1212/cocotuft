# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - DASHBOARD KPI API ENDPOINTS
# ==============================================================================
# Section Purpose: REST API delivering real-time KPI card metrics and active queue lists
# for Worker Dashboard and Supervisor Review Dashboard.
# ==============================================================================

from datetime import date
from fastapi import APIRouter, Depends
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
    db: Session = Depends(get_db),
    current_user: User = Depends(RoleChecker(["SUPERVISOR", "ADMIN"]))
):
    """
    Section Purpose: Delivers Supervisor KPI metrics (Pending approvals queue,
    Approved today count, Rejected today count, and total shop-floor SQM).
    """
    today = date.today()

    pending_count = db.query(ProductionEntry).filter(ProductionEntry.status == EntryStatus.PENDING_APPROVAL).count()
    approved_today = db.query(ProductionEntry).filter(
        ProductionEntry.entry_date == today,
        ProductionEntry.status == EntryStatus.APPROVED
    ).count()
    rejected_today = db.query(ProductionEntry).filter(
        ProductionEntry.entry_date == today,
        ProductionEntry.status == EntryStatus.REJECTED
    ).count()

    # Total SQM across factory today
    sqm_today = db.query(
        func.coalesce(func.sum(ProductionDetail.actual_qty), 0.0)
    ).join(
        ProductionEntry, ProductionDetail.entry_id == ProductionEntry.entry_id
    ).filter(
        ProductionEntry.entry_date == today
    ).scalar()

    # Fetch pending entries awaiting review
    pending_list = db.query(ProductionEntry).filter(
        ProductionEntry.status == EntryStatus.PENDING_APPROVAL
    ).order_by(ProductionEntry.created_at.asc()).all()

    return SupervisorDashboardOut(
        pending_approvals_count=pending_count,
        approved_today_count=approved_today,
        rejected_today_count=rejected_today,
        todays_total_sqm=round(float(sqm_today), 2),
        pending_entries=[_format_entry_out(e) for e in pending_list]
    )
