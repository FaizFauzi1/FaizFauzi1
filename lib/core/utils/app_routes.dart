import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';

import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/event/data/models/event_schedule_item.dart';
import 'package:eventease/features/guest/data/models/guest.dart';
import 'package:eventease/features/event/data/models/invitation.dart';
import 'package:eventease/shared/models/photo_album.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_services_hub_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_packages_hub_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_service_creator_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/collaborative_package_builder_screen.dart';
import 'package:eventease/features/vendor/presentation/views/workflow/vendor_unified_calendar_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/customer_package_customization_screen.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';
import 'package:eventease/features/customer/presentation/views/customer/product_detail_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/wedding_marketplace_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/compare_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/order_status_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/checkout_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/order_confirmation_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/my_orders_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/vendor_profile_screen.dart';
import 'package:eventease/features/customer/presentation/views/account/customer_subscription_screen.dart';
import 'package:eventease/features/booking/data/models/order.dart';
import 'package:eventease/core/utils/integration_guide.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_crm_dashboard_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_marketplace_review_screen.dart';
import 'package:eventease/features/booking/presentation/views/appointments/appointment_management_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/customer_request_management_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/customer_request_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/event_creation_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/event_edit_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/event_management_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/favorites_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/gift_management_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/guest_list_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/event_wishes_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/event_planning_hub_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/planner_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/event_countdown_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/event_collaboration_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/shop_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/real_events_gallery_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/host_rsvp_analytics_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/seller_profile_screen.dart';
import 'package:eventease/features/guest/presentation/views/guest/e_ticket_screen.dart';
import 'package:eventease/features/guest/presentation/views/guest/event_code_entry_screen.dart';
import 'package:eventease/features/guest/presentation/views/guest/event_details_screen.dart';
import 'package:eventease/features/guest/presentation/views/guest/event_map_screen.dart';
import 'package:eventease/features/guest/presentation/views/guest/event_schedule_screen.dart';
import 'package:eventease/features/guest/presentation/views/guest/gift_registry_screen.dart';
import 'package:eventease/features/guest/presentation/views/guest/guest_chat_screen_fixed.dart';
import 'package:eventease/features/guest/presentation/views/guest/guest_dashboard_screen.dart';
import 'package:eventease/features/guest/presentation/views/guest/invitation_view_screen.dart';
import 'package:eventease/features/guest/presentation/views/guest/meal_preferences_screen.dart';
import 'package:eventease/features/guest/presentation/views/guest/photo_sharing_screen_fixed.dart';
import 'package:eventease/features/guest/presentation/views/guest/rsvp_screen.dart';
import 'package:eventease/features/guest/presentation/views/guest/seating_assignment_screen.dart';
import 'package:eventease/features/gift_registry/presentation/views/registry_management_screen.dart';
import 'package:eventease/features/customer/presentation/views/home/home_screen.dart';
import 'package:eventease/features/chat/presentation/views/messages/messages_screen.dart';
import 'package:eventease/features/booking/presentation/views/rentals/rental_management_screen.dart';
import 'package:eventease/shared/views/splash_screen.dart';
import 'package:eventease/features/vendor/presentation/views/crm_dashboard_screen.dart';
import 'package:eventease/features/vendor/presentation/views/enhanced_service_creation_screen.dart';
import 'package:eventease/features/vendor/presentation/views/service_creation/service_creation_wizard.dart';
import 'package:eventease/features/vendor/presentation/views/product_service_demo_screen.dart';
import 'package:eventease/features/vendor/presentation/views/simple_availability_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_analytics_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_booking_management_screen_fixed.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_booking_status_update_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_customer_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_dashboard_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_finance_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_help_center_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_inventory_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_loyalty_programs_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_marketing_screen_fixed.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_networking_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_find_partners_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_collaboration_requests_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_package_builder_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_groups_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_marketplace_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_request_management_screen.dart';
import 'package:eventease/features/notifications/presentation/views/notification_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_notification_center_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_payment_payout_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_promotions_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_reports_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_request_management_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_services_screen_enhanced.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_settings_screen_enhanced.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_shop_performance_screen_final.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_social_media_manager_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_subscriptions_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_support_tickets_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/qr_scanner_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_qr_code_screen.dart';
import 'package:eventease/shared/views/privacy_policy_screen.dart';
import 'package:eventease/shared/views/terms_of_service_screen.dart';
import 'package:eventease/features/customer/presentation/views/account/about_screen.dart';
import 'package:eventease/features/blog/presentation/views/blog_screen.dart';
import 'package:eventease/features/blog/presentation/views/blog_detail_screen.dart';
import 'package:eventease/features/organizer/organizer_routes.dart';
// Debug-only imports: gallery screens are only compiled in debug builds
// ignore: unused_import
import 'package:eventease/debug/vendor_screens_gallery_screen.dart';
// ignore: unused_import
import 'package:eventease/debug/organizer_screens_gallery_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_join_exhibitor_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_expo_detail_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_exhibitor_apply_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_application_status_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_exhibitor_payment_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_exhibition_dashboard_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_floor_plan_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_requirements_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_staff_passes_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_post_event_screen.dart';
import 'package:eventease/features/organizer/data/models/expo_summary.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/referral/presentation/views/referral_home_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/referral_management_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/search_screen.dart';
import 'package:eventease/features/customer/presentation/views/account/settings_screen.dart';
import 'package:eventease/features/customer/presentation/views/account/account_screen.dart';
import 'package:eventease/features/quotes/presentation/proposal_builder_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_lead_kanban_screen.dart';
import 'package:eventease/features/mood_board/presentation/mood_board_screen.dart';
import 'package:eventease/features/ai_matchmaker/presentation/ai_matchmaker_screen.dart';
import 'package:eventease/features/contracts/presentation/contract_detail_screen.dart';
import 'package:eventease/features/photo_delivery/presentation/photo_delivery_portal_screen.dart';
import 'package:eventease/shared/views/help_center_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_broadcast_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/anti_bypass_dashboard_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_revenue_dashboard_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_churn_dashboard_screen.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_dispute_detail_screen.dart';

// Create default instances for screens that require parameters
Vendor _getDefaultVendor() {
  return Vendor(
    id: 'default_vendor',
    name: 'Default Vendor',
    categories: ['Catering'],
    subcategories: ['Wedding Catering', 'Corporate Events'],
    description: 'Default vendor for testing purposes',
    location: 'Kuala Lumpur, Malaysia',
    images: ['https://via.placeholder.com/300x200?text=Default+Vendor'],
    rating: 4.5,
    reviewCount: 100,
    status: VendorStatus.approved,
    documents: {
      'businessLicense': 'approved',
      'halalCertificate': 'approved',
    },
    subscriptionTier: SubscriptionTier.premium,
    logistics: {
      'deliveryRadius': '50km',
      'setupIncluded': true,
    },
    contactInfo: {
      'phone': '+60123456789',
      'email': 'default@vendor.com',
    },
    sampleServiceIds: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Booking _getDefaultBooking() {
  return Booking(
    id: 'default_booking',
    customerId: 'customer_sample',
    vendorId: 'default_vendor',
    serviceId: 'default_service',
    serviceName: 'Default Service',
    customerName: 'Default Customer',
    customerPhone: '+60123456789',
    customerEmail: 'customer@example.com',
    bookingDate: DateTime.now().add(const Duration(days: 7)),
    bookingTime: const TimeOfDay(hour: 14, minute: 0),
    duration: '4 hours',
    packageName: 'Premium Package',
    amount: 5000.0,
    location: 'Default Location',
    notes: 'Default booking for testing',
    status: BookingStatus.pending,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

  // Define all app routes
  Map<String, WidgetBuilder> getAppRoutes() {
    final defaultVendor = _getDefaultVendor();
    final defaultBooking = _getDefaultBooking();

    return {
      ...getOrganizerRoutes(),
      // Debug-only routes: gallery screens are restricted to debug builds
      if (kDebugMode)
        OrganizerScreensGalleryScreen.routeName: (context) =>
            const OrganizerScreensGalleryScreen(),
      if (kDebugMode)
        VendorScreensGalleryScreen.routeName: (context) =>
            const VendorScreensGalleryScreen(),
      // Existing routes (keeping them for backward compatibility)
      '/home': (context) => const HomeScreen(), // You may want to change this to actual home screen
      '/scan-qr': (context) => const QRScannerScreen(),
      '/search': (context) => const SearchScreen(),
      '/bookings': (context) => const SplashScreen(), // Placeholder
      '/favorites': (context) => const CustomerFavoritesScreen(),
      '/profile': (context) => const AccountScreen(),
      '/settings': (context) => const SettingsScreen(),

      // Added shop screen route
      '/shop': (context) => const CustomerShopScreen(),
      '/wedding-marketplace': (context) => const WeddingMarketplaceScreen(),
      '/real-events': (context) => const RealEventsGalleryScreen(),
      '/host-rsvp-analytics': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return HostRSVPAnalyticsScreen(
          eventId: args?['eventId'] ?? 'EVT-9021',
          eventTitle: args?['eventTitle'] ?? 'Sarah & Danial Wedding Celebration',
        );
      },
      '/seller-profile': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return SellerProfileScreen(
          sellerId: args?['sellerId'] ?? '',
          sellerName: args?['sellerName'] ?? 'Wedding Seller',
        );
      },
      '/compare': (context) => const CompareScreen(),
      '/about': (context) => const AboutScreen(),
      '/privacy-policy': (context) => const PrivacyPolicyScreen(),
      '/terms-of-service': (context) => const TermsOfServiceScreen(),
      '/blog': (context) => const BlogScreen(),
      '/blog-detail': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is String) {
          return BlogDetailScreen(slug: args);
        }
        return const SplashScreen(); // Fallback
      },

      // Networking route
      '/networking': (context) => const VendorNetworkingScreen(),
      '/find-partners': (context) => const VendorNetworkingScreen(),
      '/collaboration-requests': (context) => const VendorNetworkingScreen(),
      '/package-builder': (context) => const VendorPackageBuilderScreen(),
      '/vendor-groups': (context) => const VendorNetworkingScreen(),
      '/marketplace': (context) => const VendorMarketplaceScreen(),

      // Customer request routes
      '/customer-request': (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        final user = Supabase.instance.client.auth.currentUser;
        return CustomerRequestScreen(
          customerId: args?['customerId'] ?? user?.id ?? '',
          customerName: args?['customerName'] ?? user?.userMetadata?['full_name'] ?? 'Customer',
          existingRequest: args?['existingRequest'],
        );
      },
      '/customer-request-management': (context) {
          final user = Supabase.instance.client.auth.currentUser;
          return CustomerRequestManagementScreen(
            customerId: user?.id ?? '',
          );
      },

      // Vendor routes - Main screens
      '/vendor-dashboard': (context) => const VendorDashboardScreen(),
      '/vendor-services': (context) => const VendorServicesScreenEnhanced(),
      '/vendor-booking-management': (context) => VendorBookingManagementScreenFixed(vendor: defaultVendor),
      '/vendor-finance': (context) => const VendorFinanceScreen(),
      '/vendor-lead-kanban': (context) => const VendorLeadKanbanScreen(),
      '/proposal-builder': (context) => const ProposalBuilderScreen(),
      '/mood-boards': (context) => const MoodBoardScreen(),
      '/ai-matchmaker': (context) => const AiMatchmakerScreen(),
      '/contracts': (context) => const ContractDetailScreen(),
      '/photo-delivery': (context) => const PhotoDeliveryPortalScreen(),
      '/help-center': (context) => const HelpCenterScreen(),
      '/admin/anti-bypass': (context) => const AntiBypassDashboardScreen(),
      '/admin/revenue': (context) => const AdminRevenueDashboardScreen(),
      '/admin/churn': (context) => const AdminChurnDashboardScreen(),
      '/admin/broadcast': (context) => const AdminBroadcastScreen(),
      '/admin/dispute-detail': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return AdminDisputeDetailScreen(disputeId: args?['disputeId'] ?? '');
      },
      '/vendor-shop-performance': (context) => const VendorShopPerformanceScreen(),
      '/vendor-marketing': (context) => const VendorMarketingScreen(),
      ReferralHomeScreen.routeName: (context) => const ReferralHomeScreen(),
      '/admin/referrals': (context) => const ReferralManagementScreen(),
      '/vendor-notifications': (context) => const NotificationScreen(),
      '/notifications': (context) => const NotificationScreen(),
      '/admin-control-tower': (context) => const AdminNotificationCenterScreen(),
      '/vendor-settings': (context) => const VendorSettingsScreen(),
      '/vendor-payment-payout': (context) => const VendorPaymentPayoutScreen(),
      '/vendor-booking-status': (context) => VendorBookingStatusUpdateScreen(booking: defaultBooking),
      '/vendor-social-media': (context) => const VendorSocialMediaManagerScreen(),

      // Vendor routes - Additional screens
      '/vendor-products': (context) => const VendorDashboardScreen(), // Using dashboard as placeholder
      '/vendor-campaigns': (context) => const VendorMarketingScreen(),
      '/vendor-reports': (context) => const VendorReportsScreen(),
      '/vendor-transactions': (context) => const VendorFinanceScreen(),
      '/vendor-analytics': (context) => const VendorAnalyticsScreen(),
      '/vendor-inventory': (context) => const VendorInventoryManagementScreen(),
      '/vendor-customers': (context) => const VendorCustomerManagementScreen(),
      '/crm-dashboard': (context) => const CrmDashboardScreen(),
      '/admin-crm-dashboard': (context) => const AdminCrmDashboardScreen(),
      '/vendor-promotions': (context) => const VendorPromotionsScreen(),
      '/vendor-loyalty': (context) => const VendorLoyaltyProgramsScreen(),
      '/vendor-subscriptions': (context) => const VendorSubscriptionsScreen(),
      '/vendor-support': (context) => const VendorSupportTicketsScreen(),
      '/vendor-help': (context) => const VendorHelpCenterScreen(),
      '/vendor-request-management': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final vendor = Provider.of<VendorProvider>(context, listen: false).currentVendor;
        return VendorRequestManagementScreen(
          vendorId: args?['vendorId'] as String? ?? vendor?.id ?? '',
          vendorName: args?['vendorName'] as String? ?? vendor?.name ?? 'Vendor',
        );
      },
      '/vendor-qr-codes': (context) => const VendorQRCodeScreen(),

      // New Product Service Enhancement Routes
      '/product-service-demo': (context) => const ProductServiceDemoScreen(),
      '/enhanced-service-creation': (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        return ServiceCreationWizard(
          vendorId: args?['vendorId'] ?? 'demo-vendor',
          existingService: args?['existingService'] is VendorService ? args!['existingService'] as VendorService : null,
        );
      },
      '/vendor-availability-management': (context) => const SimpleAvailabilityScreen(),
      '/vendor-join-expo': (context) => const VendorJoinExhibitorScreen(),
      '/vendor-expo-detail': (context) {
        final expo = ModalRoute.of(context)!.settings.arguments as ExpoSummary;
        return VendorExpoDetailScreen(expo: expo);
      },
      '/vendor-exhibitor-apply': (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
        return VendorExhibitorApplyScreen(
          expo: args['expo'] as ExpoSummary,
          preselectedPackage: args['package'] as ExhibitorPackage?,
        );
      },
      '/vendor-application-status': (context) {
        final app = ModalRoute.of(context)!.settings.arguments as ExhibitorVendor;
        return VendorApplicationStatusScreen(application: app);
      },
      '/vendor-exhibitor-payment': (context) {
        final app = ModalRoute.of(context)!.settings.arguments as ExhibitorVendor;
        return VendorExhibitorPaymentScreen(application: app);
      },
      '/vendor-exhibition-dashboard': (context) {
        final exhibitor = ModalRoute.of(context)!.settings.arguments as ExhibitorVendor;
        return VendorExhibitionDashboardScreen(exhibitor: exhibitor);
      },
      '/vendor-floor-plan': (context) {
        final exhibitor = ModalRoute.of(context)!.settings.arguments as ExhibitorVendor;
        return VendorFloorPlanScreen(exhibitor: exhibitor);
      },
      '/vendor-requirements': (context) {
        final exhibitor = ModalRoute.of(context)!.settings.arguments as ExhibitorVendor;
        return VendorRequirementsScreen(exhibitor: exhibitor);
      },
      '/vendor-staff-passes': (context) {
        final exhibitor = ModalRoute.of(context)!.settings.arguments as ExhibitorVendor;
        return VendorStaffPassesScreen(exhibitor: exhibitor);
      },
      '/vendor-post-event': (context) {
        final exhibitor = ModalRoute.of(context)!.settings.arguments as ExhibitorVendor;
        return VendorPostEventScreen(exhibitor: exhibitor);
      },

      // Integration example routes from integration_guide.dart
      '/category-integration': (context) => const CategoryIntegrationExample(),
      '/pricing-integration': (context) => const PricingIntegrationExample(),
      '/image-integration': (context) => const ImageIntegrationExample(),
      '/conflict-integration': (context) => const ConflictIntegrationExample(),
      '/service-creation-integration': (context) => const ServiceCreationIntegrationExample(),
      '/demo-integration': (context) => const DemoIntegrationExample(),

      // Messages and Chat routes
      '/messages': (context) => const MessagesScreen(),

      // Appointments and Rentals routes
      '/appointments': (context) => const AppointmentManagementScreen(),
      '/rentals': (context) => const RentalManagementScreen(),

      // Guest routes
      '/invitation': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final invitationCode = args?['invitationCode'] as String?;
        if (invitationCode != null) {
          return InvitationViewScreen(invitationCode: invitationCode);
        }
        return const SplashScreen(); // Fallback
      },
      '/join-event': (context) => const EventCodeEntryScreen(),
      '/rsvp': (context) => const RSVPScreen(),
      '/event-details': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as Event?;
        if (event != null) {
          return EventDetailsScreen(event: event);
        }
        return const SplashScreen(); // Fallback
      },
      '/e-ticket': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as Event?;
        final guest = args?['guest'] as Guest?;
        if (event != null && guest != null) {
          return ETicketScreen(event: event, guest: guest);
        }
        return const SplashScreen(); // Fallback
      },
      '/event-schedule': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as Event?;
        final scheduleItems = args?['scheduleItems'] as List<EventScheduleItem>? ?? [];
        if (event != null) {
          return EventScheduleScreen(event: event, scheduleItems: scheduleItems);
        }
        return const SplashScreen(); // Fallback
      },
      '/event-map': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as Event?;
        if (event != null) {
          return EventMapScreen(event: event, venue: event.venue);
        }
        return const SplashScreen(); // Fallback
      },
      '/seating-assignment': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as Event?;
        final guest = args?['guest'] as Guest?;
        if (event != null && guest != null) {
          return SeatingAssignmentScreen(event: event, guest: guest);
        }
        return const SplashScreen(); // Fallback
      },
      '/meal-preferences': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as Event?;
        if (event != null) {
          return MealPreferencesScreen(event: event);
        }
        return const SplashScreen(); // Fallback
      },
      '/gift-registry': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as Event?;
        if (event != null) {
          return GiftRegistryScreen(event: event);
        }
        return const SplashScreen(); // Fallback
      },
      '/photo-sharing': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as Event?;
        final photoAlbums = args?['photoAlbums'] as List<PhotoAlbum>? ?? [];
        if (event != null) {
          return PhotoSharingScreen(event: event, photoAlbums: photoAlbums);
        }
        return const SplashScreen(); // Fallback
      },
      '/guest-chat': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as Event?;
        if (event != null) {
          return GuestChatScreen(event: event);
        }
        return const SplashScreen(); // Fallback
      },
      '/guest-dashboard': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as Event?;
        final invitation = args?['invitation'] as Invitation?;
        if (event != null && invitation != null) {
          return GuestDashboardScreen(event: event, invitation: invitation);
        }
        return const SplashScreen(); // Fallback
      },
      '/event-management': (context) => const EventManagementScreen(),
      '/service-creation': (context) {
        final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
        return ServiceCreationWizard(
          vendorId: args?['vendorId'] ?? 'demo-vendor',
          existingService: args?['existingService'] is VendorService ? args!['existingService'] as VendorService : null,
        );
      },
      '/services-hub': (context) => const VendorServicesHubScreen(),
      '/packages-hub': (context) => const VendorPackagesHubScreen(),
      '/service-creator': (context) => const VendorServiceCreatorScreen(),
      '/collaborative-package-builder': (context) => const CollaborativePackageBuilderScreen(),
      '/unified-calendar': (context) => const VendorUnifiedCalendarScreen(),
      '/package-customization': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final package = args?['package'] as CollaborativePackage?;
        if (package != null) {
          return CustomerPackageCustomizationScreen(package: package);
        }
        final provider = Provider.of<VendorWorkflowProvider>(context, listen: false);
        return CustomerPackageCustomizationScreen(package: provider.packages.first);
      },
      '/event-edit': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as Event?;
        if (event != null) {
          return EventEditScreen(event: event);
        }
        return const SplashScreen(); // Fallback
      },
      '/product-detail': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final service = args?['service'] as VendorService?;
        final serviceId = args?['serviceId'] as String?;
        if (service != null || serviceId != null) {
          return ProductDetailScreen(vendorService: service, serviceId: serviceId);
        }
        return const SplashScreen(); // Fallback
      },
      '/vendor-profile': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final vendorName = args?['vendorName'] as String?;
        final vendorId = args?['vendorId'] as String?;
        final services = args?['services'] as List<VendorService>?;
        if (vendorId != null || vendorName != null) {
          return VendorProfileScreen(
            vendorName: vendorName,
            vendorId: vendorId,
            services: services,
          );
        }
        return const SplashScreen(); // Fallback
      },
      '/orders': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final initialIndex = args?['initialIndex'] as int? ?? 0;
        return MyOrdersScreen(initialIndex: initialIndex);
      },
      '/order-status-old': (context) => const OrderStatusScreen(),
      '/checkout': (context) => const CheckoutScreen(),
      '/order-confirmation': (context) {
        final args = ModalRoute.of(context)?.settings.arguments;
        if (args is Order) {
          return OrderConfirmationScreen(order: args);
        }
        return const SplashScreen(); // Fallback
      },
      '/registry-management': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        final event = args?['event'] as Event?;
        return GiftManagementScreen(eventId: eventId ?? event?.id ?? '');
      },
      '/guest-list': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        final event = args?['event'] as Event?;
        return GuestListScreen(eventId: eventId ?? event?.id ?? '');
      },
      '/event-wishes': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        final event = args?['event'] as Event?;
        if (eventId != null || event != null) {
          return EventWishesScreen(eventId: eventId ?? event!.id);
        }
        return const SplashScreen();
      },
      '/customer-subscription': (context) => const CustomerSubscriptionScreen(),
      '/event-create': (context) => const EventCreationScreen(),
      '/planning-hub': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        return EventPlanningHubScreen(eventId: eventId);
      },
      '/planner': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        final initialTab = args?['tab'] as int? ?? 0;
        return CustomerPlannerScreen(eventId: eventId, initialTab: initialTab);
      },
      '/event-countdown': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final event = args?['event'] as Event?;
        if (event != null) {
          return EventCountdownScreen(event: event);
        }
        return const SplashScreen(); // Fallback
      },
      '/event-collaboration': (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        if (eventId != null) {
          return EventCollaborationScreen(eventId: eventId);
        }
        return const SplashScreen();
      },
    };
  }

// Navigation helper functions
class AppNavigation {
  // Navigate to product service demo
  static void navigateToDemo(BuildContext context) {
    Navigator.pushNamed(context, '/product-service-demo');
  }

  // Navigate to service creation
  static void navigateToServiceCreation(BuildContext context, {String? vendorId, VendorService? existingService}) {
    Navigator.pushNamed(
      context, 
      '/service-creation',
      arguments: {
        'vendorId': vendorId,
        'existingService': existingService,
      },
    );
  }

  // Navigate to availability management
  static void navigateToAvailabilityManagement(BuildContext context) {
    Navigator.pushNamed(context, '/vendor-availability-management');
  }

  // Navigate to integration examples
  static void navigateToCategoryIntegration(BuildContext context) {
    Navigator.pushNamed(context, '/category-integration');
  }

  static void navigateToPricingIntegration(BuildContext context) {
    Navigator.pushNamed(context, '/pricing-integration');
  }

  static void navigateToImageIntegration(BuildContext context) {
    Navigator.pushNamed(context, '/image-integration');
  }

  static void navigateToConflictIntegration(BuildContext context) {
    Navigator.pushNamed(context, '/conflict-integration');
  }

  static void navigateToDemoIntegration(BuildContext context) {
    Navigator.pushNamed(context, '/demo-integration');
  }

  // Navigate to messages screen
  static void navigateToMessages(BuildContext context) {
    Navigator.pushNamed(context, '/messages');
  }

  // Navigate to CRM dashboard
  static void navigateToCrmDashboard(BuildContext context) {
    Navigator.pushNamed(context, '/crm-dashboard');
  }

  // Navigate to Admin CRM dashboard
  static void navigateToAdminCrmDashboard(BuildContext context) {
    Navigator.pushNamed(context, '/admin-crm-dashboard');
  }
}
