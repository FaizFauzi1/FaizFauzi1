-- Phase 8 & 9: Admin Operations, Revenue & Growth tables

-- ─── Disputes & Evidence ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id TEXT NOT NULL UNIQUE,
    customer_id UUID REFERENCES auth.users(id),
    vendor_id UUID REFERENCES auth.users(id),
    booking_id UUID,
    parties_involved TEXT NOT NULL,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'pending', 'resolved', 'dismissed', 'escalated')),
    severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    dispute_type TEXT DEFAULT 'general',
    comments TEXT,
    notes TEXT,
    admin_decision TEXT,
    refund_amount NUMERIC(12,2),
    refund_status TEXT CHECK (refund_status IN ('none', 'pending', 'processed', 'rejected')),
    resolved_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.dispute_evidence (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispute_id UUID NOT NULL REFERENCES public.admin_disputes(id) ON DELETE CASCADE,
    evidence_type TEXT NOT NULL CHECK (evidence_type IN ('chat', 'payment', 'contract', 'photo', 'document', 'other')),
    title TEXT NOT NULL,
    content TEXT,
    file_url TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.admin_refunds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dispute_id UUID REFERENCES public.admin_disputes(id),
    payment_id UUID,
    customer_id UUID REFERENCES auth.users(id),
    vendor_id UUID REFERENCES auth.users(id),
    amount NUMERIC(12,2) NOT NULL,
    currency TEXT DEFAULT 'MYR',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'processed', 'rejected')),
    reason TEXT,
    processed_by UUID REFERENCES auth.users(id),
    processed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Anti-Bypass ───────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.bypass_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id TEXT NOT NULL,
    message_id TEXT,
    sender_id UUID REFERENCES auth.users(id),
    sender_role TEXT,
    flag_types TEXT[] NOT NULL,
    severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    original_message TEXT,
    masked_message TEXT,
    status TEXT DEFAULT 'flagged' CHECK (status IN ('flagged', 'reviewed', 'warned', 'dismissed')),
    reviewed_by UUID REFERENCES auth.users(id),
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.vendor_warnings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES auth.users(id),
    incident_id UUID REFERENCES public.bypass_incidents(id),
    warning_type TEXT NOT NULL,
    message TEXT NOT NULL,
    issued_by UUID REFERENCES auth.users(id),
    acknowledged BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.repeat_offender_scores (
    user_id UUID PRIMARY KEY REFERENCES auth.users(id),
    incident_count INT DEFAULT 0,
    warning_count INT DEFAULT 0,
    last_incident_at TIMESTAMPTZ,
    risk_level TEXT DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high', 'blocked')),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Vendor Verification History ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.vendor_verification_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES auth.users(id),
    document_id UUID,
    event_type TEXT NOT NULL CHECK (event_type IN ('submitted', 'approved', 'rejected', 'reverification_requested', 'expired')),
    document_type TEXT,
    notes TEXT,
    performed_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Impersonation Audit ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_impersonation_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES auth.users(id),
    target_user_id UUID NOT NULL REFERENCES auth.users(id),
    target_role TEXT NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('start', 'end')),
    ip_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Announcements / Broadcast ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT,
    message TEXT NOT NULL,
    audience TEXT DEFAULT 'all' CHECK (audience IN ('all', 'customers', 'vendors', 'tier_premium', 'tier_basic')),
    channel TEXT DEFAULT 'in_app' CHECK (channel IN ('in_app', 'push', 'email', 'banner')),
    pinned BOOLEAN DEFAULT false,
    scheduled_at TIMESTAMPTZ,
    sent_at TIMESTAMPTZ,
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'scheduled', 'sent', 'cancelled')),
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Sponsored Listings ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.sponsored_listing_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES auth.users(id),
    placement TEXT DEFAULT 'search' CHECK (placement IN ('search', 'home', 'category', 'map')),
    priority_score INT DEFAULT 0,
    start_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ NOT NULL,
    budget NUMERIC(12,2),
    billing_status TEXT DEFAULT 'pending' CHECK (billing_status IN ('pending', 'paid', 'overdue')),
    impressions INT DEFAULT 0,
    clicks INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Promotions Admin ──────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.admin_promotions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    promo_type TEXT DEFAULT 'percentage' CHECK (promo_type IN ('percentage', 'fixed', 'free_shipping')),
    discount_value NUMERIC(12,2),
    target_audience TEXT DEFAULT 'all',
    vendor_id UUID REFERENCES auth.users(id),
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    usage_limit INT,
    usage_count INT DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ─── Churn / At-Risk Vendors ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.vendor_churn_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES auth.users(id),
    profile_views INT DEFAULT 0,
    inquiries INT DEFAULT 0,
    bookings INT DEFAULT 0,
    revenue NUMERIC(12,2) DEFAULT 0,
    days_inactive INT DEFAULT 0,
    risk_score NUMERIC(5,2) DEFAULT 0,
    risk_level TEXT DEFAULT 'low' CHECK (risk_level IN ('low', 'medium', 'high', 'critical')),
    retention_action TEXT,
    outreach_status TEXT DEFAULT 'none' CHECK (outreach_status IN ('none', 'contacted', 'boosted', 'resolved')),
    snapshot_date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(vendor_id, snapshot_date)
);

-- ─── Revenue by Country ────────────────────────────────────────────────────
-- PostgreSQL does not support CREATE VIEW IF NOT EXISTS; use OR REPLACE.
DROP VIEW IF EXISTS public.admin_revenue_by_country;
CREATE OR REPLACE VIEW public.admin_revenue_by_country AS
SELECT
    COALESCE(cu.country_code, u.country_code, 'MY') AS country_code,
    COUNT(DISTINCT pt.id) AS transaction_count,
    COALESCE(SUM(pt.amount), 0) AS total_revenue,
    COALESCE(SUM(pt.amount * 0.02), 0) AS commission_revenue
FROM public.payment_transactions pt
LEFT JOIN public.customer_user cu ON pt.customer_id = cu.id
LEFT JOIN public.users u ON pt.customer_id = u.id
GROUP BY COALESCE(cu.country_code, u.country_code, 'MY');

-- RLS (admin-only write, authenticated read for own data where applicable)
ALTER TABLE public.admin_disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bypass_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sponsored_listing_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_churn_snapshots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Admin full access disputes" ON public.admin_disputes;
DROP POLICY IF EXISTS "Admin full access bypass" ON public.bypass_incidents;
DROP POLICY IF EXISTS "Admin full access announcements" ON public.admin_announcements;
DROP POLICY IF EXISTS "Admin full access sponsored" ON public.sponsored_listing_campaigns;
DROP POLICY IF EXISTS "Admin full access churn" ON public.vendor_churn_snapshots;

CREATE POLICY "Admin full access disputes" ON public.admin_disputes FOR ALL USING (true);
CREATE POLICY "Admin full access bypass" ON public.bypass_incidents FOR ALL USING (true);
CREATE POLICY "Admin full access announcements" ON public.admin_announcements FOR ALL USING (true);
CREATE POLICY "Admin full access sponsored" ON public.sponsored_listing_campaigns FOR ALL USING (true);
CREATE POLICY "Admin full access churn" ON public.vendor_churn_snapshots FOR ALL USING (true);

CREATE INDEX IF NOT EXISTS idx_bypass_incidents_sender ON public.bypass_incidents(sender_id);
CREATE INDEX IF NOT EXISTS idx_bypass_incidents_status ON public.bypass_incidents(status);
CREATE INDEX IF NOT EXISTS idx_admin_disputes_status ON public.admin_disputes(status);
CREATE INDEX IF NOT EXISTS idx_sponsored_vendor ON public.sponsored_listing_campaigns(vendor_id);
CREATE INDEX IF NOT EXISTS idx_churn_risk ON public.vendor_churn_snapshots(risk_level);
