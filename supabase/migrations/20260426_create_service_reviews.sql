-- Create service_reviews table
CREATE TABLE IF NOT EXISTS public.service_reviews (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES public.vendor_services(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_service_reviews_service_id ON public.service_reviews(service_id);
CREATE INDEX IF NOT EXISTS idx_service_reviews_customer_id ON public.service_reviews(customer_id);

-- Enable RLS
ALTER TABLE public.service_reviews ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Anyone can view reviews" 
ON public.service_reviews FOR SELECT 
USING (true);

CREATE POLICY "Users can submit reviews for their bookings" 
ON public.service_reviews FOR INSERT 
TO authenticated 
WITH CHECK (auth.uid() = customer_id);

CREATE POLICY "Users can update their own reviews" 
ON public.service_reviews FOR UPDATE 
TO authenticated 
USING (auth.uid() = customer_id);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_service_reviews_updated_at
    BEFORE UPDATE ON public.service_reviews
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Function to sync reviews to vendor_services JSONB column
CREATE OR REPLACE FUNCTION sync_service_reviews_to_vendor_service()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.vendor_services
    SET reviews = (
        SELECT json_agg(json_build_object(
            'id', r.id,
            'rating', r.rating,
            'comment', r.comment,
            'user', u.name,
            'date', r.created_at
        ))
        FROM public.service_reviews r
        JOIN public.customer_user u ON r.customer_id = u.id
        WHERE r.service_id = COALESCE(NEW.service_id, OLD.service_id)
    )
    WHERE id = COALESCE(NEW.service_id, OLD.service_id);
    
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER sync_reviews_on_insert_update
    AFTER INSERT OR UPDATE OR DELETE ON public.service_reviews
    FOR EACH ROW
    EXECUTE FUNCTION sync_service_reviews_to_vendor_service();
