import 'package:equatable/equatable.dart';

enum ReferralStatus { pending, active, completed, expired }

class ReferralProgram extends Equatable {
  final String id;
  final String referrerId;
  final String refereeId;
  final String referralCode;
  final ReferralStatus status;
  final double referrerReward;
  final double refereeReward;
  final String? rewardType;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReferralProgram({
    required this.id,
    required this.referrerId,
    required this.refereeId,
    required this.referralCode,
    this.status = ReferralStatus.pending,
    required this.referrerReward,
    required this.refereeReward,
    this.rewardType,
    this.completedAt,
    this.expiresAt,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReferralProgram.fromJson(Map<String, dynamic> json) {
    return ReferralProgram(
      id: json['id'] as String,
      referrerId: json['referrer_id'] as String,
      refereeId: json['referee_id'] as String,
      referralCode: json['referral_code'] as String,
      status: ReferralStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ReferralStatus.pending,
      ),
      referrerReward: (json['referrer_reward'] as num).toDouble(),
      refereeReward: (json['referee_reward'] as num).toDouble(),
      rewardType: json['reward_type'] as String?,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at']) : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'referrer_id': referrerId,
      'referee_id': refereeId,
      'referral_code': referralCode,
      'status': status.name,
      'referrer_reward': referrerReward,
      'referee_reward': refereeReward,
      'reward_type': rewardType,
      'completed_at': completedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ReferralProgram copyWith({
    String? id,
    String? referrerId,
    String? refereeId,
    String? referralCode,
    ReferralStatus? status,
    double? referrerReward,
    double? refereeReward,
    String? rewardType,
    DateTime? completedAt,
    DateTime? expiresAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReferralProgram(
      id: id ?? this.id,
      referrerId: referrerId ?? this.referrerId,
      refereeId: refereeId ?? this.refereeId,
      referralCode: referralCode ?? this.referralCode,
      status: status ?? this.status,
      referrerReward: referrerReward ?? this.referrerReward,
      refereeReward: refereeReward ?? this.refereeReward,
      rewardType: rewardType ?? this.rewardType,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        referrerId,
        refereeId,
        referralCode,
        status,
        referrerReward,
        refereeReward,
        rewardType,
        completedAt,
        expiresAt,
        metadata,
        createdAt,
        updatedAt,
      ];
}
