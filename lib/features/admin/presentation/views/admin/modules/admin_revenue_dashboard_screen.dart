import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/currency_formatter.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';
import 'package:eventease/features/admin/data/providers/admin_revenue_provider.dart';

/// Phase 9 revenue dashboard with country breakdown.
class AdminRevenueDashboardScreen extends StatefulWidget {
  const AdminRevenueDashboardScreen({super.key});

  @override
  State<AdminRevenueDashboardScreen> createState() => _AdminRevenueDashboardScreenState();
}

class _AdminRevenueDashboardScreenState extends State<AdminRevenueDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminRevenueProvider>().fetchAll();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final revenue = context.watch<AdminRevenueProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Sponsored'),
            Tab(text: 'Promotions'),
          ],
        ),
      ),
      body: revenue.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabs,
              children: [
                _overviewTab(revenue),
                _sponsoredTab(revenue),
                _promotionsTab(revenue),
              ],
            ),
    );
  }

  Widget _overviewTab(AdminRevenueProvider revenue) {
    return ListView(
      padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _metricCard('Total Revenue', CurrencyFormatter.format(revenue.totalRevenue)),
            _metricCard('Commission', CurrencyFormatter.format(revenue.totalCommission)),
            _metricCard('Subscriptions', CurrencyFormatter.format(revenue.subscriptionRevenue)),
            _metricCard('Refunds', CurrencyFormatter.format(revenue.refundTotal)),
            _metricCard('Payouts', CurrencyFormatter.format(revenue.payoutTotal)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Revenue by Country', style: EEDesignTokens.headlineMedium),
        const SizedBox(height: 12),
        ...revenue.countryRevenue.map((c) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(c.countryCode),
                subtitle: Text('${c.transactionCount} transactions'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(CurrencyFormatter.format(c.totalRevenue),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Comm: ${CurrencyFormatter.format(c.commissionRevenue)}',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _metricCard(String label, String value) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
              const SizedBox(height: 4),
              Text(value, style: EEDesignTokens.titleLarge.copyWith(color: AppTheme.primaryColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sponsoredTab(AdminRevenueProvider revenue) {
    if (revenue.campaigns.isEmpty) {
      return const Center(child: Text('No sponsored campaigns yet'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: revenue.campaigns.length,
      itemBuilder: (context, i) {
        final c = revenue.campaigns[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text('Vendor ${c.vendorId.substring(0, 8)}… · ${c.placement}'),
            subtitle: Text('${c.impressions} impressions · ${c.clicks} clicks · CTR ${c.ctr.toStringAsFixed(1)}%'),
            trailing: Text(c.billingStatus),
          ),
        );
      },
    );
  }

  Widget _promotionsTab(AdminRevenueProvider revenue) {
    if (revenue.promotions.isEmpty) {
      return const Center(child: Text('No promotions configured'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: revenue.promotions.length,
      itemBuilder: (context, i) {
        final p = revenue.promotions[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(p.name),
            subtitle: Text('${p.promoType} · ${p.targetAudience} · ${p.usageCount} uses'),
            trailing: Text(p.isActive ? 'Active' : 'Inactive'),
          ),
        );
      },
    );
  }
}
