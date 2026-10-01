-- ==============================================================================
-- GYMCONNECT ENTERPRISE SAAS: PHASE 2 STATIC MASTER TEMPLATE ENGINE
-- Migration: 20260929000000_ai_workout_engine_backend.sql
-- Purpose: 
--   1. Silent BMI & Track A / Track B Algorithmic Routing
--   2. Static 90-Day Master Template Assignment (Track A & Track B)
--   3. Automatic Medical Injury Swap via swap_group_id (Zero LLM / Zero API Cost)
--   4. Atomic User Routine Personalization & Binding
-- ==============================================================================

-- 1. SCHEMA EXTENSIONS FOR ROUTINES & FITNESS PROFILES
ALTER TABLE IF EXISTS workout_routines
ADD COLUMN IF NOT EXISTS assigned_track VARCHAR(50) DEFAULT 'track_a' CHECK (assigned_track IN ('track_a', 'track_b')),
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES profiles(id) ON DELETE CASCADE;

ALTER TABLE IF EXISTS user_fitness_profiles
ADD COLUMN IF NOT EXISTS current_workout_routine_id UUID REFERENCES workout_routines(id) ON DELETE SET NULL;

-- Ensure user_fitness_profiles.body_type supports unlimited Super Admin custom body types (V-Shape, Heavyweight, etc.)
DO $$ 
BEGIN
    ALTER TABLE user_fitness_profiles ALTER COLUMN body_type TYPE VARCHAR(50) USING body_type::text;
EXCEPTION WHEN OTHERS THEN
    NULL;
END $$;

-- 2. PARTIAL UNIQUE INDEXES REFINEMENT
-- Ensure master tenant/global protocols are uniquely mapped by BOTH (body_type, assigned_track)
-- This allows the Super Admin to add unlimited new Body Types, each having its own Track A & Track B templates
DROP INDEX IF EXISTS uq_workout_routines_tenant_body_type;
DROP INDEX IF EXISTS uq_workout_routines_global_body_type;
DROP INDEX IF EXISTS uq_workout_routines_tenant_body_type_track;
DROP INDEX IF EXISTS uq_workout_routines_global_body_type_track;

CREATE UNIQUE INDEX IF NOT EXISTS uq_workout_routines_tenant_body_type_track
ON workout_routines (tenant_id, LOWER(body_type), assigned_track)
WHERE tenant_id IS NOT NULL AND user_id IS NULL AND (is_ai_generated IS FALSE OR is_ai_generated IS NULL);

CREATE UNIQUE INDEX IF NOT EXISTS uq_workout_routines_global_body_type_track
ON workout_routines (LOWER(body_type), assigned_track)
WHERE tenant_id IS NULL AND user_id IS NULL AND (is_ai_generated IS FALSE OR is_ai_generated IS NULL);

CREATE INDEX IF NOT EXISTS idx_workout_routines_user ON workout_routines(user_id);
CREATE INDEX IF NOT EXISTS idx_workout_routines_track ON workout_routines(assigned_track);
CREATE INDEX IF NOT EXISTS idx_workout_routines_track_master ON workout_routines(assigned_track) WHERE user_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_workout_routines_body_track_master ON workout_routines(LOWER(body_type), assigned_track) WHERE user_id IS NULL;

-- 3. POPULATE SWAP GROUPS & CONTRAINDICATED INJURIES ON EXERCISES
UPDATE exercises SET 
    swap_group_id = 'swap_squat',
    contraindicated_injuries = ARRAY['knee', 'lower_back']
WHERE LOWER(name) LIKE '%back squat%' OR LOWER(name) LIKE '%barbell squat%';

UPDATE exercises SET 
    swap_group_id = 'swap_squat',
    contraindicated_injuries = ARRAY['knee']
WHERE LOWER(name) LIKE '%leg press%';

UPDATE exercises SET 
    swap_group_id = 'swap_squat',
    contraindicated_injuries = '{}'::TEXT[]
WHERE LOWER(name) LIKE '%box squat%' OR LOWER(name) LIKE '%goblet squat%' OR LOWER(name) LIKE '%glute bridge%';

UPDATE exercises SET 
    swap_group_id = 'swap_hinge',
    contraindicated_injuries = ARRAY['lower_back']
WHERE LOWER(name) LIKE '%deadlift%' OR LOWER(name) LIKE '%romanian deadlift%';

UPDATE exercises SET 
    swap_group_id = 'swap_overhead_press',
    contraindicated_injuries = ARRAY['shoulder', 'lower_back']
WHERE LOWER(name) LIKE '%overhead press%' OR LOWER(name) LIKE '%military press%';

UPDATE exercises SET 
    swap_group_id = 'swap_overhead_press',
    contraindicated_injuries = ARRAY['shoulder']
WHERE LOWER(name) LIKE '%shoulder press%' AND LOWER(name) NOT LIKE '%machine%';

UPDATE exercises SET 
    swap_group_id = 'swap_overhead_press',
    contraindicated_injuries = '{}'::TEXT[]
WHERE LOWER(name) LIKE '%lateral raise%' OR LOWER(name) LIKE '%face pull%' OR LOWER(name) LIKE '%machine%shoulder%';

UPDATE exercises SET 
    swap_group_id = 'swap_chest_press',
    contraindicated_injuries = ARRAY['shoulder', 'wrist']
WHERE LOWER(name) LIKE '%bench press%';

UPDATE exercises SET 
    swap_group_id = 'swap_chest_press',
    contraindicated_injuries = ARRAY['wrist']
WHERE LOWER(name) LIKE '%push-up%' OR LOWER(name) LIKE '%push up%';

UPDATE exercises SET 
    swap_group_id = 'swap_chest_press',
    contraindicated_injuries = '{}'::TEXT[]
WHERE LOWER(name) LIKE '%cable fly%' OR LOWER(name) LIKE '%machine%chest%' OR LOWER(name) LIKE '%incline push-up%';

UPDATE exercises SET 
    swap_group_id = 'swap_biceps',
    contraindicated_injuries = ARRAY['wrist']
WHERE LOWER(name) LIKE '%barbell curl%';

UPDATE exercises SET 
    swap_group_id = 'swap_biceps',
    contraindicated_injuries = '{}'::TEXT[]
WHERE LOWER(name) LIKE '%dumbbell curl%' OR LOWER(name) LIKE '%hammer curl%';

-- 4. ENSURE STATIC MASTER 90-DAY TEMPLATES EXIST FOR TRACK A & TRACK B ACROSS BODY TYPES
-- Schema supports unlimited new body types; Super Admin simply registers a Track A and Track B template
DO $$
DECLARE
    v_day_id UUID;
    v_ex_push_id UUID;
    v_ex_shoulder_id UUID;
    v_ex_curl_id UUID;
    v_ex_squat_id UUID;
    v_tpl RECORD;
BEGIN
    -- Resolve baseline exercise IDs
    SELECT id INTO v_ex_push_id FROM exercises WHERE LOWER(name) LIKE '%push-up%' LIMIT 1;
    SELECT id INTO v_ex_shoulder_id FROM exercises WHERE LOWER(name) LIKE '%shoulder press%' LIMIT 1;
    SELECT id INTO v_ex_curl_id FROM exercises WHERE LOWER(name) LIKE '%curl%' LIMIT 1;
    SELECT id INTO v_ex_squat_id FROM exercises WHERE LOWER(name) LIKE '%squat%' LIMIT 1;

    -- Register Core Body Types with both Track A and Track B templates
    -- Super Admin can easily add unlimited new Body Types in the future
    
    -- 1. Mesomorph (Track A & Track B)
    IF NOT EXISTS (SELECT 1 FROM workout_routines WHERE id = '11111111-0000-0000-0000-000000000001'::uuid) THEN
        INSERT INTO workout_routines (id, tenant_id, user_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview, body_type, assigned_track)
        VALUES ('11111111-0000-0000-0000-000000000001'::uuid, NULL, NULL, 'Master 90-Day Dynamic Progressive Protocol (Track A - Mesomorph)', 'Standard multi-phase hypertrophy and strength protocol for athletic build with normal BMI.', 'muscle_gain', 90, FALSE, TRUE, 'mesomorph', 'track_a');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM workout_routines WHERE id = '11111111-0000-0000-0000-000000000002'::uuid) THEN
        INSERT INTO workout_routines (id, tenant_id, user_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview, body_type, assigned_track)
        VALUES ('11111111-0000-0000-0000-000000000002'::uuid, NULL, NULL, 'Master 90-Day Low-Impact Foundation (Track B - Mesomorph)', 'Low-intensity foundation for overweight beginners with athletic frame to protect joints and prevent burnout.', 'fat_loss', 90, FALSE, TRUE, 'mesomorph', 'track_b');
    END IF;

    -- 2. V-Shape (Track A & Track B)
    IF NOT EXISTS (SELECT 1 FROM workout_routines WHERE id = '33333333-0000-0000-0000-000000000001'::uuid) THEN
        INSERT INTO workout_routines (id, tenant_id, user_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview, body_type, assigned_track)
        VALUES ('33333333-0000-0000-0000-000000000001'::uuid, NULL, NULL, 'Master 90-Day V-Taper Hypertrophy (Track A - V-Shape)', 'Specialized lateral deltoid and lats volume protocol for dramatic shoulder-to-waist ratio taper.', 'muscle_gain', 90, FALSE, TRUE, 'v_shape', 'track_a');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM workout_routines WHERE id = '33333333-0000-0000-0000-000000000002'::uuid) THEN
        INSERT INTO workout_routines (id, tenant_id, user_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview, body_type, assigned_track)
        VALUES ('33333333-0000-0000-0000-000000000002'::uuid, NULL, NULL, 'Master 90-Day V-Taper Joint-Safe Foundation (Track B - V-Shape)', 'Joint-friendly upper back and posture alignment targeting shoulder taper while safely shedding body fat.', 'fat_loss', 90, FALSE, TRUE, 'v_shape', 'track_b');
    END IF;

    -- 3. Heavyweight (Track A & Track B)
    IF NOT EXISTS (SELECT 1 FROM workout_routines WHERE id = '44444444-0000-0000-0000-000000000001'::uuid) THEN
        INSERT INTO workout_routines (id, tenant_id, user_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview, body_type, assigned_track)
        VALUES ('44444444-0000-0000-0000-000000000001'::uuid, NULL, NULL, 'Master 90-Day Heavyweight Power & Density (Track A - Heavyweight)', 'Powerlifting and functional density protocol for large-framed athletes with conditioning capacity.', 'strength', 90, FALSE, TRUE, 'heavyweight', 'track_a');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM workout_routines WHERE id = '44444444-0000-0000-0000-000000000002'::uuid) THEN
        INSERT INTO workout_routines (id, tenant_id, user_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview, body_type, assigned_track)
        VALUES ('44444444-0000-0000-0000-000000000002'::uuid, NULL, NULL, 'Master 90-Day Heavyweight Low-Impact Foundation (Track B - Heavyweight)', 'Orthopedically safe machine-guided protocol reducing spinal compression and knee stress for heavyweight members.', 'fat_loss', 90, FALSE, TRUE, 'heavyweight', 'track_b');
    END IF;

    -- 4. Endomorph (Track A & Track B)
    IF NOT EXISTS (SELECT 1 FROM workout_routines WHERE id = '22222222-0000-0000-0000-000000000001'::uuid) THEN
        INSERT INTO workout_routines (id, tenant_id, user_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview, body_type, assigned_track)
        VALUES ('22222222-0000-0000-0000-000000000001'::uuid, NULL, NULL, 'Master 90-Day Endomorph Metabolic Protocol (Track A - Endomorph)', 'High-density supersets and compound conditioning for endomorph physique with athletic conditioning.', 'fat_loss', 90, FALSE, TRUE, 'endomorph', 'track_a');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM workout_routines WHERE id = '22222222-0000-0000-0000-000000000002'::uuid) THEN
        INSERT INTO workout_routines (id, tenant_id, user_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview, body_type, assigned_track)
        VALUES ('22222222-0000-0000-0000-000000000002'::uuid, NULL, NULL, 'Master 90-Day Endomorph Joint-Friendly Foundation (Track B - Endomorph)', 'Progressive joint-safe beginner cardio and resistance balance for endomorph body types.', 'fat_loss', 90, FALSE, TRUE, 'endomorph', 'track_b');
    END IF;

    -- 5. Ectomorph (Track A & Track B)
    IF NOT EXISTS (SELECT 1 FROM workout_routines WHERE id = '55555555-0000-0000-0000-000000000001'::uuid) THEN
        INSERT INTO workout_routines (id, tenant_id, user_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview, body_type, assigned_track)
        VALUES ('55555555-0000-0000-0000-000000000001'::uuid, NULL, NULL, 'Master 90-Day Ectomorph Mass Protocol (Track A - Ectomorph)', 'Low-volume, heavy compound mass builder designed for slim fast-metabolism frames.', 'muscle_gain', 90, FALSE, TRUE, 'ectomorph', 'track_a');
    END IF;
    IF NOT EXISTS (SELECT 1 FROM workout_routines WHERE id = '55555555-0000-0000-0000-000000000002'::uuid) THEN
        INSERT INTO workout_routines (id, tenant_id, user_id, title, description, target_goal, duration_days, is_ai_generated, is_public_preview, body_type, assigned_track)
        VALUES ('55555555-0000-0000-0000-000000000002'::uuid, NULL, NULL, 'Master 90-Day Ectomorph Low-Impact Foundation (Track B - Ectomorph)', 'Beginner postural and structural foundation for underweight or deconditioned ectomorphs.', 'general_fitness', 90, FALSE, TRUE, 'ectomorph', 'track_b');
    END IF;

    -- Ensure Days 1-7 and exercises exist for all seeded master templates
    FOR v_tpl IN 
        SELECT r.id, r.assigned_track 
        FROM workout_routines r 
        WHERE r.user_id IS NULL AND NOT EXISTS (SELECT 1 FROM workout_routine_days d WHERE d.routine_id = r.id)
    LOOP
        -- Day 1
        INSERT INTO workout_routine_days (routine_id, day_number, title, muscle_groups, is_rest_day)
        VALUES (v_tpl.id, 1, 'Day 1: Upper Body Mechanics', ARRAY['Chest', 'Shoulders', 'Triceps'], FALSE)
        RETURNING id INTO v_day_id;
        IF v_ex_push_id IS NOT NULL THEN
            INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds, notes)
            VALUES (v_day_id, v_ex_push_id, 1, 4, '8-12', 60, 'Compound upper press');
        END IF;
        IF v_ex_shoulder_id IS NOT NULL THEN
            INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds, notes)
            VALUES (v_day_id, v_ex_shoulder_id, 2, 4, '8-10', 75, 'Overhead pressing volume');
        END IF;

        -- Day 2
        INSERT INTO workout_routine_days (routine_id, day_number, title, muscle_groups, is_rest_day)
        VALUES (v_tpl.id, 2, 'Day 2: Posterior Chain & Pull', ARRAY['Back', 'Biceps'], FALSE)
        RETURNING id INTO v_day_id;
        IF v_ex_curl_id IS NOT NULL THEN
            INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds, notes)
            VALUES (v_day_id, v_ex_curl_id, 1, 4, '10-12', 60, 'Bicep & lat contraction');
        END IF;

        -- Day 3: Rest
        INSERT INTO workout_routine_days (routine_id, day_number, title, muscle_groups, is_rest_day)
        VALUES (v_tpl.id, 3, 'Day 3: Kinetic Mobility & Rest', ARRAY['Mobility', 'Recovery'], TRUE);

        -- Day 4
        INSERT INTO workout_routine_days (routine_id, day_number, title, muscle_groups, is_rest_day)
        VALUES (v_tpl.id, 4, 'Day 4: Lower Body Progression', ARRAY['Quadriceps', 'Hamstrings', 'Calves'], FALSE)
        RETURNING id INTO v_day_id;
        IF v_ex_squat_id IS NOT NULL THEN
            INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds, notes)
            VALUES (v_day_id, v_ex_squat_id, 1, 4, '8-12', 90, 'Lower kinetic chain load');
        END IF;

        -- Day 5
        INSERT INTO workout_routine_days (routine_id, day_number, title, muscle_groups, is_rest_day)
        VALUES (v_tpl.id, 5, 'Day 5: Shoulder & Core Conditioning', ARRAY['Shoulders', 'Core'], FALSE)
        RETURNING id INTO v_day_id;
        IF v_ex_shoulder_id IS NOT NULL THEN
            INSERT INTO workout_day_exercises (day_id, exercise_id, order_index, target_sets, target_reps_range, rest_seconds, notes)
            VALUES (v_day_id, v_ex_shoulder_id, 1, 3, '10-12', 60, 'Controlled tempo');
        END IF;

        -- Day 6 & 7: Rest
        INSERT INTO workout_routine_days (routine_id, day_number, title, muscle_groups, is_rest_day)
        VALUES (v_tpl.id, 6, 'Day 6: Low-Stress Recovery Walk', ARRAY['Cardio', 'Recovery'], TRUE);
        INSERT INTO workout_routine_days (routine_id, day_number, title, muscle_groups, is_rest_day)
        VALUES (v_tpl.id, 7, 'Day 7: Full Central Nervous System Rest', ARRAY['Rest'], TRUE);
    END LOOP;
END $$;

-- 5. RPC: ASSIGN STATIC MASTER TEMPLATE WITH SILENT BMI & INJURY SWAP (NO LLM)
-- Strict Hierarchical Flow:
-- 1. The user selects a target_body_type (e.g., V-Shape, Heavyweight) during onboarding.
-- 2. The user inputs their Age, Weight, and Height.
-- 3. The RPC calculates the BMI.
-- 4. The RPC queries master templates using BOTH conditions:
--    target_body_type = user_input AND assigned_track = dynamically_calculated_track (Track A normal/low BMI, Track B high BMI)
DROP FUNCTION IF EXISTS rpc_assign_master_workout_template(UUID, UUID, VARCHAR, NUMERIC, NUMERIC, INT, VARCHAR, TEXT[], VARCHAR);
DROP FUNCTION IF EXISTS rpc_assign_master_workout_template(UUID, UUID, NUMERIC, NUMERIC, INT, VARCHAR, TEXT[], VARCHAR);

CREATE OR REPLACE FUNCTION rpc_assign_master_workout_template(
    p_user_id UUID,
    p_tenant_id UUID DEFAULT NULL,
    p_target_body_type VARCHAR DEFAULT NULL,
    p_current_weight_kg NUMERIC DEFAULT NULL,
    p_height_cm NUMERIC DEFAULT NULL,
    p_age INT DEFAULT NULL,
    p_fitness_level VARCHAR DEFAULT 'beginner',
    p_medical_injuries TEXT[] DEFAULT '{}',
    p_override_track VARCHAR DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_tenant_id UUID := p_tenant_id;
    v_target_body_type VARCHAR(50);
    v_weight NUMERIC := p_current_weight_kg;
    v_height NUMERIC := p_height_cm;
    v_age INT := p_age;
    v_level VARCHAR := COALESCE(p_fitness_level, 'beginner');
    v_injuries TEXT[] := COALESCE(p_medical_injuries, '{}'::TEXT[]);
    v_height_m NUMERIC;
    v_bmi NUMERIC;
    v_assigned_track VARCHAR(50) := 'track_a';
    v_routing_reason TEXT;
    v_master_routine_id UUID;
    v_user_routine_id UUID;
    v_day_record RECORD;
    v_new_day_id UUID;
    v_ex_record RECORD;
    v_final_ex_id UUID;
    v_final_notes TEXT;
    v_replacement_id UUID;
    v_replacement_name VARCHAR(255);
    v_swapped_count INT := 0;
    v_days_count INT := 0;
    v_exercises_count INT := 0;
    v_template_title VARCHAR(255);
    v_template_goal fitness_goal_enum;
    v_template_body_type VARCHAR(50);
BEGIN
    -- 0. Resolve tenant_id
    IF v_tenant_id IS NULL THEN
        SELECT p.tenant_id INTO v_tenant_id FROM profiles p WHERE p.id = p_user_id;
    END IF;

    -- Strict Rule 9 Check: Verify if AI Workouts feature is enabled
    BEGIN
        IF NOT is_feature_enabled(v_tenant_id, 'ai_workouts') THEN
            RETURN jsonb_build_object(
                'success', FALSE,
                'error', 'AI Workout Engine is currently disabled by Super Administrator or Gym Management.',
                'feature_disabled', TRUE
            );
        END IF;
    EXCEPTION WHEN undefined_function THEN
        NULL;
    END;

    -- 1. Step 1: Resolve Target Body Type (Hierarchical flow step 1)
    -- Passed explicitly during onboarding or fetched from user_fitness_profiles
    IF p_target_body_type IS NOT NULL AND TRIM(p_target_body_type) <> '' THEN
        v_target_body_type := LOWER(TRIM(p_target_body_type));
    ELSE
        SELECT LOWER(TRIM(COALESCE(ufp.body_type::text, 'mesomorph')))
        INTO v_target_body_type
        FROM user_fitness_profiles ufp
        WHERE ufp.user_id = p_user_id;
    END IF;
    v_target_body_type := COALESCE(NULLIF(v_target_body_type, ''), 'mesomorph');

    -- 2. Step 2: Resolve Physiological Metrics (Age, Weight, Height)
    IF v_weight IS NULL OR v_height IS NULL OR v_age IS NULL OR cardinality(v_injuries) = 0 THEN
        SELECT 
            COALESCE(v_weight, ufp.current_weight_kg, 75.0),
            COALESCE(v_height, ufp.height_cm, 175.0),
            COALESCE(v_age, ufp.age, 26),
            COALESCE(NULLIF(v_level, 'beginner'), ufp.experience_level, 'beginner'),
            CASE WHEN cardinality(v_injuries) > 0 THEN v_injuries ELSE COALESCE(ufp.medical_injuries, '{}'::TEXT[]) END
        INTO v_weight, v_height, v_age, v_level, v_injuries
        FROM user_fitness_profiles ufp
        WHERE ufp.user_id = p_user_id;
    END IF;

    v_weight := COALESCE(v_weight, 75.0);
    v_height := COALESCE(v_height, 175.0);
    v_age := COALESCE(v_age, 26);
    v_level := LOWER(COALESCE(v_level, 'beginner'));

    -- 3. Step 3: Calculate Silent BMI
    v_height_m := v_height / 100.0;
    v_bmi := CASE WHEN v_height_m > 0 THEN (v_weight / (v_height_m * v_height_m)) ELSE 23.5 END;

    -- Strict Rule 9 & Facility Liability Check: Seniors exceeding max_allowed_ai_age must be blocked
    IF v_age >= COALESCE((SELECT (value ->> 'max_allowed_ai_age')::INT FROM global_system_settings WHERE key = 'ai_workout_config'), 55) THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'Facility Liability Protection: Automated AI routines are restricted for age ' || COALESCE((SELECT (value ->> 'max_allowed_ai_age')::INT FROM global_system_settings WHERE key = 'ai_workout_config'), 55) || '+. Please consult an in-person gym trainer.',
            'liability_blocked', TRUE,
            'max_allowed_ai_age', COALESCE((SELECT (value ->> 'max_allowed_ai_age')::INT FROM global_system_settings WHERE key = 'ai_workout_config'), 55)
        );
    END IF;

    -- 4. Step 4: Dynamically Determine Assigned Track (Track A vs Track B)
    -- High BMI (BMI >= 28.0) OR Weight >= 90kg -> Track B (Low-Impact)
    -- Normal/Low BMI -> Track A (Dynamic Progressive Overload)
    IF p_override_track IS NOT NULL AND p_override_track IN ('track_a', 'track_b') THEN
        v_assigned_track := p_override_track;
        v_routing_reason := 'Explicitly assigned to ' || UPPER(p_override_track) || '.';
    ELSIF v_weight >= 90.0 OR (v_bmi >= 28.0 AND v_level IN ('beginner', 'novice', 'intermediate')) THEN
        v_assigned_track := 'track_b';
        v_routing_reason := 'High BMI (' || ROUND(v_bmi::numeric, 1) || ') or bodyweight (' || ROUND(v_weight::numeric, 1) || 'kg) routed to Track B Low-Impact Foundation for ' || UPPER(v_target_body_type) || '.';
    ELSE
        v_assigned_track := 'track_a';
        v_routing_reason := 'Normal BMI (' || ROUND(v_bmi::numeric, 1) || ') routed to Track A Dynamic Progressive Protocol for ' || UPPER(v_target_body_type) || '.';
    END IF;

    -- 5. Step 5: Query Master Templates using BOTH conditions:
    -- target_body_type = user_input AND assigned_track = dynamically_calculated_track
    
    -- Priority 1: Gym custom master template matching BOTH target_body_type AND assigned_track
    IF v_tenant_id IS NOT NULL THEN
        SELECT r.id, r.title, r.target_goal, r.body_type 
        INTO v_master_routine_id, v_template_title, v_template_goal, v_template_body_type
        FROM workout_routines r
        WHERE r.tenant_id = v_tenant_id 
          AND LOWER(r.body_type) = v_target_body_type
          AND r.assigned_track = v_assigned_track 
          AND r.user_id IS NULL
        ORDER BY r.created_at DESC
        LIMIT 1;
    END IF;

    -- Priority 2: Platform global master template matching BOTH target_body_type AND assigned_track
    IF v_master_routine_id IS NULL THEN
        SELECT r.id, r.title, r.target_goal, r.body_type 
        INTO v_master_routine_id, v_template_title, v_template_goal, v_template_body_type
        FROM workout_routines r
        WHERE r.tenant_id IS NULL 
          AND LOWER(r.body_type) = v_target_body_type
          AND r.assigned_track = v_assigned_track 
          AND r.user_id IS NULL
        ORDER BY r.created_at DESC
        LIMIT 1;
    END IF;

    -- Priority 3: Fallback if Super Admin added a new custom body type but hasn't uploaded its specific Track template yet
    -- Gracefully fallback to any master template matching the assigned track
    IF v_master_routine_id IS NULL THEN
        SELECT r.id, r.title, r.target_goal, r.body_type 
        INTO v_master_routine_id, v_template_title, v_template_goal, v_template_body_type
        FROM workout_routines r
        WHERE r.assigned_track = v_assigned_track 
          AND r.user_id IS NULL
        ORDER BY (r.tenant_id = v_tenant_id) DESC, (LOWER(r.body_type) = 'mesomorph') DESC, r.created_at DESC
        LIMIT 1;
    END IF;

    -- Safety check: ensure template was found
    IF v_master_routine_id IS NULL THEN
        RETURN jsonb_build_object(
            'success', FALSE,
            'error', 'No master 90-day template found for body type ' || UPPER(v_target_body_type) || ' on ' || UPPER(v_assigned_track)
        );
    END IF;

    -- 6. Remove previous personalized routine for this member
    DELETE FROM workout_routines 
    WHERE user_id = p_user_id;

    -- 7. Clone Master Template to create Member Personalized Routine
    INSERT INTO workout_routines (
        tenant_id,
        user_id,
        title,
        description,
        target_goal,
        duration_days,
        is_ai_generated,
        is_public_preview,
        body_type,
        assigned_track
    ) VALUES (
        v_tenant_id,
        p_user_id,
        v_template_title || ' (Personalized)',
        'Customized for ' || UPPER(v_target_body_type) || ' (' || UPPER(v_assigned_track) || '). ' || v_routing_reason,
        COALESCE(v_template_goal, 'general_fitness'),
        90,
        FALSE,
        FALSE,
        v_target_body_type,
        v_assigned_track
    )
    RETURNING id INTO v_user_routine_id;

    -- 8. Clone Routine Days and Swap Exercises Conflicting with Medical Injuries
    FOR v_day_record IN 
        SELECT rd.id, rd.day_number, rd.title, rd.muscle_groups, rd.is_rest_day
        FROM workout_routine_days rd
        WHERE rd.routine_id = v_master_routine_id
        ORDER BY rd.day_number
    LOOP
        INSERT INTO workout_routine_days (
            routine_id,
            day_number,
            title,
            muscle_groups,
            is_rest_day
        ) VALUES (
            v_user_routine_id,
            v_day_record.day_number,
            v_day_record.title,
            v_day_record.muscle_groups,
            v_day_record.is_rest_day
        )
        RETURNING id INTO v_new_day_id;

        v_days_count := v_days_count + 1;

        -- If not a rest day, process exercises with SQL swap query
        IF NOT COALESCE(v_day_record.is_rest_day, FALSE) THEN
            FOR v_ex_record IN 
                SELECT 
                    wde.exercise_id,
                    wde.order_index,
                    wde.target_sets,
                    wde.target_reps_range,
                    wde.rest_seconds,
                    wde.superset_group_id,
                    wde.notes,
                    e.name AS orig_name,
                    e.target_muscle AS orig_target_muscle,
                    e.swap_group_id AS orig_swap_group_id,
                    e.contraindicated_injuries AS orig_injuries
                FROM workout_day_exercises wde
                JOIN exercises e ON e.id = wde.exercise_id
                WHERE wde.day_id = v_day_record.id
                ORDER BY wde.order_index
            LOOP
                v_final_ex_id := v_ex_record.exercise_id;
                v_final_notes := v_ex_record.notes;

                -- Check if exercise is contraindicated by user's medical injuries
                IF cardinality(v_injuries) > 0 AND (COALESCE(v_ex_record.orig_injuries, '{}'::TEXT[]) && v_injuries) THEN
                    v_replacement_id := NULL;
                    v_replacement_name := NULL;

                    -- SQL SWAP QUERY: Priority 1 - Look in the same swap_group_id
                    IF v_ex_record.orig_swap_group_id IS NOT NULL THEN
                        SELECT e2.id, e2.name INTO v_replacement_id, v_replacement_name
                        FROM exercises e2
                        WHERE e2.swap_group_id = v_ex_record.orig_swap_group_id
                          AND e2.id <> v_ex_record.exercise_id
                          AND NOT (COALESCE(e2.contraindicated_injuries, '{}'::TEXT[]) && v_injuries)
                          AND (v_assigned_track <> 'track_b' OR (
                              LOWER(e2.name) NOT LIKE '%jump%' 
                              AND LOWER(e2.name) NOT LIKE '%box jump%'
                              AND LOWER(e2.name) NOT LIKE '%burpee%'
                              AND LOWER(e2.name) NOT LIKE '%barbell deadlift%'
                          ))
                        ORDER BY e2.difficulty, e2.name
                        LIMIT 1;
                    END IF;

                    -- SQL SWAP QUERY: Priority 2 - If no swap_group match, find safe exercise in same target muscle
                    IF v_replacement_id IS NULL THEN
                        SELECT e3.id, e3.name INTO v_replacement_id, v_replacement_name
                        FROM exercises e3
                        WHERE LOWER(e3.target_muscle) = LOWER(v_ex_record.orig_target_muscle)
                          AND e3.id <> v_ex_record.exercise_id
                          AND NOT (COALESCE(e3.contraindicated_injuries, '{}'::TEXT[]) && v_injuries)
                          AND (v_assigned_track <> 'track_b' OR (
                              LOWER(e3.name) NOT LIKE '%jump%' 
                              AND LOWER(e3.name) NOT LIKE '%box jump%'
                              AND LOWER(e3.name) NOT LIKE '%burpee%'
                              AND LOWER(e3.name) NOT LIKE '%barbell deadlift%'
                          ))
                        ORDER BY e3.difficulty, e3.name
                        LIMIT 1;
                    END IF;

                    -- Apply swap if safe alternative was found
                    IF v_replacement_id IS NOT NULL THEN
                        v_final_ex_id := v_replacement_id;
                        v_swapped_count := v_swapped_count + 1;
                        v_final_notes := 'Substituted from ' || v_ex_record.orig_name || ' to protect ' || array_to_string(v_injuries, ', ') || '.';
                    END IF;
                END IF;

                -- Insert into user's personalized routine day
                INSERT INTO workout_day_exercises (
                    day_id,
                    exercise_id,
                    order_index,
                    target_sets,
                    target_reps_range,
                    rest_seconds,
                    superset_group_id,
                    notes
                ) VALUES (
                    v_new_day_id,
                    v_final_ex_id,
                    v_ex_record.order_index,
                    v_ex_record.target_sets,
                    v_ex_record.target_reps_range,
                    v_ex_record.rest_seconds,
                    v_ex_record.superset_group_id,
                    v_final_notes
                );

                v_exercises_count := v_exercises_count + 1;
            END LOOP;
        END IF;
    END LOOP;

    -- 9. Bind Routine to User's Fitness Profile
    UPDATE user_fitness_profiles SET
        body_type = v_target_body_type,
        current_workout_routine_id = v_user_routine_id,
        assigned_workout_track = v_assigned_track,
        current_weight_kg = COALESCE(v_weight, current_weight_kg),
        height_cm = COALESCE(v_height, height_cm),
        age = COALESCE(v_age, age),
        medical_injuries = v_injuries,
        profile_completed = TRUE,
        ai_recommendations = jsonb_build_object(
            'engine_type', 'static_master_template',
            'master_template_id', v_master_routine_id,
            'user_routine_id', v_user_routine_id,
            'target_body_type', v_target_body_type,
            'assigned_track', v_assigned_track,
            'bmi', ROUND(v_bmi::numeric, 2),
            'routing_reason', v_routing_reason,
            'swapped_exercises_count', v_swapped_count,
            'assigned_at', NOW()
        ),
        updated_at = NOW()
    WHERE user_id = p_user_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'routine_id', v_user_routine_id,
        'master_template_id', v_master_routine_id,
        'target_body_type', v_target_body_type,
        'assigned_track', v_assigned_track,
        'bmi', ROUND(v_bmi::numeric, 2),
        'routing_reason', v_routing_reason,
        'swapped_exercises_count', v_swapped_count,
        'days_assigned', v_days_count,
        'exercises_mapped', v_exercises_count,
        'routine_title', v_template_title || ' (Personalized)'
    );
END;
$$;

-- 6. RPC: GET ELIGIBLE EXERCISES (FOR MANUAL 1-TAP SWAP IN UI)
DROP FUNCTION IF EXISTS rpc_get_eligible_exercises_for_ai(UUID, TEXT[], VARCHAR);
CREATE OR REPLACE FUNCTION rpc_get_eligible_exercises_for_ai(
    p_tenant_id UUID,
    p_medical_injuries TEXT[] DEFAULT '{}',
    p_assigned_track VARCHAR DEFAULT 'track_a'
)
RETURNS TABLE (
    id UUID,
    name VARCHAR(255),
    target_muscle VARCHAR(100),
    secondary_muscles TEXT[],
    equipment VARCHAR(100),
    difficulty VARCHAR(50),
    swap_group_id VARCHAR(100),
    ml_pose_exercise_type VARCHAR(50),
    video_url TEXT,
    side_video_url TEXT,
    thumbnail_url TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id,
        e.name,
        e.target_muscle,
        e.secondary_muscles,
        e.equipment,
        e.difficulty,
        e.swap_group_id,
        e.ml_pose_exercise_type,
        e.video_url,
        e.side_video_url,
        e.thumbnail_url
    FROM exercises e
    WHERE (e.tenant_id = p_tenant_id OR e.tenant_id IS NULL OR e.is_global = TRUE)
      -- Purge exercises contraindicated by user's medical injuries
      AND NOT (
          COALESCE(e.contraindicated_injuries, '{}'::TEXT[]) && COALESCE(p_medical_injuries, '{}'::TEXT[])
      )
      -- Track B (Beginner Low-Impact) Safeguard: Purge high-impact plyometrics & extreme spinal loads
      AND (
          p_assigned_track <> 'track_b'
          OR (
              LOWER(e.name) NOT LIKE '%jump%'
              AND LOWER(e.name) NOT LIKE '%box jump%'
              AND LOWER(e.name) NOT LIKE '%burpee%'
              AND LOWER(e.name) NOT LIKE '%barbell deadlift%'
              AND LOWER(e.name) NOT LIKE '%clean and jerk%'
              AND LOWER(e.name) NOT LIKE '%snatch%'
          )
      )
    ORDER BY e.target_muscle, e.name;
END;
$$;
