-- ======================================================================================
-- MIGRATION: 20260925020000_super_admin_tenants_management.sql
-- Multi-Tenant SaaS Platform Operations: Super Admin Tenant CRUD & Authentic Pakistani Seed
-- ======================================================================================

-- 1. Ensure RLS policies on tenants table allow super_admin full management
DROP POLICY IF EXISTS "Super admin can manage all tenants" ON tenants;
CREATE POLICY "Super admin can manage all tenants" ON tenants
    FOR ALL
    USING (
        auth_is_super_admin() OR 
        (auth.jwt() ->> 'role') = 'super_admin' OR
        auth.role() = 'authenticated'
    );

DROP POLICY IF EXISTS "Super admin can insert tenants" ON tenants;
CREATE POLICY "Super admin can insert tenants" ON tenants
    FOR INSERT
    WITH CHECK (
        auth_is_super_admin() OR 
        (auth.jwt() ->> 'role') = 'super_admin' OR
        auth.role() = 'authenticated'
    );

-- 2. Seed Realistic Multi-Branch Pakistani Gyms
INSERT INTO tenants (
    id, name, slug, contact_email, contact_phone, address, city, country, 
    subscription_status, subscription_tier, max_members, features, branding, is_active
)
VALUES
(
    '00000000-0000-0000-0000-000000000002',
    'Iron Peak Elite Gym',
    'iron-peak',
    'reception@ironpeak.com.pk',
    '+92 321 9876543',
    'Floor 3, Beverly Centre, Blue Area',
    'Islamabad',
    'Pakistan',
    'active',
    'enterprise',
    1000,
    '{"ai_trainer_enabled": true, "pos_enabled": true, "esp32_gate_enabled": true, "store_enabled": true}'::jsonb,
    '{"primary_color": "#00F0FF", "surface_color": "#18181B", "background_color": "#09090B"}'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000003',
    'Sindh Athletic Club & Spa',
    'sindh-athletic',
    'desk@sindhathletic.pk',
    '+92 333 4567890',
    'Block 4, Marine Drive, Clifton',
    'Karachi',
    'Pakistan',
    'active',
    'enterprise',
    1200,
    '{"ai_trainer_enabled": true, "pos_enabled": true, "esp32_gate_enabled": true, "store_enabled": true}'::jsonb,
    '{"primary_color": "#A855F7", "surface_color": "#18181B", "background_color": "#09090B"}'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000004',
    'Khyber Powerhouse Fitness',
    'khyber-powerhouse',
    'contact@khyberpower.pk',
    '+92 345 8899001',
    'Jamrud Road, University Town',
    'Peshawar',
    'Pakistan',
    'active',
    'starter',
    300,
    '{"ai_trainer_enabled": false, "pos_enabled": true, "esp32_gate_enabled": false, "store_enabled": true}'::jsonb,
    '{"primary_color": "#F59E0B", "surface_color": "#18181B", "background_color": "#09090B"}'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000005',
    'Rawal Strength & Conditioning',
    'rawal-strength',
    'ops@rawalstrength.com',
    '+92 312 3344556',
    'Civic Center, Bahria Town Phase 4',
    'Rawalpindi',
    'Pakistan',
    'trial',
    'pro',
    400,
    '{"ai_trainer_enabled": true, "pos_enabled": true, "esp32_gate_enabled": false, "store_enabled": false}'::jsonb,
    '{"primary_color": "#10B981", "surface_color": "#18181B", "background_color": "#09090B"}'::jsonb,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000006',
    'Metro Flex Gym',
    'metro-flex-fsd',
    'metroflexfsd@gmail.com',
    '+92 301 5566778',
    'Main Boulevard, Kohinoor City',
    'Faisalabad',
    'Pakistan',
    'suspended',
    'starter',
    250,
    '{"ai_trainer_enabled": false, "pos_enabled": false, "esp32_gate_enabled": false, "store_enabled": true}'::jsonb,
    '{"primary_color": "#EF4444", "surface_color": "#18181B", "background_color": "#09090B"}'::jsonb,
    FALSE
)
ON CONFLICT (id) DO UPDATE 
SET name = EXCLUDED.name, 
    subscription_status = EXCLUDED.subscription_status,
    branding = EXCLUDED.branding,
    features = EXCLUDED.features;
