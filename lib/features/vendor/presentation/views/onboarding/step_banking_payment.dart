import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class BankingPaymentStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onChanged;

  const BankingPaymentStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<BankingPaymentStep> createState() => _BankingPaymentStepState();
}

class _BankingPaymentStepState extends State<BankingPaymentStep> {
  late TextEditingController _bankNameController;
  late TextEditingController _accountHolderController;
  late TextEditingController _accountNumberController;
  late TextEditingController _taxNumberController;
  
  String? _payoutPreference;
  bool _fpxEnabled = false;
  
  // E-wallets are stored as a list of strings
  final List<String> _selectedEwallets = [];
  final List<String> _availableEwallets = ['Touch \'n Go', 'GrabPay', 'ShopeePay', 'Boost', 'DuitNow QR'];
  final List<String> _payoutOptions = ['Weekly (Every Monday)', 'Monthly (1st of Month)', 'Upon Request'];

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController(text: widget.data['bank_name']);
    _accountHolderController = TextEditingController(text: widget.data['account_holder_name']);
    _accountNumberController = TextEditingController(text: widget.data['account_number']);
    _taxNumberController = TextEditingController(text: widget.data['tax_number']);
    
    _payoutPreference = widget.data['payout_preference'];
    _fpxEnabled = widget.data['fpx_enabled'] ?? false;
    
    if (widget.data['ewallet_support'] != null) {
      if (widget.data['ewallet_support'] is List) {
        _selectedEwallets.addAll(List<String>.from(widget.data['ewallet_support']));
      }
    }

    _setupListeners();
  }

  void _setupListeners() {
    void listener() => _updateParent();
    _bankNameController.addListener(listener);
    _accountHolderController.addListener(listener);
    _accountNumberController.addListener(listener);
    _taxNumberController.addListener(listener);
  }

  void _updateParent() {
    widget.onChanged({
      'bank_name': _bankNameController.text,
      'account_holder_name': _accountHolderController.text,
      'account_number': _accountNumberController.text,
      'tax_number': _taxNumberController.text,
      'payout_preference': _payoutPreference,
      'fpx_enabled': _fpxEnabled,
      'ewallet_support': _selectedEwallets,
    });
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _taxNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Banking & Payment',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Setup how you receive payments from EventEase',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Bank Account'),
          _buildTextField('Bank Name', _bankNameController, required: true, hint: 'e.g., Maybank, CIMB'),
          _buildTextField('Account Holder Name', _accountHolderController, required: true),
          _buildTextField('Account Number', _accountNumberController, required: true, isNumber: true),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Payment Settings'),
          _buildDropdownField('Payout Preference', _payoutPreference, _payoutOptions, (val) {
            setState(() => _payoutPreference = val);
            _updateParent();
          }),
          _buildTextField('Income Tax Number (Optional)', _taxNumberController),
          
          const SizedBox(height: 24),
           _buildSectionHeader('Receiving Methods'),
           SwitchListTile(
             title: const Text('Enable FPX / Online Banking'),
             subtitle: const Text('Highly recommended for large transactions'),
             value: _fpxEnabled,
             onChanged: (val) {
               setState(() => _fpxEnabled = val);
               _updateParent();
             },
             activeColor: AppTheme.primaryColor,
           ),
           const SizedBox(height: 16),
           const Text(
             'Supported E-Wallets',
             style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor),
           ),
           const SizedBox(height: 8),
           Wrap(
             spacing: 8,
             runSpacing: 8,
             children: _availableEwallets.map((wallet) {
               final isSelected = _selectedEwallets.contains(wallet);
               return FilterChip(
                 label: Text(wallet),
                 selected: isSelected,
                 onSelected: (selected) {
                   setState(() {
                     if (selected) {
                       _selectedEwallets.add(wallet);
                     } else {
                       _selectedEwallets.remove(wallet);
                     }
                   });
                   _updateParent();
                 },
                 selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                 checkmarkColor: AppTheme.primaryColor,
               );
             }).toList(),
           ),
        ],
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
    {bool required = false, bool isNumber = false, String? hint}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
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
}
