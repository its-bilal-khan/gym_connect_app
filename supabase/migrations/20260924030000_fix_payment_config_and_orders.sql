-- ======================================================================================
-- MIGRATION: 20260924030000_fix_payment_config_and_orders.sql
-- Description: 1. Allow gym owners and staff to UPDATE tenant payment gateway configuration.
--              2. Seed/ensure default tenant has manual payments enabled with copyable details.
--              3. Verify store_orders payment_receipt_url and delivery fields.
-- ======================================================================================

-- 1. FIX TENANTS UPDATE RLS POLICY FOR GYM OWNERS & STAFF
DROP POLICY IF EXISTS "Owners manage their gym profile" ON tenants;
CREATE POLICY "Owners manage their gym profile" ON tenants
FOR ALL USING (
    auth_is_super_admin() OR
    auth_current_role() = 'gym_owner' OR
    auth_current_role() = 'staff' OR
    id = auth_current_tenant_id() OR
    auth_current_tenant_id() IS NULL
)
WITH CHECK (
    auth_is_super_admin() OR
    auth_current_role() = 'gym_owner' OR
    auth_current_role() = 'staff' OR
    id = auth_current_tenant_id() OR
    auth_current_tenant_id() IS NULL
);

-- 2. ENSURE TENANTS COLUMNS EXIST WITH PROPER DEFAULTS
ALTER TABLE IF EXISTS tenants
ADD COLUMN IF NOT EXISTS is_payfast_enabled BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS is_manual_payment_enabled BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS manual_easypaisa_number TEXT DEFAULT '0300-1234567 (Titan Fitness)',
ADD COLUMN IF NOT EXISTS manual_bank_details TEXT DEFAULT 'Meezan Bank | IBAN: PK64MEZN0001234567890123 | Title: Titan Fitness Club';

-- 3. ACTIVATE MANUAL PAYMENT FOR DEFAULT SEED TENANT
UPDATE tenants
SET 
    is_manual_payment_enabled = TRUE,
    manual_easypaisa_number = COALESCE(NULLIF(manual_easypaisa_number, ''), '0300-1234567 (Titan Fitness)'),
    manual_bank_details = COALESCE(NULLIF(manual_bank_details, ''), 'Meezan Bank | IBAN: PK64MEZN0001234567890123 | Title: Titan Fitness Club')
WHERE id = '00000000-0000-0000-0000-000000000001' OR is_active = TRUE;

-- 4. ENSURE STORE_ORDERS COLUMNS EXIST FOR RECEIPT AND DELIVERY
ALTER TABLE IF EXISTS store_orders
ADD COLUMN IF NOT EXISTS payment_receipt_url TEXT,
ADD COLUMN IF NOT EXISTS delivery_address TEXT,
ADD COLUMN IF NOT EXISTS estimated_ready_date VARCHAR(50),
ADD COLUMN IF NOT EXISTS estimated_ready_time VARCHAR(50);

-- 5. ENSURE PAYMENT RECEIPTS BUCKET IS FULLY ACCESSIBLE
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'payment_receipts',
    'payment_receipts',
    TRUE,
    10485760, -- 10 MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET public = TRUE, file_size_limit = 10485760;

DROP POLICY IF EXISTS "Anyone can read payment receipts" ON storage.objects;
CREATE POLICY "Anyone can read payment receipts"
ON storage.objects FOR SELECT
USING (bucket_id = 'payment_receipts');

DROP POLICY IF EXISTS "Authenticated users can upload payment receipts" ON storage.objects;
CREATE POLICY "Authenticated users can upload payment receipts"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'payment_receipts');

DROP POLICY IF EXISTS "Public can upload payment receipts" ON storage.objects;
CREATE POLICY "Public can upload payment receipts"
ON storage.objects FOR INSERT TO public
WITH CHECK (bucket_id = 'payment_receipts');
