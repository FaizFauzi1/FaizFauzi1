-- SQL Migration: Add Wedding Marketplace Tables and Configurations

-- 1. Alter vendor_profiles to support transfer settings
ALTER TABLE vendor_profiles 
ADD COLUMN IF NOT EXISTS allow_booking_transfer BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS require_transfer_approval BOOLEAN DEFAULT true;

-- 2. Create Transfer Listings Table
CREATE TABLE IF NOT EXISTS transfer_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customer_user(id) ON DELETE CASCADE,
    vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE SET NULL,
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    category TEXT NOT NULL,
    vendor_name TEXT NOT NULL,
    event_date DATE NOT NULL,
    original_booking_price DECIMAL(10,2) NOT NULL,
    selling_price DECIMAL(10,2) NOT NULL,
    package_description TEXT NOT NULL,
    images JSONB DEFAULT '[]',
    reason TEXT,
    proof_url TEXT,
    transfer_approval_status TEXT NOT NULL DEFAULT 'pending' CHECK (transfer_approval_status IN ('pending', 'approved', 'rejected')),
    listing_status TEXT NOT NULL DEFAULT 'pending_approval' CHECK (listing_status IN ('active', 'pending_approval', 'sold', 'expired')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for transfer_listings
ALTER TABLE transfer_listings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Public can view active transfer listings" ON transfer_listings;
DROP POLICY IF EXISTS "Users can insert their own transfer listings" ON transfer_listings;
DROP POLICY IF EXISTS "Sellers can update their own transfer listings" ON transfer_listings;
DROP POLICY IF EXISTS "Associated vendors can update transfer approval status" ON transfer_listings;
DROP POLICY IF EXISTS "Admins can view and manage all transfer listings" ON transfer_listings;

-- Create policies for transfer_listings
CREATE POLICY "Public can view active transfer listings" 
ON transfer_listings FOR SELECT 
USING (listing_status = 'active');

CREATE POLICY "Users can insert their own transfer listings" 
ON transfer_listings FOR INSERT 
WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Sellers can update their own transfer listings" 
ON transfer_listings FOR UPDATE 
USING (auth.uid() = customer_id)
WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Associated vendors can update transfer approval status"
ON transfer_listings FOR UPDATE
USING (
    EXISTS (
        SELECT 1 FROM vendor_profiles vp
        WHERE vp.id = transfer_listings.vendor_id 
        AND vp.user_id = auth.uid()
    )
);

CREATE POLICY "Admins can view and manage all transfer listings"
ON transfer_listings FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM admin_user au
        WHERE au.id = auth.uid()
    )
);


-- 3. Create Item Listings Table
CREATE TABLE IF NOT EXISTS item_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customer_user(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    item_name TEXT NOT NULL,
    description TEXT NOT NULL,
    condition TEXT NOT NULL CHECK (condition IN ('new', 'like_new', 'used')),
    quantity INTEGER NOT NULL DEFAULT 1,
    size TEXT,
    brand TEXT,
    price DECIMAL(10,2) NOT NULL,
    images JSONB DEFAULT '[]',
    location TEXT NOT NULL,
    delivery_option TEXT NOT NULL DEFAULT 'both' CHECK (delivery_option IN ('delivery', 'pickup', 'both')),
    listing_status TEXT NOT NULL DEFAULT 'active' CHECK (listing_status IN ('active', 'sold', 'expired', 'pending_verification')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for item_listings
ALTER TABLE item_listings ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Public can view active item listings" ON item_listings;
DROP POLICY IF EXISTS "Users can insert their own item listings" ON item_listings;
DROP POLICY IF EXISTS "Sellers can update their own item listings" ON item_listings;
DROP POLICY IF EXISTS "Admins can view and manage all item listings" ON item_listings;

-- Create policies for item_listings
CREATE POLICY "Public can view active item listings" 
ON item_listings FOR SELECT 
USING (listing_status = 'active');

CREATE POLICY "Users can insert their own item listings" 
ON item_listings FOR INSERT 
WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Sellers can update their own item listings" 
ON item_listings FOR UPDATE 
USING (auth.uid() = customer_id)
WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Admins can view and manage all item listings"
ON item_listings FOR ALL
USING (
    EXISTS (
        SELECT 1 FROM admin_user au
        WHERE au.id = auth.uid()
    )
);
