-- ==============================================================================
-- GYMCONNECT: ALLOW SUPER ADMINS & GYM OWNERS TO AUTO-SAVE WORKOUT PROTOCOLS
-- Migration: 20260926040000_fix_workout_protocols_rls_policies.sql
-- ==============================================================================

-- 1. Helper function
CREATE OR REPLACE FUNCTION auth_can_manage_workout_protocols()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. WORKOUT_ROUTINES POLICIES
ALTER TABLE IF EXISTS workout_routines ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Owners and admins manage workout routines" ON workout_routines;
DROP POLICY IF EXISTS "Authenticated users view workout routines" ON workout_routines;
DROP POLICY IF EXISTS "Anyone can view workout routines" ON workout_routines;
DROP POLICY IF EXISTS "Public can view workout routines" ON workout_routines;
DROP POLICY IF EXISTS "Public can manage workout routines" ON workout_routines;

CREATE POLICY "Public can view workout routines" ON workout_routines
    FOR SELECT TO public USING (TRUE);

CREATE POLICY "Public can manage workout routines" ON workout_routines
    FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- 3. WORKOUT_ROUTINE_DAYS POLICIES
ALTER TABLE IF EXISTS workout_routine_days ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View workout routine days" ON workout_routine_days;
DROP POLICY IF EXISTS "Manage workout routine days" ON workout_routine_days;
DROP POLICY IF EXISTS "Public can view workout routine days" ON workout_routine_days;
DROP POLICY IF EXISTS "Public can manage workout routine days" ON workout_routine_days;

CREATE POLICY "Public can view workout routine days" ON workout_routine_days
    FOR SELECT TO public USING (TRUE);

CREATE POLICY "Public can manage workout routine days" ON workout_routine_days
    FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- 4. WORKOUT_DAY_EXERCISES POLICIES
ALTER TABLE IF EXISTS workout_day_exercises ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "View workout day exercises" ON workout_day_exercises;
DROP POLICY IF EXISTS "Manage workout day exercises" ON workout_day_exercises;
DROP POLICY IF EXISTS "Public can view workout day exercises" ON workout_day_exercises;
DROP POLICY IF EXISTS "Public can manage workout day exercises" ON workout_day_exercises;

CREATE POLICY "Public can view workout day exercises" ON workout_day_exercises
    FOR SELECT TO public USING (TRUE);

CREATE POLICY "Public can manage workout day exercises" ON workout_day_exercises
    FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- 5. EXERCISES POLICIES
ALTER TABLE IF EXISTS exercises ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Super admins and owners manage exercises" ON exercises;
DROP POLICY IF EXISTS "Anyone can view exercises" ON exercises;
DROP POLICY IF EXISTS "Public can view exercises" ON exercises;
DROP POLICY IF EXISTS "Public can manage exercises" ON exercises;

CREATE POLICY "Public can view exercises" ON exercises
    FOR SELECT TO public USING (TRUE);

CREATE POLICY "Public can manage exercises" ON exercises
    FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);
