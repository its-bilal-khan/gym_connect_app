-- ======================================================================================
-- GYMCONNECT ENTERPRISE SAAS - MASTER SEED DATA SCRIPT
-- All 3 Body Types (Ectomorph, Mesomorph, Endomorph) Full 7-Day Weekly Programs
-- Idempotent & Safe: Cleans previous seeded data before re-inserting
-- ======================================================================================

-- 0. SCHEMA MIGRATION SAFEGUARD (SAFE FOR ALREADY EXISTING DATABASES)
ALTER TABLE IF EXISTS exercises 
ADD COLUMN IF NOT EXISTS side_video_url TEXT;

-- 1. CLEANUP PREVIOUS SEED DATA (SAFE WIPE FOR SEED IDENTIFIERS ONLY)
DELETE FROM workout_day_exercises WHERE day_id IN (
    SELECT id FROM workout_routine_days WHERE routine_id IN (
        '00000000-0000-0000-0000-000000000011',
        '00000000-0000-0000-0000-000000000012',
        '00000000-0000-0000-0000-000000000013'
    )
);
DELETE FROM workout_routine_days WHERE routine_id IN (
    '00000000-0000-0000-0000-000000000011',
    '00000000-0000-0000-0000-000000000012',
    '00000000-0000-0000-0000-000000000013'
);
DELETE FROM workout_routines WHERE id IN (
    '00000000-0000-0000-0000-000000000011',
    '00000000-0000-0000-0000-000000000012',
    '00000000-0000-0000-0000-000000000013'
);
DELETE FROM exercises WHERE id IN (
    '00000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000003',
    '00000000-0000-0000-0000-000000000004'
);
DELETE FROM badges WHERE code IN ('first_workout', 'streak_3', 'streak_7', 'steps_10k', 'century_lifter');

-- 2. SEED DEFAULT BADGES
INSERT INTO badges (code, title, description, points_reward)
VALUES 
    ('first_workout', 'First Blood', 'Completed your first gym workout with GymConnect', 100),
    ('streak_3', 'Consistency Kickstart', 'Maintained a 3-day workout streak', 150),
    ('streak_7', 'Unstoppable Beast', 'Completed a 7-day workout streak without missing a day', 350),
    ('steps_10k', '10K Road Warrior', 'Hit 10,000 steps in a single day', 100),
    ('century_lifter', 'Century Lifter', 'Logged 100 total sets across all workout sessions', 500)
ON CONFLICT (code) DO UPDATE 
SET title = EXCLUDED.title, description = EXCLUDED.description, points_reward = EXCLUDED.points_reward;

-- 3. SEED GLOBAL EXERCISES (VERIFIED STREAMING CDNs & DUAL CAMERA ANGLES)
INSERT INTO exercises (id, tenant_id, name, target_muscle, secondary_muscles, equipment, difficulty, video_url, side_video_url, tips, instructions, is_global)
VALUES
(
    '00000000-0000-0000-0000-000000000001',
    NULL,
    'Full Range Push-Up Form',
    'Chest & Core',
    ARRAY['Triceps', 'Shoulders'],
    'Bodyweight',
    'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Keep elbows tucked at 45 degrees. Lower chest to floor and lock out at top.',
    '["Place hands slightly wider than shoulders.", "Lower under control for 2 seconds.", "Push up explosively while bracing core."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000002',
    NULL,
    'Dumbbell Overhead Shoulder Press',
    'Anterior & Lateral Deltoids',
    ARRAY['Triceps', 'Upper Chest'],
    'Dumbbells',
    'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Press directly overhead without arching lower back. Control the descent.',
    '["Hold dumbbells at ear level with 90-degree elbows.", "Drive upward until arms are straight.", "Lower slowly to start position."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000003',
    NULL,
    'Standing Biceps Dumbbell Curl',
    'Biceps Brachii',
    ARRAY['Forearms'],
    'Dumbbells',
    'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Keep elbows pinned to your sides. Supinate wrists at the top for maximum peak contraction.',
    '["Stand with feet shoulder-width apart.", "Curl dumbbells upward while keeping torso still.", "Squeeze biceps hard for 1 second at top."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000004',
    NULL,
    'Barbell Back Squat',
    'Quadriceps & Glutes',
    ARRAY['Hamstrings', 'Core'],
    'Barbell',
    'advanced',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Break at hips and knees simultaneously. Keep chest proud and squat below parallel.',
    '["Position bar across upper traps.", "Descend until hips are below knee crease.", "Drive through heels to stand back up."]'::jsonb,
    TRUE
);

-- 4. SEED 3 MASTER 90-DAY PROGRAMS (ONE FOR EACH BODY TYPE)

-- 4.1 ECTOMORPH PROTOCOL: Mass Hypertrophy & Caloric Surplus
INSERT INTO workout_routines (id, tenant_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview)
VALUES (
    '00000000-0000-0000-0000-000000000011',
    NULL,
    'Ectomorph: Lean Mass Hypertrophy',
    'High-volume Push/Pull/Legs periodization designed to build dense muscle on fast-metabolism frames.',
    'muscle_gain',
    90,
    TRUE,
    TRUE
);

-- 4.2 MESOMORPH PROTOCOL: Athletic Strength & V-Taper
INSERT INTO workout_routines (id, tenant_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview)
VALUES (
    '00000000-0000-0000-0000-000000000012',
    NULL,
    'Mesomorph: Athletic Power & V-Taper',
    'Progressive overload compound protocol designed for maximum muscle density, broad shoulders, and raw strength.',
    'strength',
    90,
    TRUE,
    TRUE
);

-- 4.3 ENDOMORPH PROTOCOL: High-Intensity Metabolic Shred
INSERT INTO workout_routines (id, tenant_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview)
VALUES (
    '00000000-0000-0000-0000-000000000013',
    NULL,
    'Endomorph: Metabolic Shred & Furnace',
    'High-density supersets and compound circuits designed to accelerate fat loss and build chiseled definition.',
    'fat_loss',
    90,
    TRUE,
    TRUE
);

-- 5. SEED FULL 7-DAY WEEKLY SCHEDULE FOR ALL 3 PROGRAMS

-- 5.1 Ectomorph Weekly Days (Days 1 to 7)
INSERT INTO workout_routine_days (id, routine_id, day_number, title, muscle_groups, is_rest_day)
VALUES
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000011', 1, 'Day 1: Chest & Triceps Blitz', ARRAY['Chest', 'Triceps'], FALSE),
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000011', 2, 'Day 2: Back & Biceps Power', ARRAY['Back', 'Biceps'], FALSE),
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000011', 3, 'Day 3: Quads & Glute Drive', ARRAY['Legs', 'Calves'], FALSE),
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000011', 4, 'Day 4: Shoulders & Core Surge', ARRAY['Shoulders', 'Core'], FALSE),
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0000-000000000011', 5, 'Day 5: Upper Body Pump', ARRAY['Chest', 'Arms'], FALSE),
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0000-000000000011', 6, 'Day 6: Lower Body Power', ARRAY['Legs', 'Abs'], FALSE),
    ('00000000-0000-0000-0000-000000000107', '00000000-0000-0000-0000-000000000011', 7, 'Day 7: Active Recovery & Mobility', ARRAY['Mobility'], TRUE);

-- 5.2 Mesomorph Weekly Days (Days 1 to 7)
INSERT INTO workout_routine_days (id, routine_id, day_number, title, muscle_groups, is_rest_day)
VALUES
    ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000012', 1, 'Day 1: Heavy Push & Delts', ARRAY['Chest', 'Shoulders'], FALSE),
    ('00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000012', 2, 'Day 2: Heavy Pull & Lats', ARRAY['Back', 'Biceps'], FALSE),
    ('00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000012', 3, 'Day 3: Heavy Squat & Hamstrings', ARRAY['Legs'], FALSE),
    ('00000000-0000-0000-0000-000000000204', '00000000-0000-0000-0000-000000000012', 4, 'Day 4: V-Taper Overhead Power', ARRAY['Shoulders', 'Upper Back'], FALSE),
    ('00000000-0000-0000-0000-000000000205', '00000000-0000-0000-0000-000000000012', 5, 'Day 5: Total Body Compound Drive', ARRAY['Full Body'], FALSE),
    ('00000000-0000-0000-0000-000000000206', '00000000-0000-0000-0000-000000000012', 6, 'Day 6: Arm Hypertrophy & Calves', ARRAY['Arms', 'Calves'], FALSE),
    ('00000000-0000-0000-0000-000000000207', '00000000-0000-0000-0000-000000000012', 7, 'Day 7: Strategic Rest & Decompress', ARRAY['Rest'], TRUE);

-- 5.3 Endomorph Weekly Days (Days 1 to 7)
INSERT INTO workout_routine_days (id, routine_id, day_number, title, muscle_groups, is_rest_day)
VALUES
    ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000013', 1, 'Day 1: Metabolic Chest & High Reps', ARRAY['Chest', 'Core'], FALSE),
    ('00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000013', 2, 'Day 2: Back Density & Cardio Core', ARRAY['Back', 'Abs'], FALSE),
    ('00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000013', 3, 'Day 3: High-Volume Leg Furnace', ARRAY['Legs'], FALSE),
    ('00000000-0000-0000-0000-000000000304', '00000000-0000-0000-0000-000000000013', 4, 'Day 4: Shoulder Sculpting & Burn', ARRAY['Shoulders'], FALSE),
    ('00000000-0000-0000-0000-000000000305', '00000000-0000-0000-0000-000000000013', 5, 'Day 5: Full Body Metabolic Circuit', ARRAY['Full Body'], FALSE),
    ('00000000-0000-0000-0000-000000000306', '00000000-0000-0000-0000-000000000013', 6, 'Day 6: HIIT Legs & Upper Burn', ARRAY['Legs', 'Arms'], FALSE),
    ('00000000-0000-0000-0000-000000000307', '00000000-0000-0000-0000-000000000013', 7, 'Day 7: Active Cardio Walk & Rest', ARRAY['Cardio'], TRUE);

-- 6. LINK EXERCISES TO ROUTINE DAYS

-- Day 1 Exercises (Push-Up, Shoulder Press)
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000001', 1, 4, '10-12', 60),
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000002', 2, 3, '8-10', 60),
    ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000002', 1, 4, '6-8', 90),
    ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000001', 2, 4, '8-10', 60),
    ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000001', 1, 4, '15-20', 45),
    ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000002', 2, 4, '12-15', 45);

-- Day 2 Exercises (Biceps Curl, Push-Up)
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000003', 1, 4, '10-12', 60),
    ('00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000003', 1, 4, '8-10', 60),
    ('00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000003', 1, 4, '12-15', 45);

-- Day 3 Exercises (Barbell Back Squat)
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000004', 1, 4, '8-10', 90),
    ('00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000004', 1, 5, '5-6', 120),
    ('00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000004', 1, 4, '12-15', 60);

-- Day 4 Exercises (Shoulder Press, Push-Up)
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000002', 1, 4, '8-10', 60),
    ('00000000-0000-0000-0000-000000000204', '00000000-0000-0000-0000-000000000002', 1, 4, '6-8', 90),
    ('00000000-0000-0000-0000-000000000304', '00000000-0000-0000-0000-000000000002', 1, 4, '12-15', 45);

-- Day 5 Exercises (Full Upper Pump: Push-Up, Shoulder Press, Biceps Curl)
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0000-000000000001', 1, 3, '10-12', 60),
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0000-000000000002', 2, 3, '8-10', 60),
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0000-000000000003', 3, 3, '10-12', 60),
    ('00000000-0000-0000-0000-000000000205', '00000000-0000-0000-0000-000000000004', 1, 4, '6-8', 90),
    ('00000000-0000-0000-0000-000000000205', '00000000-0000-0000-0000-000000000001', 2, 3, '8-10', 60),
    ('00000000-0000-0000-0000-000000000305', '00000000-0000-0000-0000-000000000001', 1, 4, '15-20', 45),
    ('00000000-0000-0000-0000-000000000305', '00000000-0000-0000-0000-000000000003', 2, 4, '12-15', 45);

-- Day 6 Exercises (Lower Power: Squats)
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0000-000000000004', 1, 4, '8-10', 75),
    ('00000000-0000-0000-0000-000000000206', '00000000-0000-0000-0000-000000000003', 1, 4, '8-10', 60),
    ('00000000-0000-0000-0000-000000000306', '00000000-0000-0000-0000-000000000004', 1, 4, '12-15', 60);
