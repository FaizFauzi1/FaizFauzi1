import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Event Planner & Budget Management Flow
 * Tests:
 * 1. Fetch host events list
 * 2. Short ID RPC lookup
 * 3. Fetch comprehensive budget (budgets + categories + expenses joins)
 */
export function scenarioPlanner(authToken = null) {
  if (authToken) client.setAuthToken(authToken);

  const customerId = Config.customer.id || '00000000-0000-0000-0000-000000000001';

  // 1. Host Events
  const eventsRes = client.get(
    'events',
    `host_id=eq.${customerId}&select=*&order=date.desc&limit=10`,
    {},
    { name: 'planner_events_list' }
  );
  Checks.isOk(eventsRes, 'planner_events_list');

  sleep(0.5);

  // 2. Short ID RPC Call
  const shortIdRpcRes = client.rpc(
    'get_event_by_short_id',
    { prefix: 'test' },
    {},
    { name: 'planner_short_id_rpc' }
  );
  Checks.isSuccess(shortIdRpcRes, 'planner_short_id_rpc');

  sleep(0.5);

  // 3. Budgets with Categories & Expenses (Deep Nested Query)
  const budgetRes = client.get(
    'budgets',
    `customer_id=eq.${customerId}&select=*,budget_categories(*),budget_expenses(*)&limit=5`,
    {},
    { name: 'planner_budgets_deep_join' }
  );
  Checks.isOk(budgetRes, 'planner_budgets_deep_join');

  sleep(1);
}
