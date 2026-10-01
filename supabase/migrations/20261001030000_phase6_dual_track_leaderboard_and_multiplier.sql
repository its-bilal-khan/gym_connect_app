-- ==============================================================================
-- Migration: 20261001030000_phase6_dual_track_leaderboard_and_multiplier.sql
-- Description: Phase 6 Gamification SaaS: Dual-Track Leaderboard, Veteran Multiplier
--              Engine, Baseline Workout Qualification & Monthly Podium Archives
-- ==============================================================================

-- 1. Ensure Phase 6 Feature Flags in global_system_settings
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM global_system_settings WHERE key = 'feature_flags') THEN
        UPDATE global_system_settings
        SET value = value || '{
            "leaderboard_dual_track": true,
            "veteran_multiplier": true,
            "monthly_podium_archives": true
        }'::jsonb,
        updated_at = NOW()
        WHERE key = 'feature_flags';
    END IF;
END $$;

-- 2. Seed Phase 6 Global Leaderboard & Multiplier Settings
INSERT INTO global_system_settings (key, value, allow_tenant_override, description)
VALUES (
    'phase6_leaderboard_config',
    '{
        "default_qualification_workouts": 18,
        "podium_size": 3,
        "veteran_multiplier_tiers": {
            "tier_1": {"min_days": 14, "multiplier": 1.10, "label": "Iron Warrior"},
            "tier_2": {"min_days": 30, "multiplier": 1.25, "label": "Beast Mode Elite"},
            "tier_3": {"min_days": 60, "multiplier": 1.50, "label": "Legendary Titan"}
        },
        "track_a_name": "Monthly Race",
        "track_b_name": "Hall of Fame"
    }'::jsonb,
    TRUE,
    'Super Admin configuration for dual-track leaderboard, qualification threshold, and veteran streak multipliers.'
)
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    allow_tenant_override = EXCLUDED.allow_tenant_override,
    description = EXCLUDED.description,
    updated_at = NOW();

-- 3. Update Tenants Feature Flags with Phase 6 Defaults
UPDATE tenants
SET feature_flags = feature_flags || '{
    "leaderboard_dual_track": true,
    "veteran_multiplier": true,
    "monthly_podium_archives": true
}'::jsonb
WHERE feature_flags IS NOT NULL;

-- 4. RPC: Calculate Veteran Multiplier for a Given Streak
CREATE OR REPLACE FUNCTION rpc_calculate_veteran_multiplier(
    p_streak_days INT,
    p_tenant_id UUID DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_tier_config JSONB;
    v_t1_days INT := 14;
    v_t1_mult NUMERIC(3,2) := 1.10;
    v_t2_days INT := 30;
    v_t2_mult NUMERIC(3,2) := 1.25;
    v_t3_days INT := 60;
    v_t3_mult NUMERIC(3,2) := 1.50;
    v_active_mult NUMERIC(3,2) := 1.00;
    v_current_tier VARCHAR(50) := 'Standard';
    v_next_tier VARCHAR(50) := 'Iron Warrior';
    v_days_to_next INT := 14;
BEGIN
    IF p_tenant_id IS NOT NULL THEN
        SELECT veteran_multiplier_config INTO v_tier_config
        FROM tenants WHERE id = p_tenant_id;

        IF v_tier_config IS NOT NULL THEN
            v_t1_days := COALESCE((v_tier_config->>'tier_1_days')::INT, 14);
            v_t1_mult := COALESCE((v_tier_config->>'tier_1_multiplier')::NUMERIC, 1.10);
            v_t2_days := COALESCE((v_tier_config->>'tier_2_days')::INT, 30);
            v_t2_mult := COALESCE((v_tier_config->>'tier_2_multiplier')::NUMERIC, 1.25);
            v_t3_days := COALESCE((v_tier_config->>'tier_3_days')::INT, 60);
            v_t3_mult := COALESCE((v_tier_config->>'tier_3_multiplier')::NUMERIC, 1.50);
        END IF;
    END IF;

    IF p_streak_days >= v_t3_days THEN
        v_active_mult := v_t3_mult;
        v_current_tier := 'Legendary Titan';
        v_next_tier := 'Maximum Tier Achieved';
        v_days_to_next := 0;
    ELSIF p_streak_days >= v_t2_days THEN
        v_active_mult := v_t2_mult;
        v_current_tier := 'Beast Mode Elite';
        v_next_tier := 'Legendary Titan';
        v_days_to_next := v_t3_days - p_streak_days;
    ELSIF p_streak_days >= v_t1_days THEN
        v_active_mult := v_t1_mult;
        v_current_tier := 'Iron Warrior';
        v_next_tier := 'Beast Mode Elite';
        v_days_to_next := v_t2_days - p_streak_days;
    ELSE
        v_active_mult := 1.00;
        v_current_tier := 'Rising Contender';
        v_next_tier := 'Iron Warrior';
        v_days_to_next := v_t1_days - p_streak_days;
    END IF;

    RETURN jsonb_build_object(
        'streak_days', p_streak_days,
        'multiplier', v_active_mult,
        'current_tier', v_current_tier,
        'next_tier', v_next_tier,
        'days_to_next', v_days_to_next
    );
END;
$$;

-- 5. RPC: Member Real-Time Leaderboard Telemetry
CREATE OR REPLACE FUNCTION rpc_get_member_leaderboard_status(
    p_user_id UUID,
    p_tenant_id UUID
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_mg RECORD;
    v_min_workouts INT := 18;
    v_monthly_rank INT := 0;
    v_hall_rank INT := 0;
    v_multiplier_info JSONB;
    v_is_qualified BOOLEAN := FALSE;
    v_workouts_remaining INT := 0;
BEGIN
    SELECT min_monthly_workouts_qualification INTO v_min_workouts
    FROM tenants WHERE id = p_tenant_id;
    IF v_min_workouts IS NULL THEN
        v_min_workouts := 18;
    END IF;

    SELECT * INTO v_mg
    FROM member_gamification
    WHERE user_id = p_user_id;

    IF v_mg IS NULL THEN
        RETURN jsonb_build_object(
            'has_gamification', FALSE,
            'monthly_rank', 0,
            'hall_of_fame_rank', 0,
            'monthly_points', 0,
            'current_streak_days', 0,
            'streak_multiplier', 1.00,
            'is_qualified', FALSE,
            'monthly_workouts_completed', 0,
            'workouts_required', v_min_workouts,
            'workouts_remaining', v_min_workouts
        );
    END IF;

    -- Calculate rank in active monthly race
    SELECT COUNT(*) + 1 INTO v_monthly_rank
    FROM member_gamification
    WHERE tenant_id = p_tenant_id
      AND monthly_points > v_mg.monthly_points;

    -- Calculate rank in Hall of Fame (longest streak)
    SELECT COUNT(*) + 1 INTO v_hall_rank
    FROM member_gamification
    WHERE tenant_id = p_tenant_id
      AND longest_streak_days > v_mg.longest_streak_days;

    -- Check qualification
    IF v_mg.monthly_workouts_completed >= v_min_workouts THEN
        v_is_qualified := TRUE;
        v_workouts_remaining := 0;
    ELSE
        v_is_qualified := FALSE;
        v_workouts_remaining := v_min_workouts - v_mg.monthly_workouts_completed;
    END IF;

    -- Multiplier info
    v_multiplier_info := rpc_calculate_veteran_multiplier(v_mg.current_streak_days, p_tenant_id);

    RETURN jsonb_build_object(
        'has_gamification', TRUE,
        'user_id', p_user_id,
        'tenant_id', p_tenant_id,
        'monthly_rank', v_monthly_rank,
        'hall_of_fame_rank', v_hall_rank,
        'monthly_points', v_mg.monthly_points,
        'total_points', v_mg.total_points,
        'current_streak_days', v_mg.current_streak_days,
        'longest_streak_days', v_mg.longest_streak_days,
        'monthly_workouts_completed', v_mg.monthly_workouts_completed,
        'workouts_required', v_min_workouts,
        'workouts_remaining', v_workouts_remaining,
        'is_qualified', v_is_qualified,
        'streak_multiplier', COALESCE((v_multiplier_info->>'multiplier')::NUMERIC, 1.00),
        'multiplier_details', v_multiplier_info
    );
END;
$$;
