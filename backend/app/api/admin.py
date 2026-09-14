from typing import List, Optional
from datetime import datetime, date
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_

from app.database.session import get_db
from app.models.domain import User, Role, Permission, RolePermission, SystemAuditLog, ProductionEntry
from app.schemas.schemas import (
    UserCreate, UserUpdate, UserOut,
    RoleOut, RoleCreate, RoleUpdate, PermissionOut, SystemAuditLogOut
)
from app.core.security import RoleChecker, PermissionChecker, get_password_hash, log_system_activity

router = APIRouter(prefix="/admin", tags=["Admin Control Panel"])


def _format_user_out(user: User) -> UserOut:
    permissions = [p.code for p in user.role.permissions] if (user.role and user.role.permissions) else []
    return UserOut(
        user_id=user.user_id,
        username=user.username,
        email=user.email,
        full_name=user.full_name,
        role_name=user.role.role_name if user.role else "WORKER",
        is_active=user.is_active,
        is_blocked=user.is_blocked,
        is_deleted=getattr(user, 'is_deleted', False),
        permissions=permissions,
        created_at=user.created_at
    )


def _check_last_admin_protection(db: Session, target_user: User, new_role_id: Optional[int] = None, set_inactive: bool = False):
    """
    Section Purpose: Safety rule preventing deletion, deactivation, blocking, or demotion of the last active Admin.
    """
    admin_role = db.query(Role).filter(Role.role_name == "ADMIN").first()
    if not admin_role:
        return

    is_target_admin = (target_user.role_id == admin_role.role_id)
    if not is_target_admin:
        return

    # Count active non-deleted Admins
    active_admin_count = db.query(User).filter(
        User.role_id == admin_role.role_id,
        User.is_active == True,
        User.is_blocked == False,
        User.is_deleted == False
    ).count()

    if active_admin_count <= 1:
        if set_inactive or (new_role_id is not None and new_role_id != admin_role.role_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Security Protection Error: Cannot deactivate, block, demote, or delete the last active Admin user."
            )


# ------------------------------------------------------------------------------
# USER MANAGEMENT ENDPOINTS
# ------------------------------------------------------------------------------
@router.get("/users", response_model=List[UserOut])
def list_users(
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("admin_user_mgmt"))
):
    """
    Section Purpose: Lists all user login accounts in system (excluding soft-deleted ones).
    """
    users = db.query(User).filter(User.is_deleted == False).order_by(User.created_at.desc()).all()
    return [_format_user_out(u) for u in users]


@router.post("/users", response_model=UserOut)
def create_user(
    payload: UserCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("admin_user_mgmt"))
):
    """
    Section Purpose: Admin creates a new user login account.
    """
    existing = db.query(User).filter(User.username == payload.username, User.is_deleted == False).first()
    if existing:
        raise HTTPException(status_code=400, detail=f"Username '{payload.username}' already exists.")

    role = db.query(Role).filter(Role.role_name == payload.role_name.upper()).first()
    if not role:
        raise HTTPException(status_code=400, detail=f"Invalid security role '{payload.role_name}'.")

    hashed_pwd = get_password_hash(payload.password)
    user = User(
        username=payload.username,
        email=payload.email,
        hashed_password=hashed_pwd,
        full_name=payload.full_name,
        role_id=role.role_id,
        is_active=True,
        is_blocked=False,
        is_deleted=False
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    log_system_activity(
        db, current_user.user_id, current_user.username, current_user.role.role_name,
        "USER_CREATE", "users", f"Created user '{user.username}' with role '{role.role_name}'"
    )

    return _format_user_out(user)


@router.put("/users/{user_id}", response_model=UserOut)
def update_user(
    user_id: int,
    payload: UserUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("admin_user_mgmt"))
):
    """
    Section Purpose: Admin edits user details, changes role, deactivates, or resets password.
    """
    user = db.query(User).filter(User.user_id == user_id, User.is_deleted == False).first()
    if not user:
        raise HTTPException(status_code=404, detail="User account not found.")

    if payload.role_name:
        new_role = db.query(Role).filter(Role.role_name == payload.role_name.upper()).first()
        if new_role:
            _check_last_admin_protection(db, user, new_role_id=new_role.role_id)
            user.role_id = new_role.role_id

    if payload.is_active is False or payload.is_blocked is True:
        _check_last_admin_protection(db, user, set_inactive=True)

    if payload.full_name:
        user.full_name = payload.full_name
    if payload.email is not None:
        user.email = payload.email
    if payload.password:
        user.hashed_password = get_password_hash(payload.password)
    if payload.is_active is not None:
        user.is_active = payload.is_active
    if payload.is_blocked is not None:
        user.is_blocked = payload.is_blocked

    db.commit()
    db.refresh(user)

    log_system_activity(
        db, current_user.user_id, current_user.username, current_user.role.role_name,
        "USER_UPDATE", "users", f"Updated user profile #{user_id} ({user.username})"
    )
    return _format_user_out(user)


@router.put("/users/{user_id}/block", response_model=UserOut)
def toggle_block_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("admin_user_mgmt"))
):
    """
    Section Purpose: Admin blocks or unblocks user login account.
    """
    if user_id == current_user.user_id:
        raise HTTPException(status_code=400, detail="Admins cannot block their own active account.")

    user = db.query(User).filter(User.user_id == user_id, User.is_deleted == False).first()
    if not user:
        raise HTTPException(status_code=404, detail="User account not found.")

    if not user.is_blocked:
        _check_last_admin_protection(db, user, set_inactive=True)

    user.is_blocked = not user.is_blocked
    db.commit()
    db.refresh(user)

    action_label = "USER_BLOCK" if user.is_blocked else "USER_UNBLOCK"
    log_system_activity(
        db, current_user.user_id, current_user.username, current_user.role.role_name,
        action_label, "users", f"Toggled block status for user #{user_id} ({user.username}) -> is_blocked={user.is_blocked}"
    )
    return _format_user_out(user)


@router.delete("/users/{user_id}")
def delete_user(
    user_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("admin_user_mgmt"))
):
    """
    Section Purpose: Admin removes a user login account.
    Uses soft-deletion to preserve historical work records if entries exist.
    """
    if user_id == current_user.user_id:
        raise HTTPException(status_code=400, detail="Admins cannot delete their own active account.")

    user = db.query(User).filter(User.user_id == user_id, User.is_deleted == False).first()
    if not user:
        raise HTTPException(status_code=404, detail="User account not found.")

    _check_last_admin_protection(db, user, set_inactive=True)

    # Check if user has associated production entries
    entry_count = db.query(ProductionEntry).filter(ProductionEntry.worker_id == user_id).count()

    if entry_count > 0:
        # Soft-delete to preserve historical audit logs & foreign keys
        user.is_deleted = True
        user.is_active = False
        user.is_blocked = True
        db.commit()
        msg = f"User account #{user_id} ({user.username}) soft-deleted (preserved {entry_count} historical records)."
    else:
        db.delete(user)
        db.commit()
        msg = f"User account #{user_id} ({user.username}) permanently deleted."

    log_system_activity(
        db, current_user.user_id, current_user.username, current_user.role.role_name,
        "USER_DELETE", "users", msg
    )
    return {"success": True, "message": msg}


# ------------------------------------------------------------------------------
# ROLE & PERMISSION MANAGEMENT ENDPOINTS
# ------------------------------------------------------------------------------
@router.get("/permissions", response_model=List[PermissionOut])
def list_permissions(
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("admin_role_mgmt"))
):
    """
    Section Purpose: Lists all system granular permissions grouped by category.
    """
    perms = db.query(Permission).order_by(Permission.category, Permission.name).all()
    return [PermissionOut.model_validate(p) for p in perms]


@router.get("/roles", response_model=List[RoleOut])
def list_roles(
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("admin_role_mgmt"))
):
    """
    Section Purpose: Lists all security roles, assigned permissions, and active user counts.
    """
    roles = db.query(Role).order_by(Role.role_id).all()
    result = []
    for r in roles:
        ucount = db.query(User).filter(User.role_id == r.role_id, User.is_deleted == False).count()
        perms_out = [PermissionOut.model_validate(p) for p in r.permissions] if r.permissions else []
        result.append(RoleOut(
            role_id=r.role_id,
            role_name=r.role_name,
            description=r.description,
            created_at=r.created_at,
            user_count=ucount,
            permissions=perms_out
        ))
    return result


@router.post("/roles", response_model=RoleOut)
def create_role(
    payload: RoleCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("admin_role_mgmt"))
):
    """
    Section Purpose: Admin creates a custom role with selected permissions.
    """
    role_name = payload.role_name.strip().upper()
    existing = db.query(Role).filter(Role.role_name == role_name).first()
    if existing:
        raise HTTPException(status_code=400, detail=f"Role '{role_name}' already exists.")

    new_role = Role(role_name=role_name, description=payload.description)
    db.add(new_role)
    db.flush()

    if payload.permission_ids:
        perms = db.query(Permission).filter(Permission.permission_id.in_(payload.permission_ids)).all()
        for p in perms:
            db.add(RolePermission(role_id=new_role.role_id, permission_id=p.permission_id))

    db.commit()
    db.refresh(new_role)

    log_system_activity(
        db, current_user.user_id, current_user.username, current_user.role.role_name,
        "ROLE_CREATE", "roles", f"Created role '{role_name}' with {len(payload.permission_ids)} permissions"
    )

    perms_out = [PermissionOut.model_validate(p) for p in new_role.permissions] if new_role.permissions else []
    return RoleOut(
        role_id=new_role.role_id,
        role_name=new_role.role_name,
        description=new_role.description,
        created_at=new_role.created_at,
        user_count=0,
        permissions=perms_out
    )


@router.put("/roles/{role_id}", response_model=RoleOut)
def update_role(
    role_id: int,
    payload: RoleUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("admin_role_mgmt"))
):
    """
    Section Purpose: Admin edits role details and permission matrix.
    """
    role = db.query(Role).filter(Role.role_id == role_id).first()
    if not role:
        raise HTTPException(status_code=404, detail="Role not found.")

    if payload.role_name and payload.role_name.strip().upper() != role.role_name:
        if role.role_name in ["ADMIN", "SUPERVISOR", "WORKER"]:
            raise HTTPException(status_code=400, detail=f"Cannot rename default system role '{role.role_name}'.")
        role.role_name = payload.role_name.strip().upper()

    if payload.description is not None:
        role.description = payload.description

    if payload.permission_ids is not None:
        # Clear existing mappings and re-insert
        db.query(RolePermission).filter(RolePermission.role_id == role_id).delete()
        perms = db.query(Permission).filter(Permission.permission_id.in_(payload.permission_ids)).all()
        for p in perms:
            db.add(RolePermission(role_id=role_id, permission_id=p.permission_id))

    db.commit()
    db.refresh(role)

    log_system_activity(
        db, current_user.user_id, current_user.username, current_user.role.role_name,
        "ROLE_UPDATE", "roles", f"Updated permissions for role '{role.role_name}'"
    )

    ucount = db.query(User).filter(User.role_id == role.role_id, User.is_deleted == False).count()
    perms_out = [PermissionOut.model_validate(p) for p in role.permissions] if role.permissions else []
    return RoleOut(
        role_id=role.role_id,
        role_name=role.role_name,
        description=role.description,
        created_at=role.created_at,
        user_count=ucount,
        permissions=perms_out
    )


@router.delete("/roles/{role_id}")
def delete_role(
    role_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("admin_role_mgmt"))
):
    """
    Section Purpose: Admin deletes a custom role if no active users are assigned to it.
    """
    role = db.query(Role).filter(Role.role_id == role_id).first()
    if not role:
        raise HTTPException(status_code=404, detail="Role not found.")

    if role.role_name in ["ADMIN", "SUPERVISOR", "WORKER"]:
        raise HTTPException(status_code=400, detail=f"Default system role '{role.role_name}' cannot be deleted.")

    user_count = db.query(User).filter(User.role_id == role_id, User.is_deleted == False).count()
    if user_count > 0:
        raise HTTPException(status_code=400, detail=f"Cannot delete role '{role.role_name}'; {user_count} user(s) are assigned to it.")

    db.query(RolePermission).filter(RolePermission.role_id == role_id).delete()
    db.delete(role)
    db.commit()

    log_system_activity(
        db, current_user.user_id, current_user.username, current_user.role.role_name,
        "ROLE_DELETE", "roles", f"Deleted role #{role_id} ({role.role_name})"
    )
    return {"success": True, "message": f"Role '{role.role_name}' deleted successfully."}


# ------------------------------------------------------------------------------
# SYSTEM ACTIVITY AUDIT LOG ENDPOINT
# ------------------------------------------------------------------------------
@router.get("/activity", response_model=List[SystemAuditLogOut])
def list_system_activity(
    search: Optional[str] = None,
    user_id: Optional[int] = None,
    role_name: Optional[str] = None,
    action: Optional[str] = None,
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
    limit: int = Query(100, ge=1, le=1000),
    db: Session = Depends(get_db),
    current_user: User = Depends(PermissionChecker("admin_activity_view"))
):
    """
    Section Purpose: Search & filter operational activity and system audit log.
    """
    q = db.query(SystemAuditLog)

    if search:
        s_pattern = f"%{search.strip()}%"
        q = q.filter(
            or_(
                SystemAuditLog.username.like(s_pattern),
                SystemAuditLog.action.like(s_pattern),
                SystemAuditLog.resource.like(s_pattern),
                SystemAuditLog.details.like(s_pattern)
            )
        )

    if user_id:
        q = q.filter(SystemAuditLog.user_id == user_id)
    if role_name and role_name != "ALL":
        q = q.filter(SystemAuditLog.role_name == role_name.upper())
    if action and action != "ALL":
        q = q.filter(SystemAuditLog.action == action)
    if start_date:
        q = q.filter(SystemAuditLog.timestamp >= datetime.combine(start_date, datetime.min.time()))
    if end_date:
        q = q.filter(SystemAuditLog.timestamp <= datetime.combine(end_date, datetime.max.time()))

    logs = q.order_by(SystemAuditLog.timestamp.desc()).limit(limit).all()
    return [SystemAuditLogOut.model_validate(l) for l in logs]

