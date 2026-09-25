/**
 * Test Data Generator and Sanitization Helpers
 * Generates synthetic, tagged test entities so they can be isolated or pruned.
 */

export class TestDataGenerator {
  /**
   * Generate RFC4122 compliant random UUID (v4)
   */
  static uuid() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
      const r = (Math.random() * 16) | 0;
      const v = c === 'x' ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
  }

  /**
   * Generates a date string (YYYY-MM-DD) offset in the future
   */
  static futureDateString(daysAhead = 30) {
    const d = new Date();
    d.setDate(d.getDate() + daysAhead);
    return d.toISOString().split('T')[0];
  }

  /**
   * Generate booking test payload
   */
  static bookingPayload(customerId, vendorId, serviceId = null, dateOffset = 30) {
    return {
      vendor_id: vendorId,
      customer_id: customerId,
      service_id: serviceId,
      booking_date: this.futureDateString(dateOffset),
      booking_time: '14:00:00',
      total_amount: 1500.00,
      status: 'pending',
      notes: `[k6-loadtest-${Date.now()}] Automated load test booking`,
    };
  }

  /**
   * Generate favourite item payload
   */
  static favoritePayload(userId, itemId, itemType = 'vendor') {
    return {
      user_id: userId,
      item_id: itemId,
      item_type: itemType,
    };
  }

  /**
   * Generate review test payload
   */
  static reviewPayload(customerId, serviceId) {
    return {
      service_id: serviceId,
      customer_id: customerId,
      rating: 5,
      comment: `[k6-loadtest] Verified test review submitted at ${new Date().toISOString()}`,
    };
  }

  /**
   * Generate chat message test payload
   */
  static chatMessagePayload(conversationId, senderId) {
    return {
      conversation_id: conversationId,
      sender_id: senderId,
      message: `[k6-loadtest] Synthetic message payload ${Math.random().toString(36).substring(7)}`,
      created_at: new Date().toISOString(),
    };
  }

  /**
   * Generate event planner item payload
   */
  static eventPayload(hostId) {
    return {
      host_id: hostId,
      title: `[k6-loadtest] Event ${Date.now()}`,
      description: 'Automated load test generated event',
      date: this.futureDateString(60),
      location: 'Kuala Lumpur Convention Centre',
      budget: 10000.00,
      status: 'planning',
    };
  }

  /**
   * Generate Xendit Mock Webhook Payload for idempotency testing
   */
  static xenditWebhookPayload(externalId, invoiceId = null, status = 'PAID') {
    const invId = invoiceId || `inv_k6_${Date.now()}`;
    return {
      id: invId,
      external_id: externalId,
      status: status,
      amount: 100.00,
      paid_amount: 100.00,
      payer_email: 'test@eventease.app',
      description: 'EventEase Subscription Payment Load Test',
      payment_method: 'CREDIT_CARD',
      created: new Date().toISOString(),
      updated: new Date().toISOString(),
    };
  }

  /**
   * Small binary synthetic payload for Storage testing (PNG signature, ~1KB)
   */
  static generateDummyImageBytes() {
    // 64-byte minimal mock image buffer string
    return 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==';
  }
}
