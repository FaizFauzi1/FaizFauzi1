import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { TestDataGenerator } from '../helpers/data.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Favorites & Shortlist Flow
 * 1. Retrieve user favorites list
 * 2. Add item to favorites
 * 3. Verify item in favorites
 * 4. Remove item from favorites
 */
export function scenarioShortlist(authToken = null) {
  if (authToken) client.setAuthToken(authToken);

  const userId = Config.customer.id || '00000000-0000-0000-0000-000000000001';

  // 1. Get Favorites
  const listRes = client.get(
    'favorites',
    `user_id=eq.${userId}&select=*`,
    {},
    { name: 'favorites_list' }
  );
  Checks.isOk(listRes, 'favorites_list');

  // Mutative toggle test
  if (Config.allowMutativeTests) {
    const testItemId = Config.testVendorId || TestDataGenerator.uuid();
    const payload = TestDataGenerator.favoritePayload(userId, testItemId, 'vendor');

    // 2. Add Favorite
    const addRes = client.post(
      'favorites',
      payload,
      {},
      { name: 'favorites_add' }
    );
    Checks.isSuccess(addRes, 'favorites_add');

    sleep(0.5);

    // 3. Remove Favorite
    const removeRes = client.del(
      'favorites',
      `user_id=eq.${userId}&item_id=eq.${testItemId}&item_type=eq.vendor`,
      {},
      { name: 'favorites_remove' }
    );
    Checks.isSuccess(removeRes, 'favorites_remove');
  }

  sleep(1);
}
