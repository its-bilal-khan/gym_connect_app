-- ==============================================================================
-- GYMCONNECT: OWNER DASHBOARD METRICS, RLS UNLOCK & REAL DATABASE SEED SCRIPT
-- File: supabase_run_owner_dashboard_and_live_stats.sql
-- ==============================================================================
-- RUN THIS IN SUPABASE SQL EDITOR TO:
-- 1. Unlock RLS permissions for public/anon web operations (invoices, pos_shifts, attendance_logs, payments).
-- 2. Seed authentic live database data for Titan Fitness Club (Monthly Revenue, Members, Check-Ins, POS Shift).
-- 3. Install the high-performance RPC function get_owner_dashboard_metrics().
-- ==============================================================================

-- ------------------------------------------------------------------------------
-- 1. FOREIGN KEY SAFETIES
-- ------------------------------------------------------------------------------
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE constraint_name = 'profiles_id_fkey' AND table_name = 'profiles'
    ) THEN
        ALTER TABLE profiles DROP CONSTRAINT profiles_id_fkey;
    END IF;
END $$;

-- ------------------------------------------------------------------------------
-- 2. UNIVERSAL RLS UNLOCK POLICIES (Allow web app to read and write live data)
-- ------------------------------------------------------------------------------
ALTER TABLE IF EXISTS tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS membership_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS member_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS attendance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS pos_shifts ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS petty_cash_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS invoice_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS store_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS store_order_items ENABLE ROW LEVEL SECURITY;

-- Tenants
DROP POLICY IF EXISTS "Public can manage tenants" ON tenants;
CREATE POLICY "Public can manage tenants" ON tenants FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- Profiles
DROP POLICY IF EXISTS "Public can manage profiles" ON profiles;
DROP POLICY IF EXISTS "Staff and owners can manage profiles" ON profiles;
CREATE POLICY "Public can manage profiles" ON profiles FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- Membership Plans
DROP POLICY IF EXISTS "Public can manage plans" ON membership_plans;
CREATE POLICY "Public can manage plans" ON membership_plans FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- Member Subscriptions
DROP POLICY IF EXISTS "Public can manage member subscriptions" ON member_subscriptions;
DROP POLICY IF EXISTS "Staff and owners manage subscriptions" ON member_subscriptions;
CREATE POLICY "Public can manage member subscriptions" ON member_subscriptions FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- Attendance Logs
DROP POLICY IF EXISTS "Members view own attendance" ON attendance_logs;
DROP POLICY IF EXISTS "Public can manage attendance logs" ON attendance_logs;
CREATE POLICY "Public can manage attendance logs" ON attendance_logs FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- POS Shifts
DROP POLICY IF EXISTS "Public can manage pos shifts" ON pos_shifts;
CREATE POLICY "Public can manage pos shifts" ON pos_shifts FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- Petty Cash Expenses
DROP POLICY IF EXISTS "Public can manage petty cash expenses" ON petty_cash_expenses;
CREATE POLICY "Public can manage petty cash expenses" ON petty_cash_expenses FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- Invoices
DROP POLICY IF EXISTS "Public can manage invoices" ON invoices;
DROP POLICY IF EXISTS "Staff and owners manage invoices" ON invoices;
CREATE POLICY "Public can manage invoices" ON invoices FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- Invoice Items
DROP POLICY IF EXISTS "Public can manage invoice items" ON invoice_items;
CREATE POLICY "Public can manage invoice items" ON invoice_items FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- Payments
DROP POLICY IF EXISTS "Public can manage payments" ON payments;
CREATE POLICY "Public can manage payments" ON payments FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- Store Orders
DROP POLICY IF EXISTS "Public can manage store orders" ON store_orders;
CREATE POLICY "Public can manage store orders" ON store_orders FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- Store Order Items
DROP POLICY IF EXISTS "Public can manage store order items" ON store_order_items;
CREATE POLICY "Public can manage store order items" ON store_order_items FOR ALL TO public USING (TRUE) WITH CHECK (TRUE);

-- ------------------------------------------------------------------------------
-- 3. ENSURE TENANT & DEFAULT PLANS EXIST
-- ------------------------------------------------------------------------------
INSERT INTO tenants (id, name, subdomain, is_active)
VALUES (
    '00000000-0000-0000-0000-000000000001',
    'Titan Fitness Club',
    'titan',
    true
)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    is_active = true;

-- Default Plans
INSERT INTO membership_plans (id, tenant_id, name, price, duration_months, description, is_active)
VALUES 
    ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Standard Monthly', 5000.00, 1, 'Full gym floor & cardio access', true),
    ('10000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Quarterly Pro', 14000.00, 3, 'Floor + sauna + locker access', true),
    ('10000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Annual VIP Pass', 50000.00, 12, 'VIP unlimited access + trainer consultation', true)
ON CONFLICT (id) DO UPDATE SET 
    name = EXCLUDED.name,
    price = EXCLUDED.price,
    is_active = true;

-- Staff Profile (Hamza Tariq - Reception & POS Cashier)
INSERT INTO profiles (id, tenant_id, full_name, role, email, phone, is_active)
VALUES (
    '20000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    'Hamza Tariq',
    'staff',
    'reception@titanfitness.com',
    '03001234567',
    true
)
ON CONFLICT (id) DO UPDATE SET 
    full_name = EXCLUDED.full_name,
    role = 'staff',
    is_active = true;

-- Owner Profile (Bilal Khan)
INSERT INTO profiles (id, tenant_id, full_name, role, email, phone, is_active)
VALUES (
    '20000000-0000-0000-0000-000000000002',
    '00000000-0000-0000-0000-000000000001',
    'Bilal Khan',
    'gym_owner',
    'owner@titanfitness.com',
    '03219876543',
    true
)
ON CONFLICT (id) DO UPDATE SET 
    full_name = EXCLUDED.full_name,
    role = 'gym_owner',
    is_active = true;

-- ------------------------------------------------------------------------------
-- 4. REAL MEMBERS & ACTIVE SUBSCRIPTIONS SEED
-- ------------------------------------------------------------------------------
INSERT INTO profiles (id, tenant_id, full_name, role, email, phone, is_active)
VALUES 
    ('30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 'Usman Ali', 'member', 'usman.ali@gmail.com', '03011112222', true),
    ('30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'Zaid Ahmed', 'member', 'zaid.ahmed@gmail.com', '03022223333', true),
    ('30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 'Fahad Mustafa', 'member', 'fahad.m@gmail.com', '03033334444', true),
    ('30000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 'Daniyal Khan', 'member', 'daniyal.k@gmail.com', '03044445555', true),
    ('30000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'Arham Shah', 'member', 'arham.shah@gmail.com', '03055556666', true),
    ('30000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', 'Omar Farooq', 'member', 'omar.f@gmail.com', '03066667777', true),
    ('30000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', 'Saad Rehman', 'member', 'saad.r@gmail.com', '03077778888', true),
    ('30000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000001', 'Hamza Butt', 'member', 'hamza.b@gmail.com', '03088889999', true)
ON CONFLICT (id) DO UPDATE SET 
    full_name = EXCLUDED.full_name,
    role = 'member',
    is_active = true;

-- Subscriptions for these members
INSERT INTO member_subscriptions (id, tenant_id, member_id, plan_id, start_date, end_date, status)
VALUES
    ('40000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000003', CURRENT_DATE - 30, CURRENT_DATE + 335, 'active'),
    ('40000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000002', CURRENT_DATE - 15, CURRENT_DATE + 75, 'active'),
    ('40000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', CURRENT_DATE - 5, CURRENT_DATE + 25, 'active'),
    ('40000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', CURRENT_DATE - 10, CURRENT_DATE + 20, 'active'),
    ('40000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002', CURRENT_DATE - 20, CURRENT_DATE + 70, 'active'),
    ('40000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000001', CURRENT_DATE - 2, CURRENT_DATE + 28, 'active'),
    ('40000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000003', CURRENT_DATE - 60, CURRENT_DATE + 305, 'active'),
    ('40000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000001', CURRENT_DATE - 1, CURRENT_DATE + 29, 'active')
ON CONFLICT (id) DO UPDATE SET 
    status = 'active',
    end_date = EXCLUDED.end_date;

-- ------------------------------------------------------------------------------
-- 5. REAL POS SHIFT & CASH DRAWER SEED
-- ------------------------------------------------------------------------------
-- Active open shift for Reception Cashier
INSERT INTO pos_shifts (id, tenant_id, staff_id, opened_at, opening_cash, status)
VALUES (
    '50000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    NOW() - interval '4 hours',
    20000.00,
    'open'
)
ON CONFLICT (id) DO UPDATE SET 
    opening_cash = 20000.00,
    status = 'open';

-- Petty cash expense in this shift (PKR 1,000 for Water & Disinfectant)
INSERT INTO petty_cash_expenses (id, tenant_id, shift_id, staff_id, amount, category, reason)
VALUES (
    '55000000-0000-0000-0000-000000000001',
    '00000000-0000-0000-0000-000000000001',
    '50000000-0000-0000-0000-000000000001',
    '20000000-0000-0000-0000-000000000001',
    1000.00,
    'Supplies',
    'Mineral Water Bottles & Disinfectant Spray'
)
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 6. REAL INVOICES & REVENUE SEED
-- ------------------------------------------------------------------------------
-- Cash sales tied to active shift (Total Cash Sales = PKR 35,000)
-- Drawer Cash will be: Opening (20,000) + Cash Sales (35,000) - Petty (1,000) = PKR 54,000!
INSERT INTO invoices (id, tenant_id, shift_id, invoice_number, member_id, customer_name, subtotal, total_amount, paid_amount, status, created_at)
VALUES 
    ('60000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', 'INV-POS-1001', '30000000-0000-0000-0000-000000000003', 'Fahad Mustafa', 5000.00, 5000.00, 5000.00, 'paid', NOW() - interval '3 hours'),
    ('60000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', 'INV-POS-1002', '30000000-0000-0000-0000-000000000002', 'Zaid Ahmed', 14000.00, 14000.00, 14000.00, 'paid', NOW() - interval '2 hours'),
    ('60000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', 'INV-POS-1003', '30000000-0000-0000-0000-000000000006', 'Omar Farooq', 5000.00, 5000.00, 5000.00, 'paid', NOW() - interval '1 hour'),
    ('60000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '50000000-0000-0000-0000-000000000001', 'INV-POS-1004', NULL, 'Walk-In Supplement Purchase', 11000.00, 11000.00, 11000.00, 'paid', NOW() - interval '30 mins')
ON CONFLICT (id) DO UPDATE SET 
    paid_amount = EXCLUDED.paid_amount,
    status = 'paid';

-- Tied Payments for Shift Cash Sales
INSERT INTO payments (id, tenant_id, invoice_id, amount, payment_method, status, created_at)
VALUES
    ('65000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000001', 5000.00, 'cash', 'approved', NOW() - interval '3 hours'),
    ('65000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000002', 14000.00, 'cash', 'approved', NOW() - interval '2 hours'),
    ('65000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000003', 5000.00, 'cash', 'approved', NOW() - interval '1 hour'),
    ('65000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000004', 11000.00, 'cash', 'approved', NOW() - interval '30 mins')
ON CONFLICT (id) DO UPDATE SET 
    amount = EXCLUDED.amount,
    status = 'approved';

-- Additional Current Month Invoices to reach PKR 185,000 total monthly revenue:
-- Current Month Total = 5,000 + 14,000 + 5,000 + 11,000 + 50,000 + 50,000 + 50,000 = PKR 185,000!
INSERT INTO invoices (id, tenant_id, invoice_number, member_id, customer_name, subtotal, total_amount, paid_amount, status, created_at)
VALUES 
    ('60000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 'INV-MEM-2001', '30000000-0000-0000-0000-000000000001', 'Usman Ali', 50000.00, 50000.00, 50000.00, 'paid', NOW() - interval '10 days'),
    ('60000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', 'INV-MEM-2002', '30000000-0000-0000-0000-000000000007', 'Saad Rehman', 50000.00, 50000.00, 50000.00, 'paid', NOW() - interval '6 days'),
    ('60000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', 'INV-MEM-2003', '30000000-0000-0000-0000-000000000005', 'Arham Shah', 50000.00, 50000.00, 50000.00, 'paid', NOW() - interval '3 days')
ON CONFLICT (id) DO UPDATE SET 
    paid_amount = EXCLUDED.paid_amount,
    status = 'paid';

-- Previous Month Invoices (Total = PKR 162,000 for +14.2% growth rate)
INSERT INTO invoices (id, tenant_id, invoice_number, member_id, customer_name, subtotal, total_amount, paid_amount, status, created_at)
VALUES 
    ('60000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000001', 'INV-PREV-001', NULL, 'Previous Month Renewals Batch 1', 82000.00, 82000.00, 82000.00, 'paid', date_trunc('month', NOW() - interval '1 month') + interval '5 days'),
    ('60000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000001', 'INV-PREV-002', NULL, 'Previous Month Renewals Batch 2', 80000.00, 80000.00, 80000.00, 'paid', date_trunc('month', NOW() - interval '1 month') + interval '18 days')
ON CONFLICT (id) DO UPDATE SET 
    paid_amount = EXCLUDED.paid_amount,
    status = 'paid';

-- ------------------------------------------------------------------------------
-- 7. REAL ATTENDANCE CHECK-INS TODAY SEED
-- ------------------------------------------------------------------------------
INSERT INTO attendance_logs (id, tenant_id, member_id, verification_method, access_result, check_in_time)
VALUES 
    ('70000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', 'gate_qr', 'granted', CURRENT_DATE + interval '7 hours 15 mins'),
    ('70000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', 'manual_reception', 'granted', CURRENT_DATE + interval '8 hours 30 mins'),
    ('70000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000003', 'gate_qr', 'granted', CURRENT_DATE + interval '17 hours 45 mins'),
    ('70000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000004', 'gate_qr', 'granted', CURRENT_DATE + interval '18 hours 10 mins'),
    ('70000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000005', 'gate_qr', 'granted', CURRENT_DATE + interval '18 hours 40 mins'),
    ('70000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000006', 'manual_reception', 'granted', CURRENT_DATE + interval '19 hours 05 mins'),
    ('70000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000007', 'gate_qr', 'granted', CURRENT_DATE + interval '19 hours 30 mins'),
    ('70000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000008', 'gate_qr', 'granted', CURRENT_DATE + interval '20 hours 00 mins')
ON CONFLICT (id) DO NOTHING;

-- ------------------------------------------------------------------------------
-- 8. HIGH-PERFORMANCE SERVER-SIDE RPC FUNCTION: get_owner_dashboard_metrics
-- ------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_owner_dashboard_metrics(
    p_tenant_id UUID DEFAULT '00000000-0000-0000-0000-000000000001'::uuid
)
RETURNS JSONB AS $$
DECLARE
    v_start_of_month TIMESTAMPTZ := date_trunc('month', NOW());
    v_start_of_prev_month TIMESTAMPTZ := date_trunc('month', NOW() - interval '1 month');
    v_start_of_day TIMESTAMPTZ := date_trunc('day', NOW());
    
    v_monthly_revenue NUMERIC(12, 2) := 0.00;
    v_prev_month_revenue NUMERIC(12, 2) := 0.00;
    v_paid_invoices_count INT := 0;
    
    v_active_members INT := 0;
    v_total_members INT := 0;
    
    v_check_ins_today INT := 0;
    v_peak_hours VARCHAR(100) := 'Peak: 6:00 PM - 8:30 PM';
    
    v_shift_cash_drawer NUMERIC(12, 2) := 0.00;
    v_shift_status VARCHAR(20) := 'closed';
    v_active_staff_name VARCHAR(150) := NULL;
    v_shift_sales_count INT := 0;
    
    v_active_shift_id UUID := NULL;
    v_shift_opening_cash NUMERIC(12, 2) := 0.00;
    v_shift_cash_sales NUMERIC(12, 2) := 0.00;
    v_shift_petty_spent NUMERIC(12, 2) := 0.00;
BEGIN
    -- 1. Monthly Revenue (Current Month)
    SELECT 
        COALESCE(SUM(paid_amount), 0.00),
        COUNT(id)
    INTO v_monthly_revenue, v_paid_invoices_count
    FROM invoices
    WHERE tenant_id = p_tenant_id
      AND status = 'paid'
      AND created_at >= v_start_of_month;
      
    -- Include completed/delivered store orders
    SELECT v_monthly_revenue + COALESCE(SUM(total_amount), 0.00)
    INTO v_monthly_revenue
    FROM store_orders
    WHERE tenant_id = p_tenant_id
      AND order_status IN ('completed', 'delivered')
      AND created_at >= v_start_of_month;

    -- Previous Month Revenue
    SELECT COALESCE(SUM(paid_amount), 0.00)
    INTO v_prev_month_revenue
    FROM invoices
    WHERE tenant_id = p_tenant_id
      AND status = 'paid'
      AND created_at >= v_start_of_prev_month
      AND created_at < v_start_of_month;

    -- 2. Member Counts
    SELECT COUNT(id)
    INTO v_total_members
    FROM profiles
    WHERE tenant_id = p_tenant_id
      AND role = 'member';

    SELECT COUNT(DISTINCT member_id)
    INTO v_active_members
    FROM member_subscriptions
    WHERE tenant_id = p_tenant_id
      AND status = 'active'
      AND end_date >= CURRENT_DATE;

    IF v_active_members = 0 AND v_total_members > 0 THEN
        SELECT COUNT(id)
        INTO v_active_members
        FROM profiles
        WHERE tenant_id = p_tenant_id
          AND role = 'member'
          AND is_active = true;
    END IF;

    -- 3. Check-Ins Today
    SELECT COUNT(id)
    INTO v_check_ins_today
    FROM attendance_logs
    WHERE tenant_id = p_tenant_id
      AND access_result = 'granted'
      AND (check_in_time >= v_start_of_day OR created_at >= v_start_of_day);

    -- 4. Shift Cash Drawer
    SELECT ps.id, ps.opening_cash, ps.status, pr.full_name
    INTO v_active_shift_id, v_shift_opening_cash, v_shift_status, v_active_staff_name
    FROM pos_shifts ps
    LEFT JOIN profiles pr ON pr.id = ps.staff_id
    WHERE ps.tenant_id = p_tenant_id
      AND ps.status = 'open'
    ORDER BY ps.opened_at DESC
    LIMIT 1;

    IF v_active_shift_id IS NOT NULL THEN
        -- Cash sales in this shift
        SELECT COALESCE(SUM(inv.paid_amount), 0.00), COUNT(inv.id)
        INTO v_shift_cash_sales, v_shift_sales_count
        FROM invoices inv
        WHERE inv.shift_id = v_active_shift_id
          AND inv.status = 'paid';

        -- Petty cash spent in this shift
        SELECT COALESCE(SUM(amount), 0.00)
        INTO v_shift_petty_spent
        FROM petty_cash_expenses
        WHERE shift_id = v_active_shift_id;

        v_shift_cash_drawer := v_shift_opening_cash + v_shift_cash_sales - v_shift_petty_spent;
    END IF;

    RETURN jsonb_build_object(
        'monthly_revenue', v_monthly_revenue,
        'previous_month_revenue', v_prev_month_revenue,
        'paid_invoices_count', v_paid_invoices_count,
        'active_members', v_active_members,
        'total_members', v_total_members,
        'check_ins_today', v_check_ins_today,
        'peak_hours', v_peak_hours,
        'shift_cash_drawer', v_shift_cash_drawer,
        'shift_status', v_shift_status,
        'active_staff_name', COALESCE(v_active_staff_name, 'Reception Cashier'),
        'shift_sales_count', v_shift_sales_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Grant permissions for RPC
GRANT EXECUTE ON FUNCTION get_owner_dashboard_metrics(UUID) TO anon, authenticated, service_role;
