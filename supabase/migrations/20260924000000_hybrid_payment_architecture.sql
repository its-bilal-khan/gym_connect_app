-- ======================================================================================
-- MIGRATION: 20260924000000_hybrid_payment_architecture.sql
-- Description: Hybrid Payment Architecture: Manual Screenshot (Proof-of-Payment) 
--              and PayFast Gateway toggles for Super Admin & Gym Owners.
-- ======================================================================================

-- --------------------------------------------------------------------------------------
-- 1. ALTER TENANTS TABLE (Payment Gateway & Manual Transfer Configuration)
-- --------------------------------------------------------------------------------------
ALTER TABLE IF EXISTS tenants
ADD COLUMN IF NOT EXISTS is_payfast_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_manual_payment_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS manual_easypaisa_number TEXT,
ADD COLUMN IF NOT EXISTS manual_bank_details TEXT;

COMMENT ON COLUMN tenants.is_payfast_enabled IS 'Controls PayFast checkout gateway availability for this gym';
COMMENT ON COLUMN tenants.is_manual_payment_enabled IS 'Controls Manual Proof-of-Payment transfer method for this gym';
COMMENT ON COLUMN tenants.manual_easypaisa_number IS 'EasyPaisa account number for manual payment transfer';
COMMENT ON COLUMN tenants.manual_bank_details IS 'Formatted bank details (Bank name, IBAN, Title) for manual transfer';

-- --------------------------------------------------------------------------------------
-- 2. CREATE OR ALTER PAYMENTS TABLE
-- --------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES tenants(id) ON DELETE CASCADE,
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
    receipt_image_url TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    payment_method VARCHAR(50) DEFAULT 'manual_transfer',
    invoice_id UUID REFERENCES invoices(id) ON DELETE SET NULL,
    member_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    transaction_reference VARCHAR(255),
    payment_gateway_response JSONB DEFAULT '{}'::jsonb,
    collected_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- In case table already existed from earlier schema version, ensure columns exist
ALTER TABLE payments
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS receipt_image_url TEXT,
ADD COLUMN IF NOT EXISTS status VARCHAR(20) NOT NULL DEFAULT 'pending';

-- Synchronize user_id with member_id for backwards compatibility if member_id exists
DO $$ BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'payments' AND column_name = 'member_id'
    ) THEN
        UPDATE payments SET user_id = member_id WHERE user_id IS NULL AND member_id IS NOT NULL;
    END IF;
END $$;

-- --------------------------------------------------------------------------------------
-- 3. SUPABASE STORAGE BUCKET: payment_receipts
-- --------------------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'payment_receipts',
    'payment_receipts',
    TRUE,
    5242880, -- 5 MB max
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET
    public = TRUE,
    file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];

-- Storage RLS Policies
DROP POLICY IF EXISTS "Authenticated users can upload payment receipts" ON storage.objects;
CREATE POLICY "Authenticated users can upload payment receipts"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'payment_receipts');

DROP POLICY IF EXISTS "Users and gym staff can view payment receipts" ON storage.objects;
CREATE POLICY "Users and gym staff can view payment receipts"
ON storage.objects FOR SELECT
USING (bucket_id = 'payment_receipts');

-- --------------------------------------------------------------------------------------
-- 4. ROW LEVEL SECURITY (RLS) FOR PAYMENTS TABLE
-- --------------------------------------------------------------------------------------
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own payments" ON payments;
CREATE POLICY "Users can view own payments" ON payments
FOR SELECT USING (
    user_id = auth.uid() OR
    member_id = auth.uid() OR
    auth_is_super_admin() OR
    (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
);

DROP POLICY IF EXISTS "Users can insert own payments" ON payments;
CREATE POLICY "Users can insert own payments" ON payments
FOR INSERT WITH CHECK (
    user_id = auth.uid() OR
    member_id = auth.uid() OR
    auth_is_super_admin() OR
    (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
);

DROP POLICY IF EXISTS "Owners and staff manage tenant payments" ON payments;
CREATE POLICY "Owners and staff manage tenant payments" ON payments
FOR ALL USING (
    auth_is_super_admin() OR
    (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
);

-- --------------------------------------------------------------------------------------
-- 5. TRIGGER: AUTO-ACTIVATE MEMBER SUBSCRIPTION ON PAYMENT APPROVAL
-- --------------------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_activate_subscription_on_payment_approval()
RETURNS TRIGGER AS $$
DECLARE
    target_user_id UUID;
    target_tenant_id UUID;
BEGIN
    target_user_id := COALESCE(NEW.user_id, NEW.member_id);
    target_tenant_id := NEW.tenant_id;

    -- Only proceed if status transitions to 'approved'
    IF NEW.status = 'approved' AND (OLD.status IS DISTINCT FROM 'approved') AND target_user_id IS NOT NULL THEN
        -- Check if an existing subscription exists for the member
        IF EXISTS (SELECT 1 FROM member_subscriptions WHERE member_id = target_user_id) THEN
            UPDATE member_subscriptions
            SET status = 'active',
                end_date = GREATEST(end_date, CURRENT_DATE) + INTERVAL '30 days',
                updated_at = NOW()
            WHERE member_id = target_user_id;
        ELSE
            -- Provision a 30-day active subscription with the gym's primary active plan
            INSERT INTO member_subscriptions (
                tenant_id,
                member_id,
                plan_id,
                start_date,
                end_date,
                status
            )
            SELECT
                target_tenant_id,
                target_user_id,
                id,
                CURRENT_DATE,
                CURRENT_DATE + INTERVAL '30 days',
                'active'
            FROM membership_plans
            WHERE tenant_id = target_tenant_id AND is_active = TRUE
            ORDER BY price ASC
            LIMIT 1;
        END IF;

        -- Also mark any pending invoice for this member as paid if invoice_id exists
        IF NEW.invoice_id IS NOT NULL THEN
            UPDATE invoices
            SET status = 'paid',
                paid_amount = NEW.amount,
                due_amount = 0.00,
                updated_at = NOW()
            WHERE id = NEW.invoice_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_payment_approval_activate_sub ON payments;
CREATE TRIGGER trg_payment_approval_activate_sub
AFTER UPDATE OF status ON payments
FOR EACH ROW
WHEN (NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved')
EXECUTE FUNCTION trg_activate_subscription_on_payment_approval();
