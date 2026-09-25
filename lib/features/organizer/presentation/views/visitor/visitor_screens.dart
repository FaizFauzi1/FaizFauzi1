import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/models/expo_visitor.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_async_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:intl/intl.dart';

Future<String?> _activeExpoId() => OrganizerRepository.instance.resolveExpoId();

// --- Visitor Registration ---

class VisitorRegistrationScreen extends StatefulWidget {
  const VisitorRegistrationScreen({super.key});
  static const routeName = '/organizer/visitor-registration';

  @override
  State<VisitorRegistrationScreen> createState() => _VisitorRegistrationScreenState();
}

class _VisitorRegistrationScreenState extends State<VisitorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  DateTime? _weddingDate;
  String _budget = 'RM 50k – 80k';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Visitor Registration'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('Register bridal fair visitor', style: TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: const BorderSide(color: AppTheme.borderColor)),
              title: const Text('Wedding date'),
              subtitle: Text(_weddingDate == null ? 'Select date' : DateFormat('d MMM yyyy').format(_weddingDate!)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 120)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (d != null) setState(() => _weddingDate = d);
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _budget,
              decoration: const InputDecoration(labelText: 'Budget range', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'RM 20k – 30k', child: Text('RM 20k – 30k')),
                DropdownMenuItem(value: 'RM 30k – 50k', child: Text('RM 30k – 50k')),
                DropdownMenuItem(value: 'RM 50k – 80k', child: Text('RM 50k – 80k')),
                DropdownMenuItem(value: 'RM 80k – 120k', child: Text('RM 80k – 120k')),
                DropdownMenuItem(value: 'RM 100k+', child: Text('RM 100k+')),
              ],
              onChanged: (v) => setState(() => _budget = v!),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final expoId = await _activeExpoId();
                if (expoId == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No active expo — open an expo first')),
                  );
                  return;
                }
                await OrganizerRepository.instance.registerVisitor(
                  expoId: expoId,
                  name: _name.text.trim(),
                  phone: _phone.text.trim(),
                  budgetRange: _budget,
                  weddingDate: _weddingDate,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Visitor registered')),
                );
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Register & issue ticket'),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Visitor Check-In (QR) ---

class VisitorCheckInScreen extends StatefulWidget {
  const VisitorCheckInScreen({super.key});
  static const routeName = '/organizer/visitor-check-in';

  @override
  State<VisitorCheckInScreen> createState() => _VisitorCheckInScreenState();
}

class _VisitorCheckInScreenState extends State<VisitorCheckInScreen> {
  ExpoVisitor? _lastCheckIn;
  int _todayCount = 0;
  bool _loadingCount = true;

  @override
  void initState() {
    super.initState();
    _refreshCount();
  }

  Future<void> _refreshCount() async {
    final expoId = await _activeExpoId();
    if (expoId == null) {
      setState(() => _loadingCount = false);
      return;
    }
    final count = await OrganizerRepository.instance.countCheckedInToday(expoId);
    if (mounted) setState(() { _todayCount = count; _loadingCount = false; });
  }

  Future<void> _simulateScan() async {
    final expoId = await _activeExpoId();
    if (expoId == null) return;
    final visitor = await OrganizerRepository.instance.checkInNextRegistered(expoId);
    if (visitor == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No registered visitors waiting')),
      );
      return;
    }
    setState(() {
      _lastCheckIn = visitor;
      _todayCount++;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Checked in: ${visitor.name}'), backgroundColor: AppTheme.successColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Visitor Check-In'),
      body: OrganizerScreenBody(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    _loadingCount ? '…' : '$_todayCount',
                    style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                  const Text('Checked in today'),
                ],
              ),
            ),
            Expanded(
              child: OrganizerScannerPanel(
                hint: 'Scan visitor QR ticket at entrance',
                onSimulate: () => _simulateScan(),
              ),
            ),
            if (_lastCheckIn != null)
              Card(
                margin: const EdgeInsets.all(16),
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: AppTheme.successColor),
                  title: Text(_lastCheckIn!.name),
                  subtitle: Text('${_lastCheckIn!.ticketCode} · ${_lastCheckIn!.budgetRange}'),
                  trailing: TextButton(
                    onPressed: () => Navigator.pushNamed(context, VisitorProfileScreen.routeName, arguments: _lastCheckIn!.id),
                    child: const Text('Profile'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- Visitor Profile ---

class VisitorProfileScreen extends StatelessWidget {
  const VisitorProfileScreen({super.key, this.visitorId});

  final String? visitorId;
  static const routeName = '/organizer/visitor-profile';

  @override
  Widget build(BuildContext context) {
    final id = visitorId ?? ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Visitor')),
        body: const Center(child: Text('No visitor selected')),
      );
    }

    final dateFmt = DateFormat('d MMM yyyy');

    return OrganizerAsyncBody<ExpoVisitor?>(
      loader: () => OrganizerRepository.instance.fetchVisitor(id),
      isEmpty: (v) => v == null,
      emptyWidget: const Center(child: Text('Visitor not found')),
      builder: (context, visitor) {
        return _VisitorProfileBody(visitor: visitor!, dateFmt: dateFmt);
      },
    );
  }
}

class _VisitorProfileBody extends StatelessWidget {
  final ExpoVisitor visitor;
  final DateFormat dateFmt;

  const _VisitorProfileBody({required this.visitor, required this.dateFmt});

  @override
  Widget build(BuildContext context) {
    return OrganizerAsyncBody<List<ExhibitorVendor>>(
      loader: () async {
        final expoId = await _activeExpoId();
        if (expoId == null) return <ExhibitorVendor>[];
        final all = await OrganizerRepository.instance.fetchExhibitors(expoId);
        return all.where((v) => visitor.savedVendorIds.contains(v.id)).toList();
      },
      builder: (context, saved) {
        return Scaffold(
      appBar: AppBar(
        title: Text(visitor.name),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Row('Phone', visitor.phone),
                  if (visitor.weddingDate != null) _Row('Wedding', dateFmt.format(visitor.weddingDate!)),
                  _Row('Budget', visitor.budgetRange),
                  _Row('Ticket', visitor.ticketCode),
                  _Row('Status', visitor.status.name),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Interests', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: visitor.interests.map((i) => Chip(label: Text(i))).toList(),
          ),
          const SizedBox(height: 20),
          const Text('Saved vendors', style: TextStyle(fontWeight: FontWeight.bold)),
          ...saved.map(
            (v) => ListTile(
              leading: const Icon(Icons.bookmark, color: AppTheme.primaryColor),
              title: Text(v.companyName),
              subtitle: Text('${v.category} · Booth ${v.boothNumber ?? '—'}'),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Visited booths', style: TextStyle(fontWeight: FontWeight.bold)),
          ...visitor.visitedBooths.map(
            (b) => ListTile(
              dense: true,
              leading: const Icon(Icons.place_outlined),
              title: Text('Booth $b'),
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, ExpoMapScreen.routeName),
            icon: const Icon(Icons.map_outlined),
            label: const Text('Open expo map'),
          ),
        ],
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
          SizedBox(width: 90, child: Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

// --- Expo Map ---

class ExpoMapScreen extends StatefulWidget {
  const ExpoMapScreen({super.key});
  static const routeName = '/organizer/expo-map';

  @override
  State<ExpoMapScreen> createState() => _ExpoMapScreenState();
}

class _ExpoMapScreenState extends State<ExpoMapScreen> {
  String _query = '';
  String? _selectedBooth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Expo Map'),
      body: OrganizerScreenBody(
        child: OrganizerAsyncBody<List<ExpoMapVendor>>(
          loader: () async {
            final id = await _activeExpoId();
            if (id == null) return <ExpoMapVendor>[];
            return OrganizerRepository.instance.fetchExpoMapVendors(id);
          },
          builder: (context, vendors) {
            final filtered = _query.isEmpty
                ? vendors
                : vendors
                    .where((v) =>
                        v.vendorName.toLowerCase().contains(_query.toLowerCase()) ||
                        v.boothNumber.toLowerCase().contains(_query.toLowerCase()) ||
                        v.category.toLowerCase().contains(_query.toLowerCase()))
                    .toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search vendors or booths...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Stack(
                      children: [
                        const Center(child: Text('Hall floor plan', style: TextStyle(color: AppTheme.textSecondaryColor))),
                        ...filtered.map((v) {
                          final selected = _selectedBooth == v.boothNumber;
                          return Positioned(
                            left: MediaQuery.of(context).size.width * v.mapX * 0.55,
                            top: 120 * v.mapY,
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedBooth = v.boothNumber),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.accentColor : AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(v.boothNumber, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final v = filtered[i];
                      return ListTile(
                        selected: _selectedBooth == v.boothNumber,
                        title: Text(v.vendorName),
                        subtitle: Text('Booth ${v.boothNumber} · ${v.category}'),
                        trailing: const Icon(Icons.navigation_outlined),
                        onTap: () => setState(() => _selectedBooth = v.boothNumber),
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
