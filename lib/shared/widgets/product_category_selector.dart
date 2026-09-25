import 'package:flutter/material.dart';
import '../models/event/event_category.dart';

class ProductCategorySelector extends StatelessWidget {
  final EventCategory? selectedCategory;
  final ValueChanged<EventCategory?> onChanged;
  final String? labelText;
  final bool showAllOption;

  const ProductCategorySelector({
    super.key,
    this.selectedCategory,
    required this.onChanged,
    this.labelText = 'Category',
    this.showAllOption = false,
  });

  @override
  Widget build(BuildContext context) {
    final categories = EventCategory.values;
    final items = categories.map((category) {
      return DropdownMenuItem<EventCategory>(
        value: category,
        child: Row(
          children: [
            Icon(category.icon, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(category.displayName),
          ],
        ),
      );
    }).toList();

    if (showAllOption) {
      items.insert(0, const DropdownMenuItem<EventCategory>(
        value: null,
        child: Text('All Categories'),
      ));
    }

    return DropdownButtonFormField<EventCategory>(
      value: selectedCategory,
      items: items,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
      ),
      hint: const Text('Select Category'),
    );
  }
}
