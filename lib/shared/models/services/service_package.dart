import 'service_enums.dart';

class ServicePackage {
  final String id;
  final String name;
  final String description;
  final String category;
  final String? vendorName;
  final String? vendorId;
  final Map<int, double> priceByPax; // pax -> price
  final VenueDetails? venueDetails;
  final PackageMenus? menus;
  final PackageInclusions? inclusions;
  final List<String> facilities;
  final List<String> services;
  final List<String> photography;
  final Map<String, dynamic> additionalDetails;
  final bool isActive;
  final ApprovalStatus approvalStatus;

  ServicePackage({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.vendorName,
    this.vendorId,
    required this.priceByPax,
    this.venueDetails,
    this.menus,
    this.inclusions,
    required this.facilities,
    required this.services,
    required this.photography,
    this.additionalDetails = const {},
    this.isActive = true,
    this.approvalStatus = ApprovalStatus.pending,
  });

  factory ServicePackage.fromJson(Map<String, dynamic> json) => ServicePackage.fromMap(json);

  factory ServicePackage.fromMap(Map<String, dynamic> map) {
    return ServicePackage(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      vendorId: map['vendorId']?.toString(),
      category: map['category']?.toString() ?? 'Other',
      vendorName: map['vendorName']?.toString(),
      priceByPax: (map['priceByPax'] is Map) 
          ? Map<int, double>.from(map['priceByPax'].map((k, v) => MapEntry(int.tryParse(k.toString()) ?? 0, (v as num).toDouble()))) 
          : {},
      venueDetails: map['venueDetails'] is Map ? VenueDetails.fromMap(Map<String, dynamic>.from(map['venueDetails'])) : null,
      menus: map['menus'] is Map ? PackageMenus.fromMap(Map<String, dynamic>.from(map['menus'])) : null,
      inclusions: map['inclusions'] is Map ? PackageInclusions.fromMap(Map<String, dynamic>.from(map['inclusions'])) : null,
      facilities: (map['facilities'] is List) 
          ? (map['facilities'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      services: (map['services'] is List) 
          ? (map['services'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      photography: (map['photography'] is List) 
          ? (map['photography'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      additionalDetails: (map['additionalDetails'] is Map) ? Map<String, dynamic>.from(map['additionalDetails']) : {},
      isActive: map['isActive'] ?? true,
      approvalStatus: ApprovalStatus.values.firstWhere(
        (e) => e.name == (map['approvalStatus']?.toString() ?? 'pending').toLowerCase() || e.toString().split('.').last == map['approvalStatus']?.toString(),
        orElse: () => ApprovalStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toJson() => toMap();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'vendorName': vendorName,
      'vendorId': vendorId,
      'priceByPax': priceByPax,
      'venueDetails': venueDetails?.toMap(),
      'menus': menus?.toMap(),
      'inclusions': inclusions?.toMap(),
      'facilities': facilities,
      'services': services,
      'photography': photography,
      'additionalDetails': additionalDetails,
      'isActive': isActive,
      'approvalStatus': approvalStatus.toString().split('.').last,
    };
  }

  double getPriceForPax(int pax) {
    // Find the closest pax tier that's >= requested pax
    final availablePax = priceByPax.keys.toList()..sort();
    for (final p in availablePax) {
      if (p >= pax) {
        return priceByPax[p]!;
      }
    }
    // If no tier found, return the highest price
    return priceByPax[availablePax.last] ?? 0.0;
  }

  List<int> getAvailablePax() {
    return priceByPax.keys.toList()..sort();
  }

  double get basePrice {
    if (priceByPax.isEmpty) return 0.0;
    return priceByPax.values.reduce((a, b) => a < b ? a : b);
  }

  ServicePackage copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    String? vendorName,
    Map<int, double>? priceByPax,
    VenueDetails? venueDetails,
    PackageMenus? menus,
    PackageInclusions? inclusions,
    List<String>? facilities,
    List<String>? services,
    List<String>? photography,
    Map<String, dynamic>? additionalDetails,
    bool? isActive,
    ApprovalStatus? approvalStatus,
  }) {
    return ServicePackage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      vendorName: vendorName ?? this.vendorName,
      priceByPax: priceByPax ?? this.priceByPax,
      venueDetails: venueDetails ?? this.venueDetails,
      menus: menus ?? this.menus,
      inclusions: inclusions ?? this.inclusions,
      facilities: facilities ?? this.facilities,
      services: services ?? this.services,
      photography: photography ?? this.photography,
      additionalDetails: additionalDetails ?? this.additionalDetails,
      isActive: isActive ?? this.isActive,
      approvalStatus: approvalStatus ?? this.approvalStatus,
    );
  }
}

class VenueDetails {
  final String? vendorId;
  final String? vendorName;
  final String venueName;
  final String address;
  final int minCapacity;
  final int maxCapacity;
  final String eventTheme;
  final Map<String, String> eventTimes; // session -> time
  final List<String> facilityInclusions;
  final List<String> decorationEquipment;
  final Map<String, dynamic> additionalInfo;

  VenueDetails({
    this.vendorId,
    this.vendorName,
    required this.venueName,
    required this.address,
    required this.minCapacity,
    required this.maxCapacity,
    required this.eventTheme,
    required this.eventTimes,
    required this.facilityInclusions,
    required this.decorationEquipment,
    this.additionalInfo = const {},
  });

  factory VenueDetails.fromMap(Map<String, dynamic> map) {
    return VenueDetails(
      vendorId: map['vendorId']?.toString(),
      vendorName: map['vendorName']?.toString(),
      venueName: map['venueName']?.toString() ?? '',
      address: map['address']?.toString() ?? '',
      minCapacity: (map['minCapacity'] as num?)?.toInt() ?? 0,
      maxCapacity: (map['maxCapacity'] as num?)?.toInt() ?? 0,
      eventTheme: map['eventTheme']?.toString() ?? '',
      eventTimes: (map['eventTimes'] is Map) 
          ? Map<String, String>.from(map['eventTimes'].map((k, v) => MapEntry(k.toString(), v.toString()))) 
          : {},
      facilityInclusions: (map['facilityInclusions'] is List) 
          ? (map['facilityInclusions'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      decorationEquipment: (map['decorationEquipment'] is List) 
          ? (map['decorationEquipment'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      additionalInfo: (map['additionalInfo'] is Map) ? Map<String, dynamic>.from(map['additionalInfo']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'vendorName': vendorName,
      'venueName': venueName,
      'address': address,
      'minCapacity': minCapacity,
      'maxCapacity': maxCapacity,
      'eventTheme': eventTheme,
      'eventTimes': eventTimes,
      'facilityInclusions': facilityInclusions,
      'decorationEquipment': decorationEquipment,
      'additionalInfo': additionalInfo,
    };
  }
}

class PackageMenus {
  final List<String> mainMenu;
  final List<String> bridalDishes;
  final TeaCornerDetails? teaCorner;
  final List<String> sideDishes;
  final Map<String, dynamic> additionalMenus;

  PackageMenus({
    required this.mainMenu,
    required this.bridalDishes,
    this.teaCorner,
    required this.sideDishes,
    this.additionalMenus = const {},
  });

  factory PackageMenus.fromMap(Map<String, dynamic> map) {
    return PackageMenus(
      mainMenu: (map['mainMenu'] is List) 
          ? (map['mainMenu'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      bridalDishes: (map['bridalDishes'] is List) 
          ? (map['bridalDishes'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      teaCorner: map['teaCorner'] is Map ? TeaCornerDetails.fromMap(Map<String, dynamic>.from(map['teaCorner'])) : null,
      sideDishes: (map['sideDishes'] is List) 
          ? (map['sideDishes'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      additionalMenus: (map['additionalMenus'] is Map) ? Map<String, dynamic>.from(map['additionalMenus']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'mainMenu': mainMenu,
      'bridalDishes': bridalDishes,
      'teaCorner': teaCorner?.toMap(),
      'sideDishes': sideDishes,
      'additionalMenus': additionalMenus,
    };
  }
}

class TeaCornerDetails {
  final List<String> fruits;
  final List<String> drinks;
  final List<String> beverages;
  final List<String> snacks;
  final List<String> desserts;
  final String waterService;

  TeaCornerDetails({
    required this.fruits,
    required this.drinks,
    required this.beverages,
    required this.snacks,
    required this.desserts,
    required this.waterService,
  });

  factory TeaCornerDetails.fromMap(Map<String, dynamic> map) {
    return TeaCornerDetails(
      fruits: (map['fruits'] is List) 
          ? (map['fruits'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      drinks: (map['drinks'] is List) 
          ? (map['drinks'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      beverages: (map['beverages'] is List) 
          ? (map['beverages'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      snacks: (map['snacks'] is List) 
          ? (map['snacks'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      desserts: (map['desserts'] is List) 
          ? (map['desserts'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      waterService: map['waterService']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fruits': fruits,
      'drinks': drinks,
      'beverages': beverages,
      'snacks': snacks,
      'desserts': desserts,
      'waterService': waterService,
    };
  }
}

class PackageInclusions {
  final List<String> commonFacilities;
  final List<String> commonDecorations;
  final List<String> commonServices;
  final List<String> photographyServices;
  final Map<String, dynamic> additionalInclusions;

  PackageInclusions({
    required this.commonFacilities,
    required this.commonDecorations,
    required this.commonServices,
    required this.photographyServices,
    this.additionalInclusions = const {},
  });

  factory PackageInclusions.fromMap(Map<String, dynamic> map) {
    return PackageInclusions(
      commonFacilities: (map['commonFacilities'] is List) 
          ? (map['commonFacilities'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      commonDecorations: (map['commonDecorations'] is List) 
          ? (map['commonDecorations'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      commonServices: (map['commonServices'] is List) 
          ? (map['commonServices'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      photographyServices: (map['photographyServices'] is List) 
          ? (map['photographyServices'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList() 
          : [],
      additionalInclusions: (map['additionalInclusions'] is Map) ? Map<String, dynamic>.from(map['additionalInclusions']) : {},
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commonFacilities': commonFacilities,
      'commonDecorations': commonDecorations,
      'commonServices': commonServices,
      'photographyServices': photographyServices,
      'additionalInclusions': additionalInclusions,
    };
  }
}
