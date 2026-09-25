import 'package:flutter/material.dart';
import 'package:eventease/features/auth/presentation/otp_verification_screen.dart';
import 'package:eventease/features/organizer/presentation/organizer_screen_catalog.dart';
import 'package:eventease/features/organizer/presentation/views/analytics/analytics_screens.dart';
import 'package:eventease/features/organizer/presentation/views/auth/organizer_activation_screen.dart';
import 'package:eventease/features/organizer/presentation/views/auth/organizer_auth_screens.dart';
import 'package:eventease/features/organizer/presentation/views/automation/automation_screens.dart';
import 'package:eventease/features/organizer/presentation/views/booth/booth_screens.dart';
import 'package:eventease/features/organizer/presentation/views/communication/communication_screens.dart';
import 'package:eventease/features/organizer/presentation/views/company/company_setup_screens.dart';
import 'package:eventease/features/organizer/presentation/views/dashboard/expo_command_dashboard_screen.dart';
import 'package:eventease/features/organizer/presentation/views/documents/documents_screens.dart';
import 'package:eventease/features/organizer/presentation/views/expo/create_expo_screen.dart';
import 'package:eventease/features/organizer/presentation/views/expo/expo_detail_screen.dart';
import 'package:eventease/features/organizer/presentation/views/expo/expo_list_screen.dart';
import 'package:eventease/features/organizer/presentation/views/finance/finance_screens.dart';
import 'package:eventease/features/organizer/presentation/views/lead/lead_screens.dart';
import 'package:eventease/features/organizer/presentation/views/live/live_command_screens.dart';
import 'package:eventease/features/organizer/presentation/views/marketing/marketing_screens.dart';
import 'package:eventease/features/organizer/presentation/views/post_expo/post_expo_screens.dart';
import 'package:eventease/features/organizer/presentation/views/settings/settings_screens.dart';
import 'package:eventease/features/organizer/presentation/views/sponsor/sponsor_screens.dart';
import 'package:eventease/features/organizer/presentation/views/staff/staff_screens.dart';
import 'package:eventease/features/organizer/presentation/views/ticket/ticket_screens.dart';
import 'package:eventease/features/organizer/presentation/views/vendor/exhibitor_vendor_screens.dart';
import 'package:eventease/features/organizer/presentation/views/visitor/visitor_screens.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_module_bootstrap.dart';

/// Route builders for the Wedding Event Organizer (expo) module.
Map<String, WidgetBuilder> getOrganizerRoutes() {
  return {
    // Auth
    OrganizerLoginScreen.routeName: (_) => const OrganizerLoginScreen(),
    OrganizerActivationScreen.routeName: (_) => const OrganizerActivationScreen(),
    OrganizerStaffLoginScreen.routeName: (_) => const OrganizerStaffLoginScreen(),
    OrganizerForgotPasswordScreen.routeName: (_) => const OrganizerForgotPasswordScreen(),
    '${OrganizerScreenCatalog.routePrefix}/otp': (_) => const OtpVerificationScreen(
          phoneNumber: '+60123456789',
          name: 'Organizer',
          role: 'organizer',
        ),

    // Company setup
    CompanyProfileScreen.routeName: (_) => const CompanyProfileScreen(),
    OrganizerBrandingScreen.routeName: (_) => const OrganizerBrandingScreen(),
    EventTypesSetupScreen.routeName: (_) => const EventTypesSetupScreen(),
    StaffRolesSetupScreen.routeName: (_) => const StaffRolesSetupScreen(),
    ServiceRegionsScreen.routeName: (_) => const ServiceRegionsScreen(),

    // Dashboard & expo
    ExpoCommandDashboardScreen.routeName: (_) => wrapOrganizerRoute(const ExpoCommandDashboardScreen()),
    ExpoListScreen.routeName: (_) => const ExpoListScreen(),
    CreateExpoScreen.routeName: (_) => const CreateExpoScreen(),
    ExpoDetailScreen.routeName: (context) => ExpoDetailScreen(
          expoId: ModalRoute.of(context)?.settings.arguments as String?,
        ),

    // Booth management
    BoothListScreen.routeName: (_) => const BoothListScreen(),
    BoothLayoutDesignerScreen.routeName: (_) => const BoothLayoutDesignerScreen(),
    BoothBookingScreen.routeName: (_) => const BoothBookingScreen(),
    BoothAssignmentScreen.routeName: (context) => BoothAssignmentScreen(
          boothId: ModalRoute.of(context)?.settings.arguments as String?,
        ),
    BoothPricingScreen.routeName: (_) => const BoothPricingScreen(),

    // Exhibitor vendors
    VendorApplicationScreen.routeName: (_) => const VendorApplicationScreen(),
    VendorApprovalScreen.routeName: (_) => const VendorApprovalScreen(),
    VendorDirectoryScreen.routeName: (_) => const VendorDirectoryScreen(),
    VendorDetailScreen.routeName: (context) => VendorDetailScreen(
          vendorId: ModalRoute.of(context)?.settings.arguments as String?,
        ),
    VendorContractScreen.routeName: (_) => const VendorContractScreen(),
    VendorPaymentScreen.routeName: (_) => const VendorPaymentScreen(),

    // Lead management
    LeadCollectionScreen.routeName: (_) => const LeadCollectionScreen(),
    LeadDistributionScreen.routeName: (_) => const LeadDistributionScreen(),
    LeadDetailScreen.routeName: (context) => LeadDetailScreen(
          leadId: ModalRoute.of(context)?.settings.arguments as String?,
        ),
    LeadTrackingScreen.routeName: (_) => const LeadTrackingScreen(),
    LeadQualityScoringScreen.routeName: (_) => const LeadQualityScoringScreen(),

    // Visitor system
    VisitorRegistrationScreen.routeName: (_) => const VisitorRegistrationScreen(),
    VisitorCheckInScreen.routeName: (_) => const VisitorCheckInScreen(),
    VisitorProfileScreen.routeName: (context) => VisitorProfileScreen(
          visitorId: ModalRoute.of(context)?.settings.arguments as String?,
        ),
    ExpoMapScreen.routeName: (_) => const ExpoMapScreen(),

    // Ticket & entry
    TicketTypeScreen.routeName: (_) => const TicketTypeScreen(),
    TicketSalesScreen.routeName: (_) => const TicketSalesScreen(),
    QrTicketScannerScreen.routeName: (_) => const QrTicketScannerScreen(),
    AttendanceDashboardScreen.routeName: (_) => const AttendanceDashboardScreen(),

    // Staff operations
    StaffAssignmentScreen.routeName: (_) => const StaffAssignmentScreen(),
    StaffRolesScreen.routeName: (_) => const StaffRolesScreen(),
    LiveStaffTrackingScreen.routeName: (_) => const LiveStaffTrackingScreen(),

    // Sponsors
    SponsorListScreen.routeName: (_) => const SponsorListScreen(),
    SponsorPackagesScreen.routeName: (_) => const SponsorPackagesScreen(),
    SponsorAgreementScreen.routeName: (_) => const SponsorAgreementScreen(),
    SponsorExposureTrackerScreen.routeName: (_) => const SponsorExposureTrackerScreen(),

    // Finance
    RevenueDashboardScreen.routeName: (_) => const RevenueDashboardScreen(),
    ExpenseTrackerScreen.routeName: (_) => const ExpenseTrackerScreen(),
    ProfitPerExpoScreen.routeName: (_) => const ProfitPerExpoScreen(),
    InvoiceManagementScreen.routeName: (_) => const InvoiceManagementScreen(),
    PaymentTrackingScreen.routeName: (_) => const PaymentTrackingScreen(),

    // Marketing & sales
    CampaignDashboardScreen.routeName: (_) => const CampaignDashboardScreen(),
    LeadFunnelScreen.routeName: (_) => const LeadFunnelScreen(),
    PromoCodesScreen.routeName: (_) => const PromoCodesScreen(),
    InfluencerCampaignScreen.routeName: (_) => const InfluencerCampaignScreen(),

    // Live expo command center
    LiveExpoDashboardScreen.routeName: (_) => const LiveExpoDashboardScreen(),
    ExpoTimelineScreen.routeName: (_) => const ExpoTimelineScreen(),
    IncidentManagementScreen.routeName: (_) => const IncidentManagementScreen(),
    EmergencyResponseScreen.routeName: (_) => const EmergencyResponseScreen(),

    // Post-expo
    ExpoReportScreen.routeName: (_) => const ExpoReportScreen(),
    VendorRoiReportScreen.routeName: (_) => const VendorRoiReportScreen(),
    VendorFeedbackScreen.routeName: (_) => const VendorFeedbackScreen(),
    LeadConversionReportScreen.routeName: (_) => const LeadConversionReportScreen(),
    ExpoPerformanceComparisonScreen.routeName: (_) => const ExpoPerformanceComparisonScreen(),

    // Analytics
    ExpoAnalyticsDashboardScreen.routeName: (_) => const ExpoAnalyticsDashboardScreen(),
    VendorPerformanceAnalyticsScreen.routeName: (_) => const VendorPerformanceAnalyticsScreen(),
    BoothPerformanceAnalyticsScreen.routeName: (_) => const BoothPerformanceAnalyticsScreen(),
    MarketingAnalyticsScreen.routeName: (_) => const MarketingAnalyticsScreen(),

    // Communication
    ChatInboxScreen.routeName: (_) => const ChatInboxScreen(),
    VendorCommunicationScreen.routeName: (_) => const VendorCommunicationScreen(),
    BroadcastMessagingScreen.routeName: (_) => const BroadcastMessagingScreen(),

    // Documents
    DocumentVaultScreen.routeName: (_) => const DocumentVaultScreen(),
    VendorContractGeneratorScreen.routeName: (_) => const VendorContractGeneratorScreen(),
    SponsorProposalScreen.routeName: (_) => const SponsorProposalScreen(),

    // Automation
    BoothAllocationAutoScreen.routeName: (_) => const BoothAllocationAutoScreen(),
    LeadAutoDistributionScreen.routeName: (_) => const LeadAutoDistributionScreen(),
    ReminderAutomationScreen.routeName: (_) => const ReminderAutomationScreen(),

    // Settings
    ExpoSettingsScreen.routeName: (_) => const ExpoSettingsScreen(),
    CompanySettingsScreen.routeName: (_) => const CompanySettingsScreen(),
    SubscriptionPlanScreen.routeName: (_) => const SubscriptionPlanScreen(),
    NotificationSettingsScreen.routeName: (_) => const NotificationSettingsScreen(),
  };
}
