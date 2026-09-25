enum TicketTier { free, vip }

enum TicketSaleChannel { online, walkIn, promo }

class ExpoTicketType {
  final String id;
  final TicketTier tier;
  final String name;
  final double priceRm;
  final String description;
  final int quota;
  final int sold;
  final bool isActive;

  const ExpoTicketType({
    required this.id,
    required this.tier,
    required this.name,
    required this.priceRm,
    required this.description,
    required this.quota,
    required this.sold,
    required this.isActive,
  });

  int get remaining => quota - sold;

  static TicketTier tierFromDb(String? value) => value == 'vip' ? TicketTier.vip : TicketTier.free;

  factory ExpoTicketType.fromRow(Map<String, dynamic> row) {
    return ExpoTicketType(
      id: row['id'] as String,
      tier: tierFromDb(row['tier'] as String?),
      name: row['name'] as String,
      priceRm: (row['price_rm'] as num?)?.toDouble() ?? 0,
      description: (row['description'] as String?) ?? '',
      quota: (row['quota'] as num?)?.toInt() ?? 0,
      sold: (row['sold_count'] as num?)?.toInt() ?? 0,
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  static List<ExpoTicketType> sampleData() => const [
        ExpoTicketType(
          id: 'tt1',
          tier: TicketTier.free,
          name: 'General Admission',
          priceRm: 0,
          description: 'Access to all public zones',
          quota: 3000,
          sold: 1840,
          isActive: true,
        ),
        ExpoTicketType(
          id: 'tt2',
          tier: TicketTier.vip,
          name: 'VIP Experience',
          priceRm: 49,
          description: 'Early entry, VIP lounge, goodie bag',
          quota: 500,
          sold: 260,
          isActive: true,
        ),
      ];
}

class TicketSale {
  final String id;
  final String ticketCode;
  final String buyerName;
  final TicketTier tier;
  final double amountRm;
  final TicketSaleChannel channel;
  final DateTime purchasedAt;
  final bool checkedIn;

  static TicketSaleChannel channelFromDb(String? value) {
    return switch (value) {
      'walk_in' => TicketSaleChannel.walkIn,
      'promo' => TicketSaleChannel.promo,
      _ => TicketSaleChannel.online,
    };
  }

  factory TicketSale.fromRow(Map<String, dynamic> row) {
    final type = row['ticket_type'] as Map<String, dynamic>?;
    return TicketSale(
      id: row['id'] as String,
      ticketCode: row['ticket_code'] as String,
      buyerName: row['buyer_name'] as String,
      tier: ExpoTicketType.tierFromDb(type?['tier'] as String?),
      amountRm: (row['amount_rm'] as num?)?.toDouble() ?? 0,
      channel: channelFromDb(row['channel'] as String?),
      purchasedAt: DateTime.parse((row['purchased_at'] ?? row['created_at']) as String),
      checkedIn: row['checked_in'] as bool? ?? false,
    );
  }

  const TicketSale({
    required this.id,
    required this.ticketCode,
    required this.buyerName,
    required this.tier,
    required this.amountRm,
    required this.channel,
    required this.purchasedAt,
    required this.checkedIn,
  });

  static List<TicketSale> sampleData() {
    final now = DateTime.now();
    return [
      TicketSale(
        id: 'ts1',
        ticketCode: 'EXPO-KL-2100',
        buyerName: 'Amira & Hakim',
        tier: TicketTier.free,
        amountRm: 0,
        channel: TicketSaleChannel.online,
        purchasedAt: now.subtract(const Duration(days: 14)),
        checkedIn: true,
      ),
      TicketSale(
        id: 'ts2',
        ticketCode: 'EXPO-KL-2088',
        buyerName: 'Jason VIP Lim',
        tier: TicketTier.vip,
        amountRm: 49,
        channel: TicketSaleChannel.online,
        purchasedAt: now.subtract(const Duration(days: 5)),
        checkedIn: true,
      ),
      TicketSale(
        id: 'ts3',
        ticketCode: 'EXPO-KL-2103',
        buyerName: 'Nur Aisyah',
        tier: TicketTier.free,
        amountRm: 0,
        channel: TicketSaleChannel.promo,
        purchasedAt: now.subtract(const Duration(hours: 6)),
        checkedIn: false,
      ),
      TicketSale(
        id: 'ts4',
        ticketCode: 'EXPO-KL-2095',
        buyerName: 'Walk-in Guest',
        tier: TicketTier.free,
        amountRm: 0,
        channel: TicketSaleChannel.walkIn,
        purchasedAt: now.subtract(const Duration(minutes: 30)),
        checkedIn: true,
      ),
    ];
  }
}

class AttendanceSnapshot {
  final int totalRegistered;
  final int checkedInNow;
  final int vipCheckedIn;
  final int hourlyRate;
  final List<int> hourlyTrend;

  const AttendanceSnapshot({
    required this.totalRegistered,
    required this.checkedInNow,
    required this.vipCheckedIn,
    required this.hourlyRate,
    required this.hourlyTrend,
  });

  static AttendanceSnapshot sample() => const AttendanceSnapshot(
        totalRegistered: 2100,
        checkedInNow: 847,
        vipCheckedIn: 142,
        hourlyRate: 68,
        hourlyTrend: [12, 28, 45, 62, 78, 95, 110, 98, 85, 68],
      );
}
