import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/referral/data/referral_provider.dart';
import 'package:eventease/shared/models/referral.dart';

class VendorReferralProgramsScreen extends StatefulWidget {
  const VendorReferralProgramsScreen({super.key});

  @override
  State<VendorReferralProgramsScreen> createState() => _VendorReferralProgramsScreenState();
}

class _VendorReferralProgramsScreenState extends State<VendorReferralProgramsScreen> {
  String _selectedTab = 'Overview';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final effectiveId = AdminImpersonationService.instance.effectiveUserId ?? auth.userId;
    if (effectiveId != null) {
      final referralProvider = Provider.of<ReferralProvider>(context, listen: false);
      await referralProvider.loadUserReferralData(effectiveId, 'vendor');
      await referralProvider.loadLeaderboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ReferralProvider>(
      builder: (context, referralProvider, child) {
        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text(
              'Referral Programs',
              style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share, color: AppTheme.primaryColor),
                onPressed: () => _shareReferralLink(referralProvider),
              ),
            ],
          ),
          body: referralProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildTabSelector(),
                    Expanded(
                      child: _selectedTab == 'Overview'
                          ? _buildOverviewView(referralProvider)
                          : _selectedTab == 'Referrals'
                              ? _buildReferralsView(referralProvider)
                              : _buildTopReferrersView(referralProvider),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Overview', _selectedTab == 'Overview'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Referrals', _selectedTab == 'Referrals'),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Top Referrers', _selectedTab == 'Top Referrers'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return ElevatedButton(
      onPressed: () => setState(() => _selectedTab = title),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
      ),
      child: Text(title),
    );
  }

  Widget _buildOverviewView(ReferralProvider provider) {
    final activeProgram = provider.activeProgram;
    final stats = provider.stats;
    final code = provider.referralCode ?? '';
    final link = provider.shareLink;

    final programName = activeProgram?.name ?? 'Vendor Referral Program';
    final programDesc = activeProgram?.description ?? 'Refer customers or other vendors and earn rewards for confirmed bookings.';
    final referrerReward = activeProgram != null
        ? (activeProgram.rewardType == 'percentage'
            ? '${activeProgram.commissionRate ?? 5.0}% commission'
            : 'RM ${activeProgram.referrerRewardAmount.toStringAsFixed(0)} bonus')
        : 'Standard Commission Discount';
    final refereeReward = activeProgram != null && activeProgram.refereeRewardAmount > 0
        ? 'RM ${activeProgram.refereeRewardAmount.toStringAsFixed(0)} discount'
        : 'Service discount on first booking';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Program status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        programName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  programDesc,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Key metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Referrals',
                  stats.totalReferrals.toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Success Rate',
                  '${stats.conversionRate.toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Rewards Earned',
                  'RM ${stats.totalEarnings.toStringAsFixed(0)}',
                  Icons.card_giftcard,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Program rules
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Program Rules',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRuleItem('Referrer Reward', referrerReward),
                _buildRuleItem('Referee Reward', refereeReward),
                _buildRuleItem('Qualifying Event', activeProgram?.qualifyingEvent ?? 'Completed first booking'),
                _buildRuleItem('Status', activeProgram?.isActive == true ? 'Active' : 'Standby'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Referral link
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your Referral Link',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          link.isNotEmpty ? link : (code.isNotEmpty ? 'Referral Code: $code' : 'Loading code...'),
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            color: AppTheme.textPrimaryColor,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, color: AppTheme.primaryColor, size: 20),
                        onPressed: () => _copyReferralLink(link.isNotEmpty ? link : code),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copyReferralLink(link.isNotEmpty ? link : code),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Link'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _shareReferralLink(provider),
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String rule, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            rule,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralsView(ReferralProvider provider) {
    final referrals = provider.referrals;

    if (referrals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No Referrals Yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share your referral link with customers\nto earn rewards when they join and book.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: referrals.length,
      itemBuilder: (context, index) => _buildReferralCard(referrals[index]),
    );
  }

  Widget _buildReferralCard(Referral referral) {
    final statusStr = referral.status.name.toUpperCase();
    final statusColor = _getStatusColor(referral.status);
    final dateStr = DateFormat('yyyy-MM-dd').format(referral.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, color: AppTheme.primaryColor, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      referral.referredUserName ?? referral.referredUserEmail ?? 'Referred User',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusStr,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Code: ${referral.referralCode}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Joined: $dateStr',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (referral.referrerRewardAmount > 0) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'RM ${referral.referrerRewardAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
                const Text(
                  'reward',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTopReferrersView(ReferralProvider provider) {
    final leaderboard = provider.leaderboard;

    if (leaderboard.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'No Leaderboard Data Yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 8),
            const Text(
              'Top referrers will be listed here\nas referral milestones are achieved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) => _buildTopReferrerCard(leaderboard[index], index + 1),
    );
  }

  Widget _buildTopReferrerCard(ReferralLeaderboardEntry referrer, int rank) {
    final initials = referrer.name.trim().isNotEmpty
        ? (referrer.name.trim().split(' ').length > 1
            ? '${referrer.name.trim().split(' ')[0][0]}${referrer.name.trim().split(' ')[1][0]}'
            : referrer.name.trim()[0])
        : 'U';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _getRankColor(rank).withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                rank.toString(),
                style: TextStyle(
                  color: _getRankColor(rank),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                initials.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referrer.name,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${referrer.successfulReferrals}/${referrer.referralCount} successful referrals',
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${referrer.totalEarned.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
              const Text(
                'earned',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(ReferralStatus status) {
    switch (status) {
      case ReferralStatus.rewarded:
      case ReferralStatus.qualified:
        return Colors.green;
      case ReferralStatus.pending:
        return Colors.orange;
      case ReferralStatus.expired:
      case ReferralStatus.rejected:
        return Colors.red;
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700);
      case 2:
        return const Color(0xFFC0C0C0);
      case 3:
        return const Color(0xFFCD7F32);
      default:
        return AppTheme.primaryColor;
    }
  }

  void _shareReferralLink(ReferralProvider provider) {
    final link = provider.shareLink;
    final code = provider.referralCode ?? '';
    final text = 'Join EventEase with my referral code $code: $link';
    SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Join EventEase',
      ),
    );
  }

  void _copyReferralLink(String text) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral link copied to clipboard')),
    );
  }
}
