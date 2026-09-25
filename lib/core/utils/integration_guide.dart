// Integration Guide for EventEase Product Service Enhancement System
// This guide shows how to integrate the new components into existing screens

import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/shared/widgets/product_category_selector.dart';
import 'package:eventease/shared/widgets/category_badge.dart';
import 'package:eventease/shared/widgets/multi_layer_pricing_widget.dart';
import 'package:eventease/shared/widgets/enhanced_image_management_widget.dart';
import 'package:eventease/shared/widgets/simple_conflict_widget.dart';
import 'package:eventease/features/vendor/presentation/views/enhanced_service_creation_screen.dart';
import 'package:eventease/features/vendor/presentation/views/product_service_demo_screen.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:flutter/material.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_availability_management_screen.dart';

// =============================================================================
// 1. INTEGRATING PRODUCT CATEGORY SELECTOR
// =============================================================================

class CategoryIntegrationExample extends StatefulWidget {
  const CategoryIntegrationExample({super.key});

  @override
  State<CategoryIntegrationExample> createState() => _CategoryIntegrationExampleState();
}

class _CategoryIntegrationExampleState extends State<CategoryIntegrationExample> {
  EventCategory? _selectedCategory = EventCategory.catering;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Category Integration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Basic category selector
            ProductCategorySelector(
              selectedCategory: _selectedCategory,
              onChanged: (category) {
                setState(() => _selectedCategory = category);
                print('Selected category: ${category?.displayName ?? 'None'}');
              },
            ),

            const SizedBox(height: 24),

            // Category filter widget - TODO: Implement CategoryFilterWidget
            // CategoryFilterWidget(
            //   selectedCategories: [_selectedCategory],
            //   onSelectionChanged: (categories) {
            //     print('Selected categories: ${categories.map((c) => c.displayName)}');
            //   },
            //   multiSelect: true,
            // ),

            const SizedBox(height: 24),

            // Category badge
            if (_selectedCategory != null)
              CategoryBadge(
                category: ProductCategory.services, // Using a default category for demo
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 2. INTEGRATING MULTI-LAYER PRICING
// =============================================================================

class PricingIntegrationExample extends StatefulWidget {
  const PricingIntegrationExample({super.key});

  @override
  State<PricingIntegrationExample> createState() => _PricingIntegrationExampleState();
}

class _PricingIntegrationExampleState extends State<PricingIntegrationExample> {
  Map<String, dynamic> _pricing = {
    'basic': 299.0,
    'standard': 599.0,
    'premium': 999.0,
    'enterprise': 1999.0,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing Integration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Multi-layer pricing widget
            Expanded(
              child: MultiLayerPricingWidget(
                initialPricing: _pricing,
                onPricingChanged: (pricing) {
                  print('Pricing updated: $pricing');
                  // Save to service model here
                },
              ),
            ),

            const SizedBox(height: 16),

            // Quick pricing templates
            QuickPricingTemplateWidget(
              onTemplateApplied: (template) {
                print('Template applied: $template');
                // Update pricing here
                setState(() {
                  _pricing = Map<String, dynamic>.from(template);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 3. INTEGRATING ENHANCED IMAGE MANAGEMENT
// =============================================================================

class ImageIntegrationExample extends StatefulWidget {
  const ImageIntegrationExample({super.key});

  @override
  State<ImageIntegrationExample> createState() => _ImageIntegrationExampleState();
}

class _ImageIntegrationExampleState extends State<ImageIntegrationExample> {
  final List<String> _images = [
    'https://via.placeholder.com/300x200?text=Service+1',
    'https://via.placeholder.com/300x200?text=Service+2',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Integration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: EnhancedImageManagementWidget(
          initialImages: _images,
          onImagesChanged: (images) {
            print('Images updated: ${images.length} images');
            // Save to service model here
          },
          maxImages: 10,
          allowReordering: true,
        ),
      ),
    );
  }
}

// =============================================================================
// 4. INTEGRATING CONFLICT DETECTION
// =============================================================================

class ConflictIntegrationExample extends StatefulWidget {
  const ConflictIntegrationExample({super.key});

  @override
  State<ConflictIntegrationExample> createState() => _ConflictIntegrationExampleState();
}

class _ConflictIntegrationExampleState extends State<ConflictIntegrationExample> {
  final List<String> _sampleConflicts = [
    'Double booking detected for 2:00 PM slot',
    'Service unavailable on selected date',
    'Maximum daily bookings exceeded',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conflict Integration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Conflict resolution widget
            SimpleConflictWidget(
              conflicts: _sampleConflicts,
              onResolve: () {
                print('User wants to resolve conflicts');
                // Navigate to conflict resolution screen
              },
              onIgnore: () {
                print('User wants to proceed anyway');
                // Proceed with booking
              },
            ),

            const SizedBox(height: 24),

            // Automated booking widget
            Expanded(
              child: AutomatedBookingWidget(
                onSlotSelected: (dateTime, timeSlot) {
                  print('Selected slot: $timeSlot on ${dateTime.toString().split(' ')[0]}');
                  // Create booking here
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// 5. INTEGRATING SERVICE CREATION WIZARD
// =============================================================================

class ServiceCreationIntegrationExample extends StatelessWidget {
  const ServiceCreationIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Creation')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EnhancedServiceCreationScreen(vendorId: 'demo-vendor'),
              ),
            );
          },
          child: const Text('Create New Service'),
        ),
      ),
    );
  }
}

// =============================================================================
// 6. INTEGRATING DEMO SCREEN
// =============================================================================

class DemoIntegrationExample extends StatelessWidget {
  const DemoIntegrationExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demo Screen')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProductServiceDemoScreen(),
              ),
            );
          },
          child: const Text('View All Components Demo'),
        ),
      ),
    );
  }
}

// =============================================================================
// 7. UPDATING EXISTING VENDOR SCREENS
// =============================================================================

// Example: Updating vendor services screen to use new components
class UpdatedVendorServicesScreen extends StatefulWidget {
  const UpdatedVendorServicesScreen({super.key});

  @override
  State<UpdatedVendorServicesScreen> createState() => _UpdatedVendorServicesScreenState();
}

class _UpdatedVendorServicesScreenState extends State<UpdatedVendorServicesScreen> {
  final List<VendorServiceEnhanced> _services = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Services'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EnhancedServiceCreationScreen(vendorId: 'demo-vendor'),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _services.length,
        itemBuilder: (context, index) {
          final service = _services[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              leading: Icon(service.productCategory.icon, size: 32),
              title: Text(service.name),
              subtitle: Text(
                '${service.productCategory.displayName} • RM ${service.price.toStringAsFixed(2)}',
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit Service'),
                  ),
                  const PopupMenuItem(
                    value: 'availability',
                    child: Text('Manage Availability'),
                  ),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                      builder: (context) => EnhancedServiceCreationScreen(
                        existingService: service,
                        vendorId: 'demo-vendor',
                      ),
                        ),
                      );
                      break;
                    case 'availability':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VendorAvailabilityManagementScreen(
                            service: service,
                          ),
                        ),
                      );
                      break;
                  }
                },
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductServiceDemoScreen(),
            ),
          );
        },
        child: const Icon(Icons.preview),
        tooltip: 'View Demo',
      ),
    );
  }
}

// =============================================================================
// 8. USAGE EXAMPLES FOR DIFFERENT SERVICE TYPES
// =============================================================================

class ServiceTypeExamples {
  // Example 1: Venue Rental Service
  static VendorServiceEnhanced createVenueService() {
    return VendorServiceEnhanced(
      id: 'venue_001',
      vendorId: 'vendor_123',
      name: 'Grand Ballroom',
      description: 'Elegant ballroom perfect for weddings and corporate events',
      productCategory: EventCategory.venue, // Using venue category
      price: 5000.0,
      isActive: true,
      availability: {
        'monday': {'start': '08:00', 'end': '23:00', 'available': true},
        'tuesday': {'start': '08:00', 'end': '23:00', 'available': true},
        'wednesday': {'start': '08:00', 'end': '23:00', 'available': true},
      },
      extendedAvailability: {},
      unavailablePeriods: [],
      maxBookingsPerDay: 3,
      advanceBookingDays: 365,
      serviceTypes: [ServiceType.package],
      images: [],
      options: {
        'capacity': '300 guests',
        'size': '500 sqm',
        'amenities': ['Sound System', 'Lighting', 'Tables & Chairs'],
      },
      inventory: 0,
      logistics: {
        'setup_time': '2 hours',
        'parking': 'Available',
        'accessibility': 'Wheelchair accessible',
      },
      multiLayerPricing: {
        'basic': 3000.0,
        'standard': 5000.0,
        'premium': 8000.0,
        'enterprise': 12000.0,
      },
      status: ServiceStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Example 2: Equipment Rental Service
  static VendorServiceEnhanced createEquipmentService() {
    return VendorServiceEnhanced(
      id: 'equipment_001',
      vendorId: 'vendor_123',
      name: 'Professional Camera Kit',
      description: 'High-end camera equipment for professional photography',
      productCategory: EventCategory.equipment,
      price: 500.0,
      isActive: true,
      availability: {
        'monday': {'start': '09:00', 'end': '18:00', 'available': true},
        'tuesday': {'start': '09:00', 'end': '18:00', 'available': true},
      },
      extendedAvailability: {},
      unavailablePeriods: [],
      maxBookingsPerDay: 5,
      advanceBookingDays: 30,
      serviceTypes: [ServiceType.rental],
      images: [],
      options: {
        'camera_model': 'Canon EOS R5',
        'lenses': '24-70mm, 70-200mm',
        'accessories': 'Tripod, Memory Cards, Batteries',
      },
      inventory: 0,
      logistics: {
        'delivery': 'Available',
        'pickup': 'Required',
        'insurance': 'Included',
      },
      multiLayerPricing: {
        'basic': 300.0,
        'standard': 500.0,
        'premium': 800.0,
        'enterprise': 1200.0,
      },
      status: ServiceStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  // Example 3: Service Provider
  static VendorServiceEnhanced createServiceProvider() {
    return VendorServiceEnhanced(
      id: 'service_001',
      vendorId: 'vendor_123',
      name: 'Wedding Catering Service',
      description: 'Professional catering for weddings and special events',
      productCategory: EventCategory.catering,
      price: 150.0,
      isActive: true,
      availability: {
        'friday': {'start': '10:00', 'end': '22:00', 'available': true},
        'saturday': {'start': '10:00', 'end': '22:00', 'available': true},
        'sunday': {'start': '10:00', 'end': '22:00', 'available': true},
      },
      extendedAvailability: {},
      unavailablePeriods: [],
      maxBookingsPerDay: 2,
      advanceBookingDays: 180,
      serviceTypes: [ServiceType.consultation],
      images: [],
      options: {
        'cuisine': 'Malaysian, Western, Fusion',
        'dietary': 'Halal, Vegetarian, Vegan options',
        'staff': 'Professional chefs and servers',
      },
      inventory: 0,
      logistics: {
        'setup_time': '3 hours',
        'equipment': 'Provided',
        'cleanup': 'Included',
      },
      multiLayerPricing: {
        'basic': 100.0,
        'standard': 150.0,
        'premium': 250.0,
        'enterprise': 400.0,
      },
      status: ServiceStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

// =============================================================================
// 9. NAVIGATION SETUP
// =============================================================================

class NavigationHelper {
  // Add new routes to your app's router
  static Map<String, WidgetBuilder> getProductServiceRoutes() {
    return {
      '/product-service-demo': (context) => const ProductServiceDemoScreen(),
      '/enhanced-service-creation': (context) => EnhancedServiceCreationScreen(vendorId: 'demo-vendor'),
      '/category-integration': (context) => const CategoryIntegrationExample(),
      '/pricing-integration': (context) => const PricingIntegrationExample(),
      '/image-integration': (context) => const ImageIntegrationExample(),
      '/conflict-integration': (context) => const ConflictIntegrationExample(),
    };
  }

  // Update existing vendor menu to include new features
  static List<MenuItem> getVendorMenuItems() {
    return [
      MenuItem(
        title: 'My Services',
        icon: Icons.business,
        route: '/vendor-services',
        badge: 'Enhanced',
      ),
      MenuItem(
        title: 'Create Service',
        icon: Icons.add_business,
        route: '/enhanced-service-creation',
        badge: 'New',
      ),
      MenuItem(
        title: 'Product Categories',
        icon: Icons.category,
        route: '/category-integration',
      ),
      MenuItem(
        title: 'Pricing Management',
        icon: Icons.attach_money,
        route: '/pricing-integration',
      ),
      MenuItem(
        title: 'Demo Components',
        icon: Icons.preview,
        route: '/product-service-demo',
      ),
    ];
  }
}

class MenuItem {
  final String title;
  final IconData icon;
  final String route;
  final String? badge;

  MenuItem({
    required this.title,
    required this.icon,
    required this.route,
    this.badge,
  });
}

// =============================================================================
// 10. DATA MIGRATION HELPER
// =============================================================================

class DataMigrationHelper {
  // Helper to migrate existing services to new format
  static VendorServiceEnhanced migrateLegacyService(
    Map<String, dynamic> legacyService,
  ) {
    return VendorServiceEnhanced(
      id: legacyService['id'] ?? '',
      vendorId: legacyService['vendorId'] ?? '',
      name: legacyService['name'] ?? '',
      description: legacyService['description'] ?? '',
      productCategory: _mapLegacyCategory(legacyService['category'] ?? ''),
      price: (legacyService['price'] ?? 0.0).toDouble(),
      isActive: legacyService['active'] ?? true,
      availability: legacyService['availability'] ?? {},
      extendedAvailability: {},
      unavailablePeriods: [],
      maxBookingsPerDay: legacyService['maxBookingsPerDay'] ?? 10,
      advanceBookingDays: legacyService['advanceBookingDays'] ?? 365,
      serviceTypes: [_mapLegacyServiceType(legacyService['type'] ?? 'package')],
      images: List<String>.from(legacyService['images'] ?? []),
      options: legacyService['options'] ?? {},
      inventory: 0,
      logistics: legacyService['logistics'] ?? {},
      multiLayerPricing: {
        'basic': legacyService['price'] ?? 0.0,
        'standard': (legacyService['price'] ?? 0.0) * 1.5,
        'premium': (legacyService['price'] ?? 0.0) * 2.0,
        'enterprise': (legacyService['price'] ?? 0.0) * 3.0,
      },
      status: ServiceStatus.active,
      createdAt: DateTime.tryParse(legacyService['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static EventCategory _mapLegacyCategory(String legacyCategory) {
    final category = legacyCategory.toLowerCase();
    if (category.contains('venue') || category.contains('hall')) {
      return EventCategory.venue;
    } else if (category.contains('equipment') || category.contains('gear')) {
      return EventCategory.equipment;
    } else if (category.contains('catering') || category.contains('food')) {
      return EventCategory.catering;
    } else if (category.contains('fashion') || category.contains('clothing')) {
      return EventCategory.fashion;
    } else {
      return EventCategory.package;
    }
  }

  static ServiceType _mapLegacyServiceType(String legacyType) {
    switch (legacyType.toLowerCase()) {
      case 'equipment':
        return ServiceType.rental;
      case 'service':
        return ServiceType.consultation;
      case 'package':
      default:
        return ServiceType.package;
    }
  }
}
