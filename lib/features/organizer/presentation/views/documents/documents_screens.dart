import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:intl/intl.dart';

class DocumentVaultScreen extends StatefulWidget {
  const DocumentVaultScreen({super.key});
  static const routeName = '/organizer/document-vault';

  @override
  State<DocumentVaultScreen> createState() => _DocumentVaultScreenState();
}

class _DocumentVaultScreenState extends State<DocumentVaultScreen> {
  int _filter = 0;
  final _docs = [
    _Doc('Vendor participation agreement – Glam Bridal', 'Contract', DateTime.now().subtract(const Duration(days: 30))),
    _Doc('Sponsor agreement – Maybank Platinum', 'Agreement', DateTime.now().subtract(const Duration(days: 20))),
    _Doc('INV-2026-0142 – Elegant Dining', 'Invoice', DateTime.now().subtract(const Duration(days: 10))),
    _Doc('Expo insurance certificate', 'Insurance', DateTime.now().subtract(const Duration(days: 45))),
    _Doc('Venue rental contract – MITEC', 'Contract', DateTime.now().subtract(const Duration(days: 60))),
  ];

  List<_Doc> get _filtered {
    if (_filter == 0) return _docs;
    const types = ['All', 'Contract', 'Agreement', 'Invoice'];
    return _docs.where((d) => d.type == types[_filter]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Document Vault'),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: AppTheme.primaryColor, child: const Icon(Icons.upload_file)),
      body: OrganizerScreenBody(
        child: Column(
          children: [
            OrganizerFilterChips(labels: const ['All', 'Contracts', 'Agreements', 'Invoices'], selectedIndex: _filter, onSelected: (i) => setState(() => _filter = i)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final d = _filtered[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(_iconFor(d.type), color: AppTheme.primaryColor),
                      title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('${d.type} · ${DateFormat('d MMM yyyy').format(d.date)}'),
                      trailing: IconButton(icon: const Icon(Icons.download_outlined), onPressed: () {}),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'Invoice' => Icons.receipt_long,
        'Agreement' => Icons.handshake_outlined,
        _ => Icons.description_outlined,
      };
}

class _Doc {
  final String name;
  final String type;
  final DateTime date;
  const _Doc(this.name, this.type, this.date);
}

class VendorContractGeneratorScreen extends StatefulWidget {
  const VendorContractGeneratorScreen({super.key});
  static const routeName = '/organizer/vendor-contract-generator';

  @override
  State<VendorContractGeneratorScreen> createState() => _VendorContractGeneratorScreenState();
}

class _VendorContractGeneratorScreenState extends State<VendorContractGeneratorScreen> {
  final _vendor = TextEditingController(text: 'Glam Bridal Studio');
  final _booth = TextEditingController(text: 'A-01');
  final _fee = TextEditingController(text: '3500');
  String _package = 'Premium Showcase';

  @override
  void dispose() {
    _vendor.dispose();
    _booth.dispose();
    _fee.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Vendor Contract Generator'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(controller: _vendor, decoration: const InputDecoration(labelText: 'Vendor name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _booth, decoration: const InputDecoration(labelText: 'Booth number', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _fee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Booth fee (RM)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _package,
              decoration: const InputDecoration(labelText: 'Package', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Standard Booth', child: Text('Standard Booth')),
                DropdownMenuItem(value: 'Premium Showcase', child: Text('Premium Showcase')),
                DropdownMenuItem(value: 'Corner Premium', child: Text('Corner Premium')),
              ],
              onChanged: (v) => setState(() => _package = v!),
            ),
            const SizedBox(height: 20),
            Card(
              color: AppTheme.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Participation Agreement\n\n'
                  'Vendor: ${_vendor.text}\n'
                  'Booth: ${_booth.text}\n'
                  'Package: $_package\n'
                  'Fee: ${currency.format(double.tryParse(_fee.text) ?? 0)}\n\n'
                  'The vendor agrees to participate in the expo, comply with booth guidelines, and remit payment per the agreed schedule.',
                  style: const TextStyle(height: 1.5, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contract generated and saved to vault'))),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.description),
              label: const Text('Generate contract'),
            ),
          ],
        ),
      ),
    );
  }
}

class SponsorProposalScreen extends StatefulWidget {
  const SponsorProposalScreen({super.key});
  static const routeName = '/organizer/sponsor-proposal';

  @override
  State<SponsorProposalScreen> createState() => _SponsorProposalScreenState();
}

class _SponsorProposalScreenState extends State<SponsorProposalScreen> {
  final _sponsor = TextEditingController(text: 'Prospective Sponsor Sdn Bhd');
  String _tier = 'Gold';
  final _contact = TextEditingController(text: 'marketing@sponsor.com');

  @override
  void dispose() {
    _sponsor.dispose();
    _contact.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    final price = switch (_tier) {
      'Platinum' => 85000.0,
      'Gold' => 45000.0,
      _ => 18000.0,
    };

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Sponsor Proposal'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(controller: _sponsor, decoration: const InputDecoration(labelText: 'Sponsor company', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _contact, decoration: const InputDecoration(labelText: 'Contact email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _tier,
              decoration: const InputDecoration(labelText: 'Proposed tier', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Platinum', child: Text('Platinum')),
                DropdownMenuItem(value: 'Gold', child: Text('Gold')),
                DropdownMenuItem(value: 'Silver', child: Text('Silver')),
              ],
              onChanged: (v) => setState(() => _tier = v!),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_tier sponsorship proposal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Investment: ${currency.format(price)}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    const Text('Included deliverables based on selected tier. Proposal valid for 30 days.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Proposal sent to ${_contact.text}'))),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.send),
              label: const Text('Send proposal'),
            ),
          ],
        ),
      ),
    );
  }
}
