-- ENHANCED ADMIN CONTENT & MARKETING TABLES
-- Supports: Vendor Control, Campaign Engine, Sponsored Placements, CTA Articles

-- =============================================
-- 1. LISTINGS (Vendor Control Center)
-- =============================================
CREATE TABLE IF NOT EXISTS admin_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    price INT NOT NULL,
    status TEXT DEFAULT 'pending', -- pending, approved, rejected, suspended
    is_verified BOOLEAN DEFAULT FALSE,
    is_pinned BOOLEAN DEFAULT FALSE,
    views INT DEFAULT 0,
    bookings INT DEFAULT 0,
    conversion_rate DOUBLE PRECISION DEFAULT 0.0,
    vendor_id UUID,
    vendor_name TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add new columns if table already exists
ALTER TABLE admin_listings ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
ALTER TABLE admin_listings ADD COLUMN IF NOT EXISTS is_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE admin_listings ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;
ALTER TABLE admin_listings ADD COLUMN IF NOT EXISTS views INT DEFAULT 0;
ALTER TABLE admin_listings ADD COLUMN IF NOT EXISTS bookings INT DEFAULT 0;
ALTER TABLE admin_listings ADD COLUMN IF NOT EXISTS conversion_rate DOUBLE PRECISION DEFAULT 0.0;
ALTER TABLE admin_listings ADD COLUMN IF NOT EXISTS vendor_id UUID;
ALTER TABLE admin_listings ADD COLUMN IF NOT EXISTS vendor_name TEXT;

ALTER TABLE admin_listings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage listings" ON admin_listings;
CREATE POLICY "Admins can manage listings" ON admin_listings FOR ALL USING (auth.uid() IN (SELECT id FROM admin_user));
DROP POLICY IF EXISTS "Anyone can view listings" ON admin_listings;
CREATE POLICY "Anyone can view listings" ON admin_listings FOR SELECT USING (true);


-- =============================================
-- 2. PROMOTIONS (Campaign / Deals Engine)
-- =============================================
CREATE TABLE IF NOT EXISTS admin_promotions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    valid_until TEXT NOT NULL,
    campaign_type TEXT DEFAULT 'vendor', -- platform_wide, vendor, flash_deal
    description TEXT,
    discount_percent DOUBLE PRECISION,
    target_region TEXT, -- state-based targeting
    target_category TEXT, -- photography, catering, etc.
    status TEXT DEFAULT 'active', -- draft, active, expired, paused
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    redemptions INT DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE admin_promotions ADD COLUMN IF NOT EXISTS campaign_type TEXT DEFAULT 'vendor';
ALTER TABLE admin_promotions ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE admin_promotions ADD COLUMN IF NOT EXISTS discount_percent DOUBLE PRECISION;
ALTER TABLE admin_promotions ADD COLUMN IF NOT EXISTS target_region TEXT;
ALTER TABLE admin_promotions ADD COLUMN IF NOT EXISTS target_category TEXT;
ALTER TABLE admin_promotions ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'active';
ALTER TABLE admin_promotions ADD COLUMN IF NOT EXISTS start_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE admin_promotions ADD COLUMN IF NOT EXISTS end_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE admin_promotions ADD COLUMN IF NOT EXISTS redemptions INT DEFAULT 0;

ALTER TABLE admin_promotions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage promotions" ON admin_promotions;
CREATE POLICY "Admins can manage promotions" ON admin_promotions FOR ALL USING (auth.uid() IN (SELECT id FROM admin_user));
DROP POLICY IF EXISTS "Anyone can view promotions" ON admin_promotions;
CREATE POLICY "Anyone can view promotions" ON admin_promotions FOR SELECT USING (true);


-- =============================================
-- 3. ADVERTISEMENTS (Sponsored Placement System)
-- =============================================
CREATE TABLE IF NOT EXISTS admin_ads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    advertiser_name TEXT NOT NULL,
    placement_type TEXT DEFAULT 'search_boost', -- homepage_banner, category_top, search_boost
    pricing_tier TEXT DEFAULT 'basic', -- basic, premium, elite
    status TEXT DEFAULT 'pending', -- pending, approved, active, paused, expired
    impressions INT DEFAULT 0,
    clicks INT DEFAULT 0,
    budget DOUBLE PRECISION DEFAULT 0,
    spent DOUBLE PRECISION DEFAULT 0,
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE admin_ads ADD COLUMN IF NOT EXISTS placement_type TEXT DEFAULT 'search_boost';
ALTER TABLE admin_ads ADD COLUMN IF NOT EXISTS pricing_tier TEXT DEFAULT 'basic';
ALTER TABLE admin_ads ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending';
ALTER TABLE admin_ads ADD COLUMN IF NOT EXISTS impressions INT DEFAULT 0;
ALTER TABLE admin_ads ADD COLUMN IF NOT EXISTS clicks INT DEFAULT 0;
ALTER TABLE admin_ads ADD COLUMN IF NOT EXISTS budget DOUBLE PRECISION DEFAULT 0;
ALTER TABLE admin_ads ADD COLUMN IF NOT EXISTS spent DOUBLE PRECISION DEFAULT 0;
ALTER TABLE admin_ads ADD COLUMN IF NOT EXISTS start_date TIMESTAMP WITH TIME ZONE;
ALTER TABLE admin_ads ADD COLUMN IF NOT EXISTS end_date TIMESTAMP WITH TIME ZONE;

ALTER TABLE admin_ads ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage ads" ON admin_ads;
CREATE POLICY "Admins can manage ads" ON admin_ads FOR ALL USING (auth.uid() IN (SELECT id FROM admin_user));
DROP POLICY IF EXISTS "Anyone can view ads" ON admin_ads;
CREATE POLICY "Anyone can view ads" ON admin_ads FOR SELECT USING (true);


-- =============================================
-- 4. ARTICLES (SEO / Marketing Engine)
-- =============================================
CREATE TABLE IF NOT EXISTS admin_articles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    author_name TEXT NOT NULL,
    content TEXT,
    status TEXT DEFAULT 'draft',
    category TEXT, -- event_guide, vendor_tips, budgeting, general
    linked_vendor_id UUID,
    linked_vendor_name TEXT,
    cta_type TEXT, -- book_vendor, view_package, get_quote, none
    cta_link TEXT,
    featured_image TEXT,
    views INT DEFAULT 0,
    published_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE admin_articles ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'draft';
ALTER TABLE admin_articles ADD COLUMN IF NOT EXISTS category TEXT;
ALTER TABLE admin_articles ADD COLUMN IF NOT EXISTS linked_vendor_id UUID;
ALTER TABLE admin_articles ADD COLUMN IF NOT EXISTS linked_vendor_name TEXT;
ALTER TABLE admin_articles ADD COLUMN IF NOT EXISTS cta_type TEXT;
ALTER TABLE admin_articles ADD COLUMN IF NOT EXISTS cta_link TEXT;
ALTER TABLE admin_articles ADD COLUMN IF NOT EXISTS featured_image TEXT;
ALTER TABLE admin_articles ADD COLUMN IF NOT EXISTS views INT DEFAULT 0;
ALTER TABLE admin_articles ADD COLUMN IF NOT EXISTS published_at TIMESTAMP WITH TIME ZONE;

ALTER TABLE admin_articles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage articles" ON admin_articles;
CREATE POLICY "Admins can manage articles" ON admin_articles FOR ALL USING (auth.uid() IN (SELECT id FROM admin_user));
DROP POLICY IF EXISTS "Anyone can view articles" ON admin_articles;
CREATE POLICY "Anyone can view articles" ON admin_articles FOR SELECT USING (true);
