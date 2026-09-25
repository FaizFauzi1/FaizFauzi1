import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/expo_ticket.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:eventease/features/organizer/presentation/views/visitor/visitor_screens.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_async_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:intl/intl.dart';

Future<String?> _activeExpoId() => OrganizerRepository.instance.resolveExpoId();

Future<List<ExpoTicketType>> _loadTicketTypes() async {
  final id = await _activeExpoId();
  if (id == null) return [];
  return OrganizerRepository.instance.fetchTicketTypes(id);
}

Future<List<TicketSale>> _loadTicketSales() async {
  final id = await _activeExpoId();
  if (id == null) return [];
  return OrganizerRepository.instance.fetchTicketSales(id);
}

Future<AttendanceSnapshot> _loadAttendanceSnapshot() async {
  final id = await _activeExpoId();
  if (id == null) {
    return const AttendanceSnapshot(
      totalRegistered: 0,
      checkedInNow: 0,
      vipCheckedIn: 0,
      hourlyRate: 0,
      hourlyTrend: [],
    );
  }
  return OrganizerRepository.instance.fetchAttendanceSnapshot(id);
}

// --- Ticket Types ---

class TicketTypeScreen extends StatefulWidget {
  const TicketTypeScreen({super.key});
  static const routeName = '/organizer/ticket-types';

  @override
  State<TicketTypeScreen> createState() => _TicketTypeScreenState();
}

class _TicketTypeScreenState extends State<TicketTypeScreen> {
  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Ticket Types'),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<ExpoTicketType>>(
          loader: _loadTicketTypes,
          builder: (context, types) {
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: types.length,
              itemBuilder: (context, i) {
                final t = types[i];
                final isVip = t.tier == TicketTier.vip;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(isVip ? Icons.star : Icons.confirmation_number_outlined,
                                color: isVip ? AppTheme.accentColor : AppTheme.primaryColor),
                            const SizedBox(width: 8),
                            Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                            const Spacer(),
                            Switch(value: t.isActive, onChanged: (_) {}),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(t.description),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Text(t.priceRm == 0 ? 'Free' : currency.format(t.priceRm),
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            const Spacer(),
                            Text('${t.sold}/${t.quota} sold · ${t.remaining} left',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                          ],
                        ),
                        LinearProgressIndicator(
                          value: t.quota > 0 ? t.sold / t.quota : 0,
                          backgroundColor: AppTheme.borderColor,
                          color: isVip ? AppTheme.accentColor : AppTheme.primaryColor,
                          minHeight: 5,
                          borderRadius: BorderRadius.circular(4),
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

// --- Ticket Sales ---

class TicketSalesScreen extends StatefulWidget {
  const TicketSalesScreen({super.key});
  static const routeName = '/organizer/ticket-sales';

  @override
  State<TicketSalesScreen> createState() => _TicketSalesScreenState();
}

class _TicketSalesScreenState extends State<TicketSalesScreen> {
  int _filter = 0;

  List<TicketSale> _filtered(List<TicketSale> sales) {
    if (_filter == 0) return sales;
    final channel = switch (_filter) {
      1 => TicketSaleChannel.online,
      2 => TicketSaleChannel.walkIn,
      _ => TicketSaleChannel.promo,
    };
    return sales.where((s) => s.channel == channel).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Ticket Sales'),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<TicketSale>>(
          loader: _loadTicketSales,
          builder: (context, sales) {
            final totalRevenue = sales.fold<double>(0, (s, t) => s + t.amountRm);
            final online = sales.where((s) => s.channel == TicketSaleChannel.online).length;
            final filtered = _filtered(sales);

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(child: _SalesKpi('Revenue', currency.format(totalRevenue))),
                      const SizedBox(width: 10),
                      Expanded(child: _SalesKpi('Online', '$online')),
                      const SizedBox(width: 10),
                      Expanded(child: _SalesKpi('Sold', '${sales.length}')),
                    ],
                  ),
                ),
                OrganizerFilterChips(
                  labels: const ['All', 'Online', 'Walk-in', 'Promo'],
                  selectedIndex: _filter,
                  onSelected: (i) => setState(() => _filter = i),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final s = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(s.buyerName),
                          subtitle: Text('${s.ticketCode} · ${_channelLabel(s.channel)}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(s.tier == TicketTier.vip ? 'VIP' : 'Free',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: s.tier == TicketTier.vip ? AppTheme.accentColor : AppTheme.primaryColor,
                                  )),
                              Icon(
                                s.checkedIn ? Icons.check_circle : Icons.schedule,
                                size: 16,
                                color: s.checkedIn ? AppTheme.successColor : AppTheme.textSecondaryColor,
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

  String _channelLabel(TicketSaleChannel c) => switch (c) {
        TicketSaleChannel.online => 'Online',
        TicketSaleChannel.walkIn => 'Walk-in',
        TicketSaleChannel.promo => 'Promo',
      };
}

class _SalesKpi extends StatelessWidget {
  final String label;
  final String value;
  const _SalesKpi(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }
}

// --- QR Ticket Scanner ---

class QrTicketScannerScreen extends StatefulWidget {
  const QrTicketScannerScreen({super.key});
  static const routeName = '/organizer/qr-ticket-scanner';

  @override
  State<QrTicketScannerScreen> createState() => _QrTicketScannerScreenState();
}

class _QrTicketScannerScreenState extends State<QrTicketScannerScreen> {
  TicketSale? _lastValid;
  TicketSale? _lastInvalid;

  Future<void> _validate(String code) async {
    final expoId = await _activeExpoId();
    if (expoId == null) return;
    final sale = await OrganizerRepository.instance.fetchTicketSaleByCode(expoId, code);
    if (!mounted) return;
    setState(() {
      if (sale != null && !sale.checkedIn) {
        _lastValid = sale;
        _lastInvalid = null;
      } else if (sale != null && sale.checkedIn) {
        _lastValid = null;
        _lastInvalid = sale;
      } else {
        _lastValid = null;
        _lastInvalid = null;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid ticket code')));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'QR Ticket Scanner'),
      body: Column(
        children: [
          Expanded(
            child: OrganizerScannerPanel(
              hint: 'Validate entry tickets at gate',
              onSimulate: () => _validate('EXPO-KL-2103'),
            ),
          ),
          if (_lastValid != null)
            Card(
              margin: const EdgeInsets.all(16),
              color: AppTheme.successColor.withValues(alpha: 0.1),
              child: ListTile(
                leading: const Icon(Icons.verified, color: AppTheme.successColor),
                title: Text('Valid · ${_lastValid!.buyerName}'),
                subtitle: Text('${_lastValid!.ticketCode} · ${_lastValid!.tier.name.toUpperCase()}'),
                trailing: FilledButton(
                  onPressed: () async {
                    await OrganizerRepository.instance.checkInTicketSale(_lastValid!.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Entry granted')));
                    setState(() => _lastValid = null);
                  },
                  style: FilledButton.styleFrom(backgroundColor: AppTheme.successColor),
                  child: const Text('Admit'),
                ),
              ),
            ),
          if (_lastInvalid != null)
            Card(
              margin: const EdgeInsets.all(16),
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              child: ListTile(
                leading: const Icon(Icons.block, color: AppTheme.errorColor),
                title: const Text('Already checked in'),
                subtitle: Text('${_lastInvalid!.ticketCode} · ${_lastInvalid!.buyerName}'),
              ),
            ),
        ],
      ),
    );
  }
}

// --- Attendance Dashboard ---

class AttendanceDashboardScreen extends StatelessWidget {
  const AttendanceDashboardScreen({super.key});
  static const routeName = '/organizer/attendance-dashboard';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: OrganizerAppBar(
        title: 'Attendance',
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => Navigator.pushNamed(context, QrTicketScannerScreen.routeName),
          ),
        ],
      ),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<AttendanceSnapshot>(
          loader: _loadAttendanceSnapshot,
          builder: (context, snap) {
            final pct = snap.totalRegistered > 0 ? snap.checkedInNow / snap.totalRegistered : 0.0;

            return _AttendanceBody(snap: snap, pct: pct);
          },
        ),
      ),
    );
  }
}

class _AttendanceBody extends StatelessWidget {
  final AttendanceSnapshot snap;
  final double pct;

  const _AttendanceBody({required this.snap, required this.pct});

  @override
  Widget build(BuildContext context) {
    return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: const Color(0xFF1E1B4B),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('${snap.checkedInNow}', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                  const Text('Visitors inside now', style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white24,
                    color: AppTheme.accentColor,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}% of ${snap.totalRegistered} registered',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _AttKpi('VIP checked in', '${snap.vipCheckedIn}')),
              const SizedBox(width: 10),
              Expanded(child: _AttKpi('Per hour', '+${snap.hourlyRate}')),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Hourly check-ins', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(snap.hourlyTrend.length, (i) {
                final v = snap.hourlyTrend[i];
                final max = snap.hourlyTrend.reduce((a, b) => a > b ? a : b);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text('$v', style: const TextStyle(fontSize: 9)),
                        const SizedBox(height: 4),
                        Container(
                          height: max > 0 ? (v / max) * 80 : 0,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, VisitorCheckInScreen.routeName),
            icon: const Icon(Icons.login),
            label: const Text('Open check-in scanner'),
          ),
        ],
    );
  }
}

class _AttKpi extends StatelessWidget {
  final String label;
  final String value;
  const _AttKpi(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }
}
