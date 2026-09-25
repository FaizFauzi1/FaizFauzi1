-- Create vendor_order_settings table for customizing order forms in chat

CREATE TABLE IF NOT EXISTS vendor_order_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    require_event_date BOOLEAN DEFAULT true,
    require_event_time BOOLEAN DEFAULT false,
    require_delivery_address BOOLEAN DEFAULT false,
    require_special_requirements BOOLEAN DEFAULT false,
    show_quantity_field BOOLEAN DEFAULT true,
    show_delivery_method BOOLEAN DEFAULT true,
    default_delivery_method TEXT DEFAULT 'Pickup' CHECK (default_delivery_method IN ('Pickup', 'Delivery')),
    min_order_quantity INTEGER DEFAULT 1,
    max_order_quantity INTEGER DEFAULT 999,
    custom_fields JSONB DEFAULT '[]',
    auto_approve_orders BOOLEAN DEFAULT false,
    order_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vendor_id)
);

-- RLS Policies
ALTER TABLE vendor_order_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors can manage their own order settings" ON vendor_order_settings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_order_settings.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Public can view vendor order settings" ON vendor_order_settings
    FOR SELECT USING (true);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_vendor_order_settings_vendor_id ON vendor_order_settings(vendor_id);

-- Sample data for existing vendors
INSERT INTO vendor_order_settings (vendor_id, order_instructions)
SELECT id, 'Please provide event details and any special requirements.'
FROM vendor_profiles
LIMIT 5
ON CONFLICT (vendor_id) DO NOTHING;
