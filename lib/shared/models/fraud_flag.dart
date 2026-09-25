import 'package:equatable/equatable.dart';

enum FraudFlagType {
  multipleCancellations,
  duplicateAccounts,
  fakeBooking,
  suspiciousPayment,
  unusualActivity
}

enum FraudSeverity { low, medium, high, critical }
enum FraudStatus { open, investigating, resolved, dismissed }

class FraudFlag extends Equatable {
  final String id;
  final String? userId;
  final String? bookingId;
  final FraudFlagType flagType;
  final FraudSeverity severity;
  final String description;
  final Map<String, dynamic> evidence;
  final FraudStatus status;
  final String? resolvedBy;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FraudFlag({
    required this.id,
    this.userId,
    this.bookingId,
    required this.flagType,
    this.severity = FraudSeverity.medium,
    required this.description,
    required this.evidence,
    this.status = FraudStatus.open,
    this.resolvedBy,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FraudFlag.fromJson(Map<String, dynamic> json) {
    return FraudFlag(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      bookingId: json['booking_id'] as String?,
      flagType: FraudFlagType.values.firstWhere(
        (type) => type.name == json['flag_type'],
        orElse: () => FraudFlagType.unusualActivity,
      ),
      severity: FraudSeverity.values.firstWhere(
        (severity) => severity.name == json['severity'],
        orElse: () => FraudSeverity.medium,
      ),
      description: json['description'] as String,
      evidence: Map<String, dynamic>.from(json['evidence'] ?? {}),
      status: FraudStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => FraudStatus.open,
      ),
      resolvedBy: json['resolved_by'] as String?,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'booking_id': bookingId,
      'flag_type': flagType.name,
      'severity': severity.name,
      'description': description,
      'evidence': evidence,
      'status': status.name,
      'resolved_by': resolvedBy,
      'resolved_at': resolvedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  FraudFlag copyWith({
    String? id,
    String? userId,
    String? bookingId,
    FraudFlagType? flagType,
    FraudSeverity? severity,
    String? description,
    Map<String, dynamic>? evidence,
    FraudStatus? status,
    String? resolvedBy,
    DateTime? resolvedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FraudFlag(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bookingId: bookingId ?? this.bookingId,
      flagType: flagType ?? this.flagType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      evidence: evidence ?? this.evidence,
      status: status ?? this.status,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        bookingId,
        flagType,
        severity,
        description,
        evidence,
        status,
        resolvedBy,
        resolvedAt,
        createdAt,
        updatedAt,
      ];
}
