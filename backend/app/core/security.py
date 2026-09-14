# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - SECURITY & AUTHENTICATION
# ==============================================================================
# Section Purpose: Implements password hashing, JWT authentication token creation,
# token verification, and Role-Based Access Control (RBAC) authorization guards.
# ==============================================================================

from datetime import datetime, timedelta
from typing import Optional, List
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError, jwt
from passlib.context import CryptContext
from sqlalchemy.orm import Session

from app.core.config import settings
from app.database.session import get_db

# ------------------------------------------------------------------------------
# Password Hashing Context
# Section Purpose: Configure bcrypt password hashing engine.
# ------------------------------------------------------------------------------
import bcrypt

# OAuth2 scheme for extracting Bearer tokens from incoming HTTP Authorization headers
oauth2_scheme = OAuth2PasswordBearer(tokenUrl=f"{settings.API_V1_STR}/auth/login")

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """
    Section Purpose: Verifies plain text password against stored bcrypt hash.
    """
    try:
        return bcrypt.checkpw(plain_password.encode('utf-8'), hashed_password.encode('utf-8'))
    except Exception:
        return False


def get_password_hash(password: str) -> str:
    """
    Section Purpose: Hashes plain text password securely using bcrypt.
    """
    salt = bcrypt.gensalt()
    return bcrypt.hashpw(password.encode('utf-8'), salt).decode('utf-8')


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Section Purpose: Creates signed JWT access token encoding user identity and role.
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM)
    return encoded_jwt


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)):
    """
    Section Purpose: Dependency injector extracting and validating current user from JWT token.
    Enforces active, non-blocked, non-deleted account status on every request.
    """
    # Import model lazily to avoid circular imports
    from app.models.domain import User

    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate authentication credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except Exception:
        raise credentials_exception

    user = db.query(User).filter(User.username == username).first()
    if user is None or not user.is_active or user.is_blocked or getattr(user, 'is_deleted', False):
        raise credentials_exception
    return user


class RoleChecker:
    """
    Section Purpose: Security guard dependency enforcing required roles for API endpoints.
    Example: Depends(RoleChecker(["SUPERVISOR", "ADMIN"]))
    """
    def __init__(self, allowed_roles: List[str]):
        self.allowed_roles = allowed_roles

    def __call__(self, current_user = Depends(get_current_user)):
        user_role_name = current_user.role.role_name.upper() if current_user.role else ""
        if user_role_name not in [r.upper() for r in self.allowed_roles]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access forbidden. Required role: {', '.join(self.allowed_roles)}. Your role: {user_role_name}"
            )
        return current_user


class PermissionChecker:
    """
    Section Purpose: Security guard dependency enforcing required granular permissions.
    Example: Depends(PermissionChecker("excel_export"))
    """
    def __init__(self, required_permission: str):
        self.required_permission = required_permission

    def __call__(self, current_user = Depends(get_current_user)):
        user_role = current_user.role
        if not user_role:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No role assigned.")
        
        # ADMIN bypasses permission restrictions
        if user_role.role_name.upper() == "ADMIN":
            return current_user

        user_perm_codes = [p.code for p in user_role.permissions] if user_role.permissions else []
        if self.required_permission not in user_perm_codes:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Access forbidden. Missing required permission: {self.required_permission}"
            )
        return current_user


def log_system_activity(
    db: Session,
    user_id: Optional[int],
    username: str,
    role_name: str,
    action: str,
    resource: Optional[str] = None,
    details: Optional[str] = None,
    ip_address: Optional[str] = None
):
    """
    Section Purpose: Audit trail logger for important system administrative and operational actions.
    """
    from app.models.domain import SystemAuditLog
    log_entry = SystemAuditLog(
        user_id=user_id,
        username=username,
        role_name=role_name,
        action=action,
        resource=resource,
        details=details,
        ip_address=ip_address
    )
    db.add(log_entry)
    try:
        db.commit()
    except Exception:
        db.rollback()

