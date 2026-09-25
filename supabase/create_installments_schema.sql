-- Create installment_plans table
CREATE TABLE IF NOT EXISTS installment_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    total_amount DECIMAL(12, 2) NOT NULL,
    deposit_amount DECIMAL(12, 2) NOT NULL,
    remaining_balance DECIMAL(12, 2) NOT NULL,
    number_of_installments INTEGER NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create installment_payments table
CREATE TABLE IF NOT EXISTS installment_payments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES installment_plans(id) ON DELETE CASCADE,
    amount DECIMAL(12, 2) NOT NULL,
    due_date DATE NOT NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'paid', 'late', 'cancelled')),
    payment_id UUID REFERENCES payments(id), -- Optional tracking to actual payment record
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_installment_plans_booking_id ON installment_plans(booking_id);
CREATE INDEX IF NOT EXISTS idx_installment_payments_plan_id ON installment_payments(plan_id);

-- Enable RLS
ALTER TABLE installment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE installment_payments ENABLE ROW LEVEL SECURITY;

-- Policies for installment_plans
CREATE POLICY "Users can view their own installment plans" ON installment_plans
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM bookings
            WHERE bookings.id = installment_plans.booking_id
            AND (bookings.customer_id = auth.uid() OR bookings.vendor_id = auth.uid())
        )
    );

-- Policies for installment_payments
CREATE POLICY "Users can view their own installment payments" ON installment_payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM installment_plans
            JOIN bookings ON bookings.id = installment_plans.booking_id
            WHERE installment_plans.id = installment_payments.plan_id
            AND (bookings.customer_id = auth.uid() OR bookings.vendor_id = auth.uid())
        )
    );
