import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms'),
    Locale('zh'),
    Locale('zh', 'CN'),
  ];

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get commonExport;

  /// No description provided for @commonGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get commonGotIt;

  /// No description provided for @vendorSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get vendorSettingsTitle;

  /// No description provided for @vendorTooltipSearch.
  ///
  /// In en, this message translates to:
  /// **'Search Settings'**
  String get vendorTooltipSearch;

  /// No description provided for @vendorTooltipHelp.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get vendorTooltipHelp;

  /// No description provided for @vendorTooltipSave.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get vendorTooltipSave;

  /// No description provided for @vendorSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get vendorSectionAccount;

  /// No description provided for @vendorSectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get vendorSectionNotifications;

  /// No description provided for @vendorSectionAppPreferences.
  ///
  /// In en, this message translates to:
  /// **'App Preferences'**
  String get vendorSectionAppPreferences;

  /// No description provided for @vendorSectionDataPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get vendorSectionDataPrivacy;

  /// No description provided for @vendorSectionBusinessOperations.
  ///
  /// In en, this message translates to:
  /// **'Business Operations'**
  String get vendorSectionBusinessOperations;

  /// No description provided for @vendorSectionShippingDelivery.
  ///
  /// In en, this message translates to:
  /// **'Shipping & Delivery'**
  String get vendorSectionShippingDelivery;

  /// No description provided for @vendorSectionPaymentBilling.
  ///
  /// In en, this message translates to:
  /// **'Payment & Billing'**
  String get vendorSectionPaymentBilling;

  /// No description provided for @vendorSectionIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get vendorSectionIntegrations;

  /// No description provided for @vendorSectionAdvancedFeatures.
  ///
  /// In en, this message translates to:
  /// **'Advanced Features'**
  String get vendorSectionAdvancedFeatures;

  /// No description provided for @vendorSectionBusinessAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Business Analytics'**
  String get vendorSectionBusinessAnalytics;

  /// No description provided for @vendorSectionSupportHelp.
  ///
  /// In en, this message translates to:
  /// **'Support & Help'**
  String get vendorSectionSupportHelp;

  /// No description provided for @vendorSectionAccountDanger.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get vendorSectionAccountDanger;

  /// No description provided for @vendorProfileInformation.
  ///
  /// In en, this message translates to:
  /// **'Profile Information'**
  String get vendorProfileInformation;

  /// No description provided for @vendorProfileInformationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your business profile'**
  String get vendorProfileInformationSubtitle;

  /// No description provided for @vendorBusinessDetails.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get vendorBusinessDetails;

  /// No description provided for @vendorBusinessDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update business information'**
  String get vendorBusinessDetailsSubtitle;

  /// No description provided for @vendorDocumentsCertifications.
  ///
  /// In en, this message translates to:
  /// **'Documents & Certifications'**
  String get vendorDocumentsCertifications;

  /// No description provided for @vendorDocumentsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage legal documents'**
  String get vendorDocumentsSubtitle;

  /// No description provided for @vendorEnableNotifications.
  ///
  /// In en, this message translates to:
  /// **'Enable Notifications'**
  String get vendorEnableNotifications;

  /// No description provided for @vendorEnableNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive booking and system notifications'**
  String get vendorEnableNotificationsSubtitle;

  /// No description provided for @vendorEmailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get vendorEmailNotifications;

  /// No description provided for @vendorEmailNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications via email'**
  String get vendorEmailNotificationsSubtitle;

  /// No description provided for @vendorPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get vendorPushNotifications;

  /// No description provided for @vendorPushNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive push notifications on mobile'**
  String get vendorPushNotificationsSubtitle;

  /// No description provided for @vendorLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get vendorLanguage;

  /// No description provided for @vendorCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get vendorCurrency;

  /// No description provided for @vendorDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get vendorDarkMode;

  /// No description provided for @vendorDarkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Switch to dark theme'**
  String get vendorDarkModeSubtitle;

  /// No description provided for @vendorAutoBackup.
  ///
  /// In en, this message translates to:
  /// **'Auto Backup'**
  String get vendorAutoBackup;

  /// No description provided for @vendorAutoBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically backup your data'**
  String get vendorAutoBackupSubtitle;

  /// No description provided for @vendorDataRetention.
  ///
  /// In en, this message translates to:
  /// **'Data Retention'**
  String get vendorDataRetention;

  /// No description provided for @vendorPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get vendorPublicProfile;

  /// No description provided for @vendorPublicProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make your business profile visible to everyone'**
  String get vendorPublicProfileSubtitle;

  /// No description provided for @vendorShowContactInfo.
  ///
  /// In en, this message translates to:
  /// **'Show Contact Info'**
  String get vendorShowContactInfo;

  /// No description provided for @vendorShowContactInfoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Display contact information publicly'**
  String get vendorShowContactInfoSubtitle;

  /// No description provided for @vendorPrivateBookingHistory.
  ///
  /// In en, this message translates to:
  /// **'Private Booking History'**
  String get vendorPrivateBookingHistory;

  /// No description provided for @vendorPrivateBookingHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep booking history private'**
  String get vendorPrivateBookingHistorySubtitle;

  /// No description provided for @vendorMarketingEmails.
  ///
  /// In en, this message translates to:
  /// **'Marketing Emails'**
  String get vendorMarketingEmails;

  /// No description provided for @vendorMarketingEmailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive promotional emails'**
  String get vendorMarketingEmailsSubtitle;

  /// No description provided for @vendorDataSharing.
  ///
  /// In en, this message translates to:
  /// **'Data Sharing'**
  String get vendorDataSharing;

  /// No description provided for @vendorDataSharingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share anonymized data for improvements'**
  String get vendorDataSharingSubtitle;

  /// No description provided for @vendorAnalyticsTracking.
  ///
  /// In en, this message translates to:
  /// **'Analytics Tracking'**
  String get vendorAnalyticsTracking;

  /// No description provided for @vendorAnalyticsTrackingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Allow analytics tracking for better service'**
  String get vendorAnalyticsTrackingSubtitle;

  /// No description provided for @vendorPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get vendorPrivacyPolicy;

  /// No description provided for @vendorPrivacyPolicySubtitle.
  ///
  /// In en, this message translates to:
  /// **'View our privacy policy'**
  String get vendorPrivacyPolicySubtitle;

  /// No description provided for @vendorTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get vendorTermsOfService;

  /// No description provided for @vendorTermsOfServiceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View terms and conditions'**
  String get vendorTermsOfServiceSubtitle;

  /// No description provided for @vendorAutoAcceptBookings.
  ///
  /// In en, this message translates to:
  /// **'Auto-Accept Bookings'**
  String get vendorAutoAcceptBookings;

  /// No description provided for @vendorAutoAcceptBookingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically accept new bookings'**
  String get vendorAutoAcceptBookingsSubtitle;

  /// No description provided for @vendorRequireDeposit.
  ///
  /// In en, this message translates to:
  /// **'Require Deposit'**
  String get vendorRequireDeposit;

  /// No description provided for @vendorDepositSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require {percent}% deposit for bookings'**
  String vendorDepositSubtitle(int percent);

  /// No description provided for @vendorDepositPercentage.
  ///
  /// In en, this message translates to:
  /// **'Deposit Percentage'**
  String get vendorDepositPercentage;

  /// No description provided for @vendorWeekendPricing.
  ///
  /// In en, this message translates to:
  /// **'Weekend Pricing'**
  String get vendorWeekendPricing;

  /// No description provided for @vendorWeekendPricingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply special pricing for weekends'**
  String get vendorWeekendPricingSubtitle;

  /// No description provided for @vendorHolidayPricing.
  ///
  /// In en, this message translates to:
  /// **'Holiday Pricing'**
  String get vendorHolidayPricing;

  /// No description provided for @vendorHolidayPricingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Apply special pricing for holidays'**
  String get vendorHolidayPricingSubtitle;

  /// No description provided for @vendorBulkDiscounts.
  ///
  /// In en, this message translates to:
  /// **'Bulk Discounts'**
  String get vendorBulkDiscounts;

  /// No description provided for @vendorBulkDiscountsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offer discounts for large bookings'**
  String get vendorBulkDiscountsSubtitle;

  /// No description provided for @vendorLoyaltyProgram.
  ///
  /// In en, this message translates to:
  /// **'Loyalty Program'**
  String get vendorLoyaltyProgram;

  /// No description provided for @vendorLoyaltyProgramSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reward repeat customers'**
  String get vendorLoyaltyProgramSubtitle;

  /// No description provided for @vendorVacationMode.
  ///
  /// In en, this message translates to:
  /// **'Vacation Mode'**
  String get vendorVacationMode;

  /// No description provided for @vendorVacationModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Temporarily disable new bookings'**
  String get vendorVacationModeSubtitle;

  /// No description provided for @vendorVacationPeriod.
  ///
  /// In en, this message translates to:
  /// **'Vacation Period'**
  String get vendorVacationPeriod;

  /// No description provided for @vendorVacationSetDates.
  ///
  /// In en, this message translates to:
  /// **'Set vacation dates'**
  String get vendorVacationSetDates;

  /// No description provided for @vendorVacationMessage.
  ///
  /// In en, this message translates to:
  /// **'Vacation Message'**
  String get vendorVacationMessage;

  /// No description provided for @vendorEnableShipping.
  ///
  /// In en, this message translates to:
  /// **'Enable Shipping'**
  String get vendorEnableShipping;

  /// No description provided for @vendorEnableShippingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offer shipping services to customers'**
  String get vendorEnableShippingSubtitle;

  /// No description provided for @vendorBaseShippingRate.
  ///
  /// In en, this message translates to:
  /// **'Base Shipping Rate'**
  String get vendorBaseShippingRate;

  /// No description provided for @vendorBaseShippingRateAmount.
  ///
  /// In en, this message translates to:
  /// **'RM {amount}'**
  String vendorBaseShippingRateAmount(String amount);

  /// No description provided for @vendorFreeShipping.
  ///
  /// In en, this message translates to:
  /// **'Free Shipping'**
  String get vendorFreeShipping;

  /// No description provided for @vendorFreeShippingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Free shipping for orders over RM {amount}'**
  String vendorFreeShippingSubtitle(String amount);

  /// No description provided for @vendorFreeShippingThreshold.
  ///
  /// In en, this message translates to:
  /// **'Free Shipping Threshold'**
  String get vendorFreeShippingThreshold;

  /// No description provided for @vendorLocalDelivery.
  ///
  /// In en, this message translates to:
  /// **'Local Delivery'**
  String get vendorLocalDelivery;

  /// No description provided for @vendorLocalDeliverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offer delivery within local area'**
  String get vendorLocalDeliverySubtitle;

  /// No description provided for @vendorInternationalShipping.
  ///
  /// In en, this message translates to:
  /// **'International Shipping'**
  String get vendorInternationalShipping;

  /// No description provided for @vendorInternationalShippingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ship to international locations'**
  String get vendorInternationalShippingSubtitle;

  /// No description provided for @vendorProcessingTime.
  ///
  /// In en, this message translates to:
  /// **'Processing Time'**
  String get vendorProcessingTime;

  /// No description provided for @vendorDaysCount.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String vendorDaysCount(int days);

  /// No description provided for @vendorProcessingDaysOneDay.
  ///
  /// In en, this message translates to:
  /// **'{days} day'**
  String vendorProcessingDaysOneDay(int days);

  /// No description provided for @vendorProcessingDaysManyDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String vendorProcessingDaysManyDays(int days);

  /// No description provided for @vendorCashOnDelivery.
  ///
  /// In en, this message translates to:
  /// **'Cash on Delivery'**
  String get vendorCashOnDelivery;

  /// No description provided for @vendorCashOnDeliverySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept cash payments on delivery'**
  String get vendorCashOnDeliverySubtitle;

  /// No description provided for @vendorOnlinePayment.
  ///
  /// In en, this message translates to:
  /// **'Online Payment'**
  String get vendorOnlinePayment;

  /// No description provided for @vendorOnlinePaymentSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept online payments'**
  String get vendorOnlinePaymentSubtitle;

  /// No description provided for @vendorBankTransfer.
  ///
  /// In en, this message translates to:
  /// **'Bank Transfer'**
  String get vendorBankTransfer;

  /// No description provided for @vendorBankTransferSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept direct bank transfers'**
  String get vendorBankTransferSubtitle;

  /// No description provided for @vendorDigitalWallet.
  ///
  /// In en, this message translates to:
  /// **'Digital Wallet'**
  String get vendorDigitalWallet;

  /// No description provided for @vendorDigitalWalletSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Accept digital wallet payments'**
  String get vendorDigitalWalletSubtitle;

  /// No description provided for @vendorProcessingFee.
  ///
  /// In en, this message translates to:
  /// **'Processing Fee'**
  String get vendorProcessingFee;

  /// No description provided for @vendorProcessingFeePercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String vendorProcessingFeePercent(String percent);

  /// No description provided for @vendorAutoRefund.
  ///
  /// In en, this message translates to:
  /// **'Auto Refund'**
  String get vendorAutoRefund;

  /// No description provided for @vendorAutoRefundSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically process refunds'**
  String get vendorAutoRefundSubtitle;

  /// No description provided for @vendorRefundWindow.
  ///
  /// In en, this message translates to:
  /// **'Refund Window'**
  String get vendorRefundWindow;

  /// No description provided for @vendorPaymentReminders.
  ///
  /// In en, this message translates to:
  /// **'Payment Reminders'**
  String get vendorPaymentReminders;

  /// No description provided for @vendorPaymentRemindersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send payment reminders to customers'**
  String get vendorPaymentRemindersSubtitle;

  /// No description provided for @vendorCalendarSync.
  ///
  /// In en, this message translates to:
  /// **'Calendar Sync'**
  String get vendorCalendarSync;

  /// No description provided for @vendorCalendarSyncSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sync bookings with external calendars'**
  String get vendorCalendarSyncSubtitle;

  /// No description provided for @vendorPaymentGateway.
  ///
  /// In en, this message translates to:
  /// **'Payment Gateway'**
  String get vendorPaymentGateway;

  /// No description provided for @vendorPaymentGatewaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable online payments'**
  String get vendorPaymentGatewaySubtitle;

  /// No description provided for @vendorAutoSocialMediaPosts.
  ///
  /// In en, this message translates to:
  /// **'Auto Social Media Posts'**
  String get vendorAutoSocialMediaPosts;

  /// No description provided for @vendorAutoSocialMediaPostsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically post updates to social media'**
  String get vendorAutoSocialMediaPostsSubtitle;

  /// No description provided for @vendorEmailMarketing.
  ///
  /// In en, this message translates to:
  /// **'Email Marketing'**
  String get vendorEmailMarketing;

  /// No description provided for @vendorEmailMarketingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send promotional emails to customers'**
  String get vendorEmailMarketingSubtitle;

  /// No description provided for @vendorSmsNotifications.
  ///
  /// In en, this message translates to:
  /// **'SMS Notifications'**
  String get vendorSmsNotifications;

  /// No description provided for @vendorSmsNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send SMS notifications to customers'**
  String get vendorSmsNotificationsSubtitle;

  /// No description provided for @vendorWhatsappBusinessTile.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Business'**
  String get vendorWhatsappBusinessTile;

  /// No description provided for @vendorWhatsappBusinessTileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable WhatsApp Business integration'**
  String get vendorWhatsappBusinessTileSubtitle;

  /// No description provided for @vendorChatSupport.
  ///
  /// In en, this message translates to:
  /// **'Chat Support'**
  String get vendorChatSupport;

  /// No description provided for @vendorChatSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable customer chat support'**
  String get vendorChatSupportSubtitle;

  /// No description provided for @vendorChatNotifications.
  ///
  /// In en, this message translates to:
  /// **'Chat Notifications'**
  String get vendorChatNotifications;

  /// No description provided for @vendorChatNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications for new messages'**
  String get vendorChatNotificationsSubtitle;

  /// No description provided for @vendorChatAvailability.
  ///
  /// In en, this message translates to:
  /// **'Chat Availability'**
  String get vendorChatAvailability;

  /// No description provided for @vendorAutoResponse.
  ///
  /// In en, this message translates to:
  /// **'Auto Response'**
  String get vendorAutoResponse;

  /// No description provided for @vendorAutoResponseSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Send automatic responses when offline'**
  String get vendorAutoResponseSubtitle;

  /// No description provided for @vendorAutoResponseMessage.
  ///
  /// In en, this message translates to:
  /// **'Auto Response Message'**
  String get vendorAutoResponseMessage;

  /// No description provided for @vendorChatHistory.
  ///
  /// In en, this message translates to:
  /// **'Chat History'**
  String get vendorChatHistory;

  /// No description provided for @vendorChatHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save chat history with customers'**
  String get vendorChatHistorySubtitle;

  /// No description provided for @vendorAdvancedAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced Analytics'**
  String get vendorAdvancedAnalytics;

  /// No description provided for @vendorAdvancedAnalyticsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable detailed business analytics'**
  String get vendorAdvancedAnalyticsSubtitle;

  /// No description provided for @vendorCustomReports.
  ///
  /// In en, this message translates to:
  /// **'Custom Reports'**
  String get vendorCustomReports;

  /// No description provided for @vendorCustomReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create custom business reports'**
  String get vendorCustomReportsSubtitle;

  /// No description provided for @vendorApiAccess.
  ///
  /// In en, this message translates to:
  /// **'API Access'**
  String get vendorApiAccess;

  /// No description provided for @vendorApiAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enable API access for developers'**
  String get vendorApiAccessSubtitle;

  /// No description provided for @vendorWebhookNotifications.
  ///
  /// In en, this message translates to:
  /// **'Webhook Notifications'**
  String get vendorWebhookNotifications;

  /// No description provided for @vendorWebhookNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive real-time notifications via webhooks'**
  String get vendorWebhookNotificationsSubtitle;

  /// No description provided for @vendorMultiLocationSupport.
  ///
  /// In en, this message translates to:
  /// **'Multi-Location Support'**
  String get vendorMultiLocationSupport;

  /// No description provided for @vendorMultiLocationSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage multiple business locations'**
  String get vendorMultiLocationSupportSubtitle;

  /// No description provided for @vendorStaffManagement.
  ///
  /// In en, this message translates to:
  /// **'Staff Management'**
  String get vendorStaffManagement;

  /// No description provided for @vendorStaffManagementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage staff accounts and permissions'**
  String get vendorStaffManagementSubtitle;

  /// No description provided for @vendorFinancialReports.
  ///
  /// In en, this message translates to:
  /// **'Financial Reports'**
  String get vendorFinancialReports;

  /// No description provided for @vendorFinancialReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Configure financial reporting preferences'**
  String get vendorFinancialReportsSubtitle;

  /// No description provided for @vendorPerformanceMetrics.
  ///
  /// In en, this message translates to:
  /// **'Performance Metrics'**
  String get vendorPerformanceMetrics;

  /// No description provided for @vendorPerformanceMetricsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize performance tracking'**
  String get vendorPerformanceMetricsSubtitle;

  /// No description provided for @vendorExportData.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get vendorExportData;

  /// No description provided for @vendorExportDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export your business data'**
  String get vendorExportDataSubtitle;

  /// No description provided for @vendorHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get vendorHelpCenter;

  /// No description provided for @vendorHelpCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get help and support'**
  String get vendorHelpCenterSubtitle;

  /// No description provided for @vendorContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get vendorContactSupport;

  /// No description provided for @vendorContactSupportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reach out to our support team'**
  String get vendorContactSupportSubtitle;

  /// No description provided for @vendorReportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get vendorReportIssue;

  /// No description provided for @vendorReportIssueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Report a bug or issue'**
  String get vendorReportIssueSubtitle;

  /// No description provided for @vendorAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App Version'**
  String get vendorAppVersion;

  /// No description provided for @vendorAppVersionNumber.
  ///
  /// In en, this message translates to:
  /// **'1.0.0'**
  String get vendorAppVersionNumber;

  /// No description provided for @vendorSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get vendorSignOut;

  /// No description provided for @vendorSignOutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get vendorSignOutSubtitle;

  /// No description provided for @vendorDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get vendorDeleteAccount;

  /// No description provided for @vendorDeleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account'**
  String get vendorDeleteAccountSubtitle;

  /// No description provided for @vendorSelectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get vendorSelectLanguage;

  /// No description provided for @vendorLangEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get vendorLangEnglish;

  /// No description provided for @vendorLangMalay.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Malaysia'**
  String get vendorLangMalay;

  /// No description provided for @vendorLangChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get vendorLangChinese;

  /// No description provided for @vendorSelectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get vendorSelectCurrency;

  /// No description provided for @vendorCurrencyMyr.
  ///
  /// In en, this message translates to:
  /// **'MYR (Ringgit Malaysia)'**
  String get vendorCurrencyMyr;

  /// No description provided for @vendorCurrencyUsd.
  ///
  /// In en, this message translates to:
  /// **'USD (US Dollar)'**
  String get vendorCurrencyUsd;

  /// No description provided for @vendorCurrencySgd.
  ///
  /// In en, this message translates to:
  /// **'SGD (Singapore Dollar)'**
  String get vendorCurrencySgd;

  /// No description provided for @vendorDataRetentionPeriod.
  ///
  /// In en, this message translates to:
  /// **'Data Retention Period'**
  String get vendorDataRetentionPeriod;

  /// No description provided for @vendorDataRetentionKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep data for {days} days'**
  String vendorDataRetentionKeep(int days);

  /// No description provided for @vendorFinancialReportsBody.
  ///
  /// In en, this message translates to:
  /// **'Financial reporting preferences would be configured here'**
  String get vendorFinancialReportsBody;

  /// No description provided for @vendorPerformanceMetricsBody.
  ///
  /// In en, this message translates to:
  /// **'Performance tracking preferences would be configured here'**
  String get vendorPerformanceMetricsBody;

  /// No description provided for @vendorExportDataBody.
  ///
  /// In en, this message translates to:
  /// **'Data export options would be available here'**
  String get vendorExportDataBody;

  /// No description provided for @vendorHelpCenterDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get vendorHelpCenterDialogTitle;

  /// No description provided for @vendorHelpWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the Vendor Settings Help Center!'**
  String get vendorHelpWelcome;

  /// No description provided for @vendorHelpBulletAccount.
  ///
  /// In en, this message translates to:
  /// **'• Account Settings: Manage your profile and business information'**
  String get vendorHelpBulletAccount;

  /// No description provided for @vendorHelpBulletNotifications.
  ///
  /// In en, this message translates to:
  /// **'• Notifications: Configure how you receive updates'**
  String get vendorHelpBulletNotifications;

  /// No description provided for @vendorHelpBulletBusiness.
  ///
  /// In en, this message translates to:
  /// **'• Business Operations: Set up booking and pricing preferences'**
  String get vendorHelpBulletBusiness;

  /// No description provided for @vendorHelpBulletIntegrations.
  ///
  /// In en, this message translates to:
  /// **'• Integrations: Connect with external services'**
  String get vendorHelpBulletIntegrations;

  /// No description provided for @vendorHelpBulletAdvanced.
  ///
  /// In en, this message translates to:
  /// **'• Advanced Features: Enable premium functionality'**
  String get vendorHelpBulletAdvanced;

  /// No description provided for @vendorHelpBulletAnalytics.
  ///
  /// In en, this message translates to:
  /// **'• Business Analytics: Configure reporting and metrics'**
  String get vendorHelpBulletAnalytics;

  /// No description provided for @vendorHelpContactTeam.
  ///
  /// In en, this message translates to:
  /// **'For more help, contact our support team.'**
  String get vendorHelpContactTeam;

  /// No description provided for @vendorContactSupportSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get vendorContactSupportSheetTitle;

  /// No description provided for @vendorContactSupportHours.
  ///
  /// In en, this message translates to:
  /// **'Our vendor support team is available Monday – Friday, 9 AM – 6 PM (MYT).'**
  String get vendorContactSupportHours;

  /// No description provided for @vendorEmailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get vendorEmailSupport;

  /// No description provided for @vendorCallUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get vendorCallUs;

  /// No description provided for @vendorWhatsappBusiness.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Business'**
  String get vendorWhatsappBusiness;

  /// No description provided for @vendorSnackEmail.
  ///
  /// In en, this message translates to:
  /// **'Email: vendors@eventease.com'**
  String get vendorSnackEmail;

  /// No description provided for @vendorSnackPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone: +60 3-1234 5678'**
  String get vendorSnackPhone;

  /// No description provided for @vendorSnackWhatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp: +60 11-1234 5678'**
  String get vendorSnackWhatsapp;

  /// No description provided for @vendorBusinessDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Business Details'**
  String get vendorBusinessDetailsTitle;

  /// No description provided for @vendorBusinessDetailsIntro.
  ///
  /// In en, this message translates to:
  /// **'Update your business information below.'**
  String get vendorBusinessDetailsIntro;

  /// No description provided for @vendorBusinessName.
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get vendorBusinessName;

  /// No description provided for @vendorBusinessDescription.
  ///
  /// In en, this message translates to:
  /// **'Business Description'**
  String get vendorBusinessDescription;

  /// No description provided for @vendorBusinessPhone.
  ///
  /// In en, this message translates to:
  /// **'Business Phone'**
  String get vendorBusinessPhone;

  /// No description provided for @vendorBusinessWebsite.
  ///
  /// In en, this message translates to:
  /// **'Website (optional)'**
  String get vendorBusinessWebsite;

  /// No description provided for @vendorBusinessUpdated.
  ///
  /// In en, this message translates to:
  /// **'Business details updated'**
  String get vendorBusinessUpdated;

  /// No description provided for @vendorReportIssueTitle.
  ///
  /// In en, this message translates to:
  /// **'Report an Issue'**
  String get vendorReportIssueTitle;

  /// No description provided for @vendorReportCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get vendorReportCategory;

  /// No description provided for @vendorReportDescribeIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue'**
  String get vendorReportDescribeIssue;

  /// No description provided for @vendorReportIssueHint.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue in detail...'**
  String get vendorReportIssueHint;

  /// No description provided for @vendorReportSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit Report'**
  String get vendorReportSubmit;

  /// No description provided for @vendorReportDescribeEmpty.
  ///
  /// In en, this message translates to:
  /// **'Please describe the issue.'**
  String get vendorReportDescribeEmpty;

  /// No description provided for @vendorReportSignInRequired.
  ///
  /// In en, this message translates to:
  /// **'Sign in to submit a report, or email vendors@eventease.com.'**
  String get vendorReportSignInRequired;

  /// No description provided for @vendorReportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Report submitted. Our team will follow up soon.'**
  String get vendorReportSuccess;

  /// No description provided for @vendorReportCouldNotSubmit.
  ///
  /// In en, this message translates to:
  /// **'Could not submit online: {error}. Email vendors@eventease.com.'**
  String vendorReportCouldNotSubmit(String error);

  /// No description provided for @vendorSignOutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get vendorSignOutDialogTitle;

  /// No description provided for @vendorSignOutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get vendorSignOutDialogBody;

  /// No description provided for @vendorDeleteAccountDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get vendorDeleteAccountDialogTitle;

  /// No description provided for @vendorDeleteAccountDialogBody.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. All your data will be permanently deleted.'**
  String get vendorDeleteAccountDialogBody;

  /// No description provided for @vendorSettingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Settings saved successfully'**
  String get vendorSettingsSaved;

  /// No description provided for @vendorSettingsHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings Help'**
  String get vendorSettingsHelpTitle;

  /// No description provided for @vendorSettingsHelpBulletAccount.
  ///
  /// In en, this message translates to:
  /// **'• Account Settings: Manage your profile and business information'**
  String get vendorSettingsHelpBulletAccount;

  /// No description provided for @vendorSettingsHelpBulletNotifications.
  ///
  /// In en, this message translates to:
  /// **'• Notifications: Configure how you receive updates'**
  String get vendorSettingsHelpBulletNotifications;

  /// No description provided for @vendorSettingsHelpBulletBusiness.
  ///
  /// In en, this message translates to:
  /// **'• Business Operations: Set up booking and pricing preferences'**
  String get vendorSettingsHelpBulletBusiness;

  /// No description provided for @vendorSettingsHelpBulletIntegrations.
  ///
  /// In en, this message translates to:
  /// **'• Integrations: Connect with external services'**
  String get vendorSettingsHelpBulletIntegrations;

  /// No description provided for @vendorSettingsHelpBulletAdvanced.
  ///
  /// In en, this message translates to:
  /// **'• Advanced Features: Enable premium functionality'**
  String get vendorSettingsHelpBulletAdvanced;

  /// No description provided for @vendorSettingsHelpBulletAnalytics.
  ///
  /// In en, this message translates to:
  /// **'• Business Analytics: Configure reporting and metrics'**
  String get vendorSettingsHelpBulletAnalytics;

  /// No description provided for @vendorVacationPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Vacation Period'**
  String get vendorVacationPeriodTitle;

  /// No description provided for @vendorVacationStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get vendorVacationStartDate;

  /// No description provided for @vendorVacationEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get vendorVacationEndDate;

  /// No description provided for @vendorVacationMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Vacation Message'**
  String get vendorVacationMessageTitle;

  /// No description provided for @vendorNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get vendorNotSet;

  /// No description provided for @vendorVacationMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Enter message for customers during vacation'**
  String get vendorVacationMessageHint;

  /// No description provided for @vendorShippingRateTitle.
  ///
  /// In en, this message translates to:
  /// **'Base Shipping Rate'**
  String get vendorShippingRateTitle;

  /// No description provided for @vendorShippingRateCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current rate: RM {amount}'**
  String vendorShippingRateCurrent(String amount);

  /// No description provided for @vendorProcessingTimeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Processing Time'**
  String get vendorProcessingTimeDialogTitle;

  /// No description provided for @vendorProcessingTimeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current processing time: {label}'**
  String vendorProcessingTimeCurrent(String label);

  /// No description provided for @vendorProcessingFeeDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Processing Fee'**
  String get vendorProcessingFeeDialogTitle;

  /// No description provided for @vendorProcessingFeeCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current fee: {percent}%'**
  String vendorProcessingFeeCurrent(String percent);

  /// No description provided for @vendorRefundWindowTitle.
  ///
  /// In en, this message translates to:
  /// **'Refund Window'**
  String get vendorRefundWindowTitle;

  /// No description provided for @vendorRefundWindowCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current window: {days} days'**
  String vendorRefundWindowCurrent(int days);

  /// No description provided for @vendorChatAvailabilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat Availability'**
  String get vendorChatAvailabilityTitle;

  /// No description provided for @vendorAutoResponseHint.
  ///
  /// In en, this message translates to:
  /// **'Enter automatic response message'**
  String get vendorAutoResponseHint;

  /// No description provided for @vendorDefaultVendorName.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get vendorDefaultVendorName;

  /// No description provided for @vendorReportCatBug.
  ///
  /// In en, this message translates to:
  /// **'Bug'**
  String get vendorReportCatBug;

  /// No description provided for @vendorReportCatPayment.
  ///
  /// In en, this message translates to:
  /// **'Payment Issue'**
  String get vendorReportCatPayment;

  /// No description provided for @vendorReportCatBooking.
  ///
  /// In en, this message translates to:
  /// **'Booking Problem'**
  String get vendorReportCatBooking;

  /// No description provided for @vendorReportCatAccount.
  ///
  /// In en, this message translates to:
  /// **'Account Issue'**
  String get vendorReportCatAccount;

  /// No description provided for @vendorReportCatOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get vendorReportCatOther;

  /// No description provided for @vendorChatHours247.
  ///
  /// In en, this message translates to:
  /// **'24/7'**
  String get vendorChatHours247;

  /// No description provided for @vendorChatHoursBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business Hours'**
  String get vendorChatHoursBusiness;

  /// No description provided for @vendorChatHoursCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get vendorChatHoursCustom;

  /// No description provided for @vendorSearchScrollTo.
  ///
  /// In en, this message translates to:
  /// **'Would scroll to: {name}'**
  String vendorSearchScrollTo(String name);

  /// No description provided for @vendorSliderRmLabel.
  ///
  /// In en, this message translates to:
  /// **'RM {amount}'**
  String vendorSliderRmLabel(String amount);

  /// No description provided for @vendorDepositSliderLabel.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String vendorDepositSliderLabel(int percent);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'CN':
            return AppLocalizationsZhCn();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
