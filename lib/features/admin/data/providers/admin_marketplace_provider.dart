import 'package:flutter/material.dart';
import 'package:eventease/features/admin/data/services/admin_marketplace_service.dart';
import 'package:eventease/features/vendor/models/vendor_service_workflow_models.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';

class AdminMarketplaceProvider with ChangeNotifier {
  // Current active admin role
  AdminRole _currentRole = AdminRole.superAdmin;
  AdminRole get currentRole => _currentRole;

  void setAdminRole(AdminRole role) {
    _currentRole = role;
    notifyListeners();
  }

  // Active saved view
  String _activeSavedView = 'Default';
  String get activeSavedView => _activeSavedView;

  final List<String> savedViews = [
    'Default',
    'My Pending Approvals',
    'Expiring Documents',
    'Unresolved Package Issues',
    'Failed Payments',
    'High Priority Cases',
    'Services Missing Photos',
    'Vendors Awaiting Documents',
    'Booking Exceptions',
  ];

  void setSavedView(String view) {
    _activeSavedView = view;
    notifyListeners();
  }

  // Safe read-only impersonation mode
  String? _readOnlyPreviewMode; // null, 'customer', 'vendor'
  String? get readOnlyPreviewMode => _readOnlyPreviewMode;

  void setReadOnlyPreviewMode(String? mode) {
    _readOnlyPreviewMode = mode;
    notifyListeners();
  }

  // Support cases
  final List<AdminSupportCase> _supportCases = [];
  List<AdminSupportCase> get supportCases => List.unmodifiable(_supportCases);

  // Booking exceptions
  final List<BookingExceptionItem> _bookingExceptions = [];
  List<BookingExceptionItem> get bookingExceptions => List.unmodifiable(_bookingExceptions);

  // Audit logs
  final List<AdminAuditLogEntry> _auditLogs = [];
  List<AdminAuditLogEntry> get auditLogs => List.unmodifiable(_auditLogs);

  // Dynamic Category Configurations
  final List<CategoryDynamicConfig> _categoryConfigs = [];
  List<CategoryDynamicConfig> get categoryConfigs => List.unmodifiable(_categoryConfigs);

  // Potential Duplicates
  final List<DuplicateMatch> _duplicateMatches = [];
  List<DuplicateMatch> get duplicateMatches => List.unmodifiable(_duplicateMatches);

  AdminMarketplaceProvider() {
    _initSampleData();
  }

  void _initSampleData() {
    // Initialize sample Support Cases
    _supportCases.addAll([
      AdminSupportCase(
        id: 'CASE-4091',
        customerName: 'Sarah Lim & Adam Tan',
        customerEmail: 'sarah.lim@wedding.my',
        vendorId: 'v-102',
        vendorName: 'Royal Spice Banquet & Catering',
        bookingId: 'BK-10492',
        packageId: 'pkg-royal-wedding',
        eventName: 'Sarah & Adam Grand Wedding',
        subject: 'Catering menu change request 2 weeks before event',
        category: 'Booking Problem',
        priority: 'High',
        status: 'In Progress',
        assignedAdmin: 'Sarah Wong (Marketplace Ops)',
        createdAt: DateTime.now().subtract(const Duration(hours: 14)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        internalNotes: 'Contacted chef Chef Ahmad. He confirmed menu change is possible with slight ingredient surcharge of RM350.',
        timeline: [
          AdminCaseTimelineItem(
            actor: 'Sarah Lim',
            role: 'Customer',
            action: 'Submitted Request',
            details: 'Requested dietary adjustment from Western set to 8-course Halal banquet for 250 pax.',
            timestamp: DateTime.now().subtract(const Duration(hours: 14)),
          ),
          AdminCaseTimelineItem(
            actor: 'System',
            role: 'System',
            action: 'Automated Routing',
            details: 'Assigned priority High based on event date: 20 Dec 2026.',
            timestamp: DateTime.now().subtract(const Duration(hours: 13, minutes: 50)),
          ),
          AdminCaseTimelineItem(
            actor: 'Sarah Wong',
            role: 'Admin',
            action: 'Contacted Vendor',
            details: 'Reached out to Royal Spice Banquet regarding chef availability and quote.',
            timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          ),
          AdminCaseTimelineItem(
            actor: 'Royal Spice Banquet',
            role: 'Vendor',
            action: 'Vendor Responded',
            details: 'Confirmed capability, requested customer approval for RM350 surcharge.',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ],
      ),
      AdminSupportCase(
        id: 'CASE-4092',
        customerName: 'Marcus & Jessica',
        customerEmail: 'marcus.jessica@gmail.com',
        vendorId: 'v-105',
        vendorName: 'Glam Studio & Hair Design',
        bookingId: 'BK-10293',
        packageId: 'pkg-royal-wedding',
        eventName: 'Marcus & Jessica Solemnization',
        subject: 'Makeup trial timing conflict with church rehearsal',
        category: 'Appointment Issue',
        priority: 'Medium',
        status: 'Waiting for Vendor',
        assignedAdmin: 'John Doe',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 5)),
        internalNotes: 'Proposed alternate slot on 14 Dec at 10:00 AM instead of 12 Dec.',
        timeline: [
          AdminCaseTimelineItem(
            actor: 'Marcus',
            role: 'Customer',
            action: 'Requested Reschedule',
            details: 'Church solemnization practice scheduled on 12 Dec 2 PM; requested shift.',
            timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
          ),
          AdminCaseTimelineItem(
            actor: 'John Doe',
            role: 'Admin',
            action: 'Proposed Alternative',
            details: 'Sent 14 Dec 10:00 AM slot to Glam Studio for confirmation.',
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          ),
        ],
      ),
      AdminSupportCase(
        id: 'CASE-4093',
        customerName: 'Dato Daniel & Datin Linda',
        customerEmail: 'daniel@kldining.com',
        vendorId: 'v-101',
        vendorName: 'Grand Hall & Ballroom',
        bookingId: 'BK-10150',
        eventName: 'Annual Corporate Gala 2026',
        subject: 'Deposit payment gateway timeout - card charged twice',
        category: 'Payment Problem',
        priority: 'Urgent',
        status: 'Escalated',
        assignedAdmin: 'Finance Lead (David Chen)',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        internalNotes: 'Stripe webhook caught duplicate authorization token. Preparing RM 7,500 immediate reversal.',
        timeline: [
          AdminCaseTimelineItem(
            actor: 'Dato Daniel',
            role: 'Customer',
            action: 'Payment Issue Reported',
            details: 'Duplicate charge notice received on Amex card ending in 4019.',
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
          ),
          AdminCaseTimelineItem(
            actor: 'David Chen',
            role: 'Admin',
            action: 'Payment Gateway Verified',
            details: 'Checked gateway batch TX-84921 and TX-84922. Duplicate confirmed.',
            timestamp: DateTime.now().subtract(const Duration(hours: 24)),
          ),
          AdminCaseTimelineItem(
            actor: 'David Chen',
            role: 'Admin',
            action: 'Refund Initiated',
            details: 'Refund order submitted for RM 7,500. Awaiting Stripe settlement confirmation.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
      ),
      AdminSupportCase(
        id: 'CASE-4094',
        customerName: 'Afiq & Nurul',
        customerEmail: 'afiq.nurul@yahoo.com',
        vendorId: 'v-103',
        vendorName: 'Lumiere Cinema & Photography',
        bookingId: 'BK-10381',
        subject: 'Vendor cancellation request due to equipment breakdown',
        category: 'Vendor Issue',
        priority: 'Urgent',
        status: 'In Progress',
        assignedAdmin: 'Sarah Wong',
        createdAt: DateTime.now().subtract(const Duration(hours: 8)),
        updatedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        internalNotes: 'Searching emergency replacement photographer via Emergency Partner Matcher tool.',
        timeline: [
          AdminCaseTimelineItem(
            actor: 'Lumiere Cinema',
            role: 'Vendor',
            action: 'Cancellation Lodged',
            details: 'Lead drone camera damaged during outdoor event; cannot fulfill 18 Oct booking.',
            timestamp: DateTime.now().subtract(const Duration(hours: 8)),
          ),
          AdminCaseTimelineItem(
            actor: 'Sarah Wong',
            role: 'Admin',
            action: 'Contacted Backup Photographers',
            details: 'Sent broadcast to 3 approved photography vendors with matching date availability.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
          ),
        ],
      ),
    ]);

    // Initialize Booking Exceptions
    _bookingExceptions.addAll([
      BookingExceptionItem(
        id: 'EXC-101',
        bookingId: 'BK-10521',
        customerName: 'Chloe Wong',
        vendorName: 'Apex Audio & Entertainment',
        eventName: 'Chloe 21st Birthday Festival',
        eventDate: DateTime.now().add(const Duration(days: 5)),
        issueType: 'Payment Failed',
        description: 'Remaining balance installment payment declined by issuing bank (Insufficient funds).',
        severity: 'Critical',
        amount: 3200.0,
      ),
      BookingExceptionItem(
        id: 'EXC-102',
        bookingId: 'BK-10381',
        customerName: 'Afiq & Nurul',
        vendorName: 'Lumiere Cinema & Photography',
        eventName: 'Afiq & Nurul Reception',
        eventDate: DateTime.now().add(const Duration(days: 12)),
        issueType: 'Vendor Cancelled',
        description: 'Vendor equipment failure reported. Customer awaiting backup photographer confirmation.',
        severity: 'Critical',
        amount: 4500.0,
      ),
      BookingExceptionItem(
        id: 'EXC-103',
        bookingId: 'BK-10492',
        customerName: 'Sarah & Adam',
        vendorName: 'Royal Spice Banquet',
        eventName: 'Sarah & Adam Wedding',
        eventDate: DateTime.now().add(const Duration(days: 45)),
        issueType: 'Date Conflict',
        description: 'Catering vendor has high volume on same date (2 bookings confirmed). Setup buffer warning.',
        severity: 'Warning',
        amount: 14500.0,
      ),
      BookingExceptionItem(
        id: 'EXC-104',
        bookingId: 'BK-10604',
        customerName: 'Zul & Fatin',
        vendorName: 'Sweet Petals Cake Boutique',
        eventName: 'Fatin Engagement Night',
        eventDate: DateTime.now().add(const Duration(days: 18)),
        issueType: 'Package Component Missing',
        description: 'Collaborative package booked but customer choice for wedding cake was not selected in time.',
        severity: 'Warning',
        amount: 850.0,
      ),
      BookingExceptionItem(
        id: 'EXC-105',
        bookingId: 'BK-10150',
        customerName: 'Dato Daniel',
        vendorName: 'Grand Hall & Ballroom',
        eventName: 'Annual Corporate Gala 2026',
        eventDate: DateTime.now().add(const Duration(days: 60)),
        issueType: 'Refund Pending',
        description: 'Duplicate charge reversal authorization pending finance disbursement.',
        severity: 'Critical',
        amount: 7500.0,
      ),
    ]);

    // Initialize Audit Log
    _auditLogs.addAll([
      AdminAuditLogEntry(
        id: 'LOG-901',
        adminName: 'Sarah Wong',
        role: 'Marketplace Admin',
        action: 'Approved Service',
        entityType: 'Service',
        entityId: 'srv-bridal-makeup-01',
        entityName: 'Bridal Makeup & Styling Mastery',
        details: 'Verified portfolio, pricing RM 800, 3 trial appointment slots, travel radius 40km.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
      ),
      AdminAuditLogEntry(
        id: 'LOG-902',
        adminName: 'John Doe',
        role: 'Super Admin',
        action: 'Updated Package Price',
        entityType: 'Package',
        entityId: 'pkg-royal-wedding',
        entityName: 'Premium Royal Wedding Package',
        details: 'Changed base price RM 25,000 → RM 26,300 after catering tier revision.',
        timestamp: DateTime.now().subtract(const Duration(hours: 2, minutes: 15)),
      ),
      AdminAuditLogEntry(
        id: 'LOG-903',
        adminName: 'David Chen',
        role: 'Finance Admin',
        action: 'Approved Refund',
        entityType: 'Booking',
        entityId: 'BK-10150',
        entityName: 'Corporate Gala Hall Booking',
        details: 'Authorized immediate Stripe card refund RM 7,500 for duplicate gateway transaction.',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      AdminAuditLogEntry(
        id: 'LOG-904',
        adminName: 'Sarah Wong',
        role: 'Marketplace Admin',
        action: 'Published Category Version',
        entityType: 'Category',
        entityId: 'cat-makeup',
        entityName: 'Makeup & Beauty',
        details: 'Upgraded to Version 2.0. Added mandatory trial appointment rules and early morning surcharge fields.',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
      AdminAuditLogEntry(
        id: 'LOG-905',
        adminName: 'Admin System',
        role: 'System',
        action: 'Document Expiry Warning',
        entityType: 'Vendor',
        entityId: 'v-104',
        entityName: 'Elite Audio & DJ Crew',
        details: 'Public Liability Insurance policy expires in 14 days (10 Oct 2026). Notification dispatched.',
        timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 6)),
      ),
    ]);

    // Initialize Dynamic Category Configs
    _categoryConfigs.addAll([
      CategoryDynamicConfig(
        id: 'cat-makeup',
        categoryName: 'Makeup & Beauty',
        icon: Icons.face_retouching_natural,
        color: const Color(0xFFD946EF),
        activeVersion: '2.0',
        versions: [
          CategoryConfigVersion(
            version: '2.0',
            publishedAt: DateTime.now().subtract(const Duration(days: 1)),
            publishedBy: 'Sarah Wong',
            changelog: 'Added mandatory trial appointment rules, skin allergies questionnaire, and early morning surcharge calculation.',
            isLive: true,
            fields: [
              'Service Type (Bridal, Bridesmaid, Dinner)',
              'Estimated Duration (mins)',
              'Number of People Included',
              'Makeup Style (Natural Glam, Full Glam, Hijabista, Traditional)',
              'Hair / Hijab Styling Included',
              'False Lashes & Accessories Provided',
              'Touch-Up Service (Hours on standby)',
              'Early Morning Fee (Before 7 AM)',
              'Travel Radius & Outstation Rate',
            ],
            appointmentTypes: [
              'Makeup Trial (90 mins)',
              'Hair / Hijab Trial (60 mins)',
              'Virtual Styling Consultation (30 mins)',
            ],
            packageRules: {
              'customerChoiceAllowed': true,
              'multipleVendorsAllowed': true,
              'requiresAppointmentBeforeBooking': false,
              'optionalTrialAllowed': true,
            },
            bookingRules: {
              'minBookingNoticeDays': 7,
              'depositRequiredPercent': 30,
              'cancellationFreeDays': 14,
            },
            pricingRules: {
              'minBasePrice': 300.0,
              'maxBasePrice': 5000.0,
              'allowsInstallments': true,
            },
            travelRules: {
              'freeTravelKm': 20,
              'pricePerExtraKm': 2.5,
            },
          ),
          CategoryConfigVersion(
            version: '1.1',
            publishedAt: DateTime.now().subtract(const Duration(days: 90)),
            publishedBy: 'System Import',
            changelog: 'Added travel radius support.',
            isLive: false,
            fields: [
              'Service Type',
              'Number of People',
              'Makeup Style',
              'Hair Styling',
              'Travel Fee',
            ],
            appointmentTypes: ['Makeup Trial'],
            packageRules: {'customerChoiceAllowed': true},
            bookingRules: {'minBookingNoticeDays': 5},
            pricingRules: {'minBasePrice': 200.0},
            travelRules: {'freeTravelKm': 15},
          ),
        ],
      ),
      CategoryDynamicConfig(
        id: 'cat-catering',
        categoryName: 'Catering & Banquet',
        icon: Icons.restaurant_menu_outlined,
        color: const Color(0xFFF59E0B),
        activeVersion: '2.1',
        versions: [
          CategoryConfigVersion(
            version: '2.1',
            publishedAt: DateTime.now().subtract(const Duration(days: 15)),
            publishedBy: 'David Chen',
            changelog: 'Added Halal certification verification requirement and dietary options tagging.',
            isLive: true,
            fields: [
              'Cuisine Type (Malay, Chinese, Indian, Western, Fusion)',
              'Menu Format (Buffet, 8-Course Dome, Plated, Food Station)',
              'Guest Count Capacity (Min - Max)',
              'Price Per Pax / Guest',
              'Dietary Options (Halal, Vegetarian, Vegan, Gluten-Free)',
              'Staff & Servers Provided',
              'Cutlery & Table Setting Included',
              'Clean-Up & Waste Disposal Service',
            ],
            appointmentTypes: [
              'Food Tasting Session (2-4 pax)',
              'Menu & Chef Consultation',
              'Dietary & Allergy Review',
            ],
            packageRules: {
              'customerChoiceAllowed': true,
              'multipleVendorsAllowed': false,
              'requiresAppointmentBeforeBooking': false,
              'optionalTrialAllowed': true,
            },
            bookingRules: {
              'minBookingNoticeDays': 14,
              'depositRequiredPercent': 40,
              'finalPaxDeadlineDays': 7,
            },
            pricingRules: {
              'minPricePerPax': 35.0,
              'minGuestCount': 50,
            },
            travelRules: {
              'freeTravelKm': 30,
              'pricePerExtraKm': 3.0,
            },
          ),
        ],
      ),
      CategoryDynamicConfig(
        id: 'cat-venue',
        categoryName: 'Venue & Banquet Hall',
        icon: Icons.account_balance_outlined,
        color: const Color(0xFF0EA5E9),
        activeVersion: '1.5',
        versions: [
          CategoryConfigVersion(
            version: '1.5',
            publishedAt: DateTime.now().subtract(const Duration(days: 45)),
            publishedBy: 'Sarah Wong',
            changelog: 'Added multi-session timing rules and external vendor corkage policies.',
            isLive: true,
            fields: [
              'Maximum Seated & Standing Capacity',
              'Indoor / Outdoor / Glasshouse Setting',
              'Parking Spaces Available',
              'Tables & Banquet Chairs Included',
              'Central AC & Climate Control',
              'AV, Sound System & Stage Lighting',
              'Bridal Suite / VIP Holding Room',
              'External Catering Policy (Permitted / Prohibited)',
              'Curfew & Noise Ordinance Rules',
            ],
            appointmentTypes: [
              'Site Visit & Physical Tour',
              'Floor Plan & Seating Layout Review',
              'Technical AV & Acoustic Test',
            ],
            packageRules: {
              'customerChoiceAllowed': false,
              'fixedAnchorComponent': true,
              'requiresAppointmentBeforeBooking': true,
            },
            bookingRules: {
              'minBookingNoticeDays': 30,
              'depositRequiredPercent': 50,
              'damageSecurityDeposit': 2000.0,
            },
            pricingRules: {
              'minSlotPrice': 3000.0,
              'cleaningFeeIncluded': true,
            },
            travelRules: {
              'freeTravelKm': 0,
            },
          ),
        ],
      ),
      CategoryDynamicConfig(
        id: 'cat-photo',
        categoryName: 'Photography & Cinema',
        icon: Icons.camera_alt_outlined,
        color: const Color(0xFF3B82F6),
        activeVersion: '2.0',
        versions: [
          CategoryConfigVersion(
            version: '2.0',
            publishedAt: DateTime.now().subtract(const Duration(days: 10)),
            publishedBy: 'Sarah Wong',
            changelog: 'Added drone pilot license upload and same-day-edit delivery guarantees.',
            isLive: true,
            fields: [
              'Coverage Duration (Hours)',
              'Number of Lead & Secondary Photographers',
              'Cinematography / Video Included (4K / 1080p)',
              'Drone Aerial Shots Included (Licensed Pilot)',
              'Deliverables (Photobook, USB Drive, Online Gallery)',
              'Expected Turnaround Days for Raw & Edited Photos',
              'Same-Day-Edit (SDE) Video Capability',
            ],
            appointmentTypes: [
              'Pre-Wedding Moodboard Consultation',
              'Location Scouting & Lighting Assessment',
            ],
            packageRules: {
              'customerChoiceAllowed': true,
              'multipleVendorsAllowed': true,
            },
            bookingRules: {
              'minBookingNoticeDays': 7,
              'depositRequiredPercent': 30,
            },
            pricingRules: {
              'minPackagePrice': 1200.0,
            },
            travelRules: {
              'freeTravelKm': 25,
              'pricePerExtraKm': 2.0,
            },
          ),
        ],
      ),
    ]);

    // Initialize Duplicate Matches
    _duplicateMatches.addAll([
      DuplicateMatch(
        id: 'DUP-01',
        entityType: 'Vendor',
        name1: 'ABC Wedding Catering Services',
        name2: 'ABC Catering & Events Sdn Bhd',
        id1: 'v-102',
        id2: 'v-998',
        similarityScore: 0.92,
        reason: 'Identical contact phone (+6012-345-6789), identical business address in Petaling Jaya, and matching SSM prefix.',
        details1: {
          'id': 'v-102',
          'phone': '+6012-345-6789',
          'email': 'contact@abccatering.my',
          'location': 'Petaling Jaya, Selangor',
          'activeServices': 4,
          'status': 'Verified',
        },
        details2: {
          'id': 'v-998',
          'phone': '+6012-345-6789',
          'email': 'abc.events.my@gmail.com',
          'location': 'PJ Trade Centre, Selangor',
          'activeServices': 1,
          'status': 'Pending Approval',
        },
      ),
      DuplicateMatch(
        id: 'DUP-02',
        entityType: 'Service',
        name1: 'Bridal Makeup & Styling Mastery',
        name2: 'Bridal Makeup and Hairstyling (Standard)',
        id1: 'srv-001',
        id2: 'srv-044',
        similarityScore: 0.88,
        reason: 'Same vendor (Glam Studio), same photo set hash, price diff < RM 50.',
        details1: {
          'id': 'srv-001',
          'vendor': 'Glam Studio',
          'price': 'RM 800',
          'photosCount': 6,
          'status': 'Approved',
        },
        details2: {
          'id': 'srv-044',
          'vendor': 'Glam Studio',
          'price': 'RM 780',
          'photosCount': 6,
          'status': 'Draft',
        },
      ),
    ]);
  }

  // ==========================================
  // GLOBAL SEARCH ENGINE
  // ==========================================
  List<AdminSearchResult> searchMarketplace({
    required String query,
    required AdminProvider admin,
    required List<CommonServiceInfo> workflowServices,
    required List<CollaborativePackage> workflowPackages,
    required List<ServiceAppointmentBooking> workflowAppointments,
  }) {
    if (query.trim().isEmpty) return [];

    final q = query.trim().toLowerCase();
    final List<AdminSearchResult> results = [];

    // 1. Search Vendors
    for (final v in admin.vendors) {
      if (v.name.toLowerCase().contains(q) ||
          v.category.toLowerCase().contains(q) ||
          v.id.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: v.id,
          title: v.name,
          subtitle: '${v.category} • Rating: ${v.rating} (${v.reviews} reviews)',
          type: MarketplaceEntityType.vendor,
          status: v.suspended ? 'Suspended' : (v.verified ? 'Verified' : 'Pending'),
          metadata: {'vendorId': v.id, 'vendor': v},
        ));
      }
    }

    // 2. Search Services
    for (final s in workflowServices) {
      if (s.serviceName.toLowerCase().contains(q) ||
          s.category.displayName.toLowerCase().contains(q) ||
          s.vendorName.toLowerCase().contains(q) ||
          s.id.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: s.id,
          title: s.serviceName,
          subtitle: 'Vendor: ${s.vendorName} • Category: ${s.category.displayName} • RM ${s.startingPrice.toStringAsFixed(0)}',
          type: MarketplaceEntityType.service,
          status: s.status.displayName,
          metadata: {'serviceId': s.id, 'service': s},
        ));
      }
    }

    // 3. Search Packages
    for (final p in workflowPackages) {
      if (p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.id.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: p.id,
          title: p.title,
          subtitle: 'RM ${p.basePrice.toStringAsFixed(0)} • ${p.components.length} components • Events: ${p.eventTypes.join(", ")}',
          type: MarketplaceEntityType.package,
          status: p.status.displayName,
          metadata: {'packageId': p.id, 'package': p},
        ));
      }
    }

    // 4. Search Appointments
    for (final a in workflowAppointments) {
      if (a.appointmentTypeName.toLowerCase().contains(q) ||
          a.customerName.toLowerCase().contains(q) ||
          a.vendorName.toLowerCase().contains(q) ||
          a.id.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: a.id,
          title: '${a.appointmentTypeName} (${a.customerName})',
          subtitle: 'Vendor: ${a.vendorName} • Date: ${a.scheduledDate.toString().split(" ")[0]} at ${a.scheduledTime}',
          type: MarketplaceEntityType.appointment,
          status: a.status.displayName,
          metadata: {'appointmentId': a.id, 'appointment': a},
        ));
      }
    }

    // 5. Search Bookings
    for (final b in admin.bookings) {
      if (b.id.toLowerCase().contains(q) ||
          b.userName.toLowerCase().contains(q) ||
          b.vendorName.toLowerCase().contains(q) ||
          b.packageName.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: b.id,
          title: 'Booking ${b.id} — ${b.userName}',
          subtitle: 'Vendor: ${b.vendorName} • Package: ${b.packageName} • RM ${b.amount.toStringAsFixed(0)}',
          type: MarketplaceEntityType.booking,
          status: b.status.toUpperCase(),
          metadata: {'bookingId': b.id, 'booking': b},
        ));
      }
    }

    // 6. Search Transactions
    for (final t in admin.transactions) {
      if (t.id.toLowerCase().contains(q) ||
          t.party.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: t.id,
          title: 'Transaction ${t.id} — RM ${t.amount.toStringAsFixed(2)}',
          subtitle: 'Party: ${t.party} • Date: ${t.date}',
          type: MarketplaceEntityType.payment,
          status: t.status.toUpperCase(),
          metadata: {'transactionId': t.id, 'transaction': t},
        ));
      }
    }

    // 7. Search Support Cases
    for (final c in _supportCases) {
      if (c.id.toLowerCase().contains(q) ||
          c.subject.toLowerCase().contains(q) ||
          c.customerName.toLowerCase().contains(q) ||
          c.category.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: c.id,
          title: '${c.id}: ${c.subject}',
          subtitle: 'Customer: ${c.customerName} • Category: ${c.category} • Priority: ${c.priority}',
          type: MarketplaceEntityType.supportCase,
          status: c.status,
          metadata: {'caseId': c.id, 'case': c},
        ));
      }
    }

    // 8. Search Users / Customers
    for (final u in admin.users) {
      if (u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.id.toLowerCase().contains(q)) {
        results.add(AdminSearchResult(
          id: u.id,
          title: u.name,
          subtitle: '${u.email} • Role: ${u.role.toUpperCase()}',
          type: MarketplaceEntityType.customer,
          status: u.status.toUpperCase(),
          metadata: {'userId': u.id, 'user': u},
        ));
      }
    }

    return results;
  }

  // ==========================================
  // CASE ACTIONS
  // ==========================================
  void updateCaseStatus(String caseId, String newStatus, String adminName) {
    final index = _supportCases.indexWhere((c) => c.id == caseId);
    if (index >= 0) {
      final oldCase = _supportCases[index];
      final newTimeline = List<AdminCaseTimelineItem>.from(oldCase.timeline)
        ..add(AdminCaseTimelineItem(
          actor: adminName,
          role: 'Admin',
          action: 'Updated Status',
          details: 'Status changed from ${oldCase.status} to $newStatus',
          timestamp: DateTime.now(),
        ));
      _supportCases[index] = oldCase.copyWith(status: newStatus, timeline: newTimeline);
      logAdminAction(
        adminName: adminName,
        action: 'Updated Support Case Status',
        entityType: 'Support Case',
        entityId: caseId,
        entityName: oldCase.subject,
        details: 'Changed status to $newStatus',
      );
      notifyListeners();
    }
  }

  void addCaseMessage({
    required String caseId,
    required String actor,
    required String role,
    required String action,
    required String message,
  }) {
    final index = _supportCases.indexWhere((c) => c.id == caseId);
    if (index >= 0) {
      final oldCase = _supportCases[index];
      final newTimeline = List<AdminCaseTimelineItem>.from(oldCase.timeline)
        ..add(AdminCaseTimelineItem(
          actor: actor,
          role: role,
          action: action,
          details: message,
          timestamp: DateTime.now(),
        ));
      _supportCases[index] = oldCase.copyWith(timeline: newTimeline);
      notifyListeners();
    }
  }

  // ==========================================
  // AUDIT LOG RECORDER
  // ==========================================
  void logAdminAction({
    required String adminName,
    required String action,
    required String entityType,
    required String entityId,
    required String entityName,
    required String details,
  }) {
    _auditLogs.insert(
      0,
      AdminAuditLogEntry(
        id: 'LOG-${DateTime.now().millisecondsSinceEpoch % 100000}',
        adminName: adminName,
        role: _currentRole.title,
        action: action,
        entityType: entityType,
        entityId: entityId,
        entityName: entityName,
        details: details,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  // ==========================================
  // DUPLICATE ACTIONS
  // ==========================================
  void resolveDuplicate(String duplicateId, String resolution) {
    _duplicateMatches.removeWhere((d) => d.id == duplicateId);
    logAdminAction(
      adminName: 'Admin',
      action: 'Resolved Duplicate',
      entityType: 'Duplicate Detection',
      entityId: duplicateId,
      entityName: duplicateId,
      details: 'Resolution chosen: $resolution',
    );
    notifyListeners();
  }

  // ==========================================
  // CATEGORY CONFIG PUBLISHING
  // ==========================================
  void publishCategoryVersion({
    required String categoryId,
    required String newVersionNumber,
    required String changelog,
    required List<String> fields,
    required List<String> appointmentTypes,
    required String adminName,
  }) {
    final index = _categoryConfigs.indexWhere((c) => c.id == categoryId);
    if (index >= 0) {
      final oldConfig = _categoryConfigs[index];
      final newVersion = CategoryConfigVersion(
        version: newVersionNumber,
        publishedAt: DateTime.now(),
        publishedBy: adminName,
        changelog: changelog,
        isLive: true,
        fields: fields,
        appointmentTypes: appointmentTypes,
        packageRules: oldConfig.currentVersion.packageRules,
        bookingRules: oldConfig.currentVersion.bookingRules,
        pricingRules: oldConfig.currentVersion.pricingRules,
        travelRules: oldConfig.currentVersion.travelRules,
      );

      final updatedVersions = [newVersion, ...oldConfig.versions];
      _categoryConfigs[index] = CategoryDynamicConfig(
        id: oldConfig.id,
        categoryName: oldConfig.categoryName,
        icon: oldConfig.icon,
        color: oldConfig.color,
        activeVersion: newVersionNumber,
        versions: updatedVersions,
      );

      logAdminAction(
        adminName: adminName,
        action: 'Published Category Version',
        entityType: 'Category',
        entityId: categoryId,
        entityName: oldConfig.categoryName,
        details: 'Published version $newVersionNumber: $changelog',
      );
      notifyListeners();
    }
  }

  CategoryDynamicConfig? getCategoryConfig(String categoryName) {
    try {
      return _categoryConfigs.firstWhere(
        (c) => c.categoryName.toLowerCase() == categoryName.toLowerCase() || c.id == categoryName,
      );
    } catch (_) {
      return null;
    }
  }

  void publishNewVersion({
    String? categoryName,
    String? versionNumber,
    String? changelog,
    String? publishedBy,
  }) {
    publishCategoryVersion(
      categoryId: categoryName ?? '',
      newVersionNumber: versionNumber ?? '1.0',
      changelog: changelog ?? '',
      fields: ['General Info', 'Pricing', 'Availability'],
      appointmentTypes: ['Consultation', 'Site Visit'],
      adminName: publishedBy ?? 'Admin',
    );
  }

  void migrateServicesToLatestVersion(String categoryId) {
    logAdminAction(
      adminName: 'Admin',
      action: 'Migrated Services to Latest Version',
      entityType: 'Category',
      entityId: categoryId,
      entityName: categoryId,
      details: 'All active services migrated to latest configuration version.',
    );
    notifyListeners();
  }
}
