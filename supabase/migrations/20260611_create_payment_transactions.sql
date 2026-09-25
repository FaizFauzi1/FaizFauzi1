-- Create payment_transactions table for persisting PaymentTransaction objects
CREATE TABLE IF NOT EXISTS public.payment_transactions (
    id TEXT PRIMARY KEY,
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    appointment_id UUID REFERENCES public.appointments(id) ON DELETE SET NULL,
    customer_id UUID NOT NULL REFERENCES public.customer_user(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES public.vendor_profiles(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL,
    method TEXT NOT NULL,
    status TEXT NOT NULL,
    transaction_id TEXT,
    payment_reference TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);

-- Enable RLS
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any
DROP POLICY IF EXISTS "Users can view their own transactions" ON public.payment_transactions;
DROP POLICY IF EXISTS "Customers can insert transactions" ON public.payment_transactions;
DROP POLICY IF EXISTS "Parties involved can update transactions" ON public.payment_transactions;

-- RLS Policies
CREATE POLICY "Users can view their own transactions" ON public.payment_transactions
    FOR SELECT
    USING (auth.uid() = customer_id OR auth.uid() = (SELECT user_id FROM public.vendor_profiles WHERE id = vendor_id));

CREATE POLICY "Customers can insert transactions" ON public.payment_transactions
    FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Parties involved can update transactions" ON public.payment_transactions
    FOR UPDATE
    USING (auth.uid() = customer_id OR auth.uid() = (SELECT user_id FROM public.vendor_profiles WHERE id = vendor_id));
