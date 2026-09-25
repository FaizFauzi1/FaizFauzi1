enum VisitorCheckInStatus { registered, checkedIn, left }

class ExpoVisitor {
  final String id;
  final String name;
  final String phone;
  final DateTime? weddingDate;
  final String budgetRange;
  final List<String> interests;
  final List<String> savedVendorIds;
  final List<String> visitedBooths;
  final VisitorCheckInStatus status;
  final DateTime registeredAt;
  final DateTime? checkedInAt;
  final String ticketCode;

  static VisitorCheckInStatus statusFromDb(String? value) {
    return switch (value) {
      'checked_in' => VisitorCheckInStatus.checkedIn,
      'left' => VisitorCheckInStatus.left,
      _ => VisitorCheckInStatus.registered,
    };
  }

  factory ExpoVisitor.fromRow(
    Map<String, dynamic> row, {
    List<String> savedVendorIds = const [],
    List<String> visitedBooths = const [],
  }) {
    final interests = row['interests'];
    return ExpoVisitor(
      id: row['id'] as String,
      name: row['name'] as String,
      phone: row['phone'] as String,
      weddingDate: row['wedding_date'] != null ? DateTime.parse(row['wedding_date'] as String) : null,
      budgetRange: (row['budget_range'] as String?) ?? '—',
      interests: interests is List ? interests.map((e) => '$e').toList() : const [],
      savedVendorIds: savedVendorIds,
      visitedBooths: visitedBooths,
      status: statusFromDb(row['status'] as String?),
      registeredAt: DateTime.parse((row['registered_at'] ?? row['created_at']) as String),
      checkedInAt: row['checked_in_at'] != null ? DateTime.parse(row['checked_in_at'] as String) : null,
      ticketCode: (row['ticket_code'] as String?) ?? '—',
    );
  }

  const ExpoVisitor({
    required this.id,
    required this.name,
    required this.phone,
    this.weddingDate,
    required this.budgetRange,
    required this.interests,
    required this.savedVendorIds,
    required this.visitedBooths,
    required this.status,
    required this.registeredAt,
    this.checkedInAt,
    required this.ticketCode,
  });

  static List<ExpoVisitor> sampleData() {
    final now = DateTime.now();
    return [
      ExpoVisitor(
        id: 'vis1',
        name: 'Amira & Hakim',
        phone: '+60123450001',
        weddingDate: now.add(const Duration(days: 120)),
        budgetRange: 'RM 80k – 120k',
        interests: ['Photography', 'Catering', 'Decoration'],
        savedVendorIds: ['v1', 'v2', 'v4'],
        visitedBooths: ['A-01', 'A-02', 'VIP-01'],
        status: VisitorCheckInStatus.checkedIn,
        registeredAt: now.subtract(const Duration(days: 14)),
        checkedInAt: now.subtract(const Duration(hours: 2)),
        ticketCode: 'EXPO-KL-2100',
      ),
      ExpoVisitor(
        id: 'vis2',
        name: 'Priya Sharma',
        phone: '+60123450002',
        weddingDate: now.add(const Duration(days: 200)),
        budgetRange: 'RM 50k – 80k',
        interests: ['Makeup', 'Florist'],
        savedVendorIds: ['v1', 'v3'],
        visitedBooths: ['A-01', 'B-03'],
        status: VisitorCheckInStatus.checkedIn,
        registeredAt: now.subtract(const Duration(days: 7)),
        checkedInAt: now.subtract(const Duration(hours: 1, minutes: 20)),
        ticketCode: 'EXPO-KL-2101',
      ),
      ExpoVisitor(
        id: 'vis3',
        name: 'Chen Wei Ling',
        phone: '+60123450003',
        weddingDate: now.add(const Duration(days: 90)),
        budgetRange: 'RM 30k – 50k',
        interests: ['Florist', 'Cake'],
        savedVendorIds: ['v3'],
        visitedBooths: ['B-03'],
        status: VisitorCheckInStatus.registered,
        registeredAt: now.subtract(const Duration(days: 3)),
        ticketCode: 'EXPO-KL-2102',
      ),
      ExpoVisitor(
        id: 'vis4',
        name: 'Nur Aisyah',
        phone: '+60123450006',
        weddingDate: now.add(const Duration(days: 150)),
        budgetRange: 'RM 60k – 90k',
        interests: ['Jewellery', 'Photography'],
        savedVendorIds: ['v4', 'v6'],
        visitedBooths: [],
        status: VisitorCheckInStatus.registered,
        registeredAt: now.subtract(const Duration(hours: 6)),
        ticketCode: 'EXPO-KL-2103',
      ),
    ];
  }
}

class ExpoMapVendor {
  final String boothNumber;
  final String vendorName;
  final String category;
  final double mapX;
  final double mapY;

  factory ExpoMapVendor.fromRow(Map<String, dynamic> row) {
    final booth = row['booth'] as Map<String, dynamic>?;
    if (booth == null) {
      throw StateError('ExpoMapVendor requires booth data');
    }
    return ExpoMapVendor(
      boothNumber: booth['number'] as String,
      vendorName: row['company_name'] as String,
      category: (row['category'] as String?) ?? 'Vendor',
      mapX: (booth['map_x'] as num?)?.toDouble() ?? 0.2,
      mapY: (booth['map_y'] as num?)?.toDouble() ?? 0.2,
    );
  }

  const ExpoMapVendor({
    required this.boothNumber,
    required this.vendorName,
    required this.category,
    required this.mapX,
    required this.mapY,
  });

  static List<ExpoMapVendor> sampleData() => const [
        ExpoMapVendor(boothNumber: 'A-01', vendorName: 'Glam Bridal Studio', category: 'Makeup', mapX: 0.15, mapY: 0.2),
        ExpoMapVendor(boothNumber: 'A-02', vendorName: 'Royal Catering Co', category: 'Catering', mapX: 0.35, mapY: 0.2),
        ExpoMapVendor(boothNumber: 'A-03', vendorName: 'LensArt Photography', category: 'Photo', mapX: 0.55, mapY: 0.2),
        ExpoMapVendor(boothNumber: 'B-03', vendorName: 'Floral Dreams', category: 'Florist', mapX: 0.55, mapY: 0.45),
        ExpoMapVendor(boothNumber: 'VIP-01', vendorName: 'Grand Ballroom Décor', category: 'Décor', mapX: 0.25, mapY: 0.7),
        ExpoMapVendor(boothNumber: 'VIP-02', vendorName: 'Diamond Jewellers', category: 'Jewellery', mapX: 0.55, mapY: 0.7),
      ];
}
