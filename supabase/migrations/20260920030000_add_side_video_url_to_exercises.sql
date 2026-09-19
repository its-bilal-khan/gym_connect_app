-- ======================================================================================
-- MIGRATION: 20260920030000_add_side_video_url_to_exercises.sql
-- Description: Adds side_video_url column to existing exercises table for multi-angle PIP
-- Safe to run on existing databases (Idempotent: ALTER TABLE ... ADD COLUMN IF NOT EXISTS)
-- ======================================================================================

ALTER TABLE IF EXISTS exercises 
ADD COLUMN IF NOT EXISTS side_video_url TEXT;

COMMENT ON COLUMN exercises.side_video_url IS 'Multi-angle form video (Side / Alternate camera view)';
