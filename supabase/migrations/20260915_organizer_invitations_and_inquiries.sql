-- ============================================================
-- EventEase Controlled Organizer Access: Inquiries & Invitations
-- ============================================================

-- 1. Organizer Inquiries / Applications (From Public "Contact EventEase")
CREATE TABLE IF NOT EXISTS organizer_inquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name TEXT NOT NULL,
    contact_person TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT NOT NULL,
    event_type TEXT DEFAULT 'Wedding Expo',
    estimated_booths INTEGER DEFAULT 20,
    estimated_date TEXT,
    notes TEXT,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'contacted', 'approved', 'rejected')),
    reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Organizer Invitations & Activation Tokens
CREATE TABLE IF NOT EXISTS organizer_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_name TEXT NOT NULL,
    contact_person TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    event_type TEXT DEFAULT 'Wedding Expo',
    token TEXT NOT NULL UNIQUE,
    status TEXT NOT NULL DEFAULT 'pending'
        CHECK (status IN ('pending', 'accepted', 'expired', 'revoked')),
    role TEXT NOT NULL DEFAULT 'organizer',
    created_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_organizer_inquiries_status ON organizer_inquiries(status);
CREATE INDEX IF NOT EXISTS idx_organizer_invitations_token ON organizer_invitations(token);
CREATE INDEX IF NOT EXISTS idx_organizer_invitations_email ON organizer_invitations(email);

-- Enable RLS
ALTER TABLE organizer_inquiries ENABLE ROW LEVEL SECURITY;
ALTER TABLE organizer_invitations ENABLE ROW LEVEL SECURITY;

-- Policies for inquiries
-- Anyone (even unauthenticated) can submit an inquiry
CREATE POLICY "Public can submit organizer inquiry" ON organizer_inquiries
    FOR INSERT WITH CHECK (true);

-- Admins can view and manage all inquiries
CREATE POLICY "Admins manage organizer inquiries" ON organizer_inquiries
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Policies for invitations
-- Admins can view and create invitations
CREATE POLICY "Admins manage organizer invitations" ON organizer_invitations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Invited users can read invitation by valid token to activate
CREATE POLICY "Anyone can read invitation by token" ON organizer_invitations
    FOR SELECT USING (status = 'pending' AND expires_at > NOW());

-- ============================================================
-- 3. ADMIN ACCESS OVERRIDES FOR ORGANIZER TABLES
-- ============================================================

-- Admins can view and manage all organizer companies
DROP POLICY IF EXISTS "Admins manage organizer companies" ON organizer_companies;
CREATE POLICY "Admins manage organizer companies" ON organizer_companies
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Admins can view and manage all organizer expos
DROP POLICY IF EXISTS "Admins manage organizer expos" ON organizer_expos;
CREATE POLICY "Admins manage organizer expos" ON organizer_expos
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Public / Vendors can view published upcoming and ongoing expos
DROP POLICY IF EXISTS "Public and vendors view upcoming expos" ON organizer_expos;
CREATE POLICY "Public and vendors view upcoming expos" ON organizer_expos
    FOR SELECT USING (status IN ('upcoming', 'ongoing'));

