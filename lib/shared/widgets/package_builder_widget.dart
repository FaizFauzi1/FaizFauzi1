import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';

class PackageBuilderWidget extends StatefulWidget {
  final List<Vendor> availableVendors;
  final Function(List<String> vendorIds, String packageName, String description)? onCreatePackage;

  const PackageBuilderWidget({
    super.key,
    required this.availableVendors,
    this.onCreatePackage,
  });

  @override
  State<PackageBuilderWidget> createState() => _PackageBuilderWidgetState();
}

class _PackageBuilderWidgetState extends State<PackageBuilderWidget> {
  final List<String> _selectedVendorIds = [];
  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() {
    _packageNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Build Joint Package',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          // Package Details
          TextField(
            controller: _packageNameController,
            decoration: const InputDecoration(
              labelText: 'Package Name',
              hintText: 'e.g., Complete Wedding Package',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Package Description',
              hintText: 'Describe what\'s included in this joint package...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          // Vendor Selection
          const Text(
            'Select Vendors to Include',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.availableVendors.length,
              itemBuilder: (context, index) {
                final vendor = widget.availableVendors[index];
                final isSelected = _selectedVendorIds.contains(vendor.id);

                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (selected) {
                    setState(() {
                      if (selected == true) {
                        _selectedVendorIds.add(vendor.id);
                      } else {
                        _selectedVendorIds.remove(vendor.id);
                      }
                    });
                  },
                  title: Text(
                    vendor.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    '${vendor.category} • ${vendor.location}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  secondary: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      image: vendor.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(vendor.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: vendor.imageUrl == null
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : null,
                    ),
                    child: vendor.imageUrl == null
                        ? Center(
                            child: Text(
                              vendor.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Selected Vendors Summary
          if (_selectedVendorIds.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.group,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_selectedVendorIds.length} vendor${_selectedVendorIds.length == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Create Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canCreatePackage() && !_isCreating ? _createPackage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create Joint Package',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool _canCreatePackage() {
    return _packageNameController.text.trim().isNotEmpty &&
           _descriptionController.text.trim().isNotEmpty &&
           _selectedVendorIds.length >= 2; // Need at least 2 vendors for a joint package
  }

  Future<void> _createPackage() async {
    if (!_canCreatePackage()) return;

    setState(() {
      _isCreating = true;
    });

    try {
      await widget.onCreatePackage?.call(
        _selectedVendorIds,
        _packageNameController.text.trim(),
        _descriptionController.text.trim(),
      );

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Joint package created successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        // Reset form
        _packageNameController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedVendorIds.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create package: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
