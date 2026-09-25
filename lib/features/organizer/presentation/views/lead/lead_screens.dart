import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/models/expo_lead.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_async_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:intl/intl.dart';

Future<String?> _activeExpoId() => OrganizerRepository.instance.resolveExpoId();

Future<List<ExpoLead>> _loadLeads() async {
  final expoId = await _activeExpoId();
  if (expoId == null) return [];
  return OrganizerRepository.instance.fetchLeads(expoId);
}

Future<({List<ExpoLead> unassigned, List<ExhibitorVendor> vendors})> _loadLeadDistributionData() async {
  final expoId = await _activeExpoId();
  if (expoId == null) return (unassigned: <ExpoLead>[], vendors: <ExhibitorVendor>[]);
  final leads = await OrganizerRepository.instance.fetchLeads(expoId);
  final vendors = await OrganizerRepository.instance.fetchExhibitors(expoId, status: ExhibitorStatus.approved);
  return (unassigned: leads.where((l) => !l.isAssigned).toList(), vendors: vendors);
}

// --- Lead Collection ---

class LeadCollectionScreen extends StatefulWidget {
  const LeadCollectionScreen({super.key});
  static const routeName = '/organizer/lead-collection';

  @override
  State<LeadCollectionScreen> createState() => _LeadCollectionScreenState();
}

class _LeadCollectionScreenState extends State<LeadCollectionScreen> {
  int _filter = 0;

  List<ExpoLead> _filtered(List<ExpoLead> leads) {
    if (_filter == 0) return leads;
    if (_filter == 1) return leads.where((l) => !l.isAssigned).toList();
    return leads.where((l) => l.isAssigned).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OrganizerAppBar(
        title: 'Lead Collection',
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () => Navigator.pushNamed(context, LeadDistributionScreen.routeName),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCaptureDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.person_add),
      ),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<ExpoLead>>(
          loader: _loadLeads,
          builder: (context, leads) {
            final filtered = _filtered(leads);
            return Column(
              children: [
                OrganizerFilterChips(
                  labels: const ['All', 'Unassigned', 'Assigned'],
                  selectedIndex: _filter,
                  onSelected: (i) => setState(() => _filter = i),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _StatPill('${leads.length}', 'Total'),
                      const SizedBox(width: 8),
                      _StatPill('${leads.where((l) => l.temperature == LeadTemperature.hot).length}', 'Hot'),
                      const SizedBox(width: 8),
                      _StatPill('${leads.where((l) => l.stage == LeadStage.converted).length}', 'Converted'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No leads match this filter'))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: filtered.length,
                          itemBuilder: (context, i) {
                            final lead = filtered[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(lead.visitorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${lead.budgetRange}\n'
                        '${lead.interests.join(', ')}${lead.assignedVendorName != null ? '\n→ ${lead.assignedVendorName}' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LeadTemperatureChip(temp: lead.temperature),
                          const SizedBox(height: 4),
                          LeadStageChip(stage: lead.stage),
                        ],
                      ),
                      onTap: () => Navigator.pushNamed(context, LeadDetailScreen.routeName, arguments: lead.id),
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

  void _showCaptureDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Capture lead', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Visitor name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Wedding date', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Budget range', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lead captured (preview)')));
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Save lead'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String value;
  final String label;
  const _StatPill(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }
}

// --- Lead Distribution ---

class LeadDistributionScreen extends StatefulWidget {
  const LeadDistributionScreen({super.key});
  static const routeName = '/organizer/lead-distribution';

  @override
  State<LeadDistributionScreen> createState() => _LeadDistributionScreenState();
}

class _LeadDistributionScreenState extends State<LeadDistributionScreen> {
  Future<void> _assign(ExpoLead lead, String vendorId, String vendorName) async {
    await OrganizerRepository.instance.assignLead(lead.id, vendorId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Assigned ${lead.visitorName} → $vendorName')),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Lead Distribution'),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<({List<ExpoLead> unassigned, List<ExhibitorVendor> vendors})>(
          loader: _loadLeadDistributionData,
          isEmpty: (d) => d.unassigned.isEmpty,
          emptyWidget: const Center(child: Text('All leads are assigned')),
          builder: (context, data) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.unassigned.length,
              itemBuilder: (context, i) {
                final lead = data.unassigned[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Text(lead.visitorName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${lead.interests.join(', ')} · ${lead.budgetRange}'),
                      children: data.vendors
                          .map(
                            (v) => ListTile(
                              dense: true,
                              title: Text(v.companyName),
                              subtitle: Text(v.category),
                              trailing: const Icon(Icons.arrow_forward),
                              onTap: () => _assign(lead, v.id, v.companyName),
                            ),
                          )
                          .toList(),
                    ),
                  );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- Lead Detail ---

class LeadDetailScreen extends StatefulWidget {
  const LeadDetailScreen({super.key, this.leadId});

  final String? leadId;
  static const routeName = '/organizer/lead-detail';

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final id = widget.leadId ?? ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lead')),
        body: const OrganizerScreenBody(child: Center(child: Text('No lead selected'))),
      );
    }

    final dateFmt = DateFormat('d MMM yyyy');

    return OrganizerAsyncBody<ExpoLead?>(
      loader: () => OrganizerRepository.instance.fetchLead(id),
      isEmpty: (lead) => lead == null,
      emptyWidget: const Center(child: Text('Lead not found')),
      builder: (context, lead) {
        final leadData = lead!;
        return Scaffold(
      appBar: AppBar(
        title: Text(leadData.visitorName),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                LeadTemperatureChip(temp: leadData.temperature),
                const SizedBox(width: 8),
                LeadStageChip(stage: leadData.stage),
              ],
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Visitor info', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _Row('Phone', leadData.phone),
                    if (leadData.weddingDate != null) _Row('Wedding date', dateFmt.format(leadData.weddingDate!)),
                    _Row('Budget', leadData.budgetRange),
                    _Row('Source', leadData.sourceBooth),
                    _Row('Captured', DateFormat('d MMM yyyy, HH:mm').format(leadData.capturedAt)),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Interest categories', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: leadData.interests
                          .map((i) => Chip(label: Text(i), backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.store, color: AppTheme.primaryColor),
                title: const Text('Assigned vendor'),
                subtitle: Text(leadData.assignedVendorName ?? 'Not assigned'),
                trailing: leadData.isAssigned ? null : const Icon(Icons.edit),
                onTap: () => Navigator.pushNamed(context, LeadDistributionScreen.routeName),
              ),
            ),
            if (leadData.notes != null)
              Card(
                child: ListTile(
                  title: const Text('Notes'),
                  subtitle: Text(leadData.notes!),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, LeadTrackingScreen.routeName),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Update tracking stage'),
            ),
          ],
        ),
      ),
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// --- Lead Tracking (kanban-style) ---

class LeadTrackingScreen extends StatelessWidget {
  const LeadTrackingScreen({super.key});
  static const routeName = '/organizer/lead-tracking';

  @override
  Widget build(BuildContext context) {
    final stages = LeadStage.values;

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Lead Tracking'),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<ExpoLead>>(
          loader: _loadLeads,
          builder: (context, leads) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: stages.map((stage) {
            final stageLeads = leads.where((l) => l.stage == stage).toList();
            final title = switch (stage) {
              LeadStage.newLead => 'New',
              LeadStage.contacted => 'Contacted',
              LeadStage.followedUp => 'Followed up',
              LeadStage.converted => 'Converted',
              LeadStage.lost => 'Lost',
            };
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ExpansionTile(
                initiallyExpanded: stage == LeadStage.newLead || stage == LeadStage.followedUp,
                title: Text('$title (${stageLeads.length})', style: const TextStyle(fontWeight: FontWeight.w600)),
                children: stageLeads.isEmpty
                    ? [const ListTile(title: Text('No leads', style: TextStyle(color: AppTheme.textSecondaryColor)))]
                    : stageLeads
                        .map(
                          (l) => ListTile(
                            title: Text(l.visitorName),
                            subtitle: Text(l.assignedVendorName ?? 'Unassigned'),
                            trailing: LeadTemperatureChip(temp: l.temperature),
                            onTap: () => Navigator.pushNamed(context, LeadDetailScreen.routeName, arguments: l.id),
                          ),
                        )
                        .toList(),
              ),
            );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}

// --- Lead Quality Scoring ---

class LeadQualityScoringScreen extends StatelessWidget {
  const LeadQualityScoringScreen({super.key});
  static const routeName = '/organizer/lead-quality-scoring';

  @override
  Widget build(BuildContext context) {
    Widget section(String title, LeadTemperature temp, Color color, List<ExpoLead> leads) {
      final items = leads.where((l) => l.temperature == temp).toList();
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, color: color, size: 20),
                  const SizedBox(width: 8),
                  Text('$title (${items.length})', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
            if (items.isEmpty)
              const Padding(padding: EdgeInsets.all(16), child: Text('No leads'))
            else
              ...items.map(
                (l) => ListTile(
                  title: Text(l.visitorName),
                  subtitle: Text('${l.budgetRange} · ${l.interests.join(', ')}'),
                  trailing: LeadStageChip(stage: l.stage),
                  onTap: () => Navigator.pushNamed(context, LeadDetailScreen.routeName, arguments: l.id),
                ),
              ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Lead Quality Scoring'),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<ExpoLead>>(
          loader: _loadLeads,
          builder: (context, leads) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Score leads by wedding date proximity, budget fit, and booth engagement.',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 16),
                section('Hot leads', LeadTemperature.hot, Colors.redAccent, leads),
                section('Warm leads', LeadTemperature.warm, AppTheme.warningColor, leads),
                section('Cold leads', LeadTemperature.cold, Colors.blueGrey, leads),
              ],
            );
          },
        ),
      ),
    );
  }
}
