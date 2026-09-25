-- ORGANIZER MODULE — Supabase schema for Wedding Event Organizer (expo / bridal fair)
-- Covers all 20 organizer modules from organizer_screen_catalog.dart

-- ============================================================
-- HELPERS
-- ============================================================

CREATE OR REPLACE FUNCTION update_organizer_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Returns true if the current user owns or is staff of the organizer company
CREATE OR REPLACE FUNCTION is_organizer_company_member(p_company_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM organizer_companies c
        WHERE c.id = p_company_id AND c.owner_user_id = auth.uid()
    ) OR EXISTS (
        SELECT 1 FROM organizer_staff_members s
        WHERE s.company_id = p_company_id
          AND s.user_id = auth.uid()
          AND s.is_active = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

CREATE OR REPLACE FUNCTION is_organizer_expo_member(p_expo_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM organizer_expos e
        WHERE e.id = p_expo_id
          AND is_organizer_company_member(e.company_id)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ============================================================
-- 1. AUTH & COMPANY SETUP
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    legal_name TEXT NOT NULL,
    display_name TEXT,
    business_registration_no TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    address TEXT,
    website_url TEXT,
    is_verified BOOLEAN DEFAULT false,
    setup_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(owner_user_id)
);

CREATE TABLE IF NOT EXISTS organizer_company_branding (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    logo_url TEXT,
    primary_color TEXT DEFAULT '#6B21A8',
    secondary_color TEXT DEFAULT '#F59E0B',
    accent_color TEXT,
    expo_template_json JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id)
);

CREATE TABLE IF NOT EXISTS organizer_event_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    slug TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id, slug)
);

CREATE TABLE IF NOT EXISTS organizer_staff_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    permissions JSONB DEFAULT '[]',
    is_system_role BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id, name)
);

CREATE TABLE IF NOT EXISTS organizer_staff_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    role_id UUID REFERENCES organizer_staff_roles(id) ON DELETE SET NULL,
    full_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    is_active BOOLEAN DEFAULT true,
    last_login_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id, email)
);

CREATE TABLE IF NOT EXISTS organizer_service_regions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    state TEXT NOT NULL,
    city TEXT,
    coverage_notes TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 2. EXPO MANAGEMENT & DASHBOARD
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_expos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    event_type_id UUID REFERENCES organizer_event_types(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    slug TEXT,
    venue TEXT NOT NULL,
    venue_address TEXT,
    description TEXT,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'upcoming'
        CHECK (status IN ('draft', 'upcoming', 'ongoing', 'past', 'cancelled')),
    booth_capacity INTEGER DEFAULT 0,
    ticket_strategy TEXT DEFAULT 'free_and_paid'
        CHECK (ticket_strategy IN ('free_only', 'paid_only', 'free_and_paid')),
    pricing_strategy TEXT DEFAULT 'zone_based',
    cover_image_url TEXT,
    map_image_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id, slug)
);

CREATE TABLE IF NOT EXISTS organizer_expo_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    early_bird_deadline TIMESTAMPTZ,
    booth_rules JSONB DEFAULT '{}',
    pricing_rules JSONB DEFAULT '{}',
    lead_distribution_rules JSONB DEFAULT '{}',
    notification_settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(expo_id)
);

-- ============================================================
-- 3. BOOTH MANAGEMENT
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_booths (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    number TEXT NOT NULL,
    zone TEXT NOT NULL DEFAULT 'a' CHECK (zone IN ('a', 'b', 'vip')),
    size_label TEXT NOT NULL DEFAULT '3×3m',
    early_bird_price_rm NUMERIC(12, 2) DEFAULT 0,
    normal_price_rm NUMERIC(12, 2) DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'available'
        CHECK (status IN ('available', 'pending', 'booked', 'blocked')),
    exhibitor_id UUID,
    grid_x NUMERIC(8, 2) DEFAULT 0,
    grid_y NUMERIC(8, 2) DEFAULT 0,
    grid_w NUMERIC(8, 2) DEFAULT 1,
    grid_h NUMERIC(8, 2) DEFAULT 1,
    map_x NUMERIC(8, 4),
    map_y NUMERIC(8, 4),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(expo_id, number)
);

CREATE TABLE IF NOT EXISTS organizer_booth_bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booth_id UUID NOT NULL REFERENCES organizer_booths(id) ON DELETE CASCADE,
    exhibitor_id UUID NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'approved', 'rejected', 'cancelled')),
    requested_at TIMESTAMPTZ DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 4. VENDOR / EXHIBITOR MANAGEMENT
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_exhibitors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    vendor_profile_id UUID REFERENCES vendor_profiles(id) ON DELETE SET NULL,
    company_name TEXT NOT NULL,
    category TEXT,
    contact_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'approved', 'rejected', 'withdrawn')),
    booth_id UUID REFERENCES organizer_booths(id) ON DELETE SET NULL,
    package_name TEXT,
    booth_fee_rm NUMERIC(12, 2) DEFAULT 0,
    paid_rm NUMERIC(12, 2) DEFAULT 0,
    payment_status TEXT NOT NULL DEFAULT 'unpaid'
        CHECK (payment_status IN ('paid', 'partial', 'unpaid')),
    applied_at TIMESTAMPTZ DEFAULT NOW(),
    approved_at TIMESTAMPTZ,
    rejected_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE organizer_booths
    ADD CONSTRAINT organizer_booths_exhibitor_fk
    FOREIGN KEY (exhibitor_id) REFERENCES organizer_exhibitors(id) ON DELETE SET NULL;

ALTER TABLE organizer_booth_bookings
    ADD CONSTRAINT organizer_booth_bookings_exhibitor_fk
    FOREIGN KEY (exhibitor_id) REFERENCES organizer_exhibitors(id) ON DELETE CASCADE;

CREATE TABLE IF NOT EXISTS organizer_exhibitor_contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exhibitor_id UUID NOT NULL REFERENCES organizer_exhibitors(id) ON DELETE CASCADE,
    contract_title TEXT NOT NULL,
    contract_body TEXT,
    document_url TEXT,
    status TEXT NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'sent', 'signed', 'expired', 'cancelled')),
    signed_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizer_exhibitor_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exhibitor_id UUID NOT NULL REFERENCES organizer_exhibitors(id) ON DELETE CASCADE,
    amount_rm NUMERIC(12, 2) NOT NULL,
    payment_method TEXT DEFAULT 'bank_transfer',
    reference_no TEXT,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'confirmed', 'failed', 'refunded')),
    paid_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 5. LEAD MANAGEMENT
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_expo_leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    visitor_id UUID,
    visitor_name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    wedding_date DATE,
    budget_range TEXT,
    interests TEXT[] DEFAULT '{}',
    assigned_exhibitor_id UUID REFERENCES organizer_exhibitors(id) ON DELETE SET NULL,
    temperature TEXT NOT NULL DEFAULT 'warm'
        CHECK (temperature IN ('hot', 'warm', 'cold')),
    stage TEXT NOT NULL DEFAULT 'new'
        CHECK (stage IN ('new', 'contacted', 'followed_up', 'converted', 'lost')),
    source_booth TEXT,
    source_booth_id UUID REFERENCES organizer_booths(id) ON DELETE SET NULL,
    quality_score INTEGER CHECK (quality_score >= 0 AND quality_score <= 100),
    notes TEXT,
    captured_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizer_lead_stage_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID NOT NULL REFERENCES organizer_expo_leads(id) ON DELETE CASCADE,
    from_stage TEXT,
    to_stage TEXT NOT NULL,
    changed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 6. VISITOR SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_expo_visitors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    phone TEXT NOT NULL,
    email TEXT,
    wedding_date DATE,
    budget_range TEXT,
    interests TEXT[] DEFAULT '{}',
    status TEXT NOT NULL DEFAULT 'registered'
        CHECK (status IN ('registered', 'checked_in', 'left')),
    ticket_code TEXT,
    registered_at TIMESTAMPTZ DEFAULT NOW(),
    checked_in_at TIMESTAMPTZ,
    left_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(expo_id, ticket_code)
);

ALTER TABLE organizer_expo_leads
    ADD CONSTRAINT organizer_expo_leads_visitor_fk
    FOREIGN KEY (visitor_id) REFERENCES organizer_expo_visitors(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS organizer_visitor_booth_visits (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    visitor_id UUID NOT NULL REFERENCES organizer_expo_visitors(id) ON DELETE CASCADE,
    booth_id UUID NOT NULL REFERENCES organizer_booths(id) ON DELETE CASCADE,
    visited_at TIMESTAMPTZ DEFAULT NOW(),
    duration_minutes INTEGER,
    UNIQUE(visitor_id, booth_id)
);

CREATE TABLE IF NOT EXISTS organizer_visitor_saved_vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    visitor_id UUID NOT NULL REFERENCES organizer_expo_visitors(id) ON DELETE CASCADE,
    exhibitor_id UUID NOT NULL REFERENCES organizer_exhibitors(id) ON DELETE CASCADE,
    saved_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(visitor_id, exhibitor_id)
);

-- ============================================================
-- 7. TICKET & ENTRY
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_ticket_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    tier TEXT NOT NULL DEFAULT 'free' CHECK (tier IN ('free', 'vip')),
    name TEXT NOT NULL,
    description TEXT,
    price_rm NUMERIC(12, 2) DEFAULT 0,
    quota INTEGER NOT NULL DEFAULT 0,
    sold_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizer_ticket_sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    ticket_type_id UUID NOT NULL REFERENCES organizer_ticket_types(id) ON DELETE RESTRICT,
    visitor_id UUID REFERENCES organizer_expo_visitors(id) ON DELETE SET NULL,
    ticket_code TEXT NOT NULL,
    buyer_name TEXT NOT NULL,
    buyer_phone TEXT,
    buyer_email TEXT,
    amount_rm NUMERIC(12, 2) DEFAULT 0,
    channel TEXT NOT NULL DEFAULT 'online'
        CHECK (channel IN ('online', 'walk_in', 'promo')),
    promo_code_id UUID,
    purchased_at TIMESTAMPTZ DEFAULT NOW(),
    checked_in BOOLEAN DEFAULT false,
    checked_in_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(expo_id, ticket_code)
);

-- ============================================================
-- 8. STAFF OPERATIONS
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_staff_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    staff_member_id UUID NOT NULL REFERENCES organizer_staff_members(id) ON DELETE CASCADE,
    zone TEXT,
    booth_id UUID REFERENCES organizer_booths(id) ON DELETE SET NULL,
    role_label TEXT,
    shift_start TIMESTAMPTZ,
    shift_end TIMESTAMPTZ,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizer_staff_activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    staff_member_id UUID NOT NULL REFERENCES organizer_staff_members(id) ON DELETE CASCADE,
    expo_id UUID REFERENCES organizer_expos(id) ON DELETE CASCADE,
    activity_type TEXT NOT NULL,
    description TEXT,
    location TEXT,
    metadata JSONB DEFAULT '{}',
    logged_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 9. SPONSOR SYSTEM
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_sponsor_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    tier TEXT NOT NULL CHECK (tier IN ('platinum', 'gold', 'silver', 'bronze', 'custom')),
    price_rm NUMERIC(12, 2) DEFAULT 0,
    deliverables JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id, name)
);

CREATE TABLE IF NOT EXISTS organizer_sponsors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    package_id UUID REFERENCES organizer_sponsor_packages(id) ON DELETE SET NULL,
    company_name TEXT NOT NULL,
    contact_name TEXT,
    contact_email TEXT,
    contact_phone TEXT,
    logo_url TEXT,
    amount_rm NUMERIC(12, 2) DEFAULT 0,
    paid_rm NUMERIC(12, 2) DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'confirmed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizer_sponsor_agreements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sponsor_id UUID NOT NULL REFERENCES organizer_sponsors(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    document_url TEXT,
    deliverables JSONB DEFAULT '[]',
    status TEXT NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'sent', 'signed', 'completed', 'cancelled')),
    signed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizer_sponsor_exposure_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sponsor_id UUID NOT NULL REFERENCES organizer_sponsors(id) ON DELETE CASCADE,
    placement_type TEXT NOT NULL,
    placement_location TEXT,
    impressions INTEGER DEFAULT 0,
    logged_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT
);

-- ============================================================
-- 10. FINANCE
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_expo_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    description TEXT NOT NULL,
    amount_rm NUMERIC(12, 2) NOT NULL,
    expense_date DATE DEFAULT CURRENT_DATE,
    receipt_url TEXT,
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizer_invoices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    invoice_no TEXT NOT NULL,
    recipient_type TEXT NOT NULL CHECK (recipient_type IN ('exhibitor', 'sponsor')),
    exhibitor_id UUID REFERENCES organizer_exhibitors(id) ON DELETE SET NULL,
    sponsor_id UUID REFERENCES organizer_sponsors(id) ON DELETE SET NULL,
    amount_rm NUMERIC(12, 2) NOT NULL,
    paid_rm NUMERIC(12, 2) DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'sent', 'partial', 'paid', 'overdue', 'cancelled')),
    due_date DATE,
    issued_at TIMESTAMPTZ DEFAULT NOW(),
    paid_at TIMESTAMPTZ,
    document_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(expo_id, invoice_no)
);

-- ============================================================
-- 11. MARKETING & SALES
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_marketing_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    channel TEXT NOT NULL,
    budget_rm NUMERIC(12, 2) DEFAULT 0,
    spent_rm NUMERIC(12, 2) DEFAULT 0,
    impressions INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    registrations INTEGER DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('draft', 'active', 'paused', 'completed')),
    start_date DATE,
    end_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizer_promo_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'flat')),
    discount_value NUMERIC(12, 2) NOT NULL,
    applies_to TEXT NOT NULL DEFAULT 'ticket'
        CHECK (applies_to IN ('ticket', 'booth', 'both')),
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(expo_id, code)
);

ALTER TABLE organizer_ticket_sales
    ADD CONSTRAINT organizer_ticket_sales_promo_fk
    FOREIGN KEY (promo_code_id) REFERENCES organizer_promo_codes(id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS organizer_influencer_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    influencer_name TEXT NOT NULL,
    platform TEXT,
    post_url TEXT,
    fee_rm NUMERIC(12, 2) DEFAULT 0,
    reach INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    conversions INTEGER DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('planned', 'active', 'completed', 'cancelled')),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 12. LIVE EXPO COMMAND CENTER
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_expo_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    incident_type TEXT NOT NULL CHECK (incident_type IN ('booth', 'technical', 'crowd_control')),
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    status TEXT NOT NULL DEFAULT 'open'
        CHECK (status IN ('open', 'in_progress', 'resolved')),
    priority TEXT NOT NULL DEFAULT 'medium'
        CHECK (priority IN ('low', 'medium', 'high', 'critical')),
    reported_by TEXT,
    reported_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    assigned_staff_id UUID REFERENCES organizer_staff_members(id) ON DELETE SET NULL,
    reported_at TIMESTAMPTZ DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizer_expo_timeline_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    location TEXT,
    start_at TIMESTAMPTZ NOT NULL,
    end_at TIMESTAMPTZ NOT NULL,
    status TEXT NOT NULL DEFAULT 'upcoming'
        CHECK (status IN ('upcoming', 'live', 'completed', 'cancelled')),
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizer_emergency_alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    recipient_groups TEXT[] DEFAULT '{}',
    sent_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    acknowledged BOOLEAN DEFAULT false,
    acknowledged_at TIMESTAMPTZ
);

-- ============================================================
-- 13. POST-EXPO
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_expo_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    report_type TEXT NOT NULL
        CHECK (report_type IN ('summary', 'vendor_roi', 'lead_conversion', 'performance')),
    title TEXT NOT NULL,
    report_data JSONB DEFAULT '{}',
    generated_at TIMESTAMPTZ DEFAULT NOW(),
    generated_by UUID REFERENCES auth.users(id) ON DELETE SET NULL
);

CREATE TABLE IF NOT EXISTS organizer_vendor_feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID NOT NULL REFERENCES organizer_expos(id) ON DELETE CASCADE,
    exhibitor_id UUID NOT NULL REFERENCES organizer_exhibitors(id) ON DELETE CASCADE,
    rating INTEGER CHECK (rating >= 1 AND rating <= 5),
    feedback TEXT,
    submitted_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 14. COMMUNICATION
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_broadcast_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    expo_id UUID REFERENCES organizer_expos(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    subject TEXT NOT NULL,
    body TEXT NOT NULL,
    audience TEXT NOT NULL DEFAULT 'all_vendors'
        CHECK (audience IN ('all_vendors', 'all_staff', 'all_sponsors', 'custom')),
    recipient_filter JSONB DEFAULT '{}',
    sent_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    sent_at TIMESTAMPTZ DEFAULT NOW(),
    delivery_count INTEGER DEFAULT 0
);

-- ============================================================
-- 15. DOCUMENT MANAGEMENT
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_document_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    template_type TEXT NOT NULL
        CHECK (template_type IN ('vendor_contract', 'sponsor_proposal', 'invoice', 'other')),
    name TEXT NOT NULL,
    body_template TEXT,
    variables JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS organizer_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    expo_id UUID REFERENCES organizer_expos(id) ON DELETE SET NULL,
    document_type TEXT NOT NULL
        CHECK (document_type IN ('contract', 'agreement', 'invoice', 'proposal', 'other')),
    title TEXT NOT NULL,
    file_url TEXT NOT NULL,
    related_exhibitor_id UUID REFERENCES organizer_exhibitors(id) ON DELETE SET NULL,
    related_sponsor_id UUID REFERENCES organizer_sponsors(id) ON DELETE SET NULL,
    uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 16. AUTOMATION
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_automation_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    expo_id UUID REFERENCES organizer_expos(id) ON DELETE CASCADE,
    rule_type TEXT NOT NULL
        CHECK (rule_type IN ('booth_allocation', 'lead_distribution', 'payment_reminder', 'vendor_follow_up')),
    name TEXT NOT NULL,
    is_enabled BOOLEAN DEFAULT true,
    trigger_config JSONB DEFAULT '{}',
    action_config JSONB DEFAULT '{}',
    last_run_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 17. SETTINGS & SUBSCRIPTION
-- ============================================================

CREATE TABLE IF NOT EXISTS organizer_company_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    preferences JSONB DEFAULT '{}',
    default_expo_settings JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id)
);

CREATE TABLE IF NOT EXISTS organizer_notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    push_enabled BOOLEAN DEFAULT true,
    email_enabled BOOLEAN DEFAULT true,
    sms_enabled BOOLEAN DEFAULT false,
    event_types JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, company_id)
);

CREATE TABLE IF NOT EXISTS organizer_subscriptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID NOT NULL REFERENCES organizer_companies(id) ON DELETE CASCADE,
    plan_tier TEXT NOT NULL DEFAULT 'starter'
        CHECK (plan_tier IN ('starter', 'professional', 'enterprise')),
    status TEXT NOT NULL DEFAULT 'active'
        CHECK (status IN ('trial', 'active', 'past_due', 'cancelled')),
    max_expos_per_year INTEGER,
    max_staff INTEGER,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    expires_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(company_id)
);

-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_organizer_expos_company ON organizer_expos(company_id);
CREATE INDEX IF NOT EXISTS idx_organizer_expos_status ON organizer_expos(status, start_at);
CREATE INDEX IF NOT EXISTS idx_organizer_booths_expo ON organizer_booths(expo_id);
CREATE INDEX IF NOT EXISTS idx_organizer_booths_status ON organizer_booths(expo_id, status);
CREATE INDEX IF NOT EXISTS idx_organizer_exhibitors_expo ON organizer_exhibitors(expo_id);
CREATE INDEX IF NOT EXISTS idx_organizer_exhibitors_status ON organizer_exhibitors(expo_id, status);
CREATE INDEX IF NOT EXISTS idx_organizer_leads_expo ON organizer_expo_leads(expo_id);
CREATE INDEX IF NOT EXISTS idx_organizer_leads_stage ON organizer_expo_leads(expo_id, stage);
CREATE INDEX IF NOT EXISTS idx_organizer_visitors_expo ON organizer_expo_visitors(expo_id);
CREATE INDEX IF NOT EXISTS idx_organizer_visitors_status ON organizer_expo_visitors(expo_id, status);
CREATE INDEX IF NOT EXISTS idx_organizer_ticket_sales_expo ON organizer_ticket_sales(expo_id);
CREATE INDEX IF NOT EXISTS idx_organizer_incidents_expo ON organizer_expo_incidents(expo_id, status);
CREATE INDEX IF NOT EXISTS idx_organizer_staff_members_company ON organizer_staff_members(company_id);

-- ============================================================
-- DASHBOARD VIEW (expo command dashboard + analytics)
-- ============================================================

CREATE OR REPLACE VIEW organizer_expo_dashboard_stats AS
SELECT
    e.id AS expo_id,
    e.company_id,
    e.name,
    e.venue,
    e.start_at,
    e.end_at,
    e.status,
    e.booth_capacity,
    COUNT(DISTINCT b.id) FILTER (WHERE b.status = 'booked') AS booths_booked,
    COUNT(DISTINCT ex.id) FILTER (WHERE ex.status = 'approved') AS vendor_count,
    COUNT(DISTINCT v.id) AS visitor_registrations,
    COUNT(DISTINCT ts.id) AS tickets_sold,
    COALESCE(SUM(ep.amount_rm) FILTER (WHERE ep.status = 'confirmed'), 0)
        + COALESCE(SUM(ts.amount_rm), 0)
        + COALESCE(SUM(sp.paid_rm), 0) AS revenue_rm,
    COALESCE(SUM(ex.booth_fee_rm - ex.paid_rm) FILTER (WHERE ex.payment_status != 'paid'), 0)
        AS pending_payments_rm
FROM organizer_expos e
LEFT JOIN organizer_booths b ON b.expo_id = e.id
LEFT JOIN organizer_exhibitors ex ON ex.expo_id = e.id
LEFT JOIN organizer_expo_visitors v ON v.expo_id = e.id
LEFT JOIN organizer_ticket_sales ts ON ts.expo_id = e.id
LEFT JOIN organizer_exhibitor_payments ep ON ep.exhibitor_id = ex.id
LEFT JOIN organizer_sponsors sp ON sp.expo_id = e.id
GROUP BY e.id;

-- ============================================================
-- UPDATED_AT TRIGGERS
-- ============================================================

DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'organizer_companies',
        'organizer_company_branding',
        'organizer_event_types',
        'organizer_staff_roles',
        'organizer_staff_members',
        'organizer_service_regions',
        'organizer_expos',
        'organizer_expo_settings',
        'organizer_booths',
        'organizer_booth_bookings',
        'organizer_exhibitors',
        'organizer_exhibitor_contracts',
        'organizer_exhibitor_payments',
        'organizer_expo_leads',
        'organizer_expo_visitors',
        'organizer_ticket_types',
        'organizer_ticket_sales',
        'organizer_staff_assignments',
        'organizer_sponsor_packages',
        'organizer_sponsors',
        'organizer_sponsor_agreements',
        'organizer_expo_expenses',
        'organizer_invoices',
        'organizer_marketing_campaigns',
        'organizer_promo_codes',
        'organizer_influencer_campaigns',
        'organizer_expo_incidents',
        'organizer_expo_timeline_items',
        'organizer_document_templates',
        'organizer_documents',
        'organizer_automation_rules',
        'organizer_company_settings',
        'organizer_notification_preferences',
        'organizer_subscriptions'
    ]
    LOOP
        EXECUTE format(
            'DROP TRIGGER IF EXISTS trg_%I_updated_at ON %I;
             CREATE TRIGGER trg_%I_updated_at
                 BEFORE UPDATE ON %I
                 FOR EACH ROW EXECUTE PROCEDURE update_organizer_modified_column();',
            t, t, t, t
        );
    END LOOP;
END $$;

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE organizer_companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_company_branding ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_event_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_staff_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_staff_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_service_regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_expos ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_expo_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_booths ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_booth_bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_exhibitors ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_exhibitor_contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_exhibitor_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_expo_leads ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_lead_stage_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_expo_visitors ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_visitor_booth_visits ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_visitor_saved_vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_ticket_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_ticket_sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_staff_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_staff_activity_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_sponsor_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_sponsors ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_sponsor_agreements ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_sponsor_exposure_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_expo_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_marketing_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_promo_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_influencer_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_expo_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_expo_timeline_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_emergency_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_expo_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_vendor_feedback ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_broadcast_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_document_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_automation_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_company_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_subscriptions ENABLE ROW LEVEL SECURITY;

-- Company-level tables
CREATE POLICY "Organizer members manage companies" ON organizer_companies
    FOR ALL USING (owner_user_id = auth.uid() OR is_organizer_company_member(id));

CREATE POLICY "Organizer members manage branding" ON organizer_company_branding
    FOR ALL USING (is_organizer_company_member(company_id));

CREATE POLICY "Organizer members manage event types" ON organizer_event_types
    FOR ALL USING (is_organizer_company_member(company_id));

CREATE POLICY "Organizer members manage staff roles" ON organizer_staff_roles
    FOR ALL USING (is_organizer_company_member(company_id));

CREATE POLICY "Organizer members manage staff" ON organizer_staff_members
    FOR ALL USING (is_organizer_company_member(company_id));

CREATE POLICY "Organizer members manage regions" ON organizer_service_regions
    FOR ALL USING (is_organizer_company_member(company_id));

CREATE POLICY "Organizer members manage settings" ON organizer_company_settings
    FOR ALL USING (is_organizer_company_member(company_id));

CREATE POLICY "Organizer members manage subscriptions" ON organizer_subscriptions
    FOR ALL USING (is_organizer_company_member(company_id));

CREATE POLICY "Organizer members manage sponsor packages" ON organizer_sponsor_packages
    FOR ALL USING (is_organizer_company_member(company_id));

CREATE POLICY "Organizer members manage doc templates" ON organizer_document_templates
    FOR ALL USING (is_organizer_company_member(company_id));

CREATE POLICY "Organizer members manage automation" ON organizer_automation_rules
    FOR ALL USING (is_organizer_company_member(company_id));

CREATE POLICY "Users manage own notification prefs" ON organizer_notification_preferences
    FOR ALL USING (user_id = auth.uid() AND is_organizer_company_member(company_id));

-- Expo-scoped tables (macro policy via helper)
DO $$
DECLARE
    expo_table TEXT;
BEGIN
    FOREACH expo_table IN ARRAY ARRAY[
        'organizer_expos',
        'organizer_expo_settings',
        'organizer_booths',
        'organizer_booth_bookings',
        'organizer_exhibitors',
        'organizer_exhibitor_contracts',
        'organizer_exhibitor_payments',
        'organizer_expo_leads',
        'organizer_expo_visitors',
        'organizer_visitor_booth_visits',
        'organizer_visitor_saved_vendors',
        'organizer_ticket_types',
        'organizer_ticket_sales',
        'organizer_staff_assignments',
        'organizer_sponsors',
        'organizer_sponsor_agreements',
        'organizer_sponsor_exposure_logs',
        'organizer_expo_expenses',
        'organizer_invoices',
        'organizer_marketing_campaigns',
        'organizer_promo_codes',
        'organizer_influencer_campaigns',
        'organizer_expo_incidents',
        'organizer_expo_timeline_items',
        'organizer_emergency_alerts',
        'organizer_expo_reports',
        'organizer_vendor_feedback',
        'organizer_broadcast_messages',
        'organizer_documents'
    ]
    LOOP
        IF expo_table = 'organizer_expos' THEN
            EXECUTE format(
                'CREATE POLICY "Organizer members manage expos" ON %I
                 FOR ALL USING (is_organizer_company_member(company_id));',
                expo_table
            );
        ELSIF expo_table IN ('organizer_broadcast_messages') THEN
            EXECUTE format(
                'CREATE POLICY "Organizer members manage broadcast" ON %I
                 FOR ALL USING (is_organizer_company_member(company_id));',
                expo_table
            );
        ELSIF expo_table = 'organizer_documents' THEN
            EXECUTE format(
                'CREATE POLICY "Organizer members manage documents" ON %I
                 FOR ALL USING (is_organizer_company_member(company_id));',
                expo_table
            );
        ELSIF expo_table = 'organizer_booth_bookings' THEN
            EXECUTE format(
                'CREATE POLICY "Organizer members manage booth bookings" ON %I
                 FOR ALL USING (
                     EXISTS (
                         SELECT 1 FROM organizer_booths b
                         WHERE b.id = booth_id AND is_organizer_expo_member(b.expo_id)
                     )
                 );',
                expo_table
            );
        ELSIF expo_table = 'organizer_exhibitor_contracts' THEN
            EXECUTE format(
                'CREATE POLICY "Organizer members manage exhibitor contracts" ON %I
                 FOR ALL USING (
                     EXISTS (
                         SELECT 1 FROM organizer_exhibitors ex
                         JOIN organizer_expos e ON e.id = ex.expo_id
                         WHERE ex.id = exhibitor_id AND is_organizer_company_member(e.company_id)
                     )
                 );',
                expo_table
            );
        ELSIF expo_table = 'organizer_exhibitor_payments' THEN
            EXECUTE format(
                'CREATE POLICY "Organizer members manage exhibitor payments" ON %I
                 FOR ALL USING (
                     EXISTS (
                         SELECT 1 FROM organizer_exhibitors ex
                         JOIN organizer_expos e ON e.id = ex.expo_id
                         WHERE ex.id = exhibitor_id AND is_organizer_company_member(e.company_id)
                     )
                 );',
                expo_table
            );
        ELSIF expo_table IN ('organizer_visitor_booth_visits', 'organizer_visitor_saved_vendors') THEN
            EXECUTE format(
                'CREATE POLICY "Organizer members manage visitor relations" ON %I
                 FOR ALL USING (
                     EXISTS (
                         SELECT 1 FROM organizer_expo_visitors v
                         WHERE v.id = visitor_id AND is_organizer_expo_member(v.expo_id)
                     )
                 );',
                expo_table
            );
        ELSIF expo_table = 'organizer_lead_stage_history' THEN
            NULL;
        ELSIF expo_table IN ('organizer_sponsor_agreements', 'organizer_sponsor_exposure_logs') THEN
            EXECUTE format(
                'CREATE POLICY "Organizer members manage sponsor data" ON %I
                 FOR ALL USING (
                     EXISTS (
                         SELECT 1 FROM organizer_sponsors s
                         WHERE s.id = sponsor_id AND is_organizer_expo_member(s.expo_id)
                     )
                 );',
                expo_table
            );
        ELSE
            EXECUTE format(
                'CREATE POLICY "Organizer members manage expo data" ON %I
                 FOR ALL USING (is_organizer_expo_member(expo_id));',
                expo_table
            );
        END IF;
    END LOOP;
END $$;

CREATE POLICY "Organizer members manage lead history" ON organizer_lead_stage_history
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM organizer_expo_leads l
            WHERE l.id = lead_id AND is_organizer_expo_member(l.expo_id)
        )
    );

CREATE POLICY "Organizer members manage staff activity" ON organizer_staff_activity_logs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM organizer_staff_members sm
            WHERE sm.id = staff_member_id AND is_organizer_company_member(sm.company_id)
        )
    );

-- Public read for active promo codes (ticket purchase flow)
CREATE POLICY "Public can view active expo promo codes" ON organizer_promo_codes
    FOR SELECT USING (is_active = true AND (expires_at IS NULL OR expires_at > NOW()));

-- Exhibitors can view their own application on platform
CREATE POLICY "Vendors can view own exhibitor record" ON organizer_exhibitors
    FOR SELECT USING (
        vendor_profile_id IN (
            SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
        )
    );

-- Visitors can view/update own registration
CREATE POLICY "Visitors manage own registration" ON organizer_expo_visitors
    FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Public can register as visitor" ON organizer_expo_visitors
    FOR INSERT WITH CHECK (true);
