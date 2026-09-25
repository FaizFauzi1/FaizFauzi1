import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_data_mode_banner.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';

class ExpoSettingsScreen extends StatefulWidget {
  const ExpoSettingsScreen({super.key});
  static const routeName = '/organizer/expo-settings';

  @override
  State<ExpoSettingsScreen> createState() => _ExpoSettingsScreenState();
}

class _ExpoSettingsScreenState extends State<ExpoSettingsScreen> {
  final _earlyBirdDiscount = TextEditingController(text: '15');
  final _maxBoothsPerVendor = TextEditingController(text: '1');
  bool _requireApproval = true;
  bool _allowWaitlist = true;

  @override
  void dispose() {
    _earlyBirdDiscount.dispose();
    _maxBoothsPerVendor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Expo Settings'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Pricing & booth rules for expos', style: TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 16),
            TextField(controller: _earlyBirdDiscount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Early bird discount (%)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _maxBoothsPerVendor, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Max booths per vendor', border: OutlineInputBorder())),
            const SizedBox(height: 8),
            SwitchListTile(title: const Text('Require vendor approval'), value: _requireApproval, activeColor: AppTheme.primaryColor, onChanged: (v) => setState(() => _requireApproval = v)),
            SwitchListTile(title: const Text('Enable booth waitlist'), value: _allowWaitlist, activeColor: AppTheme.primaryColor, onChanged: (v) => setState(() => _allowWaitlist = v)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Expo settings saved'))),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Save settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});
  static const routeName = '/organizer/company-settings';

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  String _timezone = 'Asia/Kuala_Lumpur';
  String _currency = 'MYR';
  String _language = 'English';
  bool _twoFactor = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Company Settings'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const OrganizerDataSourceSettingsCard(),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _timezone,
              decoration: const InputDecoration(labelText: 'Timezone', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Asia/Kuala_Lumpur', child: Text('Asia/Kuala_Lumpur (GMT+8)')),
                DropdownMenuItem(value: 'Asia/Singapore', child: Text('Asia/Singapore (GMT+8)')),
              ],
              onChanged: (v) => setState(() => _timezone = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _currency,
              decoration: const InputDecoration(labelText: 'Default currency', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'MYR', child: Text('MYR – Malaysian Ringgit')),
                DropdownMenuItem(value: 'SGD', child: Text('SGD – Singapore Dollar')),
              ],
              onChanged: (v) => setState(() => _currency = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _language,
              decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'English', child: Text('English')),
                DropdownMenuItem(value: 'Bahasa Malaysia', child: Text('Bahasa Malaysia')),
              ],
              onChanged: (v) => setState(() => _language = v!),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Two-factor authentication'),
              subtitle: const Text('Require 2FA for organizer admin accounts'),
              value: _twoFactor,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) => setState(() => _twoFactor = v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company settings saved'))),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Save preferences'),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionPlanScreen extends StatelessWidget {
  const SubscriptionPlanScreen({super.key});
  static const routeName = '/organizer/subscription-plan';

  @override
  Widget build(BuildContext context) {
    const plans = [
      ('Starter', 299.0, ['1 active expo', 'Up to 50 booths', 'Basic analytics'], false),
      ('Professional', 799.0, ['3 active expos', 'Unlimited booths', 'Lead management', 'Marketing tools'], true),
      ('Enterprise', 1999.0, ['Unlimited expos', 'White-label branding', 'API access', 'Dedicated support'], false),
    ];

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Subscription Plan'),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: plans.length,
          itemBuilder: (context, i) {
            final (name, price, features, current) = plans[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: current ? const BorderSide(color: AppTheme.primaryColor, width: 2) : BorderSide.none,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        if (current) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Current', style: TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ],
                    ),
                    Text('RM ${price.toStringAsFixed(0)}/month', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    const SizedBox(height: 12),
                    ...features.map((f) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(children: [const Icon(Icons.check, size: 16, color: AppTheme.successColor), const SizedBox(width: 8), Text(f)]),
                        )),
                    if (!current) ...[
                      const SizedBox(height: 12),
                      OutlinedButton(onPressed: () {}, child: Text('Switch to $name')),
                    ],
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

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  static const routeName = '/organizer/notification-settings';

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final _prefs = {
    'New vendor application': {'push': true, 'email': true},
    'Payment received': {'push': true, 'email': true},
    'Booth booking request': {'push': true, 'email': false},
    'Staff incident report': {'push': true, 'email': true},
    'Daily expo summary': {'push': false, 'email': true},
    'Marketing campaign alerts': {'push': false, 'email': false},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Notification Settings'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Choose how you receive alerts', style: TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 12),
            ..._prefs.entries.map((entry) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Row(
                        children: [
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Push', style: TextStyle(fontSize: 13)),
                              value: entry.value['push']!,
                              activeColor: AppTheme.primaryColor,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => _prefs[entry.key]!['push'] = v),
                            ),
                          ),
                          Expanded(
                            child: SwitchListTile(
                              title: const Text('Email', style: TextStyle(fontSize: 13)),
                              value: entry.value['email']!,
                              activeColor: AppTheme.primaryColor,
                              contentPadding: EdgeInsets.zero,
                              onChanged: (v) => setState(() => _prefs[entry.key]!['email'] = v),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification preferences saved'))),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Save preferences'),
            ),
          ],
        ),
      ),
    );
  }
}
