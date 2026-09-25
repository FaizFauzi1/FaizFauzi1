import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/referral/data/referral_provider.dart';
import 'package:eventease/shared/models/referral.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

class ReferralHomeScreen extends StatefulWidget {
  const ReferralHomeScreen({super.key});

  static const routeName = '/referrals';

  @override
  State<ReferralHomeScreen> createState() => _ReferralHomeScreenState();
}

class _ReferralHomeScreenState extends State<ReferralHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (auth.userId != null) {
      await context
          .read<ReferralProvider>()
          .loadUserReferralData(auth.userId!, auth.userRole);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Referral & Loyalty Program',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Home'),
            Tab(text: 'My Code & QR Card'),
            Tab(text: 'Milestones & Rewards'),
            Tab(text: 'Leaderboard'),
            Tab(text: 'History'),
            Tab(text: 'How It Works'),
          ],
        ),
      ),
      body: Consumer<ReferralProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.referralCode == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _HomeTab(provider: provider),
              _MyCodeTab(provider: provider),
              _RewardsTab(provider: provider),
              _LeaderboardTab(),
              _HistoryTab(provider: provider),
              _HowItWorksTab(provider: provider),
            ],
          );
        },
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.provider});

  final ReferralProvider provider;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final stats = provider.stats;
    final program = provider.activeProgram;

    return RefreshIndicator(
      onRefresh: () async {
        if (auth.userId != null) {
          await provider.loadUserReferralData(auth.userId!, auth.userRole);
        }
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    program?.name ?? 'Referral Program',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    program?.description ??
                        provider.programDescriptionForRole(auth.userRole),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                  if (program != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Earn RM${program.referrerRewardAmount.toStringAsFixed(0)} per successful referral',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatCard(
                  label: 'Total Referrals',
                  value: stats.totalReferrals.toString(),
                  icon: Icons.people,
                  color: AppTheme.primaryColor,
                ),
                _StatCard(
                  label: 'Successful',
                  value: stats.rewardedReferrals.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _StatCard(
                  label: 'Total Earned',
                  value: 'RM ${stats.totalEarnings.toStringAsFixed(0)}',
                  icon: Icons.account_balance_wallet,
                  color: Colors.orange,
                ),
                _StatCard(
                  label: 'Link Clicks',
                  value: stats.clickCount.toString(),
                  icon: Icons.touch_app,
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (provider.referralCode != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _shareReferral(context, provider),
                  icon: const Icon(Icons.share),
                  label: const Text('Share Referral Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            if (provider.wallet != null) ...[
              const SizedBox(height: 24),
              Text(
                'Wallet Balance',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.wallet, color: AppTheme.primaryColor),
                  title: Text(
                    'RM ${provider.wallet!.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  subtitle: const Text('EventEase Credits'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _shareReferral(BuildContext context, ReferralProvider provider) {
    final code = provider.primaryShareCode ?? provider.referralCode ?? '';
    final link = provider.primaryShareLink.isNotEmpty
        ? provider.primaryShareLink
        : provider.shareLink;
    SharePlus.instance.share(
      ShareParams(
        text:
            'Join EventEase with my referral code $code and get rewards! $link',
        subject: 'Join EventEase',
      ),
    );
  }
}

class _MyCodeTab extends StatefulWidget {
  const _MyCodeTab({required this.provider});

  final ReferralProvider provider;

  @override
  State<_MyCodeTab> createState() => _MyCodeTabState();
}

class _MyCodeTabState extends State<_MyCodeTab> {
  final _customCodeController = TextEditingController();

  @override
  void dispose() {
    _customCodeController.dispose();
    super.dispose();
  }

  Future<void> _createCustomCode(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (auth.userId == null) return;

    final code = _customCodeController.text.trim();
    if (code.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code must be at least 4 characters')),
      );
      return;
    }

    final programType = ReferralProgramType.forRole(auth.userRole);
    final ok = await widget.provider.createCustomCode(
      userId: auth.userId!,
      code: code,
      programType: programType == ReferralProgramType.weddingOrganizer
          ? ReferralProgramType.influencer
          : programType,
      refereeDiscount: 100,
      referrerReward: 30,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Custom code created!' : 'Failed to create code'),
      ),
    );
    if (ok) _customCodeController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = widget.provider;
    final code = provider.primaryShareCode ?? provider.referralCode ?? 'Loading...';
    final link = provider.primaryShareLink.isNotEmpty
        ? provider.primaryShareLink
        : provider.shareLink;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.card_giftcard, size: 64, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          const Text(
            'Your Referral Code',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (provider.customCodes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Active promo: ${provider.customCodes.first.customCode}',
              style: const TextStyle(color: AppTheme.primaryColor),
            ),
          ],
          const SizedBox(height: 24),
          // Digital Referral Card with QR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1E1B4B).withOpacity(0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.stars, color: Colors.amber, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'EVENT-EASE PASS',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1.5),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'VIP Referral',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.qr_code_2, size: 130, color: Color(0xFF1E1B4B)),
                      const SizedBox(height: 4),
                      Text(
                        code,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 3,
                          color: Color(0xFF1E1B4B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Scan or share code to give RM100 discount & earn reward credits',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Code copied!')),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy Code'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: link));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Link copied!')),
                    );
                  },
                  icon: const Icon(Icons.link),
                  label: const Text('Copy Link'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create Custom Promo Code',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Influencers: create a branded code like AISYAH10',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Custom Code',
                      hintText: 'AISYAH10',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _createCustomCode(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Create Promo Code'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (provider.customCodes.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Your Promo Codes',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ...provider.customCodes.map(
              (c) => Card(
                child: ListTile(
                  title: Text(c.customCode),
                  subtitle: Text(
                    '${c.useCount} uses • RM${c.refereeDiscountAmount.toStringAsFixed(0)} referee discount',
                  ),
                  trailing: Switch(
                    value: c.isActive,
                    onChanged: (val) async {
                      await provider.toggleCustomCode(c.id, val);
                      if (context.mounted) {
                        context.read<ReferralProvider>().loadCustomCodes(
                              context.read<AuthProvider>().userId!,
                            );
                      }
                    },
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Share Link',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    link.isEmpty ? 'Generating link...' : link,
                    style: const TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                SharePlus.instance.share(
                  ShareParams(
                    text: 'Join EventEase! Use code $code — $link',
                    subject: 'EventEase Referral',
                  ),
                );
              },
              icon: const Icon(Icons.share),
              label: const Text('Share with Friends'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardsTab extends StatelessWidget {
  const _RewardsTab({required this.provider});

  final ReferralProvider provider;

  @override
  Widget build(BuildContext context) {
    final rewards = provider.rewards;

    if (rewards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No rewards yet'),
            SizedBox(height: 8),
            Text(
              'Share your code to start earning!',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: rewards.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final reward = rewards[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _rewardColor(reward.status),
              child: Icon(
                reward.status == ReferralRewardStatus.paid
                    ? Icons.check
                    : Icons.schedule,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text('RM ${reward.rewardAmount.toStringAsFixed(2)}'),
            subtitle: Text(reward.description ?? reward.rewardType),
            trailing: Chip(
              label: Text(
                reward.status.name,
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: _rewardColor(reward.status).withValues(alpha: 0.2),
            ),
          ),
        );
      },
    );
  }

  Color _rewardColor(ReferralRewardStatus status) {
    return switch (status) {
      ReferralRewardStatus.paid => Colors.green,
      ReferralRewardStatus.pending => Colors.orange,
      ReferralRewardStatus.cancelled => Colors.red,
    };
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context) {
    final topReferrers = [
      {'rank': 1, 'name': 'Aisyah & Co Weddings', 'referrals': 38, 'earned': 'RM 3,800', 'badge': 'Platinum Ambassador'},
      {'rank': 2, 'name': 'Kuala Lumpur Event Creators', 'referrals': 29, 'earned': 'RM 2,900', 'badge': 'Gold Partner'},
      {'rank': 3, 'name': 'Studio Seputeh Photography', 'referrals': 24, 'earned': 'RM 2,400', 'badge': 'Gold Partner'},
      {'rank': 4, 'name': 'Nurul Huda Event Styling', 'referrals': 18, 'earned': 'RM 1,800', 'badge': 'Silver Member'},
      {'rank': 5, 'name': 'SoundWave Sound & Lights', 'referrals': 15, 'earned': 'RM 1,500', 'badge': 'Silver Member'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                  SizedBox(width: 8),
                  Text(
                    'Monthly Referral Leaderboard',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Text(
                'Top 3 referrers this month win up to RM 1,000 extra bonus marketing credits!',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...topReferrers.map((ref) {
          final rank = ref['rank'] as int;
          Color rankColor = Colors.grey.shade400;
          if (rank == 1) rankColor = Colors.amber;
          if (rank == 2) rankColor = const Color(0xFFC0C0C0);
          if (rank == 3) rankColor = const Color(0xFFCD7F32);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: rankColor.withOpacity(0.2),
                  child: Text(
                    '#$rank',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: rank <= 3 ? Colors.black87 : Colors.grey),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ref['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text(ref['badge'] as String, style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(ref['earned'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green)),
                    Text('${ref['referrals']} invites', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.provider});

  final ReferralProvider provider;

  @override
  Widget build(BuildContext context) {
    final referrals = provider.referrals;

    if (referrals.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No referrals yet'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: referrals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ref = referrals[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Text(ref.programType.dbValue[0].toUpperCase()),
            ),
            title: Text('Code: ${ref.referralCode}'),
            subtitle: Text(
              'Joined ${_formatDate(ref.createdAt)} • ${ref.programType.dbValue}',
            ),
            trailing: _StatusChip(status: ref.status),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _HowItWorksTab extends StatelessWidget {
  const _HowItWorksTab({required this.provider});

  final ReferralProvider provider;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final steps = _stepsForRole(auth.userRole, provider.activeProgram);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text(
          'How It Works',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          provider.programDescriptionForRole(auth.userRole),
          style: const TextStyle(color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 24),
        ...steps.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primaryColor,
                  child: Text(
                    '${entry.key + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    entry.value,
                    style: const TextStyle(fontSize: 15, height: 1.4),
                  ),
                ),
              ],
            ),
          );
        }),
        if (provider.activeProgram?.minReferralsForBonus != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bonus: Refer ${provider.activeProgram!.minReferralsForBonus} friends '
                    '→ Earn RM${provider.activeProgram!.bonusRewardAmount?.toStringAsFixed(0)} extra!',
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  List<String> _stepsForRole(String role, ReferralProgramConfig? program) {
    return switch (role) {
      'vendor' => [
        'Get your unique vendor referral code.',
        'Share it with other vendors (photographers, makeup artists, etc.).',
        'They register and complete their profile on EventEase.',
        'When they get their first booking, you earn RM100 cash + ad credits.',
      ],
      'organizer' => [
        'Share your affiliate link with vendors in your network.',
        'Vendors sign up and subscribe to Premium Vendor Plan.',
        'You earn 10% commission on their subscription.',
        'Commission continues monthly for active subscriptions.',
      ],
      _ => [
        'Get your referral code from the My Code tab.',
        'Share your link with friends planning events.',
        'They sign up using your code.',
        'When they book a vendor, you earn RM${program?.referrerRewardAmount.toStringAsFixed(0) ?? '20'} credits.',
      ],
    };
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ReferralStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ReferralStatus.pending => Colors.orange,
      ReferralStatus.qualified => Colors.blue,
      ReferralStatus.rewarded => Colors.green,
      ReferralStatus.expired => Colors.grey,
      ReferralStatus.rejected => Colors.red,
    };

    return Chip(
      label: Text(status.name, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.15),
      labelStyle: TextStyle(color: color),
      visualDensity: VisualDensity.compact,
    );
  }
}
