-- ============================================================================
-- Migration: Real In-App Notifications & Announcements (Strict Zero Dummy Data)
-- File: 20260926010000_real_notifications_and_announcements.sql
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id UUID REFERENCES public.tenants(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- NULL indicates tenant-wide announcement
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL DEFAULT 'announcement', -- 'paymentDue', 'storeOrder', 'announcement', 'gatePass', 'storeProduct'
  action_payload TEXT,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- 1. SELECT policy: Users can see their direct notifications, or tenant-wide announcements
CREATE POLICY "Users can view own or tenant notifications"
  ON public.notifications FOR SELECT
  USING (
    user_id = auth.uid()
    OR (user_id IS NULL AND tenant_id IN (
      SELECT tenant_id FROM public.profiles WHERE id = auth.uid()
    ))
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('owner', 'super_admin', 'staff')
    )
  );

-- 2. UPDATE policy: Users can mark their notifications as read
CREATE POLICY "Users can update own notification read status"
  ON public.notifications FOR UPDATE
  USING (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('owner', 'super_admin', 'staff')
    )
  )
  WITH CHECK (
    user_id = auth.uid()
    OR EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('owner', 'super_admin', 'staff')
    )
  );

-- 3. INSERT policy: Owners, staff, or system can create notifications
CREATE POLICY "Authorized users can insert notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role IN ('owner', 'super_admin', 'staff')
    )
    OR user_id = auth.uid()
  );

-- Indexes for ultra-fast query performance
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_tenant_id ON public.notifications(tenant_id);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
