-- Fix RLS policies for subscription_payments to allow vendors to initiate upgrades
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

-- 1. Allow vendors to view their own payments (already exists but ensuring it's robust)
DROP POLICY IF EXISTS "Vendors can view their own payments" ON public.subscription_payments;
CREATE POLICY "Vendors can view their own payments" ON public.subscription_payments
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.vendor_profiles
            WHERE id = subscription_payments.vendor_id
            AND user_id = auth.uid()
        )
    );

-- 2. Allow vendors to insert their own payment records (New)
-- This is required when the vendor initiates an upgrade from the app
DROP POLICY IF EXISTS "Vendors can insert their own payments" ON public.subscription_payments;
CREATE POLICY "Vendors can insert their own payments" ON public.subscription_payments
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.vendor_profiles
            WHERE id = vendor_id
            AND user_id = auth.uid()
        )
    );

-- 3. Allow service role (Edge Functions/Webhooks) to manage all payments
-- Usually service role bypasses RLS, but if it uses a standard client, we need policies.
-- However, we shouldn't allow regular users to UPDATE.
-- Only the system (via service role) should update payment_status to 'completed'.

-- Optional: Allow vendors to update their own 'pending' payments (e.g. to 'cancelled' if they close the window)
DROP POLICY IF EXISTS "Vendors can update their own pending payments" ON public.subscription_payments;
CREATE POLICY "Vendors can update their own pending payments" ON public.subscription_payments
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.vendor_profiles
            WHERE id = subscription_payments.vendor_id
            AND user_id = auth.uid()
        )
    )
    WITH CHECK (
        payment_status = 'pending' -- Only allow updating if it's still pending
    );
