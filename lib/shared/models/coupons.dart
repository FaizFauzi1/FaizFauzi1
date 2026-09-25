import 'package:equatable/equatable.dart';

class Coupons extends Equatable {
  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final int? maxUses;
  final int usedCount;
  final DateTime validFrom;
  final DateTime validUntil;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Coupons({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    this.maxUses,
    this.usedCount = 0,
    required this.validFrom,
    required this.validUntil,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Coupons.fromJson(Map<String, dynamic> json) {
    return Coupons(
      id: json['id'] as String,
      code: json['code'] as String,
      discountType: json['discount_type'] as String,
      discountValue: (json['discount_value'] ?? 0).toDouble(),
      maxUses: json['max_uses'] as int?,
      usedCount: json['used_count'] ?? 0,
      validFrom: DateTime.parse(json['valid_from']),
      validUntil: DateTime.parse(json['valid_until']),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'discount_type': discountType,
      'discount_value': discountValue,
      'max_uses': maxUses,
      'used_count': usedCount,
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Coupons copyWith({
    String? id,
    String? code,
    String? discountType,
    double? discountValue,
    int? maxUses,
    int? usedCount,
    DateTime? validFrom,
    DateTime? validUntil,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Coupons(
      id: id ?? this.id,
      code: code ?? this.code,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      maxUses: maxUses ?? this.maxUses,
      usedCount: usedCount ?? this.usedCount,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        code,
        discountType,
        discountValue,
        maxUses,
        usedCount,
        validFrom,
        validUntil,
        isActive,
        createdAt,
        updatedAt,
      ];
}
