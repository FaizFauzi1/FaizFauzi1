import 'package:equatable/equatable.dart';

enum BanType { temporary, permanent, warning }
enum BanReason { spam, harassment, fraud, violation_of_terms, inappropriate_content }

class BannedUser extends Equatable {
  final String id;
  final String userId;
  final BanType banType;
  final BanReason banReason;
  final String? banDetails;
  final DateTime? banExpiresAt;
  final String bannedBy;
  final String? unbannedBy;
  final DateTime? unbannedAt;
  final bool isActive;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BannedUser({
    required this.id,
    required this.userId,
    required this.banType,
    required this.banReason,
    this.banDetails,
    this.banExpiresAt,
    required this.bannedBy,
    this.unbannedBy,
    this.unbannedAt,
    this.isActive = true,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory BannedUser.fromJson(Map<String, dynamic> json) {
    return BannedUser(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      banType: BanType.values.firstWhere(
        (type) => type.name == json['ban_type'],
        orElse: () => BanType.temporary,
      ),
      banReason: BanReason.values.firstWhere(
        (reason) => reason.name == json['ban_reason'],
        orElse: () => BanReason.violation_of_terms,
      ),
      banDetails: json['ban_details'] as String?,
      banExpiresAt: json['ban_expires_at'] != null ? DateTime.parse(json['ban_expires_at']) : null,
      bannedBy: json['banned_by'] as String,
      unbannedBy: json['unbanned_by'] as String?,
      unbannedAt: json['unbanned_at'] != null ? DateTime.parse(json['unbanned_at']) : null,
      isActive: json['is_active'] ?? true,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'ban_type': banType.name,
      'ban_reason': banReason.name,
      'ban_details': banDetails,
      'ban_expires_at': banExpiresAt?.toIso8601String(),
      'banned_by': bannedBy,
      'unbanned_by': unbannedBy,
      'unbanned_at': unbannedAt?.toIso8601String(),
      'is_active': isActive,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BannedUser copyWith({
    String? id,
    String? userId,
    BanType? banType,
    BanReason? banReason,
    String? banDetails,
    DateTime? banExpiresAt,
    String? bannedBy,
    String? unbannedBy,
    DateTime? unbannedAt,
    bool? isActive,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BannedUser(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      banType: banType ?? this.banType,
      banReason: banReason ?? this.banReason,
      banDetails: banDetails ?? this.banDetails,
      banExpiresAt: banExpiresAt ?? this.banExpiresAt,
      bannedBy: bannedBy ?? this.bannedBy,
      unbannedBy: unbannedBy ?? this.unbannedBy,
      unbannedAt: unbannedAt ?? this.unbannedAt,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        banType,
        banReason,
        banDetails,
        banExpiresAt,
        bannedBy,
        unbannedBy,
        unbannedAt,
        isActive,
        metadata,
        createdAt,
        updatedAt,
      ];
}
