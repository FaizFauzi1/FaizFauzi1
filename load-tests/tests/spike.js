import { Thresholds } from '../config/thresholds.js';
import { generateCustomSummary } from '../helpers/reporter.js';
import { AuthService } from '../helpers/auth.js';
import { Config } from '../config/config.js';
import { scenarioVendorBrowsing } from '../scenarios/vendor-browsing.js';
import { scenarioSearch } from '../scenarios/search.js';
import { sleep } from 'k6';

export const options = {
  stages: [
    { duration: '30s', target: 10 },    // Baseline normal traffic
    { duration: '15s', target: 100 },   // Sudden spike 1
    { duration: '15s', target: 500 },   // Viral spike 2
    { duration: '1m', target: 500 },    // Sustain peak momentarily
    { duration: '30s', target: 10 },    // Abrupt recovery to baseline
    { duration: '1m', target: 10 },     // Observe post-spike health
    { duration: '30s', target: 0 },
  ],
  thresholds: Thresholds.spike,
};

export function setup() {
  console.log('--- Starting EventEase Spike Test ---');
  let token = null;
  const login = AuthService.login(Config.customer.email, Config.customer.password, 'spike_setup_auth');
  if (login.success) token = login.accessToken;
  return { token };
}

export default function (data) {
  if (Math.random() < 0.6) {
    scenarioVendorBrowsing(data.token);
  } else {
    scenarioSearch();
  }

  sleep(0.5);
}

export function handleSummary(data) {
  return generateCustomSummary(data, 'Spike Test');
}
