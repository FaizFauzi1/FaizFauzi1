import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';

enum ExpoStatus { upcoming, ongoing, past, draft, cancelled }

class ExpoSummary {
  final String id;
  final String name;
  final String venue;
  final String? venueCity;
  final DateTime startAt;
  final DateTime endAt;
  final ExpoStatus status;
  final int boothCapacity;
  final int boothsBooked;
  final int vendorCount;
  final int visitorRegistrations;
  final int ticketsSold;
  final double revenueRm;
  final double pendingPaymentsRm;

  // Rich Expo Details for Vendor Discovery
  final String description;
  final String expectedVisitors;
  final String targetAudience;
  final String previousYearStats;
  final String organizerName;
  final double startingPriceRm;
  final List<ExhibitorPackage> packages;

  const ExpoSummary({
    required this.id,
    required this.name,
    required this.venue,
    this.venueCity,
    required this.startAt,
    required this.endAt,
    required this.status,
    required this.boothCapacity,
    required this.boothsBooked,
    required this.vendorCount,
    required this.visitorRegistrations,
    required this.ticketsSold,
    required this.revenueRm,
    required this.pendingPaymentsRm,
    this.description = 'Malaysia’s flagship event and wedding exhibition connecting top-rated bridal, catering, and decor brands with thousands of couples.',
    this.expectedVisitors = '5,000+ Visitors',
    this.targetAudience = 'Engaged Couples, Wedding Planners, Families & Event Curators',
    this.previousYearStats = '8,400+ attendees in 2025 · RM 2.8M bookings closed',
    this.organizerName = 'AP Exhibitions & EventEase Live',
    this.startingPriceRm = 1500.0,
    this.packages = const [],
  });

  double get boothSalesProgress =>
      boothCapacity > 0 ? boothsBooked / boothCapacity : 0;

  int get availableSlots => (boothCapacity - boothsBooked).clamp(0, boothCapacity);

  static ExpoStatus statusFromDb(String? value) {
    return switch (value) {
      'ongoing' => ExpoStatus.ongoing,
      'past' => ExpoStatus.past,
      'draft' => ExpoStatus.draft,
      'cancelled' => ExpoStatus.cancelled,
      _ => ExpoStatus.upcoming,
    };
  }

  factory ExpoSummary.fromRow(Map<String, dynamic> row) {
    DateTime parseDate(dynamic val, [DateTime? fallback]) {
      if (val is DateTime) return val;
      if (val is String && val.isNotEmpty) {
        return DateTime.tryParse(val) ?? fallback ?? DateTime.now();
      }
      return fallback ?? DateTime.now();
    }

    final startAt = parseDate(row['start_at']);
    final endAt = parseDate(row['end_at'], startAt.add(const Duration(days: 3)));

    final venueStr = (row['venue'] ?? row['venue_address'] ?? 'Convention Centre').toString();
    final venueCity = row['venue_city']?.toString() ??
        (venueStr.contains(',') ? venueStr.split(',').last.trim() : null);

    return ExpoSummary(
      id: (row['expo_id'] ?? row['id'] ?? '').toString(),
      name: (row['name'] ?? 'Upcoming Expo').toString(),
      venue: venueStr,
      venueCity: venueCity,
      startAt: startAt,
      endAt: endAt,
      status: statusFromDb(row['status']?.toString()),
      boothCapacity: (row['booth_capacity'] as num?)?.toInt() ?? 60,
      boothsBooked: (row['booths_booked'] as num?)?.toInt() ?? 0,
      vendorCount: (row['vendor_count'] as num?)?.toInt() ?? ((row['booths_booked'] as num?)?.toInt() ?? 0),
      visitorRegistrations: (row['visitor_registrations'] as num?)?.toInt() ?? 0,
      ticketsSold: (row['tickets_sold'] as num?)?.toInt() ?? 0,
      revenueRm: (row['revenue_rm'] as num?)?.toDouble() ?? 0.0,
      pendingPaymentsRm: (row['pending_payments_rm'] as num?)?.toDouble() ?? 0.0,
      description: (row['description']?.toString().isNotEmpty == true)
          ? row['description'].toString()
          : 'Malaysia’s premier bridal and wedding exhibition showcasing leading wedding vendors.',
      expectedVisitors: row['expected_visitors']?.toString() ?? '5,000+ Visitors',
      targetAudience: row['target_audience']?.toString() ??
          'Couples getting married in 2026/2027 and wedding enthusiasts',
      previousYearStats: row['previous_year_stats']?.toString() ??
          'Curated exhibitors · High visitor turnout',
      organizerName: row['organizer_name']?.toString() ?? row['company_name']?.toString() ?? 'EventEase Partner',
      startingPriceRm: (row['starting_price_rm'] as num?)?.toDouble() ?? 1500.0,
      packages: ExhibitorPackage.defaultPackages(),
    );
  }

  static List<ExpoSummary> sampleData() {
    return [
      ExpoSummary(
        id: 'expo-001',
        name: 'AP Event & Wedding Expo 2026',
        venue: 'MITEC (Malaysia International Trade & Exhibition Centre), KL',
        venueCity: 'Kuala Lumpur',
        startAt: DateTime(2026, 10, 10, 10, 0),
        endAt: DateTime(2026, 10, 12, 21, 0),
        status: ExpoStatus.upcoming,
        boothCapacity: 80,
        boothsBooked: 48,
        vendorCount: 46,
        visitorRegistrations: 3850,
        ticketsSold: 4200,
        revenueRm: 245000,
        pendingPaymentsRm: 28000,
        description:
            'The benchmark wedding exhibition in Southeast Asia. Featuring 80+ curated exhibitors across couture bridal gowns, bespoke banquets, master photographers, floral styling, and luxury decor. Extensive marketing reach on social media and wedding portals.',
        expectedVisitors: '5,000+ Qualified Couples',
        targetAudience: 'Brides & Grooms, Families, Wedding Coordinators',
        previousYearStats: '8,400 Visitors in 2025 · RM 2.8M On-Floor Transactions · 96% Exhibitor Satisfaction',
        organizerName: 'AP Weddings & Events SDN BHD',
        startingPriceRm: 1500.0,
        packages: ExhibitorPackage.defaultPackages(),
      ),
      ExpoSummary(
        id: 'expo-002',
        name: 'Penang Grand Wedding Expo 2026',
        venue: 'Setia SPICE Convention Centre',
        venueCity: 'Penang',
        startAt: DateTime(2026, 11, 5, 10, 0),
        endAt: DateTime(2026, 11, 7, 20, 0),
        status: ExpoStatus.upcoming,
        boothCapacity: 60,
        boothsBooked: 35,
        vendorCount: 34,
        visitorRegistrations: 1950,
        ticketsSold: 1800,
        revenueRm: 142000,
        pendingPaymentsRm: 16000,
        description:
            'Northern region’s largest bridal rendezvous. High concentration of diaspora couples, destination banquet venues, and heritage craft vendors.',
        expectedVisitors: '3,500+ Visitors',
        targetAudience: 'Northern Region Couples & Heritage Wedding Planners',
        previousYearStats: '4,600 Attendees · RM 1.4M Direct Deals',
        organizerName: 'Heritage Weddings Malaysia',
        startingPriceRm: 1500.0,
        packages: ExhibitorPackage.defaultPackages(),
      ),
      ExpoSummary(
        id: 'expo-003',
        name: 'Johor AP Wedding Showcase',
        venue: 'Persada Johor International Convention Centre',
        venueCity: 'Johor Bahru',
        startAt: DateTime(2026, 11, 28, 10, 0),
        endAt: DateTime(2026, 11, 29, 21, 0),
        status: ExpoStatus.upcoming,
        boothCapacity: 50,
        boothsBooked: 18,
        vendorCount: 16,
        visitorRegistrations: 980,
        ticketsSold: 1100,
        revenueRm: 72400,
        pendingPaymentsRm: 12000,
        description:
            'Cross-border bridal expo attracting Singaporean and Southern Malaysian wedding couples seeking value and bespoke bridal artisanal services.',
        expectedVisitors: '2,800+ Visitors',
        targetAudience: 'Cross-Border Singapore & JB Couples',
        previousYearStats: '3,100 Visitors · SGD 350k / RM 1.2M Spend',
        organizerName: 'Southern Star Events',
        startingPriceRm: 1500.0,
        packages: ExhibitorPackage.defaultPackages(),
      ),
    ];
  }
}
