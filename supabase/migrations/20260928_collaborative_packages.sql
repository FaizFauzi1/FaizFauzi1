-- Collaborative / multi-vendor packages and collaborator invitations

CREATE TABLE IF NOT EXISTS collaborative_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    owner_vendor_name TEXT DEFAULT '',
    title TEXT NOT NULL,
    description TEXT DEFAULT '',
    event_types JSONB DEFAULT '["Wedding"]'::jsonb,
    base_price DECIMAL(12,2) NOT NULL DEFAULT 0,
    components JSONB DEFAULT '[]'::jsonb,
    banner_image_url TEXT DEFAULT '',
    is_published BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS package_collaborator_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_id UUID NOT NULL REFERENCES collaborative_packages(id) ON DELETE CASCADE,
    package_name TEXT DEFAULT '',
    owner_vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    owner_vendor_name TEXT DEFAULT '',
    target_vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    target_vendor_name TEXT DEFAULT '',
    role_category TEXT DEFAULT 'other',
    role_component_name TEXT DEFAULT '',
    event_date TEXT DEFAULT '',
    location TEXT DEFAULT '',
    package_allowance DECIMAL(12,2) DEFAULT 0,
    requested_appointment_types JSONB DEFAULT '[]'::jsonb,
    status TEXT DEFAULT 'pending',
    partner_price_offered DECIMAL(12,2),
    partner_discount DECIMAL(12,2),
    offered_service_id TEXT,
    offered_service_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_collab_packages_owner ON collaborative_packages(owner_vendor_id);
CREATE INDEX IF NOT EXISTS idx_collab_invites_target ON package_collaborator_invitations(target_vendor_id);
CREATE INDEX IF NOT EXISTS idx_collab_invites_package ON package_collaborator_invitations(package_id);

ALTER TABLE collaborative_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE package_collaborator_invitations ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Vendors manage own collaborative packages" ON collaborative_packages;
CREATE POLICY "Vendors manage own collaborative packages" ON collaborative_packages
    FOR ALL USING (
        owner_vendor_id IN (
            SELECT id FROM vendor_profiles
            WHERE user_id = auth.uid() OR id::text = auth.uid()::text
        )
    )
    WITH CHECK (
        owner_vendor_id IN (
            SELECT id FROM vendor_profiles
            WHERE user_id = auth.uid() OR id::text = auth.uid()::text
        )
    );

DROP POLICY IF EXISTS "Vendors view published collaborative packages" ON collaborative_packages;
CREATE POLICY "Vendors view published collaborative packages" ON collaborative_packages
    FOR SELECT USING (is_published = true OR owner_vendor_id IN (
        SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
    ));

DROP POLICY IF EXISTS "Vendors manage package invitations" ON package_collaborator_invitations;
CREATE POLICY "Vendors manage package invitations" ON package_collaborator_invitations
    FOR ALL USING (
        owner_vendor_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid())
        OR target_vendor_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid())
    )
    WITH CHECK (
        owner_vendor_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid())
        OR target_vendor_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid())
    );
