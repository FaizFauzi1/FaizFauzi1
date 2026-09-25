-- Fix Event Tools Schema
-- Run this in the Supabase SQL Editor

-- 1. Fix event_checklists (rename is_completed to is_done)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'event_checklists' AND column_name = 'is_completed') THEN
        ALTER TABLE event_checklists RENAME COLUMN is_completed TO is_done;
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'event_checklists' AND column_name = 'is_done') THEN
        ALTER TABLE event_checklists ADD COLUMN is_done BOOLEAN DEFAULT false;
    END IF;
END $$;

-- 2. Create budgets table
CREATE TABLE IF NOT EXISTS budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    customer_id TEXT NOT NULL,
    total_budget DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    allocated_budget DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    spent_budget DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create budget_categories table
CREATE TABLE IF NOT EXISTS budget_categories (
    id TEXT PRIMARY KEY, 
    -- Typically these ids look like "venue", "catering", or uuid if dynamically created
    budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    allocated_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    spent_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    color TEXT DEFAULT '#000000',
    type TEXT NOT NULL,
    is_required BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create budget_expenses table
CREATE TABLE IF NOT EXISTS budget_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    budget_id UUID NOT NULL REFERENCES budgets(id) ON DELETE CASCADE,
    category_id TEXT NOT NULL REFERENCES budget_categories(id) ON DELETE CASCADE,
    vendor_id TEXT,
    description TEXT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    expense_date TIMESTAMP WITH TIME ZONE NOT NULL,
    receipt_url TEXT,
    notes TEXT,
    is_recurring BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create event_timeline table
CREATE TABLE IF NOT EXISTS event_timeline (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    event_date TIMESTAMP WITH TIME ZONE NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Enable RLS and setup policies
ALTER TABLE budgets ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE budget_expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_timeline ENABLE ROW LEVEL SECURITY;

-- Policies for budgets
CREATE POLICY "Users can manage their own budgets" ON budgets
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE id = budgets.event_id AND host_id = auth.uid()::text
        )
    );

-- Policies for budget_categories
CREATE POLICY "Users can manage their own budget categories" ON budget_categories
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM budgets
            JOIN events ON events.id = budgets.event_id
            WHERE budgets.id = budget_categories.budget_id AND events.host_id = auth.uid()::text
        )
    );

-- Policies for budget_expenses
CREATE POLICY "Users can manage their own budget expenses" ON budget_expenses
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM budgets
            JOIN events ON events.id = budgets.event_id
            WHERE budgets.id = budget_expenses.budget_id AND events.host_id = auth.uid()::text
        )
    );

-- Policies for event_timeline
CREATE POLICY "Users can manage their own timelines" ON event_timeline
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE id = event_timeline.event_id AND host_id = auth.uid()::text
        )
    );
