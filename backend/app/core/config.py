# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - CORE CONFIGURATION
# ==============================================================================
# Section Purpose: Defines application settings, environment variables, database
# connection strings, and security constants (JWT keys, token expiration).
# ==============================================================================

import os
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Application settings class using Pydantic settings management.
    Reads environment variables or uses default values for development.
    """
    PROJECT_NAME: str = "COCOTUFT Production Management System"
    VERSION: str = "1.0.0"
    API_V1_STR: str = "/api"

    # --------------------------------------------------------------------------
    # Database Configuration
    # Section Purpose: Configures connection to MySQL database.
    # Default uses SQLite fallback for seamless standalone demo execution if MySQL is offline.
    # --------------------------------------------------------------------------
    MYSQL_USER: str = os.getenv("MYSQL_USER", "root")
    MYSQL_PASSWORD: str = os.getenv("MYSQL_PASSWORD", "")
    MYSQL_HOST: str = os.getenv("MYSQL_HOST", "localhost")
    MYSQL_PORT: str = os.getenv("MYSQL_PORT", "3306")
    MYSQL_DB: str = os.getenv("MYSQL_DB", "cocotuft_db")

    @property
    def DATABASE_URL(self) -> str:
        # Check if explicitly provided via env
        env_url = os.getenv("DATABASE_URL")
        if env_url:
            return env_url
        # If MySQL password or custom host provided, use MySQL driver
        if self.MYSQL_PASSWORD or os.getenv("USE_MYSQL") == "true":
            return f"mysql+pymysql://{self.MYSQL_USER}:{self.MYSQL_PASSWORD}@{self.MYSQL_HOST}:{self.MYSQL_PORT}/{self.MYSQL_DB}"
        # Standalone SQLite fallback DB file inside backend root directory
        return "sqlite:///./cocotuft.db"

    # --------------------------------------------------------------------------
    # Security Configuration
    # Section Purpose: JWT Token generation secret key and hashing settings.
    # --------------------------------------------------------------------------
    SECRET_KEY: str = os.getenv("SECRET_KEY", "COCOTUFT_SUPER_SECRET_PRODUCTION_KEY_2026_ENTERPRISE")
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24  # 24 hours token validity

    # --------------------------------------------------------------------------
    # CORS Configuration
    # Section Purpose: Allowed frontend origins for REST API calls.
    # --------------------------------------------------------------------------
    ALLOWED_ORIGINS: list[str] = ["*"]

    model_config = SettingsConfigDict(case_sensitive=True, env_file=".env")


settings = Settings()
