// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonExport => 'Export';

  @override
  String get commonGotIt => 'Got it';

  @override
  String get vendorSettingsTitle => 'Settings';

  @override
  String get vendorTooltipSearch => 'Search Settings';

  @override
  String get vendorTooltipHelp => 'Help';

  @override
  String get vendorTooltipSave => 'Save Settings';

  @override
  String get vendorSectionAccount => 'Account Settings';

  @override
  String get vendorSectionNotifications => 'Notifications';

  @override
  String get vendorSectionAppPreferences => 'App Preferences';

  @override
  String get vendorSectionDataPrivacy => 'Data & Privacy';

  @override
  String get vendorSectionBusinessOperations => 'Business Operations';

  @override
  String get vendorSectionShippingDelivery => 'Shipping & Delivery';

  @override
  String get vendorSectionPaymentBilling => 'Payment & Billing';

  @override
  String get vendorSectionIntegrations => 'Integrations';

  @override
  String get vendorSectionAdvancedFeatures => 'Advanced Features';

  @override
  String get vendorSectionBusinessAnalytics => 'Business Analytics';

  @override
  String get vendorSectionSupportHelp => 'Support & Help';

  @override
  String get vendorSectionAccountDanger => 'Account';

  @override
  String get vendorProfileInformation => 'Profile Information';

  @override
  String get vendorProfileInformationSubtitle => 'Manage your business profile';

  @override
  String get vendorBusinessDetails => 'Business Details';

  @override
  String get vendorBusinessDetailsSubtitle => 'Update business information';

  @override
  String get vendorDocumentsCertifications => 'Documents & Certifications';

  @override
  String get vendorDocumentsSubtitle => 'Manage legal documents';

  @override
  String get vendorEnableNotifications => 'Enable Notifications';

  @override
  String get vendorEnableNotificationsSubtitle =>
      'Receive booking and system notifications';

  @override
  String get vendorEmailNotifications => 'Email Notifications';

  @override
  String get vendorEmailNotificationsSubtitle =>
      'Receive notifications via email';

  @override
  String get vendorPushNotifications => 'Push Notifications';

  @override
  String get vendorPushNotificationsSubtitle =>
      'Receive push notifications on mobile';

  @override
  String get vendorLanguage => 'Language';

  @override
  String get vendorCurrency => 'Currency';

  @override
  String get vendorDarkMode => 'Dark Mode';

  @override
  String get vendorDarkModeSubtitle => 'Switch to dark theme';

  @override
  String get vendorAutoBackup => 'Auto Backup';

  @override
  String get vendorAutoBackupSubtitle => 'Automatically backup your data';

  @override
  String get vendorDataRetention => 'Data Retention';

  @override
  String get vendorPublicProfile => 'Public Profile';

  @override
  String get vendorPublicProfileSubtitle =>
      'Make your business profile visible to everyone';

  @override
  String get vendorShowContactInfo => 'Show Contact Info';

  @override
  String get vendorShowContactInfoSubtitle =>
      'Display contact information publicly';

  @override
  String get vendorPrivateBookingHistory => 'Private Booking History';

  @override
  String get vendorPrivateBookingHistorySubtitle =>
      'Keep booking history private';

  @override
  String get vendorMarketingEmails => 'Marketing Emails';

  @override
  String get vendorMarketingEmailsSubtitle => 'Receive promotional emails';

  @override
  String get vendorDataSharing => 'Data Sharing';

  @override
  String get vendorDataSharingSubtitle =>
      'Share anonymized data for improvements';

  @override
  String get vendorAnalyticsTracking => 'Analytics Tracking';

  @override
  String get vendorAnalyticsTrackingSubtitle =>
      'Allow analytics tracking for better service';

  @override
  String get vendorPrivacyPolicy => 'Privacy Policy';

  @override
  String get vendorPrivacyPolicySubtitle => 'View our privacy policy';

  @override
  String get vendorTermsOfService => 'Terms of Service';

  @override
  String get vendorTermsOfServiceSubtitle => 'View terms and conditions';

  @override
  String get vendorAutoAcceptBookings => 'Auto-Accept Bookings';

  @override
  String get vendorAutoAcceptBookingsSubtitle =>
      'Automatically accept new bookings';

  @override
  String get vendorRequireDeposit => 'Require Deposit';

  @override
  String vendorDepositSubtitle(int percent) {
    return 'Require $percent% deposit for bookings';
  }

  @override
  String get vendorDepositPercentage => 'Deposit Percentage';

  @override
  String get vendorWeekendPricing => 'Weekend Pricing';

  @override
  String get vendorWeekendPricingSubtitle =>
      'Apply special pricing for weekends';

  @override
  String get vendorHolidayPricing => 'Holiday Pricing';

  @override
  String get vendorHolidayPricingSubtitle =>
      'Apply special pricing for holidays';

  @override
  String get vendorBulkDiscounts => 'Bulk Discounts';

  @override
  String get vendorBulkDiscountsSubtitle =>
      'Offer discounts for large bookings';

  @override
  String get vendorLoyaltyProgram => 'Loyalty Program';

  @override
  String get vendorLoyaltyProgramSubtitle => 'Reward repeat customers';

  @override
  String get vendorVacationMode => 'Vacation Mode';

  @override
  String get vendorVacationModeSubtitle => 'Temporarily disable new bookings';

  @override
  String get vendorVacationPeriod => 'Vacation Period';

  @override
  String get vendorVacationSetDates => 'Set vacation dates';

  @override
  String get vendorVacationMessage => 'Vacation Message';

  @override
  String get vendorEnableShipping => 'Enable Shipping';

  @override
  String get vendorEnableShippingSubtitle =>
      'Offer shipping services to customers';

  @override
  String get vendorBaseShippingRate => 'Base Shipping Rate';

  @override
  String vendorBaseShippingRateAmount(String amount) {
    return 'RM $amount';
  }

  @override
  String get vendorFreeShipping => 'Free Shipping';

  @override
  String vendorFreeShippingSubtitle(String amount) {
    return 'Free shipping for orders over RM $amount';
  }

  @override
  String get vendorFreeShippingThreshold => 'Free Shipping Threshold';

  @override
  String get vendorLocalDelivery => 'Local Delivery';

  @override
  String get vendorLocalDeliverySubtitle => 'Offer delivery within local area';

  @override
  String get vendorInternationalShipping => 'International Shipping';

  @override
  String get vendorInternationalShippingSubtitle =>
      'Ship to international locations';

  @override
  String get vendorProcessingTime => 'Processing Time';

  @override
  String vendorDaysCount(int days) {
    return '$days days';
  }

  @override
  String vendorProcessingDaysOneDay(int days) {
    return '$days day';
  }

  @override
  String vendorProcessingDaysManyDays(int days) {
    return '$days days';
  }

  @override
  String get vendorCashOnDelivery => 'Cash on Delivery';

  @override
  String get vendorCashOnDeliverySubtitle => 'Accept cash payments on delivery';

  @override
  String get vendorOnlinePayment => 'Online Payment';

  @override
  String get vendorOnlinePaymentSubtitle => 'Accept online payments';

  @override
  String get vendorBankTransfer => 'Bank Transfer';

  @override
  String get vendorBankTransferSubtitle => 'Accept direct bank transfers';

  @override
  String get vendorDigitalWallet => 'Digital Wallet';

  @override
  String get vendorDigitalWalletSubtitle => 'Accept digital wallet payments';

  @override
  String get vendorProcessingFee => 'Processing Fee';

  @override
  String vendorProcessingFeePercent(String percent) {
    return '$percent%';
  }

  @override
  String get vendorAutoRefund => 'Auto Refund';

  @override
  String get vendorAutoRefundSubtitle => 'Automatically process refunds';

  @override
  String get vendorRefundWindow => 'Refund Window';

  @override
  String get vendorPaymentReminders => 'Payment Reminders';

  @override
  String get vendorPaymentRemindersSubtitle =>
      'Send payment reminders to customers';

  @override
  String get vendorCalendarSync => 'Calendar Sync';

  @override
  String get vendorCalendarSyncSubtitle =>
      'Sync bookings with external calendars';

  @override
  String get vendorPaymentGateway => 'Payment Gateway';

  @override
  String get vendorPaymentGatewaySubtitle => 'Enable online payments';

  @override
  String get vendorAutoSocialMediaPosts => 'Auto Social Media Posts';

  @override
  String get vendorAutoSocialMediaPostsSubtitle =>
      'Automatically post updates to social media';

  @override
  String get vendorEmailMarketing => 'Email Marketing';

  @override
  String get vendorEmailMarketingSubtitle =>
      'Send promotional emails to customers';

  @override
  String get vendorSmsNotifications => 'SMS Notifications';

  @override
  String get vendorSmsNotificationsSubtitle =>
      'Send SMS notifications to customers';

  @override
  String get vendorWhatsappBusinessTile => 'WhatsApp Business';

  @override
  String get vendorWhatsappBusinessTileSubtitle =>
      'Enable WhatsApp Business integration';

  @override
  String get vendorChatSupport => 'Chat Support';

  @override
  String get vendorChatSupportSubtitle => 'Enable customer chat support';

  @override
  String get vendorChatNotifications => 'Chat Notifications';

  @override
  String get vendorChatNotificationsSubtitle =>
      'Receive notifications for new messages';

  @override
  String get vendorChatAvailability => 'Chat Availability';

  @override
  String get vendorAutoResponse => 'Auto Response';

  @override
  String get vendorAutoResponseSubtitle =>
      'Send automatic responses when offline';

  @override
  String get vendorAutoResponseMessage => 'Auto Response Message';

  @override
  String get vendorChatHistory => 'Chat History';

  @override
  String get vendorChatHistorySubtitle => 'Save chat history with customers';

  @override
  String get vendorAdvancedAnalytics => 'Advanced Analytics';

  @override
  String get vendorAdvancedAnalyticsSubtitle =>
      'Enable detailed business analytics';

  @override
  String get vendorCustomReports => 'Custom Reports';

  @override
  String get vendorCustomReportsSubtitle => 'Create custom business reports';

  @override
  String get vendorApiAccess => 'API Access';

  @override
  String get vendorApiAccessSubtitle => 'Enable API access for developers';

  @override
  String get vendorWebhookNotifications => 'Webhook Notifications';

  @override
  String get vendorWebhookNotificationsSubtitle =>
      'Receive real-time notifications via webhooks';

  @override
  String get vendorMultiLocationSupport => 'Multi-Location Support';

  @override
  String get vendorMultiLocationSupportSubtitle =>
      'Manage multiple business locations';

  @override
  String get vendorStaffManagement => 'Staff Management';

  @override
  String get vendorStaffManagementSubtitle =>
      'Manage staff accounts and permissions';

  @override
  String get vendorFinancialReports => 'Financial Reports';

  @override
  String get vendorFinancialReportsSubtitle =>
      'Configure financial reporting preferences';

  @override
  String get vendorPerformanceMetrics => 'Performance Metrics';

  @override
  String get vendorPerformanceMetricsSubtitle =>
      'Customize performance tracking';

  @override
  String get vendorExportData => 'Export Data';

  @override
  String get vendorExportDataSubtitle => 'Export your business data';

  @override
  String get vendorHelpCenter => 'Help Center';

  @override
  String get vendorHelpCenterSubtitle => 'Get help and support';

  @override
  String get vendorContactSupport => 'Contact Support';

  @override
  String get vendorContactSupportSubtitle => 'Reach out to our support team';

  @override
  String get vendorReportIssue => 'Report Issue';

  @override
  String get vendorReportIssueSubtitle => 'Report a bug or issue';

  @override
  String get vendorAppVersion => 'App Version';

  @override
  String get vendorAppVersionNumber => '1.0.0';

  @override
  String get vendorSignOut => 'Sign Out';

  @override
  String get vendorSignOutSubtitle => 'Sign out of your account';

  @override
  String get vendorDeleteAccount => 'Delete Account';

  @override
  String get vendorDeleteAccountSubtitle => 'Permanently delete your account';

  @override
  String get vendorSelectLanguage => 'Select Language';

  @override
  String get vendorLangEnglish => 'English';

  @override
  String get vendorLangMalay => 'Bahasa Malaysia';

  @override
  String get vendorLangChinese => '中文';

  @override
  String get vendorSelectCurrency => 'Select Currency';

  @override
  String get vendorCurrencyMyr => 'MYR (Ringgit Malaysia)';

  @override
  String get vendorCurrencyUsd => 'USD (US Dollar)';

  @override
  String get vendorCurrencySgd => 'SGD (Singapore Dollar)';

  @override
  String get vendorDataRetentionPeriod => 'Data Retention Period';

  @override
  String vendorDataRetentionKeep(int days) {
    return 'Keep data for $days days';
  }

  @override
  String get vendorFinancialReportsBody =>
      'Financial reporting preferences would be configured here';

  @override
  String get vendorPerformanceMetricsBody =>
      'Performance tracking preferences would be configured here';

  @override
  String get vendorExportDataBody =>
      'Data export options would be available here';

  @override
  String get vendorHelpCenterDialogTitle => 'Help Center';

  @override
  String get vendorHelpWelcome => 'Welcome to the Vendor Settings Help Center!';

  @override
  String get vendorHelpBulletAccount =>
      '• Account Settings: Manage your profile and business information';

  @override
  String get vendorHelpBulletNotifications =>
      '• Notifications: Configure how you receive updates';

  @override
  String get vendorHelpBulletBusiness =>
      '• Business Operations: Set up booking and pricing preferences';

  @override
  String get vendorHelpBulletIntegrations =>
      '• Integrations: Connect with external services';

  @override
  String get vendorHelpBulletAdvanced =>
      '• Advanced Features: Enable premium functionality';

  @override
  String get vendorHelpBulletAnalytics =>
      '• Business Analytics: Configure reporting and metrics';

  @override
  String get vendorHelpContactTeam =>
      'For more help, contact our support team.';

  @override
  String get vendorContactSupportSheetTitle => 'Contact Support';

  @override
  String get vendorContactSupportHours =>
      'Our vendor support team is available Monday – Friday, 9 AM – 6 PM (MYT).';

  @override
  String get vendorEmailSupport => 'Email Support';

  @override
  String get vendorCallUs => 'Call Us';

  @override
  String get vendorWhatsappBusiness => 'WhatsApp Business';

  @override
  String get vendorSnackEmail => 'Email: vendors@eventease.com';

  @override
  String get vendorSnackPhone => 'Phone: +60 3-1234 5678';

  @override
  String get vendorSnackWhatsapp => 'WhatsApp: +60 11-1234 5678';

  @override
  String get vendorBusinessDetailsTitle => 'Business Details';

  @override
  String get vendorBusinessDetailsIntro =>
      'Update your business information below.';

  @override
  String get vendorBusinessName => 'Business Name';

  @override
  String get vendorBusinessDescription => 'Business Description';

  @override
  String get vendorBusinessPhone => 'Business Phone';

  @override
  String get vendorBusinessWebsite => 'Website (optional)';

  @override
  String get vendorBusinessUpdated => 'Business details updated';

  @override
  String get vendorReportIssueTitle => 'Report an Issue';

  @override
  String get vendorReportCategory => 'Category';

  @override
  String get vendorReportDescribeIssue => 'Describe the issue';

  @override
  String get vendorReportIssueHint => 'Please describe the issue in detail...';

  @override
  String get vendorReportSubmit => 'Submit Report';

  @override
  String get vendorReportDescribeEmpty => 'Please describe the issue.';

  @override
  String get vendorReportSignInRequired =>
      'Sign in to submit a report, or email vendors@eventease.com.';

  @override
  String get vendorReportSuccess =>
      'Report submitted. Our team will follow up soon.';

  @override
  String vendorReportCouldNotSubmit(String error) {
    return 'Could not submit online: $error. Email vendors@eventease.com.';
  }

  @override
  String get vendorSignOutDialogTitle => 'Sign Out';

  @override
  String get vendorSignOutDialogBody => 'Are you sure you want to sign out?';

  @override
  String get vendorDeleteAccountDialogTitle => 'Delete Account';

  @override
  String get vendorDeleteAccountDialogBody =>
      'This action cannot be undone. All your data will be permanently deleted.';

  @override
  String get vendorSettingsSaved => 'Settings saved successfully';

  @override
  String get vendorSettingsHelpTitle => 'Settings Help';

  @override
  String get vendorSettingsHelpBulletAccount =>
      '• Account Settings: Manage your profile and business information';

  @override
  String get vendorSettingsHelpBulletNotifications =>
      '• Notifications: Configure how you receive updates';

  @override
  String get vendorSettingsHelpBulletBusiness =>
      '• Business Operations: Set up booking and pricing preferences';

  @override
  String get vendorSettingsHelpBulletIntegrations =>
      '• Integrations: Connect with external services';

  @override
  String get vendorSettingsHelpBulletAdvanced =>
      '• Advanced Features: Enable premium functionality';

  @override
  String get vendorSettingsHelpBulletAnalytics =>
      '• Business Analytics: Configure reporting and metrics';

  @override
  String get vendorVacationPeriodTitle => 'Set Vacation Period';

  @override
  String get vendorVacationStartDate => 'Start Date';

  @override
  String get vendorVacationEndDate => 'End Date';

  @override
  String get vendorVacationMessageTitle => 'Vacation Message';

  @override
  String get vendorNotSet => 'Not set';

  @override
  String get vendorVacationMessageHint =>
      'Enter message for customers during vacation';

  @override
  String get vendorShippingRateTitle => 'Base Shipping Rate';

  @override
  String vendorShippingRateCurrent(String amount) {
    return 'Current rate: RM $amount';
  }

  @override
  String get vendorProcessingTimeDialogTitle => 'Processing Time';

  @override
  String vendorProcessingTimeCurrent(String label) {
    return 'Current processing time: $label';
  }

  @override
  String get vendorProcessingFeeDialogTitle => 'Processing Fee';

  @override
  String vendorProcessingFeeCurrent(String percent) {
    return 'Current fee: $percent%';
  }

  @override
  String get vendorRefundWindowTitle => 'Refund Window';

  @override
  String vendorRefundWindowCurrent(int days) {
    return 'Current window: $days days';
  }

  @override
  String get vendorChatAvailabilityTitle => 'Chat Availability';

  @override
  String get vendorAutoResponseHint => 'Enter automatic response message';

  @override
  String get vendorDefaultVendorName => 'Vendor';

  @override
  String get vendorReportCatBug => 'Bug';

  @override
  String get vendorReportCatPayment => 'Payment Issue';

  @override
  String get vendorReportCatBooking => 'Booking Problem';

  @override
  String get vendorReportCatAccount => 'Account Issue';

  @override
  String get vendorReportCatOther => 'Other';

  @override
  String get vendorChatHours247 => '24/7';

  @override
  String get vendorChatHoursBusiness => 'Business Hours';

  @override
  String get vendorChatHoursCustom => 'Custom';

  @override
  String vendorSearchScrollTo(String name) {
    return 'Would scroll to: $name';
  }

  @override
  String vendorSliderRmLabel(String amount) {
    return 'RM $amount';
  }

  @override
  String vendorDepositSliderLabel(int percent) {
    return '$percent%';
  }
}
