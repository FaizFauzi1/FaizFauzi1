import { Thresholds } from '../config/thresholds.js';
import { generateCustomSummary } from '../helpers/reporter.js';
import { AuthService } from '../helpers/auth.js';
import { Config } from '../config/config.js';
import { scenarioVendorBrowsing } from '../scenarios/vendor-browsing.js';
import { scenarioSearch } from '../scenarios/search.js';
import { scenarioPackages } from '../scenarios/packages.js';
import { scenarioShortlist } from '../scenarios/shortlist.js';
import { scenarioCustomer } from '../scenarios/customer.js';
import { scenarioPlanner } from '../scenarios/planner.js';
import { scenarioEnquiry } from '../scenarios/enquiry.js';
import { scenarioBooking } from '../scenarios/booking.js';
import { scenarioCalendar } from '../scenarios/calendar.js';
import { sleep } from 'k6';

/**
 * Supabase Architecture & Connection Pool Awareness:
 * Architecture: k6 -> Cloudflare CDN -> Supabase Kong -> PostgREST -> PgBouncer -> PostgreSQL
 * - Supabase free/pro direct connection pool: ~60 connections; PgBouncer pooler: up to 200.
 * - At 200 concurrent VUs, requests queue at PgBouncer/PostgREST.
 * - If queue depth exceeds capacity, Cloudflare/Kong returns 502 Bad Gateway (15-45ms rejection).
 * - Client timeout is set to 30s in client.js (overriding k6 60s default) to prevent queue deadlocks.
 */
export const options = {
  stages: [
    { duration: '1m', target: 10 },
    { duration: '2m', target: 25 },
    { duration: '2m', target: 50 },
    { duration: '3m', target: 100 },
    { duration: '3m', target: 200 },
    { duration: '2m', target: 0 },
  ],
  thresholds: Thresholds.load,
};

export function setup() {
  console.log('--- Starting EventEase Normal Load Test ---');
  let token = null;
  const login = AuthService.login(Config.customer.email, Config.customer.password, 'load_setup_auth');
  if (login.success) {
    token = login.accessToken;
  }
  return { token };
}

export default function (data) {
  // Realistic user behavior weight distribution (0 - 100)
  const rand = Math.random() * 100;

  if (rand < 40) {
    // 40% Browsing Vendors and Venues
    scenarioVendorBrowsing(data.token);
  } else if (rand < 60) {
    // 20% Searching and Filtering
    scenarioSearch();
  } else if (rand < 75) {
    // 15% Checking Packages and Pricing Tiers
    scenarioPackages(data.token);
  } else if (rand < 85) {
    // 10% Viewing/Managing Favorites
    scenarioShortlist(data.token);
  } else if (rand < 90) {
    // 5% Customer Account & Order History
    scenarioCustomer(data.token);
  } else if (rand < 94) {
    // 4% Event Planner & Budgeting
    scenarioPlanner(data.token);
  } else if (rand < 97) {
    // 3% Enquiries and Chat History
    scenarioEnquiry(data.token);
  } else {
    // 3% Calendar & Booking Attempt
    scenarioCalendar(data.token);
    scenarioBooking(data.token);
  }

  // Realistic user think time between actions (1-3 seconds)
  sleep(1 + Math.random() * 2);
}

export function handleSummary(data) {
  return generateCustomSummary(data, 'Normal Load Test');
}
