-- ==============================================================================
-- GYMCONNECT ENTERPRISE SAAS: STRICT RULE 9 MIGRATION
-- Migration: 20261002010000_vision_ai_live_trainer_full_config.sql
-- Purpose:
--   1. Super Admin Supremacy: Centralized vision_ai_config in global_system_settings
--   2. Strict allow_tenant_override Support for B2B SaaS Tenants
--   3. Dynamic Biomechanics Thresholds: Squat depth, Pushup depth, Bad Posture delay,
--      TTS Cooldown, and Micro-Clip Duration
--   4. Global & Tenant-Level RPCs for Configuration Retrieval and Mutation
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. SEED / UPDATE GLOBAL SYSTEM SETTINGS WITH VISION AI CONFIG
-- ------------------------------------------------------------------------------
INSERT INTO global_system_settings (key, value, allow_tenant_override, description)
VALUES (
    'vision_ai_config',
    '{
        "is_live_trainer_enabled": true,
        "squat_depth_angle": 90.0,
        "pushup_depth_angle": 85.0,
        "bad_posture_trigger_ms": 1000,
        "tts_cooldown_seconds": 3.2,
        "micro_clip_duration_sec": 8
    }'::jsonb,
    TRUE,
    'Super Admin master configuration for Vision AI Live Trainer: joint thresholds, voice coaching debounce, and micro-clips.'
)
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    allow_tenant_override = EXCLUDED.allow_tenant_override,
    description = EXCLUDED.description,
    updated_at = NOW();

-- ------------------------------------------------------------------------------
-- 2. ENSURE MASTER FEATURE FLAG FOR VISION AI LIVE TRAINER
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM global_system_settings WHERE key = 'feature_flags') THEN
        UPDATE global_system_settings
        SET value = value || '{"vision_ai_live_trainer": true}'::jsonb,
            updated_at = NOW()
        WHERE key = 'feature_flags';
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 3. UPDATE TENANTS TABLE DEFAULT FEATURE FLAGS & OVERRIDES
-- ------------------------------------------------------------------------------
UPDATE tenants
SET feature_flags = feature_flags || '{"vision_ai_live_trainer": true}'::jsonb,
    allow_tenant_overrides = allow_tenant_overrides || '{"vision_ai_config": true}'::jsonb
WHERE feature_flags IS NOT NULL;

-- ------------------------------------------------------------------------------
-- 4. RPC: GET RESOLVED EFFECTIVE VISION AI CONFIG
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rpc_get_vision_ai_config(p_tenant_id UUID DEFAULT NULL)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    v_global_row global_system_settings%ROWTYPE;
    v_tenant_row tenants%ROWTYPE;
    v_can_override BOOLEAN := FALSE;
    v_result JSONB;
BEGIN
    -- 1. Fetch global config
    SELECT * INTO v_global_row FROM global_system_settings WHERE key = 'vision_ai_config';
    IF NOT FOUND THEN
        v_result := '{
            "is_live_trainer_enabled": true,
            "squat_depth_angle": 90.0,
            "pushup_depth_angle": 85.0,
            "bad_posture_trigger_ms": 1000,
            "tts_cooldown_seconds": 3.2,
            "micro_clip_duration_sec": 8
        }'::jsonb;
    ELSE
        v_result := v_global_row.value;
        v_can_override := v_global_row.allow_tenant_override;
    END IF;

    -- 2. If tenant specified, check override
    IF p_tenant_id IS NOT NULL THEN
        SELECT * INTO v_tenant_row FROM tenants WHERE id = p_tenant_id;
        IF FOUND THEN
            -- Check if tenant explicitly has override permission
            IF NOT v_can_override AND v_tenant_row.allow_tenant_overrides ? 'vision_ai_config' THEN
                v_can_override := (v_tenant_row.allow_tenant_overrides ->> 'vision_ai_config')::BOOLEAN;
            END IF;

            -- Check if vision_ai_live_trainer feature flag is disabled for this tenant
            IF v_tenant_row.feature_flags ? 'vision_ai_live_trainer' THEN
                v_result := jsonb_set(
                    v_result, 
                    '{is_live_trainer_enabled}', 
                    v_tenant_row.feature_flags -> 'vision_ai_live_trainer'
                );
            END IF;

            -- Merge config override if allowed
            IF v_can_override AND v_tenant_row.config_overrides ? 'vision_ai_config' THEN
                v_result := v_result || (v_tenant_row.config_overrides -> 'vision_ai_config');
            END IF;
        END IF;
    END IF;

    -- Inject allow_tenant_override flag into the output object for UI state management
    v_result := jsonb_set(v_result, '{allow_tenant_override}', to_jsonb(v_can_override));

    RETURN v_result;
END;
$$;

-- ------------------------------------------------------------------------------
-- 5. RPC: MUTATE VISION AI CONFIG (SUPER ADMIN OR TENANT OWNER)
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION rpc_update_vision_ai_config(
    p_tenant_id UUID DEFAULT NULL,
    p_config JSONB DEFAULT '{}'::jsonb,
    p_allow_tenant_override BOOLEAN DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_is_super_admin BOOLEAN;
    v_is_owner BOOLEAN;
    v_global_row global_system_settings%ROWTYPE;
    v_can_override BOOLEAN := FALSE;
    v_overrides JSONB;
    v_flags JSONB;
BEGIN
    -- Determine role
    SELECT (
        COALESCE((auth.jwt() ->> 'role'), '') = 'super_admin' OR
        COALESCE((auth.jwt() -> 'user_metadata' ->> 'role'), '') = 'super_admin' OR
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND role = 'super_admin')
    ) INTO v_is_super_admin;

    -- Global mutation (Super Admin only)
    IF p_tenant_id IS NULL THEN
        IF NOT COALESCE(v_is_super_admin, FALSE) THEN
            RAISE EXCEPTION 'PERMISSION DENIED: Super Admin supremacy required to mutate global Vision AI configuration.';
        END IF;

        INSERT INTO global_system_settings (key, value, allow_tenant_override, updated_at, updated_by)
        VALUES (
            'vision_ai_config',
            p_config,
            COALESCE(p_allow_tenant_override, TRUE),
            NOW(),
            auth.uid()
        )
        ON CONFLICT (key) DO UPDATE SET
            value = p_config,
            allow_tenant_override = COALESCE(p_allow_tenant_override, global_system_settings.allow_tenant_override),
            updated_at = NOW(),
            updated_by = auth.uid();

        -- Also sync global feature flag if is_live_trainer_enabled is present
        IF p_config ? 'is_live_trainer_enabled' THEN
            UPDATE global_system_settings
            SET value = jsonb_set(value, '{vision_ai_live_trainer}', p_config -> 'is_live_trainer_enabled'),
                updated_at = NOW()
            WHERE key = 'feature_flags';
        END IF;

        RETURN jsonb_build_object(
            'success', TRUE,
            'scope', 'global',
            'config', p_config,
            'allow_tenant_override', COALESCE(p_allow_tenant_override, TRUE)
        );
    END IF;

    -- Tenant-specific mutation
    SELECT (
        COALESCE(v_is_super_admin, FALSE) OR
        EXISTS (SELECT 1 FROM profiles WHERE id = auth.uid() AND tenant_id = p_tenant_id AND role IN ('owner', 'admin'))
    ) INTO v_is_owner;

    IF NOT COALESCE(v_is_owner, FALSE) THEN
        RAISE EXCEPTION 'PERMISSION DENIED: Tenant owner or Super Admin role required to update tenant Vision AI settings.';
    END IF;

    -- If not super admin, ensure tenant override is permitted
    IF NOT COALESCE(v_is_super_admin, FALSE) THEN
        SELECT allow_tenant_override INTO v_can_override FROM global_system_settings WHERE key = 'vision_ai_config';
        IF NOT COALESCE(v_can_override, FALSE) THEN
            SELECT (allow_tenant_overrides ->> 'vision_ai_config')::BOOLEAN INTO v_can_override
            FROM tenants WHERE id = p_tenant_id;
        END IF;

        IF NOT COALESCE(v_can_override, FALSE) THEN
            RAISE EXCEPTION 'PERMISSION DENIED: Super Admin has locked Vision AI configuration overrides for this tenant.';
        END IF;
    END IF;

    -- Update tenant overrides
    SELECT config_overrides, feature_flags INTO v_overrides, v_flags FROM tenants WHERE id = p_tenant_id;
    IF v_overrides IS NULL THEN v_overrides := '{}'::jsonb; END IF;
    IF v_flags IS NULL THEN v_flags := '{}'::jsonb; END IF;

    v_overrides := jsonb_set(v_overrides, '{vision_ai_config}', p_config);
    IF p_config ? 'is_live_trainer_enabled' THEN
        v_flags := jsonb_set(v_flags, '{vision_ai_live_trainer}', p_config -> 'is_live_trainer_enabled');
    END IF;

    UPDATE tenants SET
        config_overrides = v_overrides,
        feature_flags = v_flags,
        updated_at = NOW()
    WHERE id = p_tenant_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'scope', 'tenant',
        'tenant_id', p_tenant_id,
        'config', p_config
    );
END;
$$;
