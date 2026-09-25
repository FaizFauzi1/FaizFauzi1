import 'package:eventease/features/vendor/models/vendor_service.dart';

enum VendorStatus { pending, onHold, approved, rejected }

enum SubscriptionTier { free, basic, premium, enterprise, standard }

class Vendor {
  final String id;
  final String? userId; // Adding userId for auth linking
  final String name;
  final List<String> categories; // multiple categories

  // Backward compatibility getter for category (returns first category or empty string)
  String get category => categories.isNotEmpty ? categories.first : '';
  final List<String> subcategories; // e.g., Catering types or specialties
  final String? venueType; // required for venue vendors (e.g., Ballroom, Garden)
  final String description;
  final String location;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final VendorStatus status;
  final Map<String, dynamic> documents; // approvals and certificates
  final SubscriptionTier subscriptionTier;
  final Map<String, dynamic> logistics; // delivery support, coverage areas
  final Map<String, dynamic> contactInfo; // phone, email, socials
  final String? email; // vendor admin email
  final String? phone; // vendor phone number
  final List<String> sampleServiceIds; // IDs of sample services for this vendor
  final int planningHorizon; // number of days in advance for planning
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? pendingBookings; // Transient property for dashboard display
  final bool isActive; // Indicates if the vendor is active
  final String? imageUrl; // Single image URL for display
  final List<String>? offeredServices; // List of services offered
  final Map<String, dynamic>? pricing; // Pricing information
  final Map<String, dynamic>? businessHours; // Weekly schedule
  final Map<String, dynamic>? availability; // Service-specific availability or special dates
  final List<String>? portfolio; // Portfolio images
  final Map<String, dynamic>? socialMedia; // Social media links
  final List<String>? tags; // Tags for categorization
  final bool? verified; // Verification status
  final bool? featured; // Featured status
  /// Marketplace listing weight (higher = closer to top). Backed by `priority_score` in Supabase.
  final double priorityScore;
  final List<String> serviceAreas; // Service areas where the vendor operates
  final bool isClaimed; // Whether the vendor profile has been claimed by a user
  final String? claimCode; // Unique code required to claim this business
  final double? commissionRate; // Custom override for commission %
  final bool commissionOverride; // If true, ignore global rate


  Vendor({
    required this.id,
    required this.name,
    required this.categories,
    required this.subcategories,
    this.venueType,
    required this.description,
    required this.location,
    required this.images,
    required this.rating,
    required this.reviewCount,
    required this.status,
    required this.documents,
    required this.subscriptionTier,
    required this.logistics,
    required this.contactInfo,
    this.email,
    this.phone,
    required this.sampleServiceIds,
    this.planningHorizon = 0,
    required this.createdAt,
    required this.updatedAt,
    this.pendingBookings,
    this.isActive = true,
    this.imageUrl,
    this.offeredServices,
    this.pricing,
    this.availability,
    this.portfolio,
    this.socialMedia,
    this.tags,
    this.verified,
    this.featured,
    this.priorityScore = 0,
    this.businessHours,
    this.serviceAreas = const [],
    this.userId,
    this.isClaimed = true,
    this.claimCode,
    this.commissionRate,
    this.commissionOverride = false,
  });

  int bookings = 0; // Number of total bookings
  bool suspended = false; // Whether the vendor is suspended
  int reviews = 0; // Number of reviews

  factory Vendor.fromMap(Map<String, dynamic> map, String id) {
    return Vendor(
      id: id,
      name: map['name'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      subcategories: List<String>.from(map['subcategories'] ?? []),
      venueType: map['venueType'],
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
      status: VendorStatus.values.firstWhere(
        (e) => e.toString() == 'VendorStatus.${map['status']}',
        orElse: () => VendorStatus.pending,
      ),
      documents: Map<String, dynamic>.from(map['documents'] ?? {}),
      subscriptionTier: SubscriptionTier.values.firstWhere(
        (e) => e.toString() == 'SubscriptionTier.${map['subscriptionTier']}',
        orElse: () => SubscriptionTier.free,
      ),
      logistics: Map<String, dynamic>.from(map['logistics'] ?? {}),
      contactInfo: Map<String, dynamic>.from(map['contactInfo'] ?? {}),
      email: map['email'],
      phone: map['phone'],
      sampleServiceIds: List<String>.from(map['sampleServiceIds'] ?? []),
      planningHorizon: (map['planningHorizon'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
      pendingBookings: map['pendingBookings'],
      isActive: map['isActive'] ?? true,
      imageUrl: map['imageUrl'],
      offeredServices: map['offeredServices'] != null ? List<String>.from(map['offeredServices']) : null,
      pricing: map['pricing'] != null ? Map<String, dynamic>.from(map['pricing']) : null,
      tags: map['tags'] != null ? List<String>.from(map['tags']) : null,
      verified: map['verified'],
      featured: map['featured'],
      priorityScore: ((map['priorityScore'] ?? map['priority_score']) as num?)?.toDouble() ?? 0,
      businessHours: map['businessHours'] != null ? Map<String, dynamic>.from(map['businessHours']) : null,
      serviceAreas: map['coverage_area_state'] != null && map['coverage_area_state'].toString().isNotEmpty
          ? map['coverage_area_state'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
          : (map['serviceAreas'] != null ? List<String>.from(map['serviceAreas']) : (map['service_areas'] != null ? List<String>.from(map['service_areas']) : [])),
      isClaimed: map['isClaimed'] ?? true,
      claimCode: map['claimCode'],
      commissionRate: (map['commissionRate'] ?? map['commission_rate'] as num?)?.toDouble(),
      commissionOverride: map['commissionOverride'] ?? map['commission_override'] ?? false,
    );
  }

  factory Vendor.fromSupabase(Map<String, dynamic> json) {
    return Vendor(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      userId: json['user_id']?.toString(),
      name: json['business_name'] ?? 'Unknown Vendor',
      categories: (json['categories'] is List)
          ? List<String>.from(json['categories'])
          : (json['categories'] is String)
              ? (json['categories'] as String)
                  .replaceAll(RegExp(r'[\[\]"]'), '')
                  .split(',')
                  .where((e) => e.trim().isNotEmpty)
                  .map((e) => e.trim())
                  .toList()
              : ['General'],
      subcategories: [],
      // Use 'description' column, fallback to 'business_description' for compatibility
      description: json['description'] ?? json['business_description'] ?? '',
      // Use 'address' column, fallback to 'business_address' for compatibility
      location: json['address'] ?? json['business_address'] ?? json['full_address'] ?? '',
      images: (json['profile_picture_url'] != null && json['profile_picture_url'].toString().trim().isNotEmpty) 
          ? [json['profile_picture_url'].toString()] 
          : [],
      rating: 4.5,
      reviewCount: 0,
      status: _mapStatus(json['profile_completion_status']),
      documents: {},
      subscriptionTier: SubscriptionTier.free,
      logistics: json['logistics'] != null ? Map<String, dynamic>.from(json['logistics']) : {},
      contactInfo: {
        // Use 'email' column, fallback to 'business_email' for compatibility
        'email': json['email'] ?? json['business_email'],
        // Use 'phone' column, fallback to 'business_phone' for compatibility
        'phone': json['phone'] ?? json['business_phone'],
        // Use 'website' column, fallback to 'website_url' for compatibility
        'website': json['website'] ?? json['website_url']
      },
      email: json['email'] ?? json['business_email'],
      phone: json['phone'] ?? json['business_phone'],
      sampleServiceIds: [],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      isActive: true,
      imageUrl: (json['profile_picture_url'] != null && json['profile_picture_url'].toString().trim().isNotEmpty) 
          ? json['profile_picture_url'].toString() 
          : null,
      businessHours: json['business_hours'] != null ? Map<String, dynamic>.from(json['business_hours']) : null,
      serviceAreas: json['coverage_area_state'] != null && json['coverage_area_state'].toString().isNotEmpty
          ? json['coverage_area_state'].toString().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
          : (json['service_areas'] != null ? List<String>.from(json['service_areas']) : []),
      portfolio: json['portfolio'] != null ? List<String>.from(json['portfolio']) : [],
      isClaimed: json['is_claimed'] ?? true,
      claimCode: json['claim_code'],
      priorityScore: (json['priority_score'] as num?)?.toDouble() ?? 0,
      commissionRate: (json['commission_rate'] as num?)?.toDouble(),
      commissionOverride: json['commission_override'] ?? false,
    );
  }

  static VendorStatus _mapStatus(String? status) {
    if (status == 'approved') return VendorStatus.approved;
    if (status == 'pending_review') return VendorStatus.pending;
    if (status == 'rejected') return VendorStatus.rejected;
    return VendorStatus.pending; // Default
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categories': categories,
      'subcategories': subcategories,
      'venueType': venueType,
      'description': description,
      'location': location,
      'images': images,
      'rating': rating,
      'reviewCount': reviewCount,
      'status': status.toString().split('.').last,
      'documents': documents,
      'subscriptionTier': subscriptionTier.toString().split('.').last,
      'logistics': logistics,
      'contactInfo': contactInfo,
      'email': email,
      'phone': phone,
      'sampleServiceIds': sampleServiceIds,
      'planningHorizon': planningHorizon,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pendingBookings': pendingBookings,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'offeredServices': offeredServices,
      'pricing': pricing,
      'tags': tags,
      'verified': verified,
      'featured': featured,
      'priority_score': priorityScore,
      'businessHours': businessHours,
      'serviceAreas': serviceAreas,
      'coverage_area_state': serviceAreas.join(', '),
      'isClaimed': isClaimed,
      'claimCode': claimCode,
      'commission_rate': commissionRate,
      'commission_override': commissionOverride,
    };
  }

  // Computed property for total bookings
  int? get totalBookings => pendingBookings ?? 0;

  // Computed property for monthly revenue
  double? get monthlyRevenue {
    // Base revenue calculation using vendor profile data
    double baseRevenue = 1000.0; // Base monthly revenue

    // Factor in rating (higher rating = higher revenue potential)
    double ratingMultiplier = rating / 5.0; // Normalize to 0-1 scale

    // Factor in review count (more reviews = more established business)
    double reviewMultiplier = 1.0 + (reviewCount / 100.0); // 1.0 + 0.01 per review

    // Factor in subscription tier (higher tiers = higher revenue)
    double tierMultiplier;
    switch (subscriptionTier) {
      case SubscriptionTier.free:
        tierMultiplier = 1.0;
        break;
      case SubscriptionTier.basic:
        tierMultiplier = 1.5;
        break;
      case SubscriptionTier.standard:
        tierMultiplier = 2.0;
        break;
      case SubscriptionTier.premium:
        tierMultiplier = 3.0;
        break;
      case SubscriptionTier.enterprise:
        tierMultiplier = 4.0;
        break;
    }

    // Factor in category (different categories have different revenue potentials)
    double categoryMultiplier;
    String primaryCategory = categories.isNotEmpty ? categories.first : '';
    switch (primaryCategory) {
      case 'Venues':
        categoryMultiplier = 5.0; // Venues typically have higher revenue
        break;
      case 'Catering':
        categoryMultiplier = 3.0;
        break;
      case 'Photography':
        categoryMultiplier = 2.5;
        break;
      case 'Event Planner':
      case 'Wedding Planner':
        categoryMultiplier = 4.0;
        break;
      case 'Hotel':
        categoryMultiplier = 6.0;
        break;
      case 'Fashion Boutique':
        categoryMultiplier = 2.0;
        break;
      case 'Cake':
        categoryMultiplier = 1.5;
        break;
      case 'Florist':
        categoryMultiplier = 1.8;
        break;
      case 'Music':
        categoryMultiplier = 2.2;
        break;
      case 'Decoration':
        categoryMultiplier = 2.8;
        break;
      case 'Beauty':
        categoryMultiplier = 1.8;
        break;
      case 'Makeup Artist':
        categoryMultiplier = 1.6;
        break;
      default:
        categoryMultiplier = 1.0;
        break;
    }

    // Factor in status (approved vendors have higher revenue)
    double statusMultiplier = status == VendorStatus.approved ? 1.0 : 0.5;

    // Calculate final revenue
    double calculatedRevenue = baseRevenue *
        ratingMultiplier *
        reviewMultiplier *
        tierMultiplier *
        categoryMultiplier *
        statusMultiplier;

    // Ensure minimum revenue and round to nearest 100
    return (calculatedRevenue < 500 ? 500 : calculatedRevenue).roundToDouble();
  }

  // Computed property for services
  List<VendorService> get services {
    return []; // TODO: Implement service fetching logic
  }
}
