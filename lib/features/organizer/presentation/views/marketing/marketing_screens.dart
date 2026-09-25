import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:intl/intl.dart';

class CampaignDashboardScreen extends StatelessWidget {
  const CampaignDashboardScreen({super.key});
  static const routeName = '/organizer/campaign-dashboard';

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    const campaigns = [
      ('KL Bridal Fair – Facebook', 12500, 84200, 1840, 0.067),
      ('KL Bridal Fair – Instagram', 8200, 52100, 1120, 0.073),
      ('Penang Expo – Google Ads', 6800, 31500, 620, 0.11),
      ('Influencer collab – @bridalmalaysia', 5000, 98000, 890, 0.051),
    ];

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Campaign Dashboard'),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: AppTheme.primaryColor, child: const Icon(Icons.add)),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: campaigns.length,
          itemBuilder: (context, i) {
            final (name, spend, impressions, conversions, cpa) = campaigns[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _CampaignStat('Spend', currency.format(spend)),
                        _CampaignStat('Impressions', '${(impressions / 1000).toStringAsFixed(1)}K'),
                        _CampaignStat('Regs', '$conversions'),
                        _CampaignStat('CPA', currency.format(cpa)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: (conversions / 2000).clamp(0, 1),
                      backgroundColor: AppTheme.borderColor,
                      color: AppTheme.primaryColor,
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(4),
                    ),
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

class _CampaignStat extends StatelessWidget {
  final String label;
  final String value;
  const _CampaignStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class LeadFunnelScreen extends StatelessWidget {
  const LeadFunnelScreen({super.key});
  static const routeName = '/organizer/lead-funnel';

  @override
  Widget build(BuildContext context) {
    const stages = [
      ('Ad impressions', 245000, 1.0),
      ('Landing page visits', 18200, 0.074),
      ('Registrations', 1840, 0.101),
      ('Check-in at expo', 1520, 0.826),
      ('Lead captured', 1280, 0.842),
      ('Converted to booking', 186, 0.145),
    ];

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Lead Funnel'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Registration → check-in → conversion funnel for active expo.',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 20),
            ...stages.asMap().entries.map((entry) {
              final i = entry.key;
              final (label, count, rate) = entry.value;
              final widthFactor = rate.clamp(0.15, 1.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
                        const Spacer(),
                        Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                        if (i > 0) Text('  (${(rate * 100).toStringAsFixed(1)}%)', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    FractionallySizedBox(
                      widthFactor: widthFactor,
                      child: Container(
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2 + (i * 0.12)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(label, style: TextStyle(fontSize: 11, color: AppTheme.primaryColor.withValues(alpha: 0.8 + i * 0.05))),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class PromoCodesScreen extends StatefulWidget {
  const PromoCodesScreen({super.key});
  static const routeName = '/organizer/promo-codes';

  @override
  State<PromoCodesScreen> createState() => _PromoCodesScreenState();
}

class _PromoCodesScreenState extends State<PromoCodesScreen> {
  final _codes = [
    _PromoCode('BRIDAL2026', '20% off tickets', 142, true),
    _PromoCode('VIPBOOTH', 'RM 500 booth discount', 28, true),
    _PromoCode('EARLYBIRD', '15% early bird', 89, false),
    _PromoCode('INSTA15', '15% Instagram promo', 56, true),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Promo Codes'),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: AppTheme.primaryColor, child: const Icon(Icons.add)),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _codes.length,
          itemBuilder: (context, i) {
            final c = _codes[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(Icons.local_offer, color: AppTheme.accentColor),
                title: Text(c.code, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                subtitle: Text('${c.description} · ${c.uses} uses'),
                trailing: Switch(value: c.active, activeColor: AppTheme.primaryColor, onChanged: (v) => setState(() => _codes[i] = _PromoCode(c.code, c.description, c.uses, v))),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PromoCode {
  final String code;
  final String description;
  final int uses;
  final bool active;
  const _PromoCode(this.code, this.description, this.uses, this.active);
}

class InfluencerCampaignScreen extends StatefulWidget {
  const InfluencerCampaignScreen({super.key});
  static const routeName = '/organizer/influencer-campaign';

  @override
  State<InfluencerCampaignScreen> createState() => _InfluencerCampaignScreenState();
}

class _InfluencerCampaignScreenState extends State<InfluencerCampaignScreen> {
  final _campaigns = [
    _Influencer('@bridalmalaysia', 'Instagram Reels', 98000, 890, 'Live'),
    _Influencer('@wedding.my', 'Story takeover', 42000, 320, 'Completed'),
    _Influencer('@sayyes.my', 'TikTok series', 65000, 540, 'Live'),
    _Influencer('@klbride', 'YouTube vlog', 35000, 180, 'Scheduled'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Influencer Campaign'),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: AppTheme.primaryColor, child: const Icon(Icons.add)),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _campaigns.length,
          itemBuilder: (context, i) {
            final c = _campaigns[i];
            final color = switch (c.status) {
              'Live' => AppTheme.successColor,
              'Completed' => AppTheme.primaryColor,
              _ => AppTheme.warningColor,
            };
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15), child: const Icon(Icons.person, color: AppTheme.primaryColor)),
                title: Text(c.handle, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${c.format} · ${(c.reach / 1000).toStringAsFixed(0)}K reach · ${c.registrations} regs'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(c.status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Influencer {
  final String handle;
  final String format;
  final int reach;
  final int registrations;
  final String status;
  const _Influencer(this.handle, this.format, this.reach, this.registrations, this.status);
}
