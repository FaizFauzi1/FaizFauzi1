-- Support Tickets System Schema
-- Run this SQL in your Supabase SQL Editor

-- 1. Support Tickets Table
CREATE TABLE IF NOT EXISTS support_tickets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    subject TEXT NOT NULL,
    description TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('booking', 'payment', 'vendor', 'account', 'technical', 'general', 'refund', 'cancellation')),
    priority TEXT NOT NULL CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'inProgress', 'resolved', 'closed')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    assigned_agent_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    assigned_agent_name TEXT,
    attachments JSONB DEFAULT '[]'::jsonb,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- 2. Support Messages Table
CREATE TABLE IF NOT EXISTS support_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ticket_id UUID NOT NULL REFERENCES support_tickets(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    sender_name TEXT NOT NULL,
    message TEXT NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    is_from_customer BOOLEAN NOT NULL DEFAULT true,
    attachments JSONB DEFAULT '[]'::jsonb
);

-- 3. FAQ Items Table
CREATE TABLE IF NOT EXISTS faq_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('booking', 'payment', 'vendor', 'account', 'technical', 'general', 'refund', 'cancellation')),
    view_count INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    is_published BOOLEAN NOT NULL DEFAULT true
);

-- Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_support_tickets_customer_id ON support_tickets(customer_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_status ON support_tickets(status);
CREATE INDEX IF NOT EXISTS idx_support_tickets_assigned_agent_id ON support_tickets(assigned_agent_id);
CREATE INDEX IF NOT EXISTS idx_support_tickets_created_at ON support_tickets(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_support_messages_ticket_id ON support_messages(ticket_id);
CREATE INDEX IF NOT EXISTS idx_support_messages_timestamp ON support_messages(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_faq_items_category ON faq_items(category);
CREATE INDEX IF NOT EXISTS idx_faq_items_is_published ON faq_items(is_published);

-- Enable Row Level Security (RLS)
ALTER TABLE support_tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE support_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE faq_items ENABLE ROW LEVEL SECURITY;

-- RLS Policies for support_tickets

-- Customers can view their own tickets
CREATE POLICY "Customers can view own tickets"
    ON support_tickets FOR SELECT
    USING (auth.uid() = customer_id);

-- Customers can create tickets
CREATE POLICY "Customers can create tickets"
    ON support_tickets FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

-- Vendors can view their own tickets
CREATE POLICY "Vendors can view own tickets"
    ON support_tickets FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM vendor_user
            WHERE vendor_user.id = auth.uid()
        )
        AND auth.uid() = customer_id
    );

-- Vendors can create tickets
CREATE POLICY "Vendors can create tickets"
    ON support_tickets FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM vendor_user
            WHERE vendor_user.id = auth.uid()
        )
        AND auth.uid() = customer_id
    );

-- Admins can view all tickets
CREATE POLICY "Admins can view all tickets"
    ON support_tickets FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE admin_user.id = auth.uid()
        )
    );

-- Admins can update tickets
CREATE POLICY "Admins can update tickets"
    ON support_tickets FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE admin_user.id = auth.uid()
        )
    );

-- RLS Policies for support_messages

-- Users can view messages for their tickets
CREATE POLICY "Users can view messages for their tickets"
    ON support_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM support_tickets
            WHERE support_tickets.id = support_messages.ticket_id
            AND (support_tickets.customer_id = auth.uid() OR support_tickets.assigned_agent_id = auth.uid())
        )
        OR
        (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- Users can add messages to their tickets
CREATE POLICY "Users can add messages to their tickets"
    ON support_messages FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM support_tickets
            WHERE support_tickets.id = support_messages.ticket_id
            AND (support_tickets.customer_id = auth.uid() OR support_tickets.assigned_agent_id = auth.uid())
        )
        OR
        (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- RLS Policies for faq_items

-- Everyone can view published FAQs
CREATE POLICY "Everyone can view published FAQs"
    ON faq_items FOR SELECT
    USING (is_published = true);

-- Admins can manage FAQs
CREATE POLICY "Admins can manage FAQs"
    ON faq_items FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE admin_user.id = auth.uid()
        )
    );

-- Insert Sample FAQ Data
INSERT INTO faq_items (question, answer, category, view_count) VALUES
('How do I make a booking?', 'To make a booking: 1) Browse vendors in your preferred category, 2) Select a service, 3) Choose your date and time, 4) Fill in your details, 5) Complete payment. You''ll receive a confirmation email immediately.', 'booking', 245),
('What payment methods do you accept?', 'We accept all major credit cards (Visa, MasterCard, American Express), debit cards, online banking, and digital wallets (Touch ''n Go, Boost, GrabPay). All payments are processed securely through our payment gateway.', 'payment', 189),
('How do I contact a vendor?', 'You can contact vendors through: 1) The messaging system in the app, 2) Phone number provided in their profile, 3) Email address listed in vendor details. Most vendors respond within 24 hours.', 'vendor', 156),
('Can I cancel or modify my booking?', 'Yes, you can cancel or modify bookings up to 48 hours before the scheduled date through the app. Cancellation fees may apply depending on the vendor''s policy. Contact support if you need to make changes within 24 hours.', 'booking', 134),
('What should I do if I encounter a technical issue?', 'For technical issues: 1) Try logging out and back in, 2) Clear app cache, 3) Update to the latest app version, 4) Restart your device. If the issue persists, submit a support ticket with screenshots.', 'technical', 98);
