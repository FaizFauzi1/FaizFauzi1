-- ============================================================
-- SERVICE PACKAGES (RICH STRUCTURE)
-- ============================================================

-- 1. Create service_packages table
CREATE TABLE IF NOT EXISTS service_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES vendor_services(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL DEFAULT 0.0,
    duration_minutes INTEGER,
    max_pax INTEGER,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create service_package_items table
CREATE TABLE IF NOT EXISTS service_package_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    package_id UUID NOT NULL REFERENCES service_packages(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    quantity INTEGER DEFAULT 1,
    gallery_urls TEXT[] DEFAULT '{}', -- Array of image URLs specific to this item
    pdf_url TEXT,
    optional_service_id UUID REFERENCES vendor_services(id) ON DELETE SET NULL, -- Link to full service
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create indexes
CREATE INDEX IF NOT EXISTS idx_service_packages_service_id ON service_packages(service_id);
CREATE INDEX IF NOT EXISTS idx_service_package_items_package_id ON service_package_items(package_id);

-- 4. Enable RLS
ALTER TABLE service_packages ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_package_items ENABLE ROW LEVEL SECURITY;

-- 5. Policies for service_packages

-- Public can view active packages
CREATE POLICY "Public can view active packages" ON service_packages
    FOR SELECT USING (is_active = true);

-- Vendors can manage own packages
CREATE POLICY "Vendors can manage own packages" ON service_packages
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_services vs
            JOIN vendor_profiles vp ON vs.vendor_id = vp.id
            WHERE vs.id = service_packages.service_id
            AND vp.user_id = auth.uid()
        )
    );

-- 6. Policies for service_package_items

-- Public can view items of visible packages
CREATE POLICY "Public can view package items" ON service_package_items
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM service_packages sp
            WHERE sp.id = service_package_items.package_id
            AND sp.is_active = true
        )
    );

-- Vendors can manage items of their own packages
CREATE POLICY "Vendors can manage own package items" ON service_package_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM service_packages sp
            JOIN vendor_services vs ON sp.service_id = vs.id
            JOIN vendor_profiles vp ON vs.vendor_id = vp.id
            WHERE sp.id = service_package_items.package_id
            AND vp.user_id = auth.uid()
        )
    );

-- 7. Trigger for updated_at
-- Assuming update_modified_column function exists (standard in our schema)
DROP TRIGGER IF EXISTS update_service_packages_modtime ON service_packages;
CREATE TRIGGER update_service_packages_modtime
    BEFORE UPDATE ON service_packages
    FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

DROP TRIGGER IF EXISTS update_service_package_items_modtime ON service_package_items;
CREATE TRIGGER update_service_package_items_modtime
    BEFORE UPDATE ON service_package_items
    FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
