-- ======================================================================================
-- MIGRATION: 20260924020000_store_owner_management_and_rls_fix.sql
-- Description: 1. Storage bucket for product_images with public read and authenticated write.
--              2. RLS fixes for store_orders and store_order_items (Permissive INSERT for orders,
--                 and robust SELECT/UPDATE for gym owners and staff).
--              3. Clean helper to manage or clear dummy seed products.
-- ======================================================================================

-- --------------------------------------------------------------------------------------
-- 1. STORAGE BUCKET: product_images
-- --------------------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product_images',
    'product_images',
    TRUE,
    5242880, -- 5 MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET public = TRUE;

DROP POLICY IF EXISTS "Authenticated users can upload product images" ON storage.objects;
CREATE POLICY "Authenticated users can upload product images"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'product_images');

DROP POLICY IF EXISTS "Public can view product images" ON storage.objects;
CREATE POLICY "Public can view product images"
ON storage.objects FOR SELECT
USING (bucket_id = 'product_images');

-- --------------------------------------------------------------------------------------
-- 2. STORE_ORDERS RLS POLICIES (Unblocked Order Placement & Gym Owner Oversight)
-- --------------------------------------------------------------------------------------
ALTER TABLE IF EXISTS store_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS store_order_items ENABLE ROW LEVEL SECURITY;

-- 2.1 Allow ANY customer (authenticated or public guest) to insert store orders
DROP POLICY IF EXISTS "Anyone can create store orders" ON store_orders;
CREATE POLICY "Anyone can create store orders" ON store_orders
FOR INSERT WITH CHECK (TRUE);

-- 2.2 Allow ANY customer to insert order items for their order
DROP POLICY IF EXISTS "Anyone can insert store order items" ON store_order_items;
CREATE POLICY "Anyone can insert store order items" ON store_order_items
FOR INSERT WITH CHECK (TRUE);

-- 2.3 Customers can view their own orders
DROP POLICY IF EXISTS "Customers view own store orders" ON store_orders;
CREATE POLICY "Customers view own store orders" ON store_orders
FOR SELECT USING (
    user_id = auth.uid() OR
    member_id = auth.uid() OR
    auth_is_super_admin() OR
    (auth_current_role() IN ('gym_owner', 'staff') AND (tenant_id = auth_current_tenant_id() OR auth_current_tenant_id() IS NULL))
);

-- 2.4 Gym owners and staff can manage (view, update status, schedule) all orders in their tenant
DROP POLICY IF EXISTS "Owners and staff manage tenant store orders" ON store_orders;
CREATE POLICY "Owners and staff manage tenant store orders" ON store_orders
FOR ALL USING (
    auth_is_super_admin() OR
    (auth_current_role() IN ('gym_owner', 'staff') AND (tenant_id = auth_current_tenant_id() OR auth_current_tenant_id() IS NULL))
);

-- 2.5 Order items viewable by order owner and gym staff
DROP POLICY IF EXISTS "Order items viewable by customer and staff" ON store_order_items;
CREATE POLICY "Order items viewable by customer and staff" ON store_order_items
FOR SELECT USING (
    EXISTS (
        SELECT 1 FROM store_orders
        WHERE store_orders.id = store_order_items.order_id AND (
            store_orders.user_id = auth.uid() OR
            store_orders.member_id = auth.uid() OR
            auth_is_super_admin() OR
            (auth_current_role() IN ('gym_owner', 'staff') AND (store_orders.tenant_id = auth_current_tenant_id() OR auth_current_tenant_id() IS NULL))
        )
    )
);

-- --------------------------------------------------------------------------------------
-- 3. PRODUCTS RLS: Ensure Gym Owners and Staff can Insert, Update, and Delete products
-- --------------------------------------------------------------------------------------
DROP POLICY IF EXISTS "Staff and owners manage tenant products" ON products;
CREATE POLICY "Staff and owners manage tenant products" ON products
FOR ALL USING (
    auth_is_super_admin() OR
    tenant_id = auth_current_tenant_id() OR
    auth_current_tenant_id() IS NULL
);

DROP POLICY IF EXISTS "Public can view active products" ON products;
CREATE POLICY "Public can view active products" ON products
FOR SELECT USING (is_active = TRUE);

-- --------------------------------------------------------------------------------------
-- 4. OPTIONAL: Helper to wipe dummy seed products if gym owner wants a fresh catalog
-- --------------------------------------------------------------------------------------
-- To delete seeded dummy products, execute:
-- DELETE FROM products WHERE sku LIKE 'SUP-%' OR sku LIKE 'APP-%' OR sku LIKE 'DRK-%';
