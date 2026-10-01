-- ==============================================================================
-- GYMCONNECT ENTERPRISE SAAS: STRICT RULE 9 MIGRATION
-- Migration: 20261001000000_super_admin_feature_toggles_and_configs.sql
-- Purpose:
--   1. Super Admin Supremacy: Global system settings & centralized business logic
--   2. Strict allow_tenant_override Enforcement for all configs
--   3. Global & Tenant-Level Feature Toggling (AI Workouts, Gamification, Diet, Tools)
--   4. Full-Stack Backend RPC Enforcement for Phase 1 & Phase 2
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. GLOBAL SYSTEM SETTINGS TABLE (SUPER ADMIN CONTROLLED)
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS global_system_settings (
    key TEXT PRIMARY KEY,
    value JSONB NOT NULL DEFAULT '{}'::jsonb,
    allow_tenant_override BOOLEAN NOT NULL DEFAULT FALSE,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    updated_by UUID REFERENCES auth.users(id)
);

ALTER TABLE global_system_settings ENABLE ROW LEVEL SECURITY;

-- Select policy: Any authenticated user can read global settings/flags
DROP POLICY IF EXISTS "Authenticated users can view global system settings" ON global_system_settings;
CREATE POLICY "Authenticated users can view global system settings"
ON global_system_settings
FOR SELECT
TO authenticated
USING (TRUE);

-- Mutation policy: Strictly restricted to Super Admin
DROP POLICY IF EXISTS "Super admin full control on global system settings" ON global_system_settings;
CREATE POLICY "Super admin full control on global system settings"
ON global_system_settings
FOR ALL
TO authenticated
USING (
    COALESCE((auth.jwt() ->> 'role'), '') = 'super_admin' OR
    COALESCE((auth.jwt() -> 'user_metadata' ->> 'role'), '') = 'super_admin' OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
)
WITH CHECK (
    COALESCE((auth.jwt() ->> 'role'), '') = 'super_admin' OR
    COALESCE((auth.jwt() -> 'user_metadata' ->> 'role'), '') = 'super_admin' OR
    EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
);

-- ------------------------------------------------------------------------------
-- 2. TENANTS TABLE EXTENSIONS FOR FEATURE FLAGS & OVERRIDES
-- ------------------------------------------------------------------------------
ALTER TABLE IF EXISTS tenants
ADD COLUMN IF NOT EXISTS feature_flags JSONB NOT NULL DEFAULT '{
    "ai_workouts": true,
    "gamification": true,
    "diet_logs": true,
    "clinical_tools": true
}'::jsonb,
ADD COLUMN IF NOT EXISTS allow_tenant_overrides JSONB NOT NULL DEFAULT '{
    "ai_workouts": false,
    "gamification": false,
    "diet_logs": false,
    "clinical_tools": false
}'::jsonb,
ADD COLUMN IF NOT EXISTS config_overrides JSONB NOT NULL DEFAULT '{}'::jsonb;

-- ------------------------------------------------------------------------------
-- 3. SEED INITIAL GLOBAL CONFIGURATIONS & FEATURE FLAGS (PHASE 1 & 2)
-- ------------------------------------------------------------------------------
INSERT INTO global_system_settings (key, value, allow_tenant_override, description)
VALUES
(
    'feature_flags',
    '{
        "ai_workouts": true,
        "gamification": true,
        "diet_logs": true,
        "clinical_tools": true
    }'::jsonb,
    FALSE,
    'Master global killswitches for all enterprise modules. If false globally, feature is unconditionally disabled everywhere.'
),
(
    'ai_workout_config',
    '{
        "bmi_track_b_threshold": 28.0,
        "weight_track_b_threshold_kg": 90.0,
        "max_allowed_ai_age": 55,
        "cycle_duration_days": 90,
        "allow_manual_track_switch": false
    }'::jsonb,
    FALSE,
    'Phase 2 Static Master Engine & Silent BMI routing thresholds.'
),
(
    'gamification_config',
    '{
        "daily_step_goal": 6000,
        "step_points_multiplier": 1.0,
        "max_daily_points": 500,
        "anti_cheat_max_speed_kmh": 25.0,
        "streak_freeze_cooldown_days": 14,
        "age_minimum": 13
    }'::jsonb,
    FALSE,
    'Phase 1 Gamification, Leaderboards, Point caps, and Anti-Cheat speed tolerance.'
),
(
    'clinical_tools_config',
    '{
        "google_bmi_enabled": true,
        "calorie_calc_enabled": true,
        "macro_calc_enabled": true
    }'::jsonb,
    FALSE,
    'Clinical Tools and Google-style precision calculators configuration.'
)
ON CONFLICT (key) DO UPDATE
SET value = EXCLUDED.value,
    description = EXCLUDED.description;

-- ------------------------------------------------------------------------------
-- 4. PURE POSTGRESQL FEATURE TOGGLING ENFORCEMENT ENGINE
-- ------------------------------------------------------------------------------

-- 4.1 Check if a specific feature is enabled for a given tenant
CREATE OR REPLACE FUNCTION is_feature_enabled(
    p_tenant_id UUID,
    p_feature_key TEXT
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    v_global_flags JSONB;
    v_global_val BOOLEAN;
    v_tenant_flags JSONB;
    v_tenant_val BOOLEAN;
BEGIN
    -- 1. Check Global System Settings Killswitch
    SELECT value INTO v_global_flags 
    FROM global_system_settings 
    WHERE key = 'feature_flags';
    
    IF v_global_flags IS NOT NULL AND (v_global_flags ? p_feature_key) THEN
        v_global_val := (v_global_flags ->> p_feature_key)::BOOLEAN;
        -- If Super Admin globally killed the feature, it is unconditionally OFF
        IF v_global_val IS FALSE THEN
            RETURN FALSE;
        END IF;
    END IF;

    -- 2. If no tenant specified, return the global status (default true if not killed)
    IF p_tenant_id IS NULL THEN
        RETURN TRUE;
    END IF;

    -- 3. Check Tenant-Level Flag
    SELECT feature_flags INTO v_tenant_flags 
    FROM tenants 
    WHERE id = p_tenant_id;

    IF v_tenant_flags IS NOT NULL AND (v_tenant_flags ? p_feature_key) THEN
        v_tenant_val := (v_tenant_flags ->> p_feature_key)::BOOLEAN;
        IF v_tenant_val IS FALSE THEN
            RETURN FALSE;
        END IF;
    END IF;

    RETURN TRUE;
END;
$$;

-- 4.2 Get resolved effective feature flags map for UI consumption
CREATE OR REPLACE FUNCTION rpc_get_effective_feature_flags(p_tenant_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    v_global_flags JSONB;
    v_tenant_flags JSONB;
    v_result JSONB := '{}'::jsonb;
    v_key TEXT;
    v_is_enabled BOOLEAN;
BEGIN
    SELECT value INTO v_global_flags FROM global_system_settings WHERE key = 'feature_flags';
    IF v_global_flags IS NULL THEN
        v_global_flags := '{"ai_workouts": true, "gamification": true, "diet_logs": true, "clinical_tools": true}'::jsonb;
    END IF;

    IF p_tenant_id IS NOT NULL THEN
        SELECT feature_flags INTO v_tenant_flags FROM tenants WHERE id = p_tenant_id;
    END IF;
    IF v_tenant_flags IS NULL THEN
        v_tenant_flags := '{}'::jsonb;
    END IF;

    FOR v_key IN SELECT jsonb_object_keys(v_global_flags) LOOP
        v_is_enabled := is_feature_enabled(p_tenant_id, v_key);
        v_result := jsonb_set(v_result, ARRAY[v_key], to_jsonb(v_is_enabled));
    END LOOP;

    -- Inject dynamic max_allowed_ai_age into effective flags
    v_result := jsonb_set(
        v_result, 
        ARRAY['max_allowed_ai_age'], 
        COALESCE(
            (SELECT value -> 'max_allowed_ai_age' FROM global_system_settings WHERE key = 'ai_workout_config'), 
            '55'::jsonb
        )
    );

    RETURN v_result;
END;
$$;

-- 4.3 Get effective configuration (merges tenant override only if permitted by Super Admin)
CREATE OR REPLACE FUNCTION rpc_get_effective_system_config(
    p_tenant_id UUID,
    p_config_key TEXT
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    v_global_row global_system_settings%ROWTYPE;
    v_tenant_row tenants%ROWTYPE;
    v_can_override BOOLEAN := FALSE;
    v_tenant_override JSONB;
BEGIN
    SELECT * INTO v_global_row FROM global_system_settings WHERE key = p_config_key;
    IF NOT FOUND THEN
        RETURN '{}'::jsonb;
    END IF;

    -- Check if global setting allows tenant override
    v_can_override := v_global_row.allow_tenant_override;

    -- If no tenant, return pure global config
    IF p_tenant_id IS NULL THEN
        RETURN v_global_row.value;
    END IF;

    SELECT * INTO v_tenant_row FROM tenants WHERE id = p_tenant_id;
    IF NOT FOUND THEN
        RETURN v_global_row.value;
    END IF;

    -- Check if tenant explicitly has override permission in allow_tenant_overrides
    IF NOT v_can_override AND v_tenant_row.allow_tenant_overrides ? p_config_key THEN
        v_can_override := (v_tenant_row.allow_tenant_overrides ->> p_config_key)::BOOLEAN;
    END IF;

    -- If override permitted and tenant has override, merge it on top of global
    IF v_can_override AND v_tenant_row.config_overrides ? p_config_key THEN
        v_tenant_override := v_tenant_row.config_overrides -> p_config_key;
        RETURN v_global_row.value || v_tenant_override;
    END IF;

    RETURN v_global_row.value;
END;
$$;

-- ------------------------------------------------------------------------------
-- 5. SUPER ADMIN CONTROL RPCs (MUTATIONS)
-- ------------------------------------------------------------------------------

-- 5.1 Super Admin: Set global feature flag & its allow_tenant_override setting
CREATE OR REPLACE FUNCTION rpc_super_admin_set_global_feature_flag(
    p_feature_key TEXT,
    p_enabled BOOLEAN,
    p_allow_tenant_override BOOLEAN DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_admin BOOLEAN;
    v_current_flags JSONB;
    v_new_flags JSONB;
    v_current_override BOOLEAN;
BEGIN
    SELECT (
        COALESCE((auth.jwt() ->> 'role'), '') = 'super_admin' OR
        COALESCE((auth.jwt() -> 'user_metadata' ->> 'role'), '') = 'super_admin' OR
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
    ) INTO v_is_admin;

    IF NOT COALESCE(v_is_admin, FALSE) THEN
        RAISE EXCEPTION 'PERMISSION DENIED: Super Admin supremacy required to mutate global feature flags.';
    END IF;

    SELECT value, allow_tenant_override INTO v_current_flags, v_current_override
    FROM global_system_settings 
    WHERE key = 'feature_flags';

    IF v_current_flags IS NULL THEN
        v_current_flags := '{}'::jsonb;
    END IF;

    v_new_flags := jsonb_set(v_current_flags, ARRAY[p_feature_key], to_jsonb(p_enabled));

    INSERT INTO global_system_settings (key, value, allow_tenant_override, updated_at, updated_by)
    VALUES (
        'feature_flags',
        v_new_flags,
        COALESCE(p_allow_tenant_override, v_current_override, FALSE),
        NOW(),
        auth.uid()
    )
    ON CONFLICT (key) DO UPDATE SET
        value = v_new_flags,
        allow_tenant_override = COALESCE(p_allow_tenant_override, global_system_settings.allow_tenant_override),
        updated_at = NOW(),
        updated_by = auth.uid();

    RETURN jsonb_build_object(
        'success', TRUE,
        'feature_key', p_feature_key,
        'enabled', p_enabled,
        'allow_tenant_override', COALESCE(p_allow_tenant_override, v_current_override, FALSE)
    );
END;
$$;

-- 5.2 Super Admin: Set tenant-specific feature flag & tenant override permission
CREATE OR REPLACE FUNCTION rpc_super_admin_set_tenant_feature_flag(
    p_tenant_id UUID,
    p_feature_key TEXT,
    p_enabled BOOLEAN,
    p_allow_tenant_override BOOLEAN DEFAULT FALSE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_admin BOOLEAN;
    v_flags JSONB;
    v_overrides JSONB;
BEGIN
    SELECT (
        COALESCE((auth.jwt() ->> 'role'), '') = 'super_admin' OR
        COALESCE((auth.jwt() -> 'user_metadata' ->> 'role'), '') = 'super_admin' OR
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
    ) INTO v_is_admin;

    IF NOT COALESCE(v_is_admin, FALSE) THEN
        RAISE EXCEPTION 'PERMISSION DENIED: Super Admin supremacy required to set tenant feature flags.';
    END IF;

    SELECT feature_flags, allow_tenant_overrides INTO v_flags, v_overrides
    FROM tenants WHERE id = p_tenant_id;

    IF v_flags IS NULL THEN v_flags := '{}'::jsonb; END IF;
    IF v_overrides IS NULL THEN v_overrides := '{}'::jsonb; END IF;

    v_flags := jsonb_set(v_flags, ARRAY[p_feature_key], to_jsonb(p_enabled));
    v_overrides := jsonb_set(v_overrides, ARRAY[p_feature_key], to_jsonb(p_allow_tenant_override));

    UPDATE tenants SET
        feature_flags = v_flags,
        allow_tenant_overrides = v_overrides,
        updated_at = NOW()
    WHERE id = p_tenant_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'tenant_id', p_tenant_id,
        'feature_key', p_feature_key,
        'enabled', p_enabled,
        'allow_tenant_override', p_allow_tenant_override
    );
END;
$$;

-- 5.3 Super Admin: Update global configuration variables (age limits, thresholds, etc.)
CREATE OR REPLACE FUNCTION rpc_super_admin_update_global_config(
    p_config_key TEXT,
    p_value JSONB,
    p_allow_tenant_override BOOLEAN DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_admin BOOLEAN;
BEGIN
    SELECT (
        COALESCE((auth.jwt() ->> 'role'), '') = 'super_admin' OR
        COALESCE((auth.jwt() -> 'user_metadata' ->> 'role'), '') = 'super_admin' OR
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
    ) INTO v_is_admin;

    IF NOT COALESCE(v_is_admin, FALSE) THEN
        RAISE EXCEPTION 'PERMISSION DENIED: Super Admin supremacy required to modify system configuration.';
    END IF;

    INSERT INTO global_system_settings (key, value, allow_tenant_override, updated_at, updated_by)
    VALUES (
        p_config_key,
        p_value,
        COALESCE(p_allow_tenant_override, FALSE),
        NOW(),
        auth.uid()
    )
    ON CONFLICT (key) DO UPDATE SET
        value = p_value,
        allow_tenant_override = COALESCE(p_allow_tenant_override, global_system_settings.allow_tenant_override),
        updated_at = NOW(),
        updated_by = auth.uid();

    RETURN jsonb_build_object(
        'success', TRUE,
        'config_key', p_config_key,
        'value', p_value,
        'allow_tenant_override', COALESCE(p_allow_tenant_override, FALSE)
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 6. TENANT OVERRIDE RPC WITH STRICT SECURITY ENFORCEMENT
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rpc_tenant_owner_update_config_override(
    p_tenant_id UUID,
    p_config_key TEXT,
    p_override_value JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_owner BOOLEAN;
    v_global_row global_system_settings%ROWTYPE;
    v_tenant_row tenants%ROWTYPE;
    v_allowed BOOLEAN := FALSE;
    v_overrides JSONB;
BEGIN
    -- Verify caller is gym owner for this tenant
    SELECT (
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND tenant_id = p_tenant_id AND role = 'owner') OR
        COALESCE((auth.jwt() ->> 'role'), '') = 'super_admin'
    ) INTO v_is_owner;

    IF NOT COALESCE(v_is_owner, FALSE) THEN
        RAISE EXCEPTION 'PERMISSION DENIED: Caller is not an authorized owner of tenant %.', p_tenant_id;
    END IF;

    -- Strict Rule 9 Check: Inspect allow_tenant_override
    SELECT * INTO v_global_row FROM global_system_settings WHERE key = p_config_key;
    IF FOUND AND v_global_row.allow_tenant_override THEN
        v_allowed := TRUE;
    END IF;

    SELECT * INTO v_tenant_row FROM tenants WHERE id = p_tenant_id;
    IF FOUND AND v_tenant_row.allow_tenant_overrides ? p_config_key THEN
        IF (v_tenant_row.allow_tenant_overrides ->> p_config_key)::BOOLEAN THEN
            v_allowed := TRUE;
        END IF;
    END IF;

    IF NOT v_allowed THEN
        RAISE EXCEPTION 'PERMISSION DENIED (Rule 9): Super Admin has locked % configuration. allow_tenant_override is disabled.', p_config_key;
    END IF;

    v_overrides := COALESCE(v_tenant_row.config_overrides, '{}'::jsonb);
    v_overrides := jsonb_set(v_overrides, ARRAY[p_config_key], p_override_value);

    UPDATE tenants SET
        config_overrides = v_overrides,
        updated_at = NOW()
    WHERE id = p_tenant_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'tenant_id', p_tenant_id,
        'config_key', p_config_key,
        'override_saved', p_override_value
    );
END;
$$;

-- ------------------------------------------------------------------------------
-- 7. ENFORCE FEATURE TOGGLES IN PHASE 1 & PHASE 2 RPCs
-- ------------------------------------------------------------------------------

-- Update rpc_assign_static_master_workout_protocol with feature flag check
DROP FUNCTION IF EXISTS rpc_assign_static_master_workout_protocol(UUID, DOUBLE PRECISION, DOUBLE PRECISION, INT, TEXT[], VARCHAR, VARCHAR);
CREATE OR REPLACE FUNCTION rpc_assign_static_master_workout_protocol(
    p_user_id UUID,
    p_weight_kg DOUBLE PRECISION DEFAULT NULL,
    p_height_cm DOUBLE PRECISION DEFAULT NULL,
    p_age INT DEFAULT NULL,
    p_medical_injuries TEXT[] DEFAULT NULL,
    p_override_track VARCHAR DEFAULT NULL,
    p_target_body_type VARCHAR DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_profile user_fitness_profiles%ROWTYPE;
    v_tenant_id UUID;
    v_weight DOUBLE PRECISION;
    v_height DOUBLE PRECISION;
    v_age INT;
    v_injuries TEXT[];
    v_bmi DOUBLE PRECISION;
    v_assigned_track VARCHAR(50);
    v_target_body_type VARCHAR(50);
    v_routing_reason TEXT;
    v_level VARCHAR(50);
    v_master_routine_id UUID;
    v_template_title TEXT;
    v_template_goal VARCHAR(100);
    v_template_body_type VARCHAR(50);
    v_user_routine_id UUID;
    v_day_record RECORD;
    v_new_day_id UUID;
    v_item_record RECORD;
    v_candidate_exercise_id UUID;
    v_swapped_count INT := 0;
    v_days_count INT := 0;
    v_exercises_count INT := 0;
BEGIN
    -- A. Fetch Member Fitness Profile
    SELECT * INTO v_profile
    FROM user_fitness_profiles
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Fitness profile not found for user: ' || p_user_id
        );
    END IF;

    SELECT tenant_id INTO v_tenant_id
    FROM profiles
    WHERE id = p_user_id;

    -- =========================================================================
    -- STRICT RULE 9 ENFORCEMENT: Check if AI Workouts feature is enabled
    -- =========================================================================
    IF NOT is_feature_enabled(v_tenant_id, 'ai_workouts') THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'AI Workout Engine is currently disabled by Super Administrator.',
            'feature_disabled', TRUE
        );
    END IF;

    -- B. Resolve Effective Target Body Type & Physiological Metrics
    v_target_body_type := LOWER(TRIM(COALESCE(p_target_body_type, v_profile.body_type::text, 'mesomorph')));
    v_target_body_type := COALESCE(NULLIF(v_target_body_type, ''), 'mesomorph');

    v_weight := COALESCE(p_weight_kg, v_profile.current_weight_kg, 70.0);
    v_height := COALESCE(p_height_cm, v_profile.height_cm, 175.0);
    v_age := COALESCE(p_age, v_profile.age, 25);
    v_injuries := COALESCE(p_medical_injuries, v_profile.medical_injuries, '{}'::TEXT[]);
    v_level := COALESCE(v_profile.experience_level, 'beginner');

    -- Compute BMI: weight (kg) / (height (m) ^ 2)
    IF v_height > 0 THEN
        v_bmi := v_weight / ((v_height / 100.0) * (v_height / 100.0));
    ELSE
        v_bmi := 22.0;
    END IF;

    -- =========================================================================
    -- STRICT LIABILITY & RULE 9 ENFORCEMENT: Block AI workouts for seniors
    -- =========================================================================
    IF v_age >= COALESCE((SELECT (value ->> 'max_allowed_ai_age')::INT FROM global_system_settings WHERE key = 'ai_workout_config'), 55) THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Liability Safety Notice: Members aged ' || COALESCE((SELECT (value ->> 'max_allowed_ai_age')::INT FROM global_system_settings WHERE key = 'ai_workout_config'), 55) || '+ require in-person certified trainer evaluation before initiating gym workouts.',
            'liability_blocked', TRUE,
            'max_allowed_ai_age', COALESCE((SELECT (value ->> 'max_allowed_ai_age')::INT FROM global_system_settings WHERE key = 'ai_workout_config'), 55)
        );
    END IF;

    -- C. Silent BMI & Overweight Routing (Track A vs Track B)
    -- High BMI (BMI >= 28.0) OR Weight >= 90kg -> Track B (Low-Impact)
    -- Normal/Low BMI -> Track A (Dynamic Progressive Overload)
    IF p_override_track IS NOT NULL AND p_override_track IN ('track_a', 'track_b') THEN
        v_assigned_track := p_override_track;
        v_routing_reason := 'Explicitly assigned to ' || UPPER(p_override_track) || '.';
    ELSIF v_weight >= 90.0 OR (v_bmi >= 28.0 AND v_level IN ('beginner', 'novice', 'intermediate')) THEN
        v_assigned_track := 'track_b';
        v_routing_reason := 'Silent BMI (' || ROUND(v_bmi::numeric, 1) || ') or bodyweight (' || ROUND(v_weight::numeric, 1) || 'kg) routed to Track B Low-Impact Foundation for ' || UPPER(v_target_body_type) || '.';
    ELSE
        v_assigned_track := 'track_a';
        v_routing_reason := 'Assigned Track A Dynamic Progressive Protocol for ' || UPPER(v_target_body_type) || ' based on normal BMI (' || ROUND(v_bmi::numeric, 1) || ').';
    END IF;

    -- D. Locate Master 90-Day Routine for Target Body Type and Assigned Track
    IF v_tenant_id IS NOT NULL THEN
        SELECT r.id, r.title, r.target_goal, r.body_type 
        INTO v_master_routine_id, v_template_title, v_template_goal, v_template_body_type
        FROM workout_routines r
        WHERE r.tenant_id = v_tenant_id 
          AND LOWER(r.body_type) = v_target_body_type
          AND r.assigned_track = v_assigned_track 
          AND r.user_id IS NULL
        ORDER BY r.created_at DESC
        LIMIT 1;
    END IF;

    IF v_master_routine_id IS NULL THEN
        SELECT r.id, r.title, r.target_goal, r.body_type 
        INTO v_master_routine_id, v_template_title, v_template_goal, v_template_body_type
        FROM workout_routines r
        WHERE r.tenant_id IS NULL 
          AND LOWER(r.body_type) = v_target_body_type
          AND r.assigned_track = v_assigned_track 
          AND r.user_id IS NULL
        ORDER BY r.created_at DESC
        LIMIT 1;
    END IF;

    -- Fallback to master template for the assigned track if specific body type is not yet seeded
    IF v_master_routine_id IS NULL THEN
        SELECT r.id, r.title, r.target_goal, r.body_type 
        INTO v_master_routine_id, v_template_title, v_template_goal, v_template_body_type
        FROM workout_routines r
        WHERE r.assigned_track = v_assigned_track 
          AND r.user_id IS NULL
        ORDER BY (r.tenant_id = v_tenant_id) DESC, (LOWER(r.body_type) = 'mesomorph') DESC, r.created_at DESC
        LIMIT 1;
    END IF;

    IF v_master_routine_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'No master 90-day template found for body type ' || UPPER(v_target_body_type) || ' on ' || UPPER(v_assigned_track)
        );
    END IF;

    -- E. Remove previous personalized routine for this member
    DELETE FROM workout_routines 
    WHERE user_id = p_user_id;

    -- F. Clone Master Template to create Member Personalized Routine
    INSERT INTO workout_routines (
        tenant_id,
        user_id,
        title,
        description,
        target_goal,
        duration_days,
        is_ai_generated,
        is_public_preview,
        body_type,
        assigned_track
    ) VALUES (
        v_tenant_id,
        p_user_id,
        v_template_title || ' (Personalized)',
        'Assigned from Master 90-Day ' || UPPER(v_assigned_track) || ' Template. ' || v_routing_reason,
        COALESCE(v_template_goal, 'general_fitness'),
        90,
        FALSE,
        FALSE,
        v_target_body_type,
        v_assigned_track
    )
    RETURNING id INTO v_user_routine_id;

    -- G. Clone Routine Days and Swap Exercises Conflicting with Medical Injuries
    FOR v_day_record IN 
        SELECT rd.id, rd.day_number, rd.title, rd.muscle_groups, rd.is_rest_day
        FROM workout_routine_days rd
        WHERE rd.routine_id = v_master_routine_id
        ORDER BY rd.day_number
    LOOP
        INSERT INTO workout_routine_days (
            routine_id,
            day_number,
            title,
            muscle_groups,
            is_rest_day
        ) VALUES (
            v_user_routine_id,
            v_day_record.day_number,
            v_day_record.title,
            v_day_record.muscle_groups,
            v_day_record.is_rest_day
        )
        RETURNING id INTO v_new_day_id;

        v_days_count := v_days_count + 1;

        IF NOT v_day_record.is_rest_day THEN
            FOR v_item_record IN 
                SELECT 
                    rdi.exercise_id,
                    rdi.sets,
                    rdi.target_reps,
                    rdi.rest_seconds,
                    rdi.target_weight_kg,
                    rdi.order_in_day,
                    rdi.day_specific_tip,
                    e.swap_group_id,
                    e.contraindicated_injuries,
                    e.name AS exercise_name
                FROM routine_day_items rdi
                JOIN exercises e ON e.id = rdi.exercise_id
                WHERE rdi.routine_day_id = v_day_record.id
                ORDER BY rdi.order_in_day
            LOOP
                v_candidate_exercise_id := v_item_record.exercise_id;

                IF v_injuries IS NOT NULL AND array_length(v_injuries, 1) > 0 AND
                   v_item_record.contraindicated_injuries && v_injuries THEN
                    
                    SELECT e_sub.id INTO v_candidate_exercise_id
                    FROM exercises e_sub
                    WHERE e_sub.swap_group_id = v_item_record.swap_group_id
                      AND e_sub.id <> v_item_record.exercise_id
                      AND NOT (e_sub.contraindicated_injuries && v_injuries)
                      AND (v_assigned_track <> 'track_b' OR (
                          LOWER(e_sub.name) NOT LIKE '%jump%' AND 
                          LOWER(e_sub.name) NOT LIKE '%deadlift%'
                      ))
                    LIMIT 1;

                    IF v_candidate_exercise_id IS NOT NULL THEN
                        v_swapped_count := v_swapped_count + 1;
                    ELSE
                        v_candidate_exercise_id := v_item_record.exercise_id;
                    END IF;
                END IF;

                INSERT INTO routine_day_items (
                    routine_day_id,
                    exercise_id,
                    sets,
                    target_reps,
                    rest_seconds,
                    target_weight_kg,
                    order_in_day,
                    day_specific_tip
                ) VALUES (
                    v_new_day_id,
                    v_candidate_exercise_id,
                    v_item_record.sets,
                    v_item_record.target_reps,
                    v_item_record.rest_seconds,
                    v_item_record.target_weight_kg,
                    v_item_record.order_in_day,
                    v_item_record.day_specific_tip
                );

                v_exercises_count := v_exercises_count + 1;
            END LOOP;
        END IF;
    END LOOP;

    -- H. Bind Routine to User's Fitness Profile
    UPDATE user_fitness_profiles SET
        body_type = v_target_body_type,
        current_workout_routine_id = v_user_routine_id,
        assigned_workout_track = v_assigned_track,
        current_weight_kg = COALESCE(v_weight, current_weight_kg),
        height_cm = COALESCE(v_height, height_cm),
        age = COALESCE(v_age, age),
        medical_injuries = v_injuries,
        profile_completed = TRUE,
        ai_recommendations = jsonb_build_object(
            'engine_type', 'static_master_template',
            'master_template_id', v_master_routine_id,
            'user_routine_id', v_user_routine_id,
            'target_body_type', v_target_body_type,
            'assigned_track', v_assigned_track,
            'bmi', ROUND(v_bmi::numeric, 2),
            'routing_reason', v_routing_reason,
            'swapped_exercises_count', v_swapped_count,
            'assigned_at', NOW()
        ),
        updated_at = NOW()
    WHERE user_id = p_user_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'routine_id', v_user_routine_id,
        'master_template_id', v_master_routine_id,
        'assigned_track', v_assigned_track,
        'bmi', ROUND(v_bmi::numeric, 2),
        'routing_reason', v_routing_reason,
        'swapped_exercises_count', v_swapped_count,
        'days_assigned', v_days_count,
        'exercises_mapped', v_exercises_count,
        'routine_title', v_template_title || ' (Personalized)'
    );
END;
$$;
