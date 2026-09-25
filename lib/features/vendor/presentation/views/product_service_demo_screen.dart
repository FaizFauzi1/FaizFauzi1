import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/widgets/product_category_selector.dart';
import 'package:eventease/shared/widgets/category_badge.dart';
import 'package:eventease/shared/widgets/multi_layer_pricing_widget.dart' hide QuickPricingTemplateWidget;
import 'package:eventease/shared/widgets/enhanced_image_management_widget.dart';
import 'package:eventease/shared/widgets/quick_pricing_template_widget.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_availability_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/enhanced_service_creation_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';

class ProductServiceDemoScreen extends StatefulWidget {
  const ProductServiceDemoScreen({super.key});

  @override
  State<ProductServiceDemoScreen> createState() => _ProductServiceDemoScreenState();
}

class _ProductServiceDemoScreenState extends State<ProductServiceDemoScreen> {
  int _currentDemoIndex = 0;
  final List<String> _demoTitles = [
    'Product Categories',
    'Multi-Layer Pricing',
    'Image Management',
    'Availability Management',
    'Service Creation',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Product Service Demo',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Demo selector
          Container(
            height: 60,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _demoTitles.length,
              itemBuilder: (context, index) {
                return _buildDemoTab(index);
              },
            ),
          ),

          // Demo content
          Expanded(
            child: _buildDemoContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoTab(int index) {
    final isSelected = _currentDemoIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentDemoIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            _demoTitles[index],
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoContent() {
    switch (_currentDemoIndex) {
      case 0:
        return _buildCategoryDemo();
      case 1:
        return _buildPricingDemo();
      case 2:
        return _buildImageDemo();
      case 3:
        return _buildAvailabilityDemo();
      case 4:
        return _buildServiceCreationDemo();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCategoryDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Category Selection',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select appropriate categories for your rental services',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ProductCategorySelector(
            selectedCategory: null,
            onChanged: (category) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Selected category: ${category?.displayName ?? 'None'}'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
          ),
          // TODO: Implement CategoryFilterWidget
          // const SizedBox(height: 24),
          // Text(
          //   'Category Filter Widget',
          //   style: TextStyle(
          //     fontSize: 16,
          //     fontWeight: FontWeight.w600,
          //     color: AppTheme.textPrimaryColor,
          //   ),
          // ),
          // const SizedBox(height: 16),
          // CategoryFilterWidget(
          //   selectedCategories: [ProductCategory.homeGarden, ProductCategory.services],
          //   onSelectionChanged: (categories) {
          //     ScaffoldMessenger.of(context).showSnackBar(
          //       SnackBar(
          //         content: Text('Selected ${categories.length} categories'),
          //         backgroundColor: AppTheme.primaryColor,
          //       ),
          //     );
          //   },
          //   multiSelect: true,
          // ),
        ],
      ),
    );
  }

  Widget _buildPricingDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Multi-Layer Pricing System',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set different pricing tiers for your services',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          MultiLayerPricingWidget(
            initialPricing: {
              'basic': 299.0,
              'standard': 599.0,
              'premium': 999.0,
              'enterprise': 1999.0,
            },
            onPricingChanged: (pricing) {
              print('Pricing updated: $pricing');
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Quick Pricing Templates',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          QuickPricingTemplateWidget(
            onTemplateApplied: (template) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Applied pricing template'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enhanced Image Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Upload and manage images for your services',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          EnhancedImageManagementWidget(
            initialImages: [
              'https://via.placeholder.com/300x200?text=Venue+1',
              'https://via.placeholder.com/300x200?text=Venue+2',
            ],
            onImagesChanged: (images) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Images updated: ${images.length} images'),
                  backgroundColor: AppTheme.primaryColor,
                ),
              );
            },
            maxImages: 5,
            allowReordering: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityDemo() {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final services = vendorProvider.allServices;
    if (services.isEmpty) {
      return const Center(child: Text('No services found for demo'));
    }
    final sampleService = services.first;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Availability Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your service availability for up to 2 years',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VendorAvailabilityManagementScreen(
                        service: sampleService,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Open Demo'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Availability management screen will open when you tap "Open Demo"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceCreationDemo() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Creation Wizard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create new services with step-by-step guidance',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
              MaterialPageRoute(
                      builder: (context) => EnhancedServiceCreationScreen(vendorId: 'demo-vendor'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Create Service'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Service creation wizard will open when you tap "Create Service"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
