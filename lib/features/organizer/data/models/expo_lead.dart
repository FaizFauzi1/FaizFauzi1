enum LeadTemperature { hot, warm, cold }

enum LeadStage { newLead, contacted, followedUp, converted, lost }

class ExpoLead {
  final String id;
  final String visitorName;
  final String phone;
  final DateTime? weddingDate;
  final String budgetRange;
  final List<String> interests;
  final String? assignedVendorId;
  final String? assignedVendorName;
  final LeadTemperature temperature;
  final LeadStage stage;
  final String sourceBooth;
  final DateTime capturedAt;
  final String? notes;

  const ExpoLead({
    required this.id,
    required this.visitorName,
    required this.phone,
    this.weddingDate,
    required this.budgetRange,
    required this.interests,
    this.assignedVendorId,
    this.assignedVendorName,
    required this.temperature,
    required this.stage,
    required this.sourceBooth,
    required this.capturedAt,
    this.notes,
  });

  bool get isAssigned => assignedVendorId != null;

  static LeadTemperature temperatureFromDb(String? value) {
    return switch (value) {
      'hot' => LeadTemperature.hot,
      'cold' => LeadTemperature.cold,
      _ => LeadTemperature.warm,
    };
  }

  static LeadStage stageFromDb(String? value) {
    return switch (value) {
      'contacted' => LeadStage.contacted,
      'followed_up' => LeadStage.followedUp,
      'converted' => LeadStage.converted,
      'lost' => LeadStage.lost,
      _ => LeadStage.newLead,
    };
  }

  factory ExpoLead.fromRow(Map<String, dynamic> row) {
    final exhibitor = row['exhibitor'] as Map<String, dynamic>?;
    final interests = row['interests'];
    return ExpoLead(
      id: row['id'] as String,
      visitorName: row['visitor_name'] as String,
      phone: row['phone'] as String,
      weddingDate: row['wedding_date'] != null ? DateTime.parse(row['wedding_date'] as String) : null,
      budgetRange: (row['budget_range'] as String?) ?? '—',
      interests: interests is List ? interests.map((e) => '$e').toList() : const [],
      assignedVendorId: row['assigned_exhibitor_id'] as String?,
      assignedVendorName: exhibitor?['company_name'] as String?,
      temperature: temperatureFromDb(row['temperature'] as String?),
      stage: stageFromDb(row['stage'] as String?),
      sourceBooth: (row['source_booth'] as String?) ?? '—',
      capturedAt: DateTime.parse((row['captured_at'] ?? row['created_at']) as String),
      notes: row['notes'] as String?,
    );
  }

  static List<ExpoLead> sampleData() {
    final now = DateTime.now();
    return [
      ExpoLead(
        id: 'l1',
        visitorName: 'Amira & Hakim',
        phone: '+60123450001',
        weddingDate: now.add(const Duration(days: 120)),
        budgetRange: 'RM 80k – 120k',
        interests: ['Photography', 'Catering'],
        assignedVendorId: 'v2',
        assignedVendorName: 'Royal Catering Co',
        temperature: LeadTemperature.hot,
        stage: LeadStage.followedUp,
        sourceBooth: 'A-02',
        capturedAt: now.subtract(const Duration(hours: 3)),
        notes: 'Interested in halal buffet for 300 pax',
      ),
      ExpoLead(
        id: 'l2',
        visitorName: 'Priya Sharma',
        phone: '+60123450002',
        weddingDate: now.add(const Duration(days: 200)),
        budgetRange: 'RM 50k – 80k',
        interests: ['Makeup', 'Decoration'],
        assignedVendorId: 'v1',
        assignedVendorName: 'Glam Bridal Studio',
        temperature: LeadTemperature.hot,
        stage: LeadStage.contacted,
        sourceBooth: 'A-01',
        capturedAt: now.subtract(const Duration(hours: 5)),
      ),
      ExpoLead(
        id: 'l3',
        visitorName: 'Chen Wei Ling',
        phone: '+60123450003',
        weddingDate: now.add(const Duration(days: 90)),
        budgetRange: 'RM 30k – 50k',
        interests: ['Florist'],
        temperature: LeadTemperature.warm,
        stage: LeadStage.newLead,
        sourceBooth: 'B-03',
        capturedAt: now.subtract(const Duration(hours: 1)),
      ),
      ExpoLead(
        id: 'l4',
        visitorName: 'Fatimah & Azman',
        phone: '+60123450004',
        weddingDate: now.add(const Duration(days: 180)),
        budgetRange: 'RM 100k+',
        interests: ['VIP Décor', 'Photography'],
        assignedVendorId: 'v4',
        assignedVendorName: 'Grand Ballroom Décor',
        temperature: LeadTemperature.hot,
        stage: LeadStage.converted,
        sourceBooth: 'VIP-01',
        capturedAt: now.subtract(const Duration(days: 1)),
        notes: 'Signed décor package',
      ),
      ExpoLead(
        id: 'l5',
        visitorName: 'Jason Lim',
        phone: '+60123450005',
        budgetRange: 'RM 20k – 30k',
        interests: ['Cake'],
        temperature: LeadTemperature.cold,
        stage: LeadStage.lost,
        sourceBooth: 'Registration',
        capturedAt: now.subtract(const Duration(days: 2)),
        notes: 'Budget too low for expo vendors',
      ),
      ExpoLead(
        id: 'l6',
        visitorName: 'Nur Aisyah',
        phone: '+60123450006',
        weddingDate: now.add(const Duration(days: 150)),
        budgetRange: 'RM 60k – 90k',
        interests: ['Jewellery', 'Photography'],
        temperature: LeadTemperature.warm,
        stage: LeadStage.newLead,
        sourceBooth: 'VIP-02',
        capturedAt: now.subtract(const Duration(minutes: 45)),
      ),
    ];
  }
}
