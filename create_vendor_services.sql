-- ============================================================
-- CREATE TABLE: vendor_services
-- Handles both Services and Products
-- ============================================================

CREATE TABLE IF NOT EXISTS vendor_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL, -- e.g. 'photography', 'catering'
    subcategory TEXT,
    
    -- Pricing
    base_price DECIMAL(10,2) DEFAULT 0.00,
    hourly_rate DECIMAL(10,2),
    currency TEXT DEFAULT 'USD',
    
    -- Status Workflow
    is_active BOOLEAN DEFAULT true, -- Vendor toggle
    approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    service_status TEXT DEFAULT 'draft' CHECK (service_status IN ('active', 'inactive', 'draft', 'maintenance', 'discontinued')),
    
    -- Type & Config
    service_type TEXT DEFAULT 'service' CHECK (service_type IN ('product', 'rental', 'package', 'consultation', 'service')),
    
    -- JSONB for flexible fields
    images TEXT[] DEFAULT '{}',
    availability JSONB DEFAULT '{}',
    options JSONB DEFAULT '{}',
    requirements JSONB DEFAULT '{}',
    logistics JSONB DEFAULT '{}',
    packages JSONB DEFAULT '[]', -- Store sub-packages if simple
    locations TEXT[] DEFAULT '{}',
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_vendor_services_vendor_id ON vendor_services(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_services_category ON vendor_services(category);
CREATE INDEX IF NOT EXISTS idx_vendor_services_status ON vendor_services(service_status);
CREATE INDEX IF NOT EXISTS idx_vendor_services_approval ON vendor_services(approval_status);

-- RLS
ALTER TABLE vendor_services ENABLE ROW LEVEL SECURITY;

-- Policies

-- 1. Public can view APPROVED and ACTIVE services
CREATE POLICY "Public can view active approved services" ON vendor_services
    FOR SELECT USING (
        service_status = 'active' 
        AND approval_status = 'approved'
        AND is_active = true
    );

-- 2. Vendors can manage their OWN services
CREATE POLICY "Vendors can manage their own services" ON vendor_services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_services.vendor_id
            AND user_id = auth.uid()
        )
    );

-- 3. Admins can view/edit ALL services
CREATE POLICY "Admins can manage all services" ON vendor_services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
            AND status = 'active'
        )
    );

-- VIEW for Admin Dashboard (Optional, but helps flatten connection)
-- Can rely on direct table query for now.
