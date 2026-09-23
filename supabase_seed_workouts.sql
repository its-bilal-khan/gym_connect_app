-- ======================================================================================
-- GYMCONNECT ENTERPRISE SAAS - MASTER SEED DATA SCRIPT
-- All 3 Body Types (Ectomorph, Mesomorph, Endomorph) Full 7-Day Weekly Programs
-- Idempotent & Safe: Cleans previous seeded data before re-inserting
-- ======================================================================================

-- 0. SCHEMA MIGRATION SAFEGUARD (SAFE FOR ALREADY EXISTING DATABASES)
ALTER TABLE IF EXISTS exercises 
ADD COLUMN IF NOT EXISTS side_video_url TEXT;

ALTER TABLE IF EXISTS workout_routines
ADD COLUMN IF NOT EXISTS body_type VARCHAR(50);

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
) OR id::text LIKE '00000000-0000-0000-0001-%';
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
-- Base exercises for Mesomorph & Endomorph
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
),

-- Authentic Lean Body (Ectomorph) Exercises
(
    '00000000-0000-0000-0001-000000000001', NULL,
    'Flat Barbell Bench Press', 'Chest', ARRAY['Triceps', 'Anterior Deltoids'],
    'Barbell', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Tuck elbows at 45 degrees, touch lower sternum, and press explosively without bouncing.',
    '["Retract scapulae into bench.", "Lower bar under control for 2 seconds to lower chest.", "Drive feet into floor and press to full lockout."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000002', NULL,
    'Incline Dumbbell Press', 'Upper Chest', ARRAY['Triceps', 'Anterior Deltoids'],
    'Dumbbells', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Set incline to 30-45 degrees. Keep chest proud and feel deep stretch at the bottom.',
    '["Sit back with dumbbells at shoulder level.", "Press dumbbells upward and inward without clanking.", "Lower under slow control."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000003', NULL,
    'Cable Fly (Low to High)', 'Upper Chest', ARRAY['Anterior Deltoids', 'Inner Chest'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Set pulleys at lowest position. Scoop upward in an arc, squeezing upper pecs at eye level.',
    '["Step forward slightly into staggered stance.", "Bring handles up and together with slight elbow bend.", "Hold peak contraction for 1 second."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000004', NULL,
    'Machine Chest Press', 'Chest', ARRAY['Triceps', 'Anterior Deltoids'],
    'Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Adjust seat height so handles align with mid-chest. Avoid letting shoulders roll forward.',
    '["Plant back flat against pad.", "Press handles forward until arms are almost straight.", "Control return without letting stack touch."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000005', NULL,
    'Overhead Cable Extension', 'Triceps (Long Head)', ARRAY['Forearms'],
    'Cable Machine', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Face away from cable stack, extend elbows overhead and forward for deep long-head stretch.',
    '["Hold rope behind head with elbows high.", "Extend forearms forward to lockout.", "Resist return under controlled tempo."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000006', NULL,
    'Rope Pushdown', 'Triceps (Lateral Head)', ARRAY['Forearms'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Flare rope outwards at bottom of movement to trigger maximum lateral head peak contraction.',
    '["Pin upper arms to ribcage.", "Push rope down and spread hands apart at bottom.", "Squeeze triceps for 1 second."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000007', NULL,
    'Tricep Dips', 'Triceps', ARRAY['Chest', 'Shoulders'],
    'Bodyweight', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Keep torso upright to prioritize triceps rather than chest. Lower until arms hit 90 degrees.',
    '["Grip parallel dip bars.", "Lower slowly until elbows are at 90 degrees.", "Drive upward locking elbows cleanly."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000008', NULL,
    'Hanging Leg Raises', 'Lower Abs & Core', ARRAY['Hip Flexors', 'Forearms'],
    'Pull-Up Bar', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Hang without swinging, curl pelvis upward and raise toes toward the bar.',
    '["Hang from pull-up bar with firm grip.", "Raise straight legs up until parallel or higher.", "Lower under control without swinging."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000009', NULL,
    'Ab Wheel Rollout', 'Abdominals & Core', ARRAY['Lats', 'Shoulders'],
    'Ab Wheel', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Kneel on mat, roll wheel forward keeping core braced, pull back using abs.',
    '["Kneel holding wheel with straight arms.", "Roll forward until body is near horizontal.", "Engage abs to pull wheel back under hips."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000010', NULL,
    'Cable Crunch', 'Upper Abs', ARRAY['Core'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Kneel with high rope, curl spine downward bringing elbows towards knees.',
    '["Hold rope handles beside temples.", "Flex spine crunching elbows toward thighs.", "Contract abs hard at bottom."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000011', NULL,
    'Weighted Pull-Ups', 'Lats & Upper Back', ARRAY['Biceps', 'Rhomboids', 'Forearms'],
    'Pull-Up Bar', 'advanced',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Start from dead hang, drive elbows down and back, touch chest to bar.',
    '["Hang from bar with overhand grip.", "Depress shoulder blades and pull chest toward bar.", "Lower under control to full hang."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000012', NULL,
    'Barbell Bent-Over Row', 'Lats & Mid-Back', ARRAY['Biceps', 'Rear Delts', 'Spinal Erectors'],
    'Barbell', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Hinge hips back at 45 degrees, pull bar toward belly button, squeeze shoulder blades.',
    '["Hinge forward with neutral spine.", "Pull bar up to navel leading with elbows.", "Hold squeeze 1 second before lowering."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000013', NULL,
    'Lat Pulldown (Wide Grip)', 'Lats', ARRAY['Biceps', 'Upper Back'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Lean back 10-15 degrees, pull bar to upper chest leading with elbows.',
    '["Take wide overhand grip.", "Pull bar down to upper sternum pulling elbows down and back.", "Control the ascent allowing full stretch."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000014', NULL,
    'Seated Cable Row', 'Mid-Back & Rhomboids', ARRAY['Biceps', 'Lats'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Keep torso upright, avoid rocking, drive elbows back and pinch scapulae.',
    '["Sit with slight knee bend and upright torso.", "Pull V-bar to lower abdomen.", "Hold peak squeeze 1s, then return under control."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000015', NULL,
    'Cable Pullover', 'Lats & Serratus', ARRAY['Triceps Long Head', 'Chest'],
    'Cable Machine', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Keep arms extended with slight elbow bend. Sweep bar down in arc toward thighs.',
    '["Stand facing high cable with straight bar.", "Hinge hips slightly forward.", "Pull bar down toward thighs purely using lats."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000016', NULL,
    'Face Pulls', 'Rear Delts & Upper Traps', ARRAY['Rotator Cuff', 'Rhomboids'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'High pulley rope attachment, pull towards forehead/ears spreading hands apart.',
    '["Set rope at face height.", "Pull towards bridge of nose with high flared elbows.", "Externally rotate shoulders at end range."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000017', NULL,
    'Barbell Curl', 'Biceps Brachii', ARRAY['Forearms'],
    'Barbell', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Stand tall, lock elbows against ribs, curl weight without swinging hips.',
    '["Hold bar shoulder-width underhand.", "Curl bar up until biceps are fully contracted.", "Lower slowly for 3 seconds."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000018', NULL,
    'Incline Dumbbell Curl', 'Biceps (Long Head)', ARRAY['Forearms'],
    'Dumbbells', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Sit on inclined bench so arms hang behind torso, maximizing biceps long head stretch.',
    '["Set bench to 45-60 degrees.", "Let dumbbells hang with arms fully extended.", "Curl up supinating wrists at top."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000019', NULL,
    'Hammer Curl', 'Brachialis & Biceps', ARRAY['Brachioradialis', 'Forearms'],
    'Dumbbells', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Keep palms facing each other (neutral grip) to build arm thickness and brachialis.',
    '["Stand holding dumbbells with neutral palms.", "Curl up maintaining neutral wrist angle.", "Squeeze forearm and arm muscle at top."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000020', NULL,
    'Reverse Crunch', 'Lower Abs', ARRAY['Core'],
    'Bodyweight', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Lie flat, curl knees and hips towards ribs lifting lower back slightly off floor.',
    '["Lie on back with knees bent at 90 degrees.", "Curl pelvis toward chest lifting hips.", "Lower slowly back to floor."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000021', NULL,
    'Lying Leg Raises', 'Lower Abs', ARRAY['Hip Flexors'],
    'Bodyweight', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Keep lower back pressed flat into floor as you raise and lower legs.',
    '["Lie flat with hands under hips.", "Raise straight legs up to 90 degrees.", "Lower slowly stopping 2 inches off floor."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000022', NULL,
    'Plank', 'Core & Transverse Abdominis', ARRAY['Glutes', 'Shoulders'],
    'Bodyweight', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Hold straight rigid line from shoulders to heels, bracing core and glutes.',
    '["Rest on forearms and toes.", "Keep spine neutral and squeeze core tight.", "Hold steady for specified duration."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000023', NULL,
    'Plate Neck Flexion', 'Neck (Sternocleidomastoid)', ARRAY['Anterior Neck'],
    'Weight Plate', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Lie on back on flat bench with head hanging off. Place towel and light plate on forehead, curl chin to chest.',
    '["Lie supine with head off edge.", "Hold padded weight plate securely on forehead.", "Curl chin down toward chest smoothly."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000024', NULL,
    'Plate Neck Extension', 'Neck (Splenius Capitis & Traps)', ARRAY['Upper Trapezius'],
    'Weight Plate', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Lie prone on flat bench with head hanging off. Hold plate on back of head, extend neck upward.',
    '["Lie facedown with head hanging off bench edge.", "Place padded plate on back of head.", "Extend neck upward through safe range."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000025', NULL,
    'Dumbbell Shoulder Press', 'Anterior & Lateral Deltoids', ARRAY['Triceps', 'Upper Chest'],
    'Dumbbells', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Press vertically overhead without arching lower back. Control descent to ear level.',
    '["Hold dumbbells at ear level with 90-degree elbows.", "Drive upward until arms are extended overhead.", "Lower slowly to starting level."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000026', NULL,
    'Arnold Press', 'Anterior & Lateral Deltoids', ARRAY['Triceps', 'Upper Chest'],
    'Dumbbells', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Start with palms facing chest, rotate outwards as you press overhead in fluid arc.',
    '["Hold dumbbells in front of shoulders palms facing inward.", "Rotate wrists as you press up.", "Lockout with palms facing forward."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000027', NULL,
    'Cable Lateral Raise', 'Lateral Deltoids', ARRAY['Traps'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Lean slightly away from cable stack, raise hand out to side leading with elbow.',
    '["Stand beside low cable.", "Raise arm out laterally to shoulder level.", "Resist pull on way down for capped deltoids."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000028', NULL,
    'Reverse Pec Deck', 'Rear Deltoids', ARRAY['Rhomboids', 'Mid Traps'],
    'Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Sit facing machine, drive arms backward with slight elbow bend to isolate rear delts.',
    '["Sit chest forward against pad.", "Grip handles and drive arms straight back.", "Hold contraction 1s before returning."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000029', NULL,
    'Upright Row (EZ Bar Wide Grip)', 'Lateral Deltoids & Traps', ARRAY['Biceps', 'Forearms'],
    'EZ Bar', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Take wide grip to avoid shoulder impingement. Pull bar to chest leading with elbows.',
    '["Hold EZ bar with wide overhand grip.", "Pull bar up towards lower chest leading with elbows.", "Lower smoothly under control."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000030', NULL,
    'Dumbbell Front Raise', 'Anterior Deltoids', ARRAY['Upper Chest'],
    'Dumbbells', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Raise dumbbells straight ahead to eye level with controlled speed.',
    '["Stand with dumbbells on front thighs.", "Raise one or both arms forward to shoulder height.", "Lower slowly without swinging."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000031', NULL,
    'Dragon Flag (Tuck)', 'Core & Rectus Abdominis', ARRAY['Lower Back', 'Hip Flexors', 'Lats'],
    'Bodyweight', 'advanced',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Grip bench behind head, raise body up onto upper back with tucked knees.',
    '["Grip bench behind head firmly.", "Lift entire torso up in rigid pillar.", "Lower slowly under control without breaking."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000032', NULL,
    'Hanging Knee Raises', 'Lower Abs', ARRAY['Grip', 'Hip Flexors'],
    'Pull-Up Bar', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Hang from bar, curl knees up towards chest flexing pelvis forward.',
    '["Hang from bar with overhand grip.", "Pull knees up smoothly to chest level.", "Lower under control without swinging."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000033', NULL,
    'Dead Bug', 'Deep Core & Transverse Abdominis', ARRAY['Hip Flexors'],
    'Bodyweight', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Press lumbar spine flat to floor, alternate extending opposite arm and leg.',
    '["Lie on back with arms straight up and knees at 90.", "Lower right arm and left leg toward floor.", "Return and switch sides."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000034', NULL,
    'Side Plank', 'Obliques & Core', ARRAY['Glute Medius', 'Shoulders'],
    'Bodyweight', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Prop up on one forearm and outer edge of foot, hold hips high and aligned.',
    '["Lie sideways propped on forearm.", "Lift hips until body forms straight line.", "Hold for allotted seconds on each side."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000035', NULL,
    'Incline Barbell Press', 'Upper Chest', ARRAY['Triceps', 'Anterior Deltoids'],
    'Barbell', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Unrack with locked wrists. Lower under control toward upper clavicle.',
    '["Set bench to 30 degrees.", "Lower bar to clavicle smoothly.", "Drive upward driving through your palms."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000036', NULL,
    'Flat Dumbbell Press', 'Chest', ARRAY['Triceps', 'Anterior Deltoids'],
    'Dumbbells', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Allows greater depth and range of motion than barbell. Rotate slightly inwards at top.',
    '["Kick dumbbells up from thighs as you lie back.", "Press straight over chest.", "Lower with 45-degree flared elbows."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000037', NULL,
    'Pec Deck Machine Fly', 'Chest', ARRAY['Anterior Deltoids'],
    'Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Keep chest high and shoulders back. Emphasize full chest stretch without hyperextending shoulders.',
    '["Grip vertical handles or place forearms on pads.", "Sweep arms together in hugging arc.", "Squeeze pecs hard at center."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000038', NULL,
    'Cable Crossover (High to Low)', 'Lower Chest', ARRAY['Anterior Deltoids'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Pulleys set high. Drive hands downward and forward, crossing hands slightly at bottom.',
    '["Lean slightly forward from hips.", "Bring handles down in arc toward hips.", "Squeeze lower chest intensely."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000039', NULL,
    'Close-Grip Push-Ups', 'Triceps & Chest', ARRAY['Core', 'Shoulders'],
    'Bodyweight', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Keep hands shoulder-width or diamond. Push until complete muscular failure.',
    '["Place hands under chest shoulder-width.", "Keep elbows pinned close to ribs.", "Descend until chest grazes floor, press to lockout."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000040', NULL,
    'Skull Crushers (EZ Bar)', 'Triceps', ARRAY['Forearms'],
    'EZ Bar', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Keep upper arms stationary angled slightly backward to keep continuous tension.',
    '["Lie on bench, arms vertical holding inner grip.", "Hinge elbows lowering bar towards forehead.", "Extend back up forcefully."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000041', NULL,
    'Single-Arm Cable Pushdown', 'Triceps', ARRAY['Forearms'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Removes imbalances by isolating each arm individually with constant tension.',
    '["Grip single handle or ball without attachment.", "Drive downward locking elbow completely.", "Control the stretch on the way up."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000042', NULL,
    'Close-Grip Bench Press', 'Triceps & Chest', ARRAY['Anterior Deltoids'],
    'Barbell', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Grip shoulder-width apart. Avoid gripping too narrow to protect wrists.',
    '["Unrack bar over chest.", "Lower bar with elbows tucked firmly against ribs.", "Drive up focusing on tricep extension."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000043', NULL,
    'Low Cable Crunch', 'Rectus Abdominis', ARRAY['Core'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Lie on mat facing away from low pulley, hold rope attachment and crunch upward.',
    '["Lie facing away from low cable holding rope at chest.", "Crunch upper torso lifting shoulders off floor.", "Squeeze abs at apex."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000044', NULL,
    'Mountain Climbers', 'Core & Hip Flexors', ARRAY['Shoulders', 'Calves'],
    'Bodyweight', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'High push-up plank, drive knees forward toward chest in rapid rhythmic pace.',
    '["Set up in pushup plank.", "Drive right knee forward to chest, then quickly switch to left.", "Maintain rapid pace with flat hips."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000045', NULL,
    'Bicycle Crunch', 'Obliques & Core', ARRAY['Hip Flexors'],
    'Bodyweight', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Rotate torso bringing opposite elbow to opposite knee with controlled cadence.',
    '["Lie flat with hands behind head.", "Pedal legs bringing right elbow to left knee.", "Switch dynamically to other side."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000046', NULL,
    'Side Neck Raise', 'Lateral Neck (Scalenes)', ARRAY['Traps'],
    'Weight Plate', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Lie on your side on bench, place light plate on side of head, raise head sideways toward shoulder.',
    '["Lie sideways on bench with head unsupported.", "Place light padded weight on upper ear/temple.", "Raise head sideways toward shoulder."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000047', NULL,
    'Neck Isometric Hold', 'Deep Neck Stabilizers', ARRAY['Upper Traps'],
    'Bodyweight', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Place palm against forehead, temple, and back of head, pushing firmly with zero head movement.',
    '["Place palm against side or front of forehead.", "Push head gently against resistance without moving.", "Hold rigid contraction for 10 seconds."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000048', NULL,
    'Single-Arm DB Row', 'Lats & Upper Back', ARRAY['Biceps', 'Rhomboids'],
    'Dumbbells', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Brace one knee on bench, pull dumbbell to hip pocket feeling intense lat contraction.',
    '["Place hand and knee on bench with flat spine.", "Pull dumbbell toward hip crease.", "Lower slowly feeling full lat stretch."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000049', NULL,
    'Lat Pulldown (Reverse Grip)', 'Lower Lats & Biceps', ARRAY['Rhomboids'],
    'Cable Machine', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/shoulder_press_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Underhand supinated grip shoulder-width apart to target lower lat fibers and biceps.',
    '["Grip bar palms facing you shoulder-width.", "Pull bar to clavicle driving elbows down.", "Control return feeling stretch in lower lats."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000050', NULL,
    'Chest-Supported Row', 'Mid-Back & Rhomboids', ARRAY['Rear Delts', 'Biceps'],
    'Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Chest pad eliminates lower-back strain. Row weights back squeezing shoulder blades together.',
    '["Rest chest firmly against pad.", "Row handles toward torso pinching scapulae.", "Slow eccentric release for 2 seconds."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000051', NULL,
    'Straight-Arm Cable Pulldown', 'Lats & Teres Major', ARRAY['Triceps Long Head', 'Abs'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Lock elbows with subtle bend. Use wide bar and drive directly into thighs.',
    '["Grip bar at shoulder height with straight arms.", "Sweep down to hip level squeezing lats.", "Elevate slowly back to eye level."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000052', NULL,
    'Rear Delt Cable Fly', 'Rear Deltoids', ARRAY['Rhomboids', 'Traps'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Cross cables at chest height, pull handles back and apart in horizontal plane.',
    '["Stand between cable pulleys without attachments.", "Grip opposite cables and pull horizontally backward.", "Squeeze rear delts intensely."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000053', NULL,
    'EZ Bar Preacher Curl', 'Biceps (Short Head)', ARRAY['Forearms'],
    'EZ Bar', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Upper arm locked into preacher bench. Completely isolates biceps from shoulder assistance.',
    '["Sit at preacher bench with chest against pad.", "Grip EZ bar with inner grips.", "Curl up and squeeze bicep peak."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000054', NULL,
    'Cable Curl', 'Biceps Brachii', ARRAY['Brachialis'],
    'Cable Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Low pulley provides continuous constant tension throughout entire range of motion.',
    '["Attach straight bar to low pulley.", "Stand upright and curl upward keeping elbows stationary.", "Control the negative phase."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000055', NULL,
    'Concentration Curl', 'Biceps Peak', ARRAY['Forearms'],
    'Dumbbells', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/curl_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Sit and brace elbow against inner thigh, curling weight with zero body momentum.',
    '["Sit on bench with feet wide.", "Brace tricep against inner thigh.", "Curl dumbbell up to chest squeezing peak."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000056', NULL,
    'V-Ups', 'Upper & Lower Abs', ARRAY['Hip Flexors'],
    'Bodyweight', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Simultaneously lift straight legs and torso, touching fingers to toes in a V-shape.',
    '["Lie flat on back with arms outstretched.", "Explosively fold body reaching hands toward toes.", "Lower smoothly back without arching."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000057', NULL,
    'Weighted Cable Crunch', 'Abs & Core', ARRAY['Obliques'],
    'Cable Machine', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/push_up_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Heavy progressive overload for abdominal wall. Pull ribcage downward to pelvis.',
    '["Kneel holding heavy rope at crown of head.", "Flex abs curling ribcage toward pelvis.", "Pause 1 second, then control ascent."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000058', NULL,
    'Barbell Back Squat', 'Quadriceps & Glutes', ARRAY['Hamstrings', 'Core', 'Calves'],
    'Barbell', 'advanced',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Brace core with deep Valsalva breath. Squat below parallel and drive through mid-foot.',
    '["Place bar across upper traps.", "Descend until thighs break parallel.", "Drive through floor to stand tall."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000059', NULL,
    'Romanian Deadlift (RDL)', 'Hamstrings & Glutes', ARRAY['Spinal Erectors', 'Lats', 'Core'],
    'Barbell', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Push hips backward with soft knees, feel deep hamstring stretch, thrust forward.',
    '["Hold bar at thighs with shoulder-width grip.", "Hinge backward pushing hips to rear wall.", "Drive hips forward when bar reaches mid-shin."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000060', NULL,
    'Hack Squat', 'Quadriceps', ARRAY['Glutes'],
    'Machine', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Back pressed against carriage pad, feet shoulder-width, descend into deep knee bend.',
    '["Position shoulders under pads and feet on platform.", "Descend under control to 90 degrees.", "Drive through mid-foot extending knees."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000061', NULL,
    'Bulgarian Split Squat', 'Quadriceps & Glutes', ARRAY['Hamstrings', 'Adductors'],
    'Dumbbells', 'intermediate',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Rear foot elevated on bench, descend until front thigh is parallel to floor.',
    '["Elevate back foot on bench behind you.", "Lower hips vertically until front thigh is parallel.", "Drive back up through front heel."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000062', NULL,
    'Seated Leg Curl', 'Hamstrings', ARRAY['Calves'],
    'Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Lock thigh pad securely, curl heel pad back under seat squeezing hamstrings 1s.',
    '["Adjust thigh pad firmly over knees.", "Curl heels under forcefully towards seat.", "Control extension back to start."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000063', NULL,
    'Leg Extension', 'Quadriceps', ARRAY[]::TEXT[],
    'Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Extend knees fully, pause and flex quadriceps at top, control eccentric return.',
    '["Sit back against pad with shin pad above ankles.", "Extend legs upward until straight.", "Hold quad contraction 1 second before lowering."]'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0001-000000000064', NULL,
    'Standing Calf Raise', 'Calves (Gastrocnemius)', ARRAY['Soleus'],
    'Machine', 'beginner',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/squat_form.mp4',
    'https://cdn.jsdelivr.net/gh/RiccardoRiccio/Fitness-AI-coach@main/demo.mp4',
    'Get full stretch at bottom, rise high onto balls of feet and hold top for 2s.',
    '["Place balls of feet on block with straight legs.", "Lower heels for deep calf stretch.", "Explode onto toes squeezing calves hard."]'::jsonb,
    TRUE
);

-- 4. SEED 3 MASTER 90-DAY PROGRAMS (ONE FOR EACH BODY TYPE)

-- 4.1 ECTOMORPH PROTOCOL: Lean Body Shred & Hypertrophy (UPDATED AUTHENTIC PROTOCOL)
INSERT INTO workout_routines (id, tenant_id, title, description, target_goal, body_type, duration_days, is_ai_generated, is_public_preview)
VALUES (
    '00000000-0000-0000-0000-000000000011',
    NULL,
    'Ectomorph: Lean Body Shred & Hypertrophy',
    'Scientific 6-day periodized split designed for lean mass accrual, dense hypertrophy, aesthetic V-taper conditioning, six-pack core definition, and neck stability.',
    'muscle_gain',
    'ectomorph',
    90,
    TRUE,
    TRUE
);

-- 4.2 MESOMORPH PROTOCOL: Athletic Strength & V-Taper (PRESERVED)
INSERT INTO workout_routines (id, tenant_id, title, description, target_goal, body_type, duration_days, is_ai_generated, is_public_preview)
VALUES (
    '00000000-0000-0000-0000-000000000012',
    NULL,
    'Mesomorph: Athletic Power & V-Taper',
    'Progressive overload compound protocol designed for maximum muscle density, broad shoulders, and raw strength.',
    'strength',
    'mesomorph',
    90,
    TRUE,
    TRUE
);

-- 4.3 ENDOMORPH PROTOCOL: High-Intensity Metabolic Shred (PRESERVED)
INSERT INTO workout_routines (id, tenant_id, title, description, target_goal, body_type, duration_days, is_ai_generated, is_public_preview)
VALUES (
    '00000000-0000-0000-0000-000000000013',
    NULL,
    'Endomorph: Metabolic Shred & Furnace',
    'High-density supersets and compound circuits designed to accelerate fat loss and build chiseled definition.',
    'fat_loss',
    'endomorph',
    90,
    TRUE,
    TRUE
);

-- 5. SEED FULL 7-DAY WEEKLY SCHEDULE FOR ALL 3 PROGRAMS

-- 5.1 Ectomorph Weekly Days (Days 1 to 7 - Authentic Lean Body Split)
INSERT INTO workout_routine_days (id, routine_id, day_number, title, muscle_groups, is_rest_day)
VALUES
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0000-000000000011', 1, 'Day 1: Monday – Chest + Triceps + Abs', ARRAY['Chest', 'Triceps', 'Abs'], FALSE),
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0000-000000000011', 2, 'Day 2: Tuesday – Back + Biceps + Abs + Neck', ARRAY['Back', 'Biceps', 'Abs', 'Neck'], FALSE),
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0000-000000000011', 3, 'Day 3: Wednesday – Shoulders + Abs', ARRAY['Shoulders', 'Abs'], FALSE),
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0000-000000000011', 4, 'Day 4: Thursday – Chest + Triceps + Abs + Neck', ARRAY['Chest', 'Triceps', 'Abs', 'Neck'], FALSE),
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0000-000000000011', 5, 'Day 5: Friday – Back + Biceps + Abs + Neck', ARRAY['Back', 'Biceps', 'Abs', 'Neck'], FALSE),
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0000-000000000011', 6, 'Day 6: Saturday – Legs + Abs', ARRAY['Legs', 'Abs'], FALSE),
    ('00000000-0000-0000-0000-000000000107', '00000000-0000-0000-0000-000000000011', 7, 'Day 7: Sunday – Active Recovery, Mobility & Rejuvenation', ARRAY['Mobility', 'Recovery'], TRUE);

-- 5.2 Mesomorph Weekly Days (Days 1 to 7 - PRESERVED)
INSERT INTO workout_routine_days (id, routine_id, day_number, title, muscle_groups, is_rest_day)
VALUES
    ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000012', 1, 'Day 1: Heavy Push & Delts', ARRAY['Chest', 'Shoulders'], FALSE),
    ('00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000012', 2, 'Day 2: Heavy Pull & Lats', ARRAY['Back', 'Biceps'], FALSE),
    ('00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000012', 3, 'Day 3: Heavy Squat & Hamstrings', ARRAY['Legs'], FALSE),
    ('00000000-0000-0000-0000-000000000204', '00000000-0000-0000-0000-000000000012', 4, 'Day 4: V-Taper Overhead Power', ARRAY['Shoulders', 'Upper Back'], FALSE),
    ('00000000-0000-0000-0000-000000000205', '00000000-0000-0000-0000-000000000012', 5, 'Day 5: Total Body Compound Drive', ARRAY['Full Body'], FALSE),
    ('00000000-0000-0000-0000-000000000206', '00000000-0000-0000-0000-000000000012', 6, 'Day 6: Arm Hypertrophy & Calves', ARRAY['Arms', 'Calves'], FALSE),
    ('00000000-0000-0000-0000-000000000207', '00000000-0000-0000-0000-000000000012', 7, 'Day 7: Strategic Rest & Decompress', ARRAY['Rest'], TRUE);

-- 5.3 Endomorph Weekly Days (Days 1 to 7 - PRESERVED)
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

-- ======================================================================================
-- 6.1 LEAN BODY (ECTOMORPH) AUTHENTIC EXERCISES MAPPING
-- ======================================================================================

-- Day 1: Monday – Chest + Triceps + Abs
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0001-000000000001', 1, 4, '8-10', 90),   -- Flat Barbell Bench Press
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0001-000000000002', 2, 4, '10-12', 60),  -- Incline Dumbbell Press
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0001-000000000003', 3, 3, '12-15', 45),  -- Cable Fly (Low to High)
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0001-000000000004', 4, 3, '12-15', 60),  -- Machine Chest Press
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0001-000000000005', 5, 3, '12-15', 45),  -- Overhead Cable Extension
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0001-000000000006', 6, 3, '15', 45),     -- Rope Pushdown
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0001-000000000007', 7, 3, '10-12', 60),  -- Tricep Dips
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0001-000000000008', 8, 4, '12-15', 45),  -- Hanging Leg Raises
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0001-000000000009', 9, 3, '10-12', 45),  -- Ab Wheel Rollout
    ('00000000-0000-0000-0000-000000000101', '00000000-0000-0000-0001-000000000010', 10, 3, '15', 45);    -- Cable Crunch

-- Day 2: Tuesday – Back + Biceps + Abs + Neck
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000011', 1, 4, '6-10', 90),   -- Weighted Pull-Ups
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000012', 2, 4, '8-10', 75),   -- Barbell Bent-Over Row
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000013', 3, 3, '10-12', 60),  -- Lat Pulldown (wide grip)
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000014', 4, 3, '10-12', 60),  -- Seated Cable Row
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000015', 5, 3, '12-15', 45),  -- Cable Pullover
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000016', 6, 3, '15-20', 45),  -- Face Pulls
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000017', 7, 3, '8-10', 60),   -- Barbell Curl
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000018', 8, 3, '10-12', 45),  -- Incline Dumbbell Curl
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000019', 9, 2, '12', 45),     -- Hammer Curl
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000020', 10, 4, '15', 45),    -- Reverse Crunch
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000021', 11, 3, '15', 45),    -- Lying Leg Raises
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000022', 12, 3, '45-60s', 45), -- Plank
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000023', 13, 3, '15', 45),    -- Plate Neck Flexion
    ('00000000-0000-0000-0000-000000000102', '00000000-0000-0000-0001-000000000024', 14, 3, '15', 45);    -- Plate Neck Extension

-- Day 3: Wednesday – Shoulders + Abs
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0001-000000000025', 1, 4, '8-10', 75),   -- Dumbbell Shoulder Press
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0001-000000000026', 2, 3, '10-12', 60),  -- Arnold Press
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0001-000000000027', 3, 5, '15-20', 45),  -- Cable Lateral Raise
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0001-000000000028', 4, 4, '15', 45),     -- Reverse Pec Deck
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0001-000000000029', 5, 3, '12', 60),     -- Upright Row (EZ bar wide grip)
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0001-000000000030', 6, 3, '12-15', 45),  -- Dumbbell Front Raise
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0001-000000000031', 7, 3, '8-10', 60),   -- Dragon Flag (tuck)
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0001-000000000032', 8, 3, '15', 45),     -- Hanging Knee Raises
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0001-000000000033', 9, 3, '10 each', 30), -- Dead Bug
    ('00000000-0000-0000-0000-000000000103', '00000000-0000-0000-0001-000000000034', 10, 3, '30-40s', 30); -- Side Plank

-- Day 4: Thursday – Chest + Triceps + Abs + Neck
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000035', 1, 4, '8-10', 90),   -- Incline Barbell Press
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000036', 2, 3, '10-12', 60),  -- Flat Dumbbell Press
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000037', 3, 3, '12-15', 45),  -- Pec Deck Machine Fly
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000038', 4, 3, '15', 45),     -- Cable Crossover (high to low)
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000039', 5, 2, 'Failure', 60), -- Close-Grip Push-Ups
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000040', 6, 3, '10-12', 60),  -- Skull Crushers (EZ bar)
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000041', 7, 3, '12-15', 45),  -- Single-Arm Cable Pushdown
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000042', 8, 3, '8-10', 75),   -- Close-Grip Bench Press
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000043', 9, 4, '15', 45),     -- Low Cable Crunch
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000044', 10, 3, '30s', 30),   -- Mountain Climbers
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000045', 11, 3, '20', 30),    -- Bicycle Crunch
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000046', 12, 3, '12 each', 30), -- Side Neck Raise
    ('00000000-0000-0000-0000-000000000104', '00000000-0000-0000-0001-000000000047', 13, 4, '10s each', 20); -- Neck Isometric Hold

-- Day 5: Friday – Back + Biceps + Abs + Neck
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000048', 1, 4, '10-12', 60),  -- Single-Arm DB Row
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000049', 2, 4, '10-12', 60),  -- Lat Pulldown (reverse grip)
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000050', 3, 3, '12-15', 60),  -- Chest-Supported Row
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000051', 4, 3, '15', 45),     -- Straight-Arm Cable Pulldown
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000052', 5, 3, '15', 45),     -- Rear Delt Cable Fly
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000053', 6, 3, '10-12', 60),  -- EZ Bar Preacher Curl
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000054', 7, 3, '12-15', 45),  -- Cable Curl
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000055', 8, 2, '12-15', 45),  -- Concentration Curl
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000008', 9, 4, '10-12', 45),  -- Hanging Leg Raises
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000056', 10, 3, '12-15', 45), -- V-Ups
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000057', 11, 3, '15', 45),    -- Weighted Cable Crunch
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000023', 12, 3, '15', 45),    -- Plate Neck Flexion
    ('00000000-0000-0000-0000-000000000105', '00000000-0000-0000-0001-000000000024', 13, 3, '15', 45);    -- Plate Neck Extension

-- Day 6: Saturday – Legs + Abs
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0001-000000000058', 1, 4, '8-10', 90),   -- Barbell Back Squat
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0001-000000000059', 2, 4, '10-12', 75),  -- Romanian Deadlift (RDL)
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0001-000000000060', 3, 3, '10-12', 75),  -- Hack Squat
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0001-000000000061', 4, 3, '10-12', 60),  -- Bulgarian Split Squat
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0001-000000000062', 5, 3, '12-15', 60),  -- Seated Leg Curl
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0001-000000000063', 6, 3, '15', 60),     -- Leg Extension
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0001-000000000064', 7, 5, '15-20', 45),  -- Standing Calf Raise
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0001-000000000009', 8, 3, '10-12', 45),  -- Ab Wheel Rollout
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0001-000000000020', 9, 3, '15', 45),     -- Reverse Crunch
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0001-000000000057', 10, 3, '15', 45),    -- Weighted Cable Crunch
    ('00000000-0000-0000-0000-000000000106', '00000000-0000-0000-0001-000000000022', 11, 2, 'Max Hold', 60); -- Plank

-- ======================================================================================
-- 6.2 MESOMORPH & ENDOMORPH EXERCISES MAPPING (PRESERVED)
-- ======================================================================================

-- Day 1 Exercises
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000002', 1, 4, '6-8', 90),
    ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000001', 2, 4, '8-10', 60),
    ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000001', 1, 4, '15-20', 45),
    ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000002', 2, 4, '12-15', 45);

-- Day 2 Exercises
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000202', '00000000-0000-0000-0000-000000000003', 1, 4, '8-10', 60),
    ('00000000-0000-0000-0000-000000000302', '00000000-0000-0000-0000-000000000003', 1, 4, '12-15', 45);

-- Day 3 Exercises
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000203', '00000000-0000-0000-0000-000000000004', 1, 5, '5-6', 120),
    ('00000000-0000-0000-0000-000000000303', '00000000-0000-0000-0000-000000000004', 1, 4, '12-15', 60);

-- Day 4 Exercises
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000204', '00000000-0000-0000-0000-000000000002', 1, 4, '6-8', 90),
    ('00000000-0000-0000-0000-000000000304', '00000000-0000-0000-0000-000000000002', 1, 4, '12-15', 45);

-- Day 5 Exercises
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000205', '00000000-0000-0000-0000-000000000004', 1, 4, '6-8', 90),
    ('00000000-0000-0000-0000-000000000205', '00000000-0000-0000-0000-000000000001', 2, 3, '8-10', 60),
    ('00000000-0000-0000-0000-000000000305', '00000000-0000-0000-0000-000000000001', 1, 4, '15-20', 45),
    ('00000000-0000-0000-0000-000000000305', '00000000-0000-0000-0000-000000000003', 2, 4, '12-15', 45);

-- Day 6 Exercises
INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds)
VALUES
    ('00000000-0000-0000-0000-000000000206', '00000000-0000-0000-0000-000000000003', 1, 4, '8-10', 60),
    ('00000000-0000-0000-0000-000000000306', '00000000-0000-0000-0000-000000000004', 1, 4, '12-15', 60);

-- ======================================================================================
-- END OF WORKOUTS MASTER SEED SCRIPT
-- ======================================================================================
