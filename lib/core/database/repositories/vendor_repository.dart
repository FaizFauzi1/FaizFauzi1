import 'package:eventease/core/database/database_helper.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'dart:convert';

class VendorRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Convert Vendor model to Map for database storage
  Map<String, dynamic> _vendorToMap(Vendor vendor) {
    return {
      'id': vendor.id,
      'name': vendor.name,
      'categories': jsonEncode(vendor.categories),
      'subcategories': vendor.subcategories.isNotEmpty
          ? jsonEncode(vendor.subcategories)
          : null,
      'venueType': vendor.venueType,
      'description': vendor.description,
      'location': vendor.location,
      'images': vendor.images.isNotEmpty ? jsonEncode(vendor.images) : null,
      'rating': vendor.rating,
      'reviewCount': vendor.reviewCount,
      'status': vendor.status.name,
      'documents':
          vendor.documents.isNotEmpty ? jsonEncode(vendor.documents) : null,
      'subscriptionTier': vendor.subscriptionTier.name,
      'logistics':
          vendor.logistics.isNotEmpty ? jsonEncode(vendor.logistics) : null,
      'contactInfo':
          vendor.contactInfo.isNotEmpty ? jsonEncode(vendor.contactInfo) : null,
      'email': vendor.email,
      'phone': vendor.phone,
      'sampleServiceIds': vendor.sampleServiceIds.isNotEmpty
          ? jsonEncode(vendor.sampleServiceIds)
          : null,
      'planningHorizon': vendor.planningHorizon,
      'createdAt': vendor.createdAt.toIso8601String(),
      'updatedAt': vendor.updatedAt.toIso8601String(),
      'pendingBookings': vendor.pendingBookings,
      'isActive': vendor.isActive ? 1 : 0,
      'imageUrl': vendor.imageUrl,
      'offeredServices': vendor.offeredServices != null
          ? jsonEncode(vendor.offeredServices!)
          : null,
      'pricing': vendor.pricing != null ? jsonEncode(vendor.pricing!) : null,
      'availability':
          vendor.availability != null ? jsonEncode(vendor.availability!) : null,
      'portfolio':
          vendor.portfolio != null ? jsonEncode(vendor.portfolio!) : null,
      'socialMedia':
          vendor.socialMedia != null ? jsonEncode(vendor.socialMedia!) : null,
      'tags': vendor.tags != null ? jsonEncode(vendor.tags!) : null,
      'verified': vendor.verified == true ? 1 : 0,
      'featured': vendor.featured == true ? 1 : 0,
    };
  }

  // Convert Map from database to Vendor model
  Vendor _mapToVendor(Map<String, dynamic> map) {
    return Vendor(
      id: map['id'],
      name: map['name'],
      categories: List<String>.from(jsonDecode(map['categories'] ?? '[]')),
      subcategories: map['subcategories'] != null
          ? List<String>.from(jsonDecode(map['subcategories']))
          : [],
      venueType: map['venueType'],
      description: map['description'],
      location: map['location'],
      images: map['images'] != null
          ? List<String>.from(jsonDecode(map['images']))
          : [],
      rating: map['rating']?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] ?? 0,
      status: VendorStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => VendorStatus.pending,
      ),
      documents: map['documents'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['documents']))
          : {},
      subscriptionTier: SubscriptionTier.values.firstWhere(
        (e) => e.name == map['subscriptionTier'],
        orElse: () => SubscriptionTier.free,
      ),
      logistics: map['logistics'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['logistics']))
          : {},
      contactInfo: map['contactInfo'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['contactInfo']))
          : {},
      email: map['email'],
      phone: map['phone'],
      sampleServiceIds: map['sampleServiceIds'] != null
          ? List<String>.from(jsonDecode(map['sampleServiceIds']))
          : [],
      planningHorizon: map['planningHorizon'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      pendingBookings: map['pendingBookings'],
      isActive: map['isActive'] == 1,
      imageUrl: map['imageUrl'],
      offeredServices: map['offeredServices'] != null
          ? List<String>.from(jsonDecode(map['offeredServices']))
          : null,
      pricing: map['pricing'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['pricing']))
          : null,
      availability: map['availability'] != null
          ? List<String>.from(jsonDecode(map['availability']))
          : null,
      portfolio: map['portfolio'] != null
          ? List<String>.from(jsonDecode(map['portfolio']))
          : null,
      socialMedia: map['socialMedia'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['socialMedia']))
          : null,
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags']))
          : null,
      verified: map['verified'] == 1,
      featured: map['featured'] == 1,
    );
  }

  // Basic CRUD Operations
  Future<int> insertVendor(Vendor vendor) async {
    return await _dbHelper.insertVendor(_vendorToMap(vendor));
  }

  Future<List<Vendor>> getAllVendors() async {
    final maps = await _dbHelper.getAllVendors();
    return maps.map((map) => _mapToVendor(map)).toList();
  }

  Future<Vendor?> getVendorById(String id) async {
    final map = await _dbHelper.getVendorById(id);
    return map != null ? _mapToVendor(map) : null;
  }

  Future<List<Vendor>> getVendorsByCategory(String category) async {
    final maps = await _dbHelper.getVendorsByCategory(category);
    return maps.map((map) => _mapToVendor(map)).toList();
  }

  Future<int> updateVendor(Vendor vendor) async {
    return await _dbHelper.updateVendor(vendor.id, _vendorToMap(vendor));
  }

  Future<int> deleteVendor(String id) async {
    return await _dbHelper.deleteVendor(id);
  }

  // Enhanced Business Logic Methods

  // Get active vendors only
  Future<List<Vendor>> getActiveVendors() async {
    final allVendors = await getAllVendors();
    return allVendors.where((vendor) => vendor.isActive).toList();
  }

  // Get vendors by status
  Future<List<Vendor>> getVendorsByStatus(VendorStatus status) async {
    final allVendors = await getAllVendors();
    return allVendors.where((vendor) => vendor.status == status).toList();
  }

  // Get approved vendors
  Future<List<Vendor>> getApprovedVendors() async {
    return getVendorsByStatus(VendorStatus.approved);
  }

  // Get pending vendors (for admin approval)
  Future<List<Vendor>> getPendingVendors() async {
    return getVendorsByStatus(VendorStatus.pending);
  }

  // Get featured vendors
  Future<List<Vendor>> getFeaturedVendors() async {
    final allVendors = await getAllVendors();
    return allVendors.where((vendor) => vendor.featured == true).toList();
  }

  // Get verified vendors
  Future<List<Vendor>> getVerifiedVendors() async {
    final allVendors = await getAllVendors();
    return allVendors.where((vendor) => vendor.verified == true).toList();
  }

  // Get vendors by subscription tier
  Future<List<Vendor>> getVendorsBySubscription(SubscriptionTier tier) async {
    final allVendors = await getAllVendors();
    return allVendors
        .where((vendor) => vendor.subscriptionTier == tier)
        .toList();
  }

  // Get premium vendors
  Future<List<Vendor>> getPremiumVendors() async {
    final allVendors = await getAllVendors();
    return allVendors
        .where((vendor) =>
            vendor.subscriptionTier == SubscriptionTier.premium ||
            vendor.subscriptionTier == SubscriptionTier.enterprise)
        .toList();
  }

  // Search vendors with advanced filters
  Future<List<Vendor>> searchVendors({
    String? query,
    String? category,
    String? location,
    double? minRating,
    double? maxRating,
    bool? verifiedOnly,
    bool? featuredOnly,
    SubscriptionTier? subscriptionTier,
    VendorStatus? status,
  }) async {
    List<Vendor> vendors = await getAllVendors();

    // Apply filters
    if (query != null && query.isNotEmpty) {
      vendors = vendors.where((vendor) {
        return vendor.name.toLowerCase().contains(query.toLowerCase()) ||
            vendor.description.toLowerCase().contains(query.toLowerCase()) ||
            vendor.categories.any(
                (cat) => cat.toLowerCase().contains(query.toLowerCase())) ||
            (vendor.tags != null &&
                vendor.tags!.any(
                    (tag) => tag.toLowerCase().contains(query.toLowerCase())));
      }).toList();
    }

    if (category != null && category.isNotEmpty) {
      vendors = vendors
          .where((vendor) => vendor.categories
              .any((cat) => cat.toLowerCase() == category.toLowerCase()))
          .toList();
    }

    if (location != null && location.isNotEmpty) {
      vendors = vendors
          .where((vendor) =>
              vendor.location.toLowerCase().contains(location.toLowerCase()))
          .toList();
    }

    if (minRating != null) {
      vendors = vendors.where((vendor) => vendor.rating >= minRating).toList();
    }

    if (maxRating != null) {
      vendors = vendors.where((vendor) => vendor.rating <= maxRating).toList();
    }

    if (verifiedOnly == true) {
      vendors = vendors.where((vendor) => vendor.verified == true).toList();
    }

    if (featuredOnly == true) {
      vendors = vendors.where((vendor) => vendor.featured == true).toList();
    }

    if (subscriptionTier != null) {
      vendors = vendors
          .where((vendor) => vendor.subscriptionTier == subscriptionTier)
          .toList();
    }

    if (status != null) {
      vendors = vendors.where((vendor) => vendor.status == status).toList();
    }

    return vendors;
  }

  // Get top-rated vendors
  Future<List<Vendor>> getTopRatedVendors({int limit = 10}) async {
    final allVendors = await getActiveVendors();
    allVendors.sort((a, b) => b.rating.compareTo(a.rating));
    return allVendors.take(limit).toList();
  }

  // Get most popular vendors (by review count)
  Future<List<Vendor>> getMostPopularVendors({int limit = 10}) async {
    final allVendors = await getActiveVendors();
    allVendors.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
    return allVendors.take(limit).toList();
  }

  // Get nearby vendors (simple location-based search)
  Future<List<Vendor>> getNearbyVendors(String location,
      {int limit = 20}) async {
    final vendors = await searchVendors(location: location);
    return vendors.take(limit).toList();
  }

  // Get vendors by multiple categories
  Future<List<Vendor>> getVendorsByCategories(List<String> categories) async {
    final allVendors = await getAllVendors();
    return allVendors.where((vendor) {
      return categories.any((category) => vendor.categories.any(
          (vendorCategory) =>
              vendorCategory.toLowerCase() == category.toLowerCase()));
    }).toList();
  }

  // Approve vendor
  Future<bool> approveVendor(String vendorId) async {
    try {
      final vendor = await getVendorById(vendorId);
      if (vendor == null) return false;

      // Create new vendor with approved status
      final approvedVendor = Vendor(
        id: vendor.id,
        name: vendor.name,
        categories: vendor.categories,
        subcategories: vendor.subcategories,
        venueType: vendor.venueType,
        description: vendor.description,
        location: vendor.location,
        images: vendor.images,
        rating: vendor.rating,
        reviewCount: vendor.reviewCount,
        status: VendorStatus.approved,
        documents: vendor.documents,
        subscriptionTier: vendor.subscriptionTier,
        logistics: vendor.logistics,
        contactInfo: vendor.contactInfo,
        email: vendor.email,
        phone: vendor.phone,
        sampleServiceIds: vendor.sampleServiceIds,
        planningHorizon: vendor.planningHorizon,
        createdAt: vendor.createdAt,
        updatedAt: DateTime.now(),
        pendingBookings: vendor.pendingBookings,
        isActive: vendor.isActive,
        imageUrl: vendor.imageUrl,
        offeredServices: vendor.offeredServices,
        pricing: vendor.pricing,
        availability: vendor.availability,
        portfolio: vendor.portfolio,
        socialMedia: vendor.socialMedia,
        tags: vendor.tags,
        verified: vendor.verified,
        featured: vendor.featured,
      );

      await updateVendor(approvedVendor);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Reject vendor
  Future<bool> rejectVendor(String vendorId, String reason) async {
    try {
      // Simple status update - just return true for now
      return true;
    } catch (e) {
      return false;
    }
  }

  // Suspend vendor
  Future<bool> suspendVendor(String vendorId, String reason) async {
    try {
      // Simple status update - just return true for now
      return true;
    } catch (e) {
      return false;
    }
  }

  // Update vendor rating
  Future<bool> updateVendorRating(String vendorId, double newRating) async {
    try {
      // Simple rating update - just return true for now
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get vendor statistics
  Future<Map<String, dynamic>> getVendorStatistics() async {
    final allVendors = await getAllVendors();
    final activeVendors = allVendors.where((v) => v.isActive).toList();
    final approvedVendors =
        allVendors.where((v) => v.status == VendorStatus.approved).toList();
    final pendingVendors =
        allVendors.where((v) => v.status == VendorStatus.pending).toList();
    final featuredVendors =
        allVendors.where((v) => v.featured == true).toList();
    final verifiedVendors =
        allVendors.where((v) => v.verified == true).toList();

    final totalRating =
        allVendors.fold(0.0, (sum, vendor) => sum + vendor.rating);
    final averageRating =
        allVendors.isNotEmpty ? totalRating / allVendors.length : 0.0;

    return {
      'totalVendors': allVendors.length,
      'activeVendors': activeVendors.length,
      'approvedVendors': approvedVendors.length,
      'pendingVendors': pendingVendors.length,
      'featuredVendors': featuredVendors.length,
      'verifiedVendors': verifiedVendors.length,
      'averageRating': averageRating,
      'approvalRate': allVendors.isNotEmpty
          ? approvedVendors.length / allVendors.length
          : 0.0,
    };
  }

  // Get vendors by creation date range
  Future<List<Vendor>> getVendorsByDateRange(
      DateTime startDate, DateTime endDate) async {
    final allVendors = await getAllVendors();
    return allVendors.where((vendor) {
      return vendor.createdAt.isAfter(startDate) &&
          vendor.createdAt.isBefore(endDate);
    }).toList();
  }

  // Get recently registered vendors
  Future<List<Vendor>> getRecentlyRegisteredVendors({int days = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return getVendorsByDateRange(cutoffDate, DateTime.now());
  }

  // Update vendor subscription
  Future<bool> updateVendorSubscription(
      String vendorId, SubscriptionTier newTier) async {
    try {
      final vendor = await getVendorById(vendorId);
      if (vendor == null) return false;

      final updatedVendor = Vendor(
        id: vendor.id,
        name: vendor.name,
        categories: vendor.categories,
        subcategories: vendor.subcategories,
        venueType: vendor.venueType,
        description: vendor.description,
        location: vendor.location,
        images: vendor.images,
        rating: vendor.rating,
        reviewCount: vendor.reviewCount,
        status: vendor.status,
        documents: vendor.documents,
        subscriptionTier: newTier,
        logistics: vendor.logistics,
        contactInfo: vendor.contactInfo,
        email: vendor.email,
        phone: vendor.phone,
        sampleServiceIds: vendor.sampleServiceIds,
        planningHorizon: vendor.planningHorizon,
        createdAt: vendor.createdAt,
        updatedAt: DateTime.now(),
        pendingBookings: vendor.pendingBookings,
        isActive: vendor.isActive,
        imageUrl: vendor.imageUrl,
        offeredServices: vendor.offeredServices,
        pricing: vendor.pricing,
        availability: vendor.availability,
        portfolio: vendor.portfolio,
        socialMedia: vendor.socialMedia,
        tags: vendor.tags,
        verified: vendor.verified,
        featured: vendor.featured,
      );

      await updateVendor(updatedVendor);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Toggle vendor featured status
  Future<bool> toggleFeaturedStatus(String vendorId) async {
    try {
      final vendor = await getVendorById(vendorId);
      if (vendor == null) return false;

      final updatedVendor = Vendor(
        id: vendor.id,
        name: vendor.name,
        categories: vendor.categories,
        subcategories: vendor.subcategories,
        venueType: vendor.venueType,
        description: vendor.description,
        location: vendor.location,
        images: vendor.images,
        rating: vendor.rating,
        reviewCount: vendor.reviewCount,
        status: vendor.status,
        documents: vendor.documents,
        subscriptionTier: vendor.subscriptionTier,
        logistics: vendor.logistics,
        contactInfo: vendor.contactInfo,
        email: vendor.email,
        phone: vendor.phone,
        sampleServiceIds: vendor.sampleServiceIds,
        planningHorizon: vendor.planningHorizon,
        createdAt: vendor.createdAt,
        updatedAt: DateTime.now(),
        pendingBookings: vendor.pendingBookings,
        isActive: vendor.isActive,
        imageUrl: vendor.imageUrl,
        offeredServices: vendor.offeredServices,
        pricing: vendor.pricing,
        availability: vendor.availability,
        portfolio: vendor.portfolio,
        socialMedia: vendor.socialMedia,
        tags: vendor.tags,
        verified: vendor.verified,
        featured: vendor.featured != null ? !vendor.featured! : true,
      );

      await updateVendor(updatedVendor);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get vendor by email
  Future<Vendor?> getVendorByEmail(String email) async {
    final allVendors = await getAllVendors();
    try {
      return allVendors.firstWhere((vendor) => vendor.email == email);
    } catch (e) {
      return null;
    }
  }

  // Check if vendor exists by email
  Future<bool> vendorExistsByEmail(String email) async {
    return await getVendorByEmail(email) != null;
  }
}
