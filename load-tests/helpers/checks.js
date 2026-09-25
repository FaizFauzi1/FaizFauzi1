import { check } from 'k6';

/**
 * Standard HTTP Assertion Checks for EventEase Test Scenarios
 */
export class Checks {
  /**
   * Check if HTTP status is 200 OK
   */
  static isOk(res, tag = 'is_200_ok') {
    return check(res, {
      [`${tag}: status is 200`]: (r) => r.status === 200,
    });
  }

  /**
   * Check if HTTP status is 201 Created
   */
  static isCreated(res, tag = 'is_201_created') {
    return check(res, {
      [`${tag}: status is 201`]: (r) => r.status === 201,
    });
  }

  /**
   * Check if response is successful (200, 201, or 204)
   */
  static isSuccess(res, tag = 'is_success') {
    return check(res, {
      [`${tag}: status 2xx`]: (r) => r.status >= 200 && r.status < 300,
    });
  }

  /**
   * Check if response is JSON array and optionally not empty
   */
  static isJsonArray(res, minLength = 0, tag = 'json_array') {
    return check(res, {
      [`${tag}: response is valid json array`]: (r) => {
        try {
          const body = JSON.parse(r.body);
          return Array.isArray(body) && body.length >= minLength;
        } catch (_) {
          return false;
        }
      },
    });
  }

  /**
   * Check if response is JSON object with specific field
   */
  static hasField(res, fieldName, tag = 'has_field') {
    return check(res, {
      [`${tag}: response has ${fieldName}`]: (r) => {
        try {
          const body = JSON.parse(r.body);
          return body && body[fieldName] !== undefined;
        } catch (_) {
          return false;
        }
      },
    });
  }

  /**
   * Check authorization rejection (401 or 403)
   */
  static isForbiddenOrUnauthorized(res, tag = 'is_denied') {
    return check(res, {
      [`${tag}: status is 401 or 403`]: (r) => r.status === 401 || r.status === 403,
    });
  }

  /**
   * Check rate limiting (429)
   */
  static isRateLimited(res, tag = 'rate_limit') {
    return check(res, {
      [`${tag}: status is 429`]: (r) => r.status === 429,
    });
  }
}
