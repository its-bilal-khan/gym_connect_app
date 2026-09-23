-- ======================================================================================
-- MIGRATION: 20260924010000_ecommerce_store_enhancements.sql
-- Description: E-Commerce Store Enhancements:
--              1. Product photography URLs for supplements, shakes, and gym gear.
--              2. Store orders table extensions for Pickup vs Home Delivery, Hybrid Payments,
--                 and Gym Owner Ready/Delivery Date & Time Scheduling.
-- ======================================================================================

-- --------------------------------------------------------------------------------------
-- 1. ALTER STORE_ORDERS TABLE (Fulfillment, Scheduling & Payment Proof)
-- --------------------------------------------------------------------------------------
ALTER TABLE IF EXISTS store_orders
ADD COLUMN IF NOT EXISTS fulfillment_type VARCHAR(20) DEFAULT 'pickup' CHECK (fulfillment_type IN ('pickup', 'delivery')),
ADD COLUMN IF NOT EXISTS delivery_address TEXT,
ADD COLUMN IF NOT EXISTS delivery_phone TEXT,
ADD COLUMN IF NOT EXISTS customer_name TEXT,
ADD COLUMN IF NOT EXISTS customer_phone TEXT,
ADD COLUMN IF NOT EXISTS estimated_ready_date DATE,
ADD COLUMN IF NOT EXISTS estimated_ready_time TEXT,
ADD COLUMN IF NOT EXISTS payment_method VARCHAR(50) DEFAULT 'manual_transfer',
ADD COLUMN IF NOT EXISTS payment_receipt_url TEXT,
ADD COLUMN IF NOT EXISTS payment_id UUID REFERENCES payments(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES profiles(id) ON DELETE SET NULL;

-- Allow member_id to be nullable for non-member guest orders
ALTER TABLE store_orders ALTER COLUMN member_id DROP NOT NULL;

-- Synchronize user_id and member_id
UPDATE store_orders SET user_id = member_id WHERE user_id IS NULL AND member_id IS NOT NULL;

-- --------------------------------------------------------------------------------------
-- 2. UPDATE PRODUCTS TABLE WITH AUTHENTIC HIGH-RES FITNESS PHOTOGRAPHY
-- --------------------------------------------------------------------------------------
ALTER TABLE IF EXISTS products
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- Seed authentic Unsplash supplement and fitness merchandise imagery
UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1579722821273-0f6c7d44362f?auto=format&fit=crop&w=800&q=80'
WHERE sku = 'ON-WHEY-2KG-CHOC' OR name ILIKE '%Gold Standard 100% Whey%';

UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1593095948071-474c5cc2989d?auto=format&fit=crop&w=800&q=80'
WHERE sku = 'MT-NITRO-RIPPED' OR name ILIKE '%Nitro-Tech%';

UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1546483875-ad9014c88eba?auto=format&fit=crop&w=800&q=80'
WHERE sku = 'CELL-C4-ORIG-30' OR name ILIKE '%C4 Original%';

UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1584017911766-d451b3d0e843?auto=format&fit=crop&w=800&q=80'
WHERE sku = 'ON-CREATINE-300G' OR name ILIKE '%Creatine Monohydrate%';

UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1544816155-12df9643f363?auto=format&fit=crop&w=800&q=80'
WHERE sku = 'XTEND-BCAA-MANGO' OR name ILIKE '%Xtend BCAA%';

UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=800&q=80'
WHERE sku = 'BAR-SHAKE-CHOCO' OR name ILIKE '%Fresh Whey Shake%';

UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1622484216800-4b2105e4cb31?auto=format&fit=crop&w=800&q=80'
WHERE sku = 'SNACK-PROT-BAR' OR name ILIKE '%Protein Bar%';

UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1517838277536-f5f99be501cd?auto=format&fit=crop&w=800&q=80'
WHERE sku = 'GEAR-STRAPS-MIL' OR name ILIKE '%Weightlifting Straps%';

-- Fallback for any product without image
UPDATE products
SET image_url = 'https://images.unsplash.com/photo-1584735935682-2f2b69dff9d2?auto=format&fit=crop&w=800&q=80'
WHERE image_url IS NULL OR image_url = '';

-- --------------------------------------------------------------------------------------
-- 3. STORE ORDER POLICIES (Public & Authenticated Access)
-- --------------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Members and staff manage store orders" ON store_orders;
CREATE POLICY "Members and staff manage store orders" ON store_orders
FOR ALL USING (
    member_id = auth.uid() OR
    user_id = auth.uid() OR
    auth_is_super_admin() OR
    (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
);

DROP POLICY IF EXISTS "Public can view own store orders" ON store_orders;
CREATE POLICY "Public can view own store orders" ON store_orders
FOR SELECT USING (
    member_id = auth.uid() OR
    user_id = auth.uid() OR
    auth_is_super_admin() OR
    (auth_current_role() IN ('gym_owner', 'staff') AND tenant_id = auth_current_tenant_id())
);
