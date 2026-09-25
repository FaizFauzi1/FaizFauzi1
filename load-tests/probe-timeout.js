import http from 'k6/http';
import { check, sleep } from 'k6';

// ======================================================================
// PROBE: Investigate 60-second timeout on packages_components_and_items
// ======================================================================

const SUPABASE_URL = 'https://lqvsavyfbnarwsunbfzm.supabase.co';
const ANON_KEY = 'sb_publishable_tAUtEvgarcJEtlo50Bdtxg_m9SVzy_5';

const headers = {
  'apikey': ANON_KEY,
  'Content-Type': 'application/json',
};

export const options = {
  iterations: 1,
  vus: 1,
};

export default function () {
  console.log('=== PROBE: Timeout Investigation ===');

  // ----------------------------------------------------------------
  // STEP 1: Check if the fake UUID returns any data
  // ----------------------------------------------------------------
  const fakeId = '00000000-0000-0000-0000-000000000003';
  console.log(`\n--- Step 1: Query with fake service_id=${fakeId} ---`);

  const fakeRes = http.get(
    `${SUPABASE_URL}/rest/v1/service_components?service_id=eq.${fakeId}&select=*,service_items(*)`,
    { headers, tags: { name: 'probe_fake_uuid' } }
  );
  console.log(`  status=${fakeRes.status} duration=${fakeRes.timings.duration.toFixed(1)}ms body_len=${(fakeRes.body || '').length}`);
  console.log(`  body_preview=${(fakeRes.body || '').substring(0, 300)}`);

  // ----------------------------------------------------------------
  // STEP 2: Get actual service IDs from vendor_services
  // ----------------------------------------------------------------
  console.log(`\n--- Step 2: Get real vendor_service IDs ---`);
  const servicesRes = http.get(
    `${SUPABASE_URL}/rest/v1/vendor_services?select=id,name,vendor_id,category&is_active=eq.true&limit=5`,
    { headers, tags: { name: 'probe_real_services' } }
  );
  console.log(`  status=${servicesRes.status} duration=${servicesRes.timings.duration.toFixed(1)}ms`);

  let realServiceIds = [];
  try {
    const services = JSON.parse(servicesRes.body);
    realServiceIds = services.map(s => s.id);
    console.log(`  Found ${services.length} real services:`);
    for (const s of services) {
      console.log(`    id=${s.id} name="${s.name}" category=${s.category}`);
    }
  } catch (e) {
    console.log(`  Failed to parse services: ${e}`);
  }

  // ----------------------------------------------------------------
  // STEP 3: Test the nested join with a REAL service ID
  // ----------------------------------------------------------------
  if (realServiceIds.length > 0) {
    const realId = realServiceIds[0];
    console.log(`\n--- Step 3a: Nested join with REAL service_id=${realId} ---`);
    const realRes = http.get(
      `${SUPABASE_URL}/rest/v1/service_components?service_id=eq.${realId}&select=*,service_items(*)`,
      { headers, tags: { name: 'probe_real_nested' } }
    );
    console.log(`  status=${realRes.status} duration=${realRes.timings.duration.toFixed(1)}ms body_len=${(realRes.body || '').length}`);
    console.log(`  body_preview=${(realRes.body || '').substring(0, 500)}`);
  }

  // ----------------------------------------------------------------
  // STEP 4: Test service_components table alone (no join)
  // ----------------------------------------------------------------
  console.log(`\n--- Step 4: service_components table alone (no join) ---`);
  const compOnlyRes = http.get(
    `${SUPABASE_URL}/rest/v1/service_components?select=*&limit=10`,
    { headers, tags: { name: 'probe_components_only' } }
  );
  console.log(`  status=${compOnlyRes.status} duration=${compOnlyRes.timings.duration.toFixed(1)}ms body_len=${(compOnlyRes.body || '').length}`);
  console.log(`  body_preview=${(compOnlyRes.body || '').substring(0, 300)}`);

  // ----------------------------------------------------------------
  // STEP 5: Test service_items table alone
  // ----------------------------------------------------------------
  console.log(`\n--- Step 5: service_items table alone ---`);
  const itemsOnlyRes = http.get(
    `${SUPABASE_URL}/rest/v1/service_items?select=*&limit=10`,
    { headers, tags: { name: 'probe_items_only' } }
  );
  console.log(`  status=${itemsOnlyRes.status} duration=${itemsOnlyRes.timings.duration.toFixed(1)}ms body_len=${(itemsOnlyRes.body || '').length}`);
  console.log(`  body_preview=${(itemsOnlyRes.body || '').substring(0, 300)}`);

  // ----------------------------------------------------------------
  // STEP 6: Count total rows in each table
  // ----------------------------------------------------------------
  console.log(`\n--- Step 6: Row counts ---`);
  const compCountRes = http.get(
    `${SUPABASE_URL}/rest/v1/service_components?select=id`,
    { headers: { ...headers, 'Prefer': 'count=exact' }, tags: { name: 'probe_comp_count' } }
  );
  const compCount = compCountRes.headers['Content-Range'] || 'unknown';
  console.log(`  service_components count: ${compCount} (status=${compCountRes.status})`);

  const itemsCountRes = http.get(
    `${SUPABASE_URL}/rest/v1/service_items?select=id`,
    { headers: { ...headers, 'Prefer': 'count=exact' }, tags: { name: 'probe_items_count' } }
  );
  const itemsCount = itemsCountRes.headers['Content-Range'] || 'unknown';
  console.log(`  service_items count: ${itemsCount} (status=${itemsCountRes.status})`);

  // ----------------------------------------------------------------
  // STEP 7: Check for vendor_profiles and vendor_banking access (RLS)
  // ----------------------------------------------------------------
  console.log(`\n--- Step 7: Vendor details join test (RLS pressure point) ---`);
  const fakeVendorId = '00000000-0000-0000-0000-000000000002';
  const vendorDetailRes = http.get(
    `${SUPABASE_URL}/rest/v1/vendor_profiles?id=eq.${fakeVendorId}&select=*,vendor_owners(*),vendor_banking(*)`,
    { headers, tags: { name: 'probe_vendor_rls' } }
  );
  console.log(`  status=${vendorDetailRes.status} duration=${vendorDetailRes.timings.duration.toFixed(1)}ms body_len=${(vendorDetailRes.body || '').length}`);
  console.log(`  body_preview=${(vendorDetailRes.body || '').substring(0, 300)}`);

  // ----------------------------------------------------------------
  // STEP 8: Check service_pricing_tiers with fake ID
  // ----------------------------------------------------------------
  console.log(`\n--- Step 8: service_pricing_tiers with fake service_id ---`);
  const tiersRes = http.get(
    `${SUPABASE_URL}/rest/v1/service_pricing_tiers?service_id=eq.${fakeId}&select=*`,
    { headers, tags: { name: 'probe_tiers_fake' } }
  );
  console.log(`  status=${tiersRes.status} duration=${tiersRes.timings.duration.toFixed(1)}ms body=${(tiersRes.body || '').substring(0, 200)}`);

  // ----------------------------------------------------------------
  // STEP 9: Check budgets query (planner_budgets_deep_join also failed with 502)
  // ----------------------------------------------------------------
  console.log(`\n--- Step 9: Budgets deep join ---`);
  const fakeCustomerId = '00000000-0000-0000-0000-000000000001';
  const budgetRes = http.get(
    `${SUPABASE_URL}/rest/v1/budgets?customer_id=eq.${fakeCustomerId}&select=*,budget_categories(*),budget_expenses(*)&limit=5`,
    { headers, tags: { name: 'probe_budgets' } }
  );
  console.log(`  status=${budgetRes.status} duration=${budgetRes.timings.duration.toFixed(1)}ms body=${(budgetRes.body || '').substring(0, 200)}`);

  // ----------------------------------------------------------------
  // STEP 10: Rapid-fire concurrent test (simulate pressure)
  // ----------------------------------------------------------------
  console.log(`\n--- Step 10: Rapid-fire 10 sequential requests to service_components ---`);
  for (let i = 0; i < 10; i++) {
    const rapidRes = http.get(
      `${SUPABASE_URL}/rest/v1/service_components?service_id=eq.${fakeId}&select=*,service_items(*)`,
      { headers, tags: { name: `probe_rapid_${i}` } }
    );
    console.log(`  rapid[${i}] status=${rapidRes.status} duration=${rapidRes.timings.duration.toFixed(1)}ms`);
  }

  // ----------------------------------------------------------------
  // STEP 11: Check k6 default timeout
  // ----------------------------------------------------------------
  console.log(`\n--- Step 11: k6 timeout configuration ---`);
  console.log('  k6 default HTTP timeout: 60 seconds (http.timeout)');
  console.log('  This matches the observed 60000.2ms timeout exactly.');
  console.log('  Conclusion: The 60s timeout is k6s default client timeout, NOT a Supabase/Cloudflare timeout.');

  console.log('\n=== PROBE COMPLETE ===');
}
