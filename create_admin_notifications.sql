-- ===========================================
-- CREATE ADMIN NOTIFICATIONS TABLE
-- ===========================================
-- Run this in your Supabase SQL Editor

CREATE TABLE IF NOT EXISTS public.admin_notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'medium',
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    related_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    related_vendor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    related_booking_id UUID,
    status TEXT NOT NULL DEFAULT 'unread',
    action_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Constraints: enforce valid enum values
ALTER TABLE public.admin_notifications
    DROP CONSTRAINT IF EXISTS admin_notifications_type_check;
ALTER TABLE public.admin_notifications
    ADD CONSTRAINT admin_notifications_type_check
    CHECK (type IN ('booking', 'payment', 'vendor', 'system', 'support', 'onboarding', 'risk', 'health', 'business'));

ALTER TABLE public.admin_notifications
    DROP CONSTRAINT IF EXISTS admin_notifications_severity_check;
ALTER TABLE public.admin_notifications
    ADD CONSTRAINT admin_notifications_severity_check
    CHECK (severity IN ('low', 'medium', 'high', 'critical'));

ALTER TABLE public.admin_notifications
    DROP CONSTRAINT IF EXISTS admin_notifications_status_check;
ALTER TABLE public.admin_notifications
    ADD CONSTRAINT admin_notifications_status_check
    CHECK (status IN ('unread', 'read', 'resolved'));

-- Performance indexes
CREATE INDEX IF NOT EXISTS idx_admin_notifications_status
    ON public.admin_notifications(status);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_severity
    ON public.admin_notifications(severity);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_type
    ON public.admin_notifications(type);
CREATE INDEX IF NOT EXISTS idx_admin_notifications_created_at
    ON public.admin_notifications(created_at DESC);

-- RLS: Only admins can read/manage admin notifications
ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;

-- Allow admins full access (uses public.users, consistent with all other RLS policies in this project)
DROP POLICY IF EXISTS "Admins can manage admin_notifications" ON public.admin_notifications;
CREATE POLICY "Admins can manage admin_notifications"
    ON public.admin_notifications
    FOR ALL
    USING (
        (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- Allow any authenticated user to create notifications (to alert admins)
DROP POLICY IF EXISTS "Allow authenticated users to create admin_notifications" ON public.admin_notifications;
CREATE POLICY "Allow authenticated users to create admin_notifications"
    ON public.admin_notifications
    FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.update_admin_notifications_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_admin_notifications_updated_at ON public.admin_notifications;
CREATE TRIGGER trg_admin_notifications_updated_at
    BEFORE UPDATE ON public.admin_notifications
    FOR EACH ROW EXECUTE FUNCTION public.update_admin_notifications_updated_at();
