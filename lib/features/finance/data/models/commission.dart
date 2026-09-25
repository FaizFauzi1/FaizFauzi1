enum CommissionStatus { pending, paid, cancelled }

enum CommissionType { booking, service, package }

class CommissionRate {
  final String id;
  final String vendorId;
  final CommissionType type;
  final double percentage;
  final double? fixedAmount;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo;
  final bool isActive;

  CommissionRate({
    required this.id,
    required this.vendorId,
    required this.type,
    required this.percentage,
    this.fixedAmount,
    required this.effectiveFrom,
    this.effectiveTo,
    this.isActive = true,
  });

  double calculateCommission(double amount) {
    if (fixedAmount != null) {
      return fixedAmount!;
    }
    return amount * (percentage / 100);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'type': type.toString(),
      'percentage': percentage,
      'fixedAmount': fixedAmount,
      'effectiveFrom': effectiveFrom.toIso8601String(),
      'effectiveTo': effectiveTo?.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory CommissionRate.fromJson(Map<String, dynamic> json) {
    return CommissionRate(
      id: json['id'],
      vendorId: json['vendorId'],
      type: CommissionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => CommissionType.booking,
      ),
      percentage: json['percentage']?.toDouble() ?? 0.0,
      fixedAmount: json['fixedAmount']?.toDouble(),
      effectiveFrom: DateTime.parse(json['effectiveFrom']),
      effectiveTo: json['effectiveTo'] != null ? DateTime.parse(json['effectiveTo']) : null,
      isActive: json['isActive'] ?? true,
    );
  }
}

class CommissionTransaction {
  final String id;
  final String vendorId;
  final String bookingId;
  final CommissionType type;
  final double totalAmount;
  final double commissionAmount;
  final double platformFee;
  final double vendorEarnings;
  CommissionStatus status;
  final DateTime createdAt;
  DateTime? paidAt;
  String? paymentReference;
  String? notes;

  CommissionTransaction({
    required this.id,
    required this.vendorId,
    required this.bookingId,
    required this.type,
    required this.totalAmount,
    required this.commissionAmount,
    required this.platformFee,
    required this.vendorEarnings,
    this.status = CommissionStatus.pending,
    required this.createdAt,
    this.paidAt,
    this.paymentReference,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'bookingId': bookingId,
      'type': type.toString(),
      'totalAmount': totalAmount,
      'commissionAmount': commissionAmount,
      'platformFee': platformFee,
      'vendorEarnings': vendorEarnings,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'paymentReference': paymentReference,
      'notes': notes,
    };
  }

  factory CommissionTransaction.fromJson(Map<String, dynamic> json) {
    return CommissionTransaction(
      id: json['id'],
      vendorId: json['vendorId'],
      bookingId: json['bookingId'],
      type: CommissionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => CommissionType.booking,
      ),
      totalAmount: json['totalAmount']?.toDouble() ?? 0.0,
      commissionAmount: json['commissionAmount']?.toDouble() ?? 0.0,
      platformFee: json['platformFee']?.toDouble() ?? 0.0,
      vendorEarnings: json['vendorEarnings']?.toDouble() ?? 0.0,
      status: CommissionStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => CommissionStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      paymentReference: json['paymentReference'],
      notes: json['notes'],
    );
  }
}

class CommissionSummary {
  final String vendorId;
  final double totalEarnings;
  final double totalCommission;
  final double pendingPayments;
  final double paidPayments;
  final int totalTransactions;
  final int pendingTransactions;
  final DateTime lastUpdated;

  CommissionSummary({
    required this.vendorId,
    required this.totalEarnings,
    required this.totalCommission,
    required this.pendingPayments,
    required this.paidPayments,
    required this.totalTransactions,
    required this.pendingTransactions,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'totalEarnings': totalEarnings,
      'totalCommission': totalCommission,
      'pendingPayments': pendingPayments,
      'paidPayments': paidPayments,
      'totalTransactions': totalTransactions,
      'pendingTransactions': pendingTransactions,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory CommissionSummary.fromJson(Map<String, dynamic> json) {
    return CommissionSummary(
      vendorId: json['vendorId'],
      totalEarnings: json['totalEarnings']?.toDouble() ?? 0.0,
      totalCommission: json['totalCommission']?.toDouble() ?? 0.0,
      pendingPayments: json['pendingPayments']?.toDouble() ?? 0.0,
      paidPayments: json['paidPayments']?.toDouble() ?? 0.0,
      totalTransactions: json['totalTransactions'] ?? 0,
      pendingTransactions: json['pendingTransactions'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
