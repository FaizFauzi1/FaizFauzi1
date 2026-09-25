enum RegionType { country, state, city }

class Region {
  final String id;
  final String name;
  final RegionType type;
  final String? parentId; // For hierarchical structure
  final String? code; // e.g., MY for Malaysia, KL for Kuala Lumpur
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Region({
    required this.id,
    required this.name,
    required this.type,
    this.parentId,
    this.code,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Region.fromMap(Map<String, dynamic> map, String id) {
    return Region(
      id: id,
      name: map['name'] ?? '',
      type: RegionType.values.firstWhere(
        (e) => e.toString() == 'RegionType.${map['type']}',
        orElse: () => RegionType.city,
      ),
      parentId: map['parentId'],
      code: map['code'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.toString().split('.').last,
      'parentId': parentId,
      'code': code,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Get full path (e.g., "Malaysia > Selangor > Kuala Lumpur") with cycle detection
  String getFullPath(Map<String, Region> allRegions, {Set<String>? visited}) {
    final currentVisited = Set<String>.from(visited ?? {});
    if (currentVisited.contains(id)) return '(Cycle Detected: $name)';
    currentVisited.add(id);

    if (parentId == null) return name;

    final parent = allRegions[parentId];
    if (parent == null) return name;

    return '${parent.getFullPath(allRegions, visited: currentVisited)} > $name';
  }

  // Get children regions
  List<Region> getChildren(List<Region> allRegions) {
    return allRegions.where((r) => r.parentId == id).toList();
  }

  // Generate sample regions
  static List<Region> getSampleRegions() {
    final regions = <Region>[];
    int idCounter = 1;

    // Countries
    final countries = [
      {'name': 'Malaysia', 'code': 'MY'},
      {'name': 'Singapore', 'code': 'SG'},
      {'name': 'Indonesia', 'code': 'ID'},
      {'name': 'Thailand', 'code': 'TH'},
    ];

    final countryIds = <String, String>{};

    for (final country in countries) {
      final id = (idCounter++).toString();
      countryIds[country['name']!] = id;
      regions.add(Region(
        id: id,
        name: country['name']!,
        type: RegionType.country,
        code: country['code'],
        createdAt: DateTime.now().subtract(Duration(days: idCounter * 10)),
        updatedAt: DateTime.now(),
      ));
    }

    // States/Provinces
    final states = {
      'Malaysia': [
        {'name': 'Selangor', 'code': 'SL'},
        {'name': 'Kuala Lumpur', 'code': 'KL'},
        {'name': 'Penang', 'code': 'PN'},
        {'name': 'Johor', 'code': 'JH'},
        {'name': 'Perak', 'code': 'PR'},
        {'name': 'Kedah', 'code': 'KD'},
        {'name': 'Kelantan', 'code': 'KT'},
        {'name': 'Terengganu', 'code': 'TR'},
        {'name': 'Pahang', 'code': 'PH'},
        {'name': 'Melaka', 'code': 'ML'},
        {'name': 'Negeri Sembilan', 'code': 'NS'},
        {'name': 'Perlis', 'code': 'PL'},
        {'name': 'Sabah', 'code': 'SB'},
        {'name': 'Sarawak', 'code': 'SR'},
      ],
      'Singapore': [
        {'name': 'Central Region', 'code': 'CR'},
        {'name': 'East Region', 'code': 'ER'},
        {'name': 'North Region', 'code': 'NR'},
        {'name': 'North-East Region', 'code': 'NER'},
        {'name': 'West Region', 'code': 'WR'},
      ],
      'Indonesia': [
        {'name': 'Jakarta', 'code': 'JK'},
        {'name': 'West Java', 'code': 'JB'},
        {'name': 'Central Java', 'code': 'JT'},
        {'name': 'East Java', 'code': 'JI'},
        {'name': 'Bali', 'code': 'BA'},
      ],
      'Thailand': [
        {'name': 'Bangkok', 'code': 'BK'},
        {'name': 'Chiang Mai', 'code': 'CM'},
        {'name': 'Phuket', 'code': 'PK'},
        {'name': 'Pattaya', 'code': 'PT'},
      ],
    };

    final stateIds = <String, String>{};

    for (final country in countries) {
      final countryName = country['name']!;
      final countryId = countryIds[countryName]!;
      final countryStates = states[countryName] ?? [];

      for (final state in countryStates) {
        final id = (idCounter++).toString();
        stateIds['$countryName-${state['name']}'] = id;
        regions.add(Region(
          id: id,
          name: state['name']!,
          type: RegionType.state,
          parentId: countryId,
          code: state['code'],
          createdAt: DateTime.now().subtract(Duration(days: idCounter * 5)),
          updatedAt: DateTime.now(),
        ));
      }
    }

    // Cities
    final cities = {
      'Malaysia-Selangor': [
        'Petaling Jaya', 'Shah Alam', 'Subang Jaya', 'Klang', 'Ampang',
        'Cheras', 'Selayang', 'Rawang', 'Gombak', 'Kajang'
      ],
      'Malaysia-Kuala Lumpur': [
        'Bukit Bintang', 'Wangsa Maju', 'Cheras', 'Setiawangsa', 'Titiwangsa',
        'Bangsar', 'Seputeh', 'Lembah Pantai', 'Segambut', 'Batu'
      ],
      'Malaysia-Penang': [
        'George Town', 'Bayan Lepas', 'Butterworth', 'Bukit Mertajam', 'Nibong Tebal'
      ],
      'Singapore-Central Region': [
        'Orchard', 'Marina Bay', 'Raffles Place', 'Tanjong Pagar', 'Outram'
      ],
      'Singapore-East Region': [
        'Tampines', 'Pasir Ris', 'Changi', 'Bedok', 'Paya Lebar'
      ],
      'Indonesia-Jakarta': [
        'Central Jakarta', 'West Jakarta', 'East Jakarta', 'North Jakarta', 'South Jakarta'
      ],
      'Thailand-Bangkok': [
        'Siam', 'Sukhumvit', 'Silom', 'Chatuchak', 'Asok'
      ],
    };

    for (final entry in cities.entries) {
      final stateId = stateIds[entry.key];
      if (stateId != null) {
        for (final cityName in entry.value) {
          regions.add(Region(
            id: (idCounter++).toString(),
            name: cityName,
            type: RegionType.city,
            parentId: stateId,
            createdAt: DateTime.now().subtract(Duration(days: idCounter * 2)),
            updatedAt: DateTime.now(),
          ));
        }
      }
    }

    return regions;
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Region &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
