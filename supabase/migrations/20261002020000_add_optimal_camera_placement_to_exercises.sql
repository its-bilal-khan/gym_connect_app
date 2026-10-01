-- ==============================================================================
-- GYMCONNECT ENTERPRISE SAAS: OPTIMAL CAMERA PLACEMENT MIGRATION
-- Migration: 20261002020000_add_optimal_camera_placement_to_exercises.sql
-- Purpose:
--   1. Add optimal_camera_placement column to exercises table
--   2. Seed default values for gym machine phone holders vs free-standing vs floor
-- ==============================================================================

-- 1. Add optimal_camera_placement column to exercises
ALTER TABLE IF EXISTS exercises 
ADD COLUMN IF NOT EXISTS optimal_camera_placement TEXT NOT NULL DEFAULT 'free_standing';

COMMENT ON COLUMN exercises.optimal_camera_placement IS 'Recommended camera mount orientation: machine_holder, floor_level, or free_standing';

-- 2. Update machine/cable exercises to recommend machine_holder
UPDATE exercises
SET optimal_camera_placement = 'machine_holder'
WHERE equipment ILIKE '%machine%' 
   OR equipment ILIKE '%cable%' 
   OR equipment ILIKE '%leg press%'
   OR equipment ILIKE '%smith%'
   OR name ILIKE '%leg extension%'
   OR name ILIKE '%lat pulldown%'
   OR name ILIKE '%seated cable%'
   OR name ILIKE '%chest press machine%';

-- 3. Update floor exercises (pushups, planks, crunches) to floor_level
UPDATE exercises
SET optimal_camera_placement = 'floor_level'
WHERE equipment ILIKE '%bodyweight%'
   AND (name ILIKE '%pushup%' OR name ILIKE '%push-up%' OR name ILIKE '%plank%' OR name ILIKE '%floor%');
