-- ======================================================================================
-- GYMCONNECT ENTERPRISE SAAS - MASTER SUPABASE POSTGRESQL SCHEMA
-- Complete One-Go Run Script with Multi-Tenancy, PostGIS, IoT Access Control,
-- POS & Khata, AI Workout Engine, Gamification, Immutable Audit Watchdog & RLS.
-- ======================================================================================

-- --------------------------------------------------------------------------------------
-- 1. EXTENSIONS
-- --------------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- --------------------------------------------------------------------------------------
-- 2. CUSTOM ENUMS & TYPES
-- --------------------------------------------------------------------------------------
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM (
        'super_admin',
        'gym_owner',
        'staff',
        'member',
        'public_user'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE tenant_subscription_status AS ENUM (
        'trial',
        'active',
        'past_due',
        'suspended',
        'cancelled'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE member_sub_status AS ENUM (
        'active',
        'expired',
        'frozen',
        'cancelled',
        'pending_payment'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE invoice_status AS ENUM (
        'paid',
        'partial',
        'unpaid',
        'voided'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE payment_method AS ENUM (
        'cash',
        'credit_card',
        'debit_card',
        'jazzcash',
        'easypaisa',
        'stripe',
        'khata_credit',
        'split'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE gate_verification_method AS ENUM (
        'dynamic_qr',
        'fingerprint',
        'guest_pass',
        'manual_reception',
        'mobile_shake'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE gate_access_result AS ENUM (
        'granted',
        'denied'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE hardware_device_type AS ENUM (
        'esp32_gate_relay',
        'gate_display_screen',
        'fingerprint_scanner',
        'pos_terminal',
        'barcode_scanner'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE inventory_tx_type AS ENUM (
        'purchase_restock',
        'pos_sale',
        'damaged_writeoff',
        'manual_adjustment',
        'return'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE body_type_enum AS ENUM (
        'ectomorph',
        'mesomorph',
        'endomorph'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE fitness_goal_enum AS ENUM (
        'muscle_gain',
        'fat_loss',
        'strength',
        'endurance',
        'general_fitness'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE store_order_status AS ENUM (
        'pending',
        'confirmed',
        'ready_for_pickup',
        'completed',
        'cancelled'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE pos_shift_status AS ENUM (
        'open',
        'closed'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE guest_pass_status AS ENUM (
        'active',
        'used',
        'expired',
        'revoked'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- --------------------------------------------------------------------------------------
-- 3. CORE TENANCY & USERS
-- --------------------------------------------------------------------------------------

-- 3.1 Tenants Table (Gym Locations & SaaS Tenants)
CREATE TABLE IF NOT EXISTS tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    contact_email VARCHAR(255),
    contact_phone VARCHAR(50),
    address TEXT,
    city VARCHAR(100),
    country VARCHAR(100) DEFAULT 'Pakistan',
    location GEOGRAPHY(Point, 4326), -- PostGIS coordinates for Airbnb-style discovery
    branding JSONB DEFAULT '{
        "primary_color": "#CCFF00",
        "surface_color": "#18181B",
        "background_color": "#09090B",
        "logo_url": null,
        "tagline": null
    }'::jsonb,
    subscription_status tenant_subscription_status DEFAULT 'trial',
    subscription_tier VARCHAR(50) DEFAULT 'pro',
    max_members INT DEFAULT 500,
    features JSONB DEFAULT '{
        "ai_trainer_enabled": true,
        "pos_enabled": true,
        "esp32_gate_enabled": true,
        "store_enabled": true
    }'::jsonb,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.2 Profiles Table (Mapped to Supabase auth.users)
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE, -- NULL strictly for super_admin
    role user_role NOT NULL DEFAULT 'member',
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    avatar_url TEXT,
    device_id VARCHAR(255), -- Anti-cheat single-device lock for mobile app
    biometric_enabled BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    raw_user_meta JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.3 Impersonation Logs (Super Admin God Mode Engine)
CREATE TABLE IF NOT EXISTS impersonation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    super_admin_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    target_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ
);

-- --------------------------------------------------------------------------------------
-- 4. MEMBERSHIPS, SUBSCRIPTIONS & GUEST PASSES
-- --------------------------------------------------------------------------------------

-- 4.1 Membership Plans
CREATE TABLE IF NOT EXISTS membership_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    name VARCHAR(150) NOT NULL,
    description TEXT,
    duration_days INT NOT NULL, -- e.g. 30 (monthly), 90 (quarterly), 365 (annual)
    price NUMERIC(12, 2) NOT NULL CHECK (price >= 0),
    signup_fee NUMERIC(12, 2) DEFAULT 0.00 CHECK (signup_fee >= 0),
    has_classes BOOLEAN DEFAULT FALSE,
    has_trainer_access BOOLEAN DEFAULT TRUE,
    freeze_allowance_days INT DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4.2 Member Subscriptions
CREATE TABLE IF NOT EXISTS member_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    plan_id UUID NOT NULL REFERENCES membership_plans(id) ON DELETE RESTRICT,
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE NOT NULL,
    status member_sub_status NOT NULL DEFAULT 'active',
    freeze_start_date DATE,
    freeze_end_date DATE,
    auto_renew BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT valid_dates CHECK (end_date >= start_date)
);

-- 4.3 24-Hour Temporary Guest Passes (Marketplace Frictionless Conversion)
CREATE TABLE IF NOT EXISTS guest_passes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE SET NULL, -- Public user if registered
    guest_name VARCHAR(150) NOT NULL,
    guest_phone VARCHAR(50) NOT NULL,
    guest_email VARCHAR(255),
    qr_code_hash VARCHAR(255) UNIQUE NOT NULL,
    issued_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ NOT NULL, -- Defaults to issued_at + 24 hours
    status guest_pass_status NOT NULL DEFAULT 'active',
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- --------------------------------------------------------------------------------------
-- 5. HARDWARE IOT ACCESS CONTROL & ATTENDANCE
-- --------------------------------------------------------------------------------------

-- 5.1 Gym Hardware Devices (ESP32 Gate Relay, Gate Display, Scanners)
CREATE TABLE IF NOT EXISTS gym_devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    device_name VARCHAR(150) NOT NULL,
    device_type hardware_device_type NOT NULL,
    api_key_hash VARCHAR(255) NOT NULL,
    ip_address VARCHAR(45),
    mac_address VARCHAR(50),
    is_online BOOLEAN DEFAULT TRUE,
    last_heartbeat TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.2 Dynamic 10-Second QR Tokens (Anti-Sharing Gate Lock)
CREATE TABLE IF NOT EXISTS gate_access_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) UNIQUE NOT NULL,
    device_id VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    is_used BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5.3 Attendance Check-in Logs
CREATE TABLE IF NOT EXISTS attendance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    member_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    guest_pass_id UUID REFERENCES guest_passes(id) ON DELETE SET NULL,
    gate_device_id UUID REFERENCES gym_devices(id) ON DELETE SET NULL,
    check_in_time TIMESTAMPTZ DEFAULT NOW(),
    check_out_time TIMESTAMPTZ,
    verification_method gate_verification_method NOT NULL,
    access_result gate_access_result NOT NULL DEFAULT 'granted',
    denial_reason VARCHAR(255),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- --------------------------------------------------------------------------------------
-- 6. POS, BILLING, SPLIT PAYMENTS, KHATA & INVENTORY
-- --------------------------------------------------------------------------------------

-- 6.1 POS Shift Management & Z-Reports
CREATE TABLE IF NOT EXISTS pos_shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    staff_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    opened_at TIMESTAMPTZ DEFAULT NOW(),
    closed_at TIMESTAMPTZ,
    opening_cash NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    closing_cash NUMERIC(12, 2),
    expected_cash NUMERIC(12, 2) DEFAULT 0.00,
    discrepancy NUMERIC(12, 2) DEFAULT 0.00,
    total_sales_cash NUMERIC(12, 2) DEFAULT 0.00,
    total_sales_card NUMERIC(12, 2) DEFAULT 0.00,
    total_sales_online NUMERIC(12, 2) DEFAULT 0.00,
    total_khata_credit NUMERIC(12, 2) DEFAULT 0.00,
    total_petty_cash NUMERIC(12, 2) DEFAULT 0.00,
    status pos_shift_status NOT NULL DEFAULT 'open',
    z_report_summary JSONB DEFAULT '{}'::jsonb,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6.2 Petty Cash Expenses
CREATE TABLE IF NOT EXISTS petty_cash_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    shift_id UUID REFERENCES pos_shifts(id) ON DELETE SET NULL,
    staff_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    category VARCHAR(100) NOT NULL,
    reason TEXT NOT NULL,
    receipt_photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6.3 Products & Supplements Inventory
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    barcode VARCHAR(100),
    sku VARCHAR(100),
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL, -- Supplements, Drinks, Gear, Apparel
    description TEXT,
    cost_price NUMERIC(12, 2) NOT NULL DEFAULT 0.00 CHECK (cost_price >= 0),
    selling_price NUMERIC(12, 2) NOT NULL CHECK (selling_price >= 0),
    stock_quantity INT NOT NULL DEFAULT 0,
    min_stock_alert_threshold INT DEFAULT 5,
    image_url TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_tenant_barcode UNIQUE (tenant_id, barcode),
    CONSTRAINT uq_tenant_sku UNIQUE (tenant_id, sku)
);

-- 6.4 Inventory Transactions (Audit trail for every stock change)
CREATE TABLE IF NOT EXISTS inventory_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    change_quantity INT NOT NULL, -- Positive for restock, negative for sale
    transaction_type inventory_tx_type NOT NULL,
    reference_id UUID, -- e.g. invoice_id or order_id
    notes TEXT,
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6.5 Invoices
CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    shift_id UUID REFERENCES pos_shifts(id) ON DELETE SET NULL,
    invoice_number VARCHAR(100) NOT NULL,
    member_id UUID REFERENCES profiles(id) ON DELETE SET NULL, -- Nullable for drop-in walkin customer
    customer_name VARCHAR(150),
    customer_phone VARCHAR(50),
    subtotal NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    discount_amount NUMERIC(12, 2) DEFAULT 0.00,
    tax_amount NUMERIC(12, 2) DEFAULT 0.00,
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    paid_amount NUMERIC(12, 2) DEFAULT 0.00,
    due_amount NUMERIC(12, 2) DEFAULT 0.00,
    status invoice_status NOT NULL DEFAULT 'unpaid',
    created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    voided_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    voided_at TIMESTAMPTZ,
    void_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_tenant_invoice_num UNIQUE (tenant_id, invoice_number)
);

-- 6.6 Invoice Items
CREATE TABLE IF NOT EXISTS invoice_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    item_type VARCHAR(50) NOT NULL, -- 'membership', 'product', 'drop_in_fee', 'personal_training'
    product_id UUID REFERENCES products(id) ON DELETE SET NULL,
    plan_id UUID REFERENCES membership_plans(id) ON DELETE SET NULL,
    description TEXT NOT NULL,
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    total_price NUMERIC(12, 2) NOT NULL CHECK (total_price >= 0)
);

-- 6.7 Payments (Split Payment, Online, Cash)
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    invoice_id UUID NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    member_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    payment_method payment_method NOT NULL,
    transaction_reference VARCHAR(255),
    payment_gateway_response JSONB DEFAULT '{}'::jsonb,
    collected_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6.8 Member Khata Ledger (Udhaar / Credit Management)
CREATE TABLE IF NOT EXISTS member_khata_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
    transaction_type VARCHAR(20) NOT NULL CHECK (transaction_type IN ('debit', 'credit')),
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    running_balance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    description TEXT NOT NULL,
    recorded_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- --------------------------------------------------------------------------------------
-- 7. VIRTUAL AI TRAINER & WORKOUT ENGINE
-- --------------------------------------------------------------------------------------

-- 7.1 User Fitness Profiles & Goals
CREATE TABLE IF NOT EXISTS user_fitness_profiles (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    height_cm NUMERIC(5, 2),
    current_weight_kg NUMERIC(5, 2),
    target_weight_kg NUMERIC(5, 2),
    body_type body_type_enum NOT NULL DEFAULT 'mesomorph',
    fitness_goal fitness_goal_enum NOT NULL DEFAULT 'general_fitness',
    experience_level VARCHAR(50) DEFAULT 'beginner', -- beginner, intermediate, advanced
    medical_notes TEXT,
    preferred_days_per_week INT DEFAULT 4 CHECK (preferred_days_per_week BETWEEN 1 AND 7),
    ai_recommendations JSONB DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7.2 Exercise Library
CREATE TABLE IF NOT EXISTS exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE, -- NULL = Global Library
    name VARCHAR(255) NOT NULL,
    target_muscle VARCHAR(100) NOT NULL, -- Chest, Back, Legs, Shoulders, Biceps, Triceps, Core
    secondary_muscles TEXT[],
    equipment VARCHAR(100) NOT NULL, -- Barbell, Dumbbell, Machine, Cable, Bodyweight
    difficulty VARCHAR(50) DEFAULT 'intermediate',
    video_url TEXT, -- Vercel Blob / Supabase Storage PIP video link
    thumbnail_url TEXT,
    instructions JSONB DEFAULT '[]'::jsonb,
    tips TEXT,
    is_global BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7.3 90-Day Workout Calendar Routines
CREATE TABLE IF NOT EXISTS workout_routines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE, -- NULL = Global AI Program
    title VARCHAR(255) NOT NULL,
    description TEXT,
    target_goal fitness_goal_enum NOT NULL,
    duration_days INT NOT NULL DEFAULT 90,
    is_ai_generated BOOLEAN DEFAULT FALSE,
    is_public_preview BOOLEAN DEFAULT FALSE, -- FOMO engine preview for public
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7.4 Daily Workout Routines (e.g. Day 1, Day 2 ... Day 90)
CREATE TABLE IF NOT EXISTS workout_routine_days (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    routine_id UUID NOT NULL REFERENCES workout_routines(id) ON DELETE CASCADE,
    day_number INT NOT NULL CHECK (day_number BETWEEN 1 AND 365),
    title VARCHAR(150) NOT NULL, -- e.g. "Day 1: Chest & Triceps Blitz"
    muscle_groups TEXT[],
    is_rest_day BOOLEAN DEFAULT FALSE,
    CONSTRAINT uq_routine_day UNIQUE (routine_id, day_number)
);

-- 7.5 Day Exercises & Sets Configuration
CREATE TABLE IF NOT EXISTS workout_day_exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    day_id UUID NOT NULL REFERENCES workout_routine_days(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    order_index INT NOT NULL DEFAULT 1,
    target_sets INT NOT NULL DEFAULT 3,
    target_reps_range VARCHAR(50) DEFAULT '8-12',
    rest_seconds INT DEFAULT 60, -- Haptic feedback vibration trigger on countdown zero
    superset_group_id INT, -- For pairing Chest -> Triceps superset
    notes TEXT
);

-- 7.6 Member Workout Logs
CREATE TABLE IF NOT EXISTS workout_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    routine_day_id UUID REFERENCES workout_routine_days(id) ON DELETE SET NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    total_duration_minutes INT,
    total_volume_kg NUMERIC(10, 2) DEFAULT 0.00,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7.7 Member Workout Sets Log (Progressive Overload & PRs)
CREATE TABLE IF NOT EXISTS workout_set_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    workout_log_id UUID NOT NULL REFERENCES workout_logs(id) ON DELETE CASCADE,
    exercise_id UUID NOT NULL REFERENCES exercises(id) ON DELETE CASCADE,
    set_number INT NOT NULL,
    reps_completed INT NOT NULL CHECK (reps_completed >= 0),
    weight_kg NUMERIC(6, 2) NOT NULL DEFAULT 0.00,
    rpe NUMERIC(3, 1), -- Rate of Perceived Exertion (1 to 10)
    is_personal_record BOOLEAN DEFAULT FALSE, -- PR Confetti animation trigger
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- --------------------------------------------------------------------------------------
-- 8. GAMIFICATION, HEALTH SYNC, REVIEWS & IN-APP STORE
-- --------------------------------------------------------------------------------------

-- 8.1 Member Gamification & Health Tracker
CREATE TABLE IF NOT EXISTS member_gamification (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    current_streak_days INT DEFAULT 0,
    longest_streak_days INT DEFAULT 0,
    total_points INT DEFAULT 0,
    weekly_points INT DEFAULT 0,
    daily_steps INT DEFAULT 0, -- Apple Health, Google Fit & Live Pedometer sync
    daily_distance_km NUMERIC(6, 2) DEFAULT 0.00 CHECK (daily_distance_km >= 0),
    daily_calories_burned INT DEFAULT 0 CHECK (daily_calories_burned >= 0),
    daily_step_goal INT DEFAULT 10000 CHECK (daily_step_goal > 0),
    last_activity_date DATE DEFAULT CURRENT_DATE,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8.2 Daily Step Logs (Live Pedometer & Health Analytics History)
CREATE TABLE IF NOT EXISTS daily_step_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    step_count INT NOT NULL DEFAULT 0 CHECK (step_count >= 0),
    distance_km NUMERIC(6, 2) NOT NULL DEFAULT 0.00 CHECK (distance_km >= 0),
    calories_burned INT NOT NULL DEFAULT 0 CHECK (calories_burned >= 0),
    active_duration_minutes INT DEFAULT 0 CHECK (active_duration_minutes >= 0),
    step_goal INT DEFAULT 10000 CHECK (step_goal > 0),
    source VARCHAR(50) DEFAULT 'live_pedometer', -- 'live_pedometer', 'google_fit', 'apple_health', 'manual'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_member_daily_step UNIQUE (user_id, log_date)
);

-- 8.3 Achievement Badges
CREATE TABLE IF NOT EXISTS badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(100) UNIQUE NOT NULL,
    title VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    icon_url TEXT,
    points_reward INT DEFAULT 50,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8.4 User Badges
CREATE TABLE IF NOT EXISTS user_badges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    badge_id UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
    earned_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_user_badge UNIQUE (user_id, badge_id)
);

-- 8.5 Transformation Feed (Community & Motivation)
CREATE TABLE IF NOT EXISTS transformation_posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL,
    story TEXT NOT NULL,
    before_image_url TEXT,
    after_image_url TEXT,
    video_url TEXT,
    stats JSONB DEFAULT '{}'::jsonb, -- e.g. {"weight_lost_kg": 15, "months": 6}
    likes_count INT DEFAULT 0,
    is_approved BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8.6 Verified Gym Reviews (Locked strictly to enrolled gym members)
CREATE TABLE IF NOT EXISTS gym_reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_title VARCHAR(150),
    review_text TEXT NOT NULL,
    is_verified_member BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_member_gym_review UNIQUE (tenant_id, member_id)
);

-- 8.7 In-App Store Orders (In-Gym Pickup)
CREATE TABLE IF NOT EXISTS store_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    member_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    pickup_code VARCHAR(10) NOT NULL, -- 6-digit counter pickup code
    order_status store_order_status NOT NULL DEFAULT 'pending',
    total_amount NUMERIC(12, 2) NOT NULL CHECK (total_amount >= 0),
    is_paid BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8.8 In-App Store Order Items
CREATE TABLE IF NOT EXISTS store_order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES store_orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES products(id) ON DELETE RESTRICT,
    quantity INT NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price NUMERIC(12, 2) NOT NULL CHECK (unit_price >= 0),
    total_price NUMERIC(12, 2) NOT NULL CHECK (total_price >= 0)
);

-- --------------------------------------------------------------------------------------
-- 9. AUDIT LOG WATCHDOG & ANTI-THEFT ALERTS
-- --------------------------------------------------------------------------------------

-- 9.1 Immutable Audit Logs (Watches all CRUD operations)
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL, -- INSERT, UPDATE, DELETE, VOID, OVERRIDE
    table_name VARCHAR(100) NOT NULL,
    record_id VARCHAR(100) NOT NULL,
    old_data JSONB,
    new_data JSONB,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9.2 Anti-Theft Real-time Push Alerts for Gym Owner
CREATE TABLE IF NOT EXISTS anti_theft_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    alert_type VARCHAR(100) NOT NULL, -- 'invoice_voided', 'cash_drawer_anomaly', 'gate_forced_open'
    severity VARCHAR(50) DEFAULT 'warning', -- 'info', 'warning', 'critical'
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    details JSONB DEFAULT '{}'::jsonb,
    is_resolved BOOLEAN DEFAULT FALSE,
    resolved_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- --------------------------------------------------------------------------------------
-- 10. INDEXES FOR HIGH-PERFORMANCE QUERYING
-- --------------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_tenants_location ON tenants USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_tenants_slug ON tenants(slug);
CREATE INDEX IF NOT EXISTS idx_profiles_tenant ON profiles(tenant_id);
CREATE INDEX IF NOT EXISTS idx_profiles_role ON profiles(role);
CREATE INDEX IF NOT EXISTS idx_profiles_device ON profiles(device_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_member ON member_subscriptions(member_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_tenant_status ON member_subscriptions(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_attendance_tenant_time ON attendance_logs(tenant_id, check_in_time DESC);
CREATE INDEX IF NOT EXISTS idx_gate_tokens_hash ON gate_access_tokens(token_hash);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(tenant_id, barcode);
CREATE INDEX IF NOT EXISTS idx_invoices_tenant_status ON invoices(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_invoices_member ON invoices(member_id);
CREATE INDEX IF NOT EXISTS idx_khata_member ON member_khata_ledger(member_id);
CREATE INDEX IF NOT EXISTS idx_workout_logs_user ON workout_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_set_logs_ex ON workout_set_logs(exercise_id);
CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_table ON audit_logs(tenant_id, table_name);
CREATE INDEX IF NOT EXISTS idx_step_logs_user_date ON daily_step_logs(user_id, log_date DESC);
CREATE INDEX IF NOT EXISTS idx_step_logs_tenant_date ON daily_step_logs(tenant_id, log_date DESC);

-- --------------------------------------------------------------------------------------
-- 11. AUTOMATED FUNCTIONS & TRIGGERS
-- --------------------------------------------------------------------------------------

-- 11.1 Trigger Function: Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION trigger_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply updated_at triggers
DO $$
DECLARE
    tbl TEXT;
BEGIN
    FOR tbl IN
        SELECT unnest(ARRAY[
            'tenants', 'profiles', 'membership_plans', 'member_subscriptions',
            'gym_devices', 'pos_shifts', 'products', 'invoices',
            'workout_routines', 'gym_reviews', 'store_orders',
            'daily_step_logs', 'member_gamification'
        ])
    LOOP
        EXECUTE format('
            DROP TRIGGER IF EXISTS trg_set_updated_at ON %I;
            CREATE TRIGGER trg_set_updated_at
            BEFORE UPDATE ON %I
            FOR EACH ROW EXECUTE FUNCTION trigger_set_updated_at();
        ', tbl, tbl);
    END LOOP;
END $$;

-- 11.2 Trigger: Sync auth.users with public.profiles
CREATE OR REPLACE FUNCTION handle_new_user_signup()
RETURNS TRIGGER AS $$
DECLARE
    default_tenant UUID;
    req_role user_role := 'member';
BEGIN
    -- Extract tenant_id and role from raw_user_meta_data if passed during signup
    IF NEW.raw_user_meta_data ->> 'tenant_id' IS NOT NULL THEN
        default_tenant := (NEW.raw_user_meta_data ->> 'tenant_id')::UUID;
    END IF;

    IF NEW.raw_user_meta_data ->> 'role' IS NOT NULL THEN
        req_role := (NEW.raw_user_meta_data ->> 'role')::user_role;
    END IF;

    INSERT INTO public.profiles (
        id,
        tenant_id,
        role,
        full_name,
        email,
        phone,
        avatar_url,
        device_id,
        raw_user_meta
    ) VALUES (
        NEW.id,
        default_tenant,
        req_role,
        COALESCE(NEW.raw_user_meta_data ->> 'full_name', split_part(NEW.email, '@', 1)),
        NEW.email,
        NEW.raw_user_meta_data ->> 'phone',
        NEW.raw_user_meta_data ->> 'avatar_url',
        NEW.raw_user_meta_data ->> 'device_id',
        NEW.raw_user_meta_data
    )
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        full_name = EXCLUDED.full_name,
        updated_at = NOW();

    -- Create initial gamification record for member
    IF req_role = 'member' AND default_tenant IS NOT NULL THEN
        INSERT INTO public.member_gamification (user_id, tenant_id)
        VALUES (NEW.id, default_tenant)
        ON CONFLICT (user_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION handle_new_user_signup();

-- 11.3 Trigger: Anti-Theft Alert on Voided Invoice
CREATE OR REPLACE FUNCTION trigger_invoice_voided_alert()
RETURNS TRIGGER AS $$
DECLARE
    v_staff_name TEXT := 'Staff';
BEGIN
    IF (OLD.status != 'voided' AND NEW.status = 'voided') THEN
        IF NEW.voided_by IS NOT NULL THEN
            SELECT full_name INTO v_staff_name FROM profiles WHERE id = NEW.voided_by;
        END IF;

        INSERT INTO anti_theft_alerts (
            tenant_id,
            alert_type,
            severity,
            title,
            message,
            details
        ) VALUES (
            NEW.tenant_id,
            'invoice_voided',
            'critical',
            'Invoice #' || NEW.invoice_number || ' Voided!',
            'Invoice of amount Rs. ' || NEW.total_amount || ' was voided by ' || v_staff_name || '. Reason: ' || COALESCE(NEW.void_reason, 'No reason given'),
            jsonb_build_object(
                'invoice_id', NEW.id,
                'invoice_number', NEW.invoice_number,
                'total_amount', NEW.total_amount,
                'voided_by', NEW.voided_by,
                'void_reason', NEW.void_reason,
                'voided_at', NEW.voided_at
            )
        );

        -- Also write to audit_logs
        INSERT INTO audit_logs (
            tenant_id,
            actor_id,
            action,
            table_name,
            record_id,
            old_data,
            new_data
        ) VALUES (
            NEW.tenant_id,
            NEW.voided_by,
            'VOID_INVOICE',
            'invoices',
            NEW.id::TEXT,
            to_jsonb(OLD),
            to_jsonb(NEW)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_invoice_voided_alert ON invoices;
CREATE TRIGGER trg_invoice_voided_alert
AFTER UPDATE ON invoices
FOR EACH ROW EXECUTE FUNCTION trigger_invoice_voided_alert();

-- 11.4 Trigger: Auto-decrement Inventory on POS Invoice Item Insert
CREATE OR REPLACE FUNCTION trigger_inventory_pos_sale()
RETURNS TRIGGER AS $$
BEGIN
    IF (NEW.item_type = 'product' AND NEW.product_id IS NOT NULL) THEN
        -- Decrease product stock
        UPDATE products
        SET stock_quantity = stock_quantity - NEW.quantity
        WHERE id = NEW.product_id;

        -- Record stock movement audit
        INSERT INTO inventory_transactions (
            tenant_id,
            product_id,
            change_quantity,
            transaction_type,
            reference_id,
            notes
        ) VALUES (
            NEW.tenant_id,
            NEW.product_id,
            -NEW.quantity,
            'pos_sale',
            NEW.invoice_id,
            'Sold via Invoice #' || (SELECT invoice_number FROM invoices WHERE id = NEW.invoice_id)
        );

        -- Check for low stock alert
        IF EXISTS (
            SELECT 1 FROM products
            WHERE id = NEW.product_id AND stock_quantity <= min_stock_alert_threshold
        ) THEN
            INSERT INTO anti_theft_alerts (
                tenant_id,
                alert_type,
                severity,
                title,
                message,
                details
            )
            SELECT
                p.tenant_id,
                'low_stock_warning',
                'warning',
                'Low Stock Alert: ' || p.name,
                'Current stock for ' || p.name || ' is down to ' || p.stock_quantity || ' units.',
                jsonb_build_object('product_id', p.id, 'current_stock', p.stock_quantity)
            FROM products p
            WHERE p.id = NEW.product_id;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_inventory_pos_sale ON invoice_items;
CREATE TRIGGER trg_inventory_pos_sale
AFTER INSERT ON invoice_items
FOR EACH ROW EXECUTE FUNCTION trigger_inventory_pos_sale();

-- 11.5 Trigger: Member Khata Ledger Running Balance Recalculation
CREATE OR REPLACE FUNCTION trigger_khata_running_balance()
RETURNS TRIGGER AS $$
DECLARE
    v_last_balance NUMERIC(12, 2) := 0.00;
BEGIN
    -- Get latest running balance for this member
    SELECT COALESCE(running_balance, 0.00) INTO v_last_balance
    FROM member_khata_ledger
    WHERE member_id = NEW.member_id AND tenant_id = NEW.tenant_id AND id != NEW.id
    ORDER BY created_at DESC, id DESC
    LIMIT 1;

    IF NEW.transaction_type = 'debit' THEN
        -- Member took udhaar/credit (owes more money)
        NEW.running_balance := v_last_balance + NEW.amount;
    ELSE
        -- Member paid off dues (owes less money)
        NEW.running_balance := v_last_balance - NEW.amount;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_khata_running_balance ON member_khata_ledger;
CREATE TRIGGER trg_khata_running_balance
BEFORE INSERT ON member_khata_ledger
FOR EACH ROW EXECUTE FUNCTION trigger_khata_running_balance();

-- 11.6 Trigger: Sync Daily Step Logs to Member Gamification & Milestone Badges
CREATE OR REPLACE FUNCTION trigger_sync_daily_step_log()
RETURNS TRIGGER AS $$
BEGIN
    -- Sync today's steps with current member_gamification snapshot
    IF NEW.log_date = CURRENT_DATE THEN
        UPDATE member_gamification
        SET
            daily_steps = NEW.step_count,
            daily_distance_km = NEW.distance_km,
            daily_calories_burned = NEW.calories_burned,
            daily_step_goal = NEW.step_goal,
            last_activity_date = NEW.log_date,
            updated_at = NOW()
        WHERE user_id = NEW.user_id;
    END IF;

    -- Award badge if member hits 10,000 steps
    IF NEW.step_count >= 10000 THEN
        INSERT INTO user_badges (user_id, badge_id)
        SELECT NEW.user_id, b.id
        FROM badges b
        WHERE b.code = 'step_master_10k'
        ON CONFLICT (user_id, badge_id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_sync_daily_step_log ON daily_step_logs;
CREATE TRIGGER trg_sync_daily_step_log
AFTER INSERT OR UPDATE ON daily_step_logs
FOR EACH ROW EXECUTE FUNCTION trigger_sync_daily_step_log();

-- --------------------------------------------------------------------------------------
-- 12. RPC STORED PROCEDURES (GATE ACCESS & MARKETPLACE DISCOVERY)
-- --------------------------------------------------------------------------------------

-- 12.1 RPC: Verify Token and Open Gate (Called by ESP32 / Secondary Screen)
CREATE OR REPLACE FUNCTION verify_and_open_gate(
    p_tenant_id UUID,
    p_token_or_code VARCHAR,
    p_method gate_verification_method,
    p_device_id VARCHAR DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_member_id UUID;
    v_guest_pass_id UUID;
    v_member_name TEXT := 'Guest';
    v_active_sub RECORD;
    v_token_rec RECORD;
    v_guest_rec RECORD;
BEGIN
    -- 1. Dynamic QR Method
    IF p_method = 'dynamic_qr' OR p_method = 'mobile_shake' THEN
        SELECT * INTO v_token_rec
        FROM gate_access_tokens
        WHERE token_hash = p_token_or_code
          AND tenant_id = p_tenant_id
          AND is_used = FALSE
          AND expires_at >= NOW();

        IF NOT FOUND THEN
            INSERT INTO attendance_logs (
                tenant_id, verification_method, access_result, denial_reason
            ) VALUES (
                p_tenant_id, p_method, 'denied', 'Invalid or expired dynamic QR token'
            );
            RETURN jsonb_build_object(
                'success', FALSE,
                'unlock_signal', FALSE,
                'message', 'Invalid or expired QR. Shake phone for fresh code.'
            );
        END IF;

        v_member_id := v_token_rec.member_id;

        -- Verify device ID lock (Anti-sharing)
        IF p_device_id IS NOT NULL AND v_token_rec.device_id != p_device_id THEN
            INSERT INTO attendance_logs (
                tenant_id, member_id, verification_method, access_result, denial_reason
            ) VALUES (
                p_tenant_id, v_member_id, p_method, 'denied', 'Device ID Mismatch (Unauthorized sharing detected)'
            );
            RETURN jsonb_build_object(
                'success', FALSE,
                'unlock_signal', FALSE,
                'message', 'Device lock violation! Account sharing is forbidden.'
            );
        END IF;

        -- Verify Active Subscription
        SELECT * INTO v_active_sub
        FROM member_subscriptions
        WHERE member_id = v_member_id
          AND tenant_id = p_tenant_id
          AND status = 'active'
          AND end_date >= CURRENT_DATE
        LIMIT 1;

        IF NOT FOUND THEN
            INSERT INTO attendance_logs (
                tenant_id, member_id, verification_method, access_result, denial_reason
            ) VALUES (
                p_tenant_id, v_member_id, p_method, 'denied', 'Subscription expired or unpaid'
            );
            RETURN jsonb_build_object(
                'success', FALSE,
                'unlock_signal', FALSE,
                'message', 'Subscription expired! Please renew your dues.'
            );
        END IF;

        -- Mark token used
        UPDATE gate_access_tokens SET is_used = TRUE WHERE id = v_token_rec.id;

        -- Get member full name
        SELECT full_name INTO v_member_name FROM profiles WHERE id = v_member_id;

        -- Log Granted Attendance
        INSERT INTO attendance_logs (
            tenant_id, member_id, verification_method, access_result
        ) VALUES (
            p_tenant_id, v_member_id, p_method, 'granted'
        );

        -- Update gamification streak
        UPDATE member_gamification
        SET current_streak_days = current_streak_days + 1,
            total_points = total_points + 10,
            last_activity_date = CURRENT_DATE
        WHERE user_id = v_member_id;

        RETURN jsonb_build_object(
            'success', TRUE,
            'unlock_signal', TRUE,
            'member_name', v_member_name,
            'message', 'Access Granted! Welcome to workout.'
        );

    -- 2. 24-Hour Temporary Guest Pass
    ELSIF p_method = 'guest_pass' THEN
        SELECT * INTO v_guest_rec
        FROM guest_passes
        WHERE qr_code_hash = p_token_or_code
          AND tenant_id = p_tenant_id
          AND status = 'active'
          AND expires_at >= NOW();

        IF NOT FOUND THEN
            INSERT INTO attendance_logs (
                tenant_id, verification_method, access_result, denial_reason
            ) VALUES (
                p_tenant_id, p_method, 'denied', 'Guest pass expired or invalid'
            );
            RETURN jsonb_build_object(
                'success', FALSE,
                'unlock_signal', FALSE,
                'message', 'Invalid or expired 24-Hour Guest Pass.'
            );
        END IF;

        -- Mark pass used
        UPDATE guest_passes SET status = 'used', used_at = NOW() WHERE id = v_guest_rec.id;

        -- Log attendance
        INSERT INTO attendance_logs (
            tenant_id, guest_pass_id, verification_method, access_result
        ) VALUES (
            p_tenant_id, v_guest_rec.id, p_method, 'granted'
        );

        RETURN jsonb_build_object(
            'success', TRUE,
            'unlock_signal', TRUE,
            'member_name', v_guest_rec.guest_name,
            'message', 'Guest Access Granted! Enjoy your trial session.'
        );

    -- 3. Reception Manual Check-in / Fingerprint
    ELSE
        RETURN jsonb_build_object(
            'success', TRUE,
            'unlock_signal', TRUE,
            'message', 'Manual check-in acknowledged.'
        );
    END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12.2 RPC: Airbnb-style Nearby Gyms Discovery (PostGIS GPS Query)
CREATE OR REPLACE FUNCTION get_nearby_gyms(
    user_lat DOUBLE PRECISION,
    user_lng DOUBLE PRECISION,
    radius_km DOUBLE PRECISION DEFAULT 10.0
)
RETURNS TABLE (
    id UUID,
    name VARCHAR,
    slug VARCHAR,
    address TEXT,
    city VARCHAR,
    branding JSONB,
    distance_km DOUBLE PRECISION,
    average_rating NUMERIC(3, 2),
    total_reviews BIGINT,
    starting_price NUMERIC(12, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.id,
        t.name,
        t.slug,
        t.address,
        t.city,
        t.branding,
        ROUND((ST_Distance(t.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326)) / 1000.0)::numeric, 2)::double precision AS distance_km,
        COALESCE(ROUND(AVG(r.rating), 1), 5.0) AS average_rating,
        COUNT(DISTINCT r.id) AS total_reviews,
        COALESCE(MIN(p.price), 0.00) AS starting_price
    FROM tenants t
    LEFT JOIN gym_reviews r ON r.tenant_id = t.id
    LEFT JOIN membership_plans p ON p.tenant_id = t.id AND p.is_active = TRUE
    WHERE t.is_active = TRUE
      AND t.location IS NOT NULL
      AND ST_DWithin(t.location, ST_SetSRID(ST_MakePoint(user_lng, user_lat), 4326), radius_km * 1000.0)
    GROUP BY t.id, t.name, t.slug, t.address, t.city, t.branding, t.location
    ORDER BY distance_km ASC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12.3 RPC: Log Pedometer Steps (Called by Flutter Background Tracker & Health Sync)
CREATE OR REPLACE FUNCTION log_member_steps(
    p_steps INT,
    p_distance_km NUMERIC(6, 2) DEFAULT 0.00,
    p_calories INT DEFAULT 0,
    p_duration_mins INT DEFAULT 0,
    p_log_date DATE DEFAULT CURRENT_DATE,
    p_source VARCHAR DEFAULT 'live_pedometer'
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_tenant_id UUID;
    v_log_id UUID;
    v_goal_met BOOLEAN := FALSE;
BEGIN
    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Unauthorized');
    END IF;

    SELECT tenant_id INTO v_tenant_id FROM profiles WHERE id = v_user_id;

    INSERT INTO daily_step_logs (
        tenant_id,
        user_id,
        log_date,
        step_count,
        distance_km,
        calories_burned,
        active_duration_minutes,
        source
    ) VALUES (
        v_tenant_id,
        v_user_id,
        p_log_date,
        p_steps,
        p_distance_km,
        p_calories,
        p_duration_mins,
        p_source
    )
    ON CONFLICT (user_id, log_date) DO UPDATE SET
        step_count = EXCLUDED.step_count,
        distance_km = EXCLUDED.distance_km,
        calories_burned = EXCLUDED.calories_burned,
        active_duration_minutes = EXCLUDED.active_duration_minutes,
        source = EXCLUDED.source,
        updated_at = NOW()
    RETURNING id, (step_count >= step_goal) INTO v_log_id, v_goal_met;

    RETURN jsonb_build_object(
        'success', TRUE,
        'log_id', v_log_id,
        'steps', p_steps,
        'distance_km', p_distance_km,
        'calories_burned', p_calories,
        'goal_reached', v_goal_met
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --------------------------------------------------------------------------------------
-- 13. ROW LEVEL SECURITY (RLS) POLICIES & CONTEXT HELPERS
-- --------------------------------------------------------------------------------------

-- 13.1 Helper Functions for Auth Context
CREATE OR REPLACE FUNCTION auth_current_tenant_id()
RETURNS UUID AS $$
    SELECT tenant_id FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION auth_current_role()
RETURNS user_role AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$ LANGUAGE sql STABLE SECURITY DEFINER;

CREATE OR REPLACE FUNCTION auth_is_super_admin()
RETURNS BOOLEAN AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'super_admin'
    );
$$ LANGUAGE sql STABLE SECURITY DEFINER;

-- 13.2 Enable RLS on all sensitive tables
ALTER TABLE tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE impersonation_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE membership_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_passes ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE gate_access_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE pos_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE petty_cash_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_khata_ledger ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_fitness_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_routine_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_day_exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_set_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE member_gamification ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_step_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE transformation_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE gym_reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE anti_theft_alerts ENABLE ROW LEVEL SECURITY;

-- 13.3 Tenants Policies
DROP POLICY IF EXISTS "Public can view active gyms" ON tenants;
CREATE POLICY "Public can view active gyms" ON tenants
    FOR SELECT USING (is_active = TRUE);

DROP POLICY IF EXISTS "Owners manage their gym profile" ON tenants;
CREATE POLICY "Owners manage their gym profile" ON tenants
    FOR ALL USING (
        auth_is_super_admin() OR
        (auth_current_role() = 'gym_owner' AND id = auth_current_tenant_id())
    );

-- 13.4 Profiles Policies
DROP POLICY IF EXISTS "Users can view relevant profiles" ON profiles;
CREATE POLICY "Users can view relevant profiles" ON profiles
    FOR SELECT USING (
        auth_is_super_admin() OR
        tenant_id = auth_current_tenant_id() OR
        id = auth.uid()
    );

DROP POLICY IF EXISTS "Users can update own profile" ON profiles;
CREATE POLICY "Users can update own profile" ON profiles
    FOR UPDATE USING (id = auth.uid() OR auth_is_super_admin());

DROP POLICY IF EXISTS "Staff and owners can manage profiles" ON profiles;
CREATE POLICY "Staff and owners can manage profiles" ON profiles
    FOR ALL USING (
        auth_is_super_admin() OR
        (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
    );

-- 13.5 Membership Plans Policies
DROP POLICY IF EXISTS "Anyone can view active plans" ON membership_plans;
CREATE POLICY "Anyone can view active plans" ON membership_plans
    FOR SELECT USING (is_active = TRUE OR tenant_id = auth_current_tenant_id());

DROP POLICY IF EXISTS "Gym owners manage plans" ON membership_plans;
CREATE POLICY "Gym owners manage plans" ON membership_plans
    FOR ALL USING (
        auth_is_super_admin() OR
        (auth_current_role() = 'gym_owner' AND tenant_id = auth_current_tenant_id())
    );

-- 13.6 Member Subscriptions Policies
DROP POLICY IF EXISTS "Members can view own subscriptions" ON member_subscriptions;
CREATE POLICY "Members can view own subscriptions" ON member_subscriptions
    FOR SELECT USING (
        auth_is_super_admin() OR
        member_id = auth.uid() OR
        (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
    );

DROP POLICY IF EXISTS "Staff and owners manage subscriptions" ON member_subscriptions;
CREATE POLICY "Staff and owners manage subscriptions" ON member_subscriptions
    FOR ALL USING (
        auth_is_super_admin() OR
        (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
    );

-- 13.7 POS, Invoices & Products Policies
DROP POLICY IF EXISTS "Tenant staff manage products" ON products;
CREATE POLICY "Tenant staff manage products" ON products
    FOR ALL USING (
        auth_is_super_admin() OR
        tenant_id = auth_current_tenant_id()
    );

DROP POLICY IF EXISTS "Public can view active products in store" ON products;
CREATE POLICY "Public can view active products in store" ON products
    FOR SELECT USING (is_active = TRUE);

DROP POLICY IF EXISTS "Tenant staff view and manage invoices" ON invoices;
CREATE POLICY "Tenant staff view and manage invoices" ON invoices
    FOR ALL USING (
        auth_is_super_admin() OR
        (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
    );

DROP POLICY IF EXISTS "Members can view own invoices" ON invoices;
CREATE POLICY "Members can view own invoices" ON invoices
    FOR SELECT USING (member_id = auth.uid());

DROP POLICY IF EXISTS "Tenant staff manage invoice items" ON invoice_items;
CREATE POLICY "Tenant staff manage invoice items" ON invoice_items
    FOR ALL USING (
        auth_is_super_admin() OR
        tenant_id = auth_current_tenant_id()
    );

DROP POLICY IF EXISTS "Tenant staff manage payments" ON payments;
CREATE POLICY "Tenant staff manage payments" ON payments
    FOR ALL USING (
        auth_is_super_admin() OR
        tenant_id = auth_current_tenant_id()
    );

-- 13.8 Member Khata Ledger Policies
DROP POLICY IF EXISTS "Members view own khata" ON member_khata_ledger;
CREATE POLICY "Members view own khata" ON member_khata_ledger
    FOR SELECT USING (
        member_id = auth.uid() OR
        auth_is_super_admin() OR
        (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
    );

DROP POLICY IF EXISTS "Staff manage khata" ON member_khata_ledger;
CREATE POLICY "Staff manage khata" ON member_khata_ledger
    FOR ALL USING (
        auth_is_super_admin() OR
        (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
    );

-- 13.9 Attendance & Gate Access Tokens
DROP POLICY IF EXISTS "Members view own attendance" ON attendance_logs;
CREATE POLICY "Members view own attendance" ON attendance_logs
    FOR SELECT USING (
        member_id = auth.uid() OR
        auth_is_super_admin() OR
        (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
    );

DROP POLICY IF EXISTS "Members manage own gate tokens" ON gate_access_tokens;
CREATE POLICY "Members manage own gate tokens" ON gate_access_tokens
    FOR ALL USING (
        member_id = auth.uid() OR
        auth_is_super_admin() OR
        (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
    );

-- 13.10 AI Workout Routines & Logs
DROP POLICY IF EXISTS "Anyone can view exercises" ON exercises;
CREATE POLICY "Anyone can view exercises" ON exercises
    FOR SELECT USING (is_global = TRUE OR tenant_id = auth_current_tenant_id());

DROP POLICY IF EXISTS "Anyone can view workout routines" ON workout_routines;
CREATE POLICY "Anyone can view workout routines" ON workout_routines
    FOR SELECT USING (is_public_preview = TRUE OR tenant_id = auth_current_tenant_id() OR tenant_id IS NULL);

DROP POLICY IF EXISTS "Members manage own workout logs" ON workout_logs;
CREATE POLICY "Members manage own workout logs" ON workout_logs
    FOR ALL USING (user_id = auth.uid() OR auth_is_super_admin());

DROP POLICY IF EXISTS "Members manage own workout set logs" ON workout_set_logs;
CREATE POLICY "Members manage own workout set logs" ON workout_set_logs
    FOR ALL USING (
        EXISTS (SELECT 1 FROM workout_logs WHERE id = workout_set_logs.workout_log_id AND user_id = auth.uid())
        OR auth_is_super_admin()
    );

-- 13.11 Gamification, Step Tracking & Reviews
DROP POLICY IF EXISTS "Anyone can view badges" ON badges;
CREATE POLICY "Anyone can view badges" ON badges
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Anyone can read verified reviews" ON gym_reviews;
CREATE POLICY "Anyone can read verified reviews" ON gym_reviews
    FOR SELECT USING (TRUE);

DROP POLICY IF EXISTS "Members can post reviews for their gym" ON gym_reviews;
CREATE POLICY "Members can post reviews for their gym" ON gym_reviews
    FOR INSERT WITH CHECK (
        member_id = auth.uid() AND
        tenant_id = auth_current_tenant_id()
    );

DROP POLICY IF EXISTS "Members view own step logs" ON daily_step_logs;
CREATE POLICY "Members view own step logs" ON daily_step_logs
    FOR SELECT USING (
        user_id = auth.uid() OR
        auth_is_super_admin() OR
        (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
    );

DROP POLICY IF EXISTS "Members insert and update own step logs" ON daily_step_logs;
CREATE POLICY "Members insert and update own step logs" ON daily_step_logs
    FOR ALL USING (
        user_id = auth.uid() OR auth_is_super_admin()
    );

DROP POLICY IF EXISTS "Gym members view tenant gamification leaderboards" ON member_gamification;
CREATE POLICY "Gym members view tenant gamification leaderboards" ON member_gamification
    FOR SELECT USING (
        tenant_id = auth_current_tenant_id() OR
        auth_is_super_admin()
    );

DROP POLICY IF EXISTS "Members can manage own gamification profile" ON member_gamification;
CREATE POLICY "Members can manage own gamification profile" ON member_gamification
    FOR ALL USING (
        user_id = auth.uid() OR auth_is_super_admin()
    );

DROP POLICY IF EXISTS "Members view own badges" ON user_badges;
CREATE POLICY "Members view own badges" ON user_badges
    FOR SELECT USING (
        user_id = auth.uid() OR
        auth_is_super_admin() OR
        EXISTS (SELECT 1 FROM profiles WHERE id = user_badges.user_id AND tenant_id = auth_current_tenant_id())
    );

DROP POLICY IF EXISTS "Anyone can view approved transformation posts" ON transformation_posts;
CREATE POLICY "Anyone can view approved transformation posts" ON transformation_posts
    FOR SELECT USING (
        is_approved = TRUE OR
        member_id = auth.uid() OR
        (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
    );

DROP POLICY IF EXISTS "Members can create transformation posts" ON transformation_posts;
CREATE POLICY "Members can create transformation posts" ON transformation_posts
    FOR INSERT WITH CHECK (
        member_id = auth.uid() AND
        tenant_id = auth_current_tenant_id()
    );

DROP POLICY IF EXISTS "Members and staff manage store orders" ON store_orders;
CREATE POLICY "Members and staff manage store orders" ON store_orders
    FOR ALL USING (
        member_id = auth.uid() OR
        auth_is_super_admin() OR
        (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
    );

DROP POLICY IF EXISTS "Members and staff view order items" ON store_order_items;
CREATE POLICY "Members and staff view order items" ON store_order_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM store_orders
            WHERE id = store_order_items.order_id AND (
                member_id = auth.uid() OR
                auth_is_super_admin() OR
                (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
            )
        )
    );

-- 13.12 Audit Logs & Anti-Theft Watchdog (Strict Security)
DROP POLICY IF EXISTS "Audit logs viewable only by owners and superadmins" ON audit_logs;
CREATE POLICY "Audit logs viewable only by owners and superadmins" ON audit_logs
    FOR SELECT USING (
        auth_is_super_admin() OR
        (auth_current_role() = 'gym_owner' AND tenant_id = auth_current_tenant_id())
    );

DROP POLICY IF EXISTS "Audit logs cannot be updated or deleted" ON audit_logs;
-- No UPDATE or DELETE policy granted -> Audit logs are immutable!

DROP POLICY IF EXISTS "Owners view anti-theft alerts" ON anti_theft_alerts;
CREATE POLICY "Owners view anti-theft alerts" ON anti_theft_alerts
    FOR ALL USING (
        auth_is_super_admin() OR
        (auth_current_role() = 'gym_owner' AND tenant_id = auth_current_tenant_id())
    );

-- --------------------------------------------------------------------------------------
-- 14. SEED DATA (CORE SYSTEM BADGES & SAMPLE DATA)
-- --------------------------------------------------------------------------------------
INSERT INTO badges (code, title, description, points_reward) VALUES
    ('first_workout', 'First Rep of Many', 'Completed your very first workout in the app.', 50),
    ('streak_7_days', '7-Day Iron Warrior', 'Maintained an unbroken 7-day gym workout streak.', 150),
    ('streak_30_days', '30-Day Beast Mode', 'Logged in and trained for 30 consecutive days.', 500),
    ('pr_breaker', 'Personal Record Smasher', 'Set a new PR in Bench Press, Squat, or Deadlift.', 100),
    ('early_bird', 'Dawn Patrol', 'Checked into the gym before 7:00 AM.', 75),
    ('step_master_10k', '10K Strides Legend', 'Hit 10,000 steps in a single day.', 80),
    ('step_centurion', '100K Century Club', 'Walked 100,000 total steps with GymConnect Pedometer.', 250)
ON CONFLICT (code) DO NOTHING;

-- End of GymConnect Enterprise SaaS Supabase Schema Script
