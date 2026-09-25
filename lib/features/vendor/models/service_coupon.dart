class ServiceCoupon {
  final String? id;
  final String? serviceId;
  final String vendorId;
  final String code;
  final String discountType; // 'percentage' or 'flat'
  final double discountValue;
  final double minSpend;
  final double? maxDiscount;
  final DateTime? expiryDate;
  final int? usageLimit;
  final int currentUsage;
  final bool isActive;
  final DateTime? createdAt;

  ServiceCoupon({
    this.id,
    this.serviceId,
    required this.vendorId,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.minSpend = 0.0,
    this.maxDiscount,
    this.expiryDate,
    this.usageLimit,
    this.currentUsage = 0,
    this.isActive = true,
    this.createdAt,
  });

  factory ServiceCoupon.fromJson(Map<String, dynamic> json) {
    return ServiceCoupon(
      id: json['id'],
      serviceId: json['service_id'],
      vendorId: json['vendor_id'] ?? '',
      code: json['code'] ?? '',
      discountType: json['discount_type'] ?? 'percentage',
      discountValue: (json['discount_value'] as num?)?.toDouble() ?? 0.0,
      minSpend: (json['min_spend'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (json['max_discount'] as num?)?.toDouble(),
      expiryDate: json['expiry_date'] != null ? DateTime.parse(json['expiry_date']) : null,
      usageLimit: json['usage_limit'],
      currentUsage: json['current_usage'] ?? 0,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'service_id': serviceId,
      'vendor_id': vendorId,
      'code': code,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_spend': minSpend,
      'max_discount': maxDiscount,
      'expiry_date': expiryDate?.toIso8601String(),
      'usage_limit': usageLimit,
      'current_usage': currentUsage,
      'is_active': isActive,
    };
  }

  ServiceCoupon copyWith({
    String? id,
    String? serviceId,
    String? vendorId,
    String? code,
    String? discountType,
    double? discountValue,
    double? minSpend,
    double? maxDiscount,
    DateTime? expiryDate,
    int? usageLimit,
    int? currentUsage,
    bool? isActive,
  }) {
    return ServiceCoupon(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      vendorId: vendorId ?? this.vendorId,
      code: code ?? this.code,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      minSpend: minSpend ?? this.minSpend,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      expiryDate: expiryDate ?? this.expiryDate,
      usageLimit: usageLimit ?? this.usageLimit,
      currentUsage: currentUsage ?? this.currentUsage,
      isActive: isActive ?? this.isActive,
    );
  }
}
