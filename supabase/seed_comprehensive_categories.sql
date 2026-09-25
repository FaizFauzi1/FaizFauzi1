-- ============================================================
-- COMPREHENSIVE EVENT TYPE & CATEGORY SEEDING
-- EventEase - Complete Category System
-- ============================================================

-- First, ensure event_types table has the necessary columns
ALTER TABLE event_types ADD COLUMN IF NOT EXISTS category_group TEXT;
ALTER TABLE event_types ADD COLUMN IF NOT EXISTS is_enabled BOOLEAN DEFAULT true;
ALTER TABLE event_types ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';

-- ============================================================
-- SEED EVENT TYPES (15 Types)
-- ============================================================

INSERT INTO event_types (name, description, category, category_group, is_enabled, display_order, metadata) VALUES
-- Social Events
('Wedding', 'Traditional and modern wedding ceremonies', 'wedding', 'social', true, 1, '{"icon": "favorite", "color": "#E91E63"}'),
('Engagement', 'Engagement ceremonies and majlis pertunangan', 'engagement', 'social', true, 2, '{"icon": "favorite_border", "color": "#F06292"}'),
('Birthday Party', 'Birthday celebrations and private parties', 'birthday', 'social', true, 3, '{"icon": "cake", "color": "#FF9800"}'),
('Anniversary', 'Anniversary celebrations and milestones', 'anniversary', 'social', true, 4, '{"icon": "celebration", "color": "#9C27B0"}'),
('Baby Shower', 'Baby showers and gender reveal parties', 'baby_shower', 'social', true, 5, '{"icon": "child_care", "color": "#81C784"}'),

-- Corporate Events
('Corporate Event', 'Corporate functions and business events', 'corporate', 'corporate', true, 10, '{"icon": "business", "color": "#2196F3"}'),
('Conference', 'Conferences, seminars, and workshops', 'conference', 'corporate', true, 11, '{"icon": "groups", "color": "#1976D2"}'),
('Product Launch', 'Product launches and brand activations', 'product_launch', 'corporate', true, 12, '{"icon": "rocket_launch", "color": "#00BCD4"}'),

-- Community Events
('Expo', 'Expos, fairs, and bazaars', 'expo', 'community', true, 20, '{"icon": "store", "color": "#4CAF50"}'),
('Festival', 'Festivals and carnivals', 'festival', 'community', true, 21, '{"icon": "festival", "color": "#FF5722"}'),
('Charity Event', 'Charity and fundraising events', 'charity', 'community', true, 22, '{"icon": "volunteer_activism", "color": "#E91E63"}'),
('Sports Event', 'Sports tournaments and competitions', 'sports', 'community', true, 23, '{"icon": "sports", "color": "#FF9800"}'),

-- Cultural & Educational
('Religious Event', 'Religious and cultural ceremonies', 'religious', 'cultural', true, 30, '{"icon": "mosque", "color": "#009688"}'),
('Graduation', 'Graduation ceremonies and convocations', 'graduation', 'educational', true, 31, '{"icon": "school", "color": "#3F51B5"}'),

-- Sensitive
('Funeral', 'Funeral and memorial services', 'funeral', 'memorial', true, 40, '{"icon": "local_florist", "color": "#757575"}'),

-- Expanded
('Party', 'General parties and gatherings', 'party', 'social', true, 6, '{"icon": "party_mode", "color": "#FF9800"}'),
('Seminar', 'Seminars and educational talks', 'seminar', 'educational', true, 13, '{"icon": "school", "color": "#3F51B5"}'),
('Retirement', 'Retirement parties', 'retirement', 'social', true, 7, '{"icon": "emoji_events", "color": "#9C27B0"}')

ON CONFLICT (name) DO UPDATE SET
  description = EXCLUDED.description,
  category = EXCLUDED.category,
  category_group = EXCLUDED.category_group,
  is_enabled = EXCLUDED.is_enabled,
  display_order = EXCLUDED.display_order,
  metadata = EXCLUDED.metadata;

-- ============================================================
-- CREATE SERVICE CATEGORIES TABLE (if not exists)
-- ============================================================

CREATE TABLE IF NOT EXISTS service_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    description TEXT,
    
    -- Category Classification
    category_type TEXT NOT NULL CHECK (category_type IN ('service', 'product', 'package', 'rental')),
    pricing_model TEXT NOT NULL CHECK (pricing_model IN ('per_pax', 'per_day', 'per_session', 'fixed', 'per_hour', 'per_trip')),
    
    -- Visibility & Access Control
    is_active BOOLEAN DEFAULT true,
    is_advanced BOOLEAN DEFAULT false,
    requires_verification BOOLEAN DEFAULT false,
    min_vendor_tier TEXT DEFAULT 'basic' CHECK (min_vendor_tier IN ('basic', 'verified', 'premium')),
    
    -- Display
    icon_name TEXT,
    icon_code INTEGER,
    color_hex TEXT,
    display_order INTEGER DEFAULT 0,
    
    -- Metadata
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Update constraint if table already exists (to support per_trip)
DO $$
BEGIN
    -- Check if constraint exists and drop it to ensure we have the latest definition
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'service_categories_pricing_model_check') THEN
        ALTER TABLE service_categories DROP CONSTRAINT service_categories_pricing_model_check;
    END IF;
    
    -- Add the constraint with per_trip included
    ALTER TABLE service_categories ADD CONSTRAINT service_categories_pricing_model_check 
    CHECK (pricing_model IN ('per_pax', 'per_day', 'per_session', 'fixed', 'per_hour', 'per_trip'));
END $$;

-- Create event_type_categories junction table
CREATE TABLE IF NOT EXISTS event_type_categories (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type_id UUID NOT NULL REFERENCES event_types(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES service_categories(id) ON DELETE CASCADE,
    is_primary BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(event_type_id, category_id)
);

-- ============================================================
-- SEED SERVICE CATEGORIES
-- ============================================================

-- Helper function to insert category
CREATE OR REPLACE FUNCTION insert_category(
    p_name TEXT,
    p_slug TEXT,
    p_description TEXT,
    p_category_type TEXT,
    p_pricing_model TEXT,
    p_is_advanced BOOLEAN DEFAULT false,
    p_icon_name TEXT DEFAULT 'category',
    p_color_hex TEXT DEFAULT '#2196F3'
) RETURNS UUID AS $$
DECLARE
    v_category_id UUID;
BEGIN
    INSERT INTO service_categories (name, slug, description, category_type, pricing_model, is_advanced, icon_name, color_hex)
    VALUES (p_name, p_slug, p_description, p_category_type, p_pricing_model, p_is_advanced, p_icon_name, p_color_hex)
    ON CONFLICT (slug) DO UPDATE SET
        name = EXCLUDED.name,
        description = EXCLUDED.description,
        category_type = EXCLUDED.category_type,
        pricing_model = EXCLUDED.pricing_model,
        is_advanced = EXCLUDED.is_advanced,
        icon_name = EXCLUDED.icon_name,
        color_hex = EXCLUDED.color_hex
    RETURNING id INTO v_category_id;
    
    RETURN v_category_id;
END;
$$ LANGUAGE plpgsql;

-- ============================================================
-- COMMON CATEGORIES (Used across multiple event types)
-- ============================================================

DO $$
DECLARE
    -- Common category IDs
    cat_venue UUID;
    cat_catering UUID;
    cat_photography UUID;
    cat_videography UUID;
    cat_live_streaming UUID;
    cat_emcee UUID;
    cat_pa_system UUID;
    cat_lighting UUID;
    cat_led_screen UUID;
    cat_decoration UUID;
    cat_floral UUID;
    cat_transportation UUID;
    cat_security UUID;
    cat_event_coordinator UUID;
    cat_drone UUID;
    cat_projector UUID;
    cat_sound_system UUID;
    cat_dj UUID;
    
    -- Event type IDs
    evt_wedding UUID;
    evt_engagement UUID;
    evt_birthday UUID;
    evt_anniversary UUID;
    evt_baby_shower UUID;
    evt_corporate UUID;
    evt_conference UUID;
    evt_product_launch UUID;
    evt_expo UUID;
    evt_festival UUID;
    evt_charity UUID;
    evt_sports UUID;
    evt_religious UUID;
    evt_graduation UUID;
    evt_funeral UUID;
    evt_party UUID;
    evt_seminar UUID;
    evt_retirement UUID;
BEGIN
    -- Get event type IDs
    SELECT id INTO evt_wedding FROM event_types WHERE name = 'Wedding';
    SELECT id INTO evt_engagement FROM event_types WHERE name = 'Engagement';
    SELECT id INTO evt_birthday FROM event_types WHERE name = 'Birthday Party';
    SELECT id INTO evt_anniversary FROM event_types WHERE name = 'Anniversary';
    SELECT id INTO evt_baby_shower FROM event_types WHERE name = 'Baby Shower';
    SELECT id INTO evt_corporate FROM event_types WHERE name = 'Corporate Event';
    SELECT id INTO evt_conference FROM event_types WHERE name = 'Conference';
    SELECT id INTO evt_product_launch FROM event_types WHERE name = 'Product Launch';
    SELECT id INTO evt_expo FROM event_types WHERE name = 'Expo';
    SELECT id INTO evt_festival FROM event_types WHERE name = 'Festival';
    SELECT id INTO evt_charity FROM event_types WHERE name = 'Charity Event';
    SELECT id INTO evt_sports FROM event_types WHERE name = 'Sports Event';
    SELECT id INTO evt_religious FROM event_types WHERE name = 'Religious Event';
    SELECT id INTO evt_graduation FROM event_types WHERE name = 'Graduation';
    SELECT id INTO evt_funeral FROM event_types WHERE name = 'Funeral';
    SELECT id INTO evt_party FROM event_types WHERE name = 'Party';
    SELECT id INTO evt_seminar FROM event_types WHERE name = 'Seminar';
    SELECT id INTO evt_retirement FROM event_types WHERE name = 'Retirement';
    
    -- Insert common categories
    cat_venue := insert_category('Venue', 'venue', 'Event venues and halls', 'service', 'per_day', false, 'location_on', '#4CAF50');
    cat_catering := insert_category('Catering', 'catering', 'Food and beverage services', 'service', 'per_pax', false, 'restaurant', '#FF9800');
    cat_photography := insert_category('Photography', 'photography', 'Professional photography services', 'service', 'per_session', false, 'camera_alt', '#2196F3');
    cat_videography := insert_category('Videography', 'videography', 'Professional videography services', 'service', 'per_session', false, 'videocam', '#9C27B0');
    cat_live_streaming := insert_category('Live Streaming', 'live-streaming', 'Live streaming services', 'service', 'per_session', false, 'live_tv', '#E91E63');
    cat_emcee := insert_category('Emcee / Host', 'emcee', 'Event emcee and hosting services', 'service', 'per_session', false, 'mic', '#FF5722');
    cat_pa_system := insert_category('PA System', 'pa-system', 'Sound system rental and setup', 'rental', 'per_day', false, 'speaker', '#607D8B');
    cat_lighting := insert_category('Lighting', 'lighting', 'Event lighting services', 'rental', 'per_day', false, 'lightbulb', '#FFC107');
    cat_led_screen := insert_category('LED Screen', 'led-screen', 'LED screen rental and setup', 'rental', 'per_day', false, 'tv', '#3F51B5');
    cat_decoration := insert_category('Decoration', 'decoration', 'Event decoration services', 'service', 'fixed', false, 'celebration', '#E91E63');
    cat_floral := insert_category('Floral Arrangement', 'floral-arrangement', 'Flower arrangements and bouquets', 'service', 'fixed', false, 'local_florist', '#4CAF50');
    cat_transportation := insert_category('Transportation', 'transportation', 'Event transportation services', 'service', 'per_day', true, 'directions_car', '#00BCD4');
    cat_security := insert_category('Security Services', 'security', 'Event security and safety', 'service', 'per_day', true, 'security', '#795548');
    cat_event_coordinator := insert_category('Event Coordinator', 'event-coordinator', 'Professional event coordination', 'service', 'per_session', false, 'event', '#673AB7');
    cat_drone := insert_category('Drone Photography', 'drone-photography', 'Aerial drone photography', 'service', 'per_session', false, 'flight', '#2196F3');
    cat_projector := insert_category('Projector', 'projector', 'Projector and screen rental', 'rental', 'per_day', false, 'present_to_all', '#607D8B');
    cat_dj := insert_category('DJ', 'dj', 'DJ services', 'service', 'per_session', false, 'album', '#9C27B0');

    -- ============================================================
    -- 1. WEDDING EVENTS 💍
    -- ============================================================
    
    -- Core
    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_wedding, cat_venue, true, 1),
    (evt_wedding, cat_catering, true, 2),
    (evt_wedding, insert_category('Wedding Package', 'wedding-package', 'All-in wedding packages', 'package', 'fixed', false, 'card_giftcard', '#E91E63'), true, 3),
    (evt_wedding, insert_category('Bridal Assistant', 'bridal-assistant', 'Bridal assistant / coordinator', 'service', 'per_session', false, 'support_agent', '#F06292'), true, 4),
    (evt_wedding, insert_category('Wedding Planner', 'wedding-planner', 'Full wedding planning', 'service', 'fixed', false, 'event_note', '#C2185B'), true, 5)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- Media
    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_wedding, cat_photography, true, 10),
    (evt_wedding, cat_videography, true, 11),
    (evt_wedding, cat_live_streaming, true, 12),
    (evt_wedding, insert_category('Same-Day Edit', 'same-day-edit', 'Same-day video edit', 'service', 'per_session', false, 'movie', '#9C27B0'), true, 13),
    (evt_wedding, cat_drone, true, 14)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- Attire & Beauty
    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_wedding, insert_category('Bridal Attire', 'bridal-attire', 'Bridal gowns / Busana Pengantin', 'rental', 'per_day', false, 'checkroom', '#F06292'), true, 20),
    (evt_wedding, insert_category('Groom Attire', 'groom-attire', 'Groom suits', 'rental', 'per_day', false, 'checkroom', '#1976D2'), true, 21),
    (evt_wedding, insert_category('Makeup Artist', 'makeup-artist', 'Professional MUA', 'service', 'per_session', false, 'face', '#FF69B4'), true, 22),
    (evt_wedding, insert_category('Hair Stylist', 'hair-stylist', 'Professional hair styling', 'service', 'per_session', false, 'content_cut', '#FF1744'), true, 23),
    (evt_wedding, insert_category('Henna Artist', 'henna-artist', 'Henna / Inai artist', 'service', 'per_session', false, 'brush', '#8D6E63'), true, 24),
    (evt_wedding, insert_category('Bridal Accessories', 'bridal-accessories', 'Accessories and jewelry', 'rental', 'per_day', false, 'diamond', '#FFD700'), false, 25)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- Decoration
    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_wedding, insert_category('Wedding Decoration', 'wedding-decoration', 'Detailed wedding decoration', 'service', 'fixed', false, 'celebration', '#E91E63'), true, 30),
    (evt_wedding, insert_category('Pelamin', 'pelamin', 'Pelamin / Dais setup', 'service', 'fixed', false, 'chair', '#D32F2F'), true, 31),
    (evt_wedding, cat_floral, true, 32),
    (evt_wedding, insert_category('Table & Chair Rental', 'table-chair-rental', 'Table and chair rental', 'rental', 'per_day', false, 'event_seat', '#607D8B'), true, 33),
    (evt_wedding, insert_category('Canopy', 'canopy', 'Canopy / Khemah rental', 'rental', 'per_day', false, 'roofing', '#795548'), true, 34),
    (evt_wedding, insert_category('Backdrop', 'backdrop', 'Backdrop design', 'service', 'fixed', false, 'wallpaper', '#9C27B0'), true, 35)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- Gifts & Favors
    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_wedding, insert_category('Door Gift', 'door-gift', 'Door gifts / Bunga telur', 'product', 'fixed', false, 'card_giftcard', '#FF9800'), false, 40),
    (evt_wedding, insert_category('Wedding Favors', 'wedding-favors', 'Wedding favors', 'product', 'fixed', false, 'redeem', '#4CAF50'), false, 41),
    (evt_wedding, insert_category('Wedding Cake', 'wedding-cake', 'Wedding cakes', 'product', 'fixed', false, 'cake', '#FF6F00'), false, 42),
    (evt_wedding, insert_category('Dessert Table', 'dessert-table', 'Dessert table / candy bar', 'service', 'fixed', false, 'bakery_dining', '#E91E63'), false, 43),
    (evt_wedding, insert_category('Chocolate Bouquet', 'chocolate-bouquet', 'Chocolate bouquets', 'product', 'fixed', false, 'local_florist', '#795548'), false, 44)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- Entertainment
    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_wedding, cat_emcee, false, 50),
    (evt_wedding, insert_category('Live Band', 'live-band', 'Live band performance', 'service', 'per_session', false, 'music_note', '#FF5722'), false, 51),
    (evt_wedding, cat_dj, false, 52),
    (evt_wedding, insert_category('Kompang', 'kompang', 'Kompang / Hadrah', 'service', 'per_session', false, 'music_note', '#8D6E63'), false, 53),
    (evt_wedding, insert_category('Traditional Dance', 'traditional-dance', 'Silat / Zapin perfomance', 'service', 'per_session', false, 'sports_martial_arts', '#D32F2F'), false, 54),
    (evt_wedding, insert_category('Singer', 'singer', 'Singer / Vocalist', 'service', 'per_session', false, 'mic_external_on', '#E91E63'), false, 55)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- Logistics
    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_wedding, insert_category('Bridal Car', 'bridal-car', 'Bridal car rental', 'rental', 'per_day', true, 'directions_car', '#E91E63'), false, 60),
    (evt_wedding, insert_category('Guest Shuttle', 'guest-shuttle', 'Guest shuttle service', 'service', 'per_day', true, 'airport_shuttle', '#2196F3'), false, 61),
    (evt_wedding, insert_category('Valet Parking', 'valet-parking', 'Valet parking services', 'service', 'per_session', false, 'local_parking', '#607D8B'), false, 62),
    (evt_wedding, insert_category('Accommodation', 'accommodation', 'Homestay / Accommodation', 'service', 'per_day', true, 'hotel', '#4CAF50'), false, 63),
    (evt_wedding, cat_security, false, 64)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- Technical
    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_wedding, cat_pa_system, false, 70),
    (evt_wedding, cat_lighting, false, 71),
    (evt_wedding, cat_led_screen, false, 72),
    (evt_wedding, insert_category('Power Generator', 'power-generator', 'Power generator', 'rental', 'per_day', true, 'power', '#FF9800'), false, 73),
    (evt_wedding, insert_category('Stage Setup', 'stage-setup', 'Stage setup', 'service', 'fixed', false, 'layers', '#795548'), false, 74)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- Stationery
    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_wedding, insert_category('Wedding Invitation', 'wedding-invitation', 'Invitation cards', 'product', 'fixed', false, 'mail', '#E91E63'), false, 80),
    (evt_wedding, insert_category('Guest Book', 'guest-book', 'Guest book', 'product', 'fixed', false, 'book', '#795548'), false, 81),
    (evt_wedding, insert_category('Signage', 'signage', 'Signage / Bunting', 'product', 'fixed', false, 'signpost', '#607D8B'), false, 82),
    (evt_wedding, insert_category('Menu Cards', 'menu-cards', 'Menu cards', 'product', 'fixed', false, 'restaurant_menu', '#4CAF50'), false, 83),
    (evt_wedding, insert_category('Thank You Cards', 'thank-you-cards', 'Thank you cards', 'product', 'fixed', false, 'favorite', '#F44336'), false, 84)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 2. CORPORATE EVENTS 💼
    -- ============================================================
    
    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_corporate, insert_category('Conference Hall', 'conference-hall', 'Venue / Conference Hall', 'service', 'per_day', false, 'meeting_room', '#2196F3'), true, 1),
    (evt_corporate, cat_catering, true, 2),
    (evt_corporate, insert_category('Corporate Package', 'corporate-package', 'Corporate event package', 'package', 'fixed', false, 'business_center', '#1976D2'), true, 3),
    (evt_corporate, insert_category('Event Management', 'event-management', 'Professional event management', 'service', 'fixed', false, 'manage_accounts', '#3F51B5'), true, 4),
    (evt_corporate, cat_event_coordinator, true, 5),
    
    (evt_corporate, cat_photography, true, 10),
    (evt_corporate, cat_videography, true, 11),
    (evt_corporate, cat_live_streaming, true, 12),
    (evt_corporate, insert_category('Event Recording', 'event-recording', 'Full event recording', 'service', 'per_session', false, 'videocam', '#FF5722'), true, 13),
    (evt_corporate, insert_category('Highlight Video', 'highlight-video', 'Event highlight video', 'service', 'per_session', false, 'movie_filter', '#E91E63'), true, 14),
    
    (evt_corporate, cat_emcee, true, 20),
    (evt_corporate, insert_category('Moderator', 'moderator', 'Moderator', 'service', 'per_session', false, 'record_voice_over', '#9C27B0'), true, 21),
    (evt_corporate, insert_category('Keynote Speaker', 'keynote-speaker', 'Keynote speaker', 'service', 'per_session', false, 'campaign', '#FF9800'), true, 22),
    (evt_corporate, insert_category('Trainer', 'trainer', 'Trainer / Facilitator', 'service', 'per_session', false, 'school', '#4CAF50'), true, 23),
    
    (evt_corporate, cat_pa_system, true, 30),
    (evt_corporate, cat_lighting, true, 31),
    (evt_corporate, cat_led_screen, true, 32),
    (evt_corporate, cat_projector, true, 33),
    (evt_corporate, insert_category('Hybrid Setup', 'hybrid-setup', 'Hybrid meeting setup', 'service', 'fixed', false, 'settings_input_antenna', '#607D8B'), true, 34),
    (evt_corporate, insert_category('WiFi Rental', 'wifi-rental', 'Internet / WiFi rental', 'rental', 'per_day', false, 'wifi', '#00BCD4'), false, 35),
    
    (evt_corporate, insert_category('Booth Design', 'booth-design', 'Booth design', 'service', 'fixed', false, 'store', '#4CAF50'), false, 40),
    (evt_corporate, insert_category('Booth Construction', 'booth-construction', 'Booth construction', 'service', 'fixed', false, 'build', '#795548'), false, 41),
    
    (evt_corporate, cat_transportation, false, 50),
    (evt_corporate, insert_category('Registration System', 'registration-system', 'Registration system', 'service', 'per_session', false, 'how_to_reg', '#00BCD4'), false, 51)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 3. BIRTHDAY & PRIVATE PARTIES 🎂
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_birthday, insert_category('Party Venue', 'party-venue', 'Party venue', 'service', 'per_day', false, 'celebration', '#FF9800'), true, 1),
    (evt_birthday, insert_category('Party Package', 'party-package', 'Party package', 'package', 'fixed', false, 'cake', '#E91E63'), true, 2),
    (evt_birthday, cat_catering, true, 3),
    (evt_birthday, cat_event_coordinator, true, 4),
    
    (evt_birthday, insert_category('Party Decoration', 'party-decoration', 'Party decoration', 'service', 'fixed', false, 'celebration', '#FF5722'), true, 10),
    (evt_birthday, insert_category('Balloon Styling', 'balloon-styling', 'Balloon styling', 'service', 'fixed', false, 'bubble_chart', '#9C27B0'), true, 11),
    (evt_birthday, insert_category('Theme Setup', 'theme-setup', 'Theme setup', 'service', 'fixed', false, 'auto_fix_high', '#673AB7'), true, 12),
    
    (evt_birthday, insert_category('Birthday Cake', 'birthday-cake', 'Birthday cake', 'product', 'fixed', false, 'cake', '#FF6F00'), true, 20),
    (evt_birthday, insert_category('Cupcakes', 'cupcakes', 'Cupcakes / Treats', 'product', 'fixed', false, 'cookie', '#FFAB00'), true, 21),
    
    (evt_birthday, insert_category('Clown', 'clown', 'Clown / Magician', 'service', 'per_session', false, 'face', '#FF5722'), true, 30),
    (evt_birthday, insert_category('Mascot', 'mascot', 'Mascot character', 'service', 'per_session', false, 'pets', '#4CAF50'), true, 31),
    (evt_birthday, insert_category('Face Painting', 'face-painting', 'Face painting', 'service', 'per_session', false, 'brush', '#E91E63'), true, 32),
    (evt_birthday, insert_category('Bouncy Castle', 'bouncy-castle', 'Bouncy castle', 'rental', 'per_day', false, 'home', '#2196F3'), false, 33),
    
    (evt_birthday, cat_photography, false, 40),
    (evt_birthday, insert_category('Photo Booth', 'photo-booth', 'Photo booth', 'rental', 'per_day', false, 'photo_camera', '#9C27B0'), false, 41),
    
    (evt_birthday, insert_category('Party Favors', 'party-favors', 'Party favors / Goody bags', 'product', 'fixed', false, 'card_giftcard', '#8BC34A'), false, 50),
    (evt_birthday, insert_category('Piñata', 'pinata', 'Piñata', 'product', 'fixed', false, 'sports_baseball', '#F44336'), false, 51)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 4. EXPO / FAIR / BAZAAR 🏪
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_expo, insert_category('Booth Rental', 'booth-rental', 'Booth rental', 'rental', 'per_day', false, 'store', '#4CAF50'), true, 1),
    (evt_expo, insert_category('Event Organizer', 'event-organizer', 'Event organizer', 'service', 'fixed', false, 'manage_accounts', '#3F51B5'), true, 2),
    
    (evt_expo, insert_category('Tent Rental', 'tent-rental', 'Tent / Canopy', 'rental', 'per_day', false, 'roofing', '#795548'), true, 10),
    (evt_expo, insert_category('Display Shelving', 'display-shelving', 'Display shelving', 'rental', 'per_day', false, 'shelves', '#607D8B'), true, 11),
    
    (evt_expo, cat_pa_system, true, 20),
    (evt_expo, cat_security, false, 30),
    (evt_expo, insert_category('Cleaning Services', 'cleaning-services', 'Cleaning services', 'service', 'per_day', false, 'cleaning_services', '#009688'), false, 31)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 5. CONFERENCE / SEMINAR / WORKSHOP 📚
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_conference, insert_category('Seminar Room', 'seminar-room', 'Seminar room / Venue', 'service', 'per_day', false, 'meeting_room', '#2196F3'), true, 1),
    (evt_conference, insert_category('Training Package', 'training-package', 'Training package', 'package', 'fixed', false, 'school', '#3F51B5'), true, 2),
    (evt_conference, cat_event_coordinator, true, 3),
    
    (evt_conference, insert_category('Workshop Facilitator', 'workshop-facilitator', 'Workshop facilitator', 'service', 'per_session', false, 'person_add', '#4CAF50'), true, 10),
    
    (evt_conference, cat_pa_system, true, 20),
    (evt_conference, cat_projector, true, 21),
    (evt_conference, insert_category('Microphones', 'microphones', 'Microphones', 'rental', 'per_day', false, 'mic', '#FF5722'), true, 22),
    
    (evt_conference, insert_category('Training Materials', 'training-materials', 'Training materials', 'product', 'fixed', false, 'menu_book', '#795548'), false, 30),
    (evt_conference, insert_category('Name Tags', 'name-tags', 'Name tags / Lanyards', 'product', 'fixed', false, 'badge', '#607D8B'), false, 31),
    (evt_conference, insert_category('Certificates', 'certificates', 'Certificate printing', 'product', 'fixed', false, 'card_membership', '#FFC107'), false, 32),
    
    (evt_conference, insert_category('Coffee Break', 'coffee-break', 'Coffee / Tea break', 'service', 'per_pax', false, 'coffee', '#795548'), true, 40)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 6. RELIGIOUS & CULTURAL EVENTS 🕌
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_religious, cat_venue, true, 1),
    (evt_religious, cat_catering, true, 2),
    
    (evt_religious, insert_category('Imam', 'imam', 'Imam / Tok Kadi / Priest', 'service', 'per_session', false, 'person', '#4CAF50'), true, 10),
    (evt_religious, insert_category('Doa Reader', 'doa-reader', 'Doa / Prayer leader', 'service', 'per_session', false, 'record_voice_over', '#009688'), true, 11),
    (evt_religious, insert_category('Nasyid Group', 'nasyid-group', 'Nasyid group', 'service', 'per_session', false, 'groups', '#3F51B5'), true, 12),
    
    (evt_religious, insert_category('Cultural Decoration', 'cultural-decoration', 'Cultural decoration', 'service', 'fixed', false, 'celebration', '#E91E63'), false, 20)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 7. GRADUATION CEREMONIES 🎓
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_graduation, cat_venue, true, 1),
    (evt_graduation, insert_category('Graduation Package', 'graduation-package', 'Graduation package', 'package', 'fixed', false, 'school', '#3F51B5'), true, 2),
    
    (evt_graduation, insert_category('Graduation Gown', 'graduation-gown', 'Gown rental', 'rental', 'per_day', false, 'checkroom', '#1976D2'), true, 10),
    (evt_graduation, insert_category('Mortarboard', 'mortarboard', 'Mortarboard / Cap', 'rental', 'per_day', false, 'school', '#3F51B5'), true, 11),
    
    (evt_graduation, cat_photography, true, 20),
    (evt_graduation, insert_category('Graduation Gifts', 'graduation-gifts', 'Graduation gifts', 'product', 'fixed', false, 'card_giftcard', '#FF9800'), false, 30),
    (evt_graduation, insert_category('Flower Bouquet', 'flower-bouquet', 'Flower bouquet', 'product', 'fixed', false, 'local_florist', '#E91E63'), false, 31)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 8. PRODUCT LAUNCH / BRAND ACTIVATION 🚀
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_product_launch, cat_venue, true, 1),
    (evt_product_launch, insert_category('Launch Package', 'launch-package', 'Launch package', 'package', 'fixed', false, 'rocket_launch', '#E91E63'), true, 2),
    
    (evt_product_launch, insert_category('Product Display', 'product-display', 'Product display setup', 'service', 'fixed', false, 'store', '#2196F3'), true, 10),
    (evt_product_launch, insert_category('Special Effects', 'special-effects', 'Special effects (Smoke/Confetti)', 'service', 'per_session', false, 'flare', '#FF5722'), true, 11),
    
    (evt_product_launch, cat_pa_system, true, 20),
    (evt_product_launch, insert_category('Press Release', 'press-release', 'Press release distribution', 'service', 'fixed', false, 'newspaper', '#607D8B'), false, 30),
    (evt_product_launch, insert_category('Influencer', 'influencer', 'Influencer collaboration', 'service', 'per_session', false, 'star', '#FFEB3B'), false, 31)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 9. CHARITY / FUNDRAISING EVENTS 💝
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_charity, cat_venue, true, 1),
    (evt_charity, insert_category('Fundraising Coordinator', 'fundraising-coordinator', 'Fundraising coordinator', 'service', 'fixed', false, 'volunteer_activism', '#E91E63'), true, 2),
    
    (evt_charity, insert_category('Donation System', 'donation-system', 'Donation system', 'service', 'fixed', false, 'monetization_on', '#4CAF50'), true, 10),
    (evt_charity, cat_pa_system, true, 11),
    (evt_charity, cat_photography, true, 12),
    (evt_charity, insert_category('Auction Host', 'auction-host', 'Auction host', 'service', 'per_session', false, 'gavel', '#795548'), false, 20)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 10. SPORTS EVENTS / TOURNAMENTS 🏆
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_sports, insert_category('Sports Venue', 'sports-venue', 'Sports venue / Court', 'service', 'per_session', false, 'sports', '#FF9800'), true, 1),
    (evt_sports, insert_category('Tournament Coordinator', 'tournament-coordinator', 'Tournament coordinator', 'service', 'fixed', false, 'emoji_events', '#FFC107'), true, 2),
    
    (evt_sports, insert_category('Sports Equipment', 'sports-equipment', 'Equipment rental', 'rental', 'per_session', false, 'fitness_center', '#2196F3'), true, 10),
    (evt_sports, insert_category('Scoreboard', 'scoreboard', 'Scoreboard system', 'rental', 'per_day', false, 'scoreboard', '#F44336'), true, 11),
    
    (evt_sports, insert_category('Medics', 'medics', 'Medical / First aid', 'service', 'per_day', false, 'medical_services', '#F44336'), true, 20),
    (evt_sports, insert_category('Trophies', 'trophies', 'Trophies and Medals', 'product', 'fixed', false, 'emoji_events', '#FFD700'), false, 30)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 11. FESTIVAL / CARNIVAL 🎪
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_festival, insert_category('Festival Ground', 'festival-ground', 'Festival ground rental', 'service', 'per_day', false, 'festival', '#E91E63'), true, 1),
    (evt_festival, insert_category('Rides & Attractions', 'rides', 'Rides and attractions', 'service', 'per_day', false, 'attractions', '#9C27B0'), true, 10),
    (evt_festival, insert_category('Game Stalls', 'game-stalls', 'Game stalls', 'service', 'per_day', false, 'games', '#FF5722'), true, 11),
    (evt_festival, insert_category('Food Trucks', 'food-trucks', 'Food trucks', 'service', 'per_day', false, 'local_shipping', '#FF9800'), true, 20),
    (evt_festival, insert_category('Ticketing System', 'ticketing', 'Ticketing system', 'service', 'fixed', false, 'confirmation_number', '#2196F3'), false, 30)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 12. ANNIVERSARY CELEBRATIONS 💐
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_anniversary, cat_venue, true, 1),
    (evt_anniversary, cat_catering, true, 2),
    (evt_anniversary, insert_category('Anniversary Decoration', 'anniversary-decoration', 'Anniversary decoration', 'service', 'fixed', false, 'celebration', '#E91E63'), true, 10),
    (evt_anniversary, cat_photography, true, 20),
    (evt_anniversary, cat_videography, true, 21)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 13. BABY SHOWER / GENDER REVEAL 👶
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_baby_shower, cat_venue, true, 1),
    (evt_baby_shower, cat_catering, true, 2),
    (evt_baby_shower, insert_category('Baby Shower Decoration', 'baby-shower-decoration', 'Decoration', 'service', 'fixed', false, 'child_care', '#81C784'), true, 10),
    (evt_baby_shower, insert_category('Gender Reveal', 'gender-reveal', 'Gender reveal setup', 'service', 'fixed', false, 'visibility', '#2196F3'), true, 11),
    (evt_baby_shower, cat_photography, false, 20)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 14. ENGAGEMENT 💍
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_engagement, cat_venue, true, 1),
    (evt_engagement, cat_catering, true, 2),
    (evt_engagement, insert_category('Engagement Package', 'engagement-package', 'Engagement package', 'package', 'fixed', false, 'card_giftcard', '#E91E63'), true, 3),
    (evt_engagement, insert_category('Hantaran', 'hantaran', 'Hantaran / Gift trays', 'product', 'fixed', false, 'card_giftcard', '#F06292'), true, 10),
    (evt_engagement, cat_photography, true, 20)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 15. FUNERAL / MEMORIAL SERVICES 🕊️
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_funeral, insert_category('Funeral Home', 'funeral-home', 'Funeral home', 'service', 'fixed', false, 'home', '#757575'), true, 1),
    (evt_funeral, insert_category('Funeral Package', 'funeral-package', 'Funeral package', 'package', 'fixed', false, 'local_florist', '#9E9E9E'), true, 2),
    (evt_funeral, insert_category('Funeral Director', 'funeral-director', 'Funeral director', 'service', 'fixed', false, 'person', '#607D8B'), true, 3),
    
    (evt_funeral, insert_category('Hearse', 'hearse', 'Hearse / Transportation', 'service', 'per_trip', false, 'directions_car', '#455A64'), true, 10),
    (evt_funeral, insert_category('Casket', 'casket', 'Casket / Urn', 'product', 'fixed', false, 'inventory_2', '#5D4037'), true, 11),
    
    (evt_funeral, insert_category('Grief Counseling', 'grief-counseling', 'Grief counseling', 'service', 'per_session', false, 'psychology', '#009688'), false, 20),
    (evt_funeral, insert_category('Obituary', 'obituary', 'Obituary services', 'service', 'fixed', false, 'newspaper', '#607D8B'), false, 21)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 16. PARTY / GATHERING 🥳
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_party, cat_venue, true, 1),
    (evt_party, cat_catering, true, 2),
    (evt_party, cat_event_coordinator, true, 3),
    (evt_party, cat_photography, true, 10),
    (evt_party, cat_dj, false, 20)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 17. SEMINAR 🎓
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_seminar, insert_category('Seminar Room', 'seminar-venue', 'Seminar room', 'service', 'per_day', false, 'meeting_room', '#2196F3'), true, 1),
    (evt_seminar, cat_pa_system, true, 2),
    (evt_seminar, cat_projector, true, 3),
    (evt_seminar, cat_catering, true, 4),
    (evt_seminar, cat_event_coordinator, false, 10)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;

    -- ============================================================
    -- 18. RETIREMENT 👴
    -- ============================================================

    INSERT INTO event_type_categories (event_type_id, category_id, is_primary, display_order) VALUES
    (evt_retirement, cat_venue, true, 1),
    (evt_retirement, cat_catering, true, 2),
    (evt_retirement, insert_category('Retirement Cake', 'retirement-cake', 'Retirement cake', 'product', 'fixed', false, 'cake', '#FF9800'), true, 3),
    (evt_retirement, cat_photography, true, 10),
    (evt_retirement, cat_videography, false, 11)
    ON CONFLICT (event_type_id, category_id) DO UPDATE SET is_primary = EXCLUDED.is_primary, display_order = EXCLUDED.display_order;
    
END $$;

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_service_categories_slug ON service_categories(slug);
CREATE INDEX IF NOT EXISTS idx_service_categories_type ON service_categories(category_type);
CREATE INDEX IF NOT EXISTS idx_service_categories_active ON service_categories(is_active);
CREATE INDEX IF NOT EXISTS idx_event_type_categories_event ON event_type_categories(event_type_id);
CREATE INDEX IF NOT EXISTS idx_event_type_categories_category ON event_type_categories(category_id);
CREATE INDEX IF NOT EXISTS idx_event_type_categories_primary ON event_type_categories(is_primary);

-- ============================================================
-- ROW LEVEL SECURITY
-- ============================================================

ALTER TABLE service_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_type_categories ENABLE ROW LEVEL SECURITY;

-- Everyone can view active categories
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'service_categories' 
        AND policyname = 'Public can view active categories'
    ) THEN
        CREATE POLICY "Public can view active categories" ON service_categories
            FOR SELECT USING (is_active = true);
    END IF;
END $$;

-- Admins can manage categories
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'service_categories' 
        AND policyname = 'Admins can manage categories'
    ) THEN
        CREATE POLICY "Admins can manage categories" ON service_categories
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM admin_user
                    WHERE id = auth.uid()
                    AND status = 'active'
                )
            );
    END IF;
END $$;

-- Everyone can view event-category mappings
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'event_type_categories' 
        AND policyname = 'Public can view event category mappings'
    ) THEN
        CREATE POLICY "Public can view event category mappings" ON event_type_categories
            FOR SELECT USING (true);
    END IF;
END $$;

-- Admins can manage mappings
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE tablename = 'event_type_categories' 
        AND policyname = 'Admins can manage event category mappings'
    ) THEN
        CREATE POLICY "Admins can manage event category mappings" ON event_type_categories
            FOR ALL USING (
                EXISTS (
                    SELECT 1 FROM admin_user
                    WHERE id = auth.uid()
                    AND status = 'active'
                )
            );
    END IF;
END $$;

-- ============================================================
-- CLEANUP
-- ============================================================

DROP FUNCTION IF EXISTS insert_category;
