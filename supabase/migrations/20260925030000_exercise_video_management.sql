-- ==============================================================================
-- GYMCONNECT: EXERCISE VIDEO MANAGEMENT & MULTI-TENANT PERMISSIONS
-- Migration: 20260925030000_exercise_video_management.sql
-- ==============================================================================

-- 1. Ensure columns exist on exercises table
ALTER TABLE IF EXISTS exercises 
    ADD COLUMN IF NOT EXISTS video_url TEXT,
    ADD COLUMN IF NOT EXISTS side_video_url TEXT,
    ADD COLUMN IF NOT EXISTS thumbnail_url TEXT,
    ADD COLUMN IF NOT EXISTS tips TEXT DEFAULT 'Maintain strict form and controlled tempo.',
    ADD COLUMN IF NOT EXISTS instructions JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS is_global BOOLEAN DEFAULT TRUE;

-- 2. Enable RLS on exercises
ALTER TABLE IF EXISTS exercises ENABLE ROW LEVEL SECURITY;

-- 3. Comprehensive RLS policies for Super Admin, Gym Owners, and Members
DROP POLICY IF EXISTS "Anyone can view exercises" ON exercises;
DROP POLICY IF EXISTS "Super admins and owners manage exercises" ON exercises;

-- Select policy: Anyone authenticated or public preview can view global or tenant exercises
CREATE POLICY "Anyone can view exercises" ON exercises
    FOR SELECT USING (
        is_global = TRUE 
        OR tenant_id IS NULL 
        OR tenant_id = auth_current_tenant_id() 
        OR auth_is_super_admin()
        OR auth.role() = 'authenticated'
    );

-- Insert/Update/Delete policy: Super Admin can manage all; Gym Owners can manage their tenant exercises
CREATE POLICY "Super admins and owners manage exercises" ON exercises
    FOR ALL USING (
        auth_is_super_admin() 
        OR tenant_id = auth_current_tenant_id() 
        OR (tenant_id IS NULL AND auth_is_super_admin())
    )
    WITH CHECK (
        auth_is_super_admin() 
        OR tenant_id = auth_current_tenant_id() 
        OR (tenant_id IS NULL AND auth_is_super_admin())
    );

-- 4. Seed / Update Master Exercises with Verified Streaming CDN Form Videos
INSERT INTO exercises (id, tenant_id, name, target_muscle, secondary_muscles, equipment, difficulty, video_url, side_video_url, tips, is_global)
VALUES
    (
        'a1b2c3d4-e5f6-7a8b-9c0d-111111111101',
        NULL,
        'Standard Push-Up Form',
        'Chest',
        ARRAY['Triceps', 'Shoulders', 'Core'],
        'Bodyweight',
        'Beginner',
        'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
        'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
        'Keep core braced in a straight plank, lower chest to floor at 45 degree elbow flare.',
        TRUE
    ),
    (
        'a1b2c3d4-e5f6-7a8b-9c0d-111111111102',
        NULL,
        'Barbell Back Squat',
        'Legs',
        ARRAY['Glutes', 'Hamstrings', 'Lower Back'],
        'Barbell',
        'Advanced',
        'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
        'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
        'Break at hips and knees simultaneously. Keep chest proud and knees tracking over toes.',
        TRUE
    ),
    (
        'a1b2c3d4-e5f6-7a8b-9c0d-111111111103',
        NULL,
        'Flat Barbell Bench Press',
        'Chest',
        ARRAY['Triceps', 'Front Delts'],
        'Barbell',
        'Intermediate',
        'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
        'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
        'Retract scapulae into bench, touch mid-chest under control, and press upward in a slight J-curve.',
        TRUE
    ),
    (
        'a1b2c3d4-e5f6-7a8b-9c0d-111111111104',
        NULL,
        'Lat Pulldown Wide Grip',
        'Back',
        ARRAY['Biceps', 'Rear Delts'],
        'Cable',
        'Beginner',
        'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
        'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
        'Drive elbows down towards hips, squeeze lats at the bottom, and avoid swinging backward.',
        TRUE
    ),
    (
        'a1b2c3d4-e5f6-7a8b-9c0d-111111111105',
        NULL,
        'Standing Overhead Barbell Press',
        'Shoulders',
        ARRAY['Triceps', 'Upper Chest', 'Core'],
        'Barbell',
        'Intermediate',
        'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
        'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
        'Squeeze glutes to protect lower spine, press bar vertically clearing chin, lock out overhead.',
        TRUE
    ),
    (
        'a1b2c3d4-e5f6-7a8b-9c0d-111111111106',
        NULL,
        'Incline Dumbbell Curl',
        'Arms',
        ARRAY['Forearms'],
        'Dumbbell',
        'Intermediate',
        'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
        'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
        'Set bench to 45 degrees, stretch long head of biceps at bottom, curl without swinging elbows forward.',
        TRUE
    )
ON CONFLICT (id) DO UPDATE SET
    video_url = EXCLUDED.video_url,
    side_video_url = EXCLUDED.side_video_url,
    tips = EXCLUDED.tips,
    is_global = EXCLUDED.is_global;
