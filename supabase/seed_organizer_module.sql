-- Wedding Event Organizer — demo seed for Supabase (live mode)
-- Run while signed in as the organizer account:
--   select public.seed_organizer_module();
-- Or for a specific user:
--   select public.seed_organizer_module('YOUR-USER-UUID'::uuid);
--
-- Requires migration 20260530_organizer_module_schema.sql applied first.
-- Idempotent: safe to re-run (uses ON CONFLICT).

CREATE OR REPLACE FUNCTION public.seed_organizer_module(p_owner_user_id UUID DEFAULT auth.uid())
RETURNS TEXT
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_company_id UUID := 'a0000000-0000-4000-8000-000000000001';
  v_expo_ongoing UUID := 'a0000000-0000-4000-8000-000000000101';
  v_expo_upcoming UUID := 'a0000000-0000-4000-8000-000000000102';
  v_now TIMESTAMPTZ := NOW();
BEGIN
  IF p_owner_user_id IS NULL THEN
    RAISE EXCEPTION 'Must be authenticated or pass p_owner_user_id';
  END IF;

  INSERT INTO organizer_companies (id, owner_user_id, legal_name, display_name, contact_email, setup_completed)
  VALUES (
    v_company_id,
    p_owner_user_id,
    'EventEase Bridal Fairs Sdn Bhd',
    'EventEase Expo',
    'organizer@eventease.demo',
    true
  )
  ON CONFLICT (id) DO UPDATE SET
    owner_user_id = EXCLUDED.owner_user_id,
    display_name = EXCLUDED.display_name,
    updated_at = NOW();

  INSERT INTO organizer_expos (id, company_id, name, slug, venue, venue_address, start_at, end_at, status, booth_capacity)
  VALUES
    (
      v_expo_ongoing,
      v_company_id,
      'Kuala Lumpur Bridal Fair 2026',
      'kl-bridal-fair-2026',
      'MITEC, KL',
      'Kompleks MITEC, Kuala Lumpur',
      v_now - INTERVAL '2 hours',
      v_now + INTERVAL '8 hours',
      'ongoing',
      120
    ),
    (
      v_expo_upcoming,
      v_company_id,
      'Penang Wedding Expo',
      'penang-wedding-expo',
      'SPICE Arena, Penang',
      'Penang',
      v_now + INTERVAL '14 days',
      v_now + INTERVAL '16 days',
      'upcoming',
      80
    )
  ON CONFLICT (id) DO UPDATE SET
    status = EXCLUDED.status,
    start_at = EXCLUDED.start_at,
    end_at = EXCLUDED.end_at,
    updated_at = NOW();

  -- Booths (ongoing expo)
  INSERT INTO organizer_booths (id, expo_id, number, zone, size_label, early_bird_price_rm, normal_price_rm, status, grid_x, grid_y, grid_w, grid_h, map_x, map_y)
  VALUES
    ('a0000000-0000-4000-8000-000000002001', v_expo_ongoing, 'A-01', 'a', '3×3m', 2800, 3500, 'booked', 0, 0, 1, 1, 0.15, 0.20),
    ('a0000000-0000-4000-8000-000000002002', v_expo_ongoing, 'A-02', 'a', '3×3m', 2800, 3500, 'booked', 1, 0, 1, 1, 0.35, 0.20),
    ('a0000000-0000-4000-8000-000000002003', v_expo_ongoing, 'A-03', 'a', '3×3m', 2800, 3500, 'pending', 2, 0, 1, 1, 0.55, 0.20),
    ('a0000000-0000-4000-8000-000000002004', v_expo_ongoing, 'B-01', 'b', '2×2m', 1800, 2200, 'available', 0, 1, 1, 1, 0.15, 0.45),
    ('a0000000-0000-4000-8000-000000002005', v_expo_ongoing, 'B-03', 'b', '2×2m', 1800, 2200, 'booked', 2, 1, 1, 1, 0.55, 0.45),
    ('a0000000-0000-4000-8000-000000002006', v_expo_ongoing, 'VIP-01', 'vip', '5×4m', 6500, 8000, 'booked', 0, 2, 2, 1, 0.25, 0.70)
  ON CONFLICT (expo_id, number) DO UPDATE SET status = EXCLUDED.status, updated_at = NOW();

  INSERT INTO organizer_exhibitors (id, expo_id, company_name, category, contact_name, phone, email, status, booth_id, package_name, booth_fee_rm, paid_rm, payment_status)
  VALUES
    ('a0000000-0000-4000-8000-000000003001', v_expo_ongoing, 'Glam Bridal Studio', 'Makeup & Hair', 'Jane Tan', '+60123456789', 'jane@glambridal.my', 'approved', 'a0000000-0000-4000-8000-000000002001', 'Premium Showcase', 3500, 3500, 'paid'),
    ('a0000000-0000-4000-8000-000000003002', v_expo_ongoing, 'Royal Catering Co', 'Catering', 'Ahmad Rizal', '+60198765432', 'ahmad@royalcatering.my', 'approved', 'a0000000-0000-4000-8000-000000002002', 'Standard Booth', 3500, 3500, 'paid'),
    ('a0000000-0000-4000-8000-000000003003', v_expo_ongoing, 'Floral Dreams', 'Florist', 'Mei Ling', '+60111222333', 'mei@floraldreams.my', 'approved', 'a0000000-0000-4000-8000-000000002005', 'Standard Booth', 2200, 1100, 'partial'),
    ('a0000000-0000-4000-8000-000000003004', v_expo_ongoing, 'Grand Ballroom Décor', 'Decoration', 'David Lee', '+60144555666', 'david@granddecor.my', 'approved', 'a0000000-0000-4000-8000-000000002006', 'VIP Corner', 8000, 8000, 'paid'),
    ('a0000000-0000-4000-8000-000000003005', v_expo_ongoing, 'LensArt Photography', 'Photography', 'Sarah Wong', '+60177888999', 'sarah@lensart.my', 'pending', 'a0000000-0000-4000-8000-000000002003', 'Premium Showcase', 3500, 0, 'unpaid'),
    ('a0000000-0000-4000-8000-000000003006', v_expo_ongoing, 'Diamond Jewellers', 'Jewellery', 'Raj Kumar', '+60155666777', 'raj@diamondjew.my', 'pending', NULL, 'VIP Corner', 8000, 0, 'unpaid')
  ON CONFLICT (id) DO UPDATE SET status = EXCLUDED.status, payment_status = EXCLUDED.payment_status, updated_at = NOW();

  UPDATE organizer_booths b SET exhibitor_id = e.id
  FROM organizer_exhibitors e
  WHERE e.booth_id = b.id AND b.expo_id = v_expo_ongoing;

  INSERT INTO organizer_expo_leads (id, expo_id, visitor_name, phone, wedding_date, budget_range, interests, assigned_exhibitor_id, temperature, stage, source_booth, captured_at)
  VALUES
    ('a0000000-0000-4000-8000-000000004001', v_expo_ongoing, 'Amira & Hakim', '+60123450001', (CURRENT_DATE + 120), 'RM 80k – 120k', ARRAY['Photography','Catering'], 'a0000000-0000-4000-8000-000000003002', 'hot', 'followed_up', 'A-02', v_now - INTERVAL '3 hours'),
    ('a0000000-0000-4000-8000-000000004002', v_expo_ongoing, 'Priya Sharma', '+60123450002', (CURRENT_DATE + 200), 'RM 50k – 80k', ARRAY['Makeup','Decoration'], 'a0000000-0000-4000-8000-000000003001', 'hot', 'contacted', 'A-01', v_now - INTERVAL '5 hours'),
    ('a0000000-0000-4000-8000-000000004003', v_expo_ongoing, 'Chen Wei Ling', '+60123450003', (CURRENT_DATE + 90), 'RM 30k – 50k', ARRAY['Florist'], NULL, 'warm', 'new', 'B-03', v_now - INTERVAL '1 hour'),
    ('a0000000-0000-4000-8000-000000004004', v_expo_ongoing, 'Nur Aisyah', '+60123450006', (CURRENT_DATE + 150), 'RM 60k – 90k', ARRAY['Jewellery','Photography'], NULL, 'warm', 'new', 'VIP-02', v_now - INTERVAL '45 minutes')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO organizer_expo_visitors (id, expo_id, name, phone, wedding_date, budget_range, interests, status, ticket_code, registered_at, checked_in_at)
  VALUES
    ('a0000000-0000-4000-8000-000000005001', v_expo_ongoing, 'Amira & Hakim', '+60123450001', (CURRENT_DATE + 120), 'RM 80k – 120k', ARRAY['Photography','Catering','Decoration'], 'checked_in', 'EXPO-KL-2100', v_now - INTERVAL '14 days', v_now - INTERVAL '2 hours'),
    ('a0000000-0000-4000-8000-000000005002', v_expo_ongoing, 'Priya Sharma', '+60123450002', (CURRENT_DATE + 200), 'RM 50k – 80k', ARRAY['Makeup','Florist'], 'checked_in', 'EXPO-KL-2101', v_now - INTERVAL '7 days', v_now - INTERVAL '80 minutes'),
    ('a0000000-0000-4000-8000-000000005003', v_expo_ongoing, 'Chen Wei Ling', '+60123450003', (CURRENT_DATE + 90), 'RM 30k – 50k', ARRAY['Florist','Cake'], 'registered', 'EXPO-KL-2102', v_now - INTERVAL '3 days', NULL),
    ('a0000000-0000-4000-8000-000000005004', v_expo_ongoing, 'Nur Aisyah', '+60123450006', (CURRENT_DATE + 150), 'RM 60k – 90k', ARRAY['Jewellery','Photography'], 'registered', 'EXPO-KL-2103', v_now - INTERVAL '6 hours', NULL)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO organizer_ticket_types (id, expo_id, tier, name, description, price_rm, quota, sold_count)
  VALUES
    ('a0000000-0000-4000-8000-000000006001', v_expo_ongoing, 'free', 'General Admission', 'Access to all public zones', 0, 3000, 1840),
    ('a0000000-0000-4000-8000-000000006002', v_expo_ongoing, 'vip', 'VIP Experience', 'Early entry, VIP lounge, goodie bag', 49, 500, 260)
  ON CONFLICT (id) DO UPDATE SET sold_count = EXCLUDED.sold_count, updated_at = NOW();

  INSERT INTO organizer_ticket_sales (id, expo_id, ticket_type_id, ticket_code, buyer_name, buyer_phone, amount_rm, channel, checked_in, purchased_at, checked_in_at)
  VALUES
    ('a0000000-0000-4000-8000-000000007001', v_expo_ongoing, 'a0000000-0000-4000-8000-000000006001', 'EXPO-KL-2100', 'Amira & Hakim', '+60123450001', 0, 'online', true, v_now - INTERVAL '14 days', v_now - INTERVAL '2 hours'),
    ('a0000000-0000-4000-8000-000000007002', v_expo_ongoing, 'a0000000-0000-4000-8000-000000006002', 'EXPO-KL-2088', 'Jason VIP Lim', '+60120001111', 49, 'online', true, v_now - INTERVAL '5 days', v_now - INTERVAL '3 hours'),
    ('a0000000-0000-4000-8000-000000007003', v_expo_ongoing, 'a0000000-0000-4000-8000-000000006001', 'EXPO-KL-2103', 'Nur Aisyah', '+60123450006', 0, 'promo', false, v_now - INTERVAL '6 hours', NULL),
    ('a0000000-0000-4000-8000-000000007004', v_expo_ongoing, 'a0000000-0000-4000-8000-000000006001', 'EXPO-KL-2095', 'Walk-in Guest', NULL, 0, 'walk_in', true, v_now - INTERVAL '30 minutes', v_now - INTERVAL '25 minutes')
  ON CONFLICT (expo_id, ticket_code) DO NOTHING;

  INSERT INTO organizer_expo_incidents (id, expo_id, incident_type, title, description, location, status, priority, reported_by, reported_at)
  VALUES
    ('a0000000-0000-4000-8000-000000008001', v_expo_ongoing, 'booth', 'Power outage at booth A-03', 'Photography booth lost power.', 'Zone A · A-03', 'in_progress', 'high', 'Sarah Wong (LensArt)', v_now - INTERVAL '18 minutes'),
    ('a0000000-0000-4000-8000-000000008002', v_expo_ongoing, 'crowd_control', 'Queue overflow at registration', 'Main entrance queue exceeding capacity.', 'Hall 1 Entrance', 'open', 'medium', 'Registration Lead', v_now - INTERVAL '8 minutes'),
    ('a0000000-0000-4000-8000-000000008003', v_expo_ongoing, 'technical', 'WiFi down in VIP lounge', 'Lead capture tablets offline.', 'VIP Lounge', 'resolved', 'low', 'Staff · Mei', v_now - INTERVAL '1 hour')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO organizer_expo_timeline_items (id, expo_id, title, location, start_at, end_at, status, sort_order)
  VALUES
    ('a0000000-0000-4000-8000-000000009001', v_expo_ongoing, 'Doors open · General admission', 'Main Hall', v_now - INTERVAL '2 hours', v_now + INTERVAL '6 hours', 'live', 1),
    ('a0000000-0000-4000-8000-000000009002', v_expo_ongoing, 'Bridal fashion show', 'Central Stage', v_now + INTERVAL '45 minutes', v_now + INTERVAL '75 minutes', 'upcoming', 2),
    ('a0000000-0000-4000-8000-000000009003', v_expo_ongoing, 'Opening ceremony', 'Central Stage', v_now - INTERVAL '150 minutes', v_now - INTERVAL '120 minutes', 'completed', 0)
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO organizer_emergency_alerts (id, expo_id, message, recipient_groups, sent_by, sent_at, acknowledged)
  VALUES
    (
      'a0000000-0000-4000-8000-0000000001001',
      v_expo_ongoing,
      'Registration queue backup — redirect to Side Entrance B',
      ARRAY['Registration team', 'Crowd control'],
      p_owner_user_id,
      v_now - INTERVAL '12 minutes',
      true
    )
  ON CONFLICT (id) DO NOTHING;

  RETURN 'Organizer demo seed complete for company ' || v_company_id::TEXT;
END;
$$;

REVOKE ALL ON FUNCTION public.seed_organizer_module(UUID) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.seed_organizer_module(UUID) TO authenticated;

COMMENT ON FUNCTION public.seed_organizer_module IS
  'Seeds KL Bridal Fair demo data for the Wedding Event Organizer module. Call as authenticated organizer user.';
