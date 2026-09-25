import 'package:equatable/equatable.dart';

class PlatformCommission extends Equatable {
  final String id;
  final String bookingId;
  final String vendorId;
  final double platformFee;
  final double vendorEarnings;
  final double commissionRate;
  final String? adminId;
  final DateTime createdAt;

  const PlatformCommission({
    required this.id,
    required this.bookingId,
    required this.vendorId,
    required this.platformFee,
    required this.vendorEarnings,
    required this.commissionRate,
    this.adminId,
    required this.createdAt,
  });

  factory PlatformCommission.fromJson(Map<String, dynamic> json) {
    return PlatformCommission(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      vendorId: json['vendor_id'] as String,
      platformFee: (json['platform_fee'] ?? 0).toDouble(),
      vendorEarnings: (json['vendor_earnings'] ?? 0).toDouble(),
      commissionRate: (json['commission_rate'] ?? 0).toDouble(),
      adminId: json['admin_id'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'vendor_id': vendorId,
      'platform_fee': platformFee,
      'vendor_earnings': vendorEarnings,
      'commission_rate': commissionRate,
      'admin_id': adminId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        vendorId,
        platformFee,
        vendorEarnings,
        commissionRate,
        adminId,
        createdAt,
      ];
}
