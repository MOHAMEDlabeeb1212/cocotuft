-- ==============================================================================
-- COCOTUFT PRODUCTION MANAGEMENT SYSTEM - MYSQL DATABASE SCHEMA
-- ==============================================================================
-- Section Purpose: Normalized schema specifically designed for Daily Tufting Details
-- and Tufting Production Summaries. Includes User Management fields (is_blocked)
-- and exact paper form & ERP screen fields.
-- ==============================================================================

CREATE DATABASE IF NOT EXISTS cocotuft_db;
USE cocotuft_db;

-- ------------------------------------------------------------------------------
-- 1. ROLES TABLE
-- Section Purpose: Security roles (WORKER, SUPERVISOR, ADMIN).
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS roles (
    role_id INT AUTO_INCREMENT PRIMARY KEY,
    role_name VARCHAR(50) NOT NULL UNIQUE, -- WORKER, SUPERVISOR, ADMIN
    description VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 2. USERS TABLE
-- Section Purpose: User accounts with Admin control flags (is_blocked, is_active).
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role_id INT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    is_blocked BOOLEAN DEFAULT FALSE, -- Admin user block/unblock control
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 3. PROCESSES TABLE
-- Section Purpose: Manufacturing process master table (TUFTING focus).
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS processes (
    process_id INT AUTO_INCREMENT PRIMARY KEY,
    process_code VARCHAR(20) NOT NULL UNIQUE,
    process_name VARCHAR(100) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 4. MACHINES TABLE
-- Section Purpose: Equipment machines (Tufting Machine 1, 2, 3).
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS machines (
    machine_id INT AUTO_INCREMENT PRIMARY KEY,
    process_id INT NOT NULL,
    machine_code VARCHAR(30) NOT NULL UNIQUE,
    machine_name VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (process_id) REFERENCES processes(process_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 5. SHIFTS TABLE
-- Section Purpose: Shift definitions (Shift 1, Shift 2, Shift 3).
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS shifts (
    shift_id INT AUTO_INCREMENT PRIMARY KEY,
    shift_name VARCHAR(50) NOT NULL UNIQUE,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 6. CUSTOMERS TABLE
-- Section Purpose: Customer master data (TESCO, IKEA, Pepperfry).
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS customers (
    customer_id INT AUTO_INCREMENT PRIMARY KEY,
    customer_code VARCHAR(30) NOT NULL UNIQUE,
    customer_name VARCHAR(150) NOT NULL,
    country VARCHAR(100) DEFAULT 'India',
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 7. ORDERS TABLE
-- Section Purpose: Sales Orders (S.O. e.g. PCT-298) and P.O. Number (e.g. PRDOT-446).
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS orders (
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    order_number VARCHAR(50) NOT NULL UNIQUE, -- Sales Order Number (S.O.)
    po_number VARCHAR(50),                     -- Purchase Order Number (P.O.)
    customer_id INT NOT NULL,
    base_material VARCHAR(100) DEFAULT 'Natural',
    pile_height VARCHAR(50) DEFAULT '15 MM',
    target_quantity INT DEFAULT 500,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 8. PRODUCTS TABLE
-- Section Purpose: Product catalog.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_code VARCHAR(30) NOT NULL UNIQUE,
    product_name VARCHAR(150) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 9. PRODUCTION_ENTRIES TABLE
-- Section Purpose: Header record representing Daily Tufting Details batch.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS production_entries (
    entry_id INT AUTO_INCREMENT PRIMARY KEY,
    entry_number VARCHAR(30) NOT NULL UNIQUE, -- e.g. DFT-797
    entry_date DATE NOT NULL,
    tufted_date DATE NOT NULL,
    shift_id INT NOT NULL,
    process_id INT NOT NULL,
    machine_id INT NOT NULL,
    order_id INT NOT NULL,
    customer_id INT NOT NULL,
    product_id INT,
    worker_id INT NOT NULL,
    status ENUM('DRAFT', 'SUBMITTED', 'PENDING_APPROVAL', 'REJECTED', 'APPROVED') NOT NULL DEFAULT 'DRAFT',
    erp_sync_status ENUM('ERP_SYNC_PENDING', 'ERP_SYNCED', 'ERP_SYNC_FAILED') NOT NULL DEFAULT 'ERP_SYNC_PENDING',
    erp_reference_no VARCHAR(100),
    erp_sync_message TEXT,
    erp_synced_at DATETIME,
    rejection_reason TEXT,
    supervisor_remarks TEXT,
    approved_by_user_id INT,
    approved_at DATETIME,
    last_edited_by_user_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (shift_id) REFERENCES shifts(shift_id) ON DELETE RESTRICT,
    FOREIGN KEY (process_id) REFERENCES processes(process_id) ON DELETE RESTRICT,
    FOREIGN KEY (machine_id) REFERENCES machines(machine_id) ON DELETE RESTRICT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id) ON DELETE RESTRICT,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT,
    FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE SET NULL,
    FOREIGN KEY (worker_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (approved_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    FOREIGN KEY (last_edited_by_user_id) REFERENCES users(user_id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 10. PRODUCTION_DETAILS TABLE
-- Section Purpose: Detailed line items matching exact Daily Tufting paper form & ERP screen.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS production_details (
    detail_id INT AUTO_INCREMENT PRIMARY KEY,
    entry_id INT NOT NULL UNIQUE,
    base VARCHAR(100) DEFAULT 'Natural',
    pile_height VARCHAR(50) DEFAULT '15 MM',
    sales_order_no VARCHAR(50) NOT NULL, -- S.O.
    customer_code VARCHAR(50) NOT NULL,  -- Cust. Code
    po_number VARCHAR(50) NOT NULL,       -- P.O.
    roll_number VARCHAR(100) NOT NULL,    -- Roll No.
    start_time VARCHAR(20) NOT NULL,     -- Start Time (06:00 AM)
    end_time VARCHAR(20) NOT NULL,       -- End Time (07:20 AM)
    length_meters DECIMAL(10,2) NOT NULL,
    width_meters DECIMAL(10,2) NOT NULL,
    target_qty DECIMAL(10,2) DEFAULT 500.00,
    actual_qty DECIMAL(10,2) NOT NULL,   -- Actual (SQM)
    variation DECIMAL(10,2) NOT NULL,    -- Actual - Target Qty
    balance_qty DECIMAL(10,2) NOT NULL,  -- Target Qty - Actual
    belt_speed VARCHAR(50) DEFAULT 'Normal',
    defects_a_yarn INT DEFAULT 0,
    defects_b_pvc INT DEFAULT 0,
    defects_c_tufting INT DEFAULT 0,
    defects_d_stripe INT DEFAULT 0,
    defects_e_others INT DEFAULT 0,
    machine_stop_minutes INT DEFAULT 0,
    machine_stop_reason VARCHAR(255),
    round_weight_left DECIMAL(10,2) DEFAULT 0.00,
    round_weight_center DECIMAL(10,2) DEFAULT 0.00,
    round_weight_right DECIMAL(10,2) DEFAULT 0.00,
    quality_remarks TEXT,
    factory_labour_count INT DEFAULT 1,
    contract_labour_count INT DEFAULT 0,
    shift_machine_incharge VARCHAR(100),
    shift_quality_controller VARCHAR(100),
    shift_supervisor_name VARCHAR(100),
    tufting_head VARCHAR(100),
    creel_stand VARCHAR(100),
    total_running_meter DECIMAL(10,2) DEFAULT 0.00,
    total_sqm DECIMAL(10,2) DEFAULT 0.00,
    comments TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (entry_id) REFERENCES production_entries(entry_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ------------------------------------------------------------------------------
-- 11. AUDIT_LOGS TABLE
-- Section Purpose: Immutable audit log tracking changes made by users or admins.
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    entry_id INT NOT NULL,
    changed_by_user_id INT NOT NULL,
    action VARCHAR(50) NOT NULL,
    field_name VARCHAR(100),
    old_value TEXT,
    new_value TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (entry_id) REFERENCES production_entries(entry_id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by_user_id) REFERENCES users(user_id) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
