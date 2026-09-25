import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/models/expo_summary.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:intl/intl.dart';

class ExpoAnalyticsDashboardScreen extends StatelessWidget {
  const ExpoAnalyticsDashboardScreen({super.key});
  static const routeName = '/organizer/expo-analytics-dashboard';

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    final expos = ExpoSummary.sampleData();
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Expo Analytics Dashboard'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Revenue & visitor trends across expos', style: TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Revenue trend', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: expos.asMap().entries.map((e) {
                          final max = expos.map((x) => x.revenueRm).reduce((a, b) => a > b ? a : b);
                          final h = max > 0 ? (e.value.revenueRm / max) * 100 : 0.0;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(currency.format(e.value.revenueRm), style: const TextStyle(fontSize: 9), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Container(height: h, decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4))),
                                  const SizedBox(height: 4),
                                  Text('E${e.key + 1}', style: const TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Visitor trend', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: expos.asMap().entries.map((e) {
                          final max = expos.map((x) => x.visitorRegistrations).reduce((a, b) => a > b ? a : b);
                          final h = max > 0 ? (e.value.visitorRegistrations / max) * 100 : 0.0;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${e.value.visitorRegistrations}', style: const TextStyle(fontSize: 10)),
                                  const SizedBox(height: 4),
                                  Container(height: h, decoration: BoxDecoration(color: AppTheme.secondaryColor.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(4))),
                                  const SizedBox(height: 4),
                                  Text('E${e.key + 1}', style: const TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VendorPerformanceAnalyticsScreen extends StatelessWidget {
  const VendorPerformanceAnalyticsScreen({super.key});
  static const routeName = '/organizer/vendor-performance-analytics';

  @override
  Widget build(BuildContext context) {
    final vendors = ExhibitorVendor.sampleData().take(8).toList();
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Vendor Performance Analytics'),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vendors.length,
          itemBuilder: (context, i) {
            final v = vendors[i];
            final leads = 30 - i * 2;
            final roi = (1.2 + i * 0.15);
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(v.companyName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${v.category} · $leads leads captured'),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${roi.toStringAsFixed(1)}x ROI', style: TextStyle(fontWeight: FontWeight.bold, color: roi > 1.5 ? AppTheme.successColor : AppTheme.warningColor)),
                    if (i < 3) const Text('Top vendor', style: TextStyle(fontSize: 10, color: AppTheme.accentColor)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class BoothPerformanceAnalyticsScreen extends StatelessWidget {
  const BoothPerformanceAnalyticsScreen({super.key});
  static const routeName = '/organizer/booth-performance-analytics';

  @override
  Widget build(BuildContext context) {
    const zones = [
      ('Zone VIP', 98000.0, 0.95),
      ('Zone A', 142000.0, 0.88),
      ('Zone B', 98000.0, 0.72),
      ('Zone C', 52000.0, 0.58),
    ];
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    final maxRev = zones.map((z) => z.$2).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Booth Performance Analytics'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Most profitable booth zones', style: TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 16),
            ...zones.map((z) {
              final (name, revenue, occupancy) = z;
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          Text(currency.format(revenue), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: maxRev > 0 ? revenue / maxRev : 0, backgroundColor: AppTheme.borderColor, color: AppTheme.primaryColor, minHeight: 6, borderRadius: BorderRadius.circular(4)),
                      Text('${(occupancy * 100).toStringAsFixed(0)}% occupancy', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class MarketingAnalyticsScreen extends StatelessWidget {
  const MarketingAnalyticsScreen({super.key});
  static const routeName = '/organizer/marketing-analytics';

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    const channels = [
      ('Facebook Ads', 12500, 1840, 6.79),
      ('Instagram', 8200, 1120, 7.32),
      ('Google Ads', 6800, 620, 10.97),
      ('Influencer', 5000, 890, 5.62),
      ('Email', 1200, 340, 3.53),
    ];

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Marketing Analytics'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppTheme.primaryColor,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overall ad ROI', style: TextStyle(color: Colors.white70)),
                    Text('4.2x', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    Text('RM 1 spent → RM 4.20 revenue attributed', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...channels.map((c) {
              final (name, spend, conversions, cpa) = c;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('$conversions registrations · CPA ${currency.format(cpa)}'),
                  trailing: Text(currency.format(spend), style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

