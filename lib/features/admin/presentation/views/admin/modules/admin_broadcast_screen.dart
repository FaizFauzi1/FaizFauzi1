import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';
import 'package:eventease/features/admin/data/providers/admin_churn_provider.dart';

/// Broadcast scheduler with audience targeting and push support.
class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _audience = 'all';
  String _channel = 'in_app';
  DateTime? _scheduledAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminChurnProvider>().fetchAnnouncements();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final churn = context.watch<AdminChurnProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Broadcast Center'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
        children: [
          Text('New Announcement', style: EEDesignTokens.headlineMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _audience,
            decoration: const InputDecoration(labelText: 'Audience', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Users')),
              DropdownMenuItem(value: 'customers', child: Text('Customers Only')),
              DropdownMenuItem(value: 'vendors', child: Text('Vendors Only')),
              DropdownMenuItem(value: 'tier_premium', child: Text('Premium Tier')),
            ],
            onChanged: (v) => setState(() => _audience = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _channel,
            decoration: const InputDecoration(labelText: 'Channel', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'in_app', child: Text('In-App')),
              DropdownMenuItem(value: 'push', child: Text('Push Notification')),
              DropdownMenuItem(value: 'email', child: Text('Email')),
              DropdownMenuItem(value: 'banner', child: Text('Dashboard Banner')),
            ],
            onChanged: (v) => setState(() => _channel = v!),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(_scheduledAt == null ? 'Schedule for later' : 'Scheduled: $_scheduledAt'),
            trailing: IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _scheduledAt = date);
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _send(sendNow: false),
                  child: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _send(sendNow: true),
                  child: const Text('Send Now'),
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Text('History', style: EEDesignTokens.headlineMedium),
          const SizedBox(height: 12),
          ...churn.announcements.map((a) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(a.title ?? a.message.substring(0, a.message.length.clamp(0, 40))),
                  subtitle: Text('${a.audience} · ${a.channel} · ${a.status}'),
                  trailing: a.pinned ? const Icon(Icons.push_pin, size: 16) : null,
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _send({required bool sendNow}) async {
    if (_messageController.text.isEmpty) return;
    await context.read<AdminChurnProvider>().scheduleAnnouncement(
          title: _titleController.text,
          message: _messageController.text,
          audience: _audience,
          channel: _channel,
          scheduledAt: _scheduledAt,
          sendNow: sendNow,
        );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(sendNow ? 'Broadcast sent' : 'Draft saved')),
      );
      _titleController.clear();
      _messageController.clear();
    }
  }
}
