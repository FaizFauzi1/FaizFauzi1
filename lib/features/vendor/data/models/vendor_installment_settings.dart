import 'package:equatable/equatable.dart';

class VendorInstallmentSettings extends Equatable {
  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// `vendor_installment_settings.vendor_id` is a UUID; placeholders like [default_vendor] must not hit Supabase.
  static bool isValidVendorUuid(String? value) {
    if (value == null || value.isEmpty) return false;
    return _uuidRegex.hasMatch(value);
  }

  final String? id;
  final String vendorId;
  final bool isEnabled;
  final double depositPercentage;
  final int maxInstallments;
  final double minOrderAmount;
  final int paymentDeadlineDays;
  final bool allowCustomPlans;
  final double lateFeePercentage;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const VendorInstallmentSettings({
    this.id,
    required this.vendorId,
    this.isEnabled = false,
    this.depositPercentage = 30.0,
    this.maxInstallments = 5,
    this.minOrderAmount = 500.0,
    this.paymentDeadlineDays = 30,
    this.allowCustomPlans = false,
    this.lateFeePercentage = 5.0,
    this.createdAt,
    this.updatedAt,
  });

  factory VendorInstallmentSettings.defaultSettings(String vendorId) {
    return VendorInstallmentSettings(
      vendorId: vendorId,
    );
  }

  factory VendorInstallmentSettings.fromSupabase(Map<String, dynamic> json) {
    final maxInst = json['max_installments'] ?? json['default_number_of_installments'];
    return VendorInstallmentSettings(
      id: json['id'] as String?,
      vendorId: json['vendor_id'] as String,
      isEnabled: json['is_enabled'] as bool? ??
          json['installments_enabled'] as bool? ??
          false,
      depositPercentage: (json['deposit_percentage'] as num?)?.toDouble() ??
          (json['default_deposit_percentage'] as num?)?.toDouble() ??
          30.0,
      maxInstallments: maxInst is int
          ? maxInst
          : (maxInst as num?)?.toInt() ?? 5,
      minOrderAmount: (json['min_order_amount'] as num?)?.toDouble() ??
          (json['minimum_order_amount'] as num?)?.toDouble() ??
          500.0,
      paymentDeadlineDays: json['payment_deadline_days'] is int
          ? json['payment_deadline_days'] as int
          : (json['payment_deadline_days'] as num?)?.toInt() ?? 30,
      allowCustomPlans: json['allow_custom_plans'] as bool? ?? false,
      lateFeePercentage: (json['late_fee_percentage'] as num?)?.toDouble() ?? 5.0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  /// Legacy table shape (`default_deposit_percentage`, `installments_enabled`, …).
  Map<String, dynamic> toSupabaseJson() {
    return {
      if (id != null) 'id': id,
      'vendor_id': vendorId,
      'installments_enabled': isEnabled,
      'default_deposit_percentage': depositPercentage,
      'default_number_of_installments': maxInstallments,
      'minimum_order_amount': minOrderAmount,
      'payment_deadline_days': paymentDeadlineDays,
      'allow_custom_plans': allowCustomPlans,
      'late_fee_percentage': lateFeePercentage,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Newer migration shape (`deposit_percentage`, `is_enabled`, …).
  Map<String, dynamic> toSupabaseJsonModern() {
    return {
      if (id != null) 'id': id,
      'vendor_id': vendorId,
      'is_enabled': isEnabled,
      'deposit_percentage': depositPercentage,
      'max_installments': maxInstallments,
      'min_order_amount': minOrderAmount,
      'payment_deadline_days': paymentDeadlineDays,
      'allow_custom_plans': allowCustomPlans,
      'late_fee_percentage': lateFeePercentage,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  VendorInstallmentSettings copyWith({
    String? id,
    String? vendorId,
    bool? isEnabled,
    double? depositPercentage,
    int? maxInstallments,
    double? minOrderAmount,
    int? paymentDeadlineDays,
    bool? allowCustomPlans,
    double? lateFeePercentage,
  }) {
    return VendorInstallmentSettings(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      isEnabled: isEnabled ?? this.isEnabled,
      depositPercentage: depositPercentage ?? this.depositPercentage,
      maxInstallments: maxInstallments ?? this.maxInstallments,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      paymentDeadlineDays: paymentDeadlineDays ?? this.paymentDeadlineDays,
      allowCustomPlans: allowCustomPlans ?? this.allowCustomPlans,
      lateFeePercentage: lateFeePercentage ?? this.lateFeePercentage,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        isEnabled,
        depositPercentage,
        maxInstallments,
        minOrderAmount,
        paymentDeadlineDays,
        allowCustomPlans,
        lateFeePercentage,
      ];
}
