import 'dart:convert';

enum RefundPolicyType { noRefund, partialRefund, fullRefund }

extension RefundPolicyTypeExtension on RefundPolicyType {
  String get displayName {
    switch (this) {
      case RefundPolicyType.noRefund: return 'No Refund';
      case RefundPolicyType.partialRefund: return 'Partial Refund';
      case RefundPolicyType.fullRefund: return 'Full Refund';
    }
  }
  String get description {
    switch (this) {
      case RefundPolicyType.noRefund: return 'No refund will be issued upon cancellation.';
      case RefundPolicyType.partialRefund: return 'A partial refund will be issued based on cancellation timing.';
      case RefundPolicyType.fullRefund: return 'Full refund guaranteed if cancelled within the policy window.';
    }
  }
}

/// Defines the guarantee and service assurance terms a vendor provides
/// for a wedding service package.
class ServiceGuarantee {
  /// Whether the vendor offers a satisfaction guarantee.
  final bool hasSatisfactionGuarantee;

  /// The refund policy offered.
  final RefundPolicyType refundPolicy;

  /// Description of the refund conditions (e.g. "50% refund if cancelled 30+ days before")
  final String? refundConditions;

  /// Whether the vendor provides a backup plan if something goes wrong.
  final bool hasBackupPlan;

  /// Description of the backup arrangement.
  final String? backupPlanDescription;

  /// SLA: maximum hours vendor will respond to enquiries/issues.
  final int? slaResponseHours;

  /// Custom guarantee terms or additional commitments.
  final String? customTerms;

  /// Whether vendor quality is certified / accredited.
  final bool isCertifiedQuality;

  /// Name of certification / accreditation (if any).
  final String? certificationName;

  const ServiceGuarantee({
    this.hasSatisfactionGuarantee = false,
    this.refundPolicy = RefundPolicyType.noRefund,
    this.refundConditions,
    this.hasBackupPlan = false,
    this.backupPlanDescription,
    this.slaResponseHours,
    this.customTerms,
    this.isCertifiedQuality = false,
    this.certificationName,
  });

  bool get hasAnyGuarantee =>
      hasSatisfactionGuarantee ||
      hasBackupPlan ||
      refundPolicy != RefundPolicyType.noRefund ||
      (slaResponseHours != null) ||
      isCertifiedQuality;

  ServiceGuarantee copyWith({
    bool? hasSatisfactionGuarantee,
    RefundPolicyType? refundPolicy,
    String? refundConditions,
    bool? hasBackupPlan,
    String? backupPlanDescription,
    int? slaResponseHours,
    String? customTerms,
    bool? isCertifiedQuality,
    String? certificationName,
  }) {
    return ServiceGuarantee(
      hasSatisfactionGuarantee: hasSatisfactionGuarantee ?? this.hasSatisfactionGuarantee,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      refundConditions: refundConditions ?? this.refundConditions,
      hasBackupPlan: hasBackupPlan ?? this.hasBackupPlan,
      backupPlanDescription: backupPlanDescription ?? this.backupPlanDescription,
      slaResponseHours: slaResponseHours ?? this.slaResponseHours,
      customTerms: customTerms ?? this.customTerms,
      isCertifiedQuality: isCertifiedQuality ?? this.isCertifiedQuality,
      certificationName: certificationName ?? this.certificationName,
    );
  }

  Map<String, dynamic> toJson() => {
    'has_satisfaction_guarantee': hasSatisfactionGuarantee,
    'refund_policy': refundPolicy.name,
    'refund_conditions': refundConditions,
    'has_backup_plan': hasBackupPlan,
    'backup_plan_description': backupPlanDescription,
    'sla_response_hours': slaResponseHours,
    'custom_terms': customTerms,
    'is_certified_quality': isCertifiedQuality,
    'certification_name': certificationName,
  };

  factory ServiceGuarantee.fromJson(Map<String, dynamic> json) {
    return ServiceGuarantee(
      hasSatisfactionGuarantee: json['has_satisfaction_guarantee'] ?? false,
      refundPolicy: RefundPolicyType.values.firstWhere(
        (e) => e.name == (json['refund_policy'] ?? 'noRefund'),
        orElse: () => RefundPolicyType.noRefund,
      ),
      refundConditions: json['refund_conditions']?.toString(),
      hasBackupPlan: json['has_backup_plan'] ?? false,
      backupPlanDescription: json['backup_plan_description']?.toString(),
      slaResponseHours: (json['sla_response_hours'] as num?)?.toInt(),
      customTerms: json['custom_terms']?.toString(),
      isCertifiedQuality: json['is_certified_quality'] ?? false,
      certificationName: json['certification_name']?.toString(),
    );
  }

  static ServiceGuarantee? fromNullableJson(dynamic data) {
    if (data == null) return null;
    try {
      Map<String, dynamic> map;
      if (data is String) {
        if (data.isEmpty || data == '{}') return null;
        map = jsonDecode(data) as Map<String, dynamic>;
      } else if (data is Map) {
        map = Map<String, dynamic>.from(data);
      } else {
        return null;
      }
      return ServiceGuarantee.fromJson(map);
    } catch (_) {
      return null;
    }
  }
}
