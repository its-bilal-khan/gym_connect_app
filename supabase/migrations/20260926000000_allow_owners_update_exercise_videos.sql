-- ==============================================================================
-- GYMCONNECT: ALLOW GYM OWNERS & STAFF TO MANAGE EXERCISE VIDEOS
-- Migration: 20260926000000_allow_owners_update_exercise_videos.sql
-- ==============================================================================

DROP POLICY IF EXISTS "Super admins and owners manage exercises" ON exercises;

CREATE POLICY "Super admins and owners manage exercises" ON exercises
    FOR ALL USING (
        auth_is_super_admin() 
        OR tenant_id = auth_current_tenant_id() 
        OR tenant_id IS NULL
        OR auth.role() = 'authenticated'
    )
    WITH CHECK (
        auth_is_super_admin() 
        OR tenant_id = auth_current_tenant_id() 
        OR tenant_id IS NULL
        OR auth.role() = 'authenticated'
    );
