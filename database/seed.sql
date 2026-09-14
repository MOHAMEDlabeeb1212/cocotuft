-- ==============================================================================
-- COCOTUFT PRODUCTION MANAGEMENT SYSTEM - SEED DATA
-- ==============================================================================
-- Section Purpose: Populates database with default roles, demo users (worker01,
-- supervisor01, admin01), Tufting machines, sales order PCT-298 (TESCO),
-- and reference Daily Tufting entry DFT-797 matching the ERP screenshot.
-- ==============================================================================

USE cocotuft_db;

-- 1. SEED ROLES
INSERT INTO roles (role_id, role_name, description) VALUES
(1, 'WORKER', 'Shop-floor worker entering production details'),
(2, 'SUPERVISOR', 'Supervisor confirming and reviewing entries'),
(3, 'ADMIN', 'Super administrator with full edit & user management power')
ON DUPLICATE KEY UPDATE role_name=VALUES(role_name);

-- 2. SEED USERS (Password: Demo@123)
-- Bcrypt Hash for 'Demo@123': $2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeg6Lruj3vjPGga31lW
INSERT INTO users (user_id, username, email, hashed_password, full_name, role_id, is_active, is_blocked) VALUES
(1, 'worker01', 'worker01@cocotuft.com', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeg6Lruj3vjPGga31lW', 'Rajesh Kumar (Worker)', 1, TRUE, FALSE),
(2, 'supervisor01', 'supervisor01@cocotuft.com', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeg6Lruj3vjPGga31lW', 'Thomas Joseph (Supervisor)', 2, TRUE, FALSE),
(3, 'admin01', 'admin01@cocotuft.com', '$2b$12$EixZaYVK1fsbw1ZfbX3OXePaWxn96p36WQoeg6Lruj3vjPGga31lW', 'System Administrator (Super User)', 3, TRUE, FALSE)
ON DUPLICATE KEY UPDATE full_name=VALUES(full_name);

-- 3. SEED PROCESSES
INSERT INTO processes (process_id, process_code, process_name, description) VALUES
(1, 'DFT', 'TUFTING', 'Daily Tufting details recording process')
ON DUPLICATE KEY UPDATE process_name=VALUES(process_name);

-- 4. SEED MACHINES (Tufting Machines 1, 2, 3)
INSERT INTO machines (machine_id, process_id, machine_code, machine_name) VALUES
(1, 1, 'TFT-M01', 'Tufting Machine - 1'),
(2, 1, 'TFT-M02', 'Tufting Machine - 2'),
(3, 1, 'TFT-M03', 'Tufting Machine - 3')
ON DUPLICATE KEY UPDATE machine_name=VALUES(machine_name);

-- 5. SEED SHIFTS
INSERT INTO shifts (shift_id, shift_name, start_time, end_time) VALUES
(1, 'Shift 1', '06:00:00', '14:00:00'),
(2, 'Shift 2', '14:00:00', '22:00:00'),
(3, 'Shift 3', '22:00:00', '06:00:00')
ON DUPLICATE KEY UPDATE shift_name=VALUES(shift_name);

-- 6. SEED CUSTOMERS & ORDERS (TESCO - PCT-298)
INSERT INTO customers (customer_id, customer_code, customer_name, country) VALUES
(1, 'TESCO', 'TESCO Stores International', 'United Kingdom'),
(2, 'IKEA', 'IKEA Global Sourcing', 'Sweden')
ON DUPLICATE KEY UPDATE customer_name=VALUES(customer_name);

INSERT INTO orders (order_id, order_number, po_number, customer_id, base_material, pile_height, target_quantity) VALUES
(1, 'PCT-298', 'PRDOT-446', 1, 'Natural', '15 MM', 500),
(2, 'PCT-305', 'PO-IKEA-9842', 2, 'PVC', '12 MM', 300)
ON DUPLICATE KEY UPDATE order_number=VALUES(order_number);

-- 7. SEED PRODUCTS
INSERT INTO products (product_id, product_code, product_name, description) VALUES
(1, 'PRDOT-446', 'PVC TUFTED NATURAL PLAIN MATTING', 'TESCO 2.18 X 50 M X 15 MM Matting')
ON DUPLICATE KEY UPDATE product_name=VALUES(product_name);

-- 8. SEED REFERENCE ENTRY (DFT-797 Matching ERP Screenshot)
INSERT INTO production_entries (
    entry_id, entry_number, entry_date, tufted_date, shift_id, process_id, machine_id, order_id, customer_id, product_id, worker_id, status, erp_sync_status, approved_by_user_id, approved_at, created_at
) VALUES (
    1, 'DFT-797', '2026-08-05', '2026-08-05', 1, 1, 3, 1, 1, 1, 1, 'APPROVED', 'ERP_SYNCED', 2, '2026-08-05 08:35:00', '2026-08-05 08:15:00'
) ON DUPLICATE KEY UPDATE entry_number=VALUES(entry_number);

INSERT INTO production_details (
    entry_id, base, pile_height, sales_order_no, customer_code, po_number, roll_number, start_time, end_time, length_meters, width_meters, target_qty, actual_qty, variation, balance_qty, belt_speed, defects_a_yarn, defects_b_pvc, defects_c_tufting, defects_d_stripe, defects_e_others, machine_stop_minutes, machine_stop_reason, round_weight_left, round_weight_center, round_weight_right, quality_remarks, factory_labour_count, contract_labour_count, shift_machine_incharge, shift_quality_controller, shift_supervisor_name, tufting_head, creel_stand, total_running_meter, total_sqm, comments
) VALUES (
    1, 'Natural', '15 MM', 'PCT-298', 'TESCO', 'PRDOT-446', 'TF-3/1113/N15/05-08-2026/F1', '06:00 AM', '07:20 AM', 13.50, 1.95, 500.00, 26.33, -473.67, 473.67, 'Normal', 0, 0, 0, 0, 0, 5, 'Tension adjustment', 14.00, 14.50, 14.00, 'Passed quality inspection', 4, 2, 'K. Ramesh', 'P. Shaji', 'Thomas Joseph', 'Head A', 'Creel 03', 13.50, 26.33, 'Production completed cleanly'
) ON DUPLICATE KEY UPDATE roll_number=VALUES(roll_number);

INSERT INTO audit_logs (entry_id, changed_by_user_id, action, field_name, old_value, new_value, created_at) VALUES
(1, 1, 'CREATED', 'Status', NULL, 'SUBMITTED', '2026-08-05 08:15:00'),
(1, 2, 'APPROVED', 'Status', 'PENDING_APPROVAL', 'APPROVED', '2026-08-05 08:35:00');
