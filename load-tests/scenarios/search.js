import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Search & Pagination Flow
 * Tests realistic marketplace queries, multi-filter combinations, and deep pagination:
 * 1. Category search
 * 2. Multi-filter search (category + base_price range + active)
 * 3. Text pattern search (ilike)
 * 4. Sorting performance (base_price asc, created_at desc)
 * 5. Pagination degradation test (page 1, 2, 5, 10)
 */
export function scenarioSearch() {
  const categories = ['venue', 'doorgift', 'henna-artist'];
  const randomCategory = categories[Math.floor(Math.random() * categories.length)];

  // 1. Filter by Category
  const catRes = client.get(
    'vendor_services',
    `select=*&category=eq.${encodeURIComponent(randomCategory)}&is_active=eq.true&limit=15`,
    {},
    { name: 'search_by_category' }
  );
  Checks.isOk(catRes, 'search_by_category');

  sleep(0.5);

  // 2. Multi-filter: Category + Base Price Range (Column is base_price in vendor_services schema)
  const multiFilterRes = client.get(
    'vendor_services',
    `select=*&category=eq.${encodeURIComponent(randomCategory)}&base_price=gte.1&base_price=lte.5000&is_active=eq.true&order=base_price.asc&limit=15`,
    {},
    { name: 'search_multi_filter' }
  );
  Checks.isOk(multiFilterRes, 'search_multi_filter');

  sleep(0.5);

  // 3. Text Search (ILIKE) on vendor business name
  const textQuery = 'grand';
  const textRes = client.get(
    'vendor_profiles',
    `select=*&business_name=ilike.*${textQuery}*&limit=10`,
    {},
    { name: 'search_text_ilike' }
  );
  Checks.isOk(textRes, 'search_text_ilike');

  sleep(0.5);

  // 4. Pagination Test: Compare Page 1 vs Page 2 vs Page 5 vs Page 10
  const pages = [
    { page: 1, offset: 0 },
    { page: 2, offset: 10 },
    { page: 5, offset: 40 },
    { page: 10, offset: 90 },
  ];

  for (const p of pages) {
    const pageRes = client.get(
      'vendor_services',
      `select=*&limit=10&offset=${p.offset}&order=created_at.desc`,
      {},
      { name: `search_page_${p.page}` }
    );
    Checks.isOk(pageRes, `search_page_${p.page}`);
  }

  sleep(1);
}
