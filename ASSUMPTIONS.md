# DOMAIN ASSUMPTIONS & ARCHITECTURAL DECISIONS - COCOTUFT SYSTEM

## 1. ERP Integration Layer Abstraction
- **Assumption**: The exact ERP API schema or database staging table specification from the company's ERP vendor (BizCare/ERP) is pending final vendor deployment documentation.
- **Architectural Implementation**: Created an explicit `ERPIntegrationService` abstraction layer. The system generates ERP reference tracking codes (`ERP-REF-YYYYMMDD-XXXX`) and tracks sync status states (`ERP_SYNC_PENDING`, `ERP_SYNCED`, `ERP_SYNC_FAILED`). When the vendor provides API endpoints, only `ERPIntegrationService.sync_approved_production()` needs to be connected to the live API without modifying application UI or production database schemas.

---

## 2. Server-Authoritative Metric Calculations
- **Assumption**: Frontend calculations can be subject to browser tampering or local client errors.
- **Architectural Implementation**: While the Flutter UI displays live preview calculations for user convenience, the FastAPI backend re-validates and re-computes `calculated_sqm = round(length * width, 2)` upon every save/update before writing to MySQL database tables.

---

## 3. Dynamic Master Data Scope
- **Assumption**: Machine configurations, process lists, customer catalogs, and shifts vary per factory plant and change over time.
- **Architectural Implementation**: Process and Machine names are driven 100% dynamically from database master tables (`processes`, `machines`). No process codes or machine names are hardcoded inside Flutter UI components.

---

## 4. Shift & Timing Defaults
- **Assumption**: Default factory operations run across 3 standard 8-hour shifts:
  - **Shift 1**: 06:00 AM - 02:00 PM
  - **Shift 2**: 02:00 PM - 10:00 PM
  - **Shift 3**: 10:00 PM - 06:00 AM
