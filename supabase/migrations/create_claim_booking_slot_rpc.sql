-- ==============================================================================
-- Function: claim_booking_slot
-- Purpose: Atomically claims a vendor calendar slot and prevents race conditions /
--          double-booking using PostgreSQL's UNIQUE constraint on vendor_availability.
-- ==============================================================================

CREATE OR REPLACE FUNCTION public.claim_booking_slot(
    p_vendor_id UUID,
    p_date DATE,
    p_start_time TIME,
    p_end_time TIME,
    p_block_reason TEXT DEFAULT 'Slot claimed'
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
BEGIN
    INSERT INTO public.vendor_availability (
        vendor_id,
        date,
        start_time,
        end_time,
        is_available,
        is_blocked,
        block_reason
    ) VALUES (
        p_vendor_id,
        p_date,
        p_start_time,
        p_end_time,
        false,
        true,
        p_block_reason
    );

    RETURN jsonb_build_object(
        'success', true,
        'status', 201,
        'message', 'Slot successfully claimed'
    );
EXCEPTION
    WHEN unique_violation THEN
        RETURN jsonb_build_object(
            'success', false,
            'status', 409,
            'error', 'Slot already claimed'
        );
    WHEN foreign_key_violation THEN
        RETURN jsonb_build_object(
            'success', false,
            'status', 404,
            'error', 'Vendor does not exist'
        );
END;
$$;

-- Grant execution permissions to public and authenticated roles
GRANT EXECUTE ON FUNCTION public.claim_booking_slot(UUID, DATE, TIME, TIME, TEXT) TO anon, authenticated, service_role;
