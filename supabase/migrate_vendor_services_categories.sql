-- ============================================================
-- MIGRATION: Add Category Support to Vendor Services
-- This script updates existing vendor_services to work with new category system
-- ============================================================

-- Step 1: Add new columns to vendor_services
ALTER TABLE vendor_services 
    ADD COLUMN IF NOT EXISTS category_id UUID REFERENCES service_categories(id),
    ADD COLUMN IF NOT EXISTS event_types UUID[] DEFAULT '{}';

-- Step 2: Create index for performance
CREATE INDEX IF NOT EXISTS idx_vendor_services_category_id ON vendor_services(category_id);
CREATE INDEX IF NOT EXISTS idx_vendor_services_event_types ON vendor_services USING GIN(event_types);

-- Step 3: Migrate existing category strings to new category_id
-- This will map old text-based categories to new UUID-based categories

DO $$
DECLARE
    v_category_id UUID;
BEGIN
    -- Map 'catering' to new category
    SELECT id INTO v_category_id FROM service_categories WHERE slug = 'catering';
    UPDATE vendor_services SET category_id = v_category_id WHERE LOWER(category) = 'catering' AND category_id IS NULL;
    
    -- Map 'photography' to new category
    SELECT id INTO v_category_id FROM service_categories WHERE slug = 'photography';
    UPDATE vendor_services SET category_id = v_category_id WHERE LOWER(category) = 'photography' AND category_id IS NULL;
    
    -- Map 'videography' to new category
    SELECT id INTO v_category_id FROM service_categories WHERE slug = 'videography';
    UPDATE vendor_services SET category_id = v_category_id WHERE LOWER(category) = 'videography' AND category_id IS NULL;
    
    -- Map 'venue' to new category
    SELECT id INTO v_category_id FROM service_categories WHERE slug = 'venue';
    UPDATE vendor_services SET category_id = v_category_id WHERE LOWER(category) IN ('venue', 'venues') AND category_id IS NULL;
    
    -- Map 'decoration' to new category
    SELECT id INTO v_category_id FROM service_categories WHERE slug = 'decoration';
    UPDATE vendor_services SET category_id = v_category_id WHERE LOWER(category) = 'decoration' AND category_id IS NULL;
    
    -- Map 'entertainment' to new category
    SELECT id INTO v_category_id FROM service_categories WHERE slug = 'live-band';
    UPDATE vendor_services SET category_id = v_category_id WHERE LOWER(category) = 'entertainment' AND category_id IS NULL;
    
    -- Map 'fashion' to bridal attire
    SELECT id INTO v_category_id FROM service_categories WHERE slug = 'bridal-attire';
    UPDATE vendor_services SET category_id = v_category_id WHERE LOWER(category) IN ('fashion', 'attire') AND category_id IS NULL;
    
    RAISE NOTICE 'Category migration completed';
END $$;

-- Step 4: Set default event types based on category
-- If a service has a category but no event types, assign default event types

DO $$
DECLARE
    wedding_id UUID;
    corporate_id UUID;
    birthday_id UUID;
BEGIN
    -- Get event type IDs
    SELECT id INTO wedding_id FROM event_types WHERE name = 'Wedding';
    SELECT id INTO corporate_id FROM event_types WHERE name = 'Corporate Event';
    SELECT id INTO birthday_id FROM event_types WHERE name = 'Birthday Party';
    
    -- Assign wedding event type to wedding-related categories
    UPDATE vendor_services vs
    SET event_types = ARRAY[wedding_id]
    WHERE vs.category_id IN (
        SELECT id FROM service_categories 
        WHERE slug IN ('wedding-package', 'bridal-attire', 'groom-attire', 'wedding-decoration', 'pelamin', 'wedding-cake', 'bridal-assistant', 'wedding-planner')
    )
    AND vs.event_types = '{}';
    
    -- Assign corporate event type to corporate-related categories
    UPDATE vendor_services vs
    SET event_types = ARRAY[corporate_id]
    WHERE vs.category_id IN (
        SELECT id FROM service_categories 
        WHERE slug IN ('corporate-package', 'conference-hall', 'keynote-speaker', 'booth-design')
    )
    AND vs.event_types = '{}';
    
    -- Assign multiple event types to common categories (venue, catering, photography, etc.)
    UPDATE vendor_services vs
    SET event_types = ARRAY[wedding_id, corporate_id, birthday_id]
    WHERE vs.category_id IN (
        SELECT id FROM service_categories 
        WHERE slug IN ('venue', 'catering', 'photography', 'videography', 'live-streaming', 'decoration', 'floral-arrangement', 'pa-system', 'lighting', 'led-screen')
    )
    AND vs.event_types = '{}';
    
    RAISE NOTICE 'Event type assignment completed';
END $$;

-- Step 5: Report migration statistics
DO $$
DECLARE
    total_services INTEGER;
    migrated_services INTEGER;
    unmigrated_services INTEGER;
BEGIN
    SELECT COUNT(*) INTO total_services FROM vendor_services;
    SELECT COUNT(*) INTO migrated_services FROM vendor_services WHERE category_id IS NOT NULL;
    SELECT COUNT(*) INTO unmigrated_services FROM vendor_services WHERE category_id IS NULL;
    
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'MIGRATION STATISTICS';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Total services: %', total_services;
    RAISE NOTICE 'Migrated services: %', migrated_services;
    RAISE NOTICE 'Unmigrated services: %', unmigrated_services;
    RAISE NOTICE '===========================================';
END $$;

-- Step 6: List unmigrated services for manual review
SELECT 
    id,
    name,
    category as old_category,
    vendor_id
FROM vendor_services 
WHERE category_id IS NULL
ORDER BY created_at DESC
LIMIT 20;

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- View services with new category system
-- SELECT 
--     vs.name as service_name,
--     vs.category as old_category,
--     sc.name as new_category,
--     sc.category_type,
--     sc.pricing_model,
--     array_length(vs.event_types, 1) as event_type_count
-- FROM vendor_services vs
-- LEFT JOIN service_categories sc ON vs.category_id = sc.id
-- ORDER BY vs.created_at DESC
-- LIMIT 50;

-- Count services per category
-- SELECT 
--     sc.name as category,
--     COUNT(vs.id) as service_count
-- FROM service_categories sc
-- LEFT JOIN vendor_services vs ON sc.id = vs.category_id
-- GROUP BY sc.id, sc.name
-- ORDER BY service_count DESC;
