-- ============================================================
-- Service Template Schema
-- Adds structured data support for Vendor Services
-- ============================================================

-- 1. Service Pricing Tiers (for Packages / Tiered Pricing)
CREATE TABLE IF NOT EXISTS service_pricing_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES vendor_services(id) ON DELETE CASCADE,
    name TEXT, -- Optional name for the tier (e.g., "Silver", "Gold", "500 Pax")
    min_pax INTEGER NOT NULL DEFAULT 0,
    max_pax INTEGER, -- NULL means infinity/unlimited
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index for fast lookup
CREATE INDEX IF NOT EXISTS idx_pricing_service_id ON service_pricing_tiers(service_id);

-- 2. Service Components (Categories within a service, e.g. "Decoration", "Catering")
CREATE TABLE IF NOT EXISTS service_components (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES vendor_services(id) ON DELETE CASCADE,
    component_type TEXT NOT NULL, -- e.g., 'decoration', 'catering', 'hall', 'photography'
    name TEXT NOT NULL, -- e.g. "Main Hall Decor", "Buffet Menu A"
    description TEXT,
    is_optional BOOLEAN DEFAULT false,
    selection_type TEXT DEFAULT 'fixed', -- 'fixed', 'single_choice', 'multiple_choice' (for future use)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_components_service_id ON service_components(service_id);

-- 3. Service Items (Specific items within a component)
CREATE TABLE IF NOT EXISTS service_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    component_id UUID NOT NULL REFERENCES service_components(id) ON DELETE CASCADE,
    name TEXT NOT NULL, -- e.g. "Pelamin 20ft", "Ayam Masak Merah"
    description TEXT,
    quantity INTEGER DEFAULT 1,
    unit_price DECIMAL(10,2) DEFAULT 0.00, -- Used if it's an add-on or has specific value
    is_included BOOLEAN DEFAULT true, -- true = part of package, false = add-on
    image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Index
CREATE INDEX IF NOT EXISTS idx_items_component_id ON service_items(component_id);


-- ============================================================
-- POLICIES (Row Level Security)
-- ============================================================

ALTER TABLE service_pricing_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_components ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_items ENABLE ROW LEVEL SECURITY;

-- Pricing Tiers Policies
CREATE POLICY "Public read pricing" ON service_pricing_tiers FOR SELECT USING (true);
CREATE POLICY "Vendor manage pricing" ON service_pricing_tiers FOR ALL USING (
    EXISTS (
        SELECT 1 FROM vendor_services 
        JOIN vendor_profiles ON vendor_services.vendor_id = vendor_profiles.id
        WHERE vendor_services.id = service_pricing_tiers.service_id 
        AND vendor_profiles.user_id = auth.uid()
    )
);

-- Components Policies
CREATE POLICY "Public read components" ON service_components FOR SELECT USING (true);
CREATE POLICY "Vendor manage components" ON service_components FOR ALL USING (
    EXISTS (
        SELECT 1 FROM vendor_services 
        JOIN vendor_profiles ON vendor_services.vendor_id = vendor_profiles.id
        WHERE vendor_services.id = service_components.service_id 
        AND vendor_profiles.user_id = auth.uid()
    )
);

-- Items Policies
CREATE POLICY "Public read items" ON service_items FOR SELECT USING (true);
CREATE POLICY "Vendor manage items" ON service_items FOR ALL USING (
    EXISTS (
        SELECT 1 FROM service_components
        JOIN vendor_services ON service_components.service_id = vendor_services.id
        JOIN vendor_profiles ON vendor_services.vendor_id = vendor_profiles.id
        WHERE service_components.id = service_items.component_id 
        AND vendor_profiles.user_id = auth.uid()
    )
);
