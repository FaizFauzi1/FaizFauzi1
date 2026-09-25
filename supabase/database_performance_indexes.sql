-- ==============================================================================
-- EventEase Performance Indexes for High-Traffic Marketplace Endpoints
-- Aligned with k6 load test scenarios and mobile app query patterns.
-- ==============================================================================

-- 1. Vendor Profiles Sorting & Search
-- Covers: GET /vendor_profiles?order=priority_score.desc&limit=20
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_priority 
ON public.vendor_profiles (priority_score DESC);

-- Covers: GET /vendor_profiles?business_name=ilike.*query* (Trigram index for fast ILIKE)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_name_trgm 
ON public.vendor_profiles USING gin (business_name gin_trgm_ops);

-- 2. Vendor Services Filtering & Pagination
-- Covers: GET /vendor_services?category=eq.X&is_active=eq.true&order=base_price.asc
CREATE INDEX IF NOT EXISTS idx_vendor_services_composite_search 
ON public.vendor_services (category, is_active, base_price);

-- Covers: GET /vendor_services?order=created_at.desc&offset=X
CREATE INDEX IF NOT EXISTS idx_vendor_services_created_at 
ON public.vendor_services (created_at DESC);

-- 3. Service Categories & Event Types
-- Covers: GET /service_categories?is_active=eq.true&order=display_order.asc
CREATE INDEX IF NOT EXISTS idx_service_categories_active_order 
ON public.service_categories (is_active, display_order ASC);

-- 4. Customer Bookings Deep Queries
-- Covers: GET /bookings?customer_id=eq.X&order=booking_date.desc
CREATE INDEX IF NOT EXISTS idx_bookings_customer_date 
ON public.bookings (customer_id, booking_date DESC);
