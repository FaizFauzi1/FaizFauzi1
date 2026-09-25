# EventEase k6 Performance & Load Testing Suite

A professional, safe, and repeatable **k6** performance, stress, and concurrency testing suite built specifically for the **EventEase** marketplace backend (Supabase PostgREST, Supabase Auth, Supabase Storage, Supabase Realtime, and Edge Functions).

---

## 📋 Table of Contents

1. [Architecture & Mapping](#architecture--mapping)
2. [Prerequisites & Installation](#prerequisites--installation)
3. [Environment Variables](#environment-variables)
4. [Test Suite Organization](#test-suite-organization)
5. [Test Execution Commands](#test-execution-commands)
6. [Safety & Data Protection (Staging vs. Production)](#safety--data-protection)
7. [Interpreting Performance Metrics](#interpreting-performance-metrics)
8. [Diagnosing EventEase Bottlenecks](#diagnosing-eventease-bottlenecks)

---

## 🏗 Architecture & Mapping

EventEase uses a Flutter client communicating directly with Supabase:
- **Database / PostgREST**: PostgreSQL tables with Row Level Security (RLS).
- **Authentication**: Supabase GoTrue JWT tokens (`/auth/v1/*`).
- **Storage**: Supabase Storage buckets (`service-images`, `images`, `vendor_assets`, `documents`).
- **Realtime**: Phoenix Channel WebSockets (`/realtime/v1/websocket`).
- **Edge Functions**: Deno Edge runtime for payments (`create-xendit-invoice`, `create_billplz`, `xendit-webhook`, `payment-webhook`).

### Codebase Endpoints & Scenarios Mapping

| Feature | Actual Endpoint / Query | Method | Auth | Testable? | Test File |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Auth: Sign In** | `/auth/v1/token?grant_type=password` | `POST` | Anon Key | ✅ Yes | `scenarios/auth.js` |
| **Auth: User Profile** | `/auth/v1/user` | `GET` | Bearer JWT | ✅ Yes | `scenarios/auth.js` |
| **Auth: Refresh Session** | `/auth/v1/token?grant_type=refresh_token` | `POST` | Anon Key | ✅ Yes | `scenarios/auth.js` |
| **Auth: Sign Out** | `/auth/v1/logout` | `POST` | Bearer JWT | ✅ Yes | `scenarios/auth.js` |
| **Vendor Listing** | `/rest/v1/vendor_profiles?select=*&order=priority_score.desc` | `GET` | Public / Anon | ✅ Yes | `scenarios/vendor-browsing.js` |
| **Vendor Details (Joins)** | `/rest/v1/vendor_profiles?select=*,vendor_owners(*),vendor_banking(*)` | `GET` | Public / Anon | ✅ Yes | `scenarios/vendor-browsing.js` |
| **Venues Listing** | `/rest/v1/vendor_services?select=*&category=eq.Venue&is_active=eq.true` | `GET` | Public / Anon | ✅ Yes | `scenarios/vendor-browsing.js` |
| **Categories & Types** | `/rest/v1/service_categories`, `/rest/v1/event_types` | `GET` | Public / Anon | ✅ Yes | `scenarios/vendor-browsing.js` |
| **Search: Filter & Range** | `/rest/v1/vendor_services?category=eq.*&price=gte.*&price=lte.*` | `GET` | Public / Anon | ✅ Yes | `scenarios/search.js` |
| **Search: Deep Pagination** | `/rest/v1/vendor_services?limit=10&offset={0,10,40,90}` | `GET` | Public / Anon | ✅ Yes | `scenarios/search.js` |
| **Customer Profile** | `/rest/v1/customer_user?id=eq.{id}` | `GET` | Bearer JWT | ✅ Yes | `scenarios/customer.js` |
| **Customer Bookings** | `/rest/v1/bookings?customer_id=eq.{id}&select=*,vendor_profiles(*)...` | `GET` | Bearer JWT | ✅ Yes | `scenarios/customer.js` |
| **Customer Orders** | `/rest/v1/shop_orders?customer_id=eq.{id}&select=*,items:shop_order_items(*)` | `GET` | Bearer JWT | ✅ Yes | `scenarios/customer.js` |
| **Vendor Bookings & Orders** | `/rest/v1/bookings?vendor_id=eq.{id}`, `/rest/v1/shop_orders` | `GET` | Bearer JWT | ✅ Yes | `scenarios/vendor.js` |
| **Vendor Analytics RPC** | `/rest/v1/rpc/get_vendor_analytics_aggregated` | `POST` | Bearer JWT | ✅ Yes | `scenarios/vendor.js` |
| **Organizer Expos & Stats** | `/rest/v1/organizer_expos`, `/rest/v1/organizer_expo_dashboard_stats` | `GET` | Bearer JWT | ✅ Yes | `scenarios/organizer.js` |
| **Organizer Booths** | `/rest/v1/organizer_booths?select=*,exhibitor:organizer_exhibitors(*)` | `GET` | Bearer JWT | ✅ Yes | `scenarios/organizer.js` |
| **Booking Creation** | `/rest/v1/bookings` | `POST` | Bearer JWT | ⚠️ Opt-in | `scenarios/booking.js` |
| **Booking Concurrency** | Competing claims on `/rest/v1/vendor_availability` & `/rest/v1/bookings` | `POST` | Bearer JWT | ✅ Yes | `tests/concurrency.js` |
| **Favorites / Shortlist** | `/rest/v1/favorites?user_id=eq.{id}` | `GET`/`POST`/`DELETE` | Bearer JWT | ✅ Yes | `scenarios/shortlist.js` |
| **Enquiry / Chat** | `/rest/v1/chat_conversations`, `/rest/v1/chat_messages` | `GET`/`POST` | Bearer JWT | ✅ Yes | `scenarios/enquiry.js` |
| **Reviews Flow** | `/rest/v1/service_reviews?service_id=eq.{id}` | `GET`/`POST` | Public / Bearer | ✅ Yes | `scenarios/review.js` |
| **Planner & Budgets** | `/rest/v1/events`, `/rest/v1/budgets?select=*,budget_categories(*)...` | `GET` | Bearer JWT | ✅ Yes | `scenarios/planner.js` |
| **Event Short ID RPC** | `/rest/v1/rpc/get_event_by_short_id` | `POST` | Public / Anon | ✅ Yes | `scenarios/planner.js` |
| **Service Packages & Tiers** | `/rest/v1/vendor_services`, `/rest/v1/service_pricing_tiers` | `GET` | Public / Anon | ✅ Yes | `scenarios/packages.js` |
| **Service Components** | `/rest/v1/service_components?select=*,service_items(*)` | `GET` | Public / Anon | ✅ Yes | `scenarios/packages.js` |
| **Calendar & Appointments** | `/rest/v1/vendor_availability`, `/rest/v1/appointments` | `GET` | Bearer JWT | ✅ Yes | `scenarios/calendar.js` |
| **Supabase Storage** | `/storage/v1/object/public/service-images/*` | `GET` | Public | ✅ Yes | `scenarios/storage.js` |
| **Supabase Realtime** | `wss://{host}/realtime/v1/websocket?vsn=1.0.0` (Phoenix protocol) | `WS` | Anon / Bearer | ✅ Yes | `scenarios/realtime.js` |
| **Payment Invoicing** | `/functions/v1/create-xendit-invoice` | `POST` | Anon Key | ⚠️ Sandbox | `scenarios/payment.js` |
| **Webhook Idempotency** | `/functions/v1/xendit-webhook` (duplicate call test) | `POST` | Callback token | ✅ Yes | `scenarios/payment.js` |
| **Admin Safe Reads** | `/rest/v1/countries`, `/rest/v1/regions`, `/rest/v1/admin_listings` | `GET` | Bearer JWT | ✅ Yes | `scenarios/admin.js` |
| **Push Notifications** | `/functions/v1/push-notifications` | `POST` | Bearer JWT | ❌ Unsafe | *Excluded from load* |

---

## ⚙️ Prerequisites & Installation

### 1. Install k6

**Windows (winget):**
```powershell
winget install k6 --source winget
```

**Windows (Chocolatey):**
```powershell
choco install k6
```

**macOS (Homebrew):**
```bash
brew install k6
```

**Linux (Debian/Ubuntu):**
```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install k6
```

Verify installation:
```bash
k6 version
```

---

## 🔐 Environment Variables

Create your `.env` file inside `load-tests/` or export environment variables before running:

```bash
# Target Supabase Instance
export SUPABASE_URL="https://lqvsavyfbnarwsunbfzm.supabase.co"
export SUPABASE_ANON_KEY="sb_publishable_tAUtEvgarcJEtlo50Bdtxg_m9SVzy_5"

# Dedicated Test Accounts (NEVER use real user accounts)
export TEST_CUSTOMER_EMAIL="customer_test@eventease.app"
export TEST_CUSTOMER_PASSWORD="CustomerTest123!"
export TEST_CUSTOMER_ID="00000000-0000-0000-0000-000000000001"

export TEST_VENDOR_EMAIL="vendor_test@eventease.app"
export TEST_VENDOR_PASSWORD="VendorTest123!"
export TEST_VENDOR_ID="00000000-0000-0000-0000-000000000002"

# Safety Flags
export ALLOW_MUTATIVE_TESTS="false"          # Set to 'true' to allow writes
export ALLOW_PAYMENT_SANDBOX_TESTS="false"   # Set to 'true' for sandbox invoice & webhook tests
export ALLOW_STORAGE_UPLOAD_TESTS="false"    # Set to 'true' for file upload tests

# Test Sizing
export MAX_VUS_STRESS=500
export SOAK_DURATION="30m"
export BOOKING_CONCURRENCY_VUS=50
```

---

## 📁 Test Suite Organization

```
load-tests/
├── package.json               # NPM script definitions
├── .env.example               # Environment variables template
├── config/
│   ├── config.js              # Global configuration & URL builders
│   └── thresholds.js          # SLA performance thresholds (p95, p99, error rates)
├── helpers/
│   ├── auth.js                # Supabase GoTrue Auth helper
│   ├── client.js              # PostgREST and Edge Function HTTP client
│   ├── data.js                # Synthetic tagged payload generator
│   ├── checks.js              # Standard assertion checkers
│   └── reporter.js            # Custom JSON, HTML, and console report generator
├── scenarios/                 # Independent feature-level scenarios
│   ├── auth.js                # Login, refresh token, session
│   ├── vendor-browsing.js     # Categories, vendor profiles, venues
│   ├── search.js              # Multi-filter search & deep pagination
│   ├── customer.js            # Profile, bookings, shop orders
│   ├── vendor.js              # Vendor bookings, orders, analytics RPC
│   ├── organizer.js           # Expos, booths, exhibitor applications
│   ├── booking.js             # Booking submission & status update
│   ├── shortlist.js           # Favorites add/remove
│   ├── enquiry.js             # Chat conversations & message thread
│   ├── review.js              # Service & vendor reviews
│   ├── planner.js             # Events, short ID RPC, budgets
│   ├── packages.js            # Pricing tiers & components
│   ├── calendar.js            # Availability rules & appointments
│   ├── storage.js             # Public downloads & synthetic uploads
│   ├── realtime.js            # WebSocket channel subscription & heartbeat
│   ├── payment.js             # Webhook idempotency test
│   └── admin.js               # Safe administrative read queries
├── tests/                     # Main Test Runners
│   ├── smoke.js               # Quick pre-flight validation (1-2 VUs)
│   ├── load.js                # Realistic weighted marketplace load (10-200 VUs)
│   ├── stress.js              # Capacity breaking point test (up to 500 VUs)
│   ├── spike.js               # Sudden surge recovery test (10 -> 500 -> 10 VUs)
│   ├── soak.js                # Endurance & leak detection test (30-60 min)
│   └── concurrency.js         # Simultaneous double-booking race condition test
└── reports/                   # Output artifacts (HTML, JSON)
```

---

## 🚀 Test Execution Commands

From the `load-tests` directory:

### 1. Smoke Test (Pre-flight sanity check, 30 seconds)
```powershell
k6 run tests/smoke.js
# Or via npm
npm run test:smoke
```

### 2. Normal Load Test (Realistic weighted traffic, 10–200 VUs)
```powershell
k6 run tests/load.js
# Or via npm
npm run test:load
```

### 3. Stress Test (Find capacity ceiling & breaking point)
```powershell
k6 run -e MAX_VUS_STRESS=500 tests/stress.js
# Or via npm
npm run test:stress
```

### 4. Spike Test (Simulate viral social media surge)
```powershell
k6 run tests/spike.js
# Or via npm
npm run test:spike
```

### 5. Soak Test (Endurance & resource leak detection)
```powershell
k6 run -e SOAK_DURATION=30m tests/soak.js
# Or via npm
npm run test:soak
```

### 6. Booking Concurrency Test (Race condition & double-booking check)
```powershell
k6 run -e BOOKING_CONCURRENCY_VUS=50 tests/concurrency.js
# Or via npm
npm run test:concurrency
```

### 7. Storage Test
```powershell
k6 run scenarios/storage.js
```

### 8. Realtime WebSocket Test
```powershell
k6 run scenarios/realtime.js
```

### 9. Payment Webhook Idempotency Test
```powershell
k6 run -e ALLOW_PAYMENT_SANDBOX_TESTS=true scenarios/payment.js
```

---

## 🛡 Safety & Data Protection

### What tests are SAFE to run against Staging / Production?
- **Smoke Test (`tests/smoke.js`)**: Safe read-only checks.
- **Vendor Browsing (`scenarios/vendor-browsing.js`)**: Read-only public queries.
- **Search & Filtering (`scenarios/search.js`)**: Read-only queries.
- **Packages & Services (`scenarios/packages.js`)**: Read-only catalog queries.
- **Customer / Vendor Reads**: Safe when targeting dedicated test account IDs.
- **Admin Reference Reads**: Safe (countries, categories, listings).

### What tests must NEVER run against Production?
1. **Push Notification Triggers (`push-notifications` Edge function)**:
   - Invoking this triggers real Google Firebase FCM pushes to real devices, and will result in rate-limiting or quota bans.
2. **Stress & Spike Tests with High VUs (> 100 VUs)**:
   - Running 500+ VUs against production can saturate connection pools, exhaust Supabase compute CPU, trigger Cloudflare/Supabase rate limiters, or elevate database billing.
3. **Mutative Tests without Safety Flags**:
   - Creating thousands of mock bookings, fake reviews, or dummy storage uploads in production will corrupt business metrics and analytics. All mutative actions in this suite require setting `ALLOW_MUTATIVE_TESTS=true`.
4. **Payment Invoices with Real Providers**:
   - Only test with `isSandbox=true` or mocked webhooks.

---

## 📊 Interpreting Performance Metrics

| Metric | Target (SLA) | What It Means |
| :--- | :--- | :--- |
| **`http_req_failed`** | `< 1%` | Proportion of requests returning HTTP 4xx (except expected 401/409) or 5xx. |
| **`p50` (Median)** | `< 400 ms` | 50% of your requests were served faster than this time. Represents typical user experience. |
| **`p90`** | `< 800 ms` | 90% of requests completed faster than this time. Good indicator of standard service level. |
| **`p95`** | `< 1200 ms` | 95% threshold. The standard industry SLA benchmark. Any request taking longer than this is in the slowest 5%. |
| **`p99`** | `< 2500 ms` | 99% threshold. Represents worst-case user experience (cache misses, complex RLS joins, table scans). |
| **`http_reqs` (Throughput)** | Scale-dependent | Requests completed per second. If throughput plateaus while VUs increase, you have hit saturation. |

---

## 🔍 Diagnosing EventEase Bottlenecks

When tests fail or latency increases, use this troubleshooting tree:

### 1. Deep Nested PostgREST Joins (e.g. `bookings` with 5 relations)
- **Symptom**: `customer_bookings_deep` or `planner_budgets_deep_join` show high p95 (> 2000ms).
- **Cause**: The query requests `*, customer_user(*), vendor_profiles(*), vendor_services(*), installment_plans(*, installment_payments(*))` in a single request.
- **Remedy**: Ensure foreign keys (`customer_id`, `vendor_id`, `service_id`) have explicit indexes in PostgreSQL. Consider splitting secondary relations into lazy loads.

### 2. Missing Indexes on Filter Columns
- **Symptom**: `search_multi_filter` degrades rapidly under concurrency.
- **Cause**: Filtering on `vendor_services.category`, `price`, and `is_active` without a composite index.
- **Remedy**: Create a composite index in Supabase SQL editor:
  ```sql
  CREATE INDEX idx_vendor_services_cat_price ON vendor_services (category, is_active, price);
  ```

### 3. RLS Recursive Overhead
- **Symptom**: Moderate VUs cause high CPU utilization on PostgreSQL with simple `select=*` queries.
- **Cause**: RLS policies using subqueries like `EXISTS (SELECT 1 FROM vendor_user WHERE id = auth.uid())` executed per row.
- **Remedy**: Use `(SELECT auth.uid())` cached subqueries or index foreign keys referenced in RLS conditions.

### 4. Connection Pool Starvation
- **Symptom**: Sudden flood of `504 Gateway Timeout` or `500 Internal Server Error` during Spike/Stress tests.
- **Cause**: Supabase Transaction pooler limit reached.
- **Remedy**: Ensure connection pooling (PgBouncer/Supavisor on port 6543) is enabled for high concurrency workloads.
