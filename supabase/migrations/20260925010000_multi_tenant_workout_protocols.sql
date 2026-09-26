-- ======================================================================================
-- MIGRATION: 20260925010000_multi_tenant_workout_protocols.sql
-- PURPOSE: Enable Multi-Tenant Workout & Body Type Protocol Customization
--          - Platform Super Admin sets universal master defaults (tenant_id IS NULL).
--          - Gym Owners can customize/override 7-day splits for their gym (tenant_id = :tenant_id).
--          - Members fallback hierarchically: Gym Custom -> Platform Default.
--          - Adds full RLS policies for Desktop POS & Super Admin protocol management.
-- ======================================================================================

-- 1. Ensure columns exist on workout_routines
ALTER TABLE IF EXISTS workout_routines
ADD COLUMN IF NOT EXISTS tenant_id UUID REFERENCES tenants(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS body_type VARCHAR(50) DEFAULT 'mesomorph';

-- 2. Create partial unique indexes for multi-tenant protocol hierarchy
CREATE UNIQUE INDEX IF NOT EXISTS uq_workout_routines_tenant_body_type
ON workout_routines (tenant_id, body_type)
WHERE tenant_id IS NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_workout_routines_global_body_type
ON workout_routines (body_type)
WHERE tenant_id IS NULL;

-- 3. Enable RLS on all workout hierarchy tables
ALTER TABLE IF EXISTS workout_routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS workout_routine_days ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS workout_day_exercises ENABLE ROW LEVEL SECURITY;

-- 4. RLS for workout_routines
DROP POLICY IF EXISTS "Anyone can view workout routines" ON workout_routines;
DROP POLICY IF EXISTS "Authenticated users view workout routines" ON workout_routines;
DROP POLICY IF EXISTS "Owners and admins manage workout routines" ON workout_routines;

CREATE POLICY "Authenticated users view workout routines" ON workout_routines
    FOR SELECT USING (
        is_public_preview = TRUE 
        OR tenant_id IS NULL 
        OR tenant_id = auth_current_tenant_id()
        OR auth_is_super_admin()
        OR auth.role() = 'authenticated'
    );

CREATE POLICY "Owners and admins manage workout routines" ON workout_routines
    FOR ALL USING (
        auth_is_super_admin() 
        OR tenant_id = auth_current_tenant_id()
        OR (tenant_id IS NULL AND auth_is_super_admin())
    ) WITH CHECK (
        auth_is_super_admin() 
        OR tenant_id = auth_current_tenant_id()
        OR (tenant_id IS NULL AND auth_is_super_admin())
    );

-- 5. RLS for workout_routine_days
DROP POLICY IF EXISTS "View workout routine days" ON workout_routine_days;
DROP POLICY IF EXISTS "Manage workout routine days" ON workout_routine_days;

CREATE POLICY "View workout routine days" ON workout_routine_days
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM workout_routines r
            WHERE r.id = workout_routine_days.routine_id
            AND (
                r.is_public_preview = TRUE 
                OR r.tenant_id IS NULL 
                OR r.tenant_id = auth_current_tenant_id()
                OR auth_is_super_admin()
                OR auth.role() = 'authenticated'
            )
        )
    );

CREATE POLICY "Manage workout routine days" ON workout_routine_days
    FOR ALL USING (
        auth_is_super_admin() 
        OR EXISTS (
            SELECT 1 FROM workout_routines r
            WHERE r.id = workout_routine_days.routine_id
            AND (r.tenant_id = auth_current_tenant_id() OR auth_is_super_admin())
        )
    ) WITH CHECK (
        auth_is_super_admin() 
        OR EXISTS (
            SELECT 1 FROM workout_routines r
            WHERE r.id = workout_routine_days.routine_id
            AND (r.tenant_id = auth_current_tenant_id() OR auth_is_super_admin())
        )
    );

-- 6. RLS for workout_day_exercises
DROP POLICY IF EXISTS "View workout day exercises" ON workout_day_exercises;
DROP POLICY IF EXISTS "Manage workout day exercises" ON workout_day_exercises;

CREATE POLICY "View workout day exercises" ON workout_day_exercises
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM workout_routine_days d
            JOIN workout_routines r ON r.id = d.routine_id
            WHERE d.id = workout_day_exercises.day_id
            AND (
                r.is_public_preview = TRUE 
                OR r.tenant_id IS NULL 
                OR r.tenant_id = auth_current_tenant_id()
                OR auth_is_super_admin()
                OR auth.role() = 'authenticated'
            )
        )
    );

CREATE POLICY "Manage workout day exercises" ON workout_day_exercises
    FOR ALL USING (
        auth_is_super_admin() 
        OR EXISTS (
            SELECT 1 FROM workout_routine_days d
            JOIN workout_routines r ON r.id = d.routine_id
            WHERE d.id = workout_day_exercises.day_id
            AND (r.tenant_id = auth_current_tenant_id() OR auth_is_super_admin())
        )
    ) WITH CHECK (
        auth_is_super_admin() 
        OR EXISTS (
            SELECT 1 FROM workout_routine_days d
            JOIN workout_routines r ON r.id = d.routine_id
            WHERE d.id = workout_day_exercises.day_id
            AND (r.tenant_id = auth_current_tenant_id() OR auth_is_super_admin())
        )
    );
