-- Create types safely
DO $$ BEGIN
    CREATE TYPE shop_order_type AS ENUM ('purchase', 'appointment');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE shop_order_status AS ENUM ('ordered', 'processing', 'shipped', 'delivered', 'completed', 'cancelled', 'refunded');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE shop_payment_status AS ENUM ('pending', 'processing', 'completed', 'failed', 'refunded');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- Create shop_orders table
CREATE TABLE IF NOT EXISTS public.shop_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    customer_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    customer_name TEXT NOT NULL,
    customer_email TEXT NOT NULL,
    type shop_order_type DEFAULT 'purchase',
    subtotal DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    service_fee DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    total_amount DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    status shop_order_status DEFAULT 'ordered',
    payment_status shop_payment_status DEFAULT 'pending',
    payment_transaction_id TEXT,
    appointment_id UUID,
    shipping_address TEXT,
    notes TEXT,
    order_date TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    delivery_date TIMESTAMP WITH TIME ZONE,
    completion_date TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create shop_order_items table
CREATE TABLE IF NOT EXISTS public.shop_order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.shop_orders(id) ON DELETE CASCADE,
    service_id UUID REFERENCES public.vendor_services(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    description TEXT,
    price TEXT NOT NULL,
    category TEXT,
    vendor TEXT NOT NULL,
    vendor_id UUID REFERENCES public.vendor_user(id) ON DELETE SET NULL,
    image_url TEXT,
    quantity INTEGER NOT NULL DEFAULT 1,
    total_price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_shop_orders_customer_id ON public.shop_orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_shop_order_items_order_id ON public.shop_order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_shop_order_items_vendor_id ON public.shop_order_items(vendor_id);

-- Enable RLS
ALTER TABLE public.shop_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shop_order_items ENABLE ROW LEVEL SECURITY;

-- Create policies for shop_orders
CREATE POLICY "Customers can view their own shop orders" 
ON public.shop_orders FOR SELECT 
TO authenticated 
USING (auth.uid() = customer_id);

CREATE POLICY "Customers can create shop orders" 
ON public.shop_orders FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Customers can update their own shop orders" 
ON public.shop_orders FOR UPDATE 
TO authenticated 
USING (auth.uid() = customer_id);

-- Create policies for shop_order_items
CREATE POLICY "Customers can view their own order items" 
ON public.shop_order_items FOR SELECT 
TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM public.shop_orders
        WHERE shop_orders.id = shop_order_items.order_id
        AND shop_orders.customer_id = auth.uid()
    )
);

CREATE POLICY "Customers can insert order items" 
ON public.shop_order_items FOR INSERT 
TO authenticated 
WITH CHECK (
    EXISTS (
        SELECT 1 FROM public.shop_orders
        WHERE shop_orders.id = shop_order_items.order_id
        AND shop_orders.customer_id = auth.uid()
    )
);

CREATE POLICY "Vendors can view their items in orders" 
ON public.shop_order_items FOR SELECT 
TO authenticated 
USING (vendor_id = auth.uid());

CREATE POLICY "Vendors can view orders that contain their items" 
ON public.shop_orders FOR SELECT 
TO authenticated 
USING (
    EXISTS (
        SELECT 1 FROM public.shop_order_items
        WHERE shop_order_items.order_id = shop_orders.id
        AND shop_order_items.vendor_id = auth.uid()
    )
);

-- Update timestamp trigger
CREATE OR REPLACE FUNCTION update_shop_orders_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_shop_orders_updated_at
BEFORE UPDATE ON public.shop_orders
FOR EACH ROW
EXECUTE FUNCTION update_shop_orders_updated_at();

-- Add shop_order_id to installment_plans if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'installment_plans' AND column_name = 'shop_order_id') THEN
        ALTER TABLE public.installment_plans ADD COLUMN shop_order_id UUID REFERENCES public.shop_orders(id) ON DELETE CASCADE;
        
        -- Make booking_id optional since an installment plan can now belong to a booking OR a shop order
        ALTER TABLE public.installment_plans ALTER COLUMN booking_id DROP NOT NULL;
    END IF;
EXCEPTION
    WHEN undefined_table THEN
        -- installment_plans might not exist yet or we don't have access, ignore
        NULL;
END $$;
