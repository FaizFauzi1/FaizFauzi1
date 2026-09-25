import 'package:equatable/equatable.dart';

enum ReferralProgramType {
  customer,
  vendor,
  weddingOrganizer,
  influencer,
  eventCrew,
  marketplace;

  String get dbValue => switch (this) {
        ReferralProgramType.customer => 'customer',
        ReferralProgramType.vendor => 'vendor',
        ReferralProgramType.weddingOrganizer => 'wedding_organizer',
        ReferralProgramType.influencer => 'influencer',
        ReferralProgramType.eventCrew => 'event_crew',
        ReferralProgramType.marketplace => 'marketplace',
      };

  static ReferralProgramType fromDb(String value) {
    return ReferralProgramType.values.firstWhere(
      (t) => t.dbValue == value,
      orElse: () => ReferralProgramType.customer,
    );
  }

  static ReferralProgramType forRole(String role) {
    return switch (role) {
      'vendor' => ReferralProgramType.vendor,
      'organizer' => ReferralProgramType.weddingOrganizer,
      _ => ReferralProgramType.customer,
    };
  }
}

enum ReferralStatus { pending, qualified, rewarded, expired, rejected }

enum ReferralRewardStatus { pending, paid, cancelled }

class ReferralProgramConfig extends Equatable {
  final String id;
  final ReferralProgramType programType;
  final String name;
  final String? description;
  final String referrerRole;
  final String? refereeRole;
  final String rewardType;
  final double referrerRewardAmount;
  final double refereeRewardAmount;
  final double? commissionRate;
  final String qualifyingEvent;
  final int? minReferralsForBonus;
  final double? bonusRewardAmount;
  final bool isActive;

  const ReferralProgramConfig({
    required this.id,
    required this.programType,
    required this.name,
    this.description,
    required this.referrerRole,
    this.refereeRole,
    required this.rewardType,
    this.referrerRewardAmount = 0,
    this.refereeRewardAmount = 0,
    this.commissionRate,
    required this.qualifyingEvent,
    this.minReferralsForBonus,
    this.bonusRewardAmount,
    this.isActive = true,
  });

  factory ReferralProgramConfig.fromJson(Map<String, dynamic> json) {
    return ReferralProgramConfig(
      id: json['id'] as String,
      programType: ReferralProgramType.fromDb(json['program_type'] as String),
      name: json['name'] as String,
      description: json['description'] as String?,
      referrerRole: json['referrer_role'] as String,
      refereeRole: json['referee_role'] as String?,
      rewardType: json['reward_type'] as String,
      referrerRewardAmount: (json['referrer_reward_amount'] ?? 0).toDouble(),
      refereeRewardAmount: (json['referee_reward_amount'] ?? 0).toDouble(),
      commissionRate: json['commission_rate'] != null
          ? (json['commission_rate'] as num).toDouble()
          : null,
      qualifyingEvent: json['qualifying_event'] as String,
      minReferralsForBonus: json['min_referrals_for_bonus'] as int?,
      bonusRewardAmount: json['bonus_reward_amount'] != null
          ? (json['bonus_reward_amount'] as num).toDouble()
          : null,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [id, programType, name, isActive];
}

class Referral extends Equatable {
  final String id;
  final ReferralProgramType programType;
  final String referrerId;
  final String? referredUserId;
  final String referralCode;
  final ReferralStatus status;
  final String? qualifyingEvent;
  final double referrerRewardAmount;
  final double refereeRewardAmount;
  final DateTime? qualifiedAt;
  final DateTime? rewardedAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final String? referredUserName;
  final String? referredUserEmail;

  const Referral({
    required this.id,
    required this.programType,
    required this.referrerId,
    this.referredUserId,
    required this.referralCode,
    this.status = ReferralStatus.pending,
    this.qualifyingEvent,
    this.referrerRewardAmount = 0,
    this.refereeRewardAmount = 0,
    this.qualifiedAt,
    this.rewardedAt,
    this.expiresAt,
    required this.createdAt,
    this.referredUserName,
    this.referredUserEmail,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] as String,
      programType: ReferralProgramType.fromDb(json['program_type'] as String),
      referrerId: json['referrer_id'] as String,
      referredUserId: json['referred_user_id'] as String?,
      referralCode: json['referral_code'] as String,
      status: ReferralStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ReferralStatus.pending,
      ),
      qualifyingEvent: json['qualifying_event'] as String?,
      referrerRewardAmount: (json['referrer_reward_amount'] ?? 0).toDouble(),
      refereeRewardAmount: (json['referee_reward_amount'] ?? 0).toDouble(),
      qualifiedAt: json['qualified_at'] != null
          ? DateTime.parse(json['qualified_at'] as String)
          : null,
      rewardedAt: json['rewarded_at'] != null
          ? DateTime.parse(json['rewarded_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      referredUserName: json['referred_user_name'] as String?,
      referredUserEmail: json['referred_user_email'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, referrerId, referredUserId, status];
}

class ReferralReward extends Equatable {
  final String id;
  final String? referralId;
  final String userId;
  final String rewardType;
  final double rewardAmount;
  final ReferralRewardStatus status;
  final String? payoutMethod;
  final DateTime? paidAt;
  final String? description;
  final DateTime createdAt;

  const ReferralReward({
    required this.id,
    this.referralId,
    required this.userId,
    required this.rewardType,
    required this.rewardAmount,
    this.status = ReferralRewardStatus.pending,
    this.payoutMethod,
    this.paidAt,
    this.description,
    required this.createdAt,
  });

  factory ReferralReward.fromJson(Map<String, dynamic> json) {
    return ReferralReward(
      id: json['id'] as String,
      referralId: json['referral_id'] as String?,
      userId: json['user_id'] as String,
      rewardType: json['reward_type'] as String,
      rewardAmount: (json['reward_amount'] ?? 0).toDouble(),
      status: ReferralRewardStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ReferralRewardStatus.pending,
      ),
      payoutMethod: json['payout_method'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, userId, rewardAmount, status];
}

class ReferralStats extends Equatable {
  final int totalReferrals;
  final int pendingReferrals;
  final int qualifiedReferrals;
  final int rewardedReferrals;
  final double totalEarnings;
  final double pendingEarnings;
  final int clickCount;

  const ReferralStats({
    this.totalReferrals = 0,
    this.pendingReferrals = 0,
    this.qualifiedReferrals = 0,
    this.rewardedReferrals = 0,
    this.totalEarnings = 0,
    this.pendingEarnings = 0,
    this.clickCount = 0,
  });

  double get conversionRate =>
      totalReferrals > 0 ? (rewardedReferrals / totalReferrals) * 100 : 0;

  @override
  List<Object?> get props => [
        totalReferrals,
        pendingReferrals,
        qualifiedReferrals,
        rewardedReferrals,
        totalEarnings,
        pendingEarnings,
        clickCount,
      ];
}

class ReferralLeaderboardEntry extends Equatable {
  final String userId;
  final String name;
  final String role;
  final int referralCount;
  final int successfulReferrals;
  final double totalEarned;

  const ReferralLeaderboardEntry({
    required this.userId,
    required this.name,
    required this.role,
    required this.referralCount,
    required this.successfulReferrals,
    required this.totalEarned,
  });

  @override
  List<Object?> get props => [userId, referralCount, totalEarned];
}

class ReferralCustomCode extends Equatable {
  final String id;
  final String userId;
  final String customCode;
  final ReferralProgramType programType;
  final double refereeDiscountAmount;
  final double? referrerRewardAmount;
  final bool isActive;
  final int? maxUses;
  final int useCount;
  final DateTime? expiresAt;
  final DateTime createdAt;

  const ReferralCustomCode({
    required this.id,
    required this.userId,
    required this.customCode,
    required this.programType,
    this.refereeDiscountAmount = 0,
    this.referrerRewardAmount,
    this.isActive = true,
    this.maxUses,
    this.useCount = 0,
    this.expiresAt,
    required this.createdAt,
  });

  factory ReferralCustomCode.fromJson(Map<String, dynamic> json) {
    return ReferralCustomCode(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      customCode: json['custom_code'] as String,
      programType: ReferralProgramType.fromDb(json['program_type'] as String),
      refereeDiscountAmount: (json['referee_discount_amount'] ?? 0).toDouble(),
      referrerRewardAmount: json['referrer_reward_amount'] != null
          ? (json['referrer_reward_amount'] as num).toDouble()
          : null,
      isActive: json['is_active'] as bool? ?? true,
      maxUses: json['max_uses'] as int?,
      useCount: json['use_count'] as int? ?? 0,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  @override
  List<Object?> get props => [id, customCode, isActive];
}
