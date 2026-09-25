-- Create event_collaborators table
CREATE TABLE IF NOT EXISTS event_collaborators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    email TEXT,
    role TEXT NOT NULL DEFAULT 'viewer',
    status TEXT NOT NULL DEFAULT 'pending',
    invite_code TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(event_id, email),
    UNIQUE(event_id, user_id)
);

-- Add RLS policies for event_collaborators
ALTER TABLE event_collaborators ENABLE ROW LEVEL SECURITY;

-- Host can view their event's collaborators
DROP POLICY IF EXISTS "Host can view collaborators" ON event_collaborators;
CREATE POLICY "Host can view collaborators"
ON event_collaborators FOR SELECT
USING (
  EXISTS (
    SELECT 1 FROM events e 
    WHERE e.id = event_collaborators.event_id 
    AND e.host_id::text = auth.uid()::text
  )
);

-- Host can insert collaborators
DROP POLICY IF EXISTS "Host can insert collaborators" ON event_collaborators;
CREATE POLICY "Host can insert collaborators"
ON event_collaborators FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1 FROM events e 
    WHERE e.id = event_collaborators.event_id 
    AND e.host_id::text = auth.uid()::text
  )
);

-- Host can update collaborators
DROP POLICY IF EXISTS "Host can update collaborators" ON event_collaborators;
CREATE POLICY "Host can update collaborators"
ON event_collaborators FOR UPDATE
USING (
  EXISTS (
    SELECT 1 FROM events e 
    WHERE e.id = event_collaborators.event_id 
    AND e.host_id::text = auth.uid()::text
  )
);

-- Host can delete collaborators
DROP POLICY IF EXISTS "Host can delete collaborators" ON event_collaborators;
CREATE POLICY "Host can delete collaborators"
ON event_collaborators FOR DELETE
USING (
  EXISTS (
    SELECT 1 FROM events e 
    WHERE e.id = event_collaborators.event_id 
    AND e.host_id::text = auth.uid()::text
  )
);

-- Collaborators can view themselves or the events they are part of
DROP POLICY IF EXISTS "Collaborators can view themselves" ON event_collaborators;
CREATE POLICY "Collaborators can view themselves"
ON event_collaborators FOR SELECT
USING (
  user_id::text = auth.uid()::text
  OR email = (auth.jwt() ->> 'email')
);

-- Anyone can select via invite_code
DROP POLICY IF EXISTS "Anyone can view via invite code" ON event_collaborators;
CREATE POLICY "Anyone can view via invite code"
ON event_collaborators FOR SELECT
USING (
  invite_code IS NOT NULL
);

-- Collaborators can update their own status
DROP POLICY IF EXISTS "Collaborators can update their own status" ON event_collaborators;
CREATE POLICY "Collaborators can update their own status"
ON event_collaborators FOR UPDATE
USING (
  user_id::text = auth.uid()::text
  OR email = (auth.jwt() ->> 'email')
);
