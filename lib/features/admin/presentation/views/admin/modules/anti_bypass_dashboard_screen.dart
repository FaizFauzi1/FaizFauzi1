import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/ee_design_tokens.dart';
import 'package:eventease/features/admin/data/providers/admin_bypass_provider.dart';
import 'package:eventease/shared/widgets/design_system/premium_widgets.dart';

/// Admin dashboard for anti-bypass detection and enforcement.
class AntiBypassDashboardScreen extends StatefulWidget {
  const AntiBypassDashboardScreen({super.key});

  @override
  State<AntiBypassDashboardScreen> createState() => _AntiBypassDashboardScreenState();
}

class _AntiBypassDashboardScreenState extends State<AntiBypassDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminBypassProvider>().fetchIncidents();
      context.read<AdminBypassProvider>().fetchRepeatOffenders();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminBypassProvider>();
    final stats = provider.detectionStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anti-Bypass Center'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Flagged Conversations'),
            Tab(text: 'Repeat Offenders'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(EEDesignTokens.spaceMd),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _statChip('Phone', stats['phoneNumber'] ?? 0, Icons.phone),
                _statChip('Email', stats['email'] ?? 0, Icons.email),
                _statChip('WhatsApp', stats['whatsapp'] ?? 0, Icons.chat),
                _statChip('External Pay', stats['externalPayment'] ?? 0, Icons.payment),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _buildIncidentsTab(provider),
                _buildOffendersTab(provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, int count, IconData icon) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryColor),
      label: Text('$label: $count'),
      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
    );
  }

  Widget _buildIncidentsTab(AdminBypassProvider provider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['all', 'flagged', 'warned', 'reviewed', 'dismissed'].map((s) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChipPill(
                  label: s[0].toUpperCase() + s.substring(1),
                  selected: _statusFilter == s,
                  onTap: () {
                    setState(() => _statusFilter = s);
                    provider.fetchIncidents(statusFilter: s == 'all' ? null : s);
                  },
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.incidents.length,
            itemBuilder: (context, i) {
              final incident = provider.incidents[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(incident.originalMessage ?? 'Flagged message'),
                  subtitle: Text(
                    '${incident.flagTypes.join(', ')} · ${incident.severity} · ${incident.senderRole ?? 'unknown'}',
                  ),
                  trailing: PillBadge(
                    label: incident.status,
                    color: incident.severity == 'critical' ? AppTheme.errorColor : AppTheme.warningColor,
                  ),
                  onTap: () => _showIncidentActions(incident),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOffendersTab(AdminBypassProvider provider) {
    if (provider.offenders.isEmpty) {
      return const Center(child: Text('No repeat offenders recorded'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.offenders.length,
      itemBuilder: (context, i) {
        final o = provider.offenders[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _riskColor(o.riskLevel).withValues(alpha: 0.2),
              child: Icon(Icons.warning_amber, color: _riskColor(o.riskLevel)),
            ),
            title: Text('User ${o.userId.substring(0, 8)}…'),
            subtitle: Text('${o.incidentCount} incidents · ${o.warningCount} warnings'),
            trailing: PillBadge(label: o.riskLevel, color: _riskColor(o.riskLevel)),
          ),
        );
      },
    );
  }

  Color _riskColor(String level) => switch (level) {
        'blocked' || 'critical' => AppTheme.errorColor,
        'high' => Colors.orange,
        'medium' => AppTheme.warningColor,
        _ => AppTheme.successColor,
      };

  void _showIncidentActions(BypassIncident incident) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(incident.originalMessage ?? '')),
            ListTile(
              leading: const Icon(Icons.warning),
              title: const Text('Issue Warning'),
              onTap: () {
                if (incident.senderId != null) {
                  context.read<AdminBypassProvider>().issueWarning(
                        vendorId: incident.senderId!,
                        incidentId: incident.id,
                        message: 'Sharing contact details outside EventEase violates platform policy.',
                      );
                }
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check),
              title: const Text('Mark Reviewed'),
              onTap: () {
                context.read<AdminBypassProvider>().reviewIncident(incident.id, 'reviewed');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Dismiss'),
              onTap: () {
                context.read<AdminBypassProvider>().reviewIncident(incident.id, 'dismissed');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
