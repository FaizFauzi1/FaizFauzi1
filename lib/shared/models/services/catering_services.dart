class CateringService {
  final String id;
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
  final int? maxGuestsServed;
  final List<String>? amenities;
  final String? cuisineType;
  final List<String>? dietaryOptions;
  final int? minimumOrder;

  CateringService({
    required this.id,
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
    this.maxGuestsServed,
    this.amenities,
    this.cuisineType,
    this.dietaryOptions,
    this.minimumOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'maxGuestsServed': maxGuestsServed,
      'amenities': amenities,
      'cuisineType': cuisineType,
      'dietaryOptions': dietaryOptions,
      'minimumOrder': minimumOrder,
    };
  }

  factory CateringService.fromJson(Map<String, dynamic> json) {
    return CateringService(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      location: json['location'],
      images: List<String>.from(json['images']),
      rating: (json['rating'] as num).toDouble(),
      reviewCount: json['reviewCount'],
      pricePerPerson: (json['pricePerPerson'] as num).toDouble(),
      categories: List<String>.from(json['categories']),
      contactInfo: Map<String, dynamic>.from(json['contactInfo']),
      isAvailable: json['isAvailable'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      maxGuestsServed: json['maxGuestsServed'],
      amenities: json['amenities'] != null ? List<String>.from(json['amenities']) : null,
      cuisineType: json['cuisineType'],
      dietaryOptions: json['dietaryOptions'] != null ? List<String>.from(json['dietaryOptions']) : null,
      minimumOrder: json['minimumOrder'],
    );
  }

  static CateringService sample() {
    return CateringService(
      id: 'catering_sample',
      name: 'Sample Catering Service',
      description: 'This is a sample catering service for testing.',
      location: 'Sample Kitchen, Kuala Lumpur',
      images: ['https://via.placeholder.com/300x200?text=Sample+Catering'],
      rating: 4.5,
      reviewCount: 50,
      pricePerPerson: 80.0,
      categories: ['Wedding Catering', 'Corporate Catering'],
      contactInfo: {
        'phone': '+60 123456789',
        'email': 'sample@catering.com',
      },
      isAvailable: true,
      isFeatured: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      maxGuestsServed: 200,
      amenities: ['Setup', 'Cleanup', 'Staff'],
      cuisineType: 'Malay',
      dietaryOptions: ['Halal', 'Vegetarian'],
      minimumOrder: 50,
    );
  }

  // Generate sample catering services for testing
  static List<CateringService> getSampleCaterings() {
    final caterings = <CateringService>[];

    caterings.add(CateringService(
      id: 'catering1',
      name: 'Elegant Wedding Catering',
      description: 'Sophisticated catering service for elegant weddings and celebrations.',
      location: 'Kuala Lumpur, Malaysia',
      images: ['https://via.placeholder.com/300x200?text=Elegant+Wedding+Catering'],
      rating: 4.8,
      reviewCount: 120,
      pricePerPerson: 150.0,
      categories: ['Wedding Catering', 'Fine Dining'],
      contactInfo: {
        'phone': '+60 3-2001',
        'email': 'bookings@elegantweddingcatering.com',
        'website': 'www.elegantweddingcatering.com',
      },
      isAvailable: true,
      isFeatured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
      maxGuestsServed: 300,
      amenities: ['Setup', 'Cleanup', 'Staff', 'Decorative Service'],
      cuisineType: 'International',
      dietaryOptions: ['Halal', 'Vegetarian', 'Vegan', 'Gluten-Free'],
      minimumOrder: 100,
    ));

    caterings.add(CateringService(
      id: 'catering2',
      name: 'Corporate Buffet Services',
      description: 'Professional catering for corporate events, meetings, and business functions.',
      location: 'Cyberjaya, Malaysia',
      images: ['https://via.placeholder.com/300x200?text=Corporate+Buffet+Services'],
      rating: 4.6,
      reviewCount: 95,
      pricePerPerson: 120.0,
      categories: ['Corporate Catering', 'Buffet Service'],
      contactInfo: {
        'phone': '+60 3-2002',
        'email': 'info@corporatebuffet.com',
        'website': 'www.corporatebuffet.com',
      },
      isAvailable: true,
      isFeatured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
      updatedAt: DateTime.now(),
      maxGuestsServed: 500,
      amenities: ['Setup', 'Cleanup', 'Staff', 'AV Support'],
      cuisineType: 'Malay-Chinese',
      dietaryOptions: ['Halal', 'Vegetarian'],
      minimumOrder: 50,
    ));

    caterings.add(CateringService(
      id: 'catering3',
      name: 'Party Catering Delight',
      description: 'Fun and delicious catering for birthday parties with themed menus.',
      location: 'Putrajaya, Malaysia',
      images: ['https://via.placeholder.com/300x200?text=Party+Catering+Delight'],
      rating: 4.7,
      reviewCount: 85,
      pricePerPerson: 90.0,
      categories: ['Party Catering', 'Buffet Service'],
      contactInfo: {
        'phone': '+60 3-2003',
        'email': 'bookings@partycateringdelight.com',
        'website': 'www.partycateringdelight.com',
      },
      isAvailable: true,
      isFeatured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
      maxGuestsServed: 150,
      amenities: ['Setup', 'Cleanup', 'Themed Decorations', 'Entertainment'],
      cuisineType: 'Fusion',
      dietaryOptions: ['Halal', 'Vegetarian', 'Kids Menu'],
      minimumOrder: 30,
    ));

    caterings.add(CateringService(
      id: 'catering4',
      name: 'Fine Dining Experience',
      description: 'Luxury dining experience with gourmet menus for special occasions.',
      location: 'Kuala Lumpur, Malaysia',
      images: ['https://via.placeholder.com/300x200?text=Fine+Dining+Experience'],
      rating: 4.9,
      reviewCount: 150,
      pricePerPerson: 200.0,
      categories: ['Wedding Catering', 'Fine Dining'],
      contactInfo: {
        'phone': '+60 3-2004',
        'email': 'info@finediningexperience.com',
        'website': 'www.finediningexperience.com',
      },
      isAvailable: true,
      isFeatured: true,
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      updatedAt: DateTime.now(),
      maxGuestsServed: 100,
      amenities: ['Private Chef', 'Sommelier', 'Custom Menus', 'Wine Pairing'],
      cuisineType: 'French-Italian',
      dietaryOptions: ['Halal', 'Vegetarian', 'Vegan', 'Gluten-Free', 'Organic'],
      minimumOrder: 20,
    ));

    caterings.add(CateringService(
      id: 'catering5',
      name: 'Halal Catering Services',
      description: 'Authentic halal catering with traditional Malay cuisine.',
      location: 'Kuala Lumpur, Malaysia',
      images: ['https://via.placeholder.com/300x200?text=Halal+Catering+Services'],
      rating: 4.5,
      reviewCount: 110,
      pricePerPerson: 100.0,
      categories: ['Wedding Catering', 'Corporate Catering', 'Party Catering'],
      contactInfo: {
        'phone': '+60 3-2005',
        'email': 'bookings@halalcatering.com',
        'website': 'www.halalcatering.com',
      },
      isAvailable: true,
      isFeatured: false,
      createdAt: DateTime.now().subtract(const Duration(days: 40)),
      updatedAt: DateTime.now(),
      maxGuestsServed: 400,
      amenities: ['Setup', 'Cleanup', 'Staff', 'Halal Certification'],
      cuisineType: 'Malay',
      dietaryOptions: ['Halal', 'Vegetarian'],
      minimumOrder: 75,
    ));

    return caterings;
  }
}
