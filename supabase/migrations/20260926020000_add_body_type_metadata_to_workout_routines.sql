-- ==============================================================================
-- GYMCONNECT: ADD IMAGE URL AND DISPLAY METADATA TO WORKOUT ROUTINES
-- Migration: 20260926020000_add_body_type_metadata_to_workout_routines.sql
-- ==============================================================================

ALTER TABLE IF EXISTS workout_routines
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS subtitle TEXT,
ADD COLUMN IF NOT EXISTS target_physique TEXT;

-- Update RLS if needed to ensure gym owners and super admins can update these columns
-- (Already covered by "Owners and admins manage workout routines" policy on workout_routines)
