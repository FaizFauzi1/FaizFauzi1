-- Add event_id column to event_guests table
ALTER TABLE event_guests ADD COLUMN IF NOT EXISTS event_id UUID REFERENCES events(id) ON DELETE CASCADE;

-- Optional: Populate event_id from related invitation if possible (if RLS allows)
-- This is a best effort to maintain data integrity
UPDATE event_guests
SET event_id = event_invitations.event_id
FROM event_invitations
WHERE event_guests.invitation_id = event_invitations.id;

-- Make event_id NOT NULL after populating
ALTER TABLE event_guests ALTER COLUMN event_id SET NOT NULL;
