import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class PricingPackagesStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onChanged;

  const PricingPackagesStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<PricingPackagesStep> createState() => _PricingPackagesStepState();
}

class _PricingPackagesStepState extends State<PricingPackagesStep> {
  late TextEditingController _startingPriceController;
  late TextEditingController _pricePerPaxController;
  late TextEditingController _weekendSurchargeController;
  late TextEditingController _peakSurchargeController;
  late TextEditingController _overtimeRateController;
  late TextEditingController _travelFeeController;
  late TextEditingController _depositController;
  late TextEditingController _cancelDaysController;
  late TextEditingController _cancelRefundController;
  late TextEditingController _damagePolicyController;
  
  bool _rescheduleAllowed = true;

  @override
  void initState() {
    super.initState();
    _startingPriceController = TextEditingController(text: widget.data['starting_price']?.toString());
    _pricePerPaxController = TextEditingController(text: widget.data['price_per_pax']?.toString());
    _weekendSurchargeController = TextEditingController(text: widget.data['weekend_surcharge_percent']?.toString());
    _peakSurchargeController = TextEditingController(text: widget.data['peak_season_surcharge_percent']?.toString());
    _overtimeRateController = TextEditingController(text: widget.data['overtime_rate_per_hour']?.toString());
    _travelFeeController = TextEditingController(text: widget.data['travel_fee_per_km']?.toString());
    _depositController = TextEditingController(text: widget.data['deposit_required_percent']?.toString());
    _cancelDaysController = TextEditingController(text: widget.data['cancellation_policy_days']?.toString());
    _cancelRefundController = TextEditingController(text: widget.data['cancellation_refund_percent']?.toString());
    _damagePolicyController = TextEditingController(text: widget.data['damage_policy']);
    
    _rescheduleAllowed = widget.data['reschedule_allowed'] ?? true;
    
    _setupListeners();
  }

  void _setupListeners() {
    void listener() => _updateParent();
    _startingPriceController.addListener(listener);
    _pricePerPaxController.addListener(listener);
    _weekendSurchargeController.addListener(listener);
    _peakSurchargeController.addListener(listener);
    _overtimeRateController.addListener(listener);
    _travelFeeController.addListener(listener);
    _depositController.addListener(listener);
    _cancelDaysController.addListener(listener);
    _cancelRefundController.addListener(listener);
    _damagePolicyController.addListener(listener);
  }

  void _updateParent() {
    widget.onChanged({
      'starting_price': double.tryParse(_startingPriceController.text),
      'price_per_pax': double.tryParse(_pricePerPaxController.text),
      'weekend_surcharge_percent': double.tryParse(_weekendSurchargeController.text),
      'peak_season_surcharge_percent': double.tryParse(_peakSurchargeController.text),
      'overtime_rate_per_hour': double.tryParse(_overtimeRateController.text),
      'travel_fee_per_km': double.tryParse(_travelFeeController.text),
      'deposit_required_percent': double.tryParse(_depositController.text),
      'cancellation_policy_days': int.tryParse(_cancelDaysController.text),
      'cancellation_refund_percent': double.tryParse(_cancelRefundController.text),
      'damage_policy': _damagePolicyController.text,
      'reschedule_allowed': _rescheduleAllowed,
    });
  }

  @override
  void dispose() {
    _startingPriceController.dispose();
    _pricePerPaxController.dispose();
    _weekendSurchargeController.dispose();
    _peakSurchargeController.dispose();
    _overtimeRateController.dispose();
    _travelFeeController.dispose();
    _depositController.dispose();
    _cancelDaysController.dispose();
    _cancelRefundController.dispose();
    _damagePolicyController.dispose();
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
            'Pricing & Policies',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set your base rates and extra charges',
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          _buildSectionHeader('Base Rates'),
          Row(
            children: [
              Expanded(child: _buildTextField('Starting Price (RM)', _startingPriceController, isNumber: true, hint: 'Base package')),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Price Per Pax (RM)', _pricePerPaxController, isNumber: true, hint: 'Catering')),
            ],
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('Surcharges & Fees'),
          Row(
            children: [
              Expanded(child: _buildTextField('Weekend +%', _weekendSurchargeController, isNumber: true, hint: 'e.g. 10')),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField('Peak Season +%', _peakSurchargeController, isNumber: true, hint: 'e.g. 20')),
            ],
          ),
          Row(
             children: [
               Expanded(child: _buildTextField('Overtime (RM/Hr)', _overtimeRateController, isNumber: true)),
               const SizedBox(width: 16),
               Expanded(child: _buildTextField('Travel Fee (RM/KM)', _travelFeeController, isNumber: true)),
             ],
           ),

          const SizedBox(height: 24),
           _buildSectionHeader('Booking & Cancellation'),
           _buildTextField('Deposit Required (%)', _depositController, isNumber: true, hint: 'e.g. 50'),
           const Text('Cancellation Policy', style: TextStyle(fontWeight: FontWeight.w600)),
           const SizedBox(height: 8),
           Row(
             children: [
               Expanded(child: _buildTextField('Days Before Event', _cancelDaysController, isNumber: true, hint: 'e.g. 30')),
               const SizedBox(width: 16),
               Expanded(child: _buildTextField('Refundable %', _cancelRefundController, isNumber: true, hint: 'e.g. 50')),
             ],
           ),
           SwitchListTile(
             title: const Text('Allow Rescheduling?'),
             value: _rescheduleAllowed,
             onChanged: (val) {
               setState(() => _rescheduleAllowed = val);
               _updateParent();
             },
             activeColor: AppTheme.primaryColor,
           ),
           _buildTextField('Damage / Liability Policy', _damagePolicyController, maxLines: 3, hint: 'Terms related to equipment damage or loss.'),
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
    {bool isNumber = false, String? hint, int maxLines = 1}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
