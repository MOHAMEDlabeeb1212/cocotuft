# COCOTUFT Production Management System

> **Enterprise Manufacturing Production Recording, Supervisor Review, Audit Log & ERP Integration Platform**

The **COCOTUFT Production Management System** digitizes mat manufacturing production recording, supervisor review/approval workflows, field-level audit trails, read-only dynamic production summaries, and ERP synchronization abstraction.

---

## Architecture Overview

```
                      ┌──────────────────────────────┐
                      │    FLUTTER RESPONSIVE APP    │
                      │  Desktop / Tablet / Mobile   │
                      └──────────────┬───────────────┘
                                     │
                                REST API (HTTPS)
                                     │
                                     ▼
                      ┌──────────────────────────────┐
                      │    PYTHON FASTAPI BACKEND    │
                      │  JWT Auth • RBAC • Calculations│
                      └──────────────┬───────────────┘
                                     │
                              SQLAlchemy ORM
                                     │
                                     ▼
                      ┌──────────────────────────────┐
                      │       MYSQL DATABASE         │
                      │ Master Data • Entries • Audits│
                      └──────────────┬───────────────┘
                                     │
                                     ▼
                      ┌──────────────────────────────┐
                      │    ERP INTEGRATION LAYER     │
                      │  BizCare / ERP Synchronization│
                      └──────────────────────────────┘
```

> **Note**: Flutter communicates strictly through the FastAPI REST backend API. No direct database access is allowed.

---

## Key Features

1. **Role-Based Access Control (RBAC)**:
   - **WORKER**: Create production entries, view own dashboard & recent entries, save drafts, submit records, view read-only summaries. Cannot approve, edit others' records, or modify summary metrics.
   - **SUPERVISOR**: Review pending submissions, edit submitted entries (logged in audit history), approve/confirm records, reject records back to worker with reason, view read-only summaries. Cannot manually tamper with calculated summary totals.
   - **ADMIN**: Master data & user management architecture.

2. **Server-Authoritative Calculations**:
   - Live frontend area preview + backend authoritative recalculation of Square Meters (SQM): $\text{Length (m)} \times \text{Width (m)}$.
   - Read-only calculated metrics in UI; workers cannot manually overwrite SQM values.

3. **Field-Level Audit Trail**:
   - Immutable audit logging recording creator identity, creation timestamp, edit author, edit timestamp, field name diffs (`old_value` $\rightarrow$ `new_value`), supervisor approval, and rejection reason.

4. **Automated Read-Only Production Summary**:
   - Live production totals (Total Entries, Total Length, Total SQM) calculated dynamically from database records.
   - Filterable by Date, Process (Mixing, Cutting, Shearing, Tufting), Machine, Shift, and Approval Status.

5. **ERP Integration Abstraction**:
   - `ERPIntegrationService` interface managing status tracking (`ERP_SYNC_PENDING`, `ERP_SYNCED`, `ERP_SYNC_FAILED`), ERP reference codes, and retry logic.

---

## Demo Accounts

| Role | Username | Password | Purpose |
| :--- | :--- | :--- | :--- |
| **Worker** | `worker01` | `Demo@123` | Shop-floor production recording & submission |
| **Worker** | `worker02` | `Demo@123` | Additional worker account |
| **Supervisor** | `supervisor01` | `Demo@123` | Supervisor review, editing, approval & audit inspection |
| **Admin** | `admin01` | `Demo@123` | System administrator |

---

## Getting Started & Execution Guide

### 1. Backend Setup & Test Suite Execution

```bash
# Navigate to workspace
cd /Users/labeebmachingal/Downloads/react/cocotuft

# Activate Python Virtual Environment
source .venv/bin/activate

# Execute Automated Backend End-to-End Test Suite
PYTHONPATH=backend python -m pytest backend/tests/test_api.py -v

# Run FastAPI REST Server (Starts on http://127.0.0.1:8000)
PYTHONPATH=backend uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

### 2. Database Setup (MySQL or Standalone SQLite Fallback)

- **MySQL Execution**: Import `database/schema.sql` followed by `database/seed.sql` into MySQL Server (`cocotuft_db`).
- **SQLite Fallback**: If MySQL server is offline, FastAPI automatically initializes local `cocotuft.db` SQLite database with full master data seed.

### 3. Flutter Application Execution

```bash
# Run Flutter Web / Desktop App
$HOME/flutter/bin/flutter run -d chrome
# OR for macOS Desktop:
$HOME/flutter/bin/flutter run -d macos
```

---

## Interactive End-to-End Demo Workflow

1. **Login as Worker (`worker01` / `Demo@123`)**:
   - Select **New Production Entry** tab.
   - Select Process: `TUFTING`, Machine: `Tufting Machine 03`, Shift: `Shift 1`, Order: `PCT-298`.
   - Input Roll No: `TR-3/113/15/05`, Length: `13.5 m`, Width: `1.95 m`.
   - Observe live auto-calculation box: `26.33 m²` (or `26.32 m²` rounded).
   - Click **SAVE & SUBMIT** $\rightarrow$ Status transitions to `PENDING_APPROVAL` with Entry Number `DFT-001`.
2. **Sign Out & Login as Supervisor (`supervisor01` / `Demo@123`)**:
   - Open **Supervisor Portal**. Observe pending submission in queue.
   - Click **REVIEW & EDIT**. Modify Length from `13.5` to `14.0` $\rightarrow$ recalculated SQM updates to `27.30 m²`.
   - Click **History Icon** $\rightarrow$ Audit dialog displays Worker creation timestamp and Supervisor edit diff (`13.5` $\rightarrow$ `14.0`).
   - Click **CONFIRM & APPROVE** $\rightarrow$ Status changes to `APPROVED` and ERP status becomes `ERP_SYNCED`.
3. **Inspect Production Summary Tab**:
   - Observe read-only aggregate summary dynamically updated with approved Length (`14.0 m`) and SQM (`27.30 m²`).
