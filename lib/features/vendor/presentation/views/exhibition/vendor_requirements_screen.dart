import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';

class VendorRequirementsScreen extends StatefulWidget {
  final ExhibitorVendor exhibitor;

  const VendorRequirementsScreen({
    super.key,
    required this.exhibitor,
  });

  static const routeName = '/vendor-requirements';

  @override
  State<VendorRequirementsScreen> createState() => _VendorRequirementsScreenState();
}

class _VendorRequirementsScreenState extends State<VendorRequirementsScreen> {
  late final TextEditingController _fasciaNameController;
  late final TextEditingController _specialNotesController;

  String _selectedPower = '13A Standard Socket (Free with Package)';
  int _extraTables = 0;
  int _extraChairs = 0;
  bool _needDisplayScreen = false;
  bool _needSpotlight = false;
  bool _carpetUpgrade = false;
  bool _compliedSafety = true;
  bool _isSaving = false;

  final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fasciaNameController = TextEditingController(text: widget.exhibitor.companyName.toUpperCase());
    _specialNotesController = TextEditingController(text: widget.exhibitor.requirements.isNotEmpty ? widget.exhibitor.requirements.join(', ') : '');
  }

  @override
  void dispose() {
    _fasciaNameController.dispose();
    _specialNotesController.dispose();
    super.dispose();
  }

  double get _addonTotal {
    double total = 0;
    if (_selectedPower.contains('15A Heavy Duty')) total += 150;
    if (_selectedPower.contains('32A 3-Phase')) total += 600;
    total += (_extraTables * 50);
    total += (_extraChairs * 30);
    if (_needDisplayScreen) total += 450;
    if (_needSpotlight) total += 80;
    if (_carpetUpgrade) total += 180;
    return total;
  }

  Future<void> _submitRequirements() async {
    if (_fasciaNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide your Booth Fascia Board Name')),
      );
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Logistics & requirements request submitted to organizer!'),
        backgroundColor: Color(0xFF059669),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Booth Logistics & Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fascia Board Name Section
            _buildFasciaSection(),
            const SizedBox(height: 20),

            // Electrical & Power
            _buildPowerSection(),
            const SizedBox(height: 20),

            // Furniture & AV Rental
            _buildEquipmentSection(),
            const SizedBox(height: 20),

            // Logistics Notes & Unloading
            _buildNotesSection(),
            const SizedBox(height: 20),

            // Safety Rules & Declaration
            _buildSafetySection(),
            const SizedBox(height: 24),

            // Order Total & Submit
            _buildSubmitSection(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFasciaSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.signpost_rounded, color: Color(0xFF3B82F6), size: 20),
              SizedBox(width: 8),
              Text(
                'Fascia Signage Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'This exact text will be printed on the standard booth signboard above your booth (Max 32 letters).',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _fasciaNameController,
            maxLength: 32,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g. VOGUE BRIDAL COUTURE',
              counterText: '',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerSection() {
    final powers = [
      '13A Standard Socket (Free with Package)',
      '15A Heavy Duty Power Socket (+RM 150)',
      '32A 3-Phase Industrial Power (+RM 600)',
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFFF59E0B), size: 22),
              SizedBox(width: 8),
              Text(
                'Power Supply Requisition',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...powers.map((p) {
            return RadioListTile<String>(
              value: p,
              groupValue: _selectedPower,
              dense: true,
              contentPadding: EdgeInsets.zero,
              activeColor: AppTheme.primaryColor,
              title: Text(p, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              onChanged: (v) => setState(() => _selectedPower = v!),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEquipmentSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.chair_rounded, color: Color(0xFF10B981), size: 20),
              SizedBox(width: 8),
              Text(
                'Extra Furniture & AV Rental',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _counterItem(
            title: 'Extra Folding Table with Cover',
            price: 'RM 50 / unit',
            count: _extraTables,
            onDecrement: () => setState(() => _extraTables = (_extraTables - 1).clamp(0, 10)),
            onIncrement: () => setState(() => _extraTables++),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _counterItem(
            title: 'Padded Bar Stool / Chair',
            price: 'RM 30 / unit',
            count: _extraChairs,
            onDecrement: () => setState(() => _extraChairs = (_extraChairs - 1).clamp(0, 10)),
            onIncrement: () => setState(() => _extraChairs++),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _toggleItem(
            title: '55" 4K Smart TV on Mobile Floor Stand',
            subtitle: 'HDMI & USB playback compatible',
            price: 'RM 450',
            value: _needDisplayScreen,
            onChanged: (v) => setState(() => _needDisplayScreen = v),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _toggleItem(
            title: 'Adjustable LED Track Spotlight',
            subtitle: 'Warm/White display lighting',
            price: 'RM 80',
            value: _needSpotlight,
            onChanged: (v) => setState(() => _needSpotlight = v),
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          _toggleItem(
            title: 'Premium Needle-Punch Carpet',
            subtitle: 'Choice of Red / Grey / Navy',
            price: 'RM 180',
            value: _carpetUpgrade,
            onChanged: (v) => setState(() => _carpetUpgrade = v),
          ),
        ],
      ),
    );
  }

  Widget _counterItem({
    required String title,
    required String price,
    required int count,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              Text(price, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 22, color: Color(0xFF64748B)),
              onPressed: onDecrement,
            ),
            Text(
              '$count',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, size: 22, color: Color(0xFF3B82F6)),
              onPressed: onIncrement,
            ),
          ],
        ),
      ],
    );
  }

  Widget _toggleItem({
    required String title,
    required String subtitle,
    required String price,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              Text(price, style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: AppTheme.primaryColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping_rounded, color: Color(0xFF64748B), size: 20),
              SizedBox(width: 8),
              Text(
                'Delivery & Loading Bay Requests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _specialNotesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'e.g. 1 x 3-tonne lorry arriving on 9 Oct at 10 AM. Need pallet jack assistance.',
              hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetySection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: _compliedSafety,
          activeColor: AppTheme.primaryColor,
          onChanged: (v) => setState(() => _compliedSafety = v ?? true),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'I confirm that all materials used are flame-retardant and comply with KLCC / Venue Safety Regulations (Sound < 75dB, no naked flame, no unauthorized drilling).',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add-ons Total', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
              Text(
                currency.format(_addonTotal),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submitRequirements,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save & Submit Logistics Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
