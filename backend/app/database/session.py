# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - DATABASE SESSION MANAGEMENT
# ==============================================================================
# Section Purpose: Configures SQLAlchemy engine, session maker, declarative base,
# and DB dependency injector for request scope session management.
# ==============================================================================

from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# ------------------------------------------------------------------------------
# Engine & Session Setup
# Section Purpose: Initialize SQLAlchemy engine based on DATABASE_URL setting.
# Supports SQLite connect args if sqlite fallback is selected.
# ------------------------------------------------------------------------------
connect_args = {}
if "sqlite" in settings.DATABASE_URL:
    connect_args = {"check_same_thread": False}

engine = create_engine(settings.DATABASE_URL, connect_args=connect_args, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def get_db():
    """
    Section Purpose: FastAPI dependency providing database session for API endpoints.
    Ensures database session is automatically closed after request completion.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
