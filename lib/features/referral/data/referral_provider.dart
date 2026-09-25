import 'package:flutter/foundation.dart';

import '../../../core/services/supabase_service.dart';
import 'referral_service.dart';
import '../../../shared/models/referral.dart';
import '../../../shared/models/wallet.dart';

class ReferralProvider extends ChangeNotifier {
  static String? pendingReferralCodeStatic;

  String? _pendingReferralCode;
  String? _referralCode;
  ReferralProgramConfig? _activeProgram;
  List<Referral> _referrals = [];
  List<ReferralReward> _rewards = [];
  List<ReferralProgramConfig> _allPrograms = [];
  List<ReferralLeaderboardEntry> _leaderboard = [];
  List<ReferralCustomCode> _customCodes = [];
  ReferralStats _stats = const ReferralStats();
  Wallet? _wallet;
  bool _isLoading = false;
  String? _error;

  String? get pendingReferralCode => _pendingReferralCode;
  String? get referralCode => _referralCode;
  ReferralProgramConfig? get activeProgram => _activeProgram;
  List<Referral> get referrals => List.unmodifiable(_referrals);
  List<ReferralReward> get rewards => List.unmodifiable(_rewards);
  List<ReferralProgramConfig> get allPrograms => List.unmodifiable(_allPrograms);
  List<ReferralLeaderboardEntry> get leaderboard =>
      List.unmodifiable(_leaderboard);
  List<ReferralCustomCode> get customCodes => List.unmodifiable(_customCodes);
  ReferralStats get stats => _stats;
  Wallet? get wallet => _wallet;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get shareLink {
    if (_referralCode == null) return '';
    return 'https://eventease.my/signup?ref=$_referralCode';
  }

  void setPendingReferralCode(String? code) {
    _pendingReferralCode = code?.trim().toUpperCase();
    pendingReferralCodeStatic = _pendingReferralCode;
    ReferralService.setPendingCode(_pendingReferralCode);
    notifyListeners();
  }

  void clearPendingReferralCode() {
    _pendingReferralCode = null;
    pendingReferralCodeStatic = null;
    ReferralService.setPendingCode(null);
    notifyListeners();
  }

  static Future<void> applyPendingReferralOnSignup(String userId) async {
    await ReferralService.applyOnSignup(userId);
    pendingReferralCodeStatic = null;
  }

  Future<void> loadUserReferralData(String userId, String role) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final programType = ReferralProgramType.forRole(role);

      final codeResult = await SupabaseService.client
          .from('users')
          .select('referral_code')
          .eq('id', userId)
          .maybeSingle();

      _referralCode = codeResult?['referral_code'] as String?;

      if (_referralCode == null || _referralCode!.isEmpty) {
        await SupabaseService.client.from('users').update({
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);

        final refreshed = await SupabaseService.client
            .from('users')
            .select('referral_code')
            .eq('id', userId)
            .maybeSingle();
        _referralCode = refreshed?['referral_code'] as String?;
      }

      final programResult = await SupabaseService.client
          .from('referral_program_configs')
          .select()
          .eq('program_type', programType.dbValue)
          .eq('is_active', true)
          .maybeSingle();

      if (programResult != null) {
        _activeProgram = ReferralProgramConfig.fromJson(programResult);
      }

      final referralsResult = await SupabaseService.client
          .from('referrals')
          .select()
          .eq('referrer_id', userId)
          .order('created_at', ascending: false);

      _referrals = (referralsResult as List)
          .map((r) => Referral.fromJson(Map<String, dynamic>.from(r)))
          .toList();

      final rewardsResult = await SupabaseService.client
          .from('referral_rewards')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _rewards = (rewardsResult as List)
          .map((r) => ReferralReward.fromJson(Map<String, dynamic>.from(r)))
          .toList();

      final clicksResult = await SupabaseService.client
          .from('referral_clicks')
          .select('id')
          .eq('referrer_id', userId);

      final clickCount = (clicksResult as List).length;
      final totalEarnings = _rewards
          .where((r) => r.status == ReferralRewardStatus.paid)
          .fold<double>(0, (sum, r) => sum + r.rewardAmount);
      final pendingEarnings = _rewards
          .where((r) => r.status == ReferralRewardStatus.pending)
          .fold<double>(0, (sum, r) => sum + r.rewardAmount);

      _stats = ReferralStats(
        totalReferrals: _referrals.length,
        pendingReferrals:
            _referrals.where((r) => r.status == ReferralStatus.pending).length,
        qualifiedReferrals: _referrals
            .where((r) => r.status == ReferralStatus.qualified)
            .length,
        rewardedReferrals: _referrals
            .where((r) => r.status == ReferralStatus.rewarded)
            .length,
        totalEarnings: totalEarnings,
        pendingEarnings: pendingEarnings,
        clickCount: clickCount,
      );

      final walletResult = await SupabaseService.client
          .from('wallet')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (walletResult != null) {
        _wallet = Wallet.fromJson(Map<String, dynamic>.from(walletResult));
      }

      await loadCustomCodes(userId);
    } catch (e) {
      _error = e.toString();
      debugPrint('ReferralProvider.loadUserReferralData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> applyReferralOnSignup(String userId) async {
    if (_pendingReferralCode == null || _pendingReferralCode!.isEmpty) return;

    try {
      await SupabaseService.client.rpc('apply_referral_on_signup', params: {
        'p_referred_user_id': userId,
        'p_referral_code': _pendingReferralCode,
      });
      clearPendingReferralCode();
    } catch (e) {
      debugPrint('ReferralProvider.applyReferralOnSignup error: $e');
    }
  }

  Future<void> trackReferralClick(String referralCode, String referrerId) async {
    try {
      await SupabaseService.client.from('referral_clicks').insert({
        'referral_code': referralCode.toUpperCase(),
        'referrer_id': referrerId,
      });
    } catch (e) {
      debugPrint('ReferralProvider.trackReferralClick error: $e');
    }
  }

  Future<void> loadAdminData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final programsResult =
          await SupabaseService.client.from('referral_program_configs').select();

      _allPrograms = (programsResult as List)
          .map((p) => ReferralProgramConfig.fromJson(
                Map<String, dynamic>.from(p),
              ))
          .toList();

      final referralsResult = await SupabaseService.client
          .from('referrals')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      _referrals = (referralsResult as List)
          .map((r) => Referral.fromJson(Map<String, dynamic>.from(r)))
          .toList();

      final rewardsResult = await SupabaseService.client
          .from('referral_rewards')
          .select()
          .order('created_at', ascending: false)
          .limit(100);

      _rewards = (rewardsResult as List)
          .map((r) => ReferralReward.fromJson(Map<String, dynamic>.from(r)))
          .toList();

      _stats = ReferralStats(
        totalReferrals: _referrals.length,
        pendingReferrals:
            _referrals.where((r) => r.status == ReferralStatus.pending).length,
        qualifiedReferrals: _referrals
            .where((r) => r.status == ReferralStatus.qualified)
            .length,
        rewardedReferrals: _referrals
            .where((r) => r.status == ReferralStatus.rewarded)
            .length,
        totalEarnings: _rewards
            .where((r) => r.status == ReferralRewardStatus.paid)
            .fold<double>(0, (sum, r) => sum + r.rewardAmount),
        pendingEarnings: _rewards
            .where((r) => r.status == ReferralRewardStatus.pending)
            .fold<double>(0, (sum, r) => sum + r.rewardAmount),
      );

      await _loadLeaderboard();
    } catch (e) {
      _error = e.toString();
      debugPrint('ReferralProvider.loadAdminData error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadLeaderboard() async {
    try {
      final result = await SupabaseService.client.rpc('referral_leaderboard');
      if (result == null) {
        _leaderboard = _buildLeaderboardFromReferrals();
        return;
      }
      _leaderboard = (result as List)
          .map((e) => ReferralLeaderboardEntry(
                userId: e['user_id'] as String,
                name: e['name'] as String? ?? 'User',
                role: e['role'] as String? ?? 'customer',
                referralCount: e['referral_count'] as int? ?? 0,
                successfulReferrals: e['successful_referrals'] as int? ?? 0,
                totalEarned: (e['total_earned'] ?? 0).toDouble(),
              ))
          .toList();
    } catch (_) {
      _leaderboard = _buildLeaderboardFromReferrals();
    }
  }

  List<ReferralLeaderboardEntry> _buildLeaderboardFromReferrals() {
    final counts = <String, int>{};
    final success = <String, int>{};
    for (final r in _referrals) {
      counts[r.referrerId] = (counts[r.referrerId] ?? 0) + 1;
      if (r.status == ReferralStatus.rewarded) {
        success[r.referrerId] = (success[r.referrerId] ?? 0) + 1;
      }
    }
    final earnings = <String, double>{};
    for (final reward in _rewards) {
      if (reward.status == ReferralRewardStatus.paid) {
        earnings[reward.userId] =
            (earnings[reward.userId] ?? 0) + reward.rewardAmount;
      }
    }

    return counts.entries
        .map((e) => ReferralLeaderboardEntry(
              userId: e.key,
              name: 'User ${e.key.substring(0, 8)}',
              role: 'customer',
              referralCount: e.value,
              successfulReferrals: success[e.key] ?? 0,
              totalEarned: earnings[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.successfulReferrals.compareTo(a.successfulReferrals));
  }

  Future<bool> updateProgramConfig(
    String programId,
    Map<String, dynamic> updates,
  ) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      await SupabaseService.client
          .from('referral_program_configs')
          .update(updates)
          .eq('id', programId);
      await loadAdminData();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> payReward(String rewardId) async {
    try {
      await SupabaseService.client.rpc('pay_referral_reward', params: {
        'p_reward_id': rewardId,
      });
      await loadAdminData();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> qualifyReferral(String referredUserId, String event) async {
    await ReferralService.qualifyReferral(referredUserId, event);
    return true;
  }

  Future<void> loadCustomCodes(String userId) async {
    try {
      final result = await SupabaseService.client
          .from('referral_custom_codes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _customCodes = (result as List)
          .map((c) => ReferralCustomCode.fromJson(Map<String, dynamic>.from(c)))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('ReferralProvider.loadCustomCodes error: $e');
    }
  }

  Future<bool> createCustomCode({
    required String userId,
    required String code,
    required ReferralProgramType programType,
    double refereeDiscount = 0,
    double? referrerReward,
    int? maxUses,
  }) async {
    try {
      await SupabaseService.client.from('referral_custom_codes').insert({
        'user_id': userId,
        'custom_code': code.trim().toUpperCase(),
        'program_type': programType.dbValue,
        'referee_discount_amount': refereeDiscount,
        if (referrerReward != null) 'referrer_reward_amount': referrerReward,
        if (maxUses != null) 'max_uses': maxUses,
      });
      await loadCustomCodes(userId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleCustomCode(String codeId, bool isActive) async {
    try {
      await SupabaseService.client
          .from('referral_custom_codes')
          .update({
            'is_active': isActive,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', codeId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  String? get primaryShareCode {
    if (_customCodes.any((c) => c.isActive)) {
      return _customCodes.firstWhere((c) => c.isActive).customCode;
    }
    return _referralCode;
  }

  String get primaryShareLink {
    final code = primaryShareCode;
    if (code == null) return '';
    return 'https://eventease.my/signup?ref=$code';
  }

  List<ReferralReward> get pendingPayouts => _rewards
      .where((r) => r.status == ReferralRewardStatus.pending)
      .toList();

  String programDescriptionForRole(String role) {
    final type = ReferralProgramType.forRole(role);
    final program = _allPrograms.firstWhere(
      (p) => p.programType == type,
      orElse: () => _activeProgram ??
          ReferralProgramConfig(
            id: '',
            programType: type,
            name: 'Referral Program',
            referrerRole: role,
            rewardType: 'credit',
            qualifyingEvent: 'first_booking',
          ),
    );
    return program.description ?? 'Invite friends and earn rewards.';
  }
}
