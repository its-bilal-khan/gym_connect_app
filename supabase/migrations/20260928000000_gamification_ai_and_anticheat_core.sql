-- ==============================================================================
-- GYMCONNECT ENTERPRISE SAAS: PHASE 1 CORE DATABASE MIGRATION
-- Migration: 20260928000000_gamification_ai_and_anticheat_core.sql
-- Purpose: Complete Backend Infrastructure for:
--          1. Gamification Engine (Points, Streaks, Monthly Reset, Veteran Multipliers)
--          2. Adaptive AI Habit Auto-Calibration & Track A/B Routing
--          3. Hardware Gate Check-in & Device ID Anti-Share Interlock
--          4. Daily 80% Composite Threshold Engine & Native Sleep/Step Tracking
--          5. Automated Month-End Reward Fulfillment (Zero-Touch Subscription Extensions & Rs. 0 Invoices)
--          6. Fraud Moderation Queue & Points Clawback System
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. EXTENSIONS SETUP (SAFEGUARDED)
-- ------------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

DO $$
BEGIN
    CREATE EXTENSION IF NOT EXISTS pg_cron;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron extension notice: %', SQLERRM;
END $$;

-- ------------------------------------------------------------------------------
-- 2. SCHEMA ALTERATIONS ON EXISTING TABLES (IDEMPOTENT & NULL-SAFE)
-- ------------------------------------------------------------------------------

-- 2.1 Tenants: Custom Reward Configurator & Multiplier Tiers
ALTER TABLE IF EXISTS tenants
ADD COLUMN IF NOT EXISTS leaderboard_rewards JSONB NOT NULL DEFAULT '{
    "rank_1": {"title": "1-Month Free Access", "type": "membership_extension", "value": 30},
    "rank_2": {"title": "50% Off Next Renewal", "type": "discount_voucher", "value": 50},
    "rank_3": {"title": "Free Whey Shaker & Tub", "type": "custom_reward", "value": "merch"}
}'::jsonb,
ADD COLUMN IF NOT EXISTS min_monthly_workouts_qualification INT DEFAULT 18,
ADD COLUMN IF NOT EXISTS veteran_multiplier_config JSONB NOT NULL DEFAULT '{
    "tier_1_days": 14, "tier_1_multiplier": 1.10,
    "tier_2_days": 30, "tier_2_multiplier": 1.25,
    "tier_3_days": 60, "tier_3_multiplier": 1.50
}'::jsonb;

-- 2.2 Profiles: Hardware Signature & Single-Device Anti-Share Lock
ALTER TABLE IF EXISTS profiles
ADD COLUMN IF NOT EXISTS primary_device_id VARCHAR(255),
ADD COLUMN IF NOT EXISTS device_locked_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS device_model_info VARCHAR(150);

-- 2.3 User Fitness Profiles: Track A/B Routing, Adaptive Targets & Injury Matrix
ALTER TABLE IF EXISTS user_fitness_profiles
ADD COLUMN IF NOT EXISTS assigned_workout_track VARCHAR(50) DEFAULT 'track_a' CHECK (assigned_workout_track IN ('track_a', 'track_b')),
ADD COLUMN IF NOT EXISTS current_step_target INT DEFAULT 10000,
ADD COLUMN IF NOT EXISTS base_step_target INT DEFAULT 10000,
ADD COLUMN IF NOT EXISTS consecutive_target_misses INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_auto_calibrated_at TIMESTAMPTZ,
ADD COLUMN IF NOT EXISTS medical_injuries TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS profile_completed BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS onboarded_at TIMESTAMPTZ DEFAULT NOW();

-- 2.4 Exercises: Contraindications, 1-Tap Swap Grouping & Vision AI Types
ALTER TABLE IF EXISTS exercises
ADD COLUMN IF NOT EXISTS contraindicated_injuries TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS swap_group_id VARCHAR(100),
ADD COLUMN IF NOT EXISTS ml_pose_exercise_type VARCHAR(50); -- 'squat', 'pushup', 'bicep_curl', 'pullup'

-- 2.5 Member Gamification: Monthly Points, Penalties & Real Multipliers
ALTER TABLE IF EXISTS member_gamification
ADD COLUMN IF NOT EXISTS monthly_points INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS monthly_workouts_completed INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS streak_multiplier NUMERIC(3, 2) DEFAULT 1.00,
ADD COLUMN IF NOT EXISTS is_elite_qualified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS last_month_rank INT,
ADD COLUMN IF NOT EXISTS total_penalties_count INT DEFAULT 0,
ADD COLUMN IF NOT EXISTS last_penalty_date DATE;

-- ------------------------------------------------------------------------------
-- 3. NEW TABLES CREATION
-- ------------------------------------------------------------------------------

-- 3.1 Daily Gamification Logs (The Composite 80% Rule & Task Audit)
CREATE TABLE IF NOT EXISTS daily_gamification_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    device_id_used VARCHAR(255),
    workout_assigned_sets INT DEFAULT 0,
    workout_completed_sets INT DEFAULT 0,
    workout_completion_pct NUMERIC(5, 2) DEFAULT 0.00,
    step_target INT DEFAULT 10000,
    step_actual INT DEFAULT 0,
    step_completion_pct NUMERIC(5, 2) DEFAULT 0.00,
    step_source VARCHAR(50) DEFAULT 'live_pedometer', -- 'live_pedometer', 'healthkit', 'health_connect', 'manual'
    diet_logged_type VARCHAR(20) DEFAULT 'none', -- 'photo_proof', 'self_check', 'none'
    diet_proof_url TEXT,
    sleep_logged_hours NUMERIC(4, 1) DEFAULT 0.0,
    sleep_source VARCHAR(50) DEFAULT 'none', -- 'healthkit', 'health_connect', 'manual', 'none'
    sleep_asleep_minutes INT DEFAULT 0,
    gate_checkin_verified BOOLEAN DEFAULT FALSE,
    composite_completion_pct NUMERIC(5, 2) DEFAULT 0.00,
    points_awarded INT DEFAULT 0,
    penalty_deducted INT DEFAULT 0, -- -10 points for unexcused gym absence
    is_unexcused_absence BOOLEAN DEFAULT FALSE,
    streak_saved BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_daily_user_gamification UNIQUE (user_id, log_date)
);

-- 3.2 Member Workout Reels (Micro-Clips & Explore Shorts Feed)
CREATE TABLE IF NOT EXISTS member_workout_reels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    duration_seconds INT NOT NULL,
    routine_title VARCHAR(150),
    streak_days_at_record INT DEFAULT 0,
    is_public_explore BOOLEAN DEFAULT TRUE,
    is_flagged BOOLEAN DEFAULT FALSE,
    likes_count INT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3.3 Monthly Leaderboard Podium Archives & Automated Reward Fulfillment
CREATE TABLE IF NOT EXISTS monthly_leaderboard_archives (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    month_year VARCHAR(7) NOT NULL, -- Format: 'YYYY-MM'
    podium_rank INT NOT NULL, -- 1, 2, 3
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    points_scored INT NOT NULL,
    streak_at_finish INT NOT NULL,
    reward_title VARCHAR(255) NOT NULL,
    reward_type VARCHAR(50) NOT NULL, -- 'membership_extension', 'discount_voucher', 'custom_reward'
    reward_value INT DEFAULT 30,
    is_fulfilled BOOLEAN DEFAULT FALSE,
    subscription_id_extended UUID REFERENCES member_subscriptions(id) ON DELETE SET NULL,
    invoice_id_generated UUID REFERENCES invoices(id) ON DELETE SET NULL,
    fulfilled_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_month_podium UNIQUE (tenant_id, month_year, podium_rank)
);

-- 3.4 Gamification Flagged Moderation Queue (Fraud Protection & Point Clawbacks)
CREATE TABLE IF NOT EXISTS gamification_flagged_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    proof_type VARCHAR(50) NOT NULL, -- 'diet_photo', 'workout_video', 'manual_steps'
    proof_url TEXT NOT NULL,
    points_awarded INT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending_review', -- 'pending_review', 'approved', 'deducted'
    flagged_reason TEXT,
    reviewed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ------------------------------------------------------------------------------
-- 4. HIGH-PERFORMANCE INDEXES
-- ------------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_daily_gamification_user_date ON daily_gamification_logs(user_id, log_date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_gamification_tenant_date ON daily_gamification_logs(tenant_id, log_date DESC);
CREATE INDEX IF NOT EXISTS idx_reels_tenant_explore ON member_workout_reels(tenant_id, is_public_explore, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_monthly_leaderboard_tenant_month ON monthly_leaderboard_archives(tenant_id, month_year, podium_rank);
CREATE INDEX IF NOT EXISTS idx_flagged_queue_tenant_status ON gamification_flagged_queue(tenant_id, status);
CREATE INDEX IF NOT EXISTS idx_user_fitness_track ON user_fitness_profiles(assigned_workout_track);

-- ------------------------------------------------------------------------------
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ------------------------------------------------------------------------------
ALTER TABLE IF EXISTS daily_gamification_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS member_workout_reels ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS monthly_leaderboard_archives ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS gamification_flagged_queue ENABLE ROW LEVEL SECURITY;

-- 5.1 Universal Multi-Tenant Dev & Service Policies (Consistent with active setup)
DROP POLICY IF EXISTS "Public can manage daily gamification logs" ON daily_gamification_logs;
CREATE POLICY "Public can manage daily gamification logs" ON daily_gamification_logs FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

DROP POLICY IF EXISTS "Public can manage member reels" ON member_workout_reels;
CREATE POLICY "Public can manage member reels" ON member_workout_reels FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

DROP POLICY IF EXISTS "Public can manage monthly podium archives" ON monthly_leaderboard_archives;
CREATE POLICY "Public can manage monthly podium archives" ON monthly_leaderboard_archives FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

DROP POLICY IF EXISTS "Public can manage flagged queue" ON gamification_flagged_queue;
CREATE POLICY "Public can manage flagged queue" ON gamification_flagged_queue FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- ------------------------------------------------------------------------------
-- 6. CORE POSTGRESQL RPC FUNCTIONS
-- ------------------------------------------------------------------------------

-- 6.1 RPC: Submit Daily Activity, Evaluate 80% Rule & Gate Interlock
CREATE OR REPLACE FUNCTION rpc_submit_daily_activity(
    p_user_id UUID,
    p_tenant_id UUID,
    p_device_id VARCHAR,
    p_workout_assigned_sets INT DEFAULT 0,
    p_workout_completed_sets INT DEFAULT 0,
    p_step_target INT DEFAULT 10000,
    p_step_actual INT DEFAULT 0,
    p_step_source VARCHAR DEFAULT 'live_pedometer',
    p_diet_logged_type VARCHAR DEFAULT 'none',
    p_diet_proof_url TEXT DEFAULT NULL,
    p_sleep_logged_hours NUMERIC DEFAULT 0.0,
    p_sleep_source VARCHAR DEFAULT 'none',
    p_sleep_asleep_minutes INT DEFAULT 0
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_gate_verified BOOLEAN := FALSE;
    v_device_matches BOOLEAN := TRUE;
    v_reg_device_id VARCHAR(255);
    v_workout_pct NUMERIC(5, 2) := 0.00;
    v_step_pct NUMERIC(5, 2) := 0.00;
    v_diet_score_pct NUMERIC(5, 2) := 0.00;
    v_sleep_score_pct NUMERIC(5, 2) := 0.00;
    v_composite_pct NUMERIC(5, 2) := 0.00;
    v_points_workout NUMERIC(8, 2) := 0.00;
    v_points_step NUMERIC(8, 2) := 0.00;
    v_points_diet NUMERIC(8, 2) := 0.00;
    v_points_sleep NUMERIC(8, 2) := 0.00;
    v_total_base_points NUMERIC(8, 2) := 0.00;
    v_current_multiplier NUMERIC(3, 2) := 1.00;
    v_final_points INT := 0;
    v_streak_saved BOOLEAN := FALSE;
    v_min_workouts_qual INT := 18;
    v_existing_activity_date DATE;
    v_current_streak INT := 0;
    v_longest_streak INT := 0;
    v_monthly_workouts INT := 0;
BEGIN
    -- A. Verify Hardware Device Signature Lock
    SELECT primary_device_id INTO v_reg_device_id FROM profiles WHERE id = p_user_id;
    IF v_reg_device_id IS NOT NULL AND p_device_id IS NOT NULL THEN
        IF v_reg_device_id <> p_device_id THEN
            v_device_matches := FALSE;
        END IF;
    ELSIF v_reg_device_id IS NULL AND p_device_id IS NOT NULL THEN
        -- Auto-bind primary device on initial hardware handshake
        UPDATE profiles SET primary_device_id = p_device_id, device_locked_at = NOW() WHERE id = p_user_id;
    END IF;

    -- B. Verify Physical Gym Access Gate Scan for CURRENT_DATE
    SELECT EXISTS (
        SELECT 1 FROM attendance_logs
        WHERE (member_id = p_user_id OR member_id::TEXT = p_user_id::TEXT)
          AND (tenant_id = p_tenant_id OR tenant_id::TEXT = p_tenant_id::TEXT)
          AND check_in_time::DATE = CURRENT_DATE
          AND access_result = 'granted'
    ) INTO v_gate_verified;

    -- C. Calculate Component Percentages
    IF p_workout_assigned_sets > 0 THEN
        v_workout_pct := LEAST(100.00, (p_workout_completed_sets::NUMERIC / p_workout_assigned_sets::NUMERIC) * 100.00);
    ELSE
        v_workout_pct := 100.00; -- Rest day or cardio-only day
    END IF;

    IF p_step_target > 0 THEN
        v_step_pct := LEAST(100.00, (p_step_actual::NUMERIC / p_step_target::NUMERIC) * 100.00);
    ELSE
        v_step_pct := 100.00;
    END IF;

    IF p_diet_logged_type = 'photo_proof' THEN
        v_diet_score_pct := 100.00;
    ELSIF p_diet_logged_type = 'self_check' THEN
        v_diet_score_pct := 25.00;
    ELSE
        v_diet_score_pct := 0.00;
    END IF;

    IF p_sleep_logged_hours >= 7.0 THEN
        v_sleep_score_pct := 100.00;
    ELSIF p_sleep_logged_hours >= 5.0 THEN
        v_sleep_score_pct := 70.00;
    ELSIF p_sleep_logged_hours > 0.0 THEN
        v_sleep_score_pct := 30.00;
    ELSE
        v_sleep_score_pct := 0.00;
    END IF;

    -- D. 80% Composite Threshold Formula (50% Workout + 25% Steps + 15% Diet + 10% Sleep)
    v_composite_pct := (0.50 * v_workout_pct) + (0.25 * v_step_pct) + (0.15 * v_diet_score_pct) + (0.10 * v_sleep_score_pct);

    -- Streak saved strictly if composite >= 80% AND physical gate attendance is verified
    IF v_composite_pct >= 80.00 AND v_gate_verified = TRUE THEN
        v_streak_saved := TRUE;
    ELSE
        v_streak_saved := FALSE;
    END IF;

    -- E. Weighted Points Calculation
    v_points_workout := 50.00 * (v_workout_pct / 100.00);

    -- Steps: Auto-sync sensors award up to 20 pts, manual capped at 5 pts
    IF p_step_source IN ('live_pedometer', 'healthkit', 'health_connect') THEN
        v_points_step := 20.00 * (v_step_pct / 100.00);
    ELSE
        v_points_step := 5.00 * (v_step_pct / 100.00);
    END IF;

    -- Diet: Photo proof awards +15, manual checkbox awards +2
    IF p_diet_logged_type = 'photo_proof' THEN
        v_points_diet := 15.00;
    ELSIF p_diet_logged_type = 'self_check' THEN
        v_points_diet := 2.00;
    ELSE
        v_points_diet := 0.00;
    END IF;

    -- Sleep: Verified sensor sleep awards up to +10, manual capped at +3
    IF p_sleep_source IN ('healthkit', 'health_connect') THEN
        IF p_sleep_logged_hours >= 7.0 THEN
            v_points_sleep := 10.00;
        ELSIF p_sleep_logged_hours >= 5.0 THEN
            v_points_sleep := 7.00;
        ELSE
            v_points_sleep := 3.00;
        END IF;
    ELSE
        v_points_sleep := LEAST(3.00, p_sleep_logged_hours * 0.40);
    END IF;

    -- Fetch active streak multiplier
    SELECT streak_multiplier, last_activity_date, current_streak_days, longest_streak_days, monthly_workouts_completed
    INTO v_current_multiplier, v_existing_activity_date, v_current_streak, v_longest_streak, v_monthly_workouts
    FROM member_gamification
    WHERE user_id = p_user_id;

    v_current_multiplier := COALESCE(v_current_multiplier, 1.00);
    v_total_base_points := v_points_workout + v_points_step + v_points_diet + v_points_sleep;
    v_final_points := ROUND(v_total_base_points * v_current_multiplier);

    -- F. Upsert into daily_gamification_logs
    INSERT INTO daily_gamification_logs (
        tenant_id, user_id, log_date, device_id_used,
        workout_assigned_sets, workout_completed_sets, workout_completion_pct,
        step_target, step_actual, step_completion_pct, step_source,
        diet_logged_type, diet_proof_url,
        sleep_logged_hours, sleep_source, sleep_asleep_minutes,
        gate_checkin_verified, composite_completion_pct,
        points_awarded, streak_saved, notes
    ) VALUES (
        p_tenant_id, p_user_id, CURRENT_DATE, p_device_id,
        p_workout_assigned_sets, p_workout_completed_sets, v_workout_pct,
        p_step_target, p_step_actual, v_step_pct, p_step_source,
        p_diet_logged_type, p_diet_proof_url,
        p_sleep_logged_hours, p_sleep_source, p_sleep_asleep_minutes,
        v_gate_verified, v_composite_pct,
        v_final_points, v_streak_saved,
        CASE WHEN v_device_matches = FALSE THEN 'Device Mismatch Warning' ELSE 'Normal Activity' END
    )
    ON CONFLICT (user_id, log_date) DO UPDATE SET
        workout_completed_sets = EXCLUDED.workout_completed_sets,
        workout_completion_pct = EXCLUDED.workout_completion_pct,
        step_actual = EXCLUDED.step_actual,
        step_completion_pct = EXCLUDED.step_completion_pct,
        step_source = EXCLUDED.step_source,
        diet_logged_type = EXCLUDED.diet_logged_type,
        diet_proof_url = COALESCE(EXCLUDED.diet_proof_url, daily_gamification_logs.diet_proof_url),
        sleep_logged_hours = EXCLUDED.sleep_logged_hours,
        sleep_source = EXCLUDED.sleep_source,
        sleep_asleep_minutes = EXCLUDED.sleep_asleep_minutes,
        gate_checkin_verified = EXCLUDED.gate_checkin_verified,
        composite_completion_pct = EXCLUDED.composite_completion_pct,
        points_awarded = EXCLUDED.points_awarded,
        streak_saved = EXCLUDED.streak_saved,
        notes = EXCLUDED.notes;

    -- G. Update member_gamification aggregate stats
    SELECT COALESCE(min_monthly_workouts_qualification, 18) INTO v_min_workouts_qual
    FROM tenants WHERE id = p_tenant_id;

    IF v_existing_activity_date IS NULL OR v_existing_activity_date < CURRENT_DATE THEN
        IF v_streak_saved = TRUE THEN
            v_current_streak := COALESCE(v_current_streak, 0) + 1;
            v_longest_streak := GREATEST(COALESCE(v_longest_streak, 0), v_current_streak);
        END IF;

        IF p_workout_completed_sets > 0 THEN
            v_monthly_workouts := COALESCE(v_monthly_workouts, 0) + 1;
        END IF;

        UPDATE member_gamification SET
            total_points = COALESCE(total_points, 0) + v_final_points,
            monthly_points = COALESCE(monthly_points, 0) + v_final_points,
            current_streak_days = v_current_streak,
            longest_streak_days = v_longest_streak,
            monthly_workouts_completed = v_monthly_workouts,
            is_elite_qualified = (v_monthly_workouts >= v_min_workouts_qual),
            daily_steps = p_step_actual,
            last_activity_date = CURRENT_DATE,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    ELSE
        -- Update same-day metrics
        UPDATE member_gamification SET
            daily_steps = p_step_actual,
            updated_at = NOW()
        WHERE user_id = p_user_id;
    END IF;

    -- H. Enqueue diet photo in Flagged Queue for Owner Review
    IF p_diet_logged_type = 'photo_proof' AND p_diet_proof_url IS NOT NULL THEN
        INSERT INTO gamification_flagged_queue (
            tenant_id, user_id, proof_type, proof_url, points_awarded, status, flagged_reason
        ) VALUES (
            p_tenant_id, p_user_id, 'diet_photo', p_diet_proof_url, ROUND(v_points_diet), 'pending_review', 'Routine Diet Verification'
        );
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'points_awarded', v_final_points,
        'composite_pct', v_composite_pct,
        'streak_saved', v_streak_saved,
        'gate_verified', v_gate_verified,
        'device_matches', v_device_matches,
        'current_streak', v_current_streak,
        'is_elite_qualified', (v_monthly_workouts >= v_min_workouts_qual)
    );
END;
$$;

-- 6.2 RPC: Daily Midnight Audit (Penalties & Vacation/Sick Leave Exemption)
CREATE OR REPLACE FUNCTION rpc_daily_midnight_audit()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    m RECORD;
    v_penalties_applied INT := 0;
    v_exemptions_granted INT := 0;
    v_is_frozen BOOLEAN := FALSE;
    v_has_attended BOOLEAN := FALSE;
    v_current_step_target INT := 10000;
    v_consecutive_misses INT := 0;
    v_step_actual INT := 0;
BEGIN
    FOR m IN 
        SELECT p.id AS user_id, p.tenant_id
        FROM profiles p
        JOIN member_subscriptions ms ON ms.member_id = p.id
        WHERE p.role = 'member' 
          AND p.is_active = TRUE
          AND ms.status = 'active'
    LOOP
        -- Check if physical gate scan happened today
        SELECT EXISTS (
            SELECT 1 FROM attendance_logs
            WHERE (member_id = m.user_id OR member_id::TEXT = m.user_id::TEXT)
              AND check_in_time::DATE = CURRENT_DATE
              AND access_result = 'granted'
        ) INTO v_has_attended;

        -- Check Vacation / Sick Leave & Freeze Shield
        SELECT EXISTS (
            SELECT 1 FROM member_subscriptions ms
            WHERE (ms.member_id = m.user_id OR ms.member_id::TEXT = m.user_id::TEXT)
              AND (
                  ms.status = 'frozen'
                  OR (CURRENT_DATE BETWEEN ms.freeze_start_date AND ms.freeze_end_date)
              )
        ) INTO v_is_frozen;

        IF v_is_frozen = TRUE THEN
            -- Exemption Shield: No penalty, streak paused
            INSERT INTO daily_gamification_logs (
                tenant_id, user_id, log_date, is_unexcused_absence, penalty_deducted, notes
            ) VALUES (
                m.tenant_id, m.user_id, CURRENT_DATE, FALSE, 0, 'Membership Frozen (Medical/Travel Exemption)'
            ) ON CONFLICT (user_id, log_date) DO UPDATE SET
                notes = 'Membership Frozen (Medical/Travel Exemption)';
            
            v_exemptions_granted := v_exemptions_granted + 1;

        ELSIF v_has_attended = FALSE THEN
            -- Unexcused Absence: Apply -10 Points Penalty & Break Streak
            UPDATE member_gamification SET
                total_points = GREATEST(0, total_points - 10),
                monthly_points = GREATEST(0, monthly_points - 10),
                current_streak_days = 0,
                total_penalties_count = total_penalties_count + 1,
                last_penalty_date = CURRENT_DATE,
                updated_at = NOW()
            WHERE user_id = m.user_id;

            INSERT INTO daily_gamification_logs (
                tenant_id, user_id, log_date, is_unexcused_absence, penalty_deducted, notes
            ) VALUES (
                m.tenant_id, m.user_id, CURRENT_DATE, TRUE, 10, 'Unexcused Gym Absence Penalty (-10 pts)'
            ) ON CONFLICT (user_id, log_date) DO UPDATE SET
                is_unexcused_absence = TRUE,
                penalty_deducted = 10,
                notes = 'Unexcused Gym Absence Penalty (-10 pts)';

            v_penalties_applied := v_penalties_applied + 1;
        END IF;

        -- Adaptive AI Habit Calibration: Check steps
        SELECT current_step_target, consecutive_target_misses
        INTO v_current_step_target, v_consecutive_misses
        FROM user_fitness_profiles
        WHERE user_id = m.user_id;

        SELECT COALESCE(daily_steps, 0) INTO v_step_actual
        FROM member_gamification WHERE user_id = m.user_id;

        IF v_current_step_target IS NOT NULL AND v_step_actual < (v_current_step_target * 0.70) THEN
            v_consecutive_misses := COALESCE(v_consecutive_misses, 0) + 1;
            IF v_consecutive_misses >= 3 THEN
                -- Reduce step target by 2,000 steps (Floor at 5,000)
                UPDATE user_fitness_profiles SET
                    current_step_target = GREATEST(5000, v_current_step_target - 2000),
                    consecutive_target_misses = 0,
                    last_auto_calibrated_at = NOW()
                WHERE user_id = m.user_id;
            ELSE
                UPDATE user_fitness_profiles SET
                    consecutive_target_misses = v_consecutive_misses
                WHERE user_id = m.user_id;
            END IF;
        ELSE
            -- Target achieved, reset misses counter
            UPDATE user_fitness_profiles SET
                consecutive_target_misses = 0
            WHERE user_id = m.user_id;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'success', TRUE,
        'penalties_applied', v_penalties_applied,
        'exemptions_granted', v_exemptions_granted,
        'audited_at', NOW()
    );
END;
$$;

-- 6.3 RPC: Monthly Leaderboard Reset & Automated Reward Fulfillment
CREATE OR REPLACE FUNCTION rpc_monthly_leaderboard_reset()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    t RECORD;
    w RECORD;
    v_month_year VARCHAR(7);
    v_rewards JSONB;
    v_reward_info JSONB;
    v_reward_title VARCHAR(255);
    v_reward_type VARCHAR(50);
    v_reward_val INT;
    v_podium_rank INT;
    v_sub_id UUID;
    v_inv_id UUID;
    v_active_sub_end DATE;
    v_tier_config JSONB;
    v_podium_count INT := 0;
BEGIN
    v_month_year := TO_CHAR(CURRENT_DATE - INTERVAL '1 day', 'YYYY-MM');

    FOR t IN SELECT id, name, leaderboard_rewards, veteran_multiplier_config FROM tenants WHERE is_active = TRUE LOOP
        v_rewards := COALESCE(t.leaderboard_rewards, '{
            "rank_1": {"title": "1-Month Free Access", "type": "membership_extension", "value": 30},
            "rank_2": {"title": "50% Off Next Renewal", "type": "discount_voucher", "value": 50},
            "rank_3": {"title": "Free Whey Shaker & Tub", "type": "custom_reward", "value": "merch"}
        }'::jsonb);

        v_podium_rank := 1;

        -- Process Top 3 Qualified Winners
        FOR w IN 
            SELECT mg.user_id, mg.monthly_points, mg.current_streak_days, p.full_name
            FROM member_gamification mg
            JOIN profiles p ON p.id = mg.user_id
            WHERE mg.tenant_id = t.id
              AND mg.is_elite_qualified = TRUE
            ORDER BY mg.monthly_points DESC
            LIMIT 3
        LOOP
            IF v_podium_rank = 1 THEN
                v_reward_info := v_rewards->'rank_1';
            ELSIF v_podium_rank = 2 THEN
                v_reward_info := v_rewards->'rank_2';
            ELSE
                v_reward_info := v_rewards->'rank_3';
            END IF;

            v_reward_title := COALESCE(v_reward_info->>'title', 'Podium Reward');
            v_reward_type := COALESCE(v_reward_info->>'type', 'membership_extension');
            v_reward_val := COALESCE((v_reward_info->>'value')::INT, 30);
            v_sub_id := NULL;
            v_inv_id := NULL;

            -- Automated Subscription Extension for Membership Rewards
            IF v_reward_type = 'membership_extension' THEN
                SELECT id, end_date INTO v_sub_id, v_active_sub_end
                FROM member_subscriptions
                WHERE (member_id = w.user_id OR member_id::TEXT = w.user_id::TEXT)
                  AND (tenant_id = t.id OR tenant_id::TEXT = t.id::TEXT)
                  AND status = 'active'
                ORDER BY end_date DESC
                LIMIT 1;

                IF v_sub_id IS NOT NULL THEN
                    UPDATE member_subscriptions SET
                        end_date = GREATEST(v_active_sub_end, CURRENT_DATE) + (v_reward_val * INTERVAL '1 day'),
                        status = 'active',
                        updated_at = NOW()
                    WHERE id = v_sub_id;
                END IF;

                -- Generate official Rs. 0 Reconciliation Invoice
                INSERT INTO invoices (
                    tenant_id, invoice_number, member_id, customer_name,
                    subtotal, discount_amount, tax_amount, total_amount, paid_amount, due_amount,
                    status, notes
                ) VALUES (
                    t.id, 'INV-REWARD-' || SUBSTRING(gen_random_uuid()::TEXT, 1, 8), w.user_id, w.full_name,
                    0.00, 0.00, 0.00, 0.00, 0.00, 0.00,
                    'paid', 'Podium Rank #' || v_podium_rank || ' Leaderboard Prize: ' || v_reward_title
                ) RETURNING id INTO v_inv_id;
            END IF;

            -- Insert Podium Archive
            INSERT INTO monthly_leaderboard_archives (
                tenant_id, month_year, podium_rank, user_id,
                points_scored, streak_at_finish, reward_title, reward_type, reward_value,
                is_fulfilled, subscription_id_extended, invoice_id_generated, fulfilled_at
            ) VALUES (
                t.id, v_month_year, v_podium_rank, w.user_id,
                w.monthly_points, w.current_streak_days, v_reward_title, v_reward_type, v_reward_val,
                TRUE, v_sub_id, v_inv_id, NOW()
            ) ON CONFLICT (tenant_id, month_year, podium_rank) DO UPDATE SET
                points_scored = EXCLUDED.points_scored,
                streak_at_finish = EXCLUDED.streak_at_finish,
                reward_title = EXCLUDED.reward_title,
                is_fulfilled = TRUE,
                fulfilled_at = NOW();

            v_podium_count := v_podium_count + 1;
            v_podium_rank := v_podium_rank + 1;
        END LOOP;

        -- Recalculate Veteran Multipliers for all members based on unbroken streak
        UPDATE member_gamification SET
            streak_multiplier = CASE
                WHEN current_streak_days >= 60 THEN 1.50
                WHEN current_streak_days >= 30 THEN 1.25
                WHEN current_streak_days >= 14 THEN 1.10
                ELSE 1.00
            END,
            monthly_points = 0,
            monthly_workouts_completed = 0,
            is_elite_qualified = FALSE,
            updated_at = NOW()
        WHERE tenant_id = t.id;
    END LOOP;

    RETURN jsonb_build_object(
        'success', TRUE,
        'month_year', v_month_year,
        'podiums_archived', v_podium_count,
        'executed_at', NOW()
    );
END;
$$;

-- 6.4 RPC: Clawback Flagged Points (Owner Moderation Workstation)
CREATE OR REPLACE FUNCTION rpc_clawback_flagged_points(
    p_queue_id UUID,
    p_reviewer_id UUID,
    p_deduct_points BOOLEAN,
    p_reason TEXT DEFAULT 'Proof rejected by gym owner'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    q RECORD;
BEGIN
    SELECT * INTO q FROM gamification_flagged_queue WHERE id = p_queue_id;
    IF q IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Queue item not found');
    END IF;

    IF p_deduct_points = TRUE THEN
        -- Deduct fraudulently awarded points
        UPDATE member_gamification SET
            total_points = GREATEST(0, total_points - q.points_awarded),
            monthly_points = GREATEST(0, monthly_points - q.points_awarded),
            updated_at = NOW()
        WHERE user_id = q.user_id;

        UPDATE gamification_flagged_queue SET
            status = 'deducted',
            flagged_reason = p_reason,
            reviewed_by = p_reviewer_id,
            reviewed_at = NOW()
        WHERE id = p_queue_id;
    ELSE
        -- Approve proof
        UPDATE gamification_flagged_queue SET
            status = 'approved',
            reviewed_by = p_reviewer_id,
            reviewed_at = NOW()
        WHERE id = p_queue_id;
    END IF;

    RETURN jsonb_build_object('success', TRUE, 'status', CASE WHEN p_deduct_points THEN 'deducted' ELSE 'approved' END);
END;
$$;

-- ------------------------------------------------------------------------------
-- 7. AUTOMATED PG_CRON SCHEDULES (SAFEGUARDED REGISTRATION)
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        -- Daily midnight audit at 11:59 PM
        PERFORM cron.unschedule('gymconnect_daily_midnight_audit');
        PERFORM cron.schedule(
            'gymconnect_daily_midnight_audit',
            '59 23 * * *',
            'SELECT rpc_daily_midnight_audit();'
        );

        -- Monthly 1st reset & reward distribution at 00:00:00 UTC
        PERFORM cron.unschedule('gymconnect_monthly_leaderboard_reset');
        PERFORM cron.schedule(
            'gymconnect_monthly_leaderboard_reset',
            '0 0 1 * *',
            'SELECT rpc_monthly_leaderboard_reset();'
        );
    END IF;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'pg_cron automated schedule notice: %', SQLERRM;
END $$;
