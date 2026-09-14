# REQUIREMENTS DOCUMENT - COCOTUFT PRODUCTION MANAGEMENT SYSTEM

## 1. Primary System Objective
Digitize the manual paper-based production entry workflow for **COCOTUFT** mat manufacturing plant. Replace hand-written daily logs with a high-reliability, role-governed digital web/desktop/mobile platform that enforces supervisor verification, field-level audit trails, dynamic production summaries, and ERP synchronization abstraction.

---

## 2. User Roles & Access Matrix (RBAC)

| Permission / Action | WORKER | SUPERVISOR | ADMIN |
| :--- | :---: | :---: | :---: |
| Authenticate / Login | Yes | Yes | Yes |
| View Personal Dashboard & History | Yes | Yes | Yes |
| Create New Production Entry (Draft/Submit) | Yes | Yes | Yes |
| Edit Own Draft / Rejected Entries | Yes | Yes | Yes |
| Edit Submitted Entries Prior to Approval | No | **Yes (Audited)** | **Yes (Audited)** |
| Approve / Confirm Production Record | **No** | **Yes** | **Yes** |
| Reject Production Record (With Reason) | **No** | **Yes** | **Yes** |
| View Field-Level Audit Trail | Yes | Yes | Yes |
| View Read-Only Production Summary | Yes | Yes | Yes |
| Modify Dynamic Calculated Summary Totals | **No** | **No** | **No** |
| Manage System Master Data & Users | No | No | **Yes** |

---

## 3. Manufacturing Processes & Dynamic Master Data
The system supports multiple manufacturing processes without hardcoding machine names in client UIs:
1. **MIXING**: Mixing Machine 01, Mixing Machine 02
2. **CUTTING**: Cutting Machine 01, Cutting Machine 02
3. **SHEARING**: Shearing Machine 01, Shearing Machine 02
4. **TUFTING**: Tufting Machine 01, Tufting Machine 02, Tufting Machine 03

Machines are linked dynamically to their parent process in the database (`processes` $\rightarrow$ `machines`). Admins can add, edit, or deactivate machines dynamically without code modifications.

---

## 4. Production Form Field Terminology & ERP Mapping
Extracted from legacy paper forms (*Daily Tufting Details*) and ERP screen (*BizCare ERP Daily Tufting*):
- **Entry Number**: Sequential code (`DFT-001`, `MIX-001`)
- **Date & Shift**: Production date and active shift (Shift 1, Shift 2, Shift 3)
- **Order Information**: Sales Order (S.O. e.g. `PCT-298`), Customer P.O., Customer Code, Base Material, Pile Height (mm)
- **Roll Details**: Roll Number (e.g. `TR-3/113/15/05`), Start Time, End Time, Length (m), Width (m)
- **Calculated Metrics**: Square Meters ($\text{SQM} = \text{Length} \times \text{Width}$)
- **Quality Metrics**: Defects Count, Machine Stop Time (mins), Stop Reason, Round Weight (kg), Belt Speed, Quality Remarks
- **Shop-Floor Personnel**: Machine In-charge, Quality Controller, Shift Supervisor, Tufting Head, Creel Stand

---

## 5. Workflow State Machine

```
[ DRAFT ] ──────────► [ SUBMITTED / PENDING_APPROVAL ]
                             │
            ┌────────────────┴────────────────┐
            ▼                                 ▼
      [ REJECTED ]                      [ APPROVED ]
(Sent back to worker)                         │
                                              ▼
                                   [ ERP_SYNC_PENDING ]
                                              │
                                              ▼
                                      [ ERP_SYNCED ]
```

---

## 6. Auditability & Summary Rules
- **Audit Logging**: Every creation, field edit, approval, or rejection MUST write an immutable `AuditLog` row recording user ID, timestamp, action type, field name, old value, and new value.
- **Summary Totals**: Production summaries MUST be read-only aggregations calculated directly from database records (`SUM(length_meters)`, `SUM(calculated_sqm)`). No user (worker, supervisor, or admin) may manually edit summary numbers.
