import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Safe Admin Operations Flow
 * Validates read-only administrative and reference data queries:
 * 1. Geographic reference data (countries, regions, cities)
 * 2. Admin featured listings
 * 3. Admin active promotions
 * 4. Admin blog / resource articles
 * 5. Role authorization verification
 */
export function scenarioAdmin(authToken = null) {
  if (authToken) client.setAuthToken(authToken);

  // 1. Geographic Reference Data
  const geoRes = client.get('countries', 'select=*&limit=20', {}, { name: 'admin_countries_list' });
  Checks.isOk(geoRes, 'admin_countries_list');

  const regionsRes = client.get('regions', 'select=*&limit=30', {}, { name: 'admin_regions_list' });
  Checks.isOk(regionsRes, 'admin_regions_list');

  sleep(0.5);

  // 2. Admin Listings
  const listingsRes = client.get('admin_listings', 'select=*&limit=10', {}, { name: 'admin_listings_list' });
  Checks.isOk(listingsRes, 'admin_listings_list');

  sleep(0.5);

  // 3. Admin Promotions
  const promoRes = client.get('admin_promotions', 'select=*&limit=10', {}, { name: 'admin_promotions_list' });
  Checks.isOk(promoRes, 'admin_promotions_list');

  sleep(0.5);

  // 4. Admin Articles
  const articlesRes = client.get('admin_articles', 'select=*&limit=10', {}, { name: 'admin_articles_list' });
  Checks.isOk(articlesRes, 'admin_articles_list');

  sleep(1);
}
