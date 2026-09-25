import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/presentation/views/service_creation/service_creation_state.dart';
import 'package:eventease/shared/models/services/pricing_model.dart';
import 'package:eventease/core/utils/app_theme.dart';

class Step12Variations extends StatefulWidget {
  const Step12Variations({super.key});

  @override
  State<Step12Variations> createState() => _Step12VariationsState();
}

class _Step12VariationsState extends State<Step12Variations> {
  final _variationNameController = TextEditingController();
  final _optionNameController = TextEditingController();
  final _optionPriceController = TextEditingController();
  final _optionStockController = TextEditingController();

  Map<String, double> _tempPrices = {};
  Map<String, int> _tempStock = {};
  List<String> _tempOptions = [];

  @override
  void dispose() {
    _variationNameController.dispose();
    _optionNameController.dispose();
    _optionPriceController.dispose();
    _optionStockController.dispose();
    super.dispose();
  }

  void _showAddVariationDialog(ServiceCreationState state, {int? index, ProductVariation? existing}) {
    if (existing != null) {
      _variationNameController.text = existing.name;
      _tempOptions = List.from(existing.options);
      _tempPrices = Map.from(existing.optionPrices);
      _tempStock = Map.from(existing.optionStock ?? {});
    } else {
      _variationNameController.clear();
      _tempOptions = [];
      _tempPrices = {};
      _tempStock = {};
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(existing == null ? 'Add Product Variation' : 'Edit Product Variation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _variationNameController,
                  decoration: const InputDecoration(
                    labelText: 'Variation Name',
                    hintText: 'e.g., Size, Color, Flavor',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Options & Adjustments', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Add Option Form
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _optionNameController,
                        decoration: const InputDecoration(labelText: 'Option Name', hintText: 'e.g., Red, XL, Chocolate', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _optionPriceController,
                              decoration: const InputDecoration(labelText: 'Price (+/-)', prefixText: 'RM ', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _optionStockController,
                              decoration: const InputDecoration(labelText: 'Stock', hintText: '0 for no track', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final name = _optionNameController.text.trim();
                            if (name.isNotEmpty) {
                              setModalState(() {
                                if (!_tempOptions.contains(name)) _tempOptions.add(name);
                                _tempPrices[name] = double.tryParse(_optionPriceController.text) ?? 0.0;
                                final stock = int.tryParse(_optionStockController.text);
                                if (stock != null) _tempStock[name] = stock;
                                
                                _optionNameController.clear();
                                _optionPriceController.clear();
                                _optionStockController.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Option'),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Options List
                if (_tempOptions.isNotEmpty)
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tempOptions.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final opt = _tempOptions[index];
                      final price = _tempPrices[opt] ?? 0.0;
                      final stock = _tempStock[opt];
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Text(opt, style: const TextStyle(fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if (price != 0)
                              Text('${price > 0 ? "+" : ""}RM ${price.toStringAsFixed(2)}', style: TextStyle(color: price > 0 ? Colors.green : Colors.red, fontSize: 12)),
                            const SizedBox(width: 8),
                            if (stock != null)
                              Text('Stock: $stock', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 16, color: Colors.grey),
                              onPressed: () => setModalState(() {
                                _tempOptions.removeAt(index);
                                _tempPrices.remove(opt);
                                _tempStock.remove(opt);
                              }),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: _tempOptions.isEmpty || _variationNameController.text.isEmpty ? null : () {
                final variation = ProductVariation(
                  id: existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: _variationNameController.text.trim(),
                  options: _tempOptions,
                  optionPrices: _tempPrices,
                  optionStock: _tempStock.isNotEmpty ? _tempStock : null,
                );
                
                if (index != null) {
                  state.updateVariation(index, variation);
                } else {
                  state.addVariation(variation);
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text('Save Variation'),
            ),
          ],
        ),
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
            'Product Variations',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Define options like size, color, or flavor with specific price adjustments.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Variation Groups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => _showAddVariationDialog(state),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Group'),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (state.productVariations.isEmpty)
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
                  Icon(Icons.style_outlined, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No variations yet.', style: TextStyle(color: Colors.grey)),
                  Text('Add a group like "Color" or "Size".', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.productVariations.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final variation = state.productVariations[index];
                return ExpansionTile(
                  title: Text(variation.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${variation.options.length} options defined'),
                  backgroundColor: Colors.white,
                  collapsedBackgroundColor: Colors.grey.shade50,
                  childrenPadding: const EdgeInsets.all(12),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showAddVariationDialog(state, index: index, existing: variation)),
                      IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.red), onPressed: () => state.removeVariation(index)),
                    ],
                  ),
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: variation.options.map((opt) {
                        final price = variation.optionPrices[opt] ?? 0.0;
                        return Chip(
                          label: Text('$opt ${price != 0 ? "(${price > 0 ? "+" : ""}RM ${price.toStringAsFixed(2)})" : ""}'),
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
