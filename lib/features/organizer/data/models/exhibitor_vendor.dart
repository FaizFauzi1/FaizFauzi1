import 'package:flutter/material.dart';

enum ExhibitorStatus {
  pending,
  underReview,
  infoRequested,
  approved,
  paymentPending,
  confirmed,
  rejected,
  completed,
}

enum PaymentStatus { paid, partial, unpaid }

class ExhibitorPackage {
  final String id;
  final String name;
  final double priceRm;
  final String description;
  final List<String> includes;
  final String boothDimensions;
  final bool isCustom;
  final int maxSlots;

  const ExhibitorPackage({
    required this.id,
    required this.name,
    required this.priceRm,
    required this.description,
    required this.includes,
    required this.boothDimensions,
    this.isCustom = false,
    this.maxSlots = 30,
  });

  static List<ExhibitorPackage> defaultPackages() {
    return const [
      ExhibitorPackage(
        id: 'pkg-basic',
        name: 'Basic',
        priceRm: 1500,
        description: 'Ideal for boutique vendors and start-ups looking for essential floor presence.',
        includes: [
          '1 Standard Shell Scheme Booth',
          '2 Chairs & 1 Discussion Table',
          'Standard Fascia Name Board',
          '1 General Waste Bin',
          'Standard Event Directory Listing',
        ],
        boothDimensions: '3m × 3m (9 sqm)',
        maxSlots: 35,
      ),
      ExhibitorPackage(
        id: 'pkg-standard',
        name: 'Standard',
        priceRm: 2500,
        description: 'Our most popular package for growing wedding brands requiring high-traffic power.',
        includes: [
          'Larger Booth Space in Prime Walkway',
          'Dedicated 13A Single Phase Electricity',
          '4 Chairs & 2 Discussion Tables',
          'Spotlights & Enhanced Fascia Lighting',
          'EventEase In-App Exhibitor Spotlight',
          '2 Complimentary Staff QR Passes',
        ],
        boothDimensions: '3m × 4m (12 sqm)',
        maxSlots: 30,
      ),
      ExhibitorPackage(
        id: 'pkg-premium',
        name: 'Premium',
        priceRm: 4000,
        description: 'High visibility island corner booth with turnkey marketing & lead capture.',
        includes: [
          'Corner Island Prime Location by Main Stage',
          'Full 3-Phase Electricity & High-speed Wi-Fi',
          'VIP Lounge Furniture Set (Sofa + Counter)',
          'EventEase Social Media & Email Blast Feature',
          'Integrated Digital Lead QR Scanner',
          '4 Complimentary Staff VIP Passes',
        ],
        boothDimensions: '6m × 4m (24 sqm)',
        maxSlots: 15,
      ),
      ExhibitorPackage(
        id: 'pkg-custom',
        name: 'Custom',
        priceRm: 0,
        description: 'Tailored booth dimensions, stage sponsorships, and tailored technical builds.',
        includes: [
          'Custom Pavilion or Raw Space Sizing',
          'Dedicated Organizer Liaison & Rigging',
          'Main Stage Speaking / Fashion Slot',
          'Custom Marketing & Sponsorship Banners',
        ],
        boothDimensions: 'Custom / Raw Space',
        isCustom: true,
        maxSlots: 5,
      ),
    ];
  }
}

class ExhibitorStaffPass {
  final String id;
  final String name;
  final String role;
  final String phone;
  final String? email;
  final String qrPayload;
  final bool isCheckedIn;
  final DateTime? checkedInAt;
  final DateTime? issuedAt;

  String get qrCode => qrPayload;

  const ExhibitorStaffPass({
    required this.id,
    required this.name,
    required this.role,
    required this.phone,
    this.email,
    String? qrPayload,
    String? qrCode,
    this.isCheckedIn = false,
    this.checkedInAt,
    this.issuedAt,
  }) : qrPayload = qrPayload ?? qrCode ?? '';

  ExhibitorStaffPass copyWith({
    String? id,
    String? name,
    String? role,
    String? phone,
    String? email,
    String? qrPayload,
    bool? isCheckedIn,
    DateTime? checkedInAt,
    DateTime? issuedAt,
  }) {
    return ExhibitorStaffPass(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      qrPayload: qrPayload ?? this.qrPayload,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      checkedInAt: checkedInAt ?? this.checkedInAt,
      issuedAt: issuedAt ?? this.issuedAt,
    );
  }
}

class ExhibitorVendor {
  final String id;
  final String? expoId;
  final String? expoName;
  final String companyName;
  final String category;
  final String contactName;
  final String phone;
  final String email;
  final String? businessRegistration;
  final String? website;
  final String? socialMedia;
  final String? description;
  final String? logoUrl;
  final ExhibitorStatus status;
  final String? boothNumber;
  final String? boothHall;
  final String? boothSize;
  final PaymentStatus paymentStatus;
  final double boothFeeRm;
  final double paidRm;
  final String? packageName;
  final DateTime appliedAt;
  final DateTime? paymentDeadline;

  // Detailed Application Requirements
  final String? exhibitingCategory;
  final String? preferredLocation;
  final List<String> requirements;
  final bool marketingOptIn;

  // Organizer query communication
  final String? infoRequestMessage;
  final String? infoResponseMessage;

  // Staff passes
  final List<ExhibitorStaffPass> staffPasses;

  // Post Event metrics & review
  final int visitorsInteracted;
  final int leadsCollected;
  final int bookingsCount;
  final double salesValueRm;
  final double? eventRating;
  final String? reviewComment;

  const ExhibitorVendor({
    required this.id,
    this.expoId,
    this.expoName,
    required this.companyName,
    required this.category,
    required this.contactName,
    required this.phone,
    required this.email,
    this.businessRegistration,
    this.website,
    this.socialMedia,
    this.description,
    this.logoUrl,
    required this.status,
    this.boothNumber,
    this.boothHall = 'Hall A',
    this.boothSize = '3m × 3m',
    required this.paymentStatus,
    required this.boothFeeRm,
    required this.paidRm,
    this.packageName,
    required this.appliedAt,
    this.paymentDeadline,
    this.exhibitingCategory,
    this.preferredLocation = 'Any',
    this.requirements = const [],
    this.marketingOptIn = true,
    this.infoRequestMessage,
    this.infoResponseMessage,
    this.staffPasses = const [],
    this.visitorsInteracted = 0,
    this.leadsCollected = 0,
    this.bookingsCount = 0,
    this.salesValueRm = 0.0,
    this.eventRating,
    this.reviewComment,
  });

  double get outstandingRm => boothFeeRm - paidRm;

  double? get postEventRating => eventRating;
  String? get postEventReview => reviewComment;
  String get boothZone => preferredLocation ?? 'Zone A';

  String get statusLabel {
    return switch (status) {
      ExhibitorStatus.pending => 'Pending',
      ExhibitorStatus.underReview => 'Under Review',
      ExhibitorStatus.infoRequested => 'Info Requested',
      ExhibitorStatus.approved => 'Approved',
      ExhibitorStatus.paymentPending => 'Payment Due',
      ExhibitorStatus.confirmed => 'Confirmed',
      ExhibitorStatus.rejected => 'Rejected',
      ExhibitorStatus.completed => 'Completed',
    };
  }

  Color get statusColor {
    return switch (status) {
      ExhibitorStatus.pending => Colors.orange,
      ExhibitorStatus.underReview => Colors.indigo,
      ExhibitorStatus.infoRequested => Colors.amber.shade900,
      ExhibitorStatus.approved => const Color(0xFF10B981),
      ExhibitorStatus.paymentPending => Colors.deepOrange,
      ExhibitorStatus.confirmed => const Color(0xFF059669),
      ExhibitorStatus.rejected => Colors.redAccent,
      ExhibitorStatus.completed => Colors.blueGrey,
    };
  }

  static ExhibitorStatus statusFromDb(String? value) {
    return switch (value) {
      'under_review' => ExhibitorStatus.underReview,
      'info_requested' => ExhibitorStatus.infoRequested,
      'approved' => ExhibitorStatus.approved,
      'payment_pending' => ExhibitorStatus.paymentPending,
      'confirmed' => ExhibitorStatus.confirmed,
      'completed' => ExhibitorStatus.completed,
      'rejected' => ExhibitorStatus.rejected,
      'withdrawn' => ExhibitorStatus.rejected,
      _ => ExhibitorStatus.pending,
    };
  }

  static PaymentStatus paymentFromDb(String? value) {
    return switch (value) {
      'paid' => PaymentStatus.paid,
      'partial' => PaymentStatus.partial,
      _ => PaymentStatus.unpaid,
    };
  }

  factory ExhibitorVendor.fromRow(Map<String, dynamic> row) {
    final booth = row['booth'] as Map<String, dynamic>?;
    final exhibitor = row['exhibitor'] as Map<String, dynamic>?;
    final data = exhibitor ?? row;
    return ExhibitorVendor(
      id: data['id'] as String,
      expoId: data['expo_id'] as String?,
      expoName: data['expo_name'] as String?,
      companyName: data['company_name'] as String,
      category: (data['category'] as String?) ?? 'General',
      contactName: data['contact_name'] as String,
      phone: data['phone'] as String,
      email: data['email'] as String,
      businessRegistration: data['business_registration'] as String?,
      website: data['website'] as String?,
      socialMedia: data['social_media'] as String?,
      description: data['description'] as String?,
      logoUrl: data['logo_url'] as String?,
      status: statusFromDb(data['status'] as String?),
      boothNumber: booth?['number'] as String? ?? data['preferred_booth'] as String?,
      boothHall: (data['booth_hall'] as String?) ?? 'Hall A',
      boothSize: (data['booth_size'] as String?) ?? '3m × 3m',
      paymentStatus: paymentFromDb(data['payment_status'] as String?),
      boothFeeRm: (data['booth_fee_rm'] as num?)?.toDouble() ?? 0,
      paidRm: (data['paid_rm'] as num?)?.toDouble() ?? 0,
      packageName: data['package_name'] as String?,
      appliedAt: DateTime.parse((data['applied_at'] ?? data['created_at']) as String),
      paymentDeadline: data['payment_deadline'] != null ? DateTime.parse(data['payment_deadline'] as String) : null,
      exhibitingCategory: data['exhibiting_category'] as String?,
      preferredLocation: data['preferred_location'] as String? ?? 'Any',
      requirements: (data['requirements'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      marketingOptIn: (data['marketing_opt_in'] as bool?) ?? true,
      infoRequestMessage: data['info_request_message'] as String?,
      infoResponseMessage: data['info_response_message'] as String?,
      visitorsInteracted: (data['visitors_interacted'] as num?)?.toInt() ?? 0,
      leadsCollected: (data['leads_collected'] as num?)?.toInt() ?? 0,
      bookingsCount: (data['bookings_count'] as num?)?.toInt() ?? 0,
      salesValueRm: (data['sales_value_rm'] as num?)?.toDouble() ?? 0.0,
      eventRating: (data['event_rating'] as num?)?.toDouble(),
      reviewComment: data['review_comment'] as String?,
    );
  }

  ExhibitorVendor copyWith({
    String? id,
    String? expoId,
    String? expoName,
    String? companyName,
    String? category,
    String? contactName,
    String? phone,
    String? email,
    String? businessRegistration,
    String? website,
    String? socialMedia,
    String? description,
    String? logoUrl,
    ExhibitorStatus? status,
    String? boothNumber,
    String? boothHall,
    String? boothSize,
    PaymentStatus? paymentStatus,
    double? boothFeeRm,
    double? paidRm,
    String? packageName,
    DateTime? appliedAt,
    DateTime? paymentDeadline,
    String? exhibitingCategory,
    String? preferredLocation,
    List<String>? requirements,
    bool? marketingOptIn,
    String? infoRequestMessage,
    String? infoResponseMessage,
    List<ExhibitorStaffPass>? staffPasses,
    int? visitorsInteracted,
    int? leadsCollected,
    int? bookingsCount,
    double? salesValueRm,
    double? eventRating,
    String? reviewComment,
  }) {
    return ExhibitorVendor(
      id: id ?? this.id,
      expoId: expoId ?? this.expoId,
      expoName: expoName ?? this.expoName,
      companyName: companyName ?? this.companyName,
      category: category ?? this.category,
      contactName: contactName ?? this.contactName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      businessRegistration: businessRegistration ?? this.businessRegistration,
      website: website ?? this.website,
      socialMedia: socialMedia ?? this.socialMedia,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      status: status ?? this.status,
      boothNumber: boothNumber ?? this.boothNumber,
      boothHall: boothHall ?? this.boothHall,
      boothSize: boothSize ?? this.boothSize,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      boothFeeRm: boothFeeRm ?? this.boothFeeRm,
      paidRm: paidRm ?? this.paidRm,
      packageName: packageName ?? this.packageName,
      appliedAt: appliedAt ?? this.appliedAt,
      paymentDeadline: paymentDeadline ?? this.paymentDeadline,
      exhibitingCategory: exhibitingCategory ?? this.exhibitingCategory,
      preferredLocation: preferredLocation ?? this.preferredLocation,
      requirements: requirements ?? this.requirements,
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
      infoRequestMessage: infoRequestMessage ?? this.infoRequestMessage,
      infoResponseMessage: infoResponseMessage ?? this.infoResponseMessage,
      staffPasses: staffPasses ?? this.staffPasses,
      visitorsInteracted: visitorsInteracted ?? this.visitorsInteracted,
      leadsCollected: leadsCollected ?? this.leadsCollected,
      bookingsCount: bookingsCount ?? this.bookingsCount,
      salesValueRm: salesValueRm ?? this.salesValueRm,
      eventRating: eventRating ?? this.eventRating,
      reviewComment: reviewComment ?? this.reviewComment,
    );
  }

  static List<ExhibitorVendor> sampleData() {
    final now = DateTime.now();
    return [
      ExhibitorVendor(
        id: 'v1',
        expoId: 'expo-001',
        expoName: 'AP Event & Wedding Expo 2026',
        companyName: 'Glam Bridal Studio',
        category: 'Bridal / Busana',
        contactName: 'Jane Tan',
        phone: '+60123456789',
        email: 'jane@glambridal.my',
        businessRegistration: '202101034521 (1435211-X)',
        website: 'https://glambridal.my',
        socialMedia: '@glambridalstudio',
        description: 'Premier couture gowns, designer tuxedos, and bridal styling in Kuala Lumpur.',
        status: ExhibitorStatus.confirmed,
        boothNumber: 'B04',
        boothHall: 'Hall A',
        boothSize: '3m × 4m',
        paymentStatus: PaymentStatus.paid,
        boothFeeRm: 2500,
        paidRm: 2500,
        packageName: 'Standard',
        appliedAt: now.subtract(const Duration(days: 45)),
        paymentDeadline: now.subtract(const Duration(days: 30)),
        exhibitingCategory: 'Bridal / Busana',
        preferredLocation: 'High traffic',
        requirements: const ['Electricity', 'Additional table', 'Internet'],
        marketingOptIn: true,
        staffPasses: const [
          ExhibitorStaffPass(
            id: 'sp-1',
            name: 'Ahmad Rizal',
            role: 'Booth Manager',
            phone: '+60123456789',
            qrPayload: 'EE-EXPO-SP-1001',
            isCheckedIn: true,
          ),
          ExhibitorStaffPass(
            id: 'sp-2',
            name: 'Sarah Wong',
            role: 'Bridal Stylist',
            phone: '+60177888999',
            qrPayload: 'EE-EXPO-SP-1002',
            isCheckedIn: false,
          ),
          ExhibitorStaffPass(
            id: 'sp-3',
            name: 'Ali Imran',
            role: 'Support Staff',
            phone: '+60199887766',
            qrPayload: 'EE-EXPO-SP-1003',
            isCheckedIn: false,
          ),
        ],
        visitorsInteracted: 147,
        leadsCollected: 62,
        bookingsCount: 11,
        salesValueRm: 18500,
        eventRating: 5.0,
        reviewComment: 'Exceptional crowd quality and flawless organizer coordination!',
      ),
      ExhibitorVendor(
        id: 'v2',
        expoId: 'expo-001',
        expoName: 'AP Event & Wedding Expo 2026',
        companyName: 'Royal Catering Co',
        category: 'Catering',
        contactName: 'Ahmad Rizal',
        phone: '+60198765432',
        email: 'ahmad@royalcatering.my',
        businessRegistration: '201902098711 (1324881-A)',
        website: 'https://royalcatering.my',
        socialMedia: '@royalcatering_kl',
        description: 'Authentic Malay royal banquet & western fusion live buffet counters.',
        status: ExhibitorStatus.approved,
        boothNumber: 'A02',
        boothHall: 'Hall A',
        boothSize: '3m × 3m',
        paymentStatus: PaymentStatus.unpaid,
        boothFeeRm: 2500,
        paidRm: 0,
        packageName: 'Standard',
        appliedAt: now.subtract(const Duration(days: 4)),
        paymentDeadline: now.add(const Duration(days: 5)),
        exhibitingCategory: 'Catering',
        preferredLocation: 'Entrance',
        requirements: const ['Electricity', 'Water', 'Additional table'],
        marketingOptIn: true,
      ),
      ExhibitorVendor(
        id: 'v3',
        expoId: 'expo-001',
        expoName: 'AP Event & Wedding Expo 2026',
        companyName: 'LensArt Cinematic',
        category: 'Photography & Videography',
        contactName: 'Sarah Wong',
        phone: '+60177888999',
        email: 'sarah@lensart.my',
        businessRegistration: '202203049102 (1548291-K)',
        website: 'https://lensart.my',
        socialMedia: '@lensart_weddings',
        description: 'Award-winning destination wedding photography and cinematic 4K films.',
        status: ExhibitorStatus.infoRequested,
        boothNumber: 'B02',
        paymentStatus: PaymentStatus.unpaid,
        boothFeeRm: 4000,
        paidRm: 0,
        packageName: 'Premium',
        appliedAt: now.subtract(const Duration(days: 2)),
        exhibitingCategory: 'Photography',
        preferredLocation: 'Main stage',
        requirements: const ['Electricity', 'Internet', 'Display equipment'],
        marketingOptIn: true,
        infoRequestMessage: 'Please provide your SSM document and equipment power requirements for the video wall.',
      ),
      ExhibitorVendor(
        id: 'v4',
        expoId: 'expo-001',
        expoName: 'AP Event & Wedding Expo 2026',
        companyName: 'Floral Dreams Décor',
        category: 'Decoration',
        contactName: 'Mei Ling',
        phone: '+60111222333',
        email: 'mei@floraldreams.my',
        businessRegistration: '202001099234 (1209384-M)',
        status: ExhibitorStatus.underReview,
        paymentStatus: PaymentStatus.unpaid,
        boothFeeRm: 1500,
        paidRm: 0,
        packageName: 'Basic',
        appliedAt: now.subtract(const Duration(hours: 18)),
        exhibitingCategory: 'Decoration',
        preferredLocation: 'Any',
        requirements: const ['Water', 'Additional table'],
        marketingOptIn: false,
      ),
      ExhibitorVendor(
        id: 'v5',
        expoId: 'expo-002',
        expoName: 'Penang Grand Wedding Expo 2026',
        companyName: 'Heritage Couture MUA',
        category: 'MUA',
        contactName: 'Nurul Huda',
        phone: '+60144555666',
        email: 'huda@heritagecouture.my',
        status: ExhibitorStatus.paymentPending,
        boothNumber: 'C01',
        paymentStatus: PaymentStatus.unpaid,
        boothFeeRm: 1500,
        paidRm: 0,
        packageName: 'Basic',
        appliedAt: now.subtract(const Duration(days: 3)),
        paymentDeadline: now.add(const Duration(days: 4)),
        exhibitingCategory: 'MUA',
        preferredLocation: 'Any',
        requirements: const ['Electricity', 'Additional chairs'],
        marketingOptIn: true,
      ),
      ExhibitorVendor(
        id: 'v6',
        expoId: 'expo-001',
        expoName: 'AP Event & Wedding Expo 2026',
        companyName: 'Sweet Romance Doorgifts',
        category: 'Doorgift',
        contactName: 'Kenneth Lee',
        phone: '+60166778899',
        email: 'kenneth@sweetromance.my',
        status: ExhibitorStatus.rejected,
        paymentStatus: PaymentStatus.unpaid,
        boothFeeRm: 1500,
        paidRm: 0,
        packageName: 'Basic',
        appliedAt: now.subtract(const Duration(days: 10)),
        reviewComment: 'Category quota reached for doorgift vendors at this hall.',
      ),
    ];
  }
}
