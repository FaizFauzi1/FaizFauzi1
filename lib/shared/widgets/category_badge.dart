import 'package:flutter/material.dart';

enum ProductCategory {
  homeGarden('Home & Garden', Colors.green, Icons.home),
  electronics('Electronics', Colors.blue, Icons.devices),
  foodBeverage('Food & Beverage', Colors.orange, Icons.restaurant),
  fashion('Fashion', Colors.pink, Icons.checkroom),
  services('Services', Colors.purple, Icons.build);

  const ProductCategory(this.displayName, this.color, this.icon);

  final String displayName;
  final Color color;
  final IconData icon;
}

class CategoryBadge extends StatelessWidget {
  final ProductCategory category;
  final double? fontSize;

  const CategoryBadge({
    super.key,
    required this.category,
    this.fontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: category.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(category.icon, size: fontSize! + 2, color: category.color),
          const SizedBox(width: 4),
          Text(
            category.displayName,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              color: category.color,
            ),
          ),
        ],
      ),
    );
  }
}
