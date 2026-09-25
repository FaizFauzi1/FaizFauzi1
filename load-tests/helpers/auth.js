import http from 'k6/http';
import { check } from 'k6';
import { Config } from '../config/config.js';

/**
 * Supabase Auth Service Helper for k6.
 * Implements real Supabase GoTrue authentication flows with detailed diagnostics.
 */
export class AuthService {
  /**
   * Login with email and password via Supabase Auth API
   */
  static login(email, password, tag = 'auth_login') {
    // If no credentials configured, skip network call and return unauthenticated state
    if (!email || !password || email === 'customer_test@eventease.app') {
      console.warn(`[AUTH_WARN] No dedicated test credentials provided in environment. Skipping auth login.`);
      return {
        success: false,
        status: 0,
        error: 'No test credentials configured',
        accessToken: null,
        refreshToken: null,
        user: null,
      };
    }

    const url = Config.authUrl('token?grant_type=password');
    const payload = JSON.stringify({
      email: email,
      password: password,
    });

    const params = {
      headers: {
        'apikey': Config.supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      tags: { name: tag },
    };

    const res = http.post(url, payload, params);

    if (res.status >= 400) {
      const safeBody = (res.body || '').replace(/[\r\n]+/g, ' ').substring(0, 200);
      console.error(`[AUTH_FAIL] status=${res.status} method=POST endpoint=${tag} url=${url} body=${safeBody}`);
    }

    const isSuccess = check(res, {
      'login status is 200': (r) => r.status === 200,
      'access_token returned': (r) => {
        try {
          const body = JSON.parse(r.body);
          return body.access_token !== undefined && body.access_token.length > 10;
        } catch (_) {
          return false;
        }
      },
    });

    if (!isSuccess) {
      return {
        success: false,
        status: res.status,
        error: res.body,
        accessToken: null,
        refreshToken: null,
        user: null,
      };
    }

    const data = JSON.parse(res.body);
    return {
      success: true,
      status: res.status,
      accessToken: data.access_token,
      refreshToken: data.refresh_token,
      user: data.user,
    };
  }

  /**
   * Refresh session token
   */
  static refreshToken(refreshToken, tag = 'auth_refresh') {
    if (!refreshToken) return null;
    const url = Config.authUrl('token?grant_type=refresh_token');
    const payload = JSON.stringify({
      refresh_token: refreshToken,
    });

    const params = {
      headers: {
        'apikey': Config.supabaseAnonKey,
        'Content-Type': 'application/json',
      },
      tags: { name: tag },
    };

    const res = http.post(url, payload, params);

    if (res.status >= 400) {
      const safeBody = (res.body || '').replace(/[\r\n]+/g, ' ').substring(0, 200);
      console.error(`[AUTH_FAIL] status=${res.status} method=POST endpoint=${tag} url=${url} body=${safeBody}`);
    }

    const isSuccess = check(res, {
      'refresh status is 200': (r) => r.status === 200,
      'new access_token returned': (r) => {
        try {
          return JSON.parse(r.body).access_token !== undefined;
        } catch (_) {
          return false;
        }
      },
    });

    if (!isSuccess) return null;
    return JSON.parse(res.body);
  }

  /**
   * Get current authenticated user details
   */
  static getUser(accessToken, tag = 'auth_get_user') {
    if (!accessToken) return null;
    const url = Config.authUrl('user');
    const params = {
      headers: {
        'apikey': Config.supabaseAnonKey,
        'Authorization': `Bearer ${accessToken}`,
      },
      tags: { name: tag },
    };

    const res = http.get(url, params);
    if (res.status >= 400) {
      const safeBody = (res.body || '').replace(/[\r\n]+/g, ' ').substring(0, 200);
      console.error(`[AUTH_FAIL] status=${res.status} method=GET endpoint=${tag} url=${url} body=${safeBody}`);
    }

    check(res, {
      'get user status is 200': (r) => r.status === 200,
    });

    return res;
  }

  /**
   * Logout user
   */
  static logout(accessToken, tag = 'auth_logout') {
    if (!accessToken) return null;
    const url = Config.authUrl('logout');
    const params = {
      headers: {
        'apikey': Config.supabaseAnonKey,
        'Authorization': `Bearer ${accessToken}`,
      },
      tags: { name: tag },
    };

    const res = http.post(url, null, params);
    check(res, {
      'logout status is 204 or 200': (r) => r.status === 204 || r.status === 200,
    });

    return res;
  }
}
