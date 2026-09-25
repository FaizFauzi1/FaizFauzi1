import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/referral/data/referral_provider.dart';
import 'package:eventease/shared/models/referral.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReferralManagementScreen extends StatefulWidget {
  const ReferralManagementScreen({super.key});

  @override
  State<ReferralManagementScreen> createState() =>
      _ReferralManagementScreenState();
}

class _ReferralManagementScreenState extends State<ReferralManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferralProvider>().loadAdminData();
    });
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
          'Referral Management',
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
            Tab(text: 'Dashboard'),
            Tab(text: 'Programs'),
            Tab(text: 'Payouts'),
            Tab(text: 'Analytics'),
            Tab(text: 'Leaderboard'),
          ],
        ),
      ),
      body: Consumer<ReferralProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.allPrograms.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _DashboardTab(provider: provider),
              _ProgramsTab(provider: provider),
              _PayoutsTab(provider: provider),
              _AnalyticsTab(provider: provider),
              _LeaderboardTab(provider: provider),
            ],
          );
        },
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({required this.provider});

  final ReferralProvider provider;

  @override
  Widget build(BuildContext context) {
    final stats = provider.stats;

    return RefreshIndicator(
      onRefresh: provider.loadAdminData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Referral Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 800 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
              children: [
                _AdminStatCard(
                  'Total Referrals',
                  stats.totalReferrals.toString(),
                  Icons.people,
                  AppTheme.primaryColor,
                ),
                _AdminStatCard(
                  'Pending',
                  stats.pendingReferrals.toString(),
                  Icons.hourglass_empty,
                  Colors.orange,
                ),
                _AdminStatCard(
                  'Rewarded',
                  stats.rewardedReferrals.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
                _AdminStatCard(
                  'Pending Payouts',
                  'RM ${stats.pendingEarnings.toStringAsFixed(0)}',
                  Icons.payment,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Referrals',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...provider.referrals.take(10).map((ref) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text('${ref.programType.dbValue} • ${ref.referralCode}'),
                    subtitle: Text('Status: ${ref.status.name}'),
                    trailing: Text(
                      _formatDate(ref.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}

class _ProgramsTab extends StatelessWidget {
  const _ProgramsTab({required this.provider});

  final ReferralProvider provider;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.allPrograms.length,
      itemBuilder: (context, index) {
        final program = provider.allPrograms[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: Icon(
              _programIcon(program.programType),
              color: AppTheme.primaryColor,
            ),
            title: Text(program.name),
            subtitle: Text(
              program.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: program.isActive ? Colors.green : Colors.red,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (program.description != null)
                      Text(program.description!),
                    const SizedBox(height: 12),
                    _DetailRow('Referrer Role', program.referrerRole),
                    _DetailRow('Referee Role', program.refereeRole ?? 'Any'),
                    _DetailRow('Reward Type', program.rewardType),
                    _DetailRow(
                      'Referrer Reward',
                      'RM ${program.referrerRewardAmount.toStringAsFixed(2)}',
                    ),
                    _DetailRow(
                      'Referee Reward',
                      'RM ${program.refereeRewardAmount.toStringAsFixed(2)}',
                    ),
                    if (program.commissionRate != null)
                      _DetailRow(
                        'Commission',
                        '${program.commissionRate!.toStringAsFixed(1)}%',
                      ),
                    _DetailRow('Qualifying Event', program.qualifyingEvent),
                    if (program.minReferralsForBonus != null)
                      _DetailRow(
                        'Bonus Threshold',
                        '${program.minReferralsForBonus} referrals → RM${program.bonusRewardAmount?.toStringAsFixed(0)}',
                      ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Program Active'),
                      value: program.isActive,
                      onChanged: (val) {
                        provider.updateProgramConfig(program.id, {
                          'is_active': val,
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _programIcon(ReferralProgramType type) {
    return switch (type) {
      ReferralProgramType.vendor => Icons.store,
      ReferralProgramType.weddingOrganizer => Icons.favorite,
      ReferralProgramType.influencer => Icons.campaign,
      ReferralProgramType.customer => Icons.person,
      ReferralProgramType.eventCrew => Icons.groups,
      ReferralProgramType.marketplace => Icons.storefront,
    };
  }
}

class _PayoutsTab extends StatelessWidget {
  const _PayoutsTab({required this.provider});

  final ReferralProvider provider;

  @override
  Widget build(BuildContext context) {
    final pending = provider.pendingPayouts;

    if (pending.isEmpty) {
      return const Center(child: Text('No pending payouts'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final reward = pending[index];
        return Card(
          child: ListTile(
            title: Text('RM ${reward.rewardAmount.toStringAsFixed(2)}'),
            subtitle: Text(reward.description ?? reward.rewardType),
            trailing: ElevatedButton(
              onPressed: () async {
                final ok = await provider.payReward(reward.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'Payout processed' : 'Payout failed',
                      ),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Pay'),
            ),
          ),
        );
      },
    );
  }
}

class _AnalyticsTab extends StatelessWidget {
  const _AnalyticsTab({required this.provider});

  final ReferralProvider provider;

  @override
  Widget build(BuildContext context) {
    final stats = provider.stats;
    final byProgram = <ReferralProgramType, int>{};
    for (final ref in provider.referrals) {
      byProgram[ref.programType] = (byProgram[ref.programType] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Referral Analytics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _DetailRow(
            'Conversion Rate',
            '${stats.conversionRate.toStringAsFixed(1)}%',
          ),
          _DetailRow(
            'Total Paid Out',
            'RM ${stats.totalEarnings.toStringAsFixed(2)}',
          ),
          _DetailRow(
            'Pending Payouts',
            'RM ${stats.pendingEarnings.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 24),
          const Text(
            'By Program Type',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...byProgram.entries.map(
            (e) => Card(
              child: ListTile(
                title: Text(e.key.dbValue),
                trailing: Text('${e.value} referrals'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Organizer Commissions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.repeat, color: AppTheme.primaryColor),
              title: Text('Recurring subscription commission'),
              subtitle: Text(
                '10% paid to organizers when referred vendors renew premium plans',
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Fraud Detection',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Card(
            child: ListTile(
              leading: Icon(Icons.shield, color: Colors.orange),
              title: Text('Self-referral checks enabled'),
              subtitle: Text(
                'Referrals where referrer = referee are automatically blocked',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab({required this.provider});

  final ReferralProvider provider;

  @override
  Widget build(BuildContext context) {
    final entries = provider.leaderboard;

    if (entries.isEmpty) {
      return const Center(child: Text('No leaderboard data yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: index < 3
                  ? [Colors.amber, Colors.grey, Colors.brown][index]
                  : AppTheme.primaryColor.withValues(alpha: 0.2),
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: index < 3 ? Colors.white : AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(entry.name),
            subtitle: Text(
              '${entry.referralCount} referrals • ${entry.successfulReferrals} successful',
            ),
            trailing: Text(
              'RM ${entry.totalEarned.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard(this.label, this.value, this.icon, this.color);

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
