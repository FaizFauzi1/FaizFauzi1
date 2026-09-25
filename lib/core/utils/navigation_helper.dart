import 'package:flutter/material.dart';
import 'package:eventease/features/vendor/presentation/views/enhanced_service_creation_screen.dart';
import 'package:eventease/features/vendor/presentation/views/product_service_demo_screen.dart';
import 'package:eventease/features/vendor/presentation/views/simple_availability_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_settings_screen_enhanced.dart';
import 'package:eventease/core/utils/integration_guide.dart';
import 'package:eventease/features/auth/presentation/login_screen.dart';

import 'package:eventease/features/vendor/presentation/views/service_creation/service_creation_wizard.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Navigation helper class for all new screens
class NavigationHelper {
  // Navigate to product service demo
  static void navigateToDemo(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProductServiceDemoScreen()),
    );
  }

  // Navigate to service creation
  static void navigateToServiceCreation(BuildContext context, {String? vendorId, VendorService? existingService}) {
    // If no vendorId provided, try to get from current user
    final effectiveVendorId = vendorId ?? Supabase.instance.client.auth.currentUser?.id ?? 'demo-vendor';
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ServiceCreationWizard(
        vendorId: effectiveVendorId,
        existingService: existingService,
      )),
    );
  }

  // Navigate to availability management
  static void navigateToAvailabilityManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SimpleAvailabilityScreen()),
    );
  }

  // Navigate to enhanced settings
  static void navigateToEnhancedSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VendorSettingsScreen()),
    );
  }

  // Navigate to integration examples
  static void navigateToCategoryIntegration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CategoryIntegrationExample()),
    );
  }

  static void navigateToPricingIntegration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PricingIntegrationExample()),
    );
  }

  static void navigateToImageIntegration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ImageIntegrationExample()),
    );
  }

  static void navigateToConflictIntegration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ConflictIntegrationExample()),
    );
  }

  static void navigateToDemoIntegration(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const DemoIntegrationExample()),
    );
  }

  // ========== Auth Navigation Helpers ==========
  
  /// Navigate to login screen with optional return URL
  /// 
  /// Usage:
  /// ```dart
  /// NavigationHelper.navigateToLogin(context, returnUrl: '/vendor/123');
  /// ```
  static Future<T?> navigateToLogin<T>(
    BuildContext context, {
    String? returnUrl,
  }) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(returnUrl: returnUrl),
      ),
    );
  }

  /// Navigate to login and replace current route
  static Future<T?> navigateToLoginReplacement<T>(
    BuildContext context, {
    String? returnUrl,
  }) {
    return Navigator.pushReplacement<T, void>(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(returnUrl: returnUrl),
      ),
    );
  }

  /// Get the current route name from modal route
  static String? getCurrentRoute(BuildContext context) {
    final route = ModalRoute.of(context);
    return route?.settings.name;
  }

  // Show a dialog with all available screens
  static void showScreenSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Product Service Enhancement Screens'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildScreenOption(
                  context,
                  'Product Service Demo',
                  'Complete demo showcasing all components',
                  Icons.store,
                  () => navigateToDemo(context),
                ),
                _buildScreenOption(
                  context,
                  'Service Creation',
                  'Enhanced service creation wizard',
                  Icons.add_business,
                  () => navigateToServiceCreation(context),
                ),
                _buildScreenOption(
                  context,
                  'Availability Management',
                  '2-year availability planning',
                  Icons.calendar_today,
                  () => navigateToAvailabilityManagement(context),
                ),
                const Divider(),
                _buildScreenOption(
                  context,
                  'Category Integration',
                  'Product category selector example',
                  Icons.category,
                  () => navigateToCategoryIntegration(context),
                ),
                _buildScreenOption(
                  context,
                  'Pricing Integration',
                  'Multi-layer pricing widget example',
                  Icons.attach_money,
                  () => navigateToPricingIntegration(context),
                ),
                _buildScreenOption(
                  context,
                  'Image Integration',
                  'Enhanced image management example',
                  Icons.image,
                  () => navigateToImageIntegration(context),
                ),
                _buildScreenOption(
                  context,
                  'Conflict Integration',
                  'Booking conflict detection example',
                  Icons.warning,
                  () => navigateToConflictIntegration(context),
                ),
                _buildScreenOption(
                  context,
                  'Demo Integration',
                  'Complete integration showcase',
                  Icons.integration_instructions,
                  () => navigateToDemoIntegration(context),
                ),
                const Divider(),
                _buildScreenOption(
                  context,
                  'Enhanced Settings',
                  'Advanced settings and preferences',
                  Icons.settings,
                  () => navigateToEnhancedSettings(context),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildScreenOption(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(description),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}
