import http from 'k6/http';
import { Counter } from 'k6/metrics';
import { Config } from '../config/config.js';

// Custom classification counters
export const timeoutsCount = new Counter('http_timeouts_count');
export const gatewayErrorsCount = new Counter('http_gateway_errors_count');
export const serverErrorsCount = new Counter('http_server_errors_count');
export const clientErrorsCount = new Counter('http_client_errors_count');

/**
 * Standard HTTP Client for Supabase REST, Auth, and Storage calls.
 * Includes detailed failure diagnostics logging and failure classification.
 */
export class SupabaseHttpClient {
  constructor(authToken = null) {
    this.authToken = authToken;
  }

  setAuthToken(token) {
    this.authToken = token;
  }

  getHeaders(customHeaders = {}) {
    const headers = {
      'apikey': Config.supabaseAnonKey,
      'Content-Type': 'application/json',
      'Prefer': 'return=representation',
    };

    if (this.authToken) {
      headers['Authorization'] = `Bearer ${this.authToken}`;
    }

    return Object.assign(headers, customHeaders);
  }

  _logFailure(method, endpoint, url, res, params) {
    if (res.status >= 400 || res.status === 0) {
      let failureType = 'UNKNOWN';
      const endpointTag = endpoint || 'unknown';

      if (res.status === 0) {
        failureType = 'TIMEOUT';
        timeoutsCount.add(1, { endpoint: endpointTag });
      } else if (res.status === 502 || res.status === 503 || res.status === 504) {
        failureType = 'GATEWAY_ERROR';
        gatewayErrorsCount.add(1, { endpoint: endpointTag, status: `${res.status}` });
      } else if (res.status >= 500) {
        failureType = 'SERVER_ERROR';
        serverErrorsCount.add(1, { endpoint: endpointTag, status: `${res.status}` });
      } else if (res.status >= 400) {
        failureType = 'CLIENT_ERROR';
        clientErrorsCount.add(1, { endpoint: endpointTag, status: `${res.status}` });
      }

      const safeBody = (res.body || '').replace(/[\r\n]+/g, ' ').substring(0, 250);
      const duration = res.timings ? res.timings.duration.toFixed(1) : '0.0';
      console.error(`[HTTP_FAIL][${failureType}] status=${res.status} method=${method} endpoint=${endpoint} vu=${__VU} iter=${__ITER} duration=${duration}ms url=${url} body=${safeBody}`);
    }
  }

  // REST API: GET
  get(table, query = '', customHeaders = {}, tags = {}) {
    const url = Config.restUrl(table, query);
    const endpointTag = tags.name || table;
    const params = {
      headers: this.getHeaders(customHeaders),
      timeout: Config.requestTimeout || '30s',
      tags: Object.assign({ endpoint: table, method: 'GET' }, tags),
    };
    const res = http.get(url, params);
    this._logFailure('GET', endpointTag, url, res, params);
    return res;
  }

  // REST API: POST (Insert or RPC)
  post(table, body = {}, customHeaders = {}, tags = {}) {
    const url = Config.restUrl(table);
    const endpointTag = tags.name || table;
    const params = {
      headers: this.getHeaders(customHeaders),
      timeout: Config.requestTimeout || '30s',
      tags: Object.assign({ endpoint: table, method: 'POST' }, tags),
    };
    const res = http.post(url, JSON.stringify(body), params);
    this._logFailure('POST', endpointTag, url, res, params);
    return res;
  }

  // REST API: RPC Call
  rpc(functionName, params = {}, customHeaders = {}, tags = {}) {
    const url = Config.restUrl(`rpc/${functionName}`);
    const endpointTag = tags.name || `rpc_${functionName}`;
    const reqOptions = {
      headers: this.getHeaders(customHeaders),
      timeout: Config.requestTimeout || '30s',
      tags: Object.assign({ endpoint: `rpc_${functionName}`, method: 'POST' }, tags),
    };
    const res = http.post(url, JSON.stringify(params), reqOptions);
    this._logFailure('POST', endpointTag, url, res, reqOptions);
    return res;
  }

  // REST API: PATCH (Update)
  patch(table, query = '', body = {}, customHeaders = {}, tags = {}) {
    const url = Config.restUrl(table, query);
    const endpointTag = tags.name || table;
    const params = {
      headers: this.getHeaders(customHeaders),
      timeout: Config.requestTimeout || '30s',
      tags: Object.assign({ endpoint: table, method: 'PATCH' }, tags),
    };
    const res = http.patch(url, JSON.stringify(body), params);
    this._logFailure('PATCH', endpointTag, url, res, params);
    return res;
  }

  // REST API: DELETE
  del(table, query = '', customHeaders = {}, tags = {}) {
    const url = Config.restUrl(table, query);
    const endpointTag = tags.name || table;
    const params = {
      headers: this.getHeaders(customHeaders),
      timeout: Config.requestTimeout || '30s',
      tags: Object.assign({ endpoint: table, method: 'DELETE' }, tags),
    };
    const res = http.del(url, null, params);
    this._logFailure('DELETE', endpointTag, url, res, params);
    return res;
  }

  // Edge Functions: POST
  invokeFunction(functionName, body = {}, customHeaders = {}, tags = {}) {
    const url = Config.functionsUrl(functionName);
    const endpointTag = tags.name || `function_${functionName}`;
    const params = {
      headers: this.getHeaders(customHeaders),
      timeout: Config.requestTimeout || '30s',
      tags: Object.assign({ endpoint: `function_${functionName}`, method: 'POST' }, tags),
    };
    const res = http.post(url, JSON.stringify(body), params);
    this._logFailure('POST', endpointTag, url, res, params);
    return res;
  }
}
