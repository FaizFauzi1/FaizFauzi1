import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/service_template_models.dart';
import '../../../../shared/models/event/event_category.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'dart:io';

class PackageComponentConfigScreen extends StatefulWidget {
  final ServiceComponent component;
  final EventCategory category;

  const PackageComponentConfigScreen({
    super.key,
    required this.component,
    required this.category,
  });

  @override
  State<PackageComponentConfigScreen> createState() => _PackageComponentConfigScreenState();
}

class _PackageComponentConfigScreenState extends State<PackageComponentConfigScreen> {
  late List<ServiceItem> _items;
  late int _selectionLimit;
  late bool _isOptional;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Create a local copy to modify
    _items = List.from(widget.component.items);
    _selectionLimit = widget.component.selectionLimit;
    _isOptional = widget.component.isOptional;
  }

  void _addItem() {
    setState(() {
      _items.add(ServiceItem(
        name: 'New Item',
        isIncluded: true,
        isOptional: false,
        quantity: 1,
      ));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _pickImage(int index) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _items[index] = _items[index].copyWith(newGalleryFiles: [image]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Configure ${widget.category.displayName}'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: () {
              // Return the updated component
              final updatedComponent = widget.component.copyWith(
                items: _items,
                selectionLimit: _selectionLimit,
                isOptional: _isOptional,
              );
              Navigator.pop(context, updatedComponent);
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGlobalRules(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items & Choices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_items.isEmpty)
              _buildEmptyState()
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) => _buildItemTile(index),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalRules() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selection Rules',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Is this whole category optional?'),
              subtitle: const Text('If enabled, customers can remove the entire category from the package.'),
              value: _isOptional,
              onChanged: (val) => setState(() => _isOptional = val),
            ),
            const Divider(),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selection Limit', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('How many items can a customer pick?', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      hintText: '0',
                      helperText: '0 = All',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) {
                      _selectionLimit = int.tryParse(val) ?? 0;
                    },
                    controller: TextEditingController(text: _selectionLimit == 0 ? '' : _selectionLimit.toString()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No items added yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const Text('Add items that customers can choose from.', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildItemTile(int index) {
    final item = _items[index];
    final hasImage = item.newGalleryFiles != null && item.newGalleryFiles!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Header with Image and Basic Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _pickImage(index),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                      image: hasImage 
                        ? DecorationImage(
                            image: FileImage(File(item.newGalleryFiles!.first.path)),
                            fit: BoxFit.cover,
                          )
                        : null,
                    ),
                    child: !hasImage ? const Icon(Icons.add_a_photo_outlined, color: Colors.grey) : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        decoration: const InputDecoration(labelText: 'Item Name', hintText: 'e.g. Standard Guest Table'),
                        controller: TextEditingController(text: item.name),
                        onChanged: (val) => _items[index] = _items[index].copyWith(name: val),
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: 'Short Description'),
                        controller: TextEditingController(text: item.description),
                        style: const TextStyle(fontSize: 12),
                        onChanged: (val) => _items[index] = _items[index].copyWith(description: val),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Controls Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Included by Default', style: TextStyle(fontSize: 13)),
                        value: item.isIncluded,
                        onChanged: (val) => setState(() => _items[index] = _items[index].copyWith(isIncluded: val ?? true)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Is Optional', style: TextStyle(fontSize: 13)),
                        value: item.isOptional,
                        onChanged: (val) => setState(() => _items[index] = _items[index].copyWith(isOptional: val ?? false)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Is Free', style: TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.bold)),
                        value: item.isFree,
                        onChanged: (val) => setState(() => _items[index] = _items[index].copyWith(isFree: val ?? false)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                    Expanded(
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Conditional Free', style: TextStyle(fontSize: 13, color: Colors.orange)),
                        value: item.isConditionalFree,
                        onChanged: (val) => setState(() => _items[index] = _items[index].copyWith(isConditionalFree: val ?? false)),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ),
                  ],
                ),
                if (item.isConditionalFree) ...[
                  const SizedBox(height: 8),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Free Condition',
                      hintText: 'e.g. Free if pax > 500',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: item.freeCondition),
                    onChanged: (val) => _items[index] = _items[index].copyWith(freeCondition: val),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Price Adjustment: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        enabled: !item.isFree,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixText: 'RM ',
                          isDense: true,
                          border: const OutlineInputBorder(),
                          fillColor: item.isFree ? Colors.grey.shade100 : null,
                          filled: item.isFree,
                        ),
                        controller: TextEditingController(text: item.extraPrice == null ? '' : item.extraPrice.toString()),
                        onChanged: (val) {
                          _items[index] = _items[index].copyWith(extraPrice: double.tryParse(val) ?? 0.0);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.isFree ? 'Item is marked as free.' : 'Use negative for discount (removal credit).',
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
