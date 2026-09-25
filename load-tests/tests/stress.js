import { Thresholds } from '../config/thresholds.js';
import { generateCustomSummary } from '../helpers/reporter.js';
import { AuthService } from '../helpers/auth.js';
import { Config } from '../config/config.js';
import { scenarioVendorBrowsing } from '../scenarios/vendor-browsing.js';
import { scenarioSearch } from '../scenarios/search.js';
import { scenarioPackages } from '../scenarios/packages.js';
import { scenarioCustomer } from '../scenarios/customer.js';
import { sleep } from 'k6';

const peakUsers = Config.maxVUsStress;

export const options = {
  stages: [
    { duration: '1m', target: 20 },
    { duration: '2m', target: 50 },
    { duration: '2m', target: 100 },
    { duration: '2m', target: 250 },
    { duration: '2m', target: peakUsers },
    { duration: '2m', target: peakUsers },
    { duration: '2m', target: 0 },
  ],
  thresholds: Thresholds.stress,
};

export function setup() {
  console.log(`--- Starting EventEase Stress Test (Targeting up to ${peakUsers} VUs) ---`);
  let token = null;
  const login = AuthService.login(Config.customer.email, Config.customer.password, 'stress_setup_auth');
  if (login.success) token = login.accessToken;
  return { token };
}

export default function (data) {
  const rand = Math.random();

  if (rand < 0.5) {
    scenarioVendorBrowsing(data.token);
  } else if (rand < 0.8) {
    scenarioSearch();
  } else if (rand < 0.9) {
    scenarioPackages(data.token);
  } else {
    scenarioCustomer(data.token);
  }

  sleep(0.5 + Math.random());
}

export function handleSummary(data) {
  return generateCustomSummary(data, `Stress Test (Max ${peakUsers} VUs)`);
}
