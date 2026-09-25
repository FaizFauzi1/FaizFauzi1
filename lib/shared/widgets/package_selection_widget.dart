import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class PackageSelectionWidget extends StatefulWidget {
  final List<Map<String, dynamic>> packages;
  final String selectedPackageId;
  final Function(String) onPackageSelected;
  final bool showAsCards;

  const PackageSelectionWidget({
    super.key,
    required this.packages,
    required this.selectedPackageId,
    required this.onPackageSelected,
    this.showAsCards = true,
  });

  @override
  State<PackageSelectionWidget> createState() => _PackageSelectionWidgetState();
}

class _PackageSelectionWidgetState extends State<PackageSelectionWidget> {
  @override
  Widget build(BuildContext context) {
    if (widget.packages.isEmpty) {
      return const SizedBox.shrink();
    }

    if (widget.showAsCards) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Packages',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.packages.map((package) => _buildPackageCard(package)).toList(),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Package',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...widget.packages.map((package) => _buildPackageOption(package)).toList(),
        ],
      );
    }
  }

  Widget _buildPackageCard(Map<String, dynamic> package) {
    final isSelected = widget.selectedPackageId == package['id']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => widget.onPackageSelected(package['id']?.toString() ?? ''),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(
                  _getPackageIcon(package['name']?.toString() ?? ''),
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      package['name']?.toString() ?? 'Package',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      package['description']?.toString() ?? '',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'RM ${(package['price'] ?? 0).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPackageOption(Map<String, dynamic> package) {
    final isSelected = widget.selectedPackageId == package['id']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
      ),
      child: RadioListTile<String>(
        value: package['id']?.toString() ?? '',
        groupValue: widget.selectedPackageId,
        onChanged: (value) => widget.onPackageSelected(value ?? ''),
        title: Text(
          package['name']?.toString() ?? 'Package',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          package['description']?.toString() ?? '',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        secondary: Text(
          'RM ${(package['price'] ?? 0).toStringAsFixed(0)}',
          style: TextStyle(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  IconData _getPackageIcon(String packageName) {
    final name = packageName.toLowerCase();
    if (name.contains('basic')) return Icons.star_border;
    if (name.contains('standard')) return Icons.star_half;
    if (name.contains('premium')) return Icons.star;
    if (name.contains('luxury')) return Icons.diamond;
    return Icons.inventory;
  }
}
