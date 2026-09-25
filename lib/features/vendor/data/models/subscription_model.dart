class SubscriptionTierModel {
  final String id;
  final String name;
  final String displayName;
  final double price;
  final String billingCycle;
  final List<String> features;
  final Map<String, dynamic> limits;
  final bool isPopular;
  final int sortOrder;

  SubscriptionTierModel({
    required this.id,
    required this.name,
    required this.displayName,
    required this.price,
    required this.billingCycle,
    required this.features,
    required this.limits,
    this.isPopular = false,
    this.sortOrder = 0,
  });

  factory SubscriptionTierModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionTierModel(
      id: json['id'],
      name: json['name'],
      displayName: json['display_name'] ?? json['name'],
      price: (json['price'] ?? 0).toDouble(),
      billingCycle: json['billing_cycle'] ?? 'Monthly',
      features: List<String>.from(json['features'] ?? []),
      limits: json['limits'] ?? {},
      isPopular: json['is_popular'] ?? false,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'price': price,
      'billing_cycle': billingCycle,
      'features': features,
      'limits': limits,
      'is_popular': isPopular,
      'sort_order': sortOrder,
    };
  }
}

class SubscriptionPayment {
  final String id;
  final String vendorId;
  final String tierId;
  final double amount;
  final String status;
  final DateTime createdAt;
  final DateTime? periodStart;
  final DateTime? periodEnd;

  SubscriptionPayment({
    required this.id,
    required this.vendorId,
    required this.tierId,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.periodStart,
    this.periodEnd,
  });

  factory SubscriptionPayment.fromJson(Map<String, dynamic> json) {
    return SubscriptionPayment(
      id: json['id'],
      vendorId: json['vendor_id'],
      tierId: json['tier_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['payment_status'] ?? json['status'] ?? 'unknown',
      createdAt: DateTime.parse(json['created_at']),
      periodStart: json['billing_period_start'] != null ? DateTime.parse(json['billing_period_start']) : null,
      periodEnd: json['billing_period_end'] != null ? DateTime.parse(json['billing_period_end']) : null,
    );
  }
}
