import { AuthService } from '../helpers/auth.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

/**
 * Scenario: Authentication Flow
 * Validates Supabase GoTrue authentication endpoints:
 * 1. Login with credentials
 * 2. Get current user profile (/auth/v1/user)
 * 3. Refresh session token
 * 4. Logout
 */
export function scenarioAuth() {
  // 1. Login
  const loginResult = AuthService.login(
    Config.customer.email,
    Config.customer.password,
    'auth_login_customer'
  );

  if (!loginResult.success || !loginResult.accessToken) {
    sleep(1);
    return;
  }

  const token = loginResult.accessToken;
  const refreshToken = loginResult.refreshToken;

  // 2. Session / User verification
  AuthService.getUser(token, 'auth_get_user');
  sleep(0.5);

  // 3. Token refresh
  if (refreshToken) {
    AuthService.refreshToken(refreshToken, 'auth_refresh_token');
    sleep(0.5);
  }

  // 4. Logout
  AuthService.logout(token, 'auth_logout');
  sleep(1);
}
