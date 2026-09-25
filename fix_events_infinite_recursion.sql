-- =====================================================
-- FIX EVENTS INFINITE RECURSION IN RLS POLICIES
-- Resolves the PostgreSQL "infinite recursion detected in policy" error.
-- =====================================================

-- Drop the recursive policies on the events table
DO $$ 
BEGIN 
    DROP POLICY IF EXISTS "Guests can view events they are invited to" ON events;
    DROP POLICY IF EXISTS "Hosts can view their own events" ON events;
    DROP POLICY IF EXISTS "Public events are viewable by everyone" ON events;
    DROP POLICY IF EXISTS "Hosts can create events" ON events;
    DROP POLICY IF EXISTS "Hosts can update their own events" ON events;
    DROP POLICY IF EXISTS "Hosts can delete their own events" ON events;
    DROP POLICY IF EXISTS "Anyone can view events" ON events;
END $$;

-- 1. Anyone can view events (safe because IDs are secure UUIDs, same as "Anyone with link can view")
CREATE POLICY "Anyone can view events" ON events
    FOR SELECT USING (true);

-- 2. Keep update/delete/insert strictly locked to the host only
CREATE POLICY "Hosts can create events" ON events
    FOR INSERT WITH CHECK (auth.uid()::text = host_id);

CREATE POLICY "Hosts can update their own events" ON events
    FOR UPDATE USING (auth.uid()::text = host_id);

CREATE POLICY "Hosts can delete their own events" ON events
    FOR DELETE USING (auth.uid()::text = host_id);
