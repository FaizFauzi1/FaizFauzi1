/// Wedding Event Organizer (expo / bridal fair) — screen registry.
enum OrganizerModule {
  auth,
  companySetup,
  dashboard,
  expoManagement,
  booth,
  vendor,
  lead,
  visitor,
  ticket,
  staff,
  sponsor,
  finance,
  marketing,
  liveCommand,
  postExpo,
  analytics,
  communication,
  documents,
  automation,
  settings,
}

class OrganizerScreenDef {
  final String id;
  final String title;
  final String route;
  final OrganizerModule module;
  final List<String> features;
  final bool isHub;

  const OrganizerScreenDef({
    required this.id,
    required this.title,
    required this.route,
    required this.module,
    this.features = const [],
    this.isHub = false,
  });
}

class OrganizerScreenCatalog {
  OrganizerScreenCatalog._();

  static const String routePrefix = '/organizer';

  static const List<OrganizerScreenDef> all = [
    // 1 — Auth & staff access
    OrganizerScreenDef(
      id: 'login',
      title: 'Login',
      route: '$routePrefix/login',
      module: OrganizerModule.auth,
      features: ['Organizer company account'],
      isHub: true,
    ),
    OrganizerScreenDef(
      id: 'staff_login',
      title: 'Staff Login',
      route: '$routePrefix/staff-login',
      module: OrganizerModule.auth,
      features: ['Role-based access'],
    ),
    OrganizerScreenDef(
      id: 'otp',
      title: 'OTP Verification',
      route: '$routePrefix/otp',
      module: OrganizerModule.auth,
      features: ['Phone / email verification'],
    ),
    OrganizerScreenDef(
      id: 'forgot_password',
      title: 'Forgot Password',
      route: '$routePrefix/forgot-password',
      module: OrganizerModule.auth,
      features: ['Password reset'],
    ),

    // 2 — Company setup
    OrganizerScreenDef(
      id: 'company_profile',
      title: 'Company Profile',
      route: '$routePrefix/company-profile',
      module: OrganizerModule.companySetup,
      features: ['Legal name', 'Contact', 'Business registration'],
    ),
    OrganizerScreenDef(
      id: 'branding',
      title: 'Organizer Branding',
      route: '$routePrefix/branding',
      module: OrganizerModule.companySetup,
      features: ['Logo', 'Colors', 'Expo branding templates'],
    ),
    OrganizerScreenDef(
      id: 'event_types_setup',
      title: 'Event Types Setup',
      route: '$routePrefix/event-types-setup',
      module: OrganizerModule.companySetup,
      features: ['Bridal fair', 'Wedding expo', 'AP Event'],
    ),
    OrganizerScreenDef(
      id: 'staff_roles_setup',
      title: 'Staff & Role Setup',
      route: '$routePrefix/staff-roles-setup',
      module: OrganizerModule.companySetup,
      features: ['Roles', 'Permissions'],
    ),
    OrganizerScreenDef(
      id: 'service_regions',
      title: 'Service Regions',
      route: '$routePrefix/service-regions',
      module: OrganizerModule.companySetup,
      features: ['States', 'Cities', 'Coverage areas'],
    ),

    // 3 — Main dashboard
    OrganizerScreenDef(
      id: 'expo_command_dashboard',
      title: 'Expo Command Dashboard',
      route: '$routePrefix/expo-command-dashboard',
      module: OrganizerModule.dashboard,
      features: [
        'Active & upcoming expos',
        'Revenue overview',
        'Booth sales progress',
        'Vendor count',
        'Visitor registrations',
        'Tickets sold',
        'Pending payments',
        'Quick actions',
      ],
      isHub: true,
    ),

    // 4 — Expo management
    OrganizerScreenDef(
      id: 'expo_list',
      title: 'Expo List',
      route: '$routePrefix/expo-list',
      module: OrganizerModule.expoManagement,
      features: ['Upcoming', 'Ongoing', 'Past expos'],
      isHub: true,
    ),
    OrganizerScreenDef(
      id: 'create_expo',
      title: 'Create Expo',
      route: '$routePrefix/create-expo',
      module: OrganizerModule.expoManagement,
      features: [
        'Expo name',
        'Venue',
        'Date & time',
        'Booth capacity',
        'Ticket type',
        'Pricing strategy',
      ],
    ),
    OrganizerScreenDef(
      id: 'expo_detail',
      title: 'Expo Detail',
      route: '$routePrefix/expo-detail',
      module: OrganizerModule.expoManagement,
      features: [
        'Overview',
        'Booth layout',
        'Vendor list',
        'Visitor stats',
        'Revenue stats',
        'Staff allocation',
      ],
      isHub: true,
    ),

    // 5 — Booth management
    OrganizerScreenDef(
      id: 'booth_layout_designer',
      title: 'Booth Layout Designer',
      route: '$routePrefix/booth-layout-designer',
      module: OrganizerModule.booth,
      features: ['Drag & drop map', 'Zones A/B/VIP', 'Resize booths'],
    ),
    OrganizerScreenDef(
      id: 'booth_list',
      title: 'Booth List',
      route: '$routePrefix/booth-list',
      module: OrganizerModule.booth,
      features: ['Number', 'Size', 'Price', 'Status'],
    ),
    OrganizerScreenDef(
      id: 'booth_booking',
      title: 'Booth Booking',
      route: '$routePrefix/booth-booking',
      module: OrganizerModule.booth,
      features: ['Vendor selects booth', 'Organizer approves'],
    ),
    OrganizerScreenDef(
      id: 'booth_assignment',
      title: 'Booth Assignment',
      route: '$routePrefix/booth-assignment',
      module: OrganizerModule.booth,
      features: ['Assign vendor', 'Confirm layout'],
    ),
    OrganizerScreenDef(
      id: 'booth_pricing',
      title: 'Booth Pricing',
      route: '$routePrefix/booth-pricing',
      module: OrganizerModule.booth,
      features: ['Early bird', 'Normal', 'Premium zones'],
    ),

    // 6 — Vendor (exhibitors)
    OrganizerScreenDef(
      id: 'vendor_application',
      title: 'Vendor Application',
      route: '$routePrefix/vendor-application',
      module: OrganizerModule.vendor,
      features: ['Apply to join expo'],
    ),
    OrganizerScreenDef(
      id: 'vendor_approval',
      title: 'Vendor Approval',
      route: '$routePrefix/vendor-approval',
      module: OrganizerModule.vendor,
      features: ['Approve / reject'],
    ),
    OrganizerScreenDef(
      id: 'vendor_directory',
      title: 'Vendor Directory',
      route: '$routePrefix/vendor-directory',
      module: OrganizerModule.vendor,
      features: ['All registered exhibitors'],
    ),
    OrganizerScreenDef(
      id: 'vendor_detail',
      title: 'Vendor Detail',
      route: '$routePrefix/vendor-detail',
      module: OrganizerModule.vendor,
      features: ['Company info', 'Packages', 'Booth', 'Payment'],
    ),
    OrganizerScreenDef(
      id: 'vendor_contract',
      title: 'Vendor Contract',
      route: '$routePrefix/vendor-contract',
      module: OrganizerModule.vendor,
      features: ['Participation agreement'],
    ),
    OrganizerScreenDef(
      id: 'vendor_payment',
      title: 'Vendor Payment',
      route: '$routePrefix/vendor-payment',
      module: OrganizerModule.vendor,
      features: ['Booth fees', 'Outstanding payments'],
    ),

    // 7 — Lead management (core value)
    OrganizerScreenDef(
      id: 'lead_collection',
      title: 'Lead Collection',
      route: '$routePrefix/lead-collection',
      module: OrganizerModule.lead,
      features: ['Visitor data from expo'],
    ),
    OrganizerScreenDef(
      id: 'lead_distribution',
      title: 'Lead Distribution',
      route: '$routePrefix/lead-distribution',
      module: OrganizerModule.lead,
      features: ['Assign leads to vendors'],
    ),
    OrganizerScreenDef(
      id: 'lead_detail',
      title: 'Lead Detail',
      route: '$routePrefix/lead-detail',
      module: OrganizerModule.lead,
      features: ['Visitor info', 'Interest', 'Assigned vendor'],
    ),
    OrganizerScreenDef(
      id: 'lead_tracking',
      title: 'Lead Tracking',
      route: '$routePrefix/lead-tracking',
      module: OrganizerModule.lead,
      features: ['Contacted', 'Followed up', 'Converted', 'Lost'],
    ),
    OrganizerScreenDef(
      id: 'lead_quality_scoring',
      title: 'Lead Quality Scoring',
      route: '$routePrefix/lead-quality-scoring',
      module: OrganizerModule.lead,
      features: ['Hot', 'Warm', 'Cold'],
    ),

    // 8 — Visitor system
    OrganizerScreenDef(
      id: 'visitor_registration',
      title: 'Visitor Registration',
      route: '$routePrefix/visitor-registration',
      module: OrganizerModule.visitor,
      features: ['Name', 'Phone', 'Wedding date', 'Budget range'],
    ),
    OrganizerScreenDef(
      id: 'visitor_check_in',
      title: 'Visitor Check-In',
      route: '$routePrefix/visitor-check-in',
      module: OrganizerModule.visitor,
      features: ['QR scan entry'],
    ),
    OrganizerScreenDef(
      id: 'visitor_profile',
      title: 'Visitor Profile',
      route: '$routePrefix/visitor-profile',
      module: OrganizerModule.visitor,
      features: ['Saved vendors', 'Interests', 'Visited booths'],
    ),
    OrganizerScreenDef(
      id: 'expo_map',
      title: 'Expo Map',
      route: '$routePrefix/expo-map',
      module: OrganizerModule.visitor,
      features: ['Booth navigation', 'Search vendors'],
    ),

    // 9 — Ticket & entry
    OrganizerScreenDef(
      id: 'ticket_types',
      title: 'Ticket Types',
      route: '$routePrefix/ticket-types',
      module: OrganizerModule.ticket,
      features: ['Free ticket', 'VIP ticket'],
    ),
    OrganizerScreenDef(
      id: 'ticket_sales',
      title: 'Ticket Sales',
      route: '$routePrefix/ticket-sales',
      module: OrganizerModule.ticket,
      features: ['Online sales tracking'],
    ),
    OrganizerScreenDef(
      id: 'qr_ticket_scanner',
      title: 'QR Ticket Scanner',
      route: '$routePrefix/qr-ticket-scanner',
      module: OrganizerModule.ticket,
      features: ['Entry validation'],
    ),
    OrganizerScreenDef(
      id: 'attendance_dashboard',
      title: 'Attendance Dashboard',
      route: '$routePrefix/attendance-dashboard',
      module: OrganizerModule.ticket,
      features: ['Real-time visitor count'],
    ),

    // 10 — Staff operations
    OrganizerScreenDef(
      id: 'staff_assignment',
      title: 'Staff Assignment',
      route: '$routePrefix/staff-assignment',
      module: OrganizerModule.staff,
      features: ['Assign staff to zones'],
    ),
    OrganizerScreenDef(
      id: 'staff_roles',
      title: 'Staff Roles',
      route: '$routePrefix/staff-roles',
      module: OrganizerModule.staff,
      features: ['Registration', 'Booth support', 'Crowd control'],
    ),
    OrganizerScreenDef(
      id: 'live_staff_tracking',
      title: 'Live Staff Tracking',
      route: '$routePrefix/live-staff-tracking',
      module: OrganizerModule.staff,
      features: ['Activity monitoring'],
    ),

    // 11 — Sponsors
    OrganizerScreenDef(
      id: 'sponsor_list',
      title: 'Sponsor List',
      route: '$routePrefix/sponsor-list',
      module: OrganizerModule.sponsor,
      features: ['All sponsors'],
    ),
    OrganizerScreenDef(
      id: 'sponsor_packages',
      title: 'Sponsor Packages',
      route: '$routePrefix/sponsor-packages',
      module: OrganizerModule.sponsor,
      features: ['Platinum', 'Gold', 'Silver'],
    ),
    OrganizerScreenDef(
      id: 'sponsor_agreement',
      title: 'Sponsor Agreement',
      route: '$routePrefix/sponsor-agreement',
      module: OrganizerModule.sponsor,
      features: ['Contract', 'Deliverables'],
    ),
    OrganizerScreenDef(
      id: 'sponsor_exposure_tracker',
      title: 'Sponsor Exposure Tracker',
      route: '$routePrefix/sponsor-exposure-tracker',
      module: OrganizerModule.sponsor,
      features: ['Logo placement tracking'],
    ),

    // 12 — Finance
    OrganizerScreenDef(
      id: 'revenue_dashboard',
      title: 'Revenue Dashboard',
      route: '$routePrefix/revenue-dashboard',
      module: OrganizerModule.finance,
      features: ['Booth sales', 'Tickets', 'Sponsorship'],
    ),
    OrganizerScreenDef(
      id: 'expense_tracker',
      title: 'Expense Tracker',
      route: '$routePrefix/expense-tracker',
      module: OrganizerModule.finance,
      features: ['Venue', 'Marketing', 'Staff costs'],
    ),
    OrganizerScreenDef(
      id: 'profit_per_expo',
      title: 'Profit Per Expo',
      route: '$routePrefix/profit-per-expo',
      module: OrganizerModule.finance,
      features: ['Total profit calculation'],
    ),
    OrganizerScreenDef(
      id: 'invoice_management',
      title: 'Invoice Management',
      route: '$routePrefix/invoice-management',
      module: OrganizerModule.finance,
      features: ['Vendor invoices', 'Sponsor invoices'],
    ),
    OrganizerScreenDef(
      id: 'payment_tracking',
      title: 'Payment Tracking',
      route: '$routePrefix/payment-tracking',
      module: OrganizerModule.finance,
      features: ['Paid / unpaid vendors'],
    ),

    // 13 — Marketing & sales
    OrganizerScreenDef(
      id: 'campaign_dashboard',
      title: 'Campaign Dashboard',
      route: '$routePrefix/campaign-dashboard',
      module: OrganizerModule.marketing,
      features: ['Ads performance'],
    ),
    OrganizerScreenDef(
      id: 'lead_funnel',
      title: 'Lead Funnel',
      route: '$routePrefix/lead-funnel',
      module: OrganizerModule.marketing,
      features: ['Registration → check-in → conversion'],
    ),
    OrganizerScreenDef(
      id: 'promo_codes',
      title: 'Promo Codes',
      route: '$routePrefix/promo-codes',
      module: OrganizerModule.marketing,
      features: ['Ticket & booth discounts'],
    ),
    OrganizerScreenDef(
      id: 'influencer_campaign',
      title: 'Influencer Campaign',
      route: '$routePrefix/influencer-campaign',
      module: OrganizerModule.marketing,
      features: ['Marketing tracking'],
    ),

    // 14 — Live expo command center
    OrganizerScreenDef(
      id: 'live_expo_dashboard',
      title: 'Live Expo Dashboard',
      route: '$routePrefix/live-expo-dashboard',
      module: OrganizerModule.liveCommand,
      features: ['Visitor count', 'Booth status', 'Vendor activity'],
      isHub: true,
    ),
    OrganizerScreenDef(
      id: 'expo_timeline',
      title: 'Expo Timeline',
      route: '$routePrefix/expo-timeline',
      module: OrganizerModule.liveCommand,
      features: ['Live event schedule'],
    ),
    OrganizerScreenDef(
      id: 'incident_management',
      title: 'Incident Management',
      route: '$routePrefix/incident-management',
      module: OrganizerModule.liveCommand,
      features: ['Booth', 'Technical', 'Crowd control'],
    ),
    OrganizerScreenDef(
      id: 'emergency_response',
      title: 'Emergency Response',
      route: '$routePrefix/emergency-response',
      module: OrganizerModule.liveCommand,
      features: ['Alerts', 'Staff notifications'],
    ),

    // 15 — Post-expo
    OrganizerScreenDef(
      id: 'expo_report',
      title: 'Expo Report',
      route: '$routePrefix/expo-report',
      module: OrganizerModule.postExpo,
      features: ['Visitors', 'Leads', 'Revenue'],
    ),
    OrganizerScreenDef(
      id: 'vendor_roi_report',
      title: 'Vendor ROI Report',
      route: '$routePrefix/vendor-roi-report',
      module: OrganizerModule.postExpo,
      features: ['Leads per vendor', 'Conversion rates'],
    ),
    OrganizerScreenDef(
      id: 'vendor_feedback',
      title: 'Vendor Feedback',
      route: '$routePrefix/vendor-feedback',
      module: OrganizerModule.postExpo,
      features: ['Vendor satisfaction'],
    ),
    OrganizerScreenDef(
      id: 'lead_conversion_report',
      title: 'Lead Conversion Report',
      route: '$routePrefix/lead-conversion-report',
      module: OrganizerModule.postExpo,
      features: ['Post-expo wedding bookings'],
    ),
    OrganizerScreenDef(
      id: 'expo_performance_comparison',
      title: 'Expo Performance Comparison',
      route: '$routePrefix/expo-performance-comparison',
      module: OrganizerModule.postExpo,
      features: ['Compare multiple expos'],
    ),

    // 16 — Analytics
    OrganizerScreenDef(
      id: 'expo_analytics_dashboard',
      title: 'Expo Analytics Dashboard',
      route: '$routePrefix/expo-analytics-dashboard',
      module: OrganizerModule.analytics,
      features: ['Revenue trends', 'Visitor trends'],
    ),
    OrganizerScreenDef(
      id: 'vendor_performance_analytics',
      title: 'Vendor Performance Analytics',
      route: '$routePrefix/vendor-performance-analytics',
      module: OrganizerModule.analytics,
      features: ['Best vendors', 'Booth ROI'],
    ),
    OrganizerScreenDef(
      id: 'booth_performance_analytics',
      title: 'Booth Performance Analytics',
      route: '$routePrefix/booth-performance-analytics',
      module: OrganizerModule.analytics,
      features: ['Most profitable zones'],
    ),
    OrganizerScreenDef(
      id: 'marketing_analytics',
      title: 'Marketing Analytics',
      route: '$routePrefix/marketing-analytics',
      module: OrganizerModule.analytics,
      features: ['Ad ROI'],
    ),

    // 17 — Communication
    OrganizerScreenDef(
      id: 'chat_inbox',
      title: 'Chat Inbox',
      route: '$routePrefix/chat-inbox',
      module: OrganizerModule.communication,
      features: ['Vendors', 'Staff', 'Sponsors'],
    ),
    OrganizerScreenDef(
      id: 'vendor_communication',
      title: 'Vendor Communication',
      route: '$routePrefix/vendor-communication',
      module: OrganizerModule.communication,
      features: ['Expo updates'],
    ),
    OrganizerScreenDef(
      id: 'broadcast_messaging',
      title: 'Broadcast Messaging',
      route: '$routePrefix/broadcast-messaging',
      module: OrganizerModule.communication,
      features: ['Updates to all vendors'],
    ),

    // 18 — Documents
    OrganizerScreenDef(
      id: 'document_vault',
      title: 'Document Vault',
      route: '$routePrefix/document-vault',
      module: OrganizerModule.documents,
      features: ['Contracts', 'Agreements', 'Invoices'],
    ),
    OrganizerScreenDef(
      id: 'vendor_contract_generator',
      title: 'Vendor Contract Generator',
      route: '$routePrefix/vendor-contract-generator',
      module: OrganizerModule.documents,
      features: ['Generate participation contracts'],
    ),
    OrganizerScreenDef(
      id: 'sponsor_proposal',
      title: 'Sponsor Proposal',
      route: '$routePrefix/sponsor-proposal',
      module: OrganizerModule.documents,
      features: ['Sponsor proposal builder'],
    ),

    // 19 — Automation
    OrganizerScreenDef(
      id: 'booth_allocation_auto',
      title: 'Booth Allocation Auto',
      route: '$routePrefix/booth-allocation-auto',
      module: OrganizerModule.automation,
      features: ['Rule-based booth assignment'],
    ),
    OrganizerScreenDef(
      id: 'lead_auto_distribution',
      title: 'Lead Auto Distribution',
      route: '$routePrefix/lead-auto-distribution',
      module: OrganizerModule.automation,
      features: ['Auto assign leads'],
    ),
    OrganizerScreenDef(
      id: 'reminder_automation',
      title: 'Reminder Automation',
      route: '$routePrefix/reminder-automation',
      module: OrganizerModule.automation,
      features: ['Payment reminders', 'Vendor follow-ups'],
    ),

    // 20 — Settings
    OrganizerScreenDef(
      id: 'expo_settings',
      title: 'Expo Settings',
      route: '$routePrefix/expo-settings',
      module: OrganizerModule.settings,
      features: ['Pricing rules', 'Booth rules'],
    ),
    OrganizerScreenDef(
      id: 'company_settings',
      title: 'Company Settings',
      route: '$routePrefix/company-settings',
      module: OrganizerModule.settings,
      features: ['Company preferences'],
    ),
    OrganizerScreenDef(
      id: 'subscription_plan',
      title: 'Subscription Plan',
      route: '$routePrefix/subscription-plan',
      module: OrganizerModule.settings,
      features: ['Organizer subscription tiers'],
    ),
    OrganizerScreenDef(
      id: 'notification_settings',
      title: 'Notification Settings',
      route: '$routePrefix/notification-settings',
      module: OrganizerModule.settings,
      features: ['Push & email preferences'],
    ),
  ];

  static OrganizerScreenDef? byId(String id) {
    for (final def in all) {
      if (def.id == id) return def;
    }
    return null;
  }

  static OrganizerScreenDef? byRoute(String route) {
    for (final def in all) {
      if (def.route == route) return def;
    }
    return null;
  }

  static List<OrganizerScreenDef> byModule(OrganizerModule module) =>
      all.where((d) => d.module == module).toList();

  static String moduleLabel(OrganizerModule module) {
    switch (module) {
      case OrganizerModule.auth:
        return 'Auth & Staff Access';
      case OrganizerModule.companySetup:
        return 'Organizer Company Setup';
      case OrganizerModule.dashboard:
        return 'Main Operation Dashboard';
      case OrganizerModule.expoManagement:
        return 'Expo / Event Management';
      case OrganizerModule.booth:
        return 'Booth Management';
      case OrganizerModule.vendor:
        return 'Vendor Management (Exhibitors)';
      case OrganizerModule.lead:
        return 'Lead Management';
      case OrganizerModule.visitor:
        return 'Visitor System';
      case OrganizerModule.ticket:
        return 'Ticket & Entry';
      case OrganizerModule.staff:
        return 'Staff Operations';
      case OrganizerModule.sponsor:
        return 'Sponsor System';
      case OrganizerModule.finance:
        return 'Finance';
      case OrganizerModule.marketing:
        return 'Marketing & Sales';
      case OrganizerModule.liveCommand:
        return 'Expo Command Center (Live)';
      case OrganizerModule.postExpo:
        return 'Post-Expo';
      case OrganizerModule.analytics:
        return 'Analytics';
      case OrganizerModule.communication:
        return 'Communication';
      case OrganizerModule.documents:
        return 'Document Management';
      case OrganizerModule.automation:
        return 'Automation';
      case OrganizerModule.settings:
        return 'Settings';
    }
  }
}
