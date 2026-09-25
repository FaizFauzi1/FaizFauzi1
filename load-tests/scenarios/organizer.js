import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Organizer Operations Flow
 * Tests expo, booth management, and exhibitor vendor tracking:
 * 1. Organizer company lookup
 * 2. Expos list
 * 3. Expo dashboard statistics view
 * 4. Expo booths with joined exhibitor information
 * 5. Exhibitor applications list
 */
export function scenarioOrganizer(authToken = null) {
  if (authToken) client.setAuthToken(authToken);

  // 1. Organizer Expos
  const exposRes = client.get(
    'organizer_expos',
    'select=id,name,status,start_at,end_at&order=start_at.desc&limit=10',
    {},
    { name: 'organizer_expos_list' }
  );
  Checks.isOk(exposRes, 'organizer_expos_list');

  let targetExpoId = Config.testExpoId;
  try {
    const expos = JSON.parse(exposRes.body);
    if (expos.length > 0 && !targetExpoId) {
      targetExpoId = expos[0].id;
    }
  } catch (_) {}

  sleep(0.5);

  // 2. Dashboard Stats
  const statsRes = client.get(
    'organizer_expo_dashboard_stats',
    'select=*&limit=5',
    {},
    { name: 'organizer_dashboard_stats' }
  );
  Checks.isOk(statsRes, 'organizer_dashboard_stats');

  sleep(0.5);

  // 3. Booths & Exhibitors
  if (targetExpoId) {
    const boothsRes = client.get(
      'organizer_booths',
      `expo_id=eq.${targetExpoId}&select=*,exhibitor:organizer_exhibitors!exhibitor_id(company_name)&order=number&limit=30`,
      {},
      { name: 'organizer_booths_list' }
    );
    Checks.isOk(boothsRes, 'organizer_booths_list');

    const exhibitorsRes = client.get(
      'organizer_exhibitors',
      `expo_id=eq.${targetExpoId}&select=*,booth:organizer_booths!booth_id(number)&order=applied_at.desc&limit=20`,
      {},
      { name: 'organizer_exhibitors_list' }
    );
    Checks.isOk(exhibitorsRes, 'organizer_exhibitors_list');
  }

  sleep(1);
}
