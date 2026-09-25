import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/models/expo_lead.dart';
import 'package:eventease/features/organizer/data/models/expo_summary.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:intl/intl.dart';

class ExpoReportScreen extends StatelessWidget {
  const ExpoReportScreen({super.key});
  static const routeName = '/organizer/expo-report';

  @override
  Widget build(BuildContext context) {
    final expo = ExpoSummary.sampleData().first;
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Expo Report'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(expo.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('${expo.venue} · ${DateFormat('d MMM yyyy').format(expo.startAt)}', style: const TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _ReportStat('Visitors', '${expo.visitorRegistrations}', Icons.people)),
                Expanded(child: _ReportStat('Leads', '${ExpoLead.sampleData().length}', Icons.contact_page)),
                Expanded(child: _ReportStat('Revenue', currency.format(expo.revenueRm), Icons.payments)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Highlights', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ...[
              'Booth occupancy reached ${(expo.boothSalesProgress * 100).toStringAsFixed(0)}%',
              '${expo.ticketsSold} tickets sold across all tiers',
              '${expo.vendorCount} exhibitors participated',
              'Average visitor dwell time: 2h 14m',
            ].map((h) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(dense: true, leading: const Icon(Icons.check_circle, color: AppTheme.successColor, size: 20), title: Text(h)),
                )),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report exported as PDF'))),
              icon: const Icon(Icons.download),
              label: const Text('Export report'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _ReportStat(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.primaryColor, size: 22),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }
}

class VendorRoiReportScreen extends StatelessWidget {
  const VendorRoiReportScreen({super.key});
  static const routeName = '/organizer/vendor-roi-report';

  @override
  Widget build(BuildContext context) {
    final vendors = ExhibitorVendor.sampleData().take(6).toList();
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Vendor ROI Report'),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vendors.length,
          itemBuilder: (context, i) {
            final v = vendors[i];
            final leads = 20 + i * 8;
            final converted = 2 + i;
            final rate = leads > 0 ? converted / leads : 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(v.companyName, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Booth ${v.boothNumber ?? '—'} · $leads leads · $converted conversions'),
                trailing: Text('${(rate * 100).toStringAsFixed(0)}%', style: TextStyle(fontWeight: FontWeight.bold, color: rate > 0.1 ? AppTheme.successColor : AppTheme.warningColor)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class VendorFeedbackScreen extends StatefulWidget {
  const VendorFeedbackScreen({super.key});
  static const routeName = '/organizer/vendor-feedback';

  @override
  State<VendorFeedbackScreen> createState() => _VendorFeedbackScreenState();
}

class _VendorFeedbackScreenState extends State<VendorFeedbackScreen> {
  final _feedback = [
    _Feedback('Elegant Dining Solutions', 4.8, 'Great foot traffic at our booth. Lead quality was excellent.'),
    _Feedback('Capture Moments', 4.5, 'Well organised event. Would appreciate more VIP visitor introductions.'),
    _Feedback('Royal Feast Caterers', 4.2, 'Good expo overall. Booth location in Zone B was slightly quiet.'),
    _Feedback('Gourmet Delights', 3.9, 'Payment process was slow. Event day support was helpful though.'),
  ];

  @override
  Widget build(BuildContext context) {
    final avg = _feedback.fold<double>(0, (s, f) => s + f.rating) / _feedback.length;
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Vendor Feedback'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: AppTheme.primaryColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(avg.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 20),
                        Text('Average satisfaction', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._feedback.map((f) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(f.vendor, style: const TextStyle(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            ...List.generate(5, (i) => Icon(Icons.star, size: 14, color: i < f.rating.round() ? Colors.amber : AppTheme.borderColor)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(f.comment, style: const TextStyle(color: AppTheme.textSecondaryColor, height: 1.4)),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _Feedback {
  final String vendor;
  final double rating;
  final String comment;
  const _Feedback(this.vendor, this.rating, this.comment);
}

class LeadConversionReportScreen extends StatelessWidget {
  const LeadConversionReportScreen({super.key});
  static const routeName = '/organizer/lead-conversion-report';

  @override
  Widget build(BuildContext context) {
    final leads = ExpoLead.sampleData();
    final converted = leads.where((l) => l.stage == LeadStage.converted).length;
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Lead Conversion Report'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: _ConvStat('Total leads', '${leads.length}')),
                Expanded(child: _ConvStat('Converted', '$converted')),
                Expanded(child: _ConvStat('Rate', '${leads.isEmpty ? 0 : (converted / leads.length * 100).toStringAsFixed(0)}%')),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Post-expo wedding bookings attributed to expo leads', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...leads.where((l) => l.stage == LeadStage.converted).map((l) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(l.visitorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Booked via ${l.assignedVendorName ?? 'vendor'} · ${l.budgetRange}'),
                    trailing: Text(currency.format(45000 + leads.indexOf(l) * 5000), style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.successColor)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _ConvStat extends StatelessWidget {
  final String label;
  final String value;
  const _ConvStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }
}

class ExpoPerformanceComparisonScreen extends StatelessWidget {
  const ExpoPerformanceComparisonScreen({super.key});
  static const routeName = '/organizer/expo-performance-comparison';

  @override
  Widget build(BuildContext context) {
    final expos = ExpoSummary.sampleData();
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    final maxRevenue = expos.map((e) => e.revenueRm).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Expo Performance Comparison'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Compare key metrics across your expos.', style: TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 16),
            ...expos.map((e) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _CompareBar('Revenue', e.revenueRm, maxRevenue, currency.format(e.revenueRm)),
                      _CompareBar('Visitors', e.visitorRegistrations.toDouble(), 2000, '${e.visitorRegistrations}'),
                      _CompareBar('Booth fill', e.boothSalesProgress, 1, '${(e.boothSalesProgress * 100).toStringAsFixed(0)}%'),
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

class _CompareBar extends StatelessWidget {
  final String label;
  final double value;
  final double max;
  final String display;
  const _CompareBar(this.label, this.value, this.max, this.display);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Text(label, style: const TextStyle(fontSize: 12)), const Spacer(), Text(display, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))]),
          LinearProgressIndicator(value: max > 0 ? (value / max).clamp(0, 1) : 0, backgroundColor: AppTheme.borderColor, color: AppTheme.primaryColor, minHeight: 5, borderRadius: BorderRadius.circular(4)),
        ],
      ),
    );
  }
}
