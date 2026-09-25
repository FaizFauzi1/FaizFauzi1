-- ALIGN AD TABLES WITH MODELS
-- This migration ensures the database schema matches the Flutter models for Ads and Placements

-- 1. ENHANCED ADS TABLE
CREATE TABLE IF NOT EXISTS admin_ads_v2 (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL, -- banner, interstitial, native
    status TEXT NOT NULL DEFAULT 'draft', -- active, inactive, draft
    platform TEXT NOT NULL DEFAULT 'android', -- android, ios, web
    ad_unit_id TEXT NOT NULL,
    image_url TEXT,
    title TEXT,
    subtitle TEXT,
    call_to_action TEXT,
    target_url TEXT,
    targeting JSONB DEFAULT '{}'::jsonb,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    priority INT DEFAULT 1,
    max_impressions INT DEFAULT -1,
    current_impressions INT DEFAULT 0,
    max_clicks INT DEFAULT -1,
    current_clicks INT DEFAULT 0,
    cpm DOUBLE PRECISION DEFAULT 0.0,
    cpc DOUBLE PRECISION DEFAULT 0.0,
    is_test_ad BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. AD PLACEMENTS TABLE
CREATE TABLE IF NOT EXISTS admin_ad_placements (
    id TEXT PRIMARY KEY, -- usually descriptive string id
    name TEXT NOT NULL,
    description TEXT,
    ad_type TEXT NOT NULL,
    screen TEXT NOT NULL,
    position TEXT NOT NULL,
    ad_ids UUID[] DEFAULT ARRAY[]::UUID[],
    is_enabled BOOLEAN DEFAULT TRUE,
    refresh_interval INT DEFAULT 30,
    targeting JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- RLS POLICIES
ALTER TABLE admin_ads_v2 ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_ad_placements ENABLE ROW LEVEL SECURITY;

-- Admins can do everything
DROP POLICY IF EXISTS "Admins can manage ads v2" ON admin_ads_v2;
CREATE POLICY "Admins can manage ads v2" ON admin_ads_v2 FOR ALL USING (true);

DROP POLICY IF EXISTS "Admins can manage ad placements" ON admin_ad_placements;
CREATE POLICY "Admins can manage ad placements" ON admin_ad_placements FOR ALL USING (true);

-- Anyone can view
DROP POLICY IF EXISTS "Anyone can view ads v2" ON admin_ads_v2;
CREATE POLICY "Anyone can view ads v2" ON admin_ads_v2 FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can view ad placements" ON admin_ad_placements;
CREATE POLICY "Anyone can view ad placements" ON admin_ad_placements FOR SELECT USING (true);
