class Venue {
  final String id;
  final String vendorId; // Links venue to a vendor
  final String name;
  final String description;
  final String location;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final double pricePerPerson;
  final List<String> categories;
  final Map<String, dynamic> contactInfo;
  final bool isAvailable;
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? capacity;
  final List<String>? amenities;

  Venue({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.location,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.pricePerPerson,
    required this.categories,
    required this.contactInfo,
    this.isAvailable = true,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
    this.capacity,
    this.amenities,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'name': name,
      'description': description,
      'location': location,
      'images': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'pricePerPerson': pricePerPerson,
      'categories': categories,
      'contactInfo': contactInfo,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'capacity': capacity,
      'amenities': amenities,
    };
  }

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'],
      vendorId: json['vendorId'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      images: List<String>.from(json['images']),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'] as int,
      pricePerPerson: (json['pricePerPerson'] as num).toDouble(),
      categories: List<String>.from(json['categories']),
      contactInfo: Map<String, dynamic>.from(json['contactInfo']),
      isAvailable: json['isAvailable'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      capacity: json['capacity'] != null ? json['capacity'] as int : null,
      amenities: json['amenities'] != null
          ? List<String>.from(json['amenities'])
          : null,
    );
  }

  factory Venue.fromSupabase(Map<String, dynamic> json) {
    return Venue(
      id: json['id'],
      vendorId: json['vendor_id'],
      name: json['name'],
      description: json['description'] ?? '',
      location: (json['locations'] is List && (json['locations'] as List).isNotEmpty) 
          ? json['locations'][0].toString() 
          : (json['location']?.toString() ?? ''), 
      images: (json['images'] is List) ? List<String>.from(json['images']) : [],
      rating: 4.5, 
      reviewCount: 0,
      pricePerPerson: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      categories: [json['category']?.toString() ?? 'Venue'],
      contactInfo: {}, 
      isAvailable: json['active'] ?? true,
      isFeatured: false,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'].toString()) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'].toString()) : DateTime.now(),
      capacity: json['max_bookings_per_day'] is int ? json['max_bookings_per_day'] : 10, 
      amenities: (json['amenities'] is List) ? List<String>.from(json['amenities']) : [],
    );
  }
  /// A blank placeholder Venue used as a fallback when no real venue is available.
  factory Venue.sample() {
    return Venue(
      id: '',
      vendorId: '',
      name: '',
      description: '',
      location: '',
      images: [],
      rating: 0,
      reviewCount: 0,
      pricePerPerson: 0,
      categories: [],
      contactInfo: {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
