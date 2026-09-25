-- Booking Amendment Flow Migration
-- 🚀 Run this script in Supabase SQL Editor

-- 1. Create booking_changes table
CREATE TABLE IF NOT EXISTS booking_changes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    requested_by UUID NOT NULL REFERENCES auth.users(id),
    change_type TEXT NOT NULL CHECK (change_type IN ('date', 'package', 'pax', 'add_on', 'other')),
    old_value JSONB NOT NULL,
    new_value JSONB NOT NULL,
    price_diff DECIMAL(10,2) DEFAULT 0.00,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed', 'cancelled')),
    vendor_notes TEXT,
    customer_notes TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create booking_price_adjustments table
CREATE TABLE IF NOT EXISTS booking_price_adjustments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    change_id UUID REFERENCES booking_changes(id) ON DELETE SET NULL,
    amount DECIMAL(10,2) NOT NULL, -- Positive for extra charge, negative for refund/credit
    adjustment_type TEXT NOT NULL CHECK (adjustment_type IN ('extra_charge', 'refund', 'credit', 'discount')),
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'paid', 'refunded', 'cancelled')),
    transaction_id TEXT, -- Payment reference if additional payment was made
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Add vendor policies to vendor_profiles
ALTER TABLE vendor_profiles 
ADD COLUMN IF NOT EXISTS vendor_policies JSONB DEFAULT '{
    "change_window_days": 7,
    "reschedule_fee": 0,
    "upgrade_allowed": true,
    "downgrade_refund_allowed": false
}';

-- 4. Update bookings status constraint to include amendment statuses
-- (This part repeats what was in the previous notification, ensuring consistency)
DO $$
BEGIN
    ALTER TABLE bookings DROP CONSTRAINT IF EXISTS bookings_status_check;
EXCEPTION
    WHEN undefined_object THEN NULL;
END $$;

ALTER TABLE bookings 
ADD CONSTRAINT bookings_status_check 
CHECK (status IN (
    'pending_vendor',
    'awaiting_payment',
    'confirmed',
    'in_progress',
    'completed',
    'cancelled_by_user',
    'cancelled_by_vendor',
    'rejected',
    'expired',
    'pending',
    'cancelled',
    'change_requested',
    'change_approved',
    'change_rejected',
    'awaiting_adjustment_payment'
));

-- 5. RLS Policies for new tables
ALTER TABLE booking_changes ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_price_adjustments ENABLE ROW LEVEL SECURITY;

-- Customers can view/create their own change requests
CREATE POLICY "Users can manage their own booking changes" ON booking_changes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM bookings
            WHERE bookings.id = booking_changes.booking_id
            AND bookings.customer_id = auth.uid()
        )
    );

-- Vendors can view/update change requests for their bookings
CREATE POLICY "Vendors can manage changes for their bookings" ON booking_changes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM bookings
            WHERE bookings.id = booking_changes.booking_id
            AND bookings.vendor_id = (SELECT id FROM vendor_profiles WHERE user_id = auth.uid())
        )
    );

-- Similar for price adjustments
CREATE POLICY "View price adjustments" ON booking_price_adjustments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM bookings
            WHERE bookings.id = booking_price_adjustments.booking_id
            AND (bookings.customer_id = auth.uid() OR bookings.vendor_id = (SELECT id FROM vendor_profiles WHERE user_id = auth.uid()))
        )
    );
