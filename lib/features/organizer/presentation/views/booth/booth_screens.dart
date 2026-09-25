import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/booth.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_async_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:intl/intl.dart';

Future<List<Booth>> _loadBoothsForActiveExpo() async {
  final expoId = await OrganizerRepository.instance.resolveExpoId();
  if (expoId == null) return [];
  return OrganizerRepository.instance.fetchBooths(expoId);
}

Future<List<Booth>> _loadPendingBoothsForActiveExpo() async {
  final booths = await _loadBoothsForActiveExpo();
  return booths.where((b) => b.status == BoothStatus.pending).toList();
}

// --- Booth List ---

class BoothListScreen extends StatefulWidget {
  const BoothListScreen({super.key});
  static const routeName = '/organizer/booth-list';

  @override
  State<BoothListScreen> createState() => _BoothListScreenState();
}

class _BoothListScreenState extends State<BoothListScreen> {
  int _filter = 0;

  List<Booth> _filtered(List<Booth> booths) {
    if (_filter == 0) return booths;
    final status = switch (_filter) {
      1 => BoothStatus.available,
      2 => BoothStatus.pending,
      _ => BoothStatus.booked,
    };
    return booths.where((b) => b.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Booth List'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, BoothLayoutDesignerScreen.routeName),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.map_outlined),
        label: const Text('Layout'),
      ),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<Booth>>(
          loader: _loadBoothsForActiveExpo,
          builder: (context, booths) {
            final filtered = _filtered(booths);
            return Column(
              children: [
                OrganizerFilterChips(
                  labels: const ['All', 'Available', 'Pending', 'Booked'],
                  selectedIndex: _filter,
                  onSelected: (i) => setState(() => _filter = i),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No booths for this filter'))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final b = filtered[i];
                  return Card(
                    child: ListTile(
                      title: Text('Booth ${b.number}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${b.zoneLabel} · ${b.size}${b.vendorName != null ? ' · ${b.vendorName}' : ''}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          BoothStatusChip(status: b.status),
                          const SizedBox(height: 4),
                          Text(currency.format(b.normalPriceRm), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                            onTap: () => Navigator.pushNamed(
                              context,
                              BoothAssignmentScreen.routeName,
                              arguments: b.id,
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
}

// --- Booth Layout Designer ---

class BoothLayoutDesignerScreen extends StatefulWidget {
  const BoothLayoutDesignerScreen({super.key});
  static const routeName = '/organizer/booth-layout-designer';

  @override
  State<BoothLayoutDesignerScreen> createState() => _BoothLayoutDesignerScreenState();
}

class _BoothLayoutDesignerScreenState extends State<BoothLayoutDesignerScreen> {
  String? _selectedId;

  Color _boothColor(Booth b) {
    if (_selectedId == b.id) return AppTheme.accentColor;
    return switch (b.status) {
      BoothStatus.available => AppTheme.successColor.withValues(alpha: 0.5),
      BoothStatus.pending => AppTheme.warningColor.withValues(alpha: 0.6),
      BoothStatus.booked => AppTheme.primaryColor.withValues(alpha: 0.7),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booth Layout Designer'),
        backgroundColor: const Color(0xFF1E1B4B),
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Layout saved (preview)')),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<Booth>>(
          loader: _loadBoothsForActiveExpo,
          builder: (context, booths) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _LegendDot(color: AppTheme.successColor, label: 'Available'),
                      const SizedBox(width: 12),
                      _LegendDot(color: AppTheme.warningColor, label: 'Pending'),
                      const SizedBox(width: 12),
                      _LegendDot(color: AppTheme.primaryColor, label: 'Booked'),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const cols = 3.0;
                        const rows = 3.0;
                        final cellW = constraints.maxWidth / cols;
                        final cellH = constraints.maxHeight / rows;
                        return Stack(
                          children: booths.map((b) {
                        return Positioned(
                          left: b.gridX * cellW + 4,
                          top: b.gridY * cellH + 4,
                          width: b.gridW * cellW - 8,
                          height: b.gridH * cellH - 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedId = b.id),
                            onLongPress: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Resize ${b.number} (preview)')),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                color: _boothColor(b),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _selectedId == b.id ? Colors.white : Colors.black26,
                                  width: _selectedId == b.id ? 3 : 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  b.number,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                          }).toList(),
                        );
                      },
                    ),
                  ),
                ),
                if (_selectedId != null && booths.any((b) => b.id == _selectedId))
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: ListTile(
                      title: Text('Booth ${booths.firstWhere((b) => b.id == _selectedId).number}'),
                      subtitle: const Text('Long-press to resize · Drag to reposition (coming soon)'),
                      trailing: DropdownButton<BoothZone>(
                        value: booths.firstWhere((b) => b.id == _selectedId).zone,
                        items: BoothZone.values
                            .map((z) => DropdownMenuItem(value: z, child: Text(z.name.toUpperCase())))
                            .toList(),
                        onChanged: (_) {},
                      ),
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// --- Booth Booking ---

class BoothBookingScreen extends StatefulWidget {
  const BoothBookingScreen({super.key});
  static const routeName = '/organizer/booth-booking';

  @override
  State<BoothBookingScreen> createState() => _BoothBookingScreenState();
}

class _BoothBookingScreenState extends State<BoothBookingScreen> {
  void _approve(Booth booth) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Approved booking for ${booth.number}')),
    );
  }

  void _reject(Booth booth) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Rejected booking for ${booth.number}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Booth Booking Requests'),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<Booth>>(
          loader: _loadPendingBoothsForActiveExpo,
          isEmpty: (list) => list.isEmpty,
          emptyWidget: const Center(child: Text('No pending booth bookings')),
          builder: (context, pending) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pending.length,
              itemBuilder: (context, i) {
                final b = pending[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text('Booth ${b.number}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const Spacer(),
                              BoothStatusChip(status: b.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Vendor: ${b.vendorName ?? '—'}'),
                          Text('${b.zoneLabel} · ${b.size}'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _reject(b),
                                  child: const Text('Reject'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _approve(b),
                                  style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                                  child: const Text('Approve'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

// --- Booth Assignment ---

class BoothAssignmentScreen extends StatefulWidget {
  const BoothAssignmentScreen({super.key, this.boothId});

  final String? boothId;
  static const routeName = '/organizer/booth-assignment';

  @override
  State<BoothAssignmentScreen> createState() => _BoothAssignmentScreenState();
}

class _BoothAssignmentScreenState extends State<BoothAssignmentScreen> {
  Booth? _selected;
  String? _vendorId;

  Future<({List<Booth> booths, List<ExhibitorVendor> vendors})> _loadAssignmentData() async {
    final expoId = await OrganizerRepository.instance.resolveExpoId();
    if (expoId == null) return (booths: <Booth>[], vendors: <ExhibitorVendor>[]);
    final booths = await OrganizerRepository.instance.fetchBooths(expoId);
    final vendors =
        await OrganizerRepository.instance.fetchExhibitors(expoId, status: ExhibitorStatus.approved);
    if (booths.isNotEmpty) {
      final id = widget.boothId;
      _selected = id != null
          ? booths.firstWhere((b) => b.id == id, orElse: () => booths.first)
          : booths.firstWhere((b) => b.status == BoothStatus.available, orElse: () => booths.first);
      _vendorId = _selected!.vendorId;
    }
    return (booths: booths, vendors: vendors);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Booth Assignment'),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<({List<Booth> booths, List<ExhibitorVendor> vendors})>(
          loader: _loadAssignmentData,
          isEmpty: (d) => d.booths.isEmpty,
          emptyWidget: const Center(child: Text('No booths configured for this expo')),
          builder: (context, data) {
            final booths = data.booths;
            final vendors = data.vendors;
            final selected = _selected ?? booths.first;
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                DropdownButtonFormField<String>(
                  value: selected.id,
                  decoration: const InputDecoration(labelText: 'Booth', border: OutlineInputBorder()),
                  items: booths
                      .map((b) => DropdownMenuItem(value: b.id, child: Text('${b.number} (${b.statusLabel})')))
                      .toList(),
                  onChanged: (id) {
                    if (id == null) return;
                    setState(() {
                      _selected = booths.firstWhere((b) => b.id == id);
                      _vendorId = _selected!.vendorId;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _vendorId,
                  decoration: const InputDecoration(labelText: 'Assign vendor', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Unassigned')),
                    ...vendors.map((v) => DropdownMenuItem(value: v.id, child: Text(v.companyName))),
                  ],
                  onChanged: (v) => setState(() => _vendorId = v),
                ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.grid_view, color: AppTheme.primaryColor),
                    title: const Text('Confirm layout'),
                    subtitle: Text('${selected.zoneLabel} · ${selected.size}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, BoothLayoutDesignerScreen.routeName),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    await OrganizerRepository.instance.assignBooth(selected.id, exhibitorId: _vendorId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booth assignment saved')),
                    );
                    Navigator.pop(context);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Save assignment'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// --- Booth Pricing ---

class BoothPricingScreen extends StatefulWidget {
  const BoothPricingScreen({super.key});
  static const routeName = '/organizer/booth-pricing';

  @override
  State<BoothPricingScreen> createState() => _BoothPricingScreenState();
}

class _BoothPricingScreenState extends State<BoothPricingScreen> {
  Widget _zoneCard(String title, Map<String, double> prices) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            _PriceRow('Early bird', currency.format(prices['earlyBird'])),
            _PriceRow('Normal', currency.format(prices['normal'])),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit pricing'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, double> _zonePricing(List<Booth> booths, BoothZone zone, Map<String, double> fallback) {
    final sample = booths.where((b) => b.zone == zone).toList();
    if (sample.isEmpty) return fallback;
    final b = sample.first;
    return {'earlyBird': b.earlyBirdPriceRm, 'normal': b.normalPriceRm};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Booth Pricing'),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<Booth>>(
          loader: _loadBoothsForActiveExpo,
          builder: (context, booths) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Zone-based pricing from booth configuration',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 16),
                _zoneCard('Zone A (Premium)', _zonePricing(booths, BoothZone.a, {'earlyBird': 0, 'normal': 0})),
                _zoneCard('Zone B (Standard)', _zonePricing(booths, BoothZone.b, {'earlyBird': 0, 'normal': 0})),
                _zoneCard('VIP Corner', _zonePricing(booths, BoothZone.vip, {'earlyBird': 0, 'normal': 0})),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Early bird period active'),
                  subtitle: const Text('Configure deadline in expo settings'),
                  value: true,
                  onChanged: (_) {},
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  const _PriceRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
