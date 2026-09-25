-- EventEase Database Schema
-- This file defines the complete database structure for the EventEase application

-- ===========================================
-- USERS AND AUTHENTICATION TABLES
-- ===========================================

-- Main users table (managed by Supabase Auth)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'super_admin', 'vendor', 'customer')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Role-specific user tables
CREATE TABLE IF NOT EXISTS admin_user (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    role TEXT DEFAULT 'admin' CHECK (role = 'admin'),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vendor_user (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    role TEXT DEFAULT 'vendor' CHECK (role = 'vendor'),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending', 'suspended')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS customer_user (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    role TEXT DEFAULT 'customer' CHECK (role = 'customer'),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- VENDOR PROFILES AND ANALYTICS
-- ===========================================

-- Vendor profiles (extended information)
CREATE TABLE IF NOT EXISTS vendor_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vendor_user(id) ON DELETE CASCADE,
    business_name TEXT NOT NULL,
    business_description TEXT,
    business_address TEXT,
    business_phone TEXT,
    business_email TEXT,
    website_url TEXT,
    profile_picture_url TEXT,
    profile_completion_percentage INTEGER DEFAULT 0 CHECK (profile_completion_percentage >= 0 AND profile_completion_percentage <= 100),
    profile_completion_status TEXT DEFAULT 'incomplete' CHECK (profile_completion_status IN ('incomplete', 'pending_review', 'approved', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Vendor analytics (must be created AFTER vendor_profiles)
CREATE TABLE IF NOT EXISTS vendor_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_views INTEGER DEFAULT 0,
    profile_views INTEGER DEFAULT 0,
    service_views INTEGER DEFAULT 0,
    contact_clicks INTEGER DEFAULT 0,
    bookings_count INTEGER DEFAULT 0,
    revenue DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vendor_id, date)
);

-- ===========================================
-- DATABASE TRIGGERS AND FUNCTIONS
-- ===========================================

-- Function to create user profile based on role
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert into users table with correct role
    INSERT INTO users (id, email, role)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'role', 'customer'));

    -- Create role-specific profile
    CASE COALESCE(NEW.raw_user_meta_data->>'role', 'customer')
        WHEN 'admin' THEN
            INSERT INTO admin_user (id, name, email, phone, role)
            VALUES (
                NEW.id,
                COALESCE(NEW.raw_user_meta_data->>'name', 'Admin User'),
                NEW.email,
                COALESCE(NEW.raw_user_meta_data->>'phone', ''),
                'admin'
            );
        WHEN 'vendor' THEN
            INSERT INTO vendor_user (id, name, email, phone, role)
            VALUES (
                NEW.id,
                COALESCE(NEW.raw_user_meta_data->>'name', 'Vendor User'),
                NEW.email,
                COALESCE(NEW.raw_user_meta_data->>'phone', ''),
                'vendor'
            );
        ELSE
            INSERT INTO customer_user (id, name, email, phone, role)
            VALUES (
                NEW.id,
                COALESCE(NEW.raw_user_meta_data->>'name', 'Customer User'),
                NEW.email,
                COALESCE(NEW.raw_user_meta_data->>'phone', ''),
                'customer'
            );
    END CASE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- Function to create vendor profile when vendor_user is created
CREATE OR REPLACE FUNCTION create_vendor_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- Create basic vendor profile when vendor_user is created
    INSERT INTO vendor_profiles (user_id, business_name)
    VALUES (NEW.id, COALESCE(NEW.name, 'Business Name'));

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create vendor analytics when profile is created (not during sign-up)
CREATE OR REPLACE FUNCTION create_vendor_analytics_on_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- Create initial analytics record when vendor profile is created
    INSERT INTO vendor_analytics (vendor_id, date)
    VALUES (NEW.id, CURRENT_DATE)
    ON CONFLICT (vendor_id, date) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION create_user_profile();

DROP TRIGGER IF EXISTS on_vendor_user_created ON vendor_user;
CREATE TRIGGER on_vendor_user_created
    AFTER INSERT ON vendor_user
    FOR EACH ROW EXECUTE FUNCTION create_vendor_profile();

DROP TRIGGER IF EXISTS on_vendor_profile_created ON vendor_profiles;
CREATE TRIGGER on_vendor_profile_created
    AFTER INSERT ON vendor_profiles
    FOR EACH ROW EXECUTE FUNCTION create_vendor_analytics_on_profile();

-- ===========================================
-- INDEXES FOR PERFORMANCE
-- ===========================================

CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_user_id ON vendor_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_vendor_analytics_vendor_id ON vendor_analytics(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_analytics_date ON vendor_analytics(date);

-- ===========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ===========================================

-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_analytics ENABLE ROW LEVEL SECURITY;

-- Users table policies
CREATE POLICY "Users can view their own record" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Vendor profiles policies
CREATE POLICY "Vendors can view their own profile" ON vendor_profiles
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all vendor profiles" ON vendor_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Vendor analytics policies
CREATE POLICY "Vendors can view their own analytics" ON vendor_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_analytics.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all vendor analytics" ON vendor_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );
