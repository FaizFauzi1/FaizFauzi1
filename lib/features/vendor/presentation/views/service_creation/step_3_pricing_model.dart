import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'service_creation_state.dart';
import 'package:eventease/shared/models/services/pricing_model.dart';
import 'package:eventease/shared/widgets/custom_text_field.dart';
import 'package:eventease/core/utils/app_theme.dart';

class Step3PricingModel extends StatefulWidget {
  const Step3PricingModel({super.key});

  @override
  State<Step3PricingModel> createState() => _Step3PricingModelState();
}

class _Step3PricingModelState extends State<Step3PricingModel> {
  late TextEditingController _basePriceController;
  late TextEditingController _minPaxController;
  late TextEditingController _pricePerPaxController;
  late TextEditingController _otherFeesController;

  @override
  void initState() {
    super.initState();
    final state = Provider.of<ServiceCreationState>(context, listen: false);
    _basePriceController = TextEditingController(text: state.basePrice > 0 ? state.basePrice.toString() : '');
    _minPaxController = TextEditingController(text: state.minPax > 0 ? state.minPax.toString() : '');
    _pricePerPaxController = TextEditingController(text: state.pricePerPax > 0 ? state.pricePerPax.toString() : '');
    _otherFeesController = TextEditingController(text: state.otherFeesDescription);
  }

  @override
  void dispose() {
    _basePriceController.dispose();
    _minPaxController.dispose();
    _pricePerPaxController.dispose();
    _otherFeesController.dispose();
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
            'How do you price this service?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose the pricing model that best fits your service structure.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Pricing Model Dropdown
          DropdownButtonFormField<PricingModelType>(
            value: state.pricingType,
            decoration: const InputDecoration(
              labelText: 'Pricing Model',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            items: PricingModelType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.displayName),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                state.setPricingType(value);
              }
            },
          ),
          const SizedBox(height: 24),

          // Dynamic Fields based on Selection
          if (state.pricingType == PricingModelType.perEventType) ...[
            const Text(
              'You have selected "Per Event Type" pricing. In the next step, you will be able to set a different price for each event type you selected.',
              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _basePriceController,
              label: 'General Base Price (Starting From)',
              prefixText: 'RM ',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => state.updatePricingValues(basePrice: double.tryParse(val) ?? 0),
            ),
          ],

          if (state.pricingType == PricingModelType.customCombination) ...[
            _buildTextField(
              controller: _basePriceController,
              label: 'Base Price (Starting From)',
              prefixText: 'RM ',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => state.updatePricingValues(basePrice: double.tryParse(val) ?? 0),
            ),
             const SizedBox(height: 8),
            const Text('Note: You can set specific prices for custom event bundles in the next step.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],

          if (state.pricingType == PricingModelType.perPax) ...[
             _buildTextField(
              controller: _basePriceController,
              label: 'Base Price (Minimum Charge)',
              prefixText: 'RM ',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => state.updatePricingValues(basePrice: double.tryParse(val) ?? 0),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _minPaxController,
                    label: 'Min Pax',
                    keyboardType: TextInputType.number,
                    onChanged: (val) => state.updatePricingValues(minPax: int.tryParse(val) ?? 0),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _pricePerPaxController,
                    label: 'Price Per Pax',
                    prefixText: 'RM ',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (val) => state.updatePricingValues(pricePerPax: double.tryParse(val) ?? 0),
                  ),
                ),
              ],
            ),
          ],
          
           if (state.pricingType == PricingModelType.perHour) ...[
             _buildTextField(
              controller: _basePriceController,
              label: 'Hourly Rate',
              prefixText: 'RM ',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => state.updatePricingValues(basePrice: double.tryParse(val) ?? 0),
            ),
            const SizedBox(height: 16),
            const Text('Minimum hours can be configured in Availability settings.', style: TextStyle(color: Colors.grey)),
          ],

           if (state.pricingType == PricingModelType.perDay) ...[
             _buildTextField(
              controller: _basePriceController,
              label: 'Daily Rate',
              prefixText: 'RM ',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (val) => state.updatePricingValues(basePrice: double.tryParse(val) ?? 0),
            ),
          ],

          const SizedBox(height: 32),
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'What\'s Included in the Price?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be transparent about hidden costs to build trust with customers.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          SwitchListTile(
            title: const Text('Transport / Mileage Included'),
            subtitle: const Text('Is travel to the venue covered by the base price?'),
            value: state.isTransportIncluded,
            activeColor: AppTheme.primaryColor,
            onChanged: (val) => state.updateFeeTransparency(transport: val),
          ),
          SwitchListTile(
            title: const Text('Accommodation Included'),
            subtitle: const Text('Do you cover your own hotel/stay if required?'),
            value: state.isAccommodationIncluded,
            activeColor: AppTheme.primaryColor,
            onChanged: (val) => state.updateFeeTransparency(accommodation: val),
          ),
          SwitchListTile(
            title: const Text('Setup & Teardown Included'),
            subtitle: const Text('Is the time for preparation and cleanup included?'),
            value: state.isSetupIncluded,
            activeColor: AppTheme.primaryColor,
            onChanged: (val) => state.updateFeeTransparency(setup: val),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _otherFeesController,
            label: 'Other Hidden Fees details (Optional)',
            onChanged: (val) => state.updateFeeTransparency(other: val),
          ),
          const SizedBox(height: 8),
          const Text(
            'Example: "Toll and parking fees are excluded and will be charged based on actual receipts."',
            style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.text,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: prefixText,
      ),
      keyboardType: keyboardType,
      onChanged: onChanged,
    );
  }
}
