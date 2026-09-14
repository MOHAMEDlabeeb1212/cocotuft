# ==============================================================================
# COCOTUFT PRODUCTION MANAGEMENT SYSTEM - FASTAPI MAIN ENTRYPOINT
# ==============================================================================
# Section Purpose: Main app initializer registering API routers (auth, master data,
# tufting production, tufting summary, dashboard, and admin user management).
# ==============================================================================

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

from app.core.config import settings
from app.database.session import engine, Base, SessionLocal
from app.api import auth, master_data, production, summary, dashboard, admin, excel
from app.seed import init_db_seed


@asynccontextmanager
async def lifespan(app: FastAPI):
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        init_db_seed(db)
    finally:
        db.close()
    yield


app = FastAPI(
    title=settings.PROJECT_NAME,
    version=settings.VERSION,
    description="Tufting Production Management System for COCOTUFT",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix=settings.API_V1_STR)
app.include_router(master_data.router, prefix=settings.API_V1_STR)
app.include_router(production.router, prefix=settings.API_V1_STR)
app.include_router(summary.router, prefix=settings.API_V1_STR)
app.include_router(dashboard.router, prefix=settings.API_V1_STR)
app.include_router(admin.router, prefix=settings.API_V1_STR)
app.include_router(excel.router, prefix=settings.API_V1_STR)



import os
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse, RedirectResponse

# Check for Flutter Web build directory
web_build_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), "../../build/web"))

if os.path.exists(web_build_dir):
    app.mount("/", StaticFiles(directory=web_build_dir, html=True), name="web")
else:
    @app.get("/", include_in_schema=False)
    def root_redirect():
        return RedirectResponse(url="/docs")


