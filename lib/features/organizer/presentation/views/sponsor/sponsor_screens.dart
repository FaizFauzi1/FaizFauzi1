import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:intl/intl.dart';

class SponsorListScreen extends StatelessWidget {
  const SponsorListScreen({super.key});
  static const routeName = '/organizer/sponsor-list';

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    const sponsors = [
      ('Maybank', 'Platinum', 85000.0, true),
      ('Sunway Group', 'Gold', 45000.0, true),
      ('Astro', 'Gold', 42000.0, true),
      ('Tropicana', 'Silver', 18000.0, false),
    ];

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Sponsor List'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sponsors.length,
          itemBuilder: (context, i) {
            final (name, tier, amount, paid) = sponsors[i];
            final tierColor = switch (tier) {
              'Platinum' => const Color(0xFF64748B),
              'Gold' => const Color(0xFFD97706),
              _ => const Color(0xFF94A3B8),
            };
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: tierColor.withValues(alpha: 0.15), child: Icon(Icons.business, color: tierColor)),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('$tier · ${currency.format(amount)}'),
                trailing: paid
                    ? const Icon(Icons.check_circle, color: AppTheme.successColor)
                    : const Icon(Icons.pending, color: AppTheme.warningColor),
                onTap: () => Navigator.pushNamed(context, SponsorAgreementScreen.routeName),
              ),
            );
          },
        ),
      ),
    );
  }
}

class SponsorPackagesScreen extends StatefulWidget {
  const SponsorPackagesScreen({super.key});
  static const routeName = '/organizer/sponsor-packages';

  @override
  State<SponsorPackagesScreen> createState() => _SponsorPackagesScreenState();
}

class _SponsorPackagesScreenState extends State<SponsorPackagesScreen> {
  final _packages = [
    _Package('Platinum', 85000, ['Main stage backdrop', 'VIP lounge naming', 'App homepage banner', '20 VIP passes'], const Color(0xFF64748B)),
    _Package('Gold', 45000, ['Entrance arch branding', 'Programme insert', 'Social media mention', '10 VIP passes'], const Color(0xFFD97706)),
    _Package('Silver', 18000, ['Booth zone signage', 'Email newsletter', '5 VIP passes'], const Color(0xFF94A3B8)),
  ];

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Sponsor Packages'),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: AppTheme.primaryColor, child: const Icon(Icons.add)),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _packages.length,
          itemBuilder: (context, i) {
            final p = _packages[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: p.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                          child: Text(p.tier, style: TextStyle(color: p.color, fontWeight: FontWeight.bold)),
                        ),
                        const Spacer(),
                        Text(currency.format(p.priceRm), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...p.deliverables.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [
                            Icon(Icons.check, size: 16, color: p.color),
                            const SizedBox(width: 8),
                            Expanded(child: Text(d, style: const TextStyle(fontSize: 13))),
                          ]),
                        )),
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

class _Package {
  final String tier;
  final double priceRm;
  final List<String> deliverables;
  final Color color;
  const _Package(this.tier, this.priceRm, this.deliverables, this.color);
}

class SponsorAgreementScreen extends StatefulWidget {
  const SponsorAgreementScreen({super.key});
  static const routeName = '/organizer/sponsor-agreement';

  @override
  State<SponsorAgreementScreen> createState() => _SponsorAgreementScreenState();
}

class _SponsorAgreementScreenState extends State<SponsorAgreementScreen> {
  bool _signed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Sponsor Agreement'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const ListTile(
              leading: Icon(Icons.business, color: AppTheme.primaryColor),
              title: Text('Maybank', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Platinum sponsor · KL Bridal Fair 2026'),
            ),
            const Divider(),
            const Text('Deliverables', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...['Main stage backdrop logo placement', 'VIP lounge co-branding', 'Digital banner on expo app', '20 complimentary VIP passes']
                .map((d) => ListTile(dense: true, leading: const Icon(Icons.check_circle_outline, size: 20), title: Text(d))),
            const SizedBox(height: 16),
            Card(
              color: AppTheme.backgroundColor,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'This sponsorship agreement grants the sponsor exclusive branding rights as outlined above for the duration of the expo event. Payment terms: 50% upon signing, 50% before event day.',
                  style: TextStyle(height: 1.5, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Agreement signed'),
              value: _signed,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) => setState(() => _signed = v),
            ),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agreement saved'))),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Save agreement'),
            ),
          ],
        ),
      ),
    );
  }
}

class SponsorExposureTrackerScreen extends StatefulWidget {
  const SponsorExposureTrackerScreen({super.key});
  static const routeName = '/organizer/sponsor-exposure-tracker';

  @override
  State<SponsorExposureTrackerScreen> createState() => _SponsorExposureTrackerScreenState();
}

class _SponsorExposureTrackerScreenState extends State<SponsorExposureTrackerScreen> {
  final _placements = [
    _Placement('Maybank', 'Main stage backdrop', true),
    _Placement('Maybank', 'App homepage banner', true),
    _Placement('Sunway Group', 'Entrance arch', true),
    _Placement('Sunway Group', 'Programme insert', false),
    _Placement('Astro', 'Social media post', true),
    _Placement('Tropicana', 'Zone B signage', false),
  ];

  @override
  Widget build(BuildContext context) {
    final done = _placements.where((p) => p.delivered).length;
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Sponsor Exposure Tracker'),
      body: OrganizerScreenBody(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: LinearProgressIndicator(
                value: _placements.isEmpty ? 0 : done / _placements.length,
                backgroundColor: AppTheme.borderColor,
                color: AppTheme.successColor,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('$done of ${_placements.length} deliverables completed',
                  style: const TextStyle(color: AppTheme.textSecondaryColor)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _placements.length,
                itemBuilder: (context, i) {
                  final p = _placements[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      title: Text(p.placement, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(p.sponsor),
                      value: p.delivered,
                      activeColor: AppTheme.successColor,
                      onChanged: (v) => setState(() => _placements[i] = _Placement(p.sponsor, p.placement, v ?? false)),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Placement {
  final String sponsor;
  final String placement;
  final bool delivered;
  const _Placement(this.sponsor, this.placement, this.delivered);
}
