-- ==============================================================================
-- Migration: 20261001050000_phase8_owner_workstations_and_moderation.sql
-- Description: Phase 8 Gamification SaaS: Owner Reward Configurator,
--              Automated Fulfillment Ledger, and Flagged Fraud Clawback RPC
-- ==============================================================================

-- 1. Ensure Phase 8 Feature Flags in global_system_settings
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM global_system_settings WHERE key = 'feature_flags') THEN
        UPDATE global_system_settings
        SET value = value || '{
            "owner_reward_configurator": true,
            "fraud_moderation_queue": true
        }'::jsonb,
        updated_at = NOW()
        WHERE key = 'feature_flags';
    END IF;
END $$;

-- 2. Update Tenants Feature Flags with Phase 8 Defaults
UPDATE tenants
SET feature_flags = feature_flags || '{
    "owner_reward_configurator": true,
    "fraud_moderation_queue": true
}'::jsonb
WHERE feature_flags IS NOT NULL;

-- 3. RLS for gamification_flagged_queue
ALTER TABLE IF EXISTS gamification_flagged_queue ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Gym owners and staff can manage flagged queue" ON gamification_flagged_queue;
CREATE POLICY "Gym owners and staff can manage flagged queue"
ON gamification_flagged_queue
FOR ALL
TO authenticated
USING (
    tenant_id IN (
        SELECT tenant_id FROM profiles WHERE id = auth.uid() AND role::text IN ('gym_owner', 'owner', 'staff', 'super_admin')
    )
    OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role::text = 'super_admin'
    )
)
WITH CHECK (
    tenant_id IN (
        SELECT tenant_id FROM profiles WHERE id = auth.uid() AND role::text IN ('gym_owner', 'owner', 'staff', 'super_admin')
    )
    OR EXISTS (
        SELECT 1 FROM profiles WHERE id = auth.uid() AND role::text = 'super_admin'
    )
);

-- 4. RPC: Moderate Flagged Fraud Item & Clawback Points
CREATE OR REPLACE FUNCTION rpc_moderate_flagged_item(
    p_queue_id UUID,
    p_status VARCHAR(20), -- 'approved' or 'deducted'
    p_reviewer_id UUID,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_item RECORD;
    v_new_monthly INT;
    v_new_total INT;
BEGIN
    SELECT * INTO v_item
    FROM gamification_flagged_queue
    WHERE id = p_queue_id;

    IF v_item IS NULL THEN
        RETURN jsonb_build_object('success', FALSE, 'error', 'Queue item not found');
    END IF;

    -- If clawback requested, deduct awarded points from member_gamification
    IF p_status = 'deducted' AND v_item.points_awarded > 0 THEN
        UPDATE member_gamification SET
            monthly_points = GREATEST(0, monthly_points - v_item.points_awarded),
            total_points = GREATEST(0, total_points - v_item.points_awarded),
            total_penalties_count = total_penalties_count + 1,
            last_penalty_date = CURRENT_DATE,
            updated_at = NOW()
        WHERE user_id = v_item.user_id
        RETURNING monthly_points, total_points INTO v_new_monthly, v_new_total;
    END IF;

    -- Update queue item status
    UPDATE gamification_flagged_queue SET
        status = p_status,
        flagged_reason = COALESCE(p_notes, flagged_reason),
        reviewed_by = p_reviewer_id,
        reviewed_at = NOW()
    WHERE id = p_queue_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'queue_id', p_queue_id,
        'status', p_status,
        'points_clawed_back', CASE WHEN p_status = 'deducted' THEN v_item.points_awarded ELSE 0 END,
        'reviewed_at', NOW()
    );
END;
$$;

-- 5. RPC: Update Tenant Reward & Multiplier Config
CREATE OR REPLACE FUNCTION rpc_update_tenant_reward_config(
    p_tenant_id UUID,
    p_rewards JSONB,
    p_min_workouts INT,
    p_multipliers JSONB
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE tenants SET
        leaderboard_rewards = p_rewards,
        min_monthly_workouts_qualification = p_min_workouts,
        veteran_multiplier_config = p_multipliers,
        updated_at = NOW()
    WHERE id = p_tenant_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'tenant_id', p_tenant_id,
        'updated_at', NOW()
    );
END;
$$;
