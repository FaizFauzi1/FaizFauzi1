import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:eventease/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eventease/core/providers/locale_provider.dart';
import 'package:eventease/core/providers/theme_provider.dart';
import 'package:eventease/features/support/data/providers/support_provider.dart';
import 'package:eventease/features/support/data/models/support_ticket.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/currency_formatter.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/auth/presentation/login_screen.dart';
import 'package:eventease/shared/views/privacy_policy_screen.dart';
import 'package:eventease/shared/views/terms_of_service_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_profile_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_document_management_screen_fixed.dart';

class VendorSettingsScreen extends StatefulWidget {
  const VendorSettingsScreen({super.key});

  @override
  State<VendorSettingsScreen> createState() => _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends State<VendorSettingsScreen> {
  // Basic Settings
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _darkMode = false;
  String _currency = 'MYR';
  bool _autoBackup = true;
  int _dataRetentionDays = 90;

  // Business Settings
  bool _autoAcceptBookings = false;
  bool _requireDeposit = true;
  double _depositPercentage = 30.0;
  bool _weekendPricing = true;
  bool _holidayPricing = true;
  bool _bulkDiscounts = true;
  bool _loyaltyProgram = false;

  // Integration Settings
  bool _calendarSync = true;
  bool _paymentGateway = true;
  bool _socialMediaAutoPost = false;
  bool _emailMarketing = true;
  bool _smsNotifications = false;
  bool _whatsappBusiness = true;

  // Advanced Settings
  bool _advancedAnalytics = true;
  bool _customReports = false;
  bool _apiAccess = false;
  bool _webhookNotifications = false;
  bool _multiLocation = false;
  bool _staffManagement = true;
  
  // Marketplace Transfer Settings
  bool _allowBookingTransfer = false;
  bool _requireTransferApproval = true;

  // Vacation Mode Settings
  bool _vacationMode = false;
  DateTime? _vacationStartDate;
  DateTime? _vacationEndDate;
  String _vacationMessage = 'We are currently on vacation and will return soon.';

  // Shipping Settings
  bool _shippingEnabled = true;
  double _baseShippingRate = 10.0;
  bool _freeShipping = false;
  double _freeShippingThreshold = 100.0;
  bool _localDelivery = true;
  bool _internationalShipping = false;
  int _processingDays = 1;

  // Payment Settings
  bool _cashOnDelivery = true;
  bool _onlinePayment = true;
  bool _bankTransfer = true;
  bool _digitalWallet = false;
  double _processingFee = 2.5;
  bool _autoRefund = false;
  int _refundWindowDays = 7;
  bool _paymentReminders = true;

  // Chat Settings
  bool _chatSupport = true;
  bool _chatNotifications = true;
  String _chatAvailability = '24/7';
  bool _autoResponse = true;
  String _autoResponseMessage = 'Thank you for your message. We will get back to you soon!';
  bool _chatHistory = true;

  // Privacy Settings
  bool _profilePublic = true;
  bool _contactInfoVisible = false;
  bool _bookingHistoryPrivate = true;
  bool _marketingEmails = false;
  bool _dataSharing = false;
  bool _analyticsTracking = true;

  static const String _pref = 'vendor_settings_';

  static String _chatAvailLabel(AppLocalizations l10n, String stored) {
    switch (stored) {
      case '24/7':
        return l10n.vendorChatHours247;
      case 'Business Hours':
        return l10n.vendorChatHoursBusiness;
      case 'Custom':
        return l10n.vendorChatHoursCustom;
      default:
        return stored;
    }
  }

  String _processingDaysUi(AppLocalizations l10n) {
    if (_processingDays <= 1) {
      return l10n.vendorProcessingDaysOneDay(_processingDays);
    }
    return l10n.vendorProcessingDaysManyDays(_processingDays);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrateFromStorage());
  }

  Future<void> _hydrateFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final themeProvider = context.read<ThemeProvider>();
    setState(() {
      _currency = prefs.getString('${_pref}currency') ?? _currency;
      _notificationsEnabled =
          prefs.getBool('${_pref}notifications_enabled') ?? _notificationsEnabled;
      _emailNotifications =
          prefs.getBool('${_pref}email_notifications') ?? _emailNotifications;
      _allowBookingTransfer = prefs.getBool('${_pref}allow_transfer') ?? _allowBookingTransfer;
      _requireTransferApproval = prefs.getBool('${_pref}require_transfer_approval') ?? _requireTransferApproval;
      _pushNotifications =
          prefs.getBool('${_pref}push_notifications') ?? _pushNotifications;
      _dataRetentionDays =
          prefs.getInt('${_pref}data_retention_days') ?? _dataRetentionDays;
      _profilePublic = prefs.getBool('${_pref}profile_public') ?? _profilePublic;
      _contactInfoVisible =
          prefs.getBool('${_pref}contact_visible') ?? _contactInfoVisible;
      _bookingHistoryPrivate =
          prefs.getBool('${_pref}booking_private') ?? _bookingHistoryPrivate;
      _marketingEmails =
          prefs.getBool('${_pref}marketing_emails') ?? _marketingEmails;
      _darkMode = themeProvider.themeMode == ThemeMode.dark;
      _autoAcceptBookings = prefs.getBool('${_pref}auto_accept') ?? _autoAcceptBookings;
      _requireDeposit = prefs.getBool('${_pref}require_deposit') ?? _requireDeposit;
      _depositPercentage = prefs.getDouble('${_pref}deposit_pct') ?? _depositPercentage;
      _vacationMode = prefs.getBool('${_pref}vacation_mode') ?? _vacationMode;
      _shippingEnabled = prefs.getBool('${_pref}shipping_enabled') ?? _shippingEnabled;
      _freeShipping = prefs.getBool('${_pref}free_shipping') ?? _freeShipping;
      _autoRefund = prefs.getBool('${_pref}auto_refund') ?? _autoRefund;
      _weekendPricing = prefs.getBool('${_pref}weekend_pricing') ?? _weekendPricing;
      _holidayPricing = prefs.getBool('${_pref}holiday_pricing') ?? _holidayPricing;
      _loyaltyProgram = prefs.getBool('${_pref}loyalty') ?? _loyaltyProgram;
      _autoBackup = prefs.getBool('${_pref}auto_backup') ?? _autoBackup;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(l10n.vendorSettingsTitle,
            style: const TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppTheme.primaryColor),
            onPressed: _searchSettings,
            tooltip: l10n.vendorTooltipSearch,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppTheme.primaryColor),
            onPressed: _showHelpCenter,
            tooltip: l10n.vendorTooltipHelp,
          ),
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.primaryColor),
            onPressed: _saveSettings,
            tooltip: l10n.vendorTooltipSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Account Settings
            _buildSectionHeader(l10n.vendorSectionAccount),
            _buildSettingsCard([
              _buildSettingItem(
                l10n.vendorProfileInformation,
                l10n.vendorProfileInformationSubtitle,
                Icons.person,
                () => _showProfileDialog(),
              ),
              _buildSettingItem(
                l10n.vendorBusinessDetails,
                l10n.vendorBusinessDetailsSubtitle,
                Icons.business,
                () => _showBusinessDialog(),
              ),
              _buildSettingItem(
                l10n.vendorDocumentsCertifications,
                l10n.vendorDocumentsSubtitle,
                Icons.file_present,
                () => _showDocumentsDialog(),
              ),
            ]),

            const SizedBox(height: 24),

            // Notification Settings
            _buildSectionHeader(l10n.vendorSectionNotifications),
            _buildSettingsCard([
              SwitchListTile(
                value: _notificationsEnabled,
                onChanged: (value) => setState(() => _notificationsEnabled = value),
                title: Text(l10n.vendorEnableNotifications),
                subtitle: Text(l10n.vendorEnableNotificationsSubtitle),
                secondary: const Icon(Icons.notifications),
              ),
              SwitchListTile(
                value: _emailNotifications,
                onChanged: (value) => setState(() => _emailNotifications = value),
                title: Text(l10n.vendorEmailNotifications),
                subtitle: Text(l10n.vendorEmailNotificationsSubtitle),
                secondary: const Icon(Icons.email),
              ),
              SwitchListTile(
                value: _pushNotifications,
                onChanged: (value) => setState(() => _pushNotifications = value),
                title: Text(l10n.vendorPushNotifications),
                subtitle: Text(l10n.vendorPushNotificationsSubtitle),
                secondary: const Icon(Icons.smartphone),
              ),
            ]),

            const SizedBox(height: 24),

            // App Preferences
            _buildSectionHeader(l10n.vendorSectionAppPreferences),
            _buildSettingsCard([
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(l10n.vendorLanguage),
                subtitle: Text(
                  context.select<LocaleProvider, String>(
                    (p) =>
                        LocaleProvider.localeToDisplayName(p.locale),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showLanguageDialog(),
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: Text(l10n.vendorCurrency),
                subtitle: Text(_currency),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showCurrencyDialog(),
              ),
              SwitchListTile(
                value: _darkMode,
                onChanged: (value) {
                  setState(() => _darkMode = value);
                  context.read<ThemeProvider>().setThemeMode(
                        value ? ThemeMode.dark : ThemeMode.light,
                      );
                },
                title: Text(l10n.vendorDarkMode),
                subtitle: Text(l10n.vendorDarkModeSubtitle),
                secondary: const Icon(Icons.dark_mode),
              ),
            ]),

            const SizedBox(height: 24),

            // Data & Privacy
            _buildSectionHeader(l10n.vendorSectionDataPrivacy),
            _buildSettingsCard([
              SwitchListTile(
                value: _autoBackup,
                onChanged: (value) => setState(() => _autoBackup = value),
                title: Text(l10n.vendorAutoBackup),
                subtitle: Text(l10n.vendorAutoBackupSubtitle),
                secondary: const Icon(Icons.backup),
              ),
              ListTile(
                leading: const Icon(Icons.storage),
                title: Text(l10n.vendorDataRetention),
                subtitle: Text(l10n.vendorDaysCount(_dataRetentionDays)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showDataRetentionDialog(),
              ),
              // Privacy Settings
              SwitchListTile(
                value: _profilePublic,
                onChanged: (value) => setState(() => _profilePublic = value),
                title: Text(l10n.vendorPublicProfile),
                subtitle: Text(l10n.vendorPublicProfileSubtitle),
                secondary: const Icon(Icons.public),
              ),
              SwitchListTile(
                value: _contactInfoVisible,
                onChanged: (value) => setState(() => _contactInfoVisible = value),
                title: Text(l10n.vendorShowContactInfo),
                subtitle: Text(l10n.vendorShowContactInfoSubtitle),
                secondary: const Icon(Icons.contact_phone),
              ),
              SwitchListTile(
                value: _bookingHistoryPrivate,
                onChanged: (value) => setState(() => _bookingHistoryPrivate = value),
                title: Text(l10n.vendorPrivateBookingHistory),
                subtitle: Text(l10n.vendorPrivateBookingHistorySubtitle),
                secondary: const Icon(Icons.lock),
              ),
              SwitchListTile(
                value: _marketingEmails,
                onChanged: (value) => setState(() => _marketingEmails = value),
                title: Text(l10n.vendorMarketingEmails),
                subtitle: Text(l10n.vendorMarketingEmailsSubtitle),
                secondary: const Icon(Icons.mark_email_read),
              ),
              SwitchListTile(
                value: _dataSharing,
                onChanged: (value) => setState(() => _dataSharing = value),
                title: Text(l10n.vendorDataSharing),
                subtitle: Text(l10n.vendorDataSharingSubtitle),
                secondary: const Icon(Icons.share),
              ),
              SwitchListTile(
                value: _analyticsTracking,
                onChanged: (value) => setState(() => _analyticsTracking = value),
                title: Text(l10n.vendorAnalyticsTracking),
                subtitle: Text(l10n.vendorAnalyticsTrackingSubtitle),
                secondary: const Icon(Icons.analytics),
              ),
              ListTile(
                leading: const Icon(Icons.privacy_tip),
                title: Text(l10n.vendorPrivacyPolicy),
                subtitle: Text(l10n.vendorPrivacyPolicySubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showPrivacyPolicy(),
              ),
              ListTile(
                leading: const Icon(Icons.description),
                title: Text(l10n.vendorTermsOfService),
                subtitle: Text(l10n.vendorTermsOfServiceSubtitle),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showTermsOfService(),
              ),
            ]),

            const SizedBox(height: 24),

            // Business Settings
            _buildSectionHeader(l10n.vendorSectionBusinessOperations),
            _buildSettingsCard([
              SwitchListTile(
                value: _autoAcceptBookings,
                onChanged: (value) => setState(() => _autoAcceptBookings = value),
                title: Text(l10n.vendorAutoAcceptBookings),
                subtitle: Text(l10n.vendorAutoAcceptBookingsSubtitle),
                secondary: const Icon(Icons.check_circle),
              ),
              SwitchListTile(
                value: _requireDeposit,
                onChanged: (value) => setState(() => _requireDeposit = value),
                title: Text(l10n.vendorRequireDeposit),
                subtitle: Text(l10n.vendorDepositSubtitle(_depositPercentage.round())),
                secondary: const Icon(Icons.account_balance_wallet),
              ),
              SwitchListTile(
                value: _allowBookingTransfer,
                onChanged: (value) => setState(() => _allowBookingTransfer = value),
                title: const Text('Allow Booking Transfers'),
                subtitle: const Text('Let customers transfer bookings to others'),
                secondary: const Icon(Icons.swap_horiz),
              ),
              if (_allowBookingTransfer)
                SwitchListTile(
                  value: _requireTransferApproval,
                  onChanged: (value) => setState(() => _requireTransferApproval = value),
                  title: const Text('Require Transfer Approval'),
                  subtitle: const Text('Review and approve transfers manually'),
                  secondary: const Icon(Icons.fact_check),
                ),
              ListTile(
                leading: const Icon(Icons.percent, color: AppTheme.primaryColor),
                title: Text(l10n.vendorDepositPercentage),
                subtitle: Slider(
                  value: _depositPercentage,
                  onChanged: (value) => setState(() => _depositPercentage = value),
                  min: 10,
                  max: 50,
                  divisions: 4,
                  label: l10n.vendorDepositSliderLabel(_depositPercentage.round()),
                ),
              ),
              SwitchListTile(
                value: _weekendPricing,
                onChanged: (value) => setState(() => _weekendPricing = value),
                title: Text(l10n.vendorWeekendPricing),
                subtitle: Text(l10n.vendorWeekendPricingSubtitle),
                secondary: const Icon(Icons.weekend),
              ),
              SwitchListTile(
                value: _holidayPricing,
                onChanged: (value) => setState(() => _holidayPricing = value),
                title: Text(l10n.vendorHolidayPricing),
                subtitle: Text(l10n.vendorHolidayPricingSubtitle),
                secondary: const Icon(Icons.celebration),
              ),
              SwitchListTile(
                value: _bulkDiscounts,
                onChanged: (value) => setState(() => _bulkDiscounts = value),
                title: Text(l10n.vendorBulkDiscounts),
                subtitle: Text(l10n.vendorBulkDiscountsSubtitle),
                secondary: const Icon(Icons.discount),
              ),
              SwitchListTile(
                value: _loyaltyProgram,
                onChanged: (value) => setState(() => _loyaltyProgram = value),
                title: Text(l10n.vendorLoyaltyProgram),
                subtitle: Text(l10n.vendorLoyaltyProgramSubtitle),
                secondary: const Icon(Icons.loyalty),
              ),
              // Vacation Mode Settings
              SwitchListTile(
                value: _vacationMode,
                onChanged: (value) => setState(() => _vacationMode = value),
                title: Text(l10n.vendorVacationMode),
                subtitle: Text(l10n.vendorVacationModeSubtitle),
                secondary: const Icon(Icons.beach_access),
              ),
              if (_vacationMode) ...[
                ListTile(
                  leading: const Icon(Icons.date_range, color: AppTheme.primaryColor),
                  title: Text(l10n.vendorVacationPeriod),
                  subtitle: Text(
                    _vacationStartDate != null && _vacationEndDate != null
                        ? '${_vacationStartDate!.toString().split(' ')[0]} - ${_vacationEndDate!.toString().split(' ')[0]}'
                        : l10n.vendorVacationSetDates,
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showVacationPeriodDialog(),
                ),
                ListTile(
                  leading: const Icon(Icons.message, color: AppTheme.primaryColor),
                  title: Text(l10n.vendorVacationMessage),
                  subtitle: Text(_vacationMessage.length > 30
                      ? '${_vacationMessage.substring(0, 30)}...'
                      : _vacationMessage),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showVacationMessageDialog(),
                ),
              ],
            ]),

            const SizedBox(height: 24),

            // Shipping Settings
            _buildSectionHeader(l10n.vendorSectionShippingDelivery),
            _buildSettingsCard([
              SwitchListTile(
                value: _shippingEnabled,
                onChanged: (value) => setState(() => _shippingEnabled = value),
                title: Text(l10n.vendorEnableShipping),
                subtitle: Text(l10n.vendorEnableShippingSubtitle),
                secondary: const Icon(Icons.local_shipping),
              ),
              if (_shippingEnabled) ...[
                ListTile(
                  leading: const Icon(Icons.attach_money, color: AppTheme.primaryColor),
                  title: Text(l10n.vendorBaseShippingRate),
                  subtitle: Text(l10n.vendorBaseShippingRateAmount(_baseShippingRate.toStringAsFixed(2))),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showShippingRateDialog(),
                ),
                SwitchListTile(
                  value: _freeShipping,
                  onChanged: (value) => setState(() => _freeShipping = value),
                  title: Text(l10n.vendorFreeShipping),
                  subtitle: Text(l10n.vendorFreeShippingSubtitle(_freeShippingThreshold.toStringAsFixed(2))),
                  secondary: const Icon(Icons.free_breakfast),
                ),
                if (_freeShipping) ...[
                  ListTile(
                    leading: const Icon(Icons.trending_up, color: AppTheme.primaryColor),
                    title: Text(l10n.vendorFreeShippingThreshold),
                    subtitle: Slider(
                      value: _freeShippingThreshold,
                      onChanged: (value) => setState(() => _freeShippingThreshold = value),
                      min: 50,
                      max: 500,
                      divisions: 9,
                      label: l10n.vendorSliderRmLabel(_freeShippingThreshold.toStringAsFixed(0)),
                    ),
                  ),
                ],
                SwitchListTile(
                  value: _localDelivery,
                  onChanged: (value) => setState(() => _localDelivery = value),
                  title: Text(l10n.vendorLocalDelivery),
                  subtitle: Text(l10n.vendorLocalDeliverySubtitle),
                  secondary: const Icon(Icons.location_on),
                ),
                SwitchListTile(
                  value: _internationalShipping,
                  onChanged: (value) => setState(() => _internationalShipping = value),
                  title: Text(l10n.vendorInternationalShipping),
                  subtitle: Text(l10n.vendorInternationalShippingSubtitle),
                  secondary: const Icon(Icons.public),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule, color: AppTheme.primaryColor),
                  title: Text(l10n.vendorProcessingTime),
                  subtitle: Text(_processingDaysUi(l10n)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showProcessingTimeDialog(),
                ),
              ],
            ]),

            const SizedBox(height: 24),

            // Payment Settings
            _buildSectionHeader(l10n.vendorSectionPaymentBilling),
            _buildSettingsCard([
              SwitchListTile(
                value: _cashOnDelivery,
                onChanged: (value) => setState(() => _cashOnDelivery = value),
                title: Text(l10n.vendorCashOnDelivery),
                subtitle: Text(l10n.vendorCashOnDeliverySubtitle),
                secondary: const Icon(Icons.money),
              ),
              SwitchListTile(
                value: _onlinePayment,
                onChanged: (value) => setState(() => _onlinePayment = value),
                title: Text(l10n.vendorOnlinePayment),
                subtitle: Text(l10n.vendorOnlinePaymentSubtitle),
                secondary: const Icon(Icons.credit_card),
              ),
              SwitchListTile(
                value: _bankTransfer,
                onChanged: (value) => setState(() => _bankTransfer = value),
                title: Text(l10n.vendorBankTransfer),
                subtitle: Text(l10n.vendorBankTransferSubtitle),
                secondary: const Icon(Icons.account_balance),
              ),
              SwitchListTile(
                value: _digitalWallet,
                onChanged: (value) => setState(() => _digitalWallet = value),
                title: Text(l10n.vendorDigitalWallet),
                subtitle: Text(l10n.vendorDigitalWalletSubtitle),
                secondary: const Icon(Icons.account_balance_wallet),
              ),
              ListTile(
                leading: const Icon(Icons.percent, color: AppTheme.primaryColor),
                title: Text(l10n.vendorProcessingFee),
                subtitle: Text(l10n.vendorProcessingFeePercent(_processingFee.toStringAsFixed(1))),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () => _showProcessingFeeDialog(),
              ),
              SwitchListTile(
                value: _autoRefund,
                onChanged: (value) => setState(() => _autoRefund = value),
                title: Text(l10n.vendorAutoRefund),
                subtitle: Text(l10n.vendorAutoRefundSubtitle),
                secondary: const Icon(Icons.undo),
              ),
              if (_autoRefund) ...[
                ListTile(
                  leading: const Icon(Icons.access_time, color: AppTheme.primaryColor),
                  title: Text(l10n.vendorRefundWindow),
                  subtitle: Text(l10n.vendorDaysCount(_refundWindowDays)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showRefundWindowDialog(),
                ),
              ],
              SwitchListTile(
                value: _paymentReminders,
                onChanged: (value) => setState(() => _paymentReminders = value),
                title: Text(l10n.vendorPaymentReminders),
                subtitle: Text(l10n.vendorPaymentRemindersSubtitle),
                secondary: const Icon(Icons.notifications_active),
              ),
            ]),

            const SizedBox(height: 24),

            // Integration Settings
            _buildSectionHeader(l10n.vendorSectionIntegrations),
            _buildSettingsCard([
              SwitchListTile(
                value: _calendarSync,
                onChanged: (value) => setState(() => _calendarSync = value),
                title: Text(l10n.vendorCalendarSync),
                subtitle: Text(l10n.vendorCalendarSyncSubtitle),
                secondary: const Icon(Icons.calendar_today),
              ),
              SwitchListTile(
                value: _paymentGateway,
                onChanged: (value) => setState(() => _paymentGateway = value),
                title: Text(l10n.vendorPaymentGateway),
                subtitle: Text(l10n.vendorPaymentGatewaySubtitle),
                secondary: const Icon(Icons.payment),
              ),
              SwitchListTile(
                value: _socialMediaAutoPost,
                onChanged: (value) => setState(() => _socialMediaAutoPost = value),
                title: Text(l10n.vendorAutoSocialMediaPosts),
                subtitle: Text(l10n.vendorAutoSocialMediaPostsSubtitle),
                secondary: const Icon(Icons.share),
              ),
              SwitchListTile(
                value: _emailMarketing,
                onChanged: (value) => setState(() => _emailMarketing = value),
                title: Text(l10n.vendorEmailMarketing),
                subtitle: Text(l10n.vendorEmailMarketingSubtitle),
                secondary: const Icon(Icons.mark_email_read),
              ),
              SwitchListTile(
                value: _smsNotifications,
                onChanged: (value) => setState(() => _smsNotifications = value),
                title: Text(l10n.vendorSmsNotifications),
                subtitle: Text(l10n.vendorSmsNotificationsSubtitle),
                secondary: const Icon(Icons.sms),
              ),
              SwitchListTile(
                value: _whatsappBusiness,
                onChanged: (value) => setState(() => _whatsappBusiness = value),
                title: Text(l10n.vendorWhatsappBusinessTile),
                subtitle: Text(l10n.vendorWhatsappBusinessTileSubtitle),
                secondary: const Icon(Icons.message),
              ),
              // Chat Settings
              SwitchListTile(
                value: _chatSupport,
                onChanged: (value) => setState(() => _chatSupport = value),
                title: Text(l10n.vendorChatSupport),
                subtitle: Text(l10n.vendorChatSupportSubtitle),
                secondary: const Icon(Icons.chat),
              ),
              if (_chatSupport) ...[
                SwitchListTile(
                  value: _chatNotifications,
                  onChanged: (value) => setState(() => _chatNotifications = value),
                  title: Text(l10n.vendorChatNotifications),
                  subtitle: Text(l10n.vendorChatNotificationsSubtitle),
                  secondary: const Icon(Icons.notifications),
                ),
                ListTile(
                  leading: const Icon(Icons.schedule, color: AppTheme.primaryColor),
                  title: Text(l10n.vendorChatAvailability),
                  subtitle: Text(_chatAvailLabel(l10n, _chatAvailability)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showChatAvailabilityDialog(),
                ),
                SwitchListTile(
                  value: _autoResponse,
                  onChanged: (value) => setState(() => _autoResponse = value),
                  title: Text(l10n.vendorAutoResponse),
                  subtitle: Text(l10n.vendorAutoResponseSubtitle),
                  secondary: const Icon(Icons.smart_toy),
                ),
                if (_autoResponse) ...[
                  ListTile(
                    leading: const Icon(Icons.message, color: AppTheme.primaryColor),
                    title: Text(l10n.vendorAutoResponseMessage),
                    subtitle: Text(_autoResponseMessage.length > 30
                        ? '${_autoResponseMessage.substring(0, 30)}...'
                        : _autoResponseMessage),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showAutoResponseDialog(),
                  ),
                ],
                SwitchListTile(
                  value: _chatHistory,
                  onChanged: (value) => setState(() => _chatHistory = value),
                  title: Text(l10n.vendorChatHistory),
                  subtitle: Text(l10n.vendorChatHistorySubtitle),
                  secondary: const Icon(Icons.history),
                ),
              ],
            ]),

            const SizedBox(height: 24),

            // Advanced Settings
            _buildSectionHeader(l10n.vendorSectionAdvancedFeatures),
            _buildSettingsCard([
              SwitchListTile(
                value: _advancedAnalytics,
                onChanged: (value) => setState(() => _advancedAnalytics = value),
                title: Text(l10n.vendorAdvancedAnalytics),
                subtitle: Text(l10n.vendorAdvancedAnalyticsSubtitle),
                secondary: const Icon(Icons.analytics),
              ),
              SwitchListTile(
                value: _customReports,
                onChanged: (value) => setState(() => _customReports = value),
                title: Text(l10n.vendorCustomReports),
                subtitle: Text(l10n.vendorCustomReportsSubtitle),
                secondary: const Icon(Icons.assessment),
              ),
              SwitchListTile(
                value: _apiAccess,
                onChanged: (value) => setState(() => _apiAccess = value),
                title: Text(l10n.vendorApiAccess),
                subtitle: Text(l10n.vendorApiAccessSubtitle),
                secondary: const Icon(Icons.api),
              ),
              SwitchListTile(
                value: _webhookNotifications,
                onChanged: (value) => setState(() => _webhookNotifications = value),
                title: Text(l10n.vendorWebhookNotifications),
                subtitle: Text(l10n.vendorWebhookNotificationsSubtitle),
                secondary: const Icon(Icons.webhook),
              ),
              SwitchListTile(
                value: _multiLocation,
                onChanged: (value) => setState(() => _multiLocation = value),
                title: Text(l10n.vendorMultiLocationSupport),
                subtitle: Text(l10n.vendorMultiLocationSupportSubtitle),
                secondary: const Icon(Icons.location_on),
              ),
              SwitchListTile(
                value: _staffManagement,
                onChanged: (value) => setState(() => _staffManagement = value),
                title: Text(l10n.vendorStaffManagement),
                subtitle: Text(l10n.vendorStaffManagementSubtitle),
                secondary: const Icon(Icons.people),
              ),
            ]),

            const SizedBox(height: 24),

            // Business Analytics
            _buildSectionHeader(l10n.vendorSectionBusinessAnalytics),
            _buildSettingsCard([
              _buildSettingItem(
                l10n.vendorFinancialReports,
                l10n.vendorFinancialReportsSubtitle,
                Icons.analytics,
                () => _showFinancialReportsDialog(),
              ),
              _buildSettingItem(
                l10n.vendorPerformanceMetrics,
                l10n.vendorPerformanceMetricsSubtitle,
                Icons.trending_up,
                () => _showPerformanceMetricsDialog(),
              ),
              _buildSettingItem(
                l10n.vendorExportData,
                l10n.vendorExportDataSubtitle,
                Icons.download,
                () => _showExportDialog(),
              ),
            ]),

            const SizedBox(height: 24),

            // Support & Help
            _buildSectionHeader(l10n.vendorSectionSupportHelp),
            _buildSettingsCard([
              _buildSettingItem(
                l10n.vendorHelpCenter,
                l10n.vendorHelpCenterSubtitle,
                Icons.help,
                () => _showHelpCenter(),
              ),
              _buildSettingItem(
                l10n.vendorContactSupport,
                l10n.vendorContactSupportSubtitle,
                Icons.support,
                () => _showContactSupport(),
              ),
              _buildSettingItem(
                l10n.vendorReportIssue,
                l10n.vendorReportIssueSubtitle,
                Icons.bug_report,
                () => _showReportIssue(),
              ),
              ListTile(
                leading: const Icon(Icons.info, color: AppTheme.primaryColor),
                title: Text(l10n.vendorAppVersion),
                subtitle: Text(l10n.vendorAppVersionNumber),
              ),
            ]),

            const SizedBox(height: 32),

            // Danger Zone
            _buildSectionHeader(l10n.vendorSectionAccountDanger, color: Colors.red),
            _buildSettingsCard([
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.orange),
                title: Text(l10n.vendorSignOut),
                subtitle: Text(l10n.vendorSignOutSubtitle),
                onTap: () => _showSignOutDialog(),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(l10n.vendorDeleteAccount),
                subtitle: Text(l10n.vendorDeleteAccountSubtitle),
                onTap: () => _showDeleteAccountDialog(),
              ),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color color = AppTheme.primaryColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
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
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // Dialog Methods
  void _showProfileDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const VendorProfileScreen()),
    );
  }

  void _showBusinessDialog() {
    final l10n = AppLocalizations.of(context)!;
    final namCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final websiteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorBusinessDetailsTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.vendorBusinessDetailsIntro,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: namCtrl,
                decoration: InputDecoration(
                  labelText: l10n.vendorBusinessName,
                  prefixIcon: const Icon(Icons.business),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l10n.vendorBusinessDescription,
                  prefixIcon: const Icon(Icons.notes),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: l10n.vendorBusinessPhone,
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: websiteCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.vendorBusinessWebsite,
                  prefixIcon: const Icon(Icons.web),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.vendorBusinessUpdated),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showDocumentsDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const VendorDocumentManagementScreen(),
      ),
    );
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        // Dialog is a separate route: parent setState does not rebuild this UI.
        // Keep selection in StatefulBuilder so radios update immediately.
        String selected = LocaleProvider.localeToDisplayName(
          dialogContext.read<LocaleProvider>().locale,
        );
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.vendorSelectLanguage),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(l10n.vendorLangEnglish),
                    value: 'English',
                    groupValue: selected,
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selected = v);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(l10n.vendorLangMalay),
                    value: 'Bahasa Malaysia',
                    groupValue: selected,
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selected = v);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(l10n.vendorLangChinese),
                    value: '中文',
                    groupValue: selected,
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selected = v);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => navigator.pop(),
                  child: Text(l10n.commonCancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final code =
                        LocaleProvider.displayNameToCode(selected);
                    await dialogContext
                        .read<LocaleProvider>()
                        .setLocaleByCode(code);
                    if (dialogContext.mounted) navigator.pop();
                  },
                  child: Text(l10n.commonSave),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCurrencyDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorSelectCurrency),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(l10n.vendorCurrencyMyr),
              leading: Radio<String>(
                value: 'MYR',
                groupValue: _currency,
                onChanged: (value) => setState(() => _currency = value!),
              ),
              onTap: () => setState(() => _currency = 'MYR'),
            ),
            ListTile(
              title: Text(l10n.vendorCurrencyUsd),
              leading: Radio<String>(
                value: 'USD',
                groupValue: _currency,
                onChanged: (value) => setState(() => _currency = value!),
              ),
              onTap: () => setState(() => _currency = 'USD'),
            ),
            ListTile(
              title: Text(l10n.vendorCurrencySgd),
              leading: Radio<String>(
                value: 'SGD',
                groupValue: _currency,
                onChanged: (value) => setState(() => _currency = value!),
              ),
              onTap: () => setState(() => _currency = 'SGD'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('${_pref}currency', _currency);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showDataRetentionDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorDataRetentionPeriod),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.vendorDataRetentionKeep(_dataRetentionDays)),
            Slider(
              value: _dataRetentionDays.toDouble(),
              onChanged: (value) => setState(() => _dataRetentionDays = value.round()),
              min: 30,
              max: 365,
              divisions: 11,
              label: l10n.vendorDaysCount(_dataRetentionDays),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setInt('${_pref}data_retention_days', _dataRetentionDays);
              if (context.mounted) Navigator.of(context).pop();
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showFinancialReportsDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorFinancialReports),
        content: Text(l10n.vendorFinancialReportsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showPerformanceMetricsDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorPerformanceMetrics),
        content: Text(l10n.vendorPerformanceMetricsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showExportDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorExportData),
        content: Text(l10n.vendorExportDataBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonExport),
          ),
        ],
      ),
    );
  }

  void _showHelpCenter() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorHelpCenterDialogTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.vendorHelpWelcome),
              const SizedBox(height: 16),
              Text(l10n.vendorHelpBulletAccount),
              const SizedBox(height: 8),
              Text(l10n.vendorHelpBulletNotifications),
              const SizedBox(height: 8),
              Text(l10n.vendorHelpBulletBusiness),
              const SizedBox(height: 8),
              Text(l10n.vendorHelpBulletIntegrations),
              const SizedBox(height: 8),
              Text(l10n.vendorHelpBulletAdvanced),
              const SizedBox(height: 8),
              Text(l10n.vendorHelpBulletAnalytics),
              const SizedBox(height: 8),
              Text(l10n.vendorHelpContactTeam),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonClose),
          ),
        ],
      ),
    );
  }

  void _showContactSupport() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.support_agent, color: AppTheme.primaryColor, size: 28),
                const SizedBox(width: 12),
                Text(
                  l10n.vendorContactSupportSheetTitle,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.vendorContactSupportHours,
              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.email, color: AppTheme.primaryColor),
              ),
              title: Text(l10n.vendorEmailSupport),
              subtitle: const Text('vendors@eventease.com'),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse(
                  'mailto:vendors@eventease.com?subject=EventEase%20Vendor%20Support',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.vendorSnackEmail)),
                  );
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone, color: AppTheme.primaryColor),
              ),
              title: Text(l10n.vendorCallUs),
              subtitle: const Text('+60 3-1234 5678'),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('tel:+60312345678');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.vendorSnackPhone)),
                  );
                }
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.chat, color: AppTheme.primaryColor),
              ),
              title: Text(l10n.vendorWhatsappBusiness),
              subtitle: const Text('+60 11-1234 5678'),
              onTap: () async {
                Navigator.pop(ctx);
                final uri = Uri.parse('https://wa.me/601112345678');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.vendorSnackWhatsapp)),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReportIssue() {
    final l10n = AppLocalizations.of(context)!;
    final issueCtrl = TextEditingController();
    String selectedCategory = 'Bug';
    final reportCategories = <String, String>{
      'Bug': l10n.vendorReportCatBug,
      'Payment Issue': l10n.vendorReportCatPayment,
      'Booking Problem': l10n.vendorReportCatBooking,
      'Account Issue': l10n.vendorReportCatAccount,
      'Other': l10n.vendorReportCatOther,
    };

    TicketCategory mapCategory(String c) {
      switch (c) {
        case 'Payment Issue':
          return TicketCategory.payment;
        case 'Booking Problem':
          return TicketCategory.booking;
        case 'Account Issue':
          return TicketCategory.account;
        case 'Bug':
          return TicketCategory.technical;
        default:
          return TicketCategory.general;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.bug_report, color: Colors.red, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        l10n.vendorReportIssueTitle,
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.vendorReportCategory,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: reportCategories.entries
                        .map((e) =>
                            DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => selectedCategory = v!),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.vendorReportDescribeIssue,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: issueCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: l10n.vendorReportIssueHint,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.send),
                      label: Text(l10n.vendorReportSubmit),
                      onPressed: () async {
                        final text = issueCtrl.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(l10n.vendorReportDescribeEmpty)),
                          );
                          return;
                        }
                        final auth =
                            Provider.of<AuthProvider>(context, listen: false);
                        final support =
                            Provider.of<SupportProvider>(context, listen: false);
                        final uid = auth.userId ??
                            Supabase.instance.client.auth.currentUser?.id;
                        final email = auth.userEmail.isNotEmpty
                            ? auth.userEmail
                            : (Supabase.instance.client.auth.currentUser
                                    ?.email ??
                                '');
                        final name = auth.userName.isNotEmpty
                            ? auth.userName
                            : l10n.vendorDefaultVendorName;
                        if (uid == null || uid.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.vendorReportSignInRequired),
                              ),
                            );
                          }
                          return;
                        }
                        try {
                          await support.createTicket(
                            customerId: uid,
                            customerName: name,
                            customerEmail: email,
                            subject: '[Vendor] $selectedCategory',
                            description: text,
                            category: mapCategory(selectedCategory),
                            priority: selectedCategory == 'Payment Issue'
                                ? TicketPriority.high
                                : TicketPriority.medium,
                          );
                          if (kDebugMode) {
                            debugPrint(
                              '[VendorSettings] Report issue: success (ticket created)',
                            );
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(l10n.vendorReportSuccess),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          }
                        } catch (e) {
                          if (kDebugMode) {
                            debugPrint(
                              '[VendorSettings] Report issue: error $e',
                            );
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.vendorReportCouldNotSubmit('$e'),
                                ),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(issueCtrl.dispose);
  }

  void _showPrivacyPolicy() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  void _showTermsOfService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TermsOfServiceScreen(initialTab: 1),
      ),
    );
  }

  void _showSignOutDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorSignOutDialogTitle),
        content: Text(l10n.vendorSignOutDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final authProvider =
                  Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(l10n.vendorSignOut),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorDeleteAccountDialogTitle),
        content: Text(l10n.vendorDeleteAccountDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(l10n.vendorDeleteAccount),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_pref}notifications_enabled', _notificationsEnabled);
    await prefs.setBool('${_pref}email_notifications', _emailNotifications);
    await prefs.setBool('${_pref}push_notifications', _pushNotifications);
    await prefs.setString('${_pref}currency', _currency);
    await CurrencyFormatter.updateCurrency(_currency);
    await prefs.setInt('${_pref}data_retention_days', _dataRetentionDays);
    await prefs.setBool('${_pref}profile_public', _profilePublic);
    await prefs.setBool('${_pref}contact_visible', _contactInfoVisible);
    await prefs.setBool('${_pref}booking_private', _bookingHistoryPrivate);
    await prefs.setBool('${_pref}marketing_emails', _marketingEmails);
    await prefs.setBool('${_pref}allow_transfer', _allowBookingTransfer);
    await prefs.setBool('${_pref}require_transfer_approval', _requireTransferApproval);
    await prefs.setBool('${_pref}auto_accept', _autoAcceptBookings);
    await prefs.setBool('${_pref}require_deposit', _requireDeposit);
    await prefs.setDouble('${_pref}deposit_pct', _depositPercentage);
    await prefs.setBool('${_pref}vacation_mode', _vacationMode);
    await prefs.setBool('${_pref}shipping_enabled', _shippingEnabled);
    await prefs.setBool('${_pref}free_shipping', _freeShipping);
    await prefs.setBool('${_pref}auto_refund', _autoRefund);
    await prefs.setBool('${_pref}weekend_pricing', _weekendPricing);
    await prefs.setBool('${_pref}holiday_pricing', _holidayPricing);
    await prefs.setBool('${_pref}loyalty', _loyaltyProgram);
    await prefs.setBool('${_pref}auto_backup', _autoBackup);
    final lp = context.read<LocaleProvider>();
    await lp.setLocaleByCode(LocaleProvider.localeToCode(lp.locale));
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.vendorSettingsSaved),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _searchSettings() {
    final l10n = AppLocalizations.of(context)!;
    showSearch(
      context: context,
      delegate: SettingsSearchDelegate(l10n),
    );
  }

  // Vacation Mode Dialog Methods
  void _showVacationPeriodDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorVacationPeriodTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.vendorVacationStartDate),
              subtitle: Text(_vacationStartDate?.toString().split(' ')[0] ?? l10n.vendorNotSet),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _vacationStartDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _vacationStartDate = date);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.vendorVacationEndDate),
              subtitle: Text(_vacationEndDate?.toString().split(' ')[0] ?? l10n.vendorNotSet),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _vacationEndDate ?? (_vacationStartDate ?? DateTime.now()).add(const Duration(days: 1)),
                  firstDate: _vacationStartDate ?? DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _vacationEndDate = date);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showVacationMessageDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _vacationMessage);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorVacationMessageTitle),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.vendorVacationMessageHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _vacationMessage = controller.text);
              Navigator.of(context).pop();
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  // Shipping Settings Dialog Methods
  void _showShippingRateDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorShippingRateTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.vendorShippingRateCurrent(_baseShippingRate.toStringAsFixed(2))),
            Slider(
              value: _baseShippingRate,
              onChanged: (value) => setState(() => _baseShippingRate = value),
              min: 5.0,
              max: 50.0,
              divisions: 18,
              label: l10n.vendorBaseShippingRateAmount(_baseShippingRate.toStringAsFixed(2)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showProcessingTimeDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorProcessingTimeDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.vendorProcessingTimeCurrent(_processingDaysUi(l10n))),
            Slider(
              value: _processingDays.toDouble(),
              onChanged: (value) => setState(() => _processingDays = value.round()),
              min: 1,
              max: 7,
              divisions: 6,
              label: _processingDaysUi(l10n),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  // Payment Settings Dialog Methods
  void _showProcessingFeeDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorProcessingFeeDialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.vendorProcessingFeeCurrent(_processingFee.toStringAsFixed(1))),
            Slider(
              value: _processingFee,
              onChanged: (value) => setState(() => _processingFee = value),
              min: 0.0,
              max: 10.0,
              divisions: 20,
              label: l10n.vendorProcessingFeePercent(_processingFee.toStringAsFixed(1)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showRefundWindowDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorRefundWindowTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.vendorRefundWindowCurrent(_refundWindowDays)),
            Slider(
              value: _refundWindowDays.toDouble(),
              onChanged: (value) => setState(() => _refundWindowDays = value.round()),
              min: 1,
              max: 30,
              divisions: 29,
              label: l10n.vendorDaysCount(_refundWindowDays),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  // Chat Settings Dialog Methods
  void _showChatAvailabilityDialog() {
    final l10n = AppLocalizations.of(context)!;
    final List<String> availabilityOptions = ['24/7', 'Business Hours', 'Custom'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorChatAvailabilityTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availabilityOptions.map((option) {
            return RadioListTile<String>(
              value: option,
              groupValue: _chatAvailability,
              onChanged: (value) => setState(() => _chatAvailability = value!),
              title: Text(_chatAvailLabel(l10n, option)),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  void _showAutoResponseDialog() {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: _autoResponseMessage);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.vendorAutoResponseMessage),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: l10n.vendorAutoResponseHint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _autoResponseMessage = controller.text);
              Navigator.of(context).pop();
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}

// Settings Search Delegate
class SettingsSearchDelegate extends SearchDelegate<String> {
  SettingsSearchDelegate(this.l10n);

  final AppLocalizations l10n;

  List<String> get _settingsOptions => [
    l10n.vendorSectionAccount,
    l10n.vendorSectionNotifications,
    l10n.vendorSectionBusinessOperations,
    l10n.vendorSectionShippingDelivery,
    l10n.vendorSectionPaymentBilling,
    l10n.vendorSectionIntegrations,
    l10n.vendorSectionAdvancedFeatures,
    l10n.vendorSectionBusinessAnalytics,
    l10n.vendorProfileInformation,
    l10n.vendorBusinessDetails,
    l10n.vendorDocumentsCertifications,
    l10n.vendorAutoAcceptBookings,
    l10n.vendorRequireDeposit,
    l10n.vendorWeekendPricing,
    l10n.vendorHolidayPricing,
    l10n.vendorBulkDiscounts,
    l10n.vendorLoyaltyProgram,
    l10n.vendorVacationMode,
    l10n.vendorVacationPeriod,
    l10n.vendorVacationMessage,
    l10n.vendorEnableShipping,
    l10n.vendorBaseShippingRate,
    l10n.vendorFreeShipping,
    l10n.vendorFreeShippingThreshold,
    l10n.vendorLocalDelivery,
    l10n.vendorInternationalShipping,
    l10n.vendorProcessingTime,
    l10n.vendorCashOnDelivery,
    l10n.vendorOnlinePayment,
    l10n.vendorBankTransfer,
    l10n.vendorDigitalWallet,
    l10n.vendorProcessingFee,
    l10n.vendorAutoRefund,
    l10n.vendorRefundWindow,
    l10n.vendorPaymentReminders,
    l10n.vendorCalendarSync,
    l10n.vendorPaymentGateway,
    l10n.vendorAutoSocialMediaPosts,
    l10n.vendorEmailMarketing,
    l10n.vendorSmsNotifications,
    l10n.vendorWhatsappBusinessTile,
    l10n.vendorChatSupport,
    l10n.vendorChatNotifications,
    l10n.vendorChatAvailability,
    l10n.vendorAutoResponse,
    l10n.vendorAutoResponseMessage,
    l10n.vendorChatHistory,
    l10n.vendorAdvancedAnalytics,
    l10n.vendorCustomReports,
    l10n.vendorApiAccess,
    l10n.vendorWebhookNotifications,
    l10n.vendorMultiLocationSupport,
    l10n.vendorStaffManagement,
    l10n.vendorPublicProfile,
    l10n.vendorShowContactInfo,
    l10n.vendorPrivateBookingHistory,
    l10n.vendorMarketingEmails,
    l10n.vendorDataSharing,
    l10n.vendorAnalyticsTracking,
    l10n.vendorFinancialReports,
    l10n.vendorPerformanceMetrics,
    l10n.vendorExportData,
  ];

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _settingsOptions
        .where((option) => option.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index]),
          onTap: () {
            close(context, results[index]);
            _scrollToSection(context, results[index]);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = _settingsOptions
        .where((option) => option.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestions[index]),
          onTap: () {
            query = suggestions[index];
            showResults(context);
          },
        );
      },
    );
  }

  void _scrollToSection(BuildContext context, String sectionName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.vendorSearchScrollTo(sectionName))),
    );
  }
}
