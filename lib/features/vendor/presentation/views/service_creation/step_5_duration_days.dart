import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'service_creation_state.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/shared/models/services/pricing_model.dart';

class Step5DurationDays extends StatefulWidget {
  const Step5DurationDays({super.key});

  @override
  State<Step5DurationDays> createState() => _Step5DurationDaysState();
}

class _Step5DurationDaysState extends State<Step5DurationDays> {
  late TextEditingController _sameDayDiscountController;
  late TextEditingController _differentDaySurchargeController;
  late TextEditingController _minOrderQtyController;
  late TextEditingController _productionDaysController;
  late TextEditingController _minRentalDaysController;
  late TextEditingController _maxRentalDaysController;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<ServiceCreationState>(context, listen: false);
    _sameDayDiscountController = TextEditingController(text: state.sameDayDiscount?.toString() ?? '');
    _differentDaySurchargeController = TextEditingController(text: state.differentDaySurcharge?.toString() ?? '');
    _minOrderQtyController = TextEditingController(text: state.minOrderQty?.toString() ?? '');
    _productionDaysController = TextEditingController(text: state.productionDays?.toString() ?? '');
    _minRentalDaysController = TextEditingController(text: state.minRentalDays?.toString() ?? '');
    _maxRentalDaysController = TextEditingController(text: state.maxRentalDays?.toString() ?? '');
  }

  @override
  void dispose() {
    _sameDayDiscountController.dispose();
    _differentDaySurchargeController.dispose();
    _minOrderQtyController.dispose();
    _productionDaysController.dispose();
    _minRentalDaysController.dispose();
    _maxRentalDaysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ServiceCreationState>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Duration and Day Controls',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Configure how you handle multi-day events or multiple events on the same day.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          SwitchListTile(
            title: const Text('Allow Multiple Events on Same Day?'),
            subtitle: const Text('e.g. Morning Akad Nikah + Afternoon Reception'),
            value: state.allowSameDayMultiEvent,
            onChanged: (val) {
              state.updateDurationControls(allowSameDay: val);
            },
          ),
          const Divider(),
          
          if (state.allowSameDayMultiEvent) ...[
            const SizedBox(height: 16),
             _buildTextField(
              controller: _sameDayDiscountController,
              label: 'Same Day Discount (RM)',
              helperText: 'Discount applied if customer books multiple events on the same day.',
              prefixText: 'RM ',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => state.updateDurationControls(sameDayDiscount: double.tryParse(val)),
            ),
          ],
          
          const SizedBox(height: 24),
          const Text('Split Day Surcharges', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
           _buildTextField(
            controller: _differentDaySurchargeController,
            label: 'Different Day Surcharge (RM)',
            helperText: 'Extra charge if customer splits booked events across different days.',
            prefixText: 'RM ',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (val) => state.updateDurationControls(differentDaySurcharge: double.tryParse(val)),
          ),

          const SizedBox(height: 32),
          const Divider(thickness: 2),
          const SizedBox(height: 16),

          // --- Preorder Logic (Doorgift, Product, etc.) ---
          if (state.category == EventCategory.doorgift || 
              state.category == EventCategory.fashion || 
              state.category == EventCategory.other) ...[
            const Text(
              'Preorder & Bulk Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _minOrderQtyController,
              label: 'Minimum Order Quantity (MOQ)',
              helperText: 'Minimum units a customer must buy (e.g. 100 pcs).',
              keyboardType: TextInputType.number,
              onChanged: (val) => state.updatePreorderRentalInfo(minOrderQty: int.tryParse(val)),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _productionDaysController,
              label: 'Production Lead Time (Days)',
              helperText: 'How many days you need to prepare the order before the event.',
              keyboardType: TextInputType.number,
              onChanged: (val) => state.updatePreorderRentalInfo(productionDays: int.tryParse(val)),
            ),
            const SizedBox(height: 24),
          ],

          // --- Rental Logic ---
          if (state.pricingType == PricingModelType.perDay || 
              state.category == EventCategory.venue || 
              state.category == EventCategory.transportation) ...[
            const Text(
              'Rental Duration Constraints',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _minRentalDaysController,
                    label: 'Min Rental Days',
                    keyboardType: TextInputType.number,
                    onChanged: (val) => state.updatePreorderRentalInfo(minRentalDays: int.tryParse(val)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _maxRentalDaysController,
                    label: 'Max Rental Days',
                    keyboardType: TextInputType.number,
                    onChanged: (val) => state.updatePreorderRentalInfo(maxRentalDays: int.tryParse(val)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    String? helperText,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixText: prefixText,
        border: const OutlineInputBorder(),
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }
}
