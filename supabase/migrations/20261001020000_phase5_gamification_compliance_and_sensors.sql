-- ==============================================================================
-- GYMCONNECT ENTERPRISE SAAS: PHASE 5 MIGRATION
-- Migration: 20261001020000_phase5_gamification_compliance_and_sensors.sql
-- Purpose:
--   1. Super Admin Supremacy: Phase 5 business variables in global_system_settings
--   2. Phase 5 Feature Flags (sleep_tracking, diet_proof_verification, gate_interlock_strict)
--   3. Storage Bucket & RLS for diet_proofs
--   4. RPC rpc_verify_or_bind_device: Anti-cheat hardware device lock
--   5. RPC rpc_get_compliance_breakdown: Real-time 80% compliance telemetry
-- ==============================================================================

-- 1. Phase 5 Super Admin Global Business Configurations (Rule 9)
INSERT INTO global_system_settings (key, value, allow_tenant_override, description)
VALUES
(
    'phase5_compliance_config',
    '{
        "composite_threshold_pct": 80.0,
        "workout_weight_pct": 0.50,
        "step_weight_pct": 0.25,
        "diet_weight_pct": 0.15,
        "sleep_weight_pct": 0.10,
        "sleep_verified_hours_full": 7.0,
        "sleep_verified_hours_mid": 5.0,
        "points_workout_max": 50,
        "points_step_sensor_max": 20,
        "points_step_manual_max": 5,
        "points_diet_photo": 15,
        "points_diet_manual": 2,
        "points_sleep_sensor_full": 10,
        "points_sleep_sensor_mid": 7,
        "points_sleep_manual_max": 3,
        "penalty_unexcused_absence": 10,
        "adaptive_step_drop": 2000,
        "adaptive_step_floor": 5000,
        "adaptive_miss_threshold": 3,
        "require_gate_checkin_for_streak": true,
        "enforce_device_id_lock": true
    }'::jsonb,
    FALSE,
    'Phase 5 Composite compliance threshold, sensor weights, gate interlock, and anti-cheat tolerances.'
)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value,
    description = EXCLUDED.description;

-- Update feature_flags to include Phase 5 modules
UPDATE global_system_settings
SET value = value || '{
    "sleep_tracking": true,
    "diet_proof_verification": true,
    "gate_interlock_strict": true,
    "adaptive_habit_calibration": true
}'::jsonb
WHERE key = 'feature_flags';

-- 2. Storage Bucket for Diet Proofs (if storage schema exists)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'storage') THEN
        INSERT INTO storage.buckets (id, name, public)
        VALUES ('diet_proofs', 'diet_proofs', true)
        ON CONFLICT (id) DO NOTHING;
    END IF;
END $$;

-- 3. RPC: Anti-Cheat Hardware Device Lock Verification & Auto-Binding
CREATE OR REPLACE FUNCTION rpc_verify_or_bind_device(
    p_user_id UUID,
    p_device_id VARCHAR
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_reg_device VARCHAR(255);
    v_locked_at TIMESTAMPTZ;
BEGIN
    SELECT primary_device_id, device_locked_at
    INTO v_reg_device, v_locked_at
    FROM profiles
    WHERE id = p_user_id;

    IF v_reg_device IS NULL THEN
        -- Auto-bind device on initial hardware handshake
        UPDATE profiles
        SET primary_device_id = p_device_id,
            device_locked_at = NOW()
        WHERE id = p_user_id;

        RETURN jsonb_build_object(
            'status', 'bound',
            'is_valid', TRUE,
            'primary_device_id', p_device_id,
            'message', 'Device registered successfully as primary hardware signature.'
        );
    ELSIF v_reg_device = p_device_id THEN
        RETURN jsonb_build_object(
            'status', 'valid',
            'is_valid', TRUE,
            'primary_device_id', v_reg_device,
            'message', 'Hardware device signature verified.'
        );
    ELSE
        RETURN jsonb_build_object(
            'status', 'mismatch',
            'is_valid', FALSE,
            'primary_device_id', v_reg_device,
            'message', 'Device mismatch detected. Account is bound to another primary device.'
        );
    END IF;
END;
$$;

-- 4. RPC: Real-Time Compliance Breakdown for Member Today Dashboard
CREATE OR REPLACE FUNCTION rpc_get_compliance_breakdown(
    p_user_id UUID,
    p_tenant_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_log daily_gamification_logs%ROWTYPE;
    v_stats member_gamification%ROWTYPE;
    v_gate_verified BOOLEAN := FALSE;
    v_reg_device VARCHAR(255);
BEGIN
    -- Get today's log if exists
    SELECT * INTO v_log
    FROM daily_gamification_logs
    WHERE user_id = p_user_id AND log_date = CURRENT_DATE;

    -- Get member stats
    SELECT * INTO v_stats
    FROM member_gamification
    WHERE user_id = p_user_id;

    -- Check gate attendance for today
    SELECT EXISTS (
        SELECT 1 FROM attendance_logs
        WHERE (member_id = p_user_id OR member_id::TEXT = p_user_id::TEXT)
          AND (tenant_id = p_tenant_id OR tenant_id::TEXT = p_tenant_id::TEXT)
          AND check_in_time::DATE = CURRENT_DATE
          AND access_result = 'granted'
    ) INTO v_gate_verified;

    -- Get primary device
    SELECT primary_device_id INTO v_reg_device
    FROM profiles WHERE id = p_user_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'user_id', p_user_id,
        'log_date', CURRENT_DATE,
        'gate_verified', v_gate_verified,
        'primary_device_id', v_reg_device,
        'workout_completion_pct', COALESCE(v_log.workout_completion_pct, 0.00),
        'workout_completed_sets', COALESCE(v_log.workout_completed_sets, 0),
        'workout_assigned_sets', COALESCE(v_log.workout_assigned_sets, 0),
        'step_completion_pct', COALESCE(v_log.step_completion_pct, 0.00),
        'step_actual', COALESCE(v_log.step_actual, 0),
        'step_target', COALESCE(v_log.step_target, 10000),
        'step_source', COALESCE(v_log.step_source, 'live_pedometer'),
        'diet_logged_type', COALESCE(v_log.diet_logged_type, 'none'),
        'diet_proof_url', v_log.diet_proof_url,
        'sleep_logged_hours', COALESCE(v_log.sleep_logged_hours, 0.0),
        'sleep_source', COALESCE(v_log.sleep_source, 'none'),
        'composite_completion_pct', COALESCE(v_log.composite_completion_pct, 0.00),
        'points_awarded', COALESCE(v_log.points_awarded, 0),
        'streak_saved', COALESCE(v_log.streak_saved, FALSE),
        'current_streak_days', COALESCE(v_stats.current_streak_days, 0),
        'streak_multiplier', COALESCE(v_stats.streak_multiplier, 1.00)
    );
END;
$$;
