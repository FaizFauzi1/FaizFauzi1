import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/shared/models/services/service_category.dart';
import 'package:eventease/shared/widgets/event_type_category_selector.dart';
import 'package:eventease/shared/widgets/category_pricing_input.dart';
import 'package:eventease/shared/providers/category_provider.dart';

/// Example integration of the new category system into service creation
/// 
/// This shows how to use EventTypeCategorySelector and CategoryPricingInput
/// in your existing EnhancedServiceCreationScreen
class ServiceCreationIntegrationExample extends StatefulWidget {
  const ServiceCreationIntegrationExample({Key? key}) : super(key: key);

  @override
  State<ServiceCreationIntegrationExample> createState() =>
      _ServiceCreationIntegrationExampleState();
}

class _ServiceCreationIntegrationExampleState
    extends State<ServiceCreationIntegrationExample> {
  final _formKey = GlobalKey<FormState>();
  
  // Event Type & Category Selection
  List<String> _selectedEventTypeIds = [];
  ServiceCategory? _selectedCategory;
  
  // Pricing
  double? _basePrice;
  
  // Service Details
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // Vendor Info (would come from VendorProvider in real implementation)
  bool _isVerified = false;
  VendorTier _vendorTier = VendorTier.basic;
  String? _verificationStatus;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Service'),
        actions: [
          TextButton(
            onPressed: _saveService,
            child: const Text(
              'SAVE',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // STEP 1 & 2: Event Type and Category Selection
            EventTypeCategorySelector(
              selectedEventTypeIds: _selectedEventTypeIds,
              selectedCategoryId: _selectedCategory?.id,
              onEventTypesChanged: (eventTypeIds) {
                setState(() {
                  _selectedEventTypeIds = eventTypeIds;
                  // Reset category when event types change
                  _selectedCategory = null;
                  _basePrice = null;
                });
              },
              onCategoryChanged: (category) {
                setState(() {
                  _selectedCategory = category;
                  _basePrice = null; // Reset price when category changes
                });
              },
              isVerified: _isVerified,
              vendorTier: _vendorTier,
              verificationStatus: _verificationStatus,
            ),

            // Only show remaining fields if category is selected
            if (_selectedCategory != null) ...[
              const SizedBox(height: 24),

              // STEP 3: Service Details
              _buildServiceDetailsSection(),

              const SizedBox(height: 24),

              // STEP 4: Pricing (Dynamic based on category)
              CategoryPricingInput(
                category: _selectedCategory!,
                basePrice: _basePrice,
                onPriceChanged: (price) {
                  setState(() => _basePrice = price);
                },
              ),

              const SizedBox(height: 24),

              // STEP 5: Additional fields based on category type
              _buildCategorySpecificFields(),

              const SizedBox(height: 32),

              // Preview
              if (_basePrice != null) ...[
                PricingPreview(
                  category: _selectedCategory!,
                  basePrice: _basePrice!,
                  quantity: 100, // Example quantity
                ),
                const SizedBox(height: 32),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildServiceDetailsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Step 3: Service Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Service Name',
                hintText: 'e.g., Premium Wedding Photography Package',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a service name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your service in detail...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySpecificFields() {
    // Show different fields based on category type
    switch (_selectedCategory!.categoryType) {
      case CategoryType.service:
        return _buildServiceTypeFields();
      case CategoryType.product:
        return _buildProductTypeFields();
      case CategoryType.package:
        return _buildPackageTypeFields();
      case CategoryType.rental:
        return _buildRentalTypeFields();
    }
  }

  Widget _buildServiceTypeFields() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Add service-specific fields here
            // e.g., availability, duration, team size, etc.
            const Text('Service-specific fields would go here'),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTypeFields() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Add product-specific fields here
            // e.g., stock quantity, variations, shipping, etc.
            const Text('Product-specific fields would go here'),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageTypeFields() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Package Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Add package-specific fields here
            // e.g., included services, tiers, customization options, etc.
            const Text('Package-specific fields would go here'),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalTypeFields() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rental Configuration',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Add rental-specific fields here
            // e.g., rental period, deposit, condition, delivery, etc.
            const Text('Rental-specific fields would go here'),
          ],
        ),
      ),
    );
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedEventTypeIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one event type')),
      );
      return;
    }

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    if (_basePrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a price')),
      );
      return;
    }

    // Prepare service data
    final serviceData = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'category_id': _selectedCategory!.id,
      'event_types': _selectedEventTypeIds,
      'base_price': _basePrice,
      'pricing_model': _selectedCategory!.pricingModel.value,
      'category_type': _selectedCategory!.categoryType.value,
      // Add more fields as needed
    };

    // TODO: Save to Supabase via VendorProvider
    debugPrint('Saving service: $serviceData');

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service created successfully!')),
      );
      Navigator.pop(context);
    }
  }
}
