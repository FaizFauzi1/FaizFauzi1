-- Cart Items Table for Supabase
-- This table stores shopping cart items for customers

CREATE TABLE IF NOT EXISTS public.cart_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    customer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    service_id TEXT NOT NULL,
    service_name TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1 CHECK (quantity > 0),
    unit_price DECIMAL(10, 2) NOT NULL CHECK (unit_price >= 0),
    total_price DECIMAL(10, 2) NOT NULL CHECK (total_price >= 0),
    vendor_id TEXT NOT NULL,
    vendor_name TEXT,
    service_type TEXT NOT NULL DEFAULT 'service',
    options JSONB DEFAULT '{}',
    requirements JSONB DEFAULT '{}',
    added_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_customer_service UNIQUE(customer_id, service_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_cart_items_customer ON public.cart_items(customer_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_service ON public.cart_items(service_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_vendor ON public.cart_items(vendor_id);
CREATE INDEX IF NOT EXISTS idx_cart_items_added_at ON public.cart_items(added_at);

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION update_cart_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cart_items_updated_at
    BEFORE UPDATE ON public.cart_items
    FOR EACH ROW
    EXECUTE FUNCTION update_cart_items_updated_at();

-- Row Level Security (RLS) Policies
ALTER TABLE public.cart_items ENABLE ROW LEVEL SECURITY;

-- Policy: Users can only view their own cart items
CREATE POLICY "Users can view own cart items"
    ON public.cart_items
    FOR SELECT
    USING (auth.uid() = customer_id);

-- Policy: Users can insert their own cart items
CREATE POLICY "Users can insert own cart items"
    ON public.cart_items
    FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

-- Policy: Users can update their own cart items
CREATE POLICY "Users can update own cart items"
    ON public.cart_items
    FOR UPDATE
    USING (auth.uid() = customer_id)
    WITH CHECK (auth.uid() = customer_id);

-- Policy: Users can delete their own cart items
CREATE POLICY "Users can delete own cart items"
    ON public.cart_items
    FOR DELETE
    USING (auth.uid() = customer_id);

-- Function to automatically calculate total_price
CREATE OR REPLACE FUNCTION calculate_cart_item_total()
RETURNS TRIGGER AS $$
BEGIN
    NEW.total_price = NEW.unit_price * NEW.quantity;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cart_item_calculate_total
    BEFORE INSERT OR UPDATE ON public.cart_items
    FOR EACH ROW
    EXECUTE FUNCTION calculate_cart_item_total();

-- Function to clean up old cart items (older than 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_cart_items()
RETURNS void AS $$
BEGIN
    DELETE FROM public.cart_items
    WHERE added_at < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Optional: Create a scheduled job to run cleanup (requires pg_cron extension)
-- SELECT cron.schedule('cleanup-old-carts', '0 2 * * *', 'SELECT cleanup_old_cart_items()');

COMMENT ON TABLE public.cart_items IS 'Stores shopping cart items for customers';
COMMENT ON COLUMN public.cart_items.customer_id IS 'Reference to the customer who owns this cart item';
COMMENT ON COLUMN public.cart_items.service_id IS 'ID of the service/product';
COMMENT ON COLUMN public.cart_items.quantity IS 'Number of items';
COMMENT ON COLUMN public.cart_items.unit_price IS 'Price per unit';
COMMENT ON COLUMN public.cart_items.total_price IS 'Total price (unit_price * quantity) - auto-calculated';
COMMENT ON COLUMN public.cart_items.options IS 'Additional options selected for this item (JSON)';
COMMENT ON COLUMN public.cart_items.requirements IS 'Special requirements for this item (JSON)';
