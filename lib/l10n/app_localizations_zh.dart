// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonClose => '关闭';

  @override
  String get commonExport => '导出';

  @override
  String get commonGotIt => '知道了';

  @override
  String get vendorSettingsTitle => '设置';

  @override
  String get vendorTooltipSearch => '搜索设置';

  @override
  String get vendorTooltipHelp => '帮助';

  @override
  String get vendorTooltipSave => '保存设置';

  @override
  String get vendorSectionAccount => '账户设置';

  @override
  String get vendorSectionNotifications => '通知';

  @override
  String get vendorSectionAppPreferences => '应用偏好';

  @override
  String get vendorSectionDataPrivacy => '数据与隐私';

  @override
  String get vendorSectionBusinessOperations => '业务运营';

  @override
  String get vendorSectionShippingDelivery => '配送与交货';

  @override
  String get vendorSectionPaymentBilling => '付款与账单';

  @override
  String get vendorSectionIntegrations => '集成';

  @override
  String get vendorSectionAdvancedFeatures => '高级功能';

  @override
  String get vendorSectionBusinessAnalytics => '商业分析';

  @override
  String get vendorSectionSupportHelp => '支持与帮助';

  @override
  String get vendorSectionAccountDanger => '账户';

  @override
  String get vendorProfileInformation => '资料信息';

  @override
  String get vendorProfileInformationSubtitle => '管理您的商家资料';

  @override
  String get vendorBusinessDetails => '商家详情';

  @override
  String get vendorBusinessDetailsSubtitle => '更新商家信息';

  @override
  String get vendorDocumentsCertifications => '证件与认证';

  @override
  String get vendorDocumentsSubtitle => '管理法律文件';

  @override
  String get vendorEnableNotifications => '启用通知';

  @override
  String get vendorEnableNotificationsSubtitle => '接收预订和系统通知';

  @override
  String get vendorEmailNotifications => '邮件通知';

  @override
  String get vendorEmailNotificationsSubtitle => '通过电子邮件接收通知';

  @override
  String get vendorPushNotifications => '推送通知';

  @override
  String get vendorPushNotificationsSubtitle => '在手机上接收推送通知';

  @override
  String get vendorLanguage => '语言';

  @override
  String get vendorCurrency => '货币';

  @override
  String get vendorDarkMode => '深色模式';

  @override
  String get vendorDarkModeSubtitle => '切换到深色主题';

  @override
  String get vendorAutoBackup => '自动备份';

  @override
  String get vendorAutoBackupSubtitle => '自动备份您的数据';

  @override
  String get vendorDataRetention => '数据保留';

  @override
  String get vendorPublicProfile => '公开资料';

  @override
  String get vendorPublicProfileSubtitle => '向所有人展示商家资料';

  @override
  String get vendorShowContactInfo => '显示联系方式';

  @override
  String get vendorShowContactInfoSubtitle => '公开显示联系信息';

  @override
  String get vendorPrivateBookingHistory => '私密预订记录';

  @override
  String get vendorPrivateBookingHistorySubtitle => '保持预订记录私密';

  @override
  String get vendorMarketingEmails => '营销邮件';

  @override
  String get vendorMarketingEmailsSubtitle => '接收促销邮件';

  @override
  String get vendorDataSharing => '数据共享';

  @override
  String get vendorDataSharingSubtitle => '共享匿名数据以改进服务';

  @override
  String get vendorAnalyticsTracking => '分析追踪';

  @override
  String get vendorAnalyticsTrackingSubtitle => '允许分析追踪以提升服务';

  @override
  String get vendorPrivacyPolicy => '隐私政策';

  @override
  String get vendorPrivacyPolicySubtitle => '查看隐私政策';

  @override
  String get vendorTermsOfService => '服务条款';

  @override
  String get vendorTermsOfServiceSubtitle => '查看条款与条件';

  @override
  String get vendorAutoAcceptBookings => '自动接受预订';

  @override
  String get vendorAutoAcceptBookingsSubtitle => '自动接受新预订';

  @override
  String get vendorRequireDeposit => '需要定金';

  @override
  String vendorDepositSubtitle(int percent) {
    return '预订需支付 $percent% 定金';
  }

  @override
  String get vendorDepositPercentage => '定金比例';

  @override
  String get vendorWeekendPricing => '周末定价';

  @override
  String get vendorWeekendPricingSubtitle => '对周末使用特殊价格';

  @override
  String get vendorHolidayPricing => '节假日定价';

  @override
  String get vendorHolidayPricingSubtitle => '对节假日使用特殊价格';

  @override
  String get vendorBulkDiscounts => '批量折扣';

  @override
  String get vendorBulkDiscountsSubtitle => '为大额预订提供折扣';

  @override
  String get vendorLoyaltyProgram => '会员计划';

  @override
  String get vendorLoyaltyProgramSubtitle => '奖励回头客';

  @override
  String get vendorVacationMode => '假期模式';

  @override
  String get vendorVacationModeSubtitle => '暂时关闭新预订';

  @override
  String get vendorVacationPeriod => '假期时间段';

  @override
  String get vendorVacationSetDates => '设置假期日期';

  @override
  String get vendorVacationMessage => '假期留言';

  @override
  String get vendorEnableShipping => '启用配送';

  @override
  String get vendorEnableShippingSubtitle => '向客户提供配送服务';

  @override
  String get vendorBaseShippingRate => '基础运费';

  @override
  String vendorBaseShippingRateAmount(String amount) {
    return 'RM $amount';
  }

  @override
  String get vendorFreeShipping => '包邮';

  @override
  String vendorFreeShippingSubtitle(String amount) {
    return '订单满 RM $amount 包邮';
  }

  @override
  String get vendorFreeShippingThreshold => '包邮门槛';

  @override
  String get vendorLocalDelivery => '本地配送';

  @override
  String get vendorLocalDeliverySubtitle => '提供本地区域配送';

  @override
  String get vendorInternationalShipping => '国际配送';

  @override
  String get vendorInternationalShippingSubtitle => '发往国际地址';

  @override
  String get vendorProcessingTime => '处理时间';

  @override
  String vendorDaysCount(int days) {
    return '$days 天';
  }

  @override
  String vendorProcessingDaysOneDay(int days) {
    return '$days 天';
  }

  @override
  String vendorProcessingDaysManyDays(int days) {
    return '$days 天';
  }

  @override
  String get vendorCashOnDelivery => '货到付款';

  @override
  String get vendorCashOnDeliverySubtitle => '收货时收取现金';

  @override
  String get vendorOnlinePayment => '在线支付';

  @override
  String get vendorOnlinePaymentSubtitle => '接受在线付款';

  @override
  String get vendorBankTransfer => '银行转账';

  @override
  String get vendorBankTransferSubtitle => '接受银行转账';

  @override
  String get vendorDigitalWallet => '电子钱包';

  @override
  String get vendorDigitalWalletSubtitle => '接受数字钱包付款';

  @override
  String get vendorProcessingFee => '手续费';

  @override
  String vendorProcessingFeePercent(String percent) {
    return '$percent%';
  }

  @override
  String get vendorAutoRefund => '自动退款';

  @override
  String get vendorAutoRefundSubtitle => '自动处理退款';

  @override
  String get vendorRefundWindow => '退款期限';

  @override
  String get vendorPaymentReminders => '付款提醒';

  @override
  String get vendorPaymentRemindersSubtitle => '向客户发送付款提醒';

  @override
  String get vendorCalendarSync => '日历同步';

  @override
  String get vendorCalendarSyncSubtitle => '与外部日历同步预订';

  @override
  String get vendorPaymentGateway => '支付网关';

  @override
  String get vendorPaymentGatewaySubtitle => '启用在线支付';

  @override
  String get vendorAutoSocialMediaPosts => '自动发帖';

  @override
  String get vendorAutoSocialMediaPostsSubtitle => '自动发布社交动态';

  @override
  String get vendorEmailMarketing => '邮件营销';

  @override
  String get vendorEmailMarketingSubtitle => '向客户发送营销邮件';

  @override
  String get vendorSmsNotifications => '短信通知';

  @override
  String get vendorSmsNotificationsSubtitle => '向客户发送短信通知';

  @override
  String get vendorWhatsappBusinessTile => 'WhatsApp Business';

  @override
  String get vendorWhatsappBusinessTileSubtitle => '启用 WhatsApp Business 集成';

  @override
  String get vendorChatSupport => '聊天客服';

  @override
  String get vendorChatSupportSubtitle => '启用客户聊天支持';

  @override
  String get vendorChatNotifications => '聊天通知';

  @override
  String get vendorChatNotificationsSubtitle => '接收新消息通知';

  @override
  String get vendorChatAvailability => '聊天在线时间';

  @override
  String get vendorAutoResponse => '自动回复';

  @override
  String get vendorAutoResponseSubtitle => '离线时自动回复';

  @override
  String get vendorAutoResponseMessage => '自动回复内容';

  @override
  String get vendorChatHistory => '聊天记录';

  @override
  String get vendorChatHistorySubtitle => '保存与客户的聊天记录';

  @override
  String get vendorAdvancedAnalytics => '高级分析';

  @override
  String get vendorAdvancedAnalyticsSubtitle => '启用详细业务分析';

  @override
  String get vendorCustomReports => '自定义报表';

  @override
  String get vendorCustomReportsSubtitle => '创建自定义业务报表';

  @override
  String get vendorApiAccess => 'API 访问';

  @override
  String get vendorApiAccessSubtitle => '为开发者启用 API';

  @override
  String get vendorWebhookNotifications => 'Webhook 通知';

  @override
  String get vendorWebhookNotificationsSubtitle => '通过 Webhook 接收实时通知';

  @override
  String get vendorMultiLocationSupport => '多地点支持';

  @override
  String get vendorMultiLocationSupportSubtitle => '管理多个经营地点';

  @override
  String get vendorStaffManagement => '员工管理';

  @override
  String get vendorStaffManagementSubtitle => '管理员工账户与权限';

  @override
  String get vendorFinancialReports => '财务报表';

  @override
  String get vendorFinancialReportsSubtitle => '配置财务报表偏好';

  @override
  String get vendorPerformanceMetrics => '绩效指标';

  @override
  String get vendorPerformanceMetricsSubtitle => '自定义绩效跟踪';

  @override
  String get vendorExportData => '导出数据';

  @override
  String get vendorExportDataSubtitle => '导出业务数据';

  @override
  String get vendorHelpCenter => '帮助中心';

  @override
  String get vendorHelpCenterSubtitle => '获取帮助与支持';

  @override
  String get vendorContactSupport => '联系支持';

  @override
  String get vendorContactSupportSubtitle => '联系我们的支持团队';

  @override
  String get vendorReportIssue => '报告问题';

  @override
  String get vendorReportIssueSubtitle => '报告缺陷或问题';

  @override
  String get vendorAppVersion => '应用版本';

  @override
  String get vendorAppVersionNumber => '1.0.0';

  @override
  String get vendorSignOut => '退出登录';

  @override
  String get vendorSignOutSubtitle => '退出当前账户';

  @override
  String get vendorDeleteAccount => '删除账户';

  @override
  String get vendorDeleteAccountSubtitle => '永久删除您的账户';

  @override
  String get vendorSelectLanguage => '选择语言';

  @override
  String get vendorLangEnglish => 'English';

  @override
  String get vendorLangMalay => 'Bahasa Malaysia';

  @override
  String get vendorLangChinese => '中文';

  @override
  String get vendorSelectCurrency => '选择货币';

  @override
  String get vendorCurrencyMyr => 'MYR（马来西亚林吉特）';

  @override
  String get vendorCurrencyUsd => 'USD（美元）';

  @override
  String get vendorCurrencySgd => 'SGD（新加坡元）';

  @override
  String get vendorDataRetentionPeriod => '数据保留期限';

  @override
  String vendorDataRetentionKeep(int days) {
    return '保留数据 $days 天';
  }

  @override
  String get vendorFinancialReportsBody => '财务报表偏好将在此配置';

  @override
  String get vendorPerformanceMetricsBody => '绩效跟踪偏好将在此配置';

  @override
  String get vendorExportDataBody => '数据导出选项将在此提供';

  @override
  String get vendorHelpCenterDialogTitle => '帮助中心';

  @override
  String get vendorHelpWelcome => '欢迎使用商家设置帮助中心！';

  @override
  String get vendorHelpBulletAccount => '• 账户设置：管理资料与商家信息';

  @override
  String get vendorHelpBulletNotifications => '• 通知：配置接收更新的方式';

  @override
  String get vendorHelpBulletBusiness => '• 业务运营：设置预订与定价偏好';

  @override
  String get vendorHelpBulletIntegrations => '• 集成：连接外部服务';

  @override
  String get vendorHelpBulletAdvanced => '• 高级功能：启用增值功能';

  @override
  String get vendorHelpBulletAnalytics => '• 商业分析：配置报表与指标';

  @override
  String get vendorHelpContactTeam => '如需更多帮助，请联系我们的支持团队。';

  @override
  String get vendorContactSupportSheetTitle => '联系支持';

  @override
  String get vendorContactSupportHours => '商家支持团队时间为周一至周五 9:00–18:00（马来西亚时间）。';

  @override
  String get vendorEmailSupport => '邮件支持';

  @override
  String get vendorCallUs => '致电我们';

  @override
  String get vendorWhatsappBusiness => 'WhatsApp Business';

  @override
  String get vendorSnackEmail => '邮件：vendors@eventease.com';

  @override
  String get vendorSnackPhone => '电话：+60 3-1234 5678';

  @override
  String get vendorSnackWhatsapp => 'WhatsApp：+60 11-1234 5678';

  @override
  String get vendorBusinessDetailsTitle => '商家详情';

  @override
  String get vendorBusinessDetailsIntro => '请在下方更新商家信息。';

  @override
  String get vendorBusinessName => '商家名称';

  @override
  String get vendorBusinessDescription => '商家描述';

  @override
  String get vendorBusinessPhone => '商家电话';

  @override
  String get vendorBusinessWebsite => '网站（可选）';

  @override
  String get vendorBusinessUpdated => '商家详情已更新';

  @override
  String get vendorReportIssueTitle => '报告问题';

  @override
  String get vendorReportCategory => '类别';

  @override
  String get vendorReportDescribeIssue => '描述问题';

  @override
  String get vendorReportIssueHint => '请详细描述问题…';

  @override
  String get vendorReportSubmit => '提交报告';

  @override
  String get vendorReportDescribeEmpty => '请描述问题。';

  @override
  String get vendorReportSignInRequired =>
      '请登录后提交报告，或发送邮件至 vendors@eventease.com。';

  @override
  String get vendorReportSuccess => '报告已提交，我们会尽快跟进。';

  @override
  String vendorReportCouldNotSubmit(String error) {
    return '无法在线提交：$error。请发送邮件至 vendors@eventease.com。';
  }

  @override
  String get vendorSignOutDialogTitle => '退出登录';

  @override
  String get vendorSignOutDialogBody => '确定要退出登录吗？';

  @override
  String get vendorDeleteAccountDialogTitle => '删除账户';

  @override
  String get vendorDeleteAccountDialogBody => '此操作无法撤消，您的所有数据将被永久删除。';

  @override
  String get vendorSettingsSaved => '设置已保存';

  @override
  String get vendorSettingsHelpTitle => '设置帮助';

  @override
  String get vendorSettingsHelpBulletAccount => '• 账户设置：管理资料与商家信息';

  @override
  String get vendorSettingsHelpBulletNotifications => '• 通知：配置接收更新的方式';

  @override
  String get vendorSettingsHelpBulletBusiness => '• 业务运营：设置预订与定价偏好';

  @override
  String get vendorSettingsHelpBulletIntegrations => '• 集成：连接外部服务';

  @override
  String get vendorSettingsHelpBulletAdvanced => '• 高级功能：启用增值功能';

  @override
  String get vendorSettingsHelpBulletAnalytics => '• 商业分析：配置报表与指标';

  @override
  String get vendorVacationPeriodTitle => '设置假期时间段';

  @override
  String get vendorVacationStartDate => '开始日期';

  @override
  String get vendorVacationEndDate => '结束日期';

  @override
  String get vendorVacationMessageTitle => '假期留言';

  @override
  String get vendorNotSet => '未设置';

  @override
  String get vendorVacationMessageHint => '请输入假期期间向客户展示的消息';

  @override
  String get vendorShippingRateTitle => '基础运费';

  @override
  String vendorShippingRateCurrent(String amount) {
    return '当前费率：RM $amount';
  }

  @override
  String get vendorProcessingTimeDialogTitle => '处理时间';

  @override
  String vendorProcessingTimeCurrent(String label) {
    return '当前处理时间：$label';
  }

  @override
  String get vendorProcessingFeeDialogTitle => '手续费';

  @override
  String vendorProcessingFeeCurrent(String percent) {
    return '当前费率：$percent%';
  }

  @override
  String get vendorRefundWindowTitle => '退款期限';

  @override
  String vendorRefundWindowCurrent(int days) {
    return '当前期限：$days 天';
  }

  @override
  String get vendorChatAvailabilityTitle => '聊天在线时间';

  @override
  String get vendorAutoResponseHint => '输入自动回复内容';

  @override
  String get vendorDefaultVendorName => '商家';

  @override
  String get vendorReportCatBug => '程序错误';

  @override
  String get vendorReportCatPayment => '支付问题';

  @override
  String get vendorReportCatBooking => '预订问题';

  @override
  String get vendorReportCatAccount => '账户问题';

  @override
  String get vendorReportCatOther => '其他';

  @override
  String get vendorChatHours247 => '24/7';

  @override
  String get vendorChatHoursBusiness => '营业时间';

  @override
  String get vendorChatHoursCustom => '自定义';

  @override
  String vendorSearchScrollTo(String name) {
    return '将滚动至：$name';
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

/// The translations for Chinese, as used in China (`zh_CN`).
class AppLocalizationsZhCn extends AppLocalizationsZh {
  AppLocalizationsZhCn() : super('zh_CN');

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonClose => '关闭';

  @override
  String get commonExport => '导出';

  @override
  String get commonGotIt => '知道了';

  @override
  String get vendorSettingsTitle => '设置';

  @override
  String get vendorTooltipSearch => '搜索设置';

  @override
  String get vendorTooltipHelp => '帮助';

  @override
  String get vendorTooltipSave => '保存设置';

  @override
  String get vendorSectionAccount => '账户设置';

  @override
  String get vendorSectionNotifications => '通知';

  @override
  String get vendorSectionAppPreferences => '应用偏好';

  @override
  String get vendorSectionDataPrivacy => '数据与隐私';

  @override
  String get vendorSectionBusinessOperations => '业务运营';

  @override
  String get vendorSectionShippingDelivery => '配送与交货';

  @override
  String get vendorSectionPaymentBilling => '付款与账单';

  @override
  String get vendorSectionIntegrations => '集成';

  @override
  String get vendorSectionAdvancedFeatures => '高级功能';

  @override
  String get vendorSectionBusinessAnalytics => '商业分析';

  @override
  String get vendorSectionSupportHelp => '支持与帮助';

  @override
  String get vendorSectionAccountDanger => '账户';

  @override
  String get vendorProfileInformation => '资料信息';

  @override
  String get vendorProfileInformationSubtitle => '管理您的商家资料';

  @override
  String get vendorBusinessDetails => '商家详情';

  @override
  String get vendorBusinessDetailsSubtitle => '更新商家信息';

  @override
  String get vendorDocumentsCertifications => '证件与认证';

  @override
  String get vendorDocumentsSubtitle => '管理法律文件';

  @override
  String get vendorEnableNotifications => '启用通知';

  @override
  String get vendorEnableNotificationsSubtitle => '接收预订和系统通知';

  @override
  String get vendorEmailNotifications => '邮件通知';

  @override
  String get vendorEmailNotificationsSubtitle => '通过电子邮件接收通知';

  @override
  String get vendorPushNotifications => '推送通知';

  @override
  String get vendorPushNotificationsSubtitle => '在手机上接收推送通知';

  @override
  String get vendorLanguage => '语言';

  @override
  String get vendorCurrency => '货币';

  @override
  String get vendorDarkMode => '深色模式';

  @override
  String get vendorDarkModeSubtitle => '切换到深色主题';

  @override
  String get vendorAutoBackup => '自动备份';

  @override
  String get vendorAutoBackupSubtitle => '自动备份您的数据';

  @override
  String get vendorDataRetention => '数据保留';

  @override
  String get vendorPublicProfile => '公开资料';

  @override
  String get vendorPublicProfileSubtitle => '向所有人展示商家资料';

  @override
  String get vendorShowContactInfo => '显示联系方式';

  @override
  String get vendorShowContactInfoSubtitle => '公开显示联系信息';

  @override
  String get vendorPrivateBookingHistory => '私密预订记录';

  @override
  String get vendorPrivateBookingHistorySubtitle => '保持预订记录私密';

  @override
  String get vendorMarketingEmails => '营销邮件';

  @override
  String get vendorMarketingEmailsSubtitle => '接收促销邮件';

  @override
  String get vendorDataSharing => '数据共享';

  @override
  String get vendorDataSharingSubtitle => '共享匿名数据以改进服务';

  @override
  String get vendorAnalyticsTracking => '分析追踪';

  @override
  String get vendorAnalyticsTrackingSubtitle => '允许分析追踪以提升服务';

  @override
  String get vendorPrivacyPolicy => '隐私政策';

  @override
  String get vendorPrivacyPolicySubtitle => '查看隐私政策';

  @override
  String get vendorTermsOfService => '服务条款';

  @override
  String get vendorTermsOfServiceSubtitle => '查看条款与条件';

  @override
  String get vendorAutoAcceptBookings => '自动接受预订';

  @override
  String get vendorAutoAcceptBookingsSubtitle => '自动接受新预订';

  @override
  String get vendorRequireDeposit => '需要定金';

  @override
  String vendorDepositSubtitle(int percent) {
    return '预订需支付 $percent% 定金';
  }

  @override
  String get vendorDepositPercentage => '定金比例';

  @override
  String get vendorWeekendPricing => '周末定价';

  @override
  String get vendorWeekendPricingSubtitle => '对周末使用特殊价格';

  @override
  String get vendorHolidayPricing => '节假日定价';

  @override
  String get vendorHolidayPricingSubtitle => '对节假日使用特殊价格';

  @override
  String get vendorBulkDiscounts => '批量折扣';

  @override
  String get vendorBulkDiscountsSubtitle => '为大额预订提供折扣';

  @override
  String get vendorLoyaltyProgram => '会员计划';

  @override
  String get vendorLoyaltyProgramSubtitle => '奖励回头客';

  @override
  String get vendorVacationMode => '假期模式';

  @override
  String get vendorVacationModeSubtitle => '暂时关闭新预订';

  @override
  String get vendorVacationPeriod => '假期时间段';

  @override
  String get vendorVacationSetDates => '设置假期日期';

  @override
  String get vendorVacationMessage => '假期留言';

  @override
  String get vendorEnableShipping => '启用配送';

  @override
  String get vendorEnableShippingSubtitle => '向客户提供配送服务';

  @override
  String get vendorBaseShippingRate => '基础运费';

  @override
  String vendorBaseShippingRateAmount(String amount) {
    return 'RM $amount';
  }

  @override
  String get vendorFreeShipping => '包邮';

  @override
  String vendorFreeShippingSubtitle(String amount) {
    return '订单满 RM $amount 包邮';
  }

  @override
  String get vendorFreeShippingThreshold => '包邮门槛';

  @override
  String get vendorLocalDelivery => '本地配送';

  @override
  String get vendorLocalDeliverySubtitle => '提供本地区域配送';

  @override
  String get vendorInternationalShipping => '国际配送';

  @override
  String get vendorInternationalShippingSubtitle => '发往国际地址';

  @override
  String get vendorProcessingTime => '处理时间';

  @override
  String vendorDaysCount(int days) {
    return '$days 天';
  }

  @override
  String vendorProcessingDaysOneDay(int days) {
    return '$days 天';
  }

  @override
  String vendorProcessingDaysManyDays(int days) {
    return '$days 天';
  }

  @override
  String get vendorCashOnDelivery => '货到付款';

  @override
  String get vendorCashOnDeliverySubtitle => '收货时收取现金';

  @override
  String get vendorOnlinePayment => '在线支付';

  @override
  String get vendorOnlinePaymentSubtitle => '接受在线付款';

  @override
  String get vendorBankTransfer => '银行转账';

  @override
  String get vendorBankTransferSubtitle => '接受银行转账';

  @override
  String get vendorDigitalWallet => '电子钱包';

  @override
  String get vendorDigitalWalletSubtitle => '接受数字钱包付款';

  @override
  String get vendorProcessingFee => '手续费';

  @override
  String vendorProcessingFeePercent(String percent) {
    return '$percent%';
  }

  @override
  String get vendorAutoRefund => '自动退款';

  @override
  String get vendorAutoRefundSubtitle => '自动处理退款';

  @override
  String get vendorRefundWindow => '退款期限';

  @override
  String get vendorPaymentReminders => '付款提醒';

  @override
  String get vendorPaymentRemindersSubtitle => '向客户发送付款提醒';

  @override
  String get vendorCalendarSync => '日历同步';

  @override
  String get vendorCalendarSyncSubtitle => '与外部日历同步预订';

  @override
  String get vendorPaymentGateway => '支付网关';

  @override
  String get vendorPaymentGatewaySubtitle => '启用在线支付';

  @override
  String get vendorAutoSocialMediaPosts => '自动发帖';

  @override
  String get vendorAutoSocialMediaPostsSubtitle => '自动发布社交动态';

  @override
  String get vendorEmailMarketing => '邮件营销';

  @override
  String get vendorEmailMarketingSubtitle => '向客户发送营销邮件';

  @override
  String get vendorSmsNotifications => '短信通知';

  @override
  String get vendorSmsNotificationsSubtitle => '向客户发送短信通知';

  @override
  String get vendorWhatsappBusinessTile => 'WhatsApp Business';

  @override
  String get vendorWhatsappBusinessTileSubtitle => '启用 WhatsApp Business 集成';

  @override
  String get vendorChatSupport => '聊天客服';

  @override
  String get vendorChatSupportSubtitle => '启用客户聊天支持';

  @override
  String get vendorChatNotifications => '聊天通知';

  @override
  String get vendorChatNotificationsSubtitle => '接收新消息通知';

  @override
  String get vendorChatAvailability => '聊天在线时间';

  @override
  String get vendorAutoResponse => '自动回复';

  @override
  String get vendorAutoResponseSubtitle => '离线时自动回复';

  @override
  String get vendorAutoResponseMessage => '自动回复内容';

  @override
  String get vendorChatHistory => '聊天记录';

  @override
  String get vendorChatHistorySubtitle => '保存与客户的聊天记录';

  @override
  String get vendorAdvancedAnalytics => '高级分析';

  @override
  String get vendorAdvancedAnalyticsSubtitle => '启用详细业务分析';

  @override
  String get vendorCustomReports => '自定义报表';

  @override
  String get vendorCustomReportsSubtitle => '创建自定义业务报表';

  @override
  String get vendorApiAccess => 'API 访问';

  @override
  String get vendorApiAccessSubtitle => '为开发者启用 API';

  @override
  String get vendorWebhookNotifications => 'Webhook 通知';

  @override
  String get vendorWebhookNotificationsSubtitle => '通过 Webhook 接收实时通知';

  @override
  String get vendorMultiLocationSupport => '多地点支持';

  @override
  String get vendorMultiLocationSupportSubtitle => '管理多个经营地点';

  @override
  String get vendorStaffManagement => '员工管理';

  @override
  String get vendorStaffManagementSubtitle => '管理员工账户与权限';

  @override
  String get vendorFinancialReports => '财务报表';

  @override
  String get vendorFinancialReportsSubtitle => '配置财务报表偏好';

  @override
  String get vendorPerformanceMetrics => '绩效指标';

  @override
  String get vendorPerformanceMetricsSubtitle => '自定义绩效跟踪';

  @override
  String get vendorExportData => '导出数据';

  @override
  String get vendorExportDataSubtitle => '导出业务数据';

  @override
  String get vendorHelpCenter => '帮助中心';

  @override
  String get vendorHelpCenterSubtitle => '获取帮助与支持';

  @override
  String get vendorContactSupport => '联系支持';

  @override
  String get vendorContactSupportSubtitle => '联系我们的支持团队';

  @override
  String get vendorReportIssue => '报告问题';

  @override
  String get vendorReportIssueSubtitle => '报告缺陷或问题';

  @override
  String get vendorAppVersion => '应用版本';

  @override
  String get vendorAppVersionNumber => '1.0.0';

  @override
  String get vendorSignOut => '退出登录';

  @override
  String get vendorSignOutSubtitle => '退出当前账户';

  @override
  String get vendorDeleteAccount => '删除账户';

  @override
  String get vendorDeleteAccountSubtitle => '永久删除您的账户';

  @override
  String get vendorSelectLanguage => '选择语言';

  @override
  String get vendorLangEnglish => 'English';

  @override
  String get vendorLangMalay => 'Bahasa Malaysia';

  @override
  String get vendorLangChinese => '中文';

  @override
  String get vendorSelectCurrency => '选择货币';

  @override
  String get vendorCurrencyMyr => 'MYR（马来西亚林吉特）';

  @override
  String get vendorCurrencyUsd => 'USD（美元）';

  @override
  String get vendorCurrencySgd => 'SGD（新加坡元）';

  @override
  String get vendorDataRetentionPeriod => '数据保留期限';

  @override
  String vendorDataRetentionKeep(int days) {
    return '保留数据 $days 天';
  }

  @override
  String get vendorFinancialReportsBody => '财务报表偏好将在此配置';

  @override
  String get vendorPerformanceMetricsBody => '绩效跟踪偏好将在此配置';

  @override
  String get vendorExportDataBody => '数据导出选项将在此提供';

  @override
  String get vendorHelpCenterDialogTitle => '帮助中心';

  @override
  String get vendorHelpWelcome => '欢迎使用商家设置帮助中心！';

  @override
  String get vendorHelpBulletAccount => '• 账户设置：管理资料与商家信息';

  @override
  String get vendorHelpBulletNotifications => '• 通知：配置接收更新的方式';

  @override
  String get vendorHelpBulletBusiness => '• 业务运营：设置预订与定价偏好';

  @override
  String get vendorHelpBulletIntegrations => '• 集成：连接外部服务';

  @override
  String get vendorHelpBulletAdvanced => '• 高级功能：启用增值功能';

  @override
  String get vendorHelpBulletAnalytics => '• 商业分析：配置报表与指标';

  @override
  String get vendorHelpContactTeam => '如需更多帮助，请联系我们的支持团队。';

  @override
  String get vendorContactSupportSheetTitle => '联系支持';

  @override
  String get vendorContactSupportHours => '商家支持团队时间为周一至周五 9:00–18:00（马来西亚时间）。';

  @override
  String get vendorEmailSupport => '邮件支持';

  @override
  String get vendorCallUs => '致电我们';

  @override
  String get vendorWhatsappBusiness => 'WhatsApp Business';

  @override
  String get vendorSnackEmail => '邮件：vendors@eventease.com';

  @override
  String get vendorSnackPhone => '电话：+60 3-1234 5678';

  @override
  String get vendorSnackWhatsapp => 'WhatsApp：+60 11-1234 5678';

  @override
  String get vendorBusinessDetailsTitle => '商家详情';

  @override
  String get vendorBusinessDetailsIntro => '请在下方更新商家信息。';

  @override
  String get vendorBusinessName => '商家名称';

  @override
  String get vendorBusinessDescription => '商家描述';

  @override
  String get vendorBusinessPhone => '商家电话';

  @override
  String get vendorBusinessWebsite => '网站（可选）';

  @override
  String get vendorBusinessUpdated => '商家详情已更新';

  @override
  String get vendorReportIssueTitle => '报告问题';

  @override
  String get vendorReportCategory => '类别';

  @override
  String get vendorReportDescribeIssue => '描述问题';

  @override
  String get vendorReportIssueHint => '请详细描述问题…';

  @override
  String get vendorReportSubmit => '提交报告';

  @override
  String get vendorReportDescribeEmpty => '请描述问题。';

  @override
  String get vendorReportSignInRequired =>
      '请登录后提交报告，或发送邮件至 vendors@eventease.com。';

  @override
  String get vendorReportSuccess => '报告已提交，我们会尽快跟进。';

  @override
  String vendorReportCouldNotSubmit(String error) {
    return '无法在线提交：$error。请发送邮件至 vendors@eventease.com。';
  }

  @override
  String get vendorSignOutDialogTitle => '退出登录';

  @override
  String get vendorSignOutDialogBody => '确定要退出登录吗？';

  @override
  String get vendorDeleteAccountDialogTitle => '删除账户';

  @override
  String get vendorDeleteAccountDialogBody => '此操作无法撤消，您的所有数据将被永久删除。';

  @override
  String get vendorSettingsSaved => '设置已保存';

  @override
  String get vendorSettingsHelpTitle => '设置帮助';

  @override
  String get vendorSettingsHelpBulletAccount => '• 账户设置：管理资料与商家信息';

  @override
  String get vendorSettingsHelpBulletNotifications => '• 通知：配置接收更新的方式';

  @override
  String get vendorSettingsHelpBulletBusiness => '• 业务运营：设置预订与定价偏好';

  @override
  String get vendorSettingsHelpBulletIntegrations => '• 集成：连接外部服务';

  @override
  String get vendorSettingsHelpBulletAdvanced => '• 高级功能：启用增值功能';

  @override
  String get vendorSettingsHelpBulletAnalytics => '• 商业分析：配置报表与指标';

  @override
  String get vendorVacationPeriodTitle => '设置假期时间段';

  @override
  String get vendorVacationStartDate => '开始日期';

  @override
  String get vendorVacationEndDate => '结束日期';

  @override
  String get vendorVacationMessageTitle => '假期留言';

  @override
  String get vendorNotSet => '未设置';

  @override
  String get vendorVacationMessageHint => '请输入假期期间向客户展示的消息';

  @override
  String get vendorShippingRateTitle => '基础运费';

  @override
  String vendorShippingRateCurrent(String amount) {
    return '当前费率：RM $amount';
  }

  @override
  String get vendorProcessingTimeDialogTitle => '处理时间';

  @override
  String vendorProcessingTimeCurrent(String label) {
    return '当前处理时间：$label';
  }

  @override
  String get vendorProcessingFeeDialogTitle => '手续费';

  @override
  String vendorProcessingFeeCurrent(String percent) {
    return '当前费率：$percent%';
  }

  @override
  String get vendorRefundWindowTitle => '退款期限';

  @override
  String vendorRefundWindowCurrent(int days) {
    return '当前期限：$days 天';
  }

  @override
  String get vendorChatAvailabilityTitle => '聊天在线时间';

  @override
  String get vendorAutoResponseHint => '输入自动回复内容';

  @override
  String get vendorDefaultVendorName => '商家';

  @override
  String get vendorReportCatBug => '程序错误';

  @override
  String get vendorReportCatPayment => '支付问题';

  @override
  String get vendorReportCatBooking => '预订问题';

  @override
  String get vendorReportCatAccount => '账户问题';

  @override
  String get vendorReportCatOther => '其他';

  @override
  String get vendorChatHours247 => '24/7';

  @override
  String get vendorChatHoursBusiness => '营业时间';

  @override
  String get vendorChatHoursCustom => '自定义';

  @override
  String vendorSearchScrollTo(String name) {
    return '将滚动至：$name';
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
