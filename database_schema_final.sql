-- ===========================================
-- EVENTEASE COMPLETE DATABASE SCHEMA
-- ===========================================
-- This file defines the COMPLETE database structure for the EventEase application
-- Includes all 28 tables found in the codebase + services and products

-- ===========================================
-- TABLE OF CONTENTS (70 Tables)
-- ===========================================

-- 🔥 HIGH PRIORITY (Must Add Soon)
-- 1.  users                    - Main users table (Supabase Auth)
-- 2.  admin_user               - Admin user profiles
-- 3.  vendor_user              - Vendor user profiles
-- 4.  customer_user            - Customer user profiles
-- 5.  vendor_profiles          - Extended vendor information
-- 6.  vendor_analytics         - Vendor performance analytics
-- 7.  vendor_performance_metrics - Detailed vendor metrics
-- 8.  vendor_documents         - Vendor document storage
-- 9.  vendor_services          - Vendor service offerings
-- 10. product_performance      - Product analytics tracking
-- 11. bookings                 - Customer bookings
-- 12. reviews                  - Customer reviews
-- 13. subscription_tiers       - Subscription plans
-- 14. subscription_payments    - Subscription payment records
-- 15. notifications            - User notifications
-- 16. notification_settings    - Notification preferences
-- 17. chat_conversations       - Chat conversations
-- 18. chat_messages            - Chat messages
-- 19. chat_group_members       - Group chat members
-- 20. chat_typing_indicators   - Typing indicators
-- 21. admin_vendors            - Admin-vendor assignments
-- 22. admin_vendor_documents   - Admin vendor documents
-- 23. guest_invitations        - Guest user invitations
-- 24. reported_users           - User reports
-- 25. documents                - General document storage
-- 26. admin_service_categories - Service category management
-- 27. service_packages         - Service package definitions
-- 28. product_categories       - Product category management

-- ⭐ MEDIUM PRIORITY (Recommended)
-- 29. payments                 - Payment transactions
-- 30. refunds                  - Refund records
-- 31. audit_logs               - Admin/vendor action tracking
-- 32. user_device_tokens       - Push notification tokens
-- 33. favorites                - Customer favorites/wishlist
-- 34. vendor_availability      - Vendor scheduling
-- 35. vendor_payouts           - Vendor payment records
-- 36. disputes                 - Conflict resolution
-- 37. coupons                  - Promo codes & discounts
-- 38. app_settings             - Platform configuration

-- 🟪 LOW PRIORITY (Nice to have)
-- 39. search_history           - User search tracking
-- 40. vendor_portfolio         - Vendor work showcase
-- 41. event_checklists         - Event planning tools
-- 42. security_events          - Security monitoring

-- 💰 ADVANCED TABLES FOR PRO APPS
-- 43. platform_commissions     - Platform earnings tracking
-- 44. vendor_bank_accounts     - Multiple bank accounts per vendor
-- 45. payout_requests          - Vendor payout request system
-- 46. api_logs                 - Backend API usage tracking
-- 47. error_logs               - Automatic error logging
-- 48. maintenance_logs         - Maintenance mode tracking

-- 🎭 EVENT INDUSTRY–SPECIFIC TABLES
-- 49. venue_availability       - Date-based venue availability
-- 50. venue_rooms              - Multiple rooms per venue
-- 51. add_on_services          - Extra service items (upselling)
-- 52. event_types              - Wedding, Corporate, Birthday, etc.
-- 53. event_requirements_form  - Customer requirement submissions

-- 💰 MONETIZATION TABLES
-- 54. ads_campaigns            - Paid vendor promotions
-- 55. boosted_listings         - Boosted search results
-- 56. referral_program         - Referral code system
-- 57. wallet                   - User credits/wallet system

-- 🛡️ TRUST & SAFETY TABLES
-- 58. kyc_documents            - Identity verification
-- 59. fraud_flags              - Suspicious activity tracking
-- 60. moderation_queue         - Content moderation system
-- 61. banned_users             - User ban management

-- ⚙ INTERNAL OPERATION TABLES
-- 62. task_assignments          - Admin task management
-- 63. activity_feed             - Platform activity tracking
-- 64. admin_roles               - Granular admin permissions
-- 65. email_templates           - Email template management

-- 📊 ADVANCED ANALYTICS TABLES
-- 66. search_analytics          - Failed search tracking
-- 67. browsing_history          - User browsing behavior
-- 68. conversion_funnels        - User journey analytics
-- 69. vendor_response_time      - Chat response time tracking
-- 70. churn_reasons             - User churn analysis

-- ===========================================
-- STORAGE BUCKETS (6 Required)
-- ===========================================
-- 1. profile-pictures     - User profile images
-- 2. documents           - General file uploads
-- 3. vendor-documents    - Vendor-specific documents
-- 4. chat-attachments    - Chat file attachments
-- 5. event-photos        - Event-related photos
-- 6. service-images      - Service and package images

-- ===========================================
-- DROP TABLES (for safe re-running migrations)
-- ===========================================

-- Drop tables in reverse dependency order to avoid foreign key constraints
-- Wrapped in DO block to handle errors gracefully
DO $$
BEGIN
    -- Drop tables in reverse dependency order
    DROP TABLE IF EXISTS churn_reasons CASCADE;
    DROP TABLE IF EXISTS vendor_response_time CASCADE;
    DROP TABLE IF EXISTS conversion_funnels CASCADE;
    DROP TABLE IF EXISTS browsing_history CASCADE;
    DROP TABLE IF EXISTS search_analytics CASCADE;
    DROP TABLE IF EXISTS email_templates CASCADE;
    DROP TABLE IF EXISTS admin_role_assignments CASCADE;
    DROP TABLE IF EXISTS admin_roles CASCADE;
    DROP TABLE IF EXISTS activity_feed CASCADE;
    DROP TABLE IF EXISTS task_assignments CASCADE;
    DROP TABLE IF EXISTS banned_users CASCADE;
    DROP TABLE IF EXISTS moderation_queue CASCADE;
    DROP TABLE IF EXISTS fraud_flags CASCADE;
    DROP TABLE IF EXISTS kyc_documents CASCADE;
    DROP TABLE IF EXISTS wallet_transactions CASCADE;
    DROP TABLE IF EXISTS wallet CASCADE;
    DROP TABLE IF EXISTS referral_program CASCADE;
    DROP TABLE IF EXISTS boosted_listings CASCADE;
    DROP TABLE IF EXISTS ads_campaigns CASCADE;
    DROP TABLE IF EXISTS event_requirements_form CASCADE;
    DROP TABLE IF EXISTS event_types CASCADE;
    DROP TABLE IF EXISTS add_on_services CASCADE;
    DROP TABLE IF EXISTS venue_rooms CASCADE;
    DROP TABLE IF EXISTS venue_availability CASCADE;
    DROP TABLE IF EXISTS maintenance_logs CASCADE;
    DROP TABLE IF EXISTS error_logs CASCADE;
    DROP TABLE IF EXISTS api_logs CASCADE;
    DROP TABLE IF EXISTS payout_requests CASCADE;
    DROP TABLE IF EXISTS vendor_bank_accounts CASCADE;
    DROP TABLE IF EXISTS platform_commissions CASCADE;
    DROP TABLE IF EXISTS event_checklists CASCADE;
    DROP TABLE IF EXISTS vendor_portfolio CASCADE;
    DROP TABLE IF EXISTS app_settings CASCADE;
    DROP TABLE IF EXISTS coupons CASCADE;
    DROP TABLE IF EXISTS disputes CASCADE;
    DROP TABLE IF EXISTS vendor_availability CASCADE;
    DROP TABLE IF EXISTS search_history CASCADE;
    DROP TABLE IF EXISTS favorites CASCADE;
    DROP TABLE IF EXISTS security_events CASCADE;
    DROP TABLE IF EXISTS user_device_tokens CASCADE;
    DROP TABLE IF EXISTS audit_logs CASCADE;
    DROP TABLE IF EXISTS vendor_payouts CASCADE;
    DROP TABLE IF EXISTS refunds CASCADE;
    DROP TABLE IF EXISTS payments CASCADE;
    DROP TABLE IF EXISTS documents CASCADE;
    DROP TABLE IF EXISTS reported_users CASCADE;
    DROP TABLE IF EXISTS guest_invitations CASCADE;
    DROP TABLE IF EXISTS admin_vendor_documents CASCADE;
    DROP TABLE IF EXISTS admin_vendors CASCADE;
    DROP TABLE IF EXISTS chat_typing_indicators CASCADE;
    DROP TABLE IF EXISTS chat_group_members CASCADE;
    DROP TABLE IF EXISTS chat_messages CASCADE;
    DROP TABLE IF EXISTS chat_conversations CASCADE;
    DROP TABLE IF EXISTS notification_settings CASCADE;
    DROP TABLE IF EXISTS notifications CASCADE;
    DROP TABLE IF EXISTS subscription_payments CASCADE;
    DROP TABLE IF EXISTS subscription_tiers CASCADE;
    DROP TABLE IF EXISTS reviews CASCADE;
    DROP TABLE IF EXISTS bookings CASCADE;
    DROP TABLE IF EXISTS product_performance CASCADE;
    DROP TABLE IF EXISTS vendor_services CASCADE;
    DROP TABLE IF EXISTS vendor_documents CASCADE;
    DROP TABLE IF EXISTS vendor_performance_metrics CASCADE;
    DROP TABLE IF EXISTS vendor_analytics CASCADE;
    DROP TABLE IF EXISTS vendor_profiles CASCADE;
    DROP TABLE IF EXISTS customer_user CASCADE;
    DROP TABLE IF EXISTS vendor_user CASCADE;
    DROP TABLE IF EXISTS admin_user CASCADE;
    DROP TABLE IF EXISTS users CASCADE;
EXCEPTION WHEN OTHERS THEN
    -- Log the error but continue
    RAISE NOTICE 'Error dropping tables: %', SQLERRM;
END $$;

-- ===========================================
-- USERS AND AUTHENTICATION TABLES
-- ===========================================

-- Main users table (managed by Supabase Auth)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('admin', 'super_admin', 'vendor', 'customer')),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'banned')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Role-specific user tables
CREATE TABLE IF NOT EXISTS admin_user (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    role TEXT DEFAULT 'admin' CHECK (role = 'admin'),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'banned')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS vendor_user (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    role TEXT DEFAULT 'vendor' CHECK (role = 'vendor'),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'pending', 'suspended', 'banned')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS customer_user (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    role TEXT DEFAULT 'customer' CHECK (role = 'customer'),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'banned')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- VENDOR PROFILES AND ANALYTICS
-- ===========================================

-- Vendor profiles (extended information)
CREATE TABLE IF NOT EXISTS vendor_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES vendor_user(id) ON DELETE CASCADE,
    business_name TEXT NOT NULL,
    business_description TEXT,
    business_address TEXT,
    business_phone TEXT,
    business_email TEXT,
    website_url TEXT,
    profile_picture_url TEXT,
    profile_completion_percentage INTEGER DEFAULT 0 CHECK (profile_completion_percentage >= 0 AND profile_completion_percentage <= 100),
    profile_completion_status TEXT DEFAULT 'incomplete' CHECK (profile_completion_status IN ('incomplete', 'pending_review', 'approved', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Vendor analytics (must be created AFTER vendor_profiles)
CREATE TABLE IF NOT EXISTS vendor_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    total_views INTEGER DEFAULT 0,
    profile_views INTEGER DEFAULT 0,
    service_views INTEGER DEFAULT 0,
    contact_clicks INTEGER DEFAULT 0,
    bookings_count INTEGER DEFAULT 0,
    revenue DECIMAL(10,2) DEFAULT 0.00,
    total_revenue DECIMAL(10,2) DEFAULT 0.00,
    total_orders INTEGER DEFAULT 0,
    customer_segments JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vendor_id, date)
);

-- Vendor performance metrics
CREATE TABLE IF NOT EXISTS vendor_performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    metric_type TEXT NOT NULL,
    metric_value DECIMAL(10,2),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vendor_id, metric_type, period_start, period_end)
);

-- Vendor documents
CREATE TABLE IF NOT EXISTS vendor_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    document_url TEXT NOT NULL,
    document_name TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by UUID REFERENCES admin_user(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- VENDOR SERVICES
-- ===========================================

-- Vendor services (detailed service offerings)
CREATE TABLE IF NOT EXISTS vendor_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    subcategory TEXT,
    base_price DECIMAL(10,2),
    hourly_rate DECIMAL(10,2),
    active BOOLEAN DEFAULT true,
    approval_status TEXT DEFAULT 'pending' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    availability JSONB DEFAULT '{}',
    max_bookings_per_day INTEGER DEFAULT 10,
    advance_booking_days INTEGER DEFAULT 7,
    type TEXT NOT NULL,
    images JSONB DEFAULT '[]',
    options JSONB DEFAULT '{}',
    requirements JSONB DEFAULT '{}',
    logistics JSONB DEFAULT '{}',
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended', 'banned')),
    supports_appointments BOOLEAN DEFAULT false,
    supports_rentals BOOLEAN DEFAULT false,
    amenities JSONB DEFAULT '[]',
    cancellation_policy TEXT,
    reviews JSONB DEFAULT '[]',
    packages JSONB DEFAULT '[]',
    allowed_actions JSONB DEFAULT '[]',
    locations JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- PRODUCT PERFORMANCE
-- ===========================================

-- Product performance tracking
CREATE TABLE IF NOT EXISTS product_performance (
    product_id TEXT PRIMARY KEY,
    product_name TEXT NOT NULL,
    units_sold INTEGER DEFAULT 0,
    revenue DECIMAL(10,2) DEFAULT 0.00,
    profit DECIMAL(10,2) DEFAULT 0.00,
    views INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    conversion_rate DECIMAL(5,2) DEFAULT 0.00,
    average_rating DECIMAL(3,2) DEFAULT 0.00,
    review_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- BOOKINGS AND SERVICES
-- ===========================================

-- Bookings
CREATE TABLE IF NOT EXISTS bookings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customer_user(id) ON DELETE CASCADE,
    service_id UUID REFERENCES vendor_services(id) ON DELETE SET NULL,
    booking_date DATE NOT NULL,
    booking_time TIME NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled')),
    total_amount DECIMAL(10,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reviews
CREATE TABLE IF NOT EXISTS reviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID REFERENCES bookings(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customer_user(id) ON DELETE CASCADE,
    rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- SUBSCRIPTIONS AND PAYMENTS
-- ===========================================

-- Subscription tiers
CREATE TABLE IF NOT EXISTS subscription_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    duration_days INTEGER NOT NULL,
    features JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subscription payments
CREATE TABLE IF NOT EXISTS subscription_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    tier_id UUID NOT NULL REFERENCES subscription_tiers(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    payment_status TEXT DEFAULT 'pending' CHECK (payment_status IN ('pending', 'completed', 'failed', 'refunded')),
    payment_method TEXT,
    transaction_id TEXT,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- NOTIFICATIONS
-- ===========================================

-- Notifications
CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    is_archived BOOLEAN DEFAULT false,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notification settings
CREATE TABLE IF NOT EXISTS notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    email_notifications BOOLEAN DEFAULT true,
    push_notifications BOOLEAN DEFAULT true,
    sms_notifications BOOLEAN DEFAULT false,
    marketing_emails BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- ===========================================
-- CHAT SYSTEM
-- ===========================================

-- Chat conversations
CREATE TABLE IF NOT EXISTS chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    type TEXT NOT NULL CHECK (type IN ('direct', 'group')),
    name TEXT, -- For group chats
    description TEXT,
    avatar_url TEXT,
    created_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_active BOOLEAN DEFAULT true,
    last_message_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Chat messages
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message_type TEXT DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'system')),
    content TEXT,
    metadata JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Chat group members
CREATE TABLE IF NOT EXISTS chat_group_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT DEFAULT 'member' CHECK (role IN ('admin', 'member')),
    is_active BOOLEAN DEFAULT true,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

-- Chat typing indicators
CREATE TABLE IF NOT EXISTS chat_typing_indicators (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    is_typing BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(conversation_id, user_id)
);

-- ===========================================
-- ADMIN TABLES
-- ===========================================

-- Admin vendors (for admin management)
CREATE TABLE IF NOT EXISTS admin_vendors (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    admin_id UUID NOT NULL REFERENCES admin_user(id) ON DELETE CASCADE,
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'suspended')),
    notes TEXT,
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vendor_id, admin_id)
);

-- Admin vendor documents
CREATE TABLE IF NOT EXISTS admin_vendor_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_vendor_id UUID NOT NULL REFERENCES admin_vendors(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL,
    document_url TEXT NOT NULL,
    document_name TEXT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- GUEST AND REPORTING SYSTEM
-- ===========================================

-- Guest invitations
CREATE TABLE IF NOT EXISTS guest_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT NOT NULL,
    invited_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('admin', 'vendor', 'customer')),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'expired')),
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    accepted_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(email, invited_by)
);

-- Reported users
CREATE TABLE IF NOT EXISTS reported_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reported_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reported_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'investigating', 'resolved', 'dismissed')),
    resolved_by UUID REFERENCES admin_user(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- DOCUMENTS STORAGE
-- ===========================================

-- Documents (general document storage)
CREATE TABLE IF NOT EXISTS documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_path TEXT NOT NULL,
    file_size INTEGER,
    mime_type TEXT,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- PAYMENTS AND FINANCIAL TABLES
-- ===========================================

-- Payments / transactions (track all financial activity)
CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    amount DECIMAL(10,2) NOT NULL,
    payment_provider TEXT NOT NULL CHECK (payment_provider IN ('stripe', 'senangpay', 'toyyibpay', 'manual')),
    payment_method TEXT,
    transaction_id TEXT UNIQUE,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'failed', 'refunded', 'cancelled')),
    receipt_url TEXT,
    payment_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Refunds (track refund requests and processing)
CREATE TABLE IF NOT EXISTS refunds (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    payment_id UUID NOT NULL REFERENCES payments(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    reason TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'processed', 'rejected')),
    processed_by UUID REFERENCES admin_user(id),
    processed_at TIMESTAMP WITH TIME ZONE,
    refund_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Vendor payouts (platform payments to vendors)
CREATE TABLE IF NOT EXISTS vendor_payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    bank_account JSONB NOT NULL, -- Encrypted bank details
    payout_status TEXT DEFAULT 'pending' CHECK (payout_status IN ('pending', 'processing', 'completed', 'failed')),
    payout_date DATE,
    reference_id TEXT UNIQUE,
    payout_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- AUDIT AND SECURITY TABLES
-- ===========================================

-- Audit logs (track all admin/vendor actions)
CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- User device tokens (for push notifications)
CREATE TABLE IF NOT EXISTS user_device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_token TEXT NOT NULL UNIQUE,
    device_type TEXT NOT NULL CHECK (device_type IN ('ios', 'android', 'web')),
    device_model TEXT,
    app_version TEXT,
    is_active BOOLEAN DEFAULT true,
    last_used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, device_token)
);

-- Security events (track security-related activities)
CREATE TABLE IF NOT EXISTS security_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    severity TEXT DEFAULT 'low' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    ip_address INET,
    user_agent TEXT,
    description TEXT,
    metadata JSONB DEFAULT '{}',
    resolved BOOLEAN DEFAULT false,
    resolved_by UUID REFERENCES admin_user(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- USER ENGAGEMENT TABLES
-- ===========================================

-- Favorites / wishlist (customer saved items)
CREATE TABLE IF NOT EXISTS favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    item_type TEXT NOT NULL CHECK (item_type IN ('vendor', 'service', 'product')),
    item_id UUID NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, item_type, item_id)
);

-- Search history (track user searches for recommendations)
CREATE TABLE IF NOT EXISTS search_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    search_query TEXT NOT NULL,
    search_type TEXT NOT NULL CHECK (search_type IN ('vendor', 'service', 'location', 'category')),
    filters JSONB DEFAULT '{}',
    results_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- SCHEDULING AND AVAILABILITY
-- ===========================================

-- Vendor availability (control vendor schedules)
CREATE TABLE IF NOT EXISTS vendor_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT true,
    is_blocked BOOLEAN DEFAULT false,
    block_reason TEXT,
    recurring BOOLEAN DEFAULT false,
    recurring_pattern TEXT, -- 'daily', 'weekly', 'monthly'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vendor_id, date, start_time, end_time)
);

-- ===========================================
-- CONFLICT RESOLUTION
-- ===========================================

-- Disputes / conflict resolution
CREATE TABLE IF NOT EXISTS disputes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    initiator_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    respondent_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    booking_id UUID REFERENCES bookings(id) ON DELETE SET NULL,
    dispute_type TEXT NOT NULL CHECK (dispute_type IN ('booking_issue', 'refund_request', 'service_quality', 'communication', 'fraud', 'other')),
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'closed')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    evidence JSONB DEFAULT '[]', -- File URLs, messages, etc.
    resolution TEXT,
    resolved_by UUID REFERENCES admin_user(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- PROMOTIONS AND CONFIGURATION
-- ===========================================

-- Coupons / promo codes
CREATE TABLE IF NOT EXISTS coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code TEXT NOT NULL UNIQUE,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'fixed_amount')),
    discount_value DECIMAL(10,2) NOT NULL,
    minimum_order_amount DECIMAL(10,2) DEFAULT 0,
    maximum_discount_amount DECIMAL(10,2),
    usage_limit INTEGER,
    usage_count INTEGER DEFAULT 0,
    valid_from TIMESTAMP WITH TIME ZONE NOT NULL,
    valid_until TIMESTAMP WITH TIME ZONE NOT NULL,
    applicable_to TEXT DEFAULT 'all' CHECK (applicable_to IN ('all', 'vendors', 'services', 'bookings')),
    applicable_items JSONB DEFAULT '[]', -- Specific vendor/service IDs
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES admin_user(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- App settings (platform-wide configuration)
CREATE TABLE IF NOT EXISTS app_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    setting_key TEXT NOT NULL UNIQUE,
    setting_value JSONB NOT NULL,
    setting_type TEXT NOT NULL CHECK (setting_type IN ('string', 'number', 'boolean', 'json')),
    description TEXT,
    is_system BOOLEAN DEFAULT false,
    updated_by UUID REFERENCES admin_user(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- PORTFOLIO AND PLANNING
-- ===========================================

-- Vendor portfolio (showcase of work)
CREATE TABLE IF NOT EXISTS vendor_portfolio (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video', 'document')),
    media_url TEXT NOT NULL,
    thumbnail_url TEXT,
    category TEXT,
    tags JSONB DEFAULT '[]',
    is_featured BOOLEAN DEFAULT false,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event checklists (customer planning tools)
CREATE TABLE IF NOT EXISTS event_checklists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    due_date DATE,
    completed_at TIMESTAMP WITH TIME ZONE,
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    assigned_to UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- ADVANCED TABLES FOR PRO APPS
-- ===========================================

-- Platform commissions (tracks platform earnings from each booking)
CREATE TABLE IF NOT EXISTS platform_commissions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    platform_fee DECIMAL(10,2) NOT NULL,
    vendor_earnings DECIMAL(10,2) NOT NULL,
    commission_rate DECIMAL(5,2) NOT NULL,
    admin_id UUID REFERENCES admin_user(id),
    payment_id UUID REFERENCES payments(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Vendor bank accounts (multiple accounts per vendor for payouts)
CREATE TABLE IF NOT EXISTS vendor_bank_accounts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    bank_name TEXT NOT NULL,
    account_holder_name TEXT NOT NULL,
    account_number TEXT NOT NULL,
    routing_number TEXT,
    swift_code TEXT,
    currency TEXT DEFAULT 'MYR',
    is_primary BOOLEAN DEFAULT false,
    is_verified BOOLEAN DEFAULT false,
    verification_documents JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Payout requests (vendor requests payment → admin approves)
CREATE TABLE IF NOT EXISTS payout_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    bank_account_id UUID NOT NULL REFERENCES vendor_bank_accounts(id),
    amount DECIMAL(10,2) NOT NULL,
    currency TEXT DEFAULT 'MYR',
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'processing', 'completed', 'rejected')),
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE,
    processed_at TIMESTAMP WITH TIME ZONE,
    approved_by UUID REFERENCES admin_user(id),
    rejection_reason TEXT,
    reference_number TEXT UNIQUE,
    payout_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- API logs (tracks backend API usage for debugging/security)
CREATE TABLE IF NOT EXISTS api_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    endpoint TEXT NOT NULL,
    method TEXT NOT NULL,
    status_code INTEGER,
    response_time INTEGER, -- in milliseconds
    ip_address INET,
    user_agent TEXT,
    request_data JSONB,
    response_data JSONB,
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Error logs (automatic logging for crashes/failures)
CREATE TABLE IF NOT EXISTS error_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    error_type TEXT NOT NULL,
    error_message TEXT NOT NULL,
    stack_trace TEXT,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    endpoint TEXT,
    request_data JSONB,
    severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    is_resolved BOOLEAN DEFAULT false,
    resolved_by UUID REFERENCES admin_user(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Maintenance logs (maintenance mode tracking)
CREATE TABLE IF NOT EXISTS maintenance_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    status TEXT NOT NULL CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled')),
    reason TEXT NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    estimated_duration INTERVAL,
    affected_services JSONB DEFAULT '[]',
    changed_by UUID NOT NULL REFERENCES admin_user(id),
    notification_sent BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- EVENT INDUSTRY–SPECIFIC TABLES
-- ===========================================

-- Venue rooms (multiple halls/rooms per venue) - Must be created BEFORE venue_availability
CREATE TABLE IF NOT EXISTS venue_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    room_name TEXT NOT NULL,
    room_type TEXT NOT NULL CHECK (room_type IN ('hall', 'room', 'outdoor', 'indoor')),
    capacity INTEGER NOT NULL,
    size_sqm DECIMAL(8,2),
    description TEXT,
    base_price DECIMAL(10,2),
    images JSONB DEFAULT '[]',
    amenities JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Venue availability (date-based venue availability) - References venue_rooms
CREATE TABLE IF NOT EXISTS venue_availability (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    venue_room_id UUID REFERENCES venue_rooms(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    is_available BOOLEAN DEFAULT true,
    is_blocked BOOLEAN DEFAULT false,
    block_reason TEXT,
    booking_id UUID REFERENCES bookings(id),
    price_override DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vendor_id, venue_room_id, date, start_time, end_time)
);

-- Add-on services (extra service items for upselling)
CREATE TABLE IF NOT EXISTS add_on_services (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    service_id UUID REFERENCES vendor_services(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    category TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    max_quantity INTEGER DEFAULT 10,
    images JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event types (Wedding, Corporate, Birthday, etc.)
CREATE TABLE IF NOT EXISTS event_types (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    category TEXT NOT NULL,
    icon_url TEXT,
    is_active BOOLEAN DEFAULT true,
    display_order INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event requirements form (customer requirement submissions)
CREATE TABLE IF NOT EXISTS event_requirements_form (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    event_type_id UUID REFERENCES event_types(id),
    event_date DATE NOT NULL,
    guest_count INTEGER NOT NULL,
    budget_range TEXT NOT NULL,
    venue_type TEXT NOT NULL,
    theme TEXT,
    special_requests TEXT,
    preferred_vendors JSONB DEFAULT '[]',
    timeline_requirements JSONB DEFAULT '{}',
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'submitted', 'reviewed', 'matched')),
    reviewed_by UUID REFERENCES admin_user(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- MONETIZATION TABLES
-- ===========================================

-- Ads campaigns (paid vendor promotions)
CREATE TABLE IF NOT EXISTS ads_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    campaign_name TEXT NOT NULL,
    campaign_type TEXT NOT NULL CHECK (campaign_type IN ('boosted_listing', 'featured_vendor', 'banner_ad', 'sponsored_search')),
    budget DECIMAL(10,2) NOT NULL,
    spent DECIMAL(10,2) DEFAULT 0.00,
    impressions INTEGER DEFAULT 0,
    clicks INTEGER DEFAULT 0,
    conversions INTEGER DEFAULT 0,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'active', 'paused', 'completed', 'cancelled')),
    targeting JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Boosted listings (boosted search results)
CREATE TABLE IF NOT EXISTS boosted_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    campaign_id UUID REFERENCES ads_campaigns(id),
    boost_type TEXT NOT NULL CHECK (boost_type IN ('search_priority', 'featured_badge', 'top_listing')),
    boost_duration_hours INTEGER NOT NULL,
    boost_start TIMESTAMP WITH TIME ZONE NOT NULL,
    boost_end TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    search_keywords JSONB DEFAULT '[]',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Referral program (referral code system)
CREATE TABLE IF NOT EXISTS referral_program (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referrer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    referee_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    referral_code TEXT NOT NULL UNIQUE,
    reward_type TEXT NOT NULL CHECK (reward_type IN ('credit', 'discount', 'free_service')),
    reward_amount DECIMAL(10,2),
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'qualified', 'rewarded', 'expired')),
    qualified_at TIMESTAMP WITH TIME ZONE,
    rewarded_at TIMESTAMP WITH TIME ZONE,
    expiry_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Wallet / credits (user credits/wallet system)
CREATE TABLE IF NOT EXISTS wallet (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    balance DECIMAL(10,2) DEFAULT 0.00,
    currency TEXT DEFAULT 'MYR',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Wallet transactions (track credit usage)
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES wallet(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('credit', 'debit', 'refund', 'reward', 'purchase')),
    amount DECIMAL(10,2) NOT NULL,
    balance_before DECIMAL(10,2) NOT NULL,
    balance_after DECIMAL(10,2) NOT NULL,
    reference_type TEXT,
    reference_id UUID,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- TRUST & SAFETY TABLES
-- ===========================================

-- KYC documents (identity verification)
CREATE TABLE IF NOT EXISTS kyc_documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    document_type TEXT NOT NULL CHECK (document_type IN ('passport', 'driving_license', 'national_id', 'business_license', 'tax_certificate')),
    document_number TEXT,
    document_url TEXT NOT NULL,
    selfie_url TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'approved', 'rejected')),
    rejection_reason TEXT,
    verified_by UUID REFERENCES admin_user(id),
    verified_at TIMESTAMP WITH TIME ZONE,
    expiry_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Fraud flags (suspicious activity tracking)
CREATE TABLE IF NOT EXISTS fraud_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    flag_type TEXT NOT NULL CHECK (flag_type IN ('too_many_cancellations', 'duplicate_accounts', 'fake_bookings', 'suspicious_payments', 'unusual_activity')),
    severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    description TEXT NOT NULL,
    evidence JSONB DEFAULT '{}',
    is_resolved BOOLEAN DEFAULT false,
    resolved_by UUID REFERENCES admin_user(id),
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Moderation queue (content moderation system)
CREATE TABLE IF NOT EXISTS moderation_queue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    content_type TEXT NOT NULL CHECK (content_type IN ('review', 'message', 'profile', 'service_description', 'portfolio')),
    content_id UUID NOT NULL,
    reported_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reason TEXT NOT NULL,
    description TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'approved', 'rejected', 'escalated')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    assigned_to UUID REFERENCES admin_user(id),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    action_taken TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Banned users (user ban management)
CREATE TABLE IF NOT EXISTS banned_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    ban_type TEXT NOT NULL CHECK (ban_type IN ('temporary', 'permanent')),
    reason TEXT NOT NULL,
    banned_by UUID NOT NULL REFERENCES admin_user(id),
    ban_start TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ban_end TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN DEFAULT true,
    appeal_status TEXT DEFAULT 'none' CHECK (appeal_status IN ('none', 'pending', 'approved', 'rejected')),
    appeal_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- INTERNAL OPERATION TABLES
-- ===========================================

-- Task assignments (admin task management)
CREATE TABLE IF NOT EXISTS task_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    task_type TEXT NOT NULL CHECK (task_type IN ('document_verification', 'vendor_approval', 'dispute_resolution', 'payment_review', 'content_moderation', 'user_support')),
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high', 'urgent')),
    status TEXT DEFAULT 'open' CHECK (status IN ('open', 'in_progress', 'completed', 'cancelled')),
    assigned_to UUID REFERENCES admin_user(id),
    assigned_by UUID REFERENCES admin_user(id),
    due_date TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    related_entity_type TEXT,
    related_entity_id UUID,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Activity feed (platform activity tracking)
CREATE TABLE IF NOT EXISTS activity_feed (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id UUID,
    metadata JSONB DEFAULT '{}',
    visibility TEXT DEFAULT 'admin' CHECK (visibility IN ('public', 'admin', 'vendor', 'customer')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin roles (granular admin permissions)
CREATE TABLE IF NOT EXISTS admin_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role_name TEXT NOT NULL UNIQUE,
    description TEXT,
    permissions JSONB NOT NULL DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin role assignments
CREATE TABLE IF NOT EXISTS admin_role_assignments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES admin_user(id) ON DELETE CASCADE,
    role_id UUID NOT NULL REFERENCES admin_roles(id) ON DELETE CASCADE,
    assigned_by UUID REFERENCES admin_user(id),
    assigned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(admin_id, role_id)
);

-- Email templates (email template management)
CREATE TABLE IF NOT EXISTS email_templates (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    template_key TEXT NOT NULL UNIQUE,
    subject TEXT NOT NULL,
    html_content TEXT NOT NULL,
    text_content TEXT,
    variables JSONB DEFAULT '[]',
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES admin_user(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- ADVANCED ANALYTICS TABLES
-- ===========================================

-- Search analytics (failed search tracking)
CREATE TABLE IF NOT EXISTS search_analytics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    search_query TEXT NOT NULL,
    search_type TEXT NOT NULL,
    filters_applied JSONB DEFAULT '{}',
    results_count INTEGER DEFAULT 0,
    clicked_result_id UUID,
    conversion_happened BOOLEAN DEFAULT false,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Browsing history (user browsing behavior)
CREATE TABLE IF NOT EXISTS browsing_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    entity_type TEXT NOT NULL CHECK (entity_type IN ('vendor', 'service', 'product', 'event')),
    entity_id UUID NOT NULL,
    view_duration INTEGER, -- in seconds
    source TEXT, -- how they found it (search, recommendation, etc.)
    device_type TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Conversion funnels (user journey analytics)
CREATE TABLE IF NOT EXISTS conversion_funnels (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    session_id TEXT NOT NULL,
    step TEXT NOT NULL CHECK (step IN ('profile_view', 'browse', 'chat_initiated', 'booking_started', 'payment_completed')),
    step_order INTEGER NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Vendor response time (chat response time tracking)
CREATE TABLE IF NOT EXISTS vendor_response_time (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    response_time_seconds INTEGER NOT NULL,
    message_type TEXT DEFAULT 'initial' CHECK (message_type IN ('initial', 'follow_up')),
    customer_rating INTEGER CHECK (customer_rating >= 1 AND customer_rating <= 5),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Churn reasons (user churn analysis)
CREATE TABLE IF NOT EXISTS churn_reasons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    churn_type TEXT NOT NULL CHECK (churn_type IN ('voluntary', 'involuntary')),
    primary_reason TEXT NOT NULL,
    secondary_reasons JSONB DEFAULT '[]',
    feedback TEXT,
    likelihood_to_return TEXT CHECK (likelihood_to_return IN ('very_unlikely', 'unlikely', 'neutral', 'likely', 'very_likely')),
    collected_by UUID REFERENCES admin_user(id),
    collected_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ===========================================
-- DATABASE TRIGGERS AND FUNCTIONS
-- ===========================================

-- Function to create user profile based on role
CREATE OR REPLACE FUNCTION create_user_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert into users table with correct role
    INSERT INTO users (id, email, role)
    VALUES (NEW.id, NEW.email, COALESCE(NEW.raw_user_meta_data->>'role', 'customer'));

    -- Create role-specific profile
    CASE COALESCE(NEW.raw_user_meta_data->>'role', 'customer')
        WHEN 'admin' THEN
            INSERT INTO admin_user (id, name, email, phone)
            VALUES (
                NEW.id,
                COALESCE(NEW.raw_user_meta_data->>'name', 'Admin User'),
                NEW.email,
                COALESCE(NEW.raw_user_meta_data->>'phone', '')
            );
        WHEN 'vendor' THEN
            INSERT INTO vendor_user (id, name, email, phone)
            VALUES (
                NEW.id,
                COALESCE(NEW.raw_user_meta_data->>'name', 'Vendor User'),
                NEW.email,
                COALESCE(NEW.raw_user_meta_data->>'phone', '')
            );
        ELSE
            INSERT INTO customer_user (id, name, email, phone)
            VALUES (
                NEW.id,
                COALESCE(NEW.raw_user_meta_data->>'name', 'Customer User'),
                NEW.email,
                COALESCE(NEW.raw_user_meta_data->>'phone', '')
            );
    END CASE;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create vendor profile when vendor_user is created
CREATE OR REPLACE FUNCTION create_vendor_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- Create basic vendor profile when vendor_user is created
    INSERT INTO vendor_profiles (user_id, business_name)
    VALUES (NEW.id, COALESCE(NEW.name, 'Business Name'));

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create vendor analytics when profile is created
CREATE OR REPLACE FUNCTION create_vendor_analytics_on_profile()
RETURNS TRIGGER AS $$
BEGIN
    -- Create initial analytics record when vendor profile is created
    INSERT INTO vendor_analytics (vendor_id, date)
    VALUES (NEW.id, CURRENT_DATE)
    ON CONFLICT (vendor_id, date) DO NOTHING;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION create_user_profile();

DROP TRIGGER IF EXISTS on_vendor_user_created ON vendor_user;
CREATE TRIGGER on_vendor_user_created
    AFTER INSERT ON vendor_user
    FOR EACH ROW EXECUTE FUNCTION create_vendor_profile();

DROP TRIGGER IF EXISTS on_vendor_profile_created ON vendor_profiles;
CREATE TRIGGER on_vendor_profile_created
    AFTER INSERT ON vendor_profiles
    FOR EACH ROW EXECUTE FUNCTION create_vendor_analytics_on_profile();

-- ===========================================
-- INDEXES FOR PERFORMANCE
-- ===========================================

-- User and auth indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_status ON users(status);

-- Vendor indexes
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_user_id ON vendor_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_vendor_analytics_vendor_id ON vendor_analytics(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_analytics_date ON vendor_analytics(date);
CREATE INDEX IF NOT EXISTS idx_vendor_documents_vendor_id ON vendor_documents(vendor_id);

-- Vendor services indexes
CREATE INDEX IF NOT EXISTS idx_vendor_services_vendor_id ON vendor_services(vendor_id);
CREATE INDEX IF NOT EXISTS idx_vendor_services_category ON vendor_services(category);
CREATE INDEX IF NOT EXISTS idx_vendor_services_approval_status ON vendor_services(approval_status);
CREATE INDEX IF NOT EXISTS idx_vendor_services_active ON vendor_services(active);

-- Product performance indexes
CREATE INDEX IF NOT EXISTS idx_product_performance_product_name ON product_performance(product_name);
CREATE INDEX IF NOT EXISTS idx_product_performance_is_active ON product_performance(is_active);

-- Booking and review indexes
CREATE INDEX IF NOT EXISTS idx_bookings_vendor_id ON bookings(vendor_id);
CREATE INDEX IF NOT EXISTS idx_bookings_customer_id ON bookings(customer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(booking_date);
CREATE INDEX IF NOT EXISTS idx_reviews_vendor_id ON reviews(vendor_id);
CREATE INDEX IF NOT EXISTS idx_reviews_customer_id ON reviews(customer_id);

-- Subscription indexes
CREATE INDEX IF NOT EXISTS idx_subscription_payments_vendor_id ON subscription_payments(vendor_id);
CREATE INDEX IF NOT EXISTS idx_subscription_payments_status ON subscription_payments(payment_status);

-- Notification indexes
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at);

-- Chat indexes
CREATE INDEX IF NOT EXISTS idx_chat_conversations_created_by ON chat_conversations(created_by);
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation_id ON chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_id ON chat_messages(sender_id);
CREATE INDEX IF NOT EXISTS idx_chat_group_members_conversation_id ON chat_group_members(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_group_members_user_id ON chat_group_members(user_id);

-- Admin indexes
CREATE INDEX IF NOT EXISTS idx_admin_vendors_vendor_id ON admin_vendors(vendor_id);
CREATE INDEX IF NOT EXISTS idx_admin_vendors_admin_id ON admin_vendors(admin_id);

-- Guest and reporting indexes
CREATE INDEX IF NOT EXISTS idx_guest_invitations_email ON guest_invitations(email);
CREATE INDEX IF NOT EXISTS idx_guest_invitations_status ON guest_invitations(status);
CREATE INDEX IF NOT EXISTS idx_reported_users_reported_user_id ON reported_users(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_reported_users_status ON reported_users(status);

-- Document indexes
CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents(user_id);

-- ===========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ===========================================

-- Enable RLS on all tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_performance ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_typing_indicators ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_vendors ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_vendor_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE guest_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE reported_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE refunds ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_payouts ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_device_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE search_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons ENABLE ROW LEVEL SECURITY;
ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_portfolio ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE platform_commissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE payout_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE error_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE maintenance_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE venue_availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE venue_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE add_on_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_requirements_form ENABLE ROW LEVEL SECURITY;
ALTER TABLE ads_campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE boosted_listings ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_program ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE kyc_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE fraud_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE moderation_queue ENABLE ROW LEVEL SECURITY;
ALTER TABLE banned_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE task_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE activity_feed ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_role_assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_templates ENABLE ROW LEVEL SECURITY;
ALTER TABLE search_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE browsing_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE conversion_funnels ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_response_time ENABLE ROW LEVEL SECURITY;
ALTER TABLE churn_reasons ENABLE ROW LEVEL SECURITY;

-- Drop existing policies (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view their own record" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Vendors can view their own profile" ON vendor_profiles;
DROP POLICY IF EXISTS "Admins can view all vendor profiles" ON vendor_profiles;
DROP POLICY IF EXISTS "Vendors can view their own analytics" ON vendor_analytics;
DROP POLICY IF EXISTS "Admins can view all vendor analytics" ON vendor_analytics;

-- Users table policies
CREATE POLICY "Users can view their own record" ON users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Vendor profiles policies
CREATE POLICY "Vendors can view their own profile" ON vendor_profiles
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all vendor profiles" ON vendor_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Vendor analytics policies
CREATE POLICY "Vendors can view their own analytics" ON vendor_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_analytics.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all vendor analytics" ON vendor_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Vendor services policies
CREATE POLICY "Vendors can manage their own services" ON vendor_services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_services.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all vendor services" ON vendor_services
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "Customers can view approved services" ON vendor_services
    FOR SELECT USING (active = true AND approval_status = 'approved');

-- Basic policies for other tables (customize as needed)
-- These are basic policies - you may need to adjust based on your security requirements

CREATE POLICY "Users can view their own notifications" ON notifications
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage their own notification settings" ON notification_settings
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can view chat conversations they are members of" ON chat_conversations
    FOR SELECT USING (
        auth.uid() = created_by OR
        EXISTS (
            SELECT 1 FROM chat_group_members
            WHERE conversation_id = chat_conversations.id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can view messages in conversations they are members of" ON chat_messages
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM chat_group_members
            WHERE conversation_id = chat_messages.conversation_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can view their own documents" ON documents
    FOR ALL USING (auth.uid() = user_id);

-- Payments policies
CREATE POLICY "Users can view their own payments" ON payments
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all payments" ON payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Refunds policies
CREATE POLICY "Users can view their own refunds" ON refunds
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all refunds" ON refunds
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Vendor payouts policies
CREATE POLICY "Vendors can view their own payouts" ON vendor_payouts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_payouts.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage all payouts" ON vendor_payouts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Audit logs policies (admins only)
CREATE POLICY "Admins can view all audit logs" ON audit_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- User device tokens policies
CREATE POLICY "Users can manage their own device tokens" ON user_device_tokens
    FOR ALL USING (auth.uid() = user_id);

-- Security events policies (admins only)
CREATE POLICY "Admins can view all security events" ON security_events
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Favorites policies
CREATE POLICY "Users can manage their own favorites" ON favorites
    FOR ALL USING (auth.uid() = user_id);

-- Search history policies
CREATE POLICY "Users can view their own search history" ON search_history
    FOR SELECT USING (auth.uid() = user_id);

-- Vendor availability policies
CREATE POLICY "Vendors can manage their own availability" ON vendor_availability
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_availability.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Customers can view vendor availability" ON vendor_availability
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_availability.vendor_id
        )
    );

-- Disputes policies
CREATE POLICY "Users can view disputes they are involved in" ON disputes
    FOR SELECT USING (auth.uid() IN (initiator_id, respondent_id));

CREATE POLICY "Admins can manage all disputes" ON disputes
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Coupons policies
CREATE POLICY "Admins can manage coupons" ON coupons
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "Customers can view active coupons" ON coupons
    FOR SELECT USING (is_active = true);

-- App settings policies (admins only)
CREATE POLICY "Admins can manage app settings" ON app_settings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Vendor portfolio policies
CREATE POLICY "Vendors can manage their own portfolio" ON vendor_portfolio
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_portfolio.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Customers can view vendor portfolios" ON vendor_portfolio
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_portfolio.vendor_id
        )
    );

-- Event checklists policies
CREATE POLICY "Users can manage their own checklists" ON event_checklists
    FOR ALL USING (auth.uid() = user_id);

-- Platform commissions policies (admins only)
CREATE POLICY "Admins can view all commissions" ON platform_commissions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Vendor bank accounts policies
CREATE POLICY "Vendors can manage their own bank accounts" ON vendor_bank_accounts
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_bank_accounts.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all bank accounts" ON vendor_bank_accounts
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Payout requests policies
CREATE POLICY "Vendors can view their own payout requests" ON payout_requests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = payout_requests.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can manage all payout requests" ON payout_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- API logs policies (admins only)
CREATE POLICY "Admins can view all API logs" ON api_logs
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Error logs policies (admins only)
CREATE POLICY "Admins can view all error logs" ON error_logs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Maintenance logs policies (admins only)
CREATE POLICY "Admins can manage maintenance logs" ON maintenance_logs
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Venue availability policies
CREATE POLICY "Vendors can manage their own venue availability" ON venue_availability
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = venue_availability.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Customers can view venue availability" ON venue_availability
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = venue_availability.vendor_id
        )
    );

-- Venue rooms policies
CREATE POLICY "Vendors can manage their own venue rooms" ON venue_rooms
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = venue_rooms.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Customers can view venue rooms" ON venue_rooms
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = venue_rooms.vendor_id
        )
    );

-- Add-on services policies
CREATE POLICY "Vendors can manage their own add-on services" ON add_on_services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = add_on_services.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Customers can view add-on services" ON add_on_services
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = add_on_services.vendor_id
        )
    );

-- Event types policies (public read)
CREATE POLICY "Everyone can view active event types" ON event_types
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage event types" ON event_types
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Event requirements form policies
CREATE POLICY "Users can manage their own requirements forms" ON event_requirements_form
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can view all requirements forms" ON event_requirements_form
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Ads campaigns policies
CREATE POLICY "Vendors can manage their own campaigns" ON ads_campaigns
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = ads_campaigns.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all campaigns" ON ads_campaigns
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Boosted listings policies (public read for active boosts)
CREATE POLICY "Everyone can view active boosted listings" ON boosted_listings
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage boosted listings" ON boosted_listings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Referral program policies
CREATE POLICY "Users can view their own referrals" ON referral_program
    FOR SELECT USING (auth.uid() = referrer_id);

CREATE POLICY "Admins can view all referrals" ON referral_program
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Wallet policies
CREATE POLICY "Users can view their own wallet" ON wallet
    FOR ALL USING (auth.uid() = user_id);

-- Wallet transactions policies
CREATE POLICY "Users can view their own wallet transactions" ON wallet_transactions
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM wallet
            WHERE id = wallet_transactions.wallet_id
            AND user_id = auth.uid()
        )
    );

-- KYC documents policies
CREATE POLICY "Users can manage their own KYC documents" ON kyc_documents
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Admins can manage all KYC documents" ON kyc_documents
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Fraud flags policies (admins only)
CREATE POLICY "Admins can manage all fraud flags" ON fraud_flags
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Moderation queue policies (admins only)
CREATE POLICY "Admins can manage moderation queue" ON moderation_queue
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Banned users policies (admins only)
CREATE POLICY "Admins can manage banned users" ON banned_users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Task assignments policies (admins only)
CREATE POLICY "Admins can manage task assignments" ON task_assignments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Activity feed policies
CREATE POLICY "Admins can view all activity" ON activity_feed
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

CREATE POLICY "Vendors can view their own activity" ON activity_feed
    FOR SELECT USING (
        auth.uid() = actor_id OR
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE user_id = auth.uid()
        )
    );

-- Admin roles policies (admins only)
CREATE POLICY "Admins can manage admin roles" ON admin_roles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Admin role assignments policies (admins only)
CREATE POLICY "Admins can manage role assignments" ON admin_role_assignments
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Email templates policies (admins only)
CREATE POLICY "Admins can manage email templates" ON email_templates
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Search analytics policies (admins only)
CREATE POLICY "Admins can view search analytics" ON search_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Browsing history policies
CREATE POLICY "Users can view their own browsing history" ON browsing_history
    FOR SELECT USING (auth.uid() = user_id);

-- Conversion funnels policies (admins only)
CREATE POLICY "Admins can view conversion funnels" ON conversion_funnels
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Vendor response time policies
CREATE POLICY "Vendors can view their own response times" ON vendor_response_time
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_response_time.vendor_id
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Admins can view all response times" ON vendor_response_time
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Churn reasons policies (admins only)
CREATE POLICY "Admins can manage churn reasons" ON churn_reasons
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
        )
    );

-- Add more policies as needed for your specific security requirements

-- ===========================================
-- STORAGE BUCKETS
-- ===========================================
-- These need to be created manually in Supabase Storage Dashboard:
-- 1. profile-pictures
-- 2. documents
-- 3. vendor-documents
-- 4. chat-attachments
-- 5. event-photos
-- 6. service-images
