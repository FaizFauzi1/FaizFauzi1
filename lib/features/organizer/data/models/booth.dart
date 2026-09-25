enum BoothZone { a, b, vip }

enum BoothStatus { available, pending, booked }

class Booth {
  final String id;
  final String number;
  final BoothZone zone;
  final String size;
  final double earlyBirdPriceRm;
  final double normalPriceRm;
  final BoothStatus status;
  final String? vendorId;
  final String? vendorName;
  final double gridX;
  final double gridY;
  final double gridW;
  final double gridH;

  const Booth({
    required this.id,
    required this.number,
    required this.zone,
    required this.size,
    required this.earlyBirdPriceRm,
    required this.normalPriceRm,
    required this.status,
    this.vendorId,
    this.vendorName,
    this.gridX = 0,
    this.gridY = 0,
    this.gridW = 1,
    this.gridH = 1,
  });

  String get zoneLabel => switch (zone) {
        BoothZone.a => 'Zone A',
        BoothZone.b => 'Zone B',
        BoothZone.vip => 'VIP',
      };

  String get statusLabel => switch (status) {
        BoothStatus.available => 'Available',
        BoothStatus.pending => 'Pending',
        BoothStatus.booked => 'Booked',
      };

  static BoothStatus statusFromDb(String? value) {
    return switch (value) {
      'pending' => BoothStatus.pending,
      'booked' => BoothStatus.booked,
      _ => BoothStatus.available,
    };
  }

  static BoothZone zoneFromDb(String? value) {
    return switch (value) {
      'b' => BoothZone.b,
      'vip' => BoothZone.vip,
      _ => BoothZone.a,
    };
  }

  factory Booth.fromRow(Map<String, dynamic> row, {String? vendorName}) {
    final booth = row['booth'] as Map<String, dynamic>?;
    final exhibitor = row['exhibitor'] as Map<String, dynamic>?;
    final data = booth ?? row;
    return Booth(
      id: data['id'] as String,
      number: data['number'] as String,
      zone: zoneFromDb(data['zone'] as String?),
      size: (data['size_label'] as String?) ?? '3×3m',
      earlyBirdPriceRm: (data['early_bird_price_rm'] as num?)?.toDouble() ?? 0,
      normalPriceRm: (data['normal_price_rm'] as num?)?.toDouble() ?? 0,
      status: statusFromDb(data['status'] as String?),
      vendorId: (data['exhibitor_id'] ?? exhibitor?['id']) as String?,
      vendorName: vendorName ?? exhibitor?['company_name'] as String?,
      gridX: (data['grid_x'] as num?)?.toDouble() ?? 0,
      gridY: (data['grid_y'] as num?)?.toDouble() ?? 0,
      gridW: (data['grid_w'] as num?)?.toDouble() ?? 1,
      gridH: (data['grid_h'] as num?)?.toDouble() ?? 1,
    );
  }

  static List<Booth> sampleData() => [
        const Booth(id: 'b1', number: 'A-01', zone: BoothZone.a, size: '3×3m', earlyBirdPriceRm: 2800, normalPriceRm: 3500, status: BoothStatus.booked, vendorId: 'v1', vendorName: 'Glam Bridal Studio', gridX: 0, gridY: 0),
        const Booth(id: 'b2', number: 'A-02', zone: BoothZone.a, size: '3×3m', earlyBirdPriceRm: 2800, normalPriceRm: 3500, status: BoothStatus.booked, vendorId: 'v2', vendorName: 'Royal Catering Co', gridX: 1, gridY: 0),
        const Booth(id: 'b3', number: 'A-03', zone: BoothZone.a, size: '3×3m', earlyBirdPriceRm: 2800, normalPriceRm: 3500, status: BoothStatus.pending, vendorId: 'v5', vendorName: 'LensArt Photography', gridX: 2, gridY: 0),
        const Booth(id: 'b4', number: 'B-01', zone: BoothZone.b, size: '2×2m', earlyBirdPriceRm: 1800, normalPriceRm: 2200, status: BoothStatus.available, gridX: 0, gridY: 1),
        const Booth(id: 'b5', number: 'B-02', zone: BoothZone.b, size: '2×2m', earlyBirdPriceRm: 1800, normalPriceRm: 2200, status: BoothStatus.available, gridX: 1, gridY: 1),
        const Booth(id: 'b6', number: 'B-03', zone: BoothZone.b, size: '2×2m', earlyBirdPriceRm: 1800, normalPriceRm: 2200, status: BoothStatus.booked, vendorId: 'v3', vendorName: 'Floral Dreams', gridX: 2, gridY: 1),
        const Booth(id: 'b7', number: 'VIP-01', zone: BoothZone.vip, size: '5×4m', earlyBirdPriceRm: 6500, normalPriceRm: 8000, status: BoothStatus.booked, vendorId: 'v4', vendorName: 'Grand Ballroom Décor', gridX: 0, gridY: 2, gridW: 2),
        const Booth(id: 'b8', number: 'VIP-02', zone: BoothZone.vip, size: '5×4m', earlyBirdPriceRm: 6500, normalPriceRm: 8000, status: BoothStatus.pending, vendorId: 'v6', vendorName: 'Diamond Jewellers', gridX: 2, gridY: 2, gridW: 2),
      ];
}
