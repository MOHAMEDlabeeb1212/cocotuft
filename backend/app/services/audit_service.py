# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - AUDIT LOG SERVICE
# ==============================================================================
# Section Purpose: Auditing service that records user identity, change timestamp,
# field diffs, and workflow state transitions for regulatory compliance and auditability.
# ==============================================================================

from sqlalchemy.orm import Session
from app.models.domain import AuditLog, ProductionEntry, ProductionDetail


class AuditService:
    """
    Audit logging service tracking every change made to production records.
    """

    @staticmethod
    def log_action(
        db: Session,
        entry_id: int,
        user_id: int,
        action: str,
        field_name: str = None,
        old_value: str = None,
        new_value: str = None
    ) -> AuditLog:
        """
        Section Purpose: Creates an immutable audit log entry.
        """
        log_entry = AuditLog(
            entry_id=entry_id,
            changed_by_user_id=user_id,
            action=action,
            field_name=field_name,
            old_value=str(old_value) if old_value is not None else None,
            new_value=str(new_value) if new_value is not None else None
        )
        db.add(log_entry)
        db.commit()
        db.refresh(log_entry)
        return log_entry

    @staticmethod
    def log_field_changes(
        db: Session,
        entry_id: int,
        user_id: int,
        old_obj: dict,
        new_obj: dict,
        action: str = "EDITED"
    ):
        """
        Section Purpose: Compares old object dictionary vs new object dictionary
        and creates field-level audit log diff records for changed attributes.
        """
        ignore_fields = {"created_at", "updated_at", "entry_id", "detail_id"}
        for key, new_val in new_obj.items():
            if key in ignore_fields:
                continue
            old_val = old_obj.get(key)
            # Log diff if value actually changed
            if str(old_val) != str(new_val):
                AuditService.log_action(
                    db=db,
                    entry_id=entry_id,
                    user_id=user_id,
                    action=action,
                    field_name=key,
                    old_value=str(old_val),
                    new_value=str(new_val)
                )
