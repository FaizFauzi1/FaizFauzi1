import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';

class BoothAllocationAutoScreen extends StatefulWidget {
  const BoothAllocationAutoScreen({super.key});
  static const routeName = '/organizer/booth-allocation-auto';

  @override
  State<BoothAllocationAutoScreen> createState() => _BoothAllocationAutoScreenState();
}

class _BoothAllocationAutoScreenState extends State<BoothAllocationAutoScreen> {
  bool _enabled = true;
  String _strategy = 'Category clustering';
  final _rules = [
    _Rule('Premium vendors → Zone VIP', true),
    _Rule('Same category adjacent booths', true),
    _Rule('First-paid-first-choice priority', true),
    _Rule('Avoid competitor adjacency', false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Booth Allocation Auto'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Enable auto-allocation', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Automatically assign booths when vendor payment is confirmed'),
              value: _enabled,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _strategy,
              decoration: const InputDecoration(labelText: 'Allocation strategy', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Category clustering', child: Text('Category clustering')),
                DropdownMenuItem(value: 'Revenue priority', child: Text('Revenue priority')),
                DropdownMenuItem(value: 'First come first served', child: Text('First come first served')),
              ],
              onChanged: (v) => setState(() => _strategy = v!),
            ),
            const SizedBox(height: 20),
            const Text('Rules', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._rules.asMap().entries.map((e) => SwitchListTile(
                  title: Text(e.value.label),
                  value: e.value.enabled,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (v) => setState(() => _rules[e.key] = _Rule(e.value.label, v)),
                )),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Auto-allocation rules saved'))),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Save rules'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rule {
  final String label;
  final bool enabled;
  const _Rule(this.label, this.enabled);
}

class LeadAutoDistributionScreen extends StatefulWidget {
  const LeadAutoDistributionScreen({super.key});
  static const routeName = '/organizer/lead-auto-distribution';

  @override
  State<LeadAutoDistributionScreen> createState() => _LeadAutoDistributionScreenState();
}

class _LeadAutoDistributionScreenState extends State<LeadAutoDistributionScreen> {
  bool _enabled = true;
  String _method = 'Interest matching';
  final _settings = {
    'Round-robin among category vendors': false,
    'Match visitor interest to vendor category': true,
    'Prioritise paid premium vendors': true,
    'Cap leads per vendor at 50/day': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Lead Auto Distribution'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SwitchListTile(
              title: const Text('Enable auto-distribution', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Assign captured leads to vendors automatically'),
              value: _enabled,
              activeColor: AppTheme.primaryColor,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(labelText: 'Distribution method', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Interest matching', child: Text('Interest matching')),
                DropdownMenuItem(value: 'Round robin', child: Text('Round robin')),
                DropdownMenuItem(value: 'Vendor tier priority', child: Text('Vendor tier priority')),
              ],
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: 20),
            const Text('Distribution rules', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._settings.keys.map((k) => SwitchListTile(
                  title: Text(k),
                  value: _settings[k]!,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (v) => setState(() => _settings[k] = v),
                )),
            const SizedBox(height: 16),
            Card(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              child: const ListTile(
                leading: Icon(Icons.auto_awesome, color: AppTheme.successColor),
                title: Text('128 leads auto-assigned today'),
                subtitle: Text('94% match rate based on visitor interests'),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Distribution settings saved'))),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Save settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderAutomationScreen extends StatefulWidget {
  const ReminderAutomationScreen({super.key});
  static const routeName = '/organizer/reminder-automation';

  @override
  State<ReminderAutomationScreen> createState() => _ReminderAutomationScreenState();
}

class _ReminderAutomationScreenState extends State<ReminderAutomationScreen> {
  final _reminders = [
    _Reminder('Payment due – 7 days before', 'Email + Push', true, 24),
    _Reminder('Payment overdue – daily', 'Email', true, 8),
    _Reminder('Booth setup checklist – 3 days before', 'Push', true, 42),
    _Reminder('Vendor document upload reminder', 'Email', false, 0),
    _Reminder('Post-expo feedback survey', 'Email', true, 3),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Reminder Automation'),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: AppTheme.primaryColor, child: const Icon(Icons.add)),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _reminders.length,
          itemBuilder: (context, i) {
            final r = _reminders[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: SwitchListTile(
                title: Text(r.label, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('${r.channel}${r.sentToday > 0 ? ' · ${r.sentToday} sent today' : ''}'),
                value: r.enabled,
                activeColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _reminders[i] = _Reminder(r.label, r.channel, v, r.sentToday)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Reminder {
  final String label;
  final String channel;
  final bool enabled;
  final int sentToday;
  const _Reminder(this.label, this.channel, this.enabled, this.sentToday);
}
