import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';
import 'package:eventease/features/admin/data/providers/admin_churn_provider.dart';
import 'package:eventease/shared/widgets/design_system/premium_widgets.dart';

/// At-risk vendor detection and retention outreach.
class AdminChurnDashboardScreen extends StatefulWidget {
  const AdminChurnDashboardScreen({super.key});

  @override
  State<AdminChurnDashboardScreen> createState() => _AdminChurnDashboardScreenState();
}

class _AdminChurnDashboardScreenState extends State<AdminChurnDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminChurnProvider>().fetchAtRiskVendors();
    });
  }

  @override
  Widget build(BuildContext context) {
    final churn = context.watch<AdminChurnProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Churn & Retention'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: churn.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
              children: [
                Row(
                  children: [
                    Expanded(child: _summaryCard('Critical', churn.criticalCount, AppTheme.errorColor)),
                    const SizedBox(width: 12),
                    Expanded(child: _summaryCard('High Risk', churn.highCount, Colors.orange)),
                  ],
                ),
                const SizedBox(height: 24),
                Text('At-Risk Vendors', style: EEDesignTokens.headlineMedium),
                const SizedBox(height: 12),
                ...churn.atRiskVendors.map((v) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text('Vendor ${v.vendorId.substring(0, 8)}…'),
                        subtitle: Text(
                          '${v.daysInactive}d inactive · ${v.profileViews} views · ${v.inquiries} inquiries',
                        ),
                        trailing: PillBadge(
                          label: v.riskLevel,
                          color: v.riskLevel == 'critical' ? AppTheme.errorColor : Colors.orange,
                        ),
                        onTap: () => _showRetentionActions(v.id),
                      ),
                    )),
              ],
            ),
    );
  }

  Widget _summaryCard(String label, int count, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: EEDesignTokens.bodyMedium),
          ],
        ),
      ),
    );
  }

  void _showRetentionActions(String snapshotId) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Profile Boost'),
              onTap: () {
                context.read<AdminChurnProvider>().applyRetentionAction(snapshotId, 'profile_boost');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Send Outreach Email'),
              onTap: () {
                context.read<AdminChurnProvider>().applyRetentionAction(snapshotId, 'outreach_email');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.local_offer),
              title: const Text('Offer Free Month'),
              onTap: () {
                context.read<AdminChurnProvider>().applyRetentionAction(snapshotId, 'free_month');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
