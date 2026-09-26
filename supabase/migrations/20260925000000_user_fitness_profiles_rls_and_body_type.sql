-- ======================================================================================
-- MIGRATION: 20260925000000_user_fitness_profiles_rls_and_body_type.sql
-- Description: 1. Ensure user_fitness_profiles table exists with valid body_type and fitness_goal enums.
--              2. Fix missing RLS policies on user_fitness_profiles (Grant authenticated users
--                 full access to view and update their own genetics & fitness profile).
--              3. Grant gym staff read permissions for coaching.
--              4. Ensure index on workout_routines(body_type).
-- ======================================================================================

-- 1. Ensure body_type_enum and fitness_goal_enum exist
DO $$ BEGIN
    CREATE TYPE body_type_enum AS ENUM (
        'ectomorph',
        'mesomorph',
        'endomorph'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
    CREATE TYPE fitness_goal_enum AS ENUM (
        'muscle_gain',
        'fat_loss',
        'strength',
        'endurance',
        'general_fitness'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- 2. Ensure user_fitness_profiles table exists
CREATE TABLE IF NOT EXISTS user_fitness_profiles (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    height_cm NUMERIC(5, 2),
    current_weight_kg NUMERIC(5, 2),
    target_weight_kg NUMERIC(5, 2),
    body_type body_type_enum NOT NULL DEFAULT 'mesomorph',
    fitness_goal fitness_goal_enum NOT NULL DEFAULT 'general_fitness',
    experience_level VARCHAR(50) DEFAULT 'beginner',
    medical_notes TEXT,
    preferred_days_per_week INT DEFAULT 4 CHECK (preferred_days_per_week BETWEEN 1 AND 7),
    ai_recommendations JSONB DEFAULT '{}'::jsonb,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Ensure workout_routines has body_type column
ALTER TABLE IF EXISTS workout_routines 
ADD COLUMN IF NOT EXISTS body_type VARCHAR(50) DEFAULT 'mesomorph';

CREATE INDEX IF NOT EXISTS idx_workout_routines_body_type ON workout_routines(body_type);

-- 4. Enable Row Level Security
ALTER TABLE user_fitness_profiles ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies: Authenticated users manage their own fitness profile
DROP POLICY IF EXISTS "Users can manage their own fitness profile" ON user_fitness_profiles;
CREATE POLICY "Users can manage their own fitness profile" ON user_fitness_profiles
    FOR ALL USING (
        user_id = auth.uid() OR auth_is_super_admin()
    ) WITH CHECK (
        user_id = auth.uid() OR auth_is_super_admin()
    );

-- 6. RLS Policies: Gym owners & staff can view fitness profiles of their members
DROP POLICY IF EXISTS "Gym staff can view member fitness profiles" ON user_fitness_profiles;
CREATE POLICY "Gym staff can view member fitness profiles" ON user_fitness_profiles
    FOR SELECT USING (
        auth_is_super_admin() OR
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = user_fitness_profiles.user_id 
            AND profiles.tenant_id = auth_current_tenant_id()
        )
    );
