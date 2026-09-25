-- =============================================
-- CREATE CUSTOMER REQUESTS TABLE (UPDATED)
-- =============================================

-- 1. Create table
CREATE TABLE IF NOT EXISTS customer_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID REFERENCES customer_user(id) ON DELETE CASCADE,
    customer_name TEXT,
    event_category TEXT,
    event_type TEXT,
    event_date TIMESTAMP WITH TIME ZONE,
    budget DECIMAL(10,2),
    description TEXT,
    location TEXT,
    guest_count INTEGER,
    guest_count_range TEXT,
    contact_phone TEXT,
    contact_email TEXT,
    status TEXT DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    offers JSONB DEFAULT '[]'::jsonb
);

-- 2. Enable RLS
ALTER TABLE customer_requests ENABLE ROW LEVEL SECURITY;

-- 3. Drop existing policies
DROP POLICY IF EXISTS "Customers can manage own requests" ON customer_requests;
DROP POLICY IF EXISTS "Authenticated users can view requests" ON customer_requests;
DROP POLICY IF EXISTS "Authenticated users can update requests" ON customer_requests;
DROP POLICY IF EXISTS "Authenticated users can insert requests" ON customer_requests;
DROP POLICY IF EXISTS "Customers can delete own requests" ON customer_requests;
DROP POLICY IF EXISTS "Admins can delete requests" ON customer_requests; -- Explicit drop

-- 4. Create Policies

-- Customers can view/edit their own requests (SELECT, UPDATE)
CREATE POLICY "Customers can manage own requests" ON customer_requests
    USING (auth.uid() = customer_id)
    WITH CHECK (auth.uid() = customer_id);

-- Customers can DELETE their own requests
CREATE POLICY "Customers can delete own requests" ON customer_requests
    FOR DELETE
    USING (auth.uid() = customer_id);

-- Admins can DELETE any request
CREATE POLICY "Admins can delete requests" ON customer_requests
    FOR DELETE
    USING (
        EXISTS (SELECT 1 FROM admin_user WHERE id = auth.uid()) OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- Authenticated users (Vendors/Admins) can view all requests
CREATE POLICY "Authenticated users can view requests" ON customer_requests
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Authenticated users (Vendors) can update requests (to add offers)
CREATE POLICY "Authenticated users can update requests" ON customer_requests
    FOR UPDATE
    USING (auth.role() = 'authenticated');
    
-- Authenticated users (Customers) can insert new requests
CREATE POLICY "Authenticated users can insert requests" ON customer_requests
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- 5. Grant permissions
GRANT ALL ON customer_requests TO authenticated;
GRANT ALL ON customer_requests TO service_role;
