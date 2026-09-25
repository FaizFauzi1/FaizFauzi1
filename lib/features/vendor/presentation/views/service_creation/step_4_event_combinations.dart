import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'service_creation_state.dart';
import 'package:eventease/shared/models/services/pricing_model.dart';
import 'package:eventease/shared/widgets/custom_text_field.dart';

class Step4EventCombinations extends StatelessWidget {
  const Step4EventCombinations({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<ServiceCreationState>(context);

    // If pricing model is not one that uses combinations, we might skip this step or show minimal info.
    // However, even per-pax might have different base prices per event type?
    // For now, let's assume this step is active if there are event types selected.

    if (state.selectedEventTypes.isEmpty) {
      return const Center(child: Text('Please select event types in Step 2 first.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Set Prices for Event Types',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Customize pricing for single events and bundles.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          if (state.eventCombinations.isEmpty)
             const Text('No event combinations generated. Go back and select event types.'),
          
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.eventCombinations.length,
            itemBuilder: (context, index) {
              final combo = state.eventCombinations[index];
              final isBundle = combo.eventTypes.length > 1;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  combo.displayName ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                if (isBundle)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 4.0),
                                    child: Chip(
                                      label: Text('BUNDLE Deal', style: TextStyle(fontSize: 10)),
                                      padding: EdgeInsets.zero,
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: Colors.amberAccent,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 120,
                            child: TextField(
                              decoration: const InputDecoration(
                                labelText: 'Price (RM)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              controller: TextEditingController(text: combo.price > 0 ? combo.price.toString() : '')
                                ..selection = TextSelection.collapsed(offset: (combo.price > 0 ? combo.price.toString() : '').length),
                              onChanged: (val) {
                                state.updateCombinationPrice(index, double.tryParse(val) ?? 0);
                              },
                            ),
                          ),
                        ],
                      ),
                      if (isBundle) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Bundle includes: ',
                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                        ),
                        Text(
                          combo.eventTypes.join(', '), // Should map to display names in real app
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
