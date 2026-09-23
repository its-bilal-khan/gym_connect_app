-- ======================================================================================
-- GYMCONNECT ENTERPRISE SAAS - MEMBER PORTAL & STORE SEED DATA SCRIPT
-- 100% Realistic Data: Authentic supplement brands, Pakistani pricing, real transformations
-- Idempotent & Safe: Resolves auth.users foreign key constraints dynamically
-- ======================================================================================

-- 1. SEED DEFAULT TENANT (IF NOT EXISTS)
INSERT INTO tenants (id, name, slug, contact_email, contact_phone, address, city, country, branding, is_active)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Titan Fitness Club',
    'titan-fitness',
    'info@titanfitness.pk',
    '+92 300 1234567',
    'Plot 14-B, Sector C, Commercial Phase 5, DHA',
    'Lahore',
    'Pakistan',
    '{
        "primary_color": "#CCFF00",
        "surface_color": "#18181B",
        "background_color": "#09090B",
        "tagline": "Peak Human Performance & AI Training"
    }'::jsonb,
    TRUE
)
ON CONFLICT (id) DO UPDATE 
SET name = EXCLUDED.name, branding = EXCLUDED.branding;

-- 2. SEED MEMBERSHIP PLANS
INSERT INTO membership_plans (id, tenant_id, name, description, duration_days, price, signup_fee, has_classes, has_trainer_access, is_active)
VALUES 
(
    '00000000-0000-0000-0000-000000000021',
    '00000000-0000-0000-0000-000000000001',
    'Monthly Pro Pass',
    'Full access to gym floor, cardio zone, locker room, and AI workout tracker.',
    30,
    5000.00,
    1000.00,
    FALSE,
    TRUE,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000022',
    '00000000-0000-0000-0000-000000000001',
    'Annual VIP Membership',
    'All-access pass with steam bath, unlimited biometric gate unlock, and guest passes.',
    365,
    48000.00,
    0.00,
    TRUE,
    TRUE,
    TRUE
)
ON CONFLICT (id) DO UPDATE 
SET name = EXCLUDED.name, price = EXCLUDED.price, duration_days = EXCLUDED.duration_days;

-- 3. SEED AUTHENTIC IN-GYM STORE PRODUCTS
DELETE FROM products WHERE tenant_id = '00000000-0000-0000-0000-000000000001';

INSERT INTO products (id, tenant_id, barcode, sku, name, category, description, cost_price, selling_price, stock_quantity, is_active)
VALUES
(
    '00000000-0000-0000-0000-000000000031',
    '00000000-0000-0000-0000-000000000001',
    '748927028669',
    'ON-WHEY-2KG-CHOC',
    'Optimum Nutrition Gold Standard 100% Whey (2.27 KG)',
    'Supplements',
    '24g Whey protein per serving, 5.5g BCAAs, Double Rich Chocolate flavor.',
    14500.00,
    18500.00,
    25,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000032',
    '00000000-0000-0000-0000-000000000001',
    '631656708523',
    'MT-NITRO-RIPPED',
    'MuscleTech Nitro-Tech Ripped (1.81 KG - French Vanilla)',
    'Supplements',
    '30g Whey peptides & isolate with CLA, L-Carnitine, and green tea extract for fat loss.',
    12800.00,
    16200.00,
    18,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000033',
    '00000000-0000-0000-0000-000000000001',
    '842595100012',
    'CELL-C4-ORIG-30',
    'Cellucor C4 Original Pre-Workout (Icy Blue Razz - 30 Serv)',
    'Supplements',
    'Explosive energy with 150mg caffeine, CarnoSyn Beta-Alanine, and Creatine Nitrate.',
    5200.00,
    6800.00,
    35,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000034',
    '00000000-0000-0000-0000-000000000001',
    '748927052923',
    'ON-CREATINE-300G',
    'Optimum Nutrition Micronized Creatine Monohydrate (300g)',
    'Supplements',
    '5g pure micronized creatine per serving for peak strength, power, and muscle volume.',
    4200.00,
    5500.00,
    40,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000035',
    '00000000-0000-0000-0000-000000000001',
    '842595101115',
    'XTEND-BCAA-MANGO',
    'Scivation Xtend BCAA 7G Electrolytes (Mango Madness)',
    'Drinks',
    '7g of BCAAs in 2:1:1 ratio with hydrating electrolytes to support intra-workout endurance.',
    4800.00,
    6200.00,
    22,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000036',
    '00000000-0000-0000-0000-000000000001',
    '100000000001',
    'BAR-SHAKE-CHOCO',
    'Juice Bar Fresh Whey Shake (Double Scoop - Choco Blast)',
    'Juice Bar',
    'Freshly blended cold protein shake with 24g whey isolate, crushed ice, and almond milk.',
    280.00,
    450.00,
    500,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000037',
    '00000000-0000-0000-0000-000000000001',
    '890123456789',
    'SNACK-PROT-BAR',
    'Raw Crunch Protein Bar (Peanut Butter Crisp - 20g Protein)',
    'Snacks',
    'Delicious zero-guilt snack with 20g whey/soy protein, 3g fiber, and low sugar.',
    180.00,
    300.00,
    150,
    TRUE
),
(
    '00000000-0000-0000-0000-000000000038',
    '00000000-0000-0000-0000-000000000001',
    '850012345001',
    'GEAR-STRAPS-MIL',
    'GymReapers Neoprene Padded Weightlifting Straps (Pair)',
    'Gear',
    'Heavy-duty industrial cotton lifting straps with soft neoprene padding for heavy deadlifts.',
    1900.00,
    2800.00,
    30,
    TRUE
);

-- 4. SEED MEMBER DATA (DYNAMICALLY RESOLVING AUTH.USERS TO AVOID FOREIGN KEY ERRORS)
DO $$ 
DECLARE
    sample_member_id UUID;
BEGIN
    -- Step A: Check if a user already exists in auth.users
    SELECT id INTO sample_member_id FROM auth.users WHERE email = 'member@titan.com' LIMIT 1;
    
    IF sample_member_id IS NULL THEN
        SELECT id INTO sample_member_id FROM auth.users ORDER BY created_at ASC LIMIT 1;
    END IF;

    -- Step B: If absolutely no user exists in auth.users, create one safely
    IF sample_member_id IS NULL THEN
        sample_member_id := '00000000-0000-0000-0000-000000000002';
        
        INSERT INTO auth.users (
            id,
            instance_id,
            email,
            encrypted_password,
            email_confirmed_at,
            raw_app_meta_data,
            raw_user_meta_data,
            created_at,
            updated_at,
            role,
            aud
        )
        VALUES (
            sample_member_id,
            '00000000-0000-0000-0000-000000000000',
            'member@titan.com',
            crypt('MemberPass123!', gen_salt('bf')),
            NOW(),
            '{"provider":"email","providers":["email"]}'::jsonb,
            '{"full_name":"Ahmad Raza","role":"member","tenant_id":"00000000-0000-0000-0000-000000000001"}'::jsonb,
            NOW(),
            NOW(),
            'authenticated',
            'authenticated'
        )
        ON CONFLICT (id) DO NOTHING;

        SELECT id INTO sample_member_id FROM auth.users WHERE email = 'member@titan.com' LIMIT 1;
    END IF;

    -- Step C: Ensure profiles table has this member associated with the tenant
    IF sample_member_id IS NOT NULL THEN
        INSERT INTO public.profiles (id, tenant_id, role, full_name, email, is_active)
        VALUES (sample_member_id, '00000000-0000-0000-0000-000000000001', 'member', 'Ahmad Raza', 'member@titan.com', TRUE)
        ON CONFLICT (id) DO UPDATE SET tenant_id = '00000000-0000-0000-0000-000000000001';

        -- 4.1 Seed Member Transformation Posts
        DELETE FROM transformation_posts WHERE tenant_id = '00000000-0000-0000-0000-000000000001';
        
        INSERT INTO transformation_posts (id, tenant_id, member_id, title, story, stats, likes_count, is_approved)
        VALUES 
        (
            '00000000-0000-0000-0000-000000000041',
            '00000000-0000-0000-0000-000000000001',
            sample_member_id,
            'Ahmad''s 90-Day Transformation',
            'GymConnect ke 90-day smart calendar aur calorie engine ne meri life badal di! Har roz ka routine auto-load hota tha aur sets log karte hue rest timer ne discipline banaye rakha.',
            '{
                "member_name": "Ahmad Raza",
                "weight_loss": "-14.5 KG",
                "body_fat": "28% ➔ 15%",
                "program": "SHRED D-90",
                "days_active": 78
            }'::jsonb,
            143,
            TRUE
        ),
        (
            '00000000-0000-0000-0000-000000000042',
            '00000000-0000-0000-0000-000000000001',
            sample_member_id,
            'Danial''s Lean Muscle Bulk',
            'Mesomorph protocol aur AI progressive overload ki madad se deadlift 120kg se 180kg tak pohanchi baghair injury ke. Calorie tracking ne target protein hit karna asaan bana diya.',
            '{
                "member_name": "Danial Khan",
                "muscle_gain": "+6.2 KG",
                "body_fat": "12% ➔ 13%",
                "program": "HYPERTROPHY BULK",
                "days_active": 90
            }'::jsonb,
            98,
            TRUE
        );

        -- 4.2 Seed Verified Gym Reviews
        DELETE FROM gym_reviews WHERE tenant_id = '00000000-0000-0000-0000-000000000001';
        
        INSERT INTO gym_reviews (tenant_id, member_id, rating, review_title, review_text, is_verified_member)
        VALUES 
        (
            '00000000-0000-0000-0000-000000000001',
            sample_member_id,
            5,
            'Top-Tier Facility & Cleanliness',
            'Hammer Strength machines aur air conditioning dono peak standards par hain. Pedometer aur mobile gate pass se check-in karna bilkul seamless hai.',
            TRUE
        )
        ON CONFLICT (tenant_id, member_id) DO NOTHING;

        -- 4.3 Seed Active Subscription
        DELETE FROM member_subscriptions WHERE tenant_id = '00000000-0000-0000-0000-000000000001' AND member_id = sample_member_id;
        
        INSERT INTO member_subscriptions (tenant_id, member_id, plan_id, start_date, end_date, status, auto_renew)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            sample_member_id,
            '00000000-0000-0000-0000-000000000022',
            CURRENT_DATE - INTERVAL '60 days',
            CURRENT_DATE + INTERVAL '305 days',
            'active',
            TRUE
        );

        -- 4.4 Seed Pending Monthly Dues Invoice
        DELETE FROM invoices WHERE tenant_id = '00000000-0000-0000-0000-000000000001' AND member_id = sample_member_id AND status = 'unpaid';
        
        INSERT INTO invoices (tenant_id, invoice_number, member_id, customer_name, total_amount, due_amount, status)
        VALUES (
            '00000000-0000-0000-0000-000000000001',
            'INV-2026-0914',
            sample_member_id,
            'Ahmad Raza',
            5000.00,
            5000.00,
            'unpaid'
        );
    END IF;
END $$;
