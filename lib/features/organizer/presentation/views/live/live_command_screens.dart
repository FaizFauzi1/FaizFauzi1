import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/features/organizer/data/models/live_expo.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:eventease/features/organizer/presentation/views/lead/lead_screens.dart';
import 'package:eventease/features/organizer/presentation/views/ticket/ticket_screens.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_async_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:intl/intl.dart';

class _LiveDashboardData {
  final String expoName;
  final LiveExpoStats stats;
  final List<LiveBoothActivity> booths;
  final int openIncidents;
  final List<ExpoTimelineItem> timeline;

  const _LiveDashboardData({
    required this.expoName,
    required this.stats,
    required this.booths,
    required this.openIncidents,
    required this.timeline,
  });

  static const empty = _LiveDashboardData(
    expoName: 'Live Expo',
    stats: LiveExpoStats(visitorsNow: 0, activeBooths: 0, hourlyRate: 0, leadsToday: 0),
    booths: [],
    openIncidents: 0,
    timeline: [],
  );
}

Future<List<ExpoTimelineItem>> _loadTimeline() async {
  final id = await OrganizerRepository.instance.resolveExpoId();
  if (id == null) return [];
  return OrganizerRepository.instance.fetchTimeline(id);
}

Future<List<ExpoIncident>> _loadIncidents() async {
  final id = await OrganizerRepository.instance.resolveExpoId();
  if (id == null) return [];
  return OrganizerRepository.instance.fetchIncidents(id);
}

Future<List<EmergencyAlert>> _loadEmergencyAlerts() async {
  final id = await OrganizerRepository.instance.resolveExpoId();
  if (id == null) return [];
  return OrganizerRepository.instance.fetchEmergencyAlerts(id);
}

Future<_LiveDashboardData> _loadLiveDashboard() async {
  final expoId = await OrganizerRepository.instance.resolveExpoId();
  if (expoId == null) return _LiveDashboardData.empty;
  final name = await OrganizerRepository.instance.fetchExpoName(expoId) ?? 'Live Expo';
  final stats = await OrganizerRepository.instance.fetchLiveExpoStats(expoId);
  final booths = await OrganizerRepository.instance.fetchLiveBoothActivity(expoId);
  final incidents = await OrganizerRepository.instance.fetchIncidents(expoId);
  final timeline = await OrganizerRepository.instance.fetchTimeline(expoId);
  final open = incidents.where((i) => i.status != IncidentStatus.resolved).length;
  return _LiveDashboardData(
    expoName: name,
    stats: stats,
    booths: booths,
    openIncidents: open,
    timeline: timeline,
  );
}

// --- Live Expo Dashboard ---

class LiveExpoDashboardScreen extends StatelessWidget {
  const LiveExpoDashboardScreen({super.key});
  static const routeName = '/organizer/live-expo-dashboard';

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      backgroundColor: Colors.black87,
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<_LiveDashboardData>(
          loader: _loadLiveDashboard,
          builder: (context, data) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  title: Text('LIVE · ${data.expoName}'),
                  actions: [
                    Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          Text('${data.openIncidents} alerts', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      GridView.count(
                        crossAxisCount: ResponsiveUtils.getGridColumnCount(context, mobile: 2, tablet: 4, desktop: 4),
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: ResponsiveUtils.isMobile(context) ? 1.4 : 1.6,
                        children: [
                          _LiveKpi('${data.stats.visitorsNow}', 'Visitors now', Icons.people, Colors.cyanAccent),
                          _LiveKpi('${data.stats.activeBooths}', 'Active booths', Icons.storefront, Colors.greenAccent),
                          _LiveKpi('${data.stats.hourlyRate}/hr', 'Check-in rate', Icons.trending_up, AppTheme.accentColor),
                          _LiveKpi('${data.stats.leadsToday}', 'Leads today', Icons.leaderboard, Colors.purpleAccent),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionTitle('Booth activity', onTap: () => Navigator.pushNamed(context, '/organizer/booth-list')),
            ...data.booths.map(
              (b) => Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    b.isActive ? Icons.circle : Icons.circle_outlined,
                    color: b.isActive ? Colors.greenAccent : Colors.redAccent,
                    size: 14,
                  ),
                  title: Text(b.vendorName, style: const TextStyle(color: Colors.white)),
                  subtitle: Text('${b.boothNumber} · ${b.statusNote}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                  trailing: Text('${b.leadsToday} leads', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle('Live schedule', onTap: () => Navigator.pushNamed(context, ExpoTimelineScreen.routeName)),
            ...data.timeline
                .where((t) => t.status != TimelineItemStatus.completed)
                .take(2)
                .map(
                  (t) => Card(
                    color: Colors.grey[900],
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        t.status == TimelineItemStatus.live ? Icons.play_circle : Icons.schedule,
                        color: t.status == TimelineItemStatus.live ? Colors.greenAccent : Colors.white54,
                      ),
                      title: Text(t.title, style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${timeFmt.format(t.startAt)} · ${t.location}', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    ),
                  ),
                ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _LiveAction('Incidents', Icons.report_problem, () => Navigator.pushNamed(context, IncidentManagementScreen.routeName)),
                _LiveAction('Emergency', Icons.notification_important, () => Navigator.pushNamed(context, EmergencyResponseScreen.routeName)),
                _LiveAction('Attendance', Icons.qr_code, () => Navigator.pushNamed(context, AttendanceDashboardScreen.routeName)),
                _LiveAction('Leads', Icons.people_alt, () => Navigator.pushNamed(context, LeadCollectionScreen.routeName)),
              ],
            ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}

class _LiveKpi extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _LiveKpi(this.value, this.label, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 11)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  const _SectionTitle(this.title, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          if (onTap != null) TextButton(onPressed: onTap, child: const Text('View all')),
        ],
      ),
    );
  }
}

class _LiveAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _LiveAction(this.label, this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: Colors.white70),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      backgroundColor: Colors.grey[800],
      side: BorderSide(color: Colors.grey[700]!),
      onPressed: onTap,
    );
  }
}

// --- Expo Timeline ---

class ExpoTimelineScreen extends StatelessWidget {
  const ExpoTimelineScreen({super.key});
  static const routeName = '/organizer/expo-timeline';

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Expo Timeline · Live'),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<ExpoTimelineItem>>(
          loader: _loadTimeline,
          builder: (context, items) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final t = items[i];
                final (color, label) = switch (t.status) {
                  TimelineItemStatus.live => (AppTheme.successColor, 'LIVE'),
                  TimelineItemStatus.upcoming => (AppTheme.primaryColor, 'Upcoming'),
                  TimelineItemStatus.completed => (AppTheme.textSecondaryColor, 'Done'),
                };
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                        if (i < items.length - 1)
                          Container(width: 2, height: 60, color: AppTheme.borderColor),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('${timeFmt.format(t.startAt)} – ${timeFmt.format(t.endAt)} · ${t.location}',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- Incident Management ---

class IncidentManagementScreen extends StatefulWidget {
  const IncidentManagementScreen({super.key});
  static const routeName = '/organizer/incident-management';

  @override
  State<IncidentManagementScreen> createState() => _IncidentManagementScreenState();
}

class _IncidentManagementScreenState extends State<IncidentManagementScreen> {
  int _filter = 0;

  List<ExpoIncident> _filtered(List<ExpoIncident> incidents) {
    if (_filter == 0) return incidents;
    final type = switch (_filter) {
      1 => IncidentType.booth,
      2 => IncidentType.technical,
      _ => IncidentType.crowdControl,
    };
    return incidents.where((i) => i.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OrganizerAppBar(
        title: 'Incidents',
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showReportSheet(context),
          ),
        ],
      ),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<ExpoIncident>>(
          loader: _loadIncidents,
          builder: (context, incidents) {
            final filtered = _filtered(incidents);
            return Column(
              children: [
                OrganizerFilterChips(
                  labels: const ['All', 'Booth', 'Technical', 'Crowd'],
                  selectedIndex: _filter,
                  onSelected: (i) => setState(() => _filter = i),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final inc = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _IncidentTypeIcon(type: inc.type),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(inc.title, style: const TextStyle(fontWeight: FontWeight.w600))),
                                  _PriorityChip(priority: inc.priority),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(inc.description, style: const TextStyle(fontSize: 13)),
                              const SizedBox(height: 8),
                              Text('${inc.location} · ${inc.reportedBy}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                              if (inc.assignedStaff != null)
                                Text('Assigned: ${inc.assignedStaff}', style: const TextStyle(fontSize: 11)),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _StatusChip(status: inc.status),
                                  const Spacer(),
                                  if (inc.status != IncidentStatus.resolved)
                                    TextButton(
                                      onPressed: () async {
                                        await OrganizerRepository.instance.updateIncidentStatus(
                                          inc.id,
                                          IncidentStatus.inProgress,
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Updated ${inc.title}')),
                                        );
                                        setState(() {});
                                      },
                                      child: const Text('Update'),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Report incident', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Location', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(maxLines: 3, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Incident reported')));
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Submit'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _IncidentTypeIcon extends StatelessWidget {
  final IncidentType type;
  const _IncidentTypeIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (type) {
      IncidentType.booth => (Icons.storefront, AppTheme.primaryColor),
      IncidentType.technical => (Icons.build, Colors.blue),
      IncidentType.crowdControl => (Icons.groups, AppTheme.warningColor),
    };
    return Icon(icon, color: color, size: 20);
  }
}

class _PriorityChip extends StatelessWidget {
  final IncidentPriority priority;
  const _PriorityChip({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = switch (priority) {
      IncidentPriority.critical => Colors.red,
      IncidentPriority.high => Colors.orange,
      IncidentPriority.medium => AppTheme.warningColor,
      IncidentPriority.low => AppTheme.textSecondaryColor,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(priority.name, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IncidentStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      IncidentStatus.open => ('Open', AppTheme.errorColor),
      IncidentStatus.inProgress => ('In progress', AppTheme.warningColor),
      IncidentStatus.resolved => ('Resolved', AppTheme.successColor),
    };
    return Chip(label: Text(label, style: TextStyle(color: color, fontSize: 11)), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact);
  }
}

// --- Emergency Response ---

class EmergencyResponseScreen extends StatefulWidget {
  const EmergencyResponseScreen({super.key});
  static const routeName = '/organizer/emergency-response';

  @override
  State<EmergencyResponseScreen> createState() => _EmergencyResponseScreenState();
}

class _EmergencyResponseScreenState extends State<EmergencyResponseScreen> {
  final _message = TextEditingController();
  final _groups = {'Registration team': true, 'Booth support': true, 'Crowd control': false, 'All vendors': false};

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Response'),
        backgroundColor: Colors.red.shade900,
        foregroundColor: Colors.white,
      ),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.red.shade50,
              child: const ListTile(
                leading: Icon(Icons.warning_amber_rounded, color: Colors.red),
                title: Text('Broadcast urgent alerts to staff & vendors'),
                subtitle: Text('Use for crowd, safety, or operational emergencies only'),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _message,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Alert message',
                hintText: 'e.g. Evacuate Zone B — fire drill',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Notify groups', style: TextStyle(fontWeight: FontWeight.bold)),
            ..._groups.entries.map(
              (e) => CheckboxListTile(
                title: Text(e.key),
                value: e.value,
                onChanged: (v) => setState(() => _groups[e.key] = v ?? false),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () async {
                if (_message.text.trim().isEmpty) return;
                final expoId = await OrganizerRepository.instance.resolveExpoId();
                if (expoId == null) return;
                final groups = _groups.entries.where((e) => e.value).map((e) => e.key).toList();
                await OrganizerRepository.instance.sendEmergencyAlert(
                  expoId: expoId,
                  message: _message.text.trim(),
                  recipientGroups: groups,
                );
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Emergency alert sent to selected groups'), backgroundColor: Colors.red),
                );
                _message.clear();
                setState(() {});
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade800, padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.send),
              label: const Text('Send emergency alert'),
            ),
            const SizedBox(height: 28),
            const Text('Recent alerts', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            OrganizerAsyncBody<List<EmergencyAlert>>(
              loader: _loadEmergencyAlerts,
              builder: (context, history) {
                return Column(
                  children: history
                      .map(
                        (a) => Card(
                          child: ListTile(
                            leading: Icon(
                              a.acknowledged ? Icons.check_circle : Icons.schedule,
                              color: a.acknowledged ? AppTheme.successColor : AppTheme.warningColor,
                            ),
                            title: Text(a.message),
                            subtitle: Text('${DateFormat('HH:mm').format(a.sentAt)} · ${a.recipientGroups.join(', ')}'),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
