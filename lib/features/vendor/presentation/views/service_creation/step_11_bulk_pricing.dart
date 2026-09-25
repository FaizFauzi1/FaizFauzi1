import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/presentation/views/service_creation/service_creation_state.dart';
import 'package:eventease/shared/models/services/pricing_model.dart';
import 'package:eventease/core/utils/app_theme.dart';

class Step11BulkPricing extends StatefulWidget {
  const Step11BulkPricing({super.key});

  @override
  State<Step11BulkPricing> createState() => _Step11BulkPricingState();
}

class _Step11BulkPricingState extends State<Step11BulkPricing> {
  final _minQtyController = TextEditingController();
  final _maxQtyController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void dispose() {
    _minQtyController.dispose();
    _maxQtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _showAddTierDialog(ServiceCreationState state, {int? index, BulkPricingTier? existing}) {
    if (existing != null) {
      _minQtyController.text = existing.minQty.toString();
      _maxQtyController.text = existing.maxQty?.toString() ?? '';
      _priceController.text = existing.pricePerUnit.toString();
    } else {
      _minQtyController.clear();
      _maxQtyController.clear();
      _priceController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'Add Pricing Tier' : 'Edit Pricing Tier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _minQtyController,
              decoration: const InputDecoration(labelText: 'Min Quantity', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _maxQtyController,
              decoration: const InputDecoration(labelText: 'Max Quantity (Optional)', hintText: 'Leave empty for no limit', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: 'Price per Unit', prefixText: 'RM ', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final min = int.tryParse(_minQtyController.text) ?? 1;
              final max = int.tryParse(_maxQtyController.text);
              final price = double.tryParse(_priceController.text) ?? 0.0;
              
              final tier = BulkPricingTier(minQty: min, maxQty: max, pricePerUnit: price);
              if (index != null) {
                state.updateBulkPricingTier(index, tier);
              } else {
                state.addBulkPricingTier(tier);
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text('Save Tier'),
          ),
        ],
      ),
    );
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
            'Bulk Pricing Models',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Incentivize larger orders by offering volume discounts.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          SwitchListTile(
            title: const Text('Enable Volume Discounts'),
            subtitle: const Text('Allow custom pricing based on order quantity.'),
            value: state.bulkPricingEnabled,
            activeColor: AppTheme.primaryColor,
            onChanged: (val) => state.toggleBulkPricing(val),
          ),

          if (state.bulkPricingEnabled) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Price Ladder', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: () => _showAddTierDialog(state),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Tier'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (state.bulkPricingTiers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.layers_outlined, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No tiers defined yet.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.bulkPricingTiers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final tier = state.bulkPricingTiers[index];
                  return Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                        child: Text('${index + 1}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(
                        '${tier.minQty}${tier.maxQty != null ? " – ${tier.maxQty}" : "+"} units',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('RM ${tier.pricePerUnit.toStringAsFixed(2)} per unit'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showAddTierDialog(state, index: index, existing: tier)),
                          IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => state.removeBulkPricingTier(index)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Tiers are applied based on the quantity in the customer\'s cart. The unit price will adjust automatically.',
                      style: TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
