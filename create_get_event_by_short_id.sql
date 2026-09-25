-- ====================================================================
-- GET EVENT BY SHORT ID (PREFIX SEARCH FOR UUID)
-- Allows prefix searching event UUIDs via short 8-char codes
-- Run this script in the Supabase SQL Editor.
-- ====================================================================

CREATE OR REPLACE FUNCTION get_event_by_short_id(prefix text)
RETURNS SETOF events AS $$
BEGIN
    RETURN QUERY 
    SELECT * FROM events 
    WHERE id::text ILIKE (prefix || '%')
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
