-- ==============================================================================
-- Migration: 20261001040000_phase7_vision_ai_micro_clips_and_explore_feed.sql
-- Description: Phase 7 Gamification SaaS: Vision AI Biomechanics Config,
--              Workout Reels Storage Bucket, Privacy Controls & Explore Feed RPCs
-- ==============================================================================

-- 1. Ensure Phase 7 Feature Flags in global_system_settings
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM global_system_settings WHERE key = 'feature_flags') THEN
        UPDATE global_system_settings
        SET value = value || '{
            "ml_kit_rep_counter": true,
            "micro_clip_recorder": true,
            "explore_reels_feed": true
        }'::jsonb,
        updated_at = NOW()
        WHERE key = 'feature_flags';
    END IF;
END $$;

-- 2. Seed Phase 7 Global Vision AI & Biomechanics Configuration
INSERT INTO global_system_settings (key, value, allow_tenant_override, description)
VALUES (
    'phase7_vision_ai_config',
    '{
        "rep_counter": {
            "squat": {"down_angle": 90, "up_angle": 165, "primary_joints": ["hip", "knee", "ankle"]},
            "pushup": {"down_angle": 85, "up_angle": 160, "primary_joints": ["shoulder", "elbow", "wrist"]},
            "bicep_curl": {"up_angle": 45, "down_angle": 150, "primary_joints": ["shoulder", "elbow", "wrist"]},
            "pullup": {"up_angle": 65, "down_angle": 155, "primary_joints": ["shoulder", "elbow", "wrist"]}
        },
        "micro_clip": {
            "set1_capture_duration_seconds": 8,
            "max_reel_duration_seconds": 90,
            "auto_stitch_enabled": true,
            "watermark_gym_logo": true
        },
        "explore_feed": {
            "default_public_privacy": true,
            "moderation_auto_flag": false
        }
    }'::jsonb,
    TRUE,
    'Super Admin settings for Google ML Kit joint angle biomechanics thresholds, micro-clip capture, and Explore Feed.'
)
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    allow_tenant_override = EXCLUDED.allow_tenant_override,
    description = EXCLUDED.description,
    updated_at = NOW();

-- 3. Update Tenants Feature Flags with Phase 7 Defaults
UPDATE tenants
SET feature_flags = feature_flags || '{
    "ml_kit_rep_counter": true,
    "micro_clip_recorder": true,
    "explore_reels_feed": true
}'::jsonb
WHERE feature_flags IS NOT NULL;

-- 4. Create Storage Bucket for Workout Reels
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'workout_reels',
    'workout_reels',
    TRUE,
    52428800, -- 50 MB limit for micro clips / reels
    ARRAY['video/mp4', 'video/webm', 'video/quicktime']
)
ON CONFLICT (id) DO NOTHING;

-- RLS for workout_reels storage bucket
DROP POLICY IF EXISTS "Public can view workout reels" ON storage.objects;
CREATE POLICY "Public can view workout reels"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'workout_reels');

DROP POLICY IF EXISTS "Authenticated members can upload workout reels" ON storage.objects;
CREATE POLICY "Authenticated members can upload workout reels"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'workout_reels');

-- 5. RPC: Publish Workout Reel to Explore Feed
CREATE OR REPLACE FUNCTION rpc_publish_workout_reel(
    p_tenant_id UUID,
    p_user_id UUID,
    p_video_url TEXT,
    p_thumbnail_url TEXT,
    p_duration_seconds INT,
    p_routine_title VARCHAR(150),
    p_streak_days INT,
    p_is_public BOOLEAN DEFAULT TRUE
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_reel_id UUID;
BEGIN
    INSERT INTO member_workout_reels (
        tenant_id, user_id, video_url, thumbnail_url,
        duration_seconds, routine_title, streak_days_at_record,
        is_public_explore, is_flagged, likes_count, created_at
    ) VALUES (
        p_tenant_id, p_user_id, p_video_url, p_thumbnail_url,
        p_duration_seconds, p_routine_title, p_streak_days,
        p_is_public, FALSE, 0, NOW()
    ) RETURNING id INTO v_reel_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'reel_id', v_reel_id,
        'is_public_explore', p_is_public,
        'published_at', NOW()
    );
END;
$$;

-- 6. RPC: Toggle Reel Like
CREATE OR REPLACE FUNCTION rpc_toggle_reel_like(
    p_reel_id UUID,
    p_increment BOOLEAN DEFAULT TRUE
)
RETURNS INT
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_new_likes INT;
BEGIN
    IF p_increment THEN
        UPDATE member_workout_reels
        SET likes_count = likes_count + 1
        WHERE id = p_reel_id
        RETURNING likes_count INTO v_new_likes;
    ELSE
        UPDATE member_workout_reels
        SET likes_count = GREATEST(0, likes_count - 1)
        WHERE id = p_reel_id
        RETURNING likes_count INTO v_new_likes;
    END IF;

    RETURN COALESCE(v_new_likes, 0);
END;
$$;
