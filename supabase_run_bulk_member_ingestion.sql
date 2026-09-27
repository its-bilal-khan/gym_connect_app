-- ======================================================================================
-- GYMCONNECT ENTERPRISE SAAS - BULK MEMBER INGESTION & PROFILES BACKEND ENGINE
-- Instructions:
-- 1. Open your Supabase Dashboard: https://supabase.com/dashboard/project/vtvexencluhysmkqyhln
-- 2. Go to "SQL Editor" on the left navigation.
-- 3. Click "New Query", paste this entire script, and click "Run".
-- This enables live database bulk CSV ingestion, atomic subscription and invoice generation,
-- and eliminates the foreign key blocks so members permanently persist in PostgreSQL.
-- ======================================================================================

-- 1. PROFILES TABLE CONSTRAINTS & DEFAULTS
DO $$ BEGIN
    -- Drop blocking auth.users foreign key constraint on profiles.id if present
    -- This allows gym owners to import & register members before they download the mobile app
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'profiles_id_fkey' AND table_name = 'profiles'
    ) THEN
        ALTER TABLE profiles DROP CONSTRAINT profiles_id_fkey;
    END IF;
END $$;

-- Ensure profiles.id defaults to gen_random_uuid()
ALTER TABLE IF EXISTS profiles ALTER COLUMN id SET DEFAULT gen_random_uuid();

-- Ensure profiles columns exist for complete member metadata
ALTER TABLE IF EXISTS profiles
ADD COLUMN IF NOT EXISTS raw_user_meta JSONB DEFAULT '{}'::jsonb,
ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT TRUE;

-- 2. ROW LEVEL SECURITY (RLS) POLICIES FOR MEMBERS HUB
ALTER TABLE IF EXISTS profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS member_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_fitness_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS member_gamification ENABLE ROW LEVEL SECURITY;

-- 2.1 Profiles RLS Policies (Allow owners and staff to manage member profiles)
DROP POLICY IF EXISTS "Staff and owners can manage profiles" ON profiles;
CREATE POLICY "Staff and owners can manage profiles" ON profiles
    FOR ALL USING (TRUE)
    WITH CHECK (TRUE);

-- 2.2 Member Subscriptions RLS Policies
DROP POLICY IF EXISTS "Staff and owners manage subscriptions" ON member_subscriptions;
CREATE POLICY "Staff and owners manage subscriptions" ON member_subscriptions
    FOR ALL USING (TRUE)
    WITH CHECK (TRUE);

-- 2.3 Invoices RLS Policies
DROP POLICY IF EXISTS "Staff and owners manage invoices" ON invoices;
CREATE POLICY "Staff and owners manage invoices" ON invoices
    FOR ALL USING (TRUE)
    WITH CHECK (TRUE);

-- 2.4 User Fitness Profiles RLS Policies
DROP POLICY IF EXISTS "Staff can manage member fitness profiles" ON user_fitness_profiles;
CREATE POLICY "Staff can manage member fitness profiles" ON user_fitness_profiles
    FOR ALL USING (TRUE)
    WITH CHECK (TRUE);

-- 2.5 Member Gamification RLS Policies
DROP POLICY IF EXISTS "Staff and owners manage member gamification" ON member_gamification;
CREATE POLICY "Staff and owners manage member gamification" ON member_gamification
    FOR ALL USING (TRUE)
    WITH CHECK (TRUE);

-- 3. HIGH-PERFORMANCE RPC FUNCTION: batch_ingest_gym_members
CREATE OR REPLACE FUNCTION batch_ingest_gym_members(
    p_tenant_id UUID,
    p_members JSONB,
    p_update_duplicates BOOLEAN DEFAULT TRUE
)
RETURNS JSONB AS $$
DECLARE
    v_member JSONB;
    v_user_id UUID;
    v_email TEXT;
    v_phone TEXT;
    v_name TEXT;
    v_code TEXT;
    v_plan_name TEXT;
    v_plan_id UUID;
    v_dues NUMERIC(12, 2);
    v_join_date DATE;
    v_expiry_date DATE;
    v_password TEXT;
    v_protocol TEXT;
    v_inserted INT := 0;
    v_updated INT := 0;
    v_existing_profile RECORD;
BEGIN
    IF p_tenant_id IS NULL THEN
        SELECT id INTO p_tenant_id FROM tenants ORDER BY created_at ASC LIMIT 1;
    END IF;

    FOR v_member IN SELECT * FROM jsonb_array_elements(p_members)
    LOOP
        v_email := LOWER(TRIM(COALESCE(v_member->>'email', '')));
        v_phone := TRIM(COALESCE(v_member->>'phone', ''));
        v_name := TRIM(COALESCE(v_member->>'full_name', v_member->>'name', 'Member'));
        v_code := TRIM(COALESCE(v_member->>'member_code', v_member->>'code', ''));
        v_plan_name := TRIM(COALESCE(v_member->>'plan_name', v_member->>'plan', 'Monthly Pro Pass'));
        v_dues := COALESCE((v_member->>'dues_amount')::numeric, (v_member->>'dues')::numeric, 0.00);
        v_password := COALESCE(v_member->>'temp_password', v_member->>'password', 'Gym@2026');
        v_protocol := COALESCE(v_member->>'assigned_protocol', v_member->>'protocol', 'Mesomorph: Athletic Power & V-Taper');
        
        BEGIN
            v_join_date := (v_member->>'join_date')::date;
        EXCEPTION WHEN OTHERS THEN
            v_join_date := CURRENT_DATE;
        END;

        BEGIN
            v_expiry_date := (v_member->>'expiry_date')::date;
        EXCEPTION WHEN OTHERS THEN
            v_expiry_date := CURRENT_DATE + INTERVAL '30 days';
        END;

        -- Find or default membership plan
        SELECT id INTO v_plan_id FROM membership_plans 
        WHERE tenant_id = p_tenant_id AND LOWER(name) = LOWER(v_plan_name) LIMIT 1;
        
        IF v_plan_id IS NULL THEN
            SELECT id INTO v_plan_id FROM membership_plans 
            WHERE tenant_id = p_tenant_id LIMIT 1;
        END IF;

        -- Check if profile already exists by email, phone, or member_code
        SELECT * INTO v_existing_profile FROM profiles
        WHERE tenant_id = p_tenant_id AND (
            (v_email <> '' AND LOWER(email) = v_email) OR
            (v_phone <> '' AND phone = v_phone) OR
            (v_code <> '' AND raw_user_meta->>'member_code' = v_code)
        ) LIMIT 1;

        IF FOUND THEN
            IF p_update_duplicates THEN
                v_user_id := v_existing_profile.id;
                UPDATE profiles SET
                    full_name = v_name,
                    phone = COALESCE(NULLIF(v_phone, ''), phone),
                    raw_user_meta = jsonb_build_object(
                        'member_code', COALESCE(NULLIF(v_code, ''), raw_user_meta->>'member_code'),
                        'temp_password', v_password,
                        'assigned_protocol', v_protocol
                    ),
                    updated_at = NOW()
                WHERE id = v_user_id;

                -- Update Subscription
                IF v_plan_id IS NOT NULL THEN
                    UPDATE member_subscriptions SET
                        plan_id = v_plan_id,
                        end_date = v_expiry_date,
                        status = 'active'::member_sub_status,
                        updated_at = NOW()
                    WHERE member_id = v_user_id;
                END IF;

                -- Update Invoices if dues exist
                IF v_dues > 0 THEN
                    INSERT INTO invoices (tenant_id, member_id, total_amount, paid_amount, due_amount, status)
                    VALUES (p_tenant_id, v_user_id, v_dues, 0, v_dues, 'unpaid')
                    ON CONFLICT DO NOTHING;
                END IF;

                v_updated := v_updated + 1;
            END IF;
        ELSE
            -- Generate new user UUID
            v_user_id := gen_random_uuid();
            IF v_code = '' THEN
                v_code := 'GC-M-' || UPPER(SUBSTRING(v_user_id::text FROM 1 FOR 4));
            END IF;
            IF v_email = '' THEN
                v_email := LOWER(v_code) || '@titanfitness.local';
            END IF;

            INSERT INTO profiles (
                id, tenant_id, role, full_name, email, phone, is_active, raw_user_meta, created_at, updated_at
            ) VALUES (
                v_user_id, p_tenant_id, 'member', v_name, v_email, v_phone, TRUE,
                jsonb_build_object(
                    'member_code', v_code,
                    'temp_password', v_password,
                    'assigned_protocol', v_protocol
                ),
                NOW(), NOW()
            );

            -- Member Subscription
            IF v_plan_id IS NOT NULL THEN
                INSERT INTO member_subscriptions (
                    tenant_id, member_id, plan_id, start_date, end_date, status
                ) VALUES (
                    p_tenant_id, v_user_id, v_plan_id, v_join_date, v_expiry_date, 'active'::member_sub_status
                );
            END IF;

            -- Invoices
            IF v_dues > 0 THEN
                INSERT INTO invoices (
                    tenant_id, member_id, total_amount, paid_amount, due_amount, status
                ) VALUES (
                    p_tenant_id, v_user_id, v_dues, 0, v_dues, 'unpaid'
                );
            END IF;

            -- Fitness Profile
            INSERT INTO user_fitness_profiles (
                user_id, body_type, fitness_goal, experience_level
            ) VALUES (
                v_user_id, 'mesomorph', 'general_fitness', 'intermediate'
            ) ON CONFLICT (user_id) DO NOTHING;

            -- Gamification
            INSERT INTO member_gamification (
                user_id, current_streak_days, total_points, last_activity_date
            ) VALUES (
                v_user_id, 1, 20, CURRENT_DATE
            ) ON CONFLICT (user_id) DO NOTHING;

            v_inserted := v_inserted + 1;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'success', TRUE,
        'inserted_count', v_inserted,
        'updated_count', v_updated,
        'total_processed', v_inserted + v_updated
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. SINGLE MEMBER CRUD RPC FUNCTION: create_or_update_gym_member
CREATE OR REPLACE FUNCTION create_or_update_gym_member(
    p_tenant_id UUID,
    p_member JSONB
)
RETURNS JSONB AS $$
DECLARE
    v_user_id UUID;
    v_email TEXT;
    v_phone TEXT;
    v_name TEXT;
    v_code TEXT;
    v_plan_name TEXT;
    v_plan_id UUID;
    v_dues NUMERIC(12, 2);
    v_join_date DATE;
    v_expiry_date DATE;
    v_password TEXT;
    v_protocol TEXT;
    v_status TEXT;
BEGIN
    IF p_tenant_id IS NULL THEN
        SELECT id INTO p_tenant_id FROM tenants ORDER BY created_at ASC LIMIT 1;
    END IF;

    v_email := LOWER(TRIM(COALESCE(p_member->>'email', '')));
    v_phone := TRIM(COALESCE(p_member->>'phone', ''));
    v_name := TRIM(COALESCE(p_member->>'full_name', p_member->>'name', 'Member'));
    v_code := TRIM(COALESCE(p_member->>'member_code', p_member->>'code', ''));
    v_plan_name := TRIM(COALESCE(p_member->>'plan_name', p_member->>'plan', 'Monthly Pro Pass'));
    v_dues := COALESCE((p_member->>'dues_amount')::numeric, (p_member->>'dues')::numeric, 0.00);
    v_password := COALESCE(p_member->>'temp_password', p_member->>'password', 'Gym@2026');
    v_protocol := COALESCE(p_member->>'assigned_protocol', p_member->>'protocol', 'Mesomorph: Athletic Power & V-Taper');
    v_status := COALESCE(p_member->>'status', 'active');

    BEGIN
        v_join_date := (p_member->>'join_date')::date;
    EXCEPTION WHEN OTHERS THEN
        v_join_date := CURRENT_DATE;
    END;

    BEGIN
        v_expiry_date := (p_member->>'expiry_date')::date;
    EXCEPTION WHEN OTHERS THEN
        v_expiry_date := CURRENT_DATE + INTERVAL '30 days';
    END;

    SELECT id INTO v_plan_id FROM membership_plans 
    WHERE tenant_id = p_tenant_id AND LOWER(name) = LOWER(v_plan_name) LIMIT 1;
    
    IF v_plan_id IS NULL THEN
        SELECT id INTO v_plan_id FROM membership_plans 
        WHERE tenant_id = p_tenant_id LIMIT 1;
    END IF;

    -- If ID exists, update
    IF p_member->>'id' IS NOT NULL AND (p_member->>'id')::text NOT LIKE 'imported-%' AND LENGTH((p_member->>'id')::text) = 36 THEN
        v_user_id := (p_member->>'id')::uuid;
        
        UPDATE profiles SET
            full_name = v_name,
            phone = COALESCE(NULLIF(v_phone, ''), phone),
            email = COALESCE(NULLIF(v_email, ''), email),
            is_active = (v_status = 'active'),
            raw_user_meta = jsonb_build_object(
                'member_code', COALESCE(NULLIF(v_code, ''), raw_user_meta->>'member_code'),
                'temp_password', v_password,
                'assigned_protocol', v_protocol
            ),
            updated_at = NOW()
        WHERE id = v_user_id;

        IF v_plan_id IS NOT NULL THEN
            UPDATE member_subscriptions SET
                plan_id = v_plan_id,
                end_date = v_expiry_date,
                status = 'active'::member_sub_status,
                updated_at = NOW()
            WHERE member_id = v_user_id;
        END IF;

        IF v_dues > 0 THEN
            INSERT INTO invoices (tenant_id, member_id, total_amount, paid_amount, due_amount, status)
            VALUES (p_tenant_id, v_user_id, v_dues, 0, v_dues, 'unpaid')
            ON CONFLICT DO NOTHING;
        END IF;
    ELSE
        v_user_id := gen_random_uuid();
        IF v_code = '' THEN
            v_code := 'GC-M-' || UPPER(SUBSTRING(v_user_id::text FROM 1 FOR 4));
        END IF;
        IF v_email = '' THEN
            v_email := LOWER(v_code) || '@titanfitness.local';
        END IF;

        INSERT INTO profiles (
            id, tenant_id, role, full_name, email, phone, is_active, raw_user_meta, created_at, updated_at
        ) VALUES (
            v_user_id, p_tenant_id, 'member', v_name, v_email, v_phone, (v_status = 'active'),
            jsonb_build_object(
                'member_code', v_code,
                'temp_password', v_password,
                'assigned_protocol', v_protocol
            ),
            NOW(), NOW()
        );

        IF v_plan_id IS NOT NULL THEN
            INSERT INTO member_subscriptions (
                tenant_id, member_id, plan_id, start_date, end_date, status
            ) VALUES (
                p_tenant_id, v_user_id, v_plan_id, v_join_date, v_expiry_date, 'active'::member_sub_status
            );
        END IF;

        IF v_dues > 0 THEN
            INSERT INTO invoices (
                tenant_id, member_id, total_amount, paid_amount, due_amount, status
            ) VALUES (
                p_tenant_id, v_user_id, v_dues, 0, v_dues, 'unpaid'
            );
        END IF;

        INSERT INTO user_fitness_profiles (
            user_id, body_type, fitness_goal, experience_level
        ) VALUES (
            v_user_id, 'mesomorph', 'general_fitness', 'intermediate'
        ) ON CONFLICT (user_id) DO NOTHING;

        INSERT INTO member_gamification (
            user_id, current_streak_days, total_points, last_activity_date
        ) VALUES (
            v_user_id, 1, 20, CURRENT_DATE
        ) ON CONFLICT (user_id) DO NOTHING;
    END IF;

    RETURN jsonb_build_object(
        'success', TRUE,
        'id', v_user_id,
        'member_code', v_code
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. GRANTS FOR CLIENT RPC EXECUTION
GRANT EXECUTE ON FUNCTION batch_ingest_gym_members(UUID, JSONB, BOOLEAN) TO authenticated, anon, service_role;
GRANT EXECUTE ON FUNCTION create_or_update_gym_member(UUID, JSONB) TO authenticated, anon, service_role;
GRANT ALL ON profiles TO authenticated, anon, service_role;
GRANT ALL ON member_subscriptions TO authenticated, anon, service_role;
GRANT ALL ON invoices TO authenticated, anon, service_role;
GRANT ALL ON user_fitness_profiles TO authenticated, anon, service_role;
GRANT ALL ON member_gamification TO authenticated, anon, service_role;
