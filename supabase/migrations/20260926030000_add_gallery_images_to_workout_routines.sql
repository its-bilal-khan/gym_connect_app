-- ==============================================================================
-- GYMCONNECT: ADD GALLERY IMAGES ARRAY TO WORKOUT ROUTINES
-- Migration: 20260926030000_add_gallery_images_to_workout_routines.sql
-- ==============================================================================

ALTER TABLE IF EXISTS workout_routines
ADD COLUMN IF NOT EXISTS gallery_images TEXT[] DEFAULT '{}';
