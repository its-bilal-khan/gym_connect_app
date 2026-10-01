-- ======================================================================================
-- MIGRATION: 20261001010000_auth_signup_trigger_and_profiles_sync.sql
-- Description: Real Supabase Authentication & Automatic Database Sync Flow:
--              1. Automatic trigger on auth.users (handle_new_auth_user) creating:
--                 - profiles row (role = 'member', active, tenant assigned)
--                 - user_fitness_profiles row (profile_completed = FALSE, track_a)
--                 - member_gamification row (0 streak, 0 points)
--              2. RPC rpc_sync_new_user_profile for application-level fallback sync
--              3. Bulletproof RLS policies for members managing their own profiles
-- ======================================================================================

-- --------------------------------------------------------------------------------------
-- 1. TRIGGER FUNCTION: handle_new_auth_user
-- --------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_auth_user()
RETURNS TRIGGER AS $$
DECLARE
    v_tenant_id UUID;
    v_role VARCHAR(50);
    v_full_name TEXT;
    v_tenant_str TEXT;
BEGIN
    -- 1. Extract metadata from raw_user_meta_data
    v_tenant_str := NEW.raw_user_meta_data->>'tenant_id';
    v_role := COALESCE(NEW.raw_user_meta_data->>'role', 'member');
    v_full_name := COALESCE(
        NULLIF(NEW.raw_user_meta_data->>'full_name', ''),
        NULLIF(split_part(NEW.email, '@', 1), ''),
        'Gym Member'
    );

    -- 2. Resolve tenant_id
    IF v_tenant_str IS NOT NULL AND v_tenant_str ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' THEN
        v_tenant_id := v_tenant_str::uuid;
    ELSE
        SELECT id INTO v_tenant_id FROM public.tenants ORDER BY created_at ASC LIMIT 1;
        IF v_tenant_id IS NULL THEN
            v_tenant_id := '00000000-0000-0000-0000-000000000001'::uuid;
        END IF;
    END IF;

    -- 3. Upsert into public.profiles
    INSERT INTO public.profiles (
        id,
        tenant_id,
        role,
        full_name,
        email,
        is_active,
        raw_user_meta,
        created_at,
        updated_at
    ) VALUES (
        NEW.id,
        v_tenant_id,
        v_role,
        v_full_name,
        COALESCE(NEW.email, ''),
        TRUE,
        COALESCE(NEW.raw_user_meta_data, '{}'::jsonb),
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = EXCLUDED.full_name,
        email = EXCLUDED.email,
        tenant_id = COALESCE(profiles.tenant_id, EXCLUDED.tenant_id),
        updated_at = NOW();

    -- 4. Upsert into public.user_fitness_profiles with profile_completed = FALSE
    INSERT INTO public.user_fitness_profiles (
        user_id,
        profile_completed,
        assigned_workout_track,
        body_type,
        fitness_goal,
        experience_level,
        preferred_days_per_week,
        current_step_target,
        consecutive_target_misses,
        medical_injuries,
        updated_at
    ) VALUES (
        NEW.id,
        FALSE,
        'track_a',
        'mesomorph',
        'general_fitness',
        'beginner',
        6,
        10000,
        0,
        '{}'::text[],
        NOW()
    )
    ON CONFLICT (user_id) DO UPDATE SET
        updated_at = NOW()
    WHERE user_fitness_profiles.profile_completed IS NULL;

    -- 5. Upsert into public.member_gamification
    INSERT INTO public.member_gamification (
        user_id,
        current_streak_days,
        total_points,
        monthly_points,
        streak_multiplier,
        last_activity_date
    ) VALUES (
        NEW.id,
        0,
        0,
        0,
        1.00,
        CURRENT_DATE
    )
    ON CONFLICT (user_id) DO NOTHING;

    RETURN NEW;
EXCEPTION WHEN OTHERS THEN
    RAISE WARNING 'handle_new_auth_user error: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --------------------------------------------------------------------------------------
-- 2. ATTACH TRIGGER TO auth.users
-- --------------------------------------------------------------------------------------
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_auth_user();

-- --------------------------------------------------------------------------------------
-- 3. APPLICATION-LEVEL FALLBACK RPC: rpc_sync_new_user_profile
-- --------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.rpc_sync_new_user_profile(
    p_user_id UUID,
    p_email TEXT,
    p_full_name TEXT,
    p_tenant_id UUID DEFAULT NULL
)
RETURNS JSONB AS $$
DECLARE
    v_tenant_id UUID := p_tenant_id;
    v_profile_completed BOOLEAN;
BEGIN
    IF v_tenant_id IS NULL THEN
        SELECT id INTO v_tenant_id FROM public.tenants ORDER BY created_at ASC LIMIT 1;
        IF v_tenant_id IS NULL THEN
            v_tenant_id := '00000000-0000-0000-0000-000000000001'::uuid;
        END IF;
    END IF;

    -- Upsert profile
    INSERT INTO public.profiles (
        id, tenant_id, role, full_name, email, is_active, created_at, updated_at
    ) VALUES (
        p_user_id, v_tenant_id, 'member', p_full_name, p_email, TRUE, NOW(), NOW()
    )
    ON CONFLICT (id) DO UPDATE SET
        full_name = COALESCE(NULLIF(p_full_name, ''), profiles.full_name),
        email = COALESCE(NULLIF(p_email, ''), profiles.email),
        updated_at = NOW();

    -- Ensure user_fitness_profiles exists
    INSERT INTO public.user_fitness_profiles (
        user_id, profile_completed, assigned_workout_track, body_type, fitness_goal, experience_level, updated_at
    ) VALUES (
        p_user_id, FALSE, 'track_a', 'mesomorph', 'general_fitness', 'beginner', NOW()
    )
    ON CONFLICT (user_id) DO NOTHING;

    -- Ensure member_gamification exists
    INSERT INTO public.member_gamification (
        user_id, current_streak_days, total_points, monthly_points, streak_multiplier, last_activity_date
    ) VALUES (
        p_user_id, 0, 0, 0, 1.00, CURRENT_DATE
    )
    ON CONFLICT (user_id) DO NOTHING;

    SELECT profile_completed INTO v_profile_completed
    FROM public.user_fitness_profiles
    WHERE user_id = p_user_id;

    RETURN jsonb_build_object(
        'success', TRUE,
        'user_id', p_user_id,
        'tenant_id', v_tenant_id,
        'profile_completed', COALESCE(v_profile_completed, FALSE)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --------------------------------------------------------------------------------------
-- 4. RLS POLICIES FOR USERS MANAGING THEIR OWN PROFILE
-- --------------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Users can view and edit own profile" ON profiles;
CREATE POLICY "Users can view and edit own profile" ON profiles
    FOR ALL USING (
        id = auth.uid() OR auth_is_super_admin()
    ) WITH CHECK (
        id = auth.uid() OR auth_is_super_admin()
    );

GRANT EXECUTE ON FUNCTION public.handle_new_auth_user() TO service_role, postgres;
GRANT EXECUTE ON FUNCTION public.rpc_sync_new_user_profile(UUID, TEXT, TEXT, UUID) TO authenticated, service_role, anon;
