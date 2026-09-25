import { Thresholds } from '../config/thresholds.js';
import { generateCustomSummary } from '../helpers/reporter.js';
import { AuthService } from '../helpers/auth.js';
import { Config } from '../config/config.js';
import { scenarioVendorBrowsing } from '../scenarios/vendor-browsing.js';
import { scenarioSearch } from '../scenarios/search.js';
import { scenarioPackages } from '../scenarios/packages.js';
import { scenarioCustomer } from '../scenarios/customer.js';
import { sleep } from 'k6';

const duration = Config.soakDuration;

export const options = {
  stages: [
    { duration: '2m', target: 100 },       // Ramp up
    { duration: duration, target: 100 },   // Sustained moderate load
    { duration: '2m', target: 0 },         // Ramp down
  ],
  thresholds: Thresholds.soak,
};

export function setup() {
  console.log(`--- Starting EventEase Soak Test (Duration: ${duration}) ---`);
  let token = null;
  const login = AuthService.login(Config.customer.email, Config.customer.password, 'soak_setup_auth');
  if (login.success) token = login.accessToken;
  return { token };
}

export default function (data) {
  const rand = Math.random();

  if (rand < 0.4) {
    scenarioVendorBrowsing(data.token);
  } else if (rand < 0.7) {
    scenarioSearch();
  } else if (rand < 0.9) {
    scenarioPackages(data.token);
  } else {
    scenarioCustomer(data.token);
  }

  // Realistic pacing
  sleep(2 + Math.random() * 2);
}

export function handleSummary(data) {
  return generateCustomSummary(data, `Soak Test (${duration})`);
}
