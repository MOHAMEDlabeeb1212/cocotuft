# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - ERP INTEGRATION LAYER
# ==============================================================================
# Section Purpose: Architecture layer for integrating COCOTUFT system with company ERP.
# Handles ERP synchronization status tracking (ERP_SYNC_PENDING, ERP_SYNCED, ERP_SYNC_FAILED),
# reference code assignment, error logging, and retry queues.
# ==============================================================================

from datetime import datetime
from sqlalchemy.orm import Session
from app.models.domain import ProductionEntry, ERPSyncStatus, AuditLog


class ERPIntegrationService:
    """
    ERP Integration Interface & Service.
    Prepared to interface with ERP REST API, direct database, or file exchange interfaces.
    """

    @staticmethod
    def sync_approved_production(db: Session, entry_id: int) -> dict:
        """
        Section Purpose: Synchronizes an APPROVED production record to the ERP system.
        Simulates ERP API endpoint transmission and updates database synchronization state.
        """
        entry = db.query(ProductionEntry).filter(ProductionEntry.entry_id == entry_id).first()
        if not entry:
            return {"success": False, "message": "Production entry not found"}

        if entry.status.value != "APPROVED":
            return {"success": False, "message": "Only APPROVED production entries can be synchronized to ERP."}

        try:
            # ERP Synchronization Simulation Layer
            # In production, this method calls the ERP REST API endpoint or ERP DB procedure.
            erp_ref = f"ERP-REF-{datetime.utcnow().strftime('%Y%m%d')}-{entry.entry_id:04d}"
            
            entry.erp_sync_status = ERPSyncStatus.ERP_SYNCED
            entry.erp_reference_no = erp_ref
            entry.erp_synced_at = datetime.utcnow()
            entry.erp_sync_message = "Successfully synchronized to COCOTUFT BizCare ERP system."

            # Log audit event for ERP sync
            audit_log = AuditLog(
                entry_id=entry.entry_id,
                changed_by_user_id=entry.approved_by_user_id or entry.worker_id,
                action="ERP_SYNC",
                field_name="erp_sync_status",
                old_value="ERP_SYNC_PENDING",
                new_value="ERP_SYNCED"
            )
            db.add(audit_log)
            db.commit()

            return {
                "success": True,
                "erp_reference_no": erp_ref,
                "sync_status": "ERP_SYNCED",
                "message": "Successfully synchronized entry to ERP."
            }

        except Exception as e:
            db.rollback()
            entry.erp_sync_status = ERPSyncStatus.ERP_SYNC_FAILED
            entry.erp_sync_message = f"ERP Sync Error: {str(e)}"
            db.commit()

            return {
                "success": False,
                "sync_status": "ERP_SYNC_FAILED",
                "message": f"ERP Sync Failed: {str(e)}"
            }

    @staticmethod
    def check_sync_status(db: Session, entry_id: int) -> dict:
        """
        Section Purpose: Returns current ERP synchronization status and reference details.
        """
        entry = db.query(ProductionEntry).filter(ProductionEntry.entry_id == entry_id).first()
        if not entry:
            return {"found": False}

        return {
            "found": True,
            "entry_number": entry.entry_number,
            "status": entry.status.value,
            "erp_sync_status": entry.erp_sync_status.value,
            "erp_reference_no": entry.erp_reference_no,
            "erp_synced_at": entry.erp_synced_at,
            "erp_sync_message": entry.erp_sync_message
        }
