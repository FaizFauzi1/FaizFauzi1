import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/presentation/views/claim_business_screen.dart';

import 'package:intl/intl.dart';

class BusinessInfoStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onChanged;

  const BusinessInfoStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<BusinessInfoStep> createState() => _BusinessInfoStepState();
}

class _BusinessInfoStepState extends State<BusinessInfoStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _legalNameController;
  late TextEditingController _tradingNameController;
  late TextEditingController _ssmNumberController;
  late TextEditingController _businessRegAddressController;
  late TextEditingController _operatingAddressController;
  late TextEditingController _websiteController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;
  late TextEditingController _staffCountController;
  late TextEditingController _capacityController;
  
  String? _businessType;
  DateTime? _ssmExpiryDate;
  int? _startYear;

  final List<String> _businessTypes = [
    'Sole Proprietorship',
    'Partnership',
    'SDN BHD',
    'Individual / Freelancer',
    'Public Limited Company'
  ];

  @override
  void initState() {
    super.initState();
    _legalNameController = TextEditingController(text: widget.data['legal_business_name']);
    _tradingNameController = TextEditingController(text: widget.data['trading_name']);
    _ssmNumberController = TextEditingController(text: widget.data['ssm_number']);
    _businessRegAddressController = TextEditingController(text: widget.data['business_registration_address']);
    _operatingAddressController = TextEditingController(text: widget.data['operating_address']);
    _websiteController = TextEditingController(text: widget.data['website_url']);
    _instagramController = TextEditingController(text: widget.data['social_instagram']);
    _tiktokController = TextEditingController(text: widget.data['social_tiktok']);
    _staffCountController = TextEditingController(text: widget.data['staff_count']?.toString());
    _capacityController = TextEditingController(text: widget.data['peak_season_capacity_per_month']?.toString());
    
    _businessType = widget.data['business_type'];
    if (widget.data['ssm_expiry_date'] != null) {
      _ssmExpiryDate = DateTime.tryParse(widget.data['ssm_expiry_date']);
    }
    _startYear = widget.data['business_start_year'];

    _setupListeners();
  }

  void _setupListeners() {
    void listener() {
      _updateParent();
    }
    _legalNameController.addListener(listener);
    _tradingNameController.addListener(listener);
    _ssmNumberController.addListener(listener);
    _businessRegAddressController.addListener(listener);
    _operatingAddressController.addListener(listener);
    _websiteController.addListener(listener);
    _instagramController.addListener(listener);
    _tiktokController.addListener(listener);
    _staffCountController.addListener(listener);
    _capacityController.addListener(listener);
  }

  void _updateParent() {
    widget.onChanged({
      'legal_business_name': _legalNameController.text,
      'trading_name': _tradingNameController.text,
      'business_type': _businessType,
      'ssm_number': _ssmNumberController.text,
      'ssm_expiry_date': _ssmExpiryDate?.toIso8601String(),
      'business_registration_address': _businessRegAddressController.text,
      'operating_address': _operatingAddressController.text,
      'website_url': _websiteController.text,
      'social_instagram': _instagramController.text,
      'social_tiktok': _tiktokController.text,
      'business_start_year': _startYear,
      'staff_count': int.tryParse(_staffCountController.text),
      'peak_season_capacity_per_month': int.tryParse(_capacityController.text),
    });
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _tradingNameController.dispose();
    _ssmNumberController.dispose();
    _businessRegAddressController.dispose();
    _operatingAddressController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _staffCountController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Information',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please provide your official business details as registered',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Identification'),
            _buildTextField('Legal Business Name', _legalNameController, required: true),
            _buildTextField('Trading Name (if different)', _tradingNameController),
            _buildDropdownField(
              'Business Type',
              _businessType,
              _businessTypes,
              (val) {
                setState(() => _businessType = val);
                _updateParent();
              },
            ),
            Row(
              children: [
                Expanded(child: _buildTextField('SSM Number', _ssmNumberController)),
                const SizedBox(width: 16),
                Expanded(child: _buildDatePicker('SSM Expiry Date', _ssmExpiryDate)),
              ],
            ),
            _buildYearPicker('Business Start Year', _startYear),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Location'),
            _buildTextField('Business Registration Address', _businessRegAddressController, maxLines: 3),
            _buildTextField('Operating Address', _operatingAddressController, maxLines: 3),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Operations & Socials'),
            Row(
              children: [
                Expanded(child: _buildTextField('No. of Staff', _staffCountController, isNumber: true)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField('Monthly Capacity', _capacityController, isNumber: true, hint: 'Events/Month')),
              ],
            ),
            _buildTextField('Website', _websiteController, icon: Icons.language),
            _buildTextField('Instagram', _instagramController, icon: Icons.camera_alt),
            _buildTextField('TikTok', _tiktokController, icon: Icons.music_note),
            const SizedBox(height: 32),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClaimBusinessScreen()),
                  );
                },
                child: const Text('Already have a claim code? Click here to claim your business'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    {bool required = false, int maxLines = 1, bool isNumber = false, String? hint, IconData? icon}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon, color: AppTheme.textSecondaryColor) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: required ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            setState(() => _ssmExpiryDate = picked);
            _updateParent();
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          child: Text(
            date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Select Date',
            style: TextStyle(color: date != null ? AppTheme.textPrimaryColor : Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildYearPicker(String label, int? year) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<int>(
        value: year,
        items: List.generate(50, (index) {
          final y = DateTime.now().year - index;
          return DropdownMenuItem(value: y, child: Text(y.toString()));
        }),
        onChanged: (val) {
          setState(() => _startYear = val);
          _updateParent();
        },
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
