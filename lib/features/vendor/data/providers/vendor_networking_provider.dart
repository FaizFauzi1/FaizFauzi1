import 'package:flutter/foundation.dart';
import 'package:eventease/core/services/supabase_service.dart';
import '../../../../shared/models/vendor_collaboration_request_fixed.dart';
import '../../../../shared/models/vendor_partnership.dart';
import '../../../../shared/models/vendor_group.dart';
import '../../../../shared/models/vendor_referral.dart';
import '../../../../shared/models/vendor_marketplace_item.dart';
import '../../data/models/vendor.dart';

class VendorNetworkingProvider extends ChangeNotifier {
  // Data storage
  final List<VendorCollaborationRequest> _collaborationRequests = [];
  final List<VendorPartnership> _partnerships = [];
  final List<VendorGroup> _groups = [];
  final List<VendorReferral> _referrals = [];
  final List<VendorMarketplaceItem> _marketplaceItems = [];
  final List<Vendor> _allVendors = []; // For discovery

  // Current vendor context
  String? _currentVendorId;

  // Loading states
  bool _isLoadingRequests = false;
  bool _isLoadingPartnerships = false;
  bool _isLoadingGroups = false;
  bool _isLoadingReferrals = false;
  bool _isLoadingMarketplace = false;
  bool _isLoadingDiscovery = false;

  // Getters
  List<VendorCollaborationRequest> get collaborationRequests => List.unmodifiable(_collaborationRequests);
  List<VendorPartnership> get partnerships => List.unmodifiable(_partnerships);
  List<VendorGroup> get groups => List.unmodifiable(_groups);
  List<VendorReferral> get referrals => List.unmodifiable(_referrals);
  List<VendorMarketplaceItem> get marketplaceItems => List.unmodifiable(_marketplaceItems);
  List<Vendor> get allVendors => List.unmodifiable(_allVendors);

  bool get isLoadingRequests => _isLoadingRequests;
  bool get isLoadingPartnerships => _isLoadingPartnerships;
  bool get isLoadingGroups => _isLoadingGroups;
  bool get isLoadingReferrals => _isLoadingReferrals;
  bool get isLoadingMarketplace => _isLoadingMarketplace;
  bool get isLoadingDiscovery => _isLoadingDiscovery;

  // Filtered getters for current vendor
  List<VendorCollaborationRequest> get sentRequests =>
      _collaborationRequests.where((r) => r.senderVendorId == _currentVendorId).toList();

  List<VendorCollaborationRequest> get receivedRequests =>
      _collaborationRequests.where((r) => r.receiverVendorId == _currentVendorId).toList();

  List<VendorCollaborationRequest> get pendingRequests =>
      receivedRequests.where((r) => r.isPending).toList();

  List<VendorPartnership> get myPartnerships =>
      _partnerships.where((p) => p.vendorIds.contains(_currentVendorId)).toList();

  List<VendorGroup> get myGroups =>
      _groups.where((g) => g.memberIds.contains(_currentVendorId)).toList();

  List<VendorReferral> get sentReferrals =>
      _referrals.where((r) => r.senderVendorId == _currentVendorId).toList();

  List<VendorReferral> get receivedReferrals =>
      _referrals.where((r) => r.receiverVendorId == _currentVendorId).toList();

  List<VendorMarketplaceItem> get myMarketplaceItems =>
      _marketplaceItems.where((item) => item.vendorId == _currentVendorId).toList();

  List<VendorMarketplaceItem> get pendingMarketplaceItems =>
      _marketplaceItems.where((item) => item.status == MarketplaceItemStatus.pending).toList();

  // Statistics
  Map<String, dynamic> get networkingStats {
    if (_currentVendorId == null) return {};

    return {
      'totalRequestsSent': sentRequests.length,
      'totalRequestsReceived': receivedRequests.length,
      'pendingRequests': pendingRequests.length,
      'activePartnerships': myPartnerships.where((p) => p.isActive).length,
      'totalGroups': myGroups.length,
      'totalReferralsSent': sentReferrals.length,
      'totalReferralsReceived': receivedReferrals.length,
      'successfulReferrals': sentReferrals.where((r) => r.isCompleted).length,
      'totalCommissionEarned': sentReferrals
          .where((r) => r.commissionEarned != null)
          .fold(0.0, (sum, r) => sum + r.commissionEarned!),
    };
  }

  // Initialize with current vendor
  void setCurrentVendor(String vendorId) {
    _currentVendorId = vendorId;
    notifyListeners();
  }

  // Loads discovery vendors from Supabase vendor_profiles with sample fallback
  Future<void> loadDiscoveryVendors() async {
    _isLoadingDiscovery = true;
    notifyListeners();

    try {
      final data = await SupabaseService.select(
        table: 'vendor_profiles',
        orderBy: 'priority_score',
        ascending: false,
      );

      _allVendors.clear();
      if (data.isNotEmpty) {
        _allVendors.addAll(data.map((json) => Vendor.fromSupabase(json)).toList());
      }
    } catch (e) {
      debugPrint('Error loading discovery vendors from Supabase: $e');
    }

    if (_allVendors.isEmpty) {
      _allVendors.addAll(_sampleDiscoveryVendors());
    }

    _isLoadingDiscovery = false;
    notifyListeners();
  }

  void loadSampleData() {
    if (_allVendors.isEmpty) {
      _allVendors.addAll(_sampleDiscoveryVendors());
    }
    notifyListeners();
  }

  // Collaboration Request Management
  Future<void> sendCollaborationRequest(VendorCollaborationRequest request) async {
    _isLoadingRequests = true;
    notifyListeners();

    // Simulate async dispatch & persist
    await Future.delayed(const Duration(milliseconds: 400));

    _collaborationRequests.removeWhere((r) => r.id == request.id);
    _collaborationRequests.insert(0, request);
    _isLoadingRequests = false;
    notifyListeners();
  }

  Future<void> respondToCollaborationRequest(String requestId, CollaborationRequestStatus status, {String? responseMessage}) async {
    _isLoadingRequests = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 400));

    final index = _collaborationRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final updatedRequest = _collaborationRequests[index].copyWith(
        status: status,
        responseMessage: responseMessage,
        respondedAt: DateTime.now(),
      );
      _collaborationRequests[index] = updatedRequest;

      // If accepted, also record an active partnership
      if (status == CollaborationRequestStatus.accepted) {
        final existing = _partnerships.any((p) =>
          p.vendorIds.contains(updatedRequest.senderVendorId) &&
          p.vendorIds.contains(updatedRequest.receiverVendorId)
        );
        if (!existing) {
          final partnership = VendorPartnership(
            id: 'part-${DateTime.now().millisecondsSinceEpoch}',
            partnershipName: '${updatedRequest.senderVendorName} & ${updatedRequest.receiverVendorName}',
            vendorIds: [updatedRequest.senderVendorId, updatedRequest.receiverVendorId],
            vendorNames: [updatedRequest.senderVendorName, updatedRequest.receiverVendorName],
            type: updatedRequest.type == CollaborationType.package
                ? PartnershipType.jointPackage
                : updatedRequest.type == CollaborationType.referral
                    ? PartnershipType.referral
                    : PartnershipType.marketingAlliance,
            status: PartnershipStatus.active,
            description: updatedRequest.message.isNotEmpty
                ? updatedRequest.message
                : 'Mutual event collaboration between ${updatedRequest.senderVendorName} and ${updatedRequest.receiverVendorName}.',
            terms: const {},
            revenueShares: const {},
            createdAt: DateTime.now(),
            startedAt: DateTime.now(),
            packageIds: const [],
          );
          _partnerships.insert(0, partnership);
        }
      }
    }

    _isLoadingRequests = false;
    notifyListeners();
  }

  static List<Vendor> _sampleDiscoveryVendors() {
    return [
      Vendor(
        id: 'sample-v-001',
        name: 'Lumière Wedding Photography',
        categories: ['Photography'],
        subcategories: ['Pre-wedding', 'Actual Day', 'Cinematography'],
        description: 'Award-winning wedding photography and documentary cinematic films capturing candid moments and authentic love stories across Malaysia.',
        location: 'Kuala Lumpur',
        images: const ['https://images.unsplash.com/photo-1537633552985-df8429e8048b?w=500'],
        imageUrl: 'https://images.unsplash.com/photo-1537633552985-df8429e8048b?w=500',
        rating: 4.9,
        reviewCount: 38,
        status: VendorStatus.approved,
        documents: const {},
        subscriptionTier: SubscriptionTier.premium,
        logistics: const {},
        contactInfo: const {
          'email': 'hello@lumierephoto.my',
          'phone': '+60123456781',
          'website': 'https://lumierephoto.my',
        },
        email: 'hello@lumierephoto.my',
        phone: '+60123456781',
        sampleServiceIds: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 120)),
        updatedAt: DateTime.now(),
        verified: true,
      ),
      Vendor(
        id: 'sample-v-002',
        name: 'Royal Floral & Bespoke Decor',
        categories: ['Decoration'],
        subcategories: ['Floral Arch', 'Stage Backdrop', 'Table Centerpieces'],
        description: 'Luxury wedding stage styling, romantic floral installations, and bespoke tablescapes curated for unforgettable wedding celebrations.',
        location: 'Petaling Jaya',
        images: const ['https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=500'],
        imageUrl: 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=500',
        rating: 4.8,
        reviewCount: 29,
        status: VendorStatus.approved,
        documents: const {},
        subscriptionTier: SubscriptionTier.premium,
        logistics: const {},
        contactInfo: const {
          'email': 'contact@royalfloral.com',
          'phone': '+60129876543',
        },
        email: 'contact@royalfloral.com',
        phone: '+60129876543',
        sampleServiceIds: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        updatedAt: DateTime.now(),
        verified: true,
      ),
      Vendor(
        id: 'sample-v-003',
        name: 'Grand Royale Ballroom & Event Space',
        categories: ['Venues'],
        subcategories: ['Pillarless Ballroom', 'Garden Terrace'],
        description: 'A contemporary 800-capacity pillarless grand ballroom with state-of-the-art panoramic LED screens and crystal chandeliers.',
        location: 'Subang Jaya',
        images: const ['https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=500'],
        imageUrl: 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=500',
        rating: 4.7,
        reviewCount: 52,
        status: VendorStatus.approved,
        documents: const {},
        subscriptionTier: SubscriptionTier.enterprise,
        logistics: const {},
        contactInfo: const {
          'email': 'events@grandroyale.my',
          'phone': '+60380234567',
        },
        email: 'events@grandroyale.my',
        phone: '+60380234567',
        sampleServiceIds: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        updatedAt: DateTime.now(),
        verified: true,
      ),
      Vendor(
        id: 'sample-v-004',
        name: 'Gourmet Artisan Wedding Catering',
        categories: ['Catering'],
        subcategories: ['Buffet & Dome', 'Live Cooking Stations', 'Halal Fusion'],
        description: 'Certified Halal premium wedding catering offering exquisite fusion menus, dome sets, and interactive dessert bars.',
        location: 'Shah Alam',
        images: const ['https://images.unsplash.com/photo-1555244162-803834f70033?w=500'],
        imageUrl: 'https://images.unsplash.com/photo-1555244162-803834f70033?w=500',
        rating: 4.9,
        reviewCount: 44,
        status: VendorStatus.approved,
        documents: const {},
        subscriptionTier: SubscriptionTier.premium,
        logistics: const {},
        contactInfo: const {
          'email': 'catering@gourmetartisan.my',
          'phone': '+60173459812',
        },
        email: 'catering@gourmetartisan.my',
        phone: '+60173459812',
        sampleServiceIds: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
        updatedAt: DateTime.now(),
        verified: true,
      ),
      Vendor(
        id: 'sample-v-005',
        name: 'SoundWave Live DJ & Event Production',
        categories: ['Music & DJ'],
        subcategories: ['Wedding DJ', 'Live Acoustic Band', 'Concert Audio'],
        description: 'Premier audio-visual production, professional multilingual MCs, and live wedding band performances that elevate the crowd.',
        location: 'Kuala Lumpur',
        images: const ['https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500'],
        imageUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?w=500',
        rating: 4.8,
        reviewCount: 22,
        status: VendorStatus.approved,
        documents: const {},
        subscriptionTier: SubscriptionTier.basic,
        logistics: const {},
        contactInfo: const {
          'email': 'booking@soundwave.my',
          'phone': '+60162345678',
        },
        email: 'booking@soundwave.my',
        phone: '+60162345678',
        sampleServiceIds: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 80)),
        updatedAt: DateTime.now(),
        verified: true,
      ),
      Vendor(
        id: 'sample-v-006',
        name: 'Prestige Bridal Glam & Hair Studio',
        categories: ['Beauty & Spa'],
        subcategories: ['Airbrush Makeup', 'Bridal Hijab Styling', 'Touch-up Crew'],
        description: 'Specializing in flawless dewy bridal glam, airbrush makeup, and hair styling for brides and bridal parties.',
        location: 'Petaling Jaya',
        images: const ['https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=500'],
        imageUrl: 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?w=500',
        rating: 4.9,
        reviewCount: 31,
        status: VendorStatus.approved,
        documents: const {},
        subscriptionTier: SubscriptionTier.premium,
        logistics: const {},
        contactInfo: const {
          'email': 'glam@prestigebridal.my',
          'phone': '+60193456782',
        },
        email: 'glam@prestigebridal.my',
        phone: '+60193456782',
        sampleServiceIds: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        updatedAt: DateTime.now(),
        verified: true,
      ),
      Vendor(
        id: 'sample-v-007',
        name: 'Vintage Luxe Bridal Chauffeur',
        categories: ['Transportation'],
        subcategories: ['Classic Rolls Royce', 'Modern S-Class', 'Bridal Convoy'],
        description: 'Chauffeured luxury and classic vintage car rentals ensuring a grand and memorable arrival for the bride and groom.',
        location: 'Klang',
        images: const ['https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=500'],
        imageUrl: 'https://images.unsplash.com/photo-1549399542-7e3f8b79c341?w=500',
        rating: 4.6,
        reviewCount: 16,
        status: VendorStatus.approved,
        documents: const {},
        subscriptionTier: SubscriptionTier.standard,
        logistics: const {},
        contactInfo: const {
          'email': 'ride@vintageluxe.my',
          'phone': '+60124567890',
        },
        email: 'ride@vintageluxe.my',
        phone: '+60124567890',
        sampleServiceIds: const [],
        createdAt: DateTime.now().subtract(const Duration(days: 70)),
        updatedAt: DateTime.now(),
        verified: true,
      ),
    ];
  }

  // Partnership Management
  Future<void> createPartnership(VendorPartnership partnership) async {
    _isLoadingPartnerships = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _partnerships.add(partnership);
    _isLoadingPartnerships = false;
    notifyListeners();
  }

  Future<void> updatePartnership(String partnershipId, VendorPartnership updatedPartnership) async {
    _isLoadingPartnerships = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _partnerships.indexWhere((p) => p.id == partnershipId);
    if (index != -1) {
      _partnerships[index] = updatedPartnership;
    }

    _isLoadingPartnerships = false;
    notifyListeners();
  }

  // Group Management
  Future<void> createGroup(VendorGroup group) async {
    _isLoadingGroups = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _groups.add(group);
    _isLoadingGroups = false;
    notifyListeners();
  }

  Future<void> joinGroup(String groupId) async {
    if (_currentVendorId == null) return;

    _isLoadingGroups = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = _groups[index];
      if (!group.memberIds.contains(_currentVendorId) && !group.isFull) {
        final updatedMembers = List<String>.from(group.memberIds)..add(_currentVendorId!);
        _groups[index] = group.copyWith(memberIds: updatedMembers);
      }
    }

    _isLoadingGroups = false;
    notifyListeners();
  }

  Future<void> leaveGroup(String groupId) async {
    if (_currentVendorId == null) return;

    _isLoadingGroups = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _groups.indexWhere((g) => g.id == groupId);
    if (index != -1) {
      final group = _groups[index];
      if (group.memberIds.contains(_currentVendorId)) {
        final updatedMembers = List<String>.from(group.memberIds)..remove(_currentVendorId!);
        _groups[index] = group.copyWith(memberIds: updatedMembers);
      }
    }

    _isLoadingGroups = false;
    notifyListeners();
  }

  // Referral Management
  Future<void> sendReferral(VendorReferral referral) async {
    _isLoadingReferrals = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _referrals.add(referral);
    _isLoadingReferrals = false;
    notifyListeners();
  }

  Future<void> updateReferralStatus(String referralId, ReferralStatus status) async {
    _isLoadingReferrals = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _referrals.indexWhere((r) => r.id == referralId);
    if (index != -1) {
      final updatedReferral = _referrals[index].copyWith(
        status: status,
        responseDate: status != ReferralStatus.pending ? DateTime.now() : null,
        completionDate: status == ReferralStatus.completed ? DateTime.now() : null,
      );
      _referrals[index] = updatedReferral;
    }

    _isLoadingReferrals = false;
    notifyListeners();
  }

  Future<void> updateCollaborationRequestStatus(String requestId, CollaborationRequestStatus status) async {
    _isLoadingRequests = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _collaborationRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final updatedRequest = _collaborationRequests[index].copyWith(
        status: status,
        respondedAt: status != CollaborationRequestStatus.pending ? DateTime.now() : null,
      );
      _collaborationRequests[index] = updatedRequest;
    }

    _isLoadingRequests = false;
    notifyListeners();
  }

  // Marketplace Management
  Future<void> createMarketplaceItem(VendorMarketplaceItem item) async {
    _isLoadingMarketplace = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _marketplaceItems.add(item);
    _isLoadingMarketplace = false;
    notifyListeners();
  }

  Future<void> updateMarketplaceItem(String itemId, VendorMarketplaceItem updatedItem) async {
    _isLoadingMarketplace = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _marketplaceItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      _marketplaceItems[index] = updatedItem;
    }

    _isLoadingMarketplace = false;
    notifyListeners();
  }

  Future<void> deleteMarketplaceItem(String itemId) async {
    _isLoadingMarketplace = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    _marketplaceItems.removeWhere((item) => item.id == itemId);
    _isLoadingMarketplace = false;
    notifyListeners();
  }

  Future<void> approveMarketplaceItem(String itemId) async {
    _isLoadingMarketplace = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _marketplaceItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final updatedItem = _marketplaceItems[index].copyWith(
        status: MarketplaceItemStatus.active,
      );
      _marketplaceItems[index] = updatedItem;
    }

    _isLoadingMarketplace = false;
    notifyListeners();
  }

  Future<void> rejectMarketplaceItem(String itemId) async {
    _isLoadingMarketplace = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    final index = _marketplaceItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final updatedItem = _marketplaceItems[index].copyWith(
        status: MarketplaceItemStatus.inactive,
      );
      _marketplaceItems[index] = updatedItem;
    }

    _isLoadingMarketplace = false;
    notifyListeners();
  }

  void incrementItemViewCount(String itemId) {
    final index = _marketplaceItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final updatedItem = _marketplaceItems[index].copyWith(
        viewCount: _marketplaceItems[index].viewCount + 1,
      );
      _marketplaceItems[index] = updatedItem;
      notifyListeners();
    }
  }

  void incrementItemInquiryCount(String itemId) {
    final index = _marketplaceItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      final updatedItem = _marketplaceItems[index].copyWith(
        inquiryCount: _marketplaceItems[index].inquiryCount + 1,
      );
      _marketplaceItems[index] = updatedItem;
      notifyListeners();
    }
  }

  // Discovery methods
  List<Vendor> discoverVendors({
    String? category,
    String? location,
    double? minRating,
    bool? verifiedOnly,
  }) {
    return _allVendors.where((vendor) {
      if (category != null && vendor.category != category) return false;
      if (location != null && !vendor.location.toLowerCase().contains(location.toLowerCase())) return false;
      if (minRating != null && vendor.rating < minRating) return false;
      if (verifiedOnly == true && vendor.verified != true) return false;
      // Don't show current vendor in discovery
      if (_currentVendorId != null && vendor.id == _currentVendorId) return false;
      return true;
    }).toList();
  }

  // Search methods
  List<Vendor> searchVendors(String query) {
    if (query.isEmpty) return _allVendors;

    final lowercaseQuery = query.toLowerCase();
    return _allVendors.where((vendor) {
      return vendor.name.toLowerCase().contains(lowercaseQuery) ||
             vendor.category.toLowerCase().contains(lowercaseQuery) ||
             vendor.description.toLowerCase().contains(lowercaseQuery) ||
             vendor.location.toLowerCase().contains(lowercaseQuery) ||
             (vendor.tags?.any((tag) => tag.toLowerCase().contains(lowercaseQuery)) ?? false);
    }).toList();
  }

  List<VendorMarketplaceItem> searchMarketplaceItems(String query, {
    MarketplaceItemType? type,
    String? category,
    double? maxPrice,
    String? location,
  }) {
    var items = _marketplaceItems.where((item) => item.isActive).toList();

    if (query.isNotEmpty) {
      final lowercaseQuery = query.toLowerCase();
      items = items.where((item) {
        return item.title.toLowerCase().contains(lowercaseQuery) ||
               item.description.toLowerCase().contains(lowercaseQuery) ||
               item.vendorName.toLowerCase().contains(lowercaseQuery) ||
               item.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();
    }

    if (type != null) {
      items = items.where((item) => item.type == type).toList();
    }

    if (category != null) {
      items = items.where((item) => item.tags.contains(category.toLowerCase())).toList();
    }

    if (maxPrice != null) {
      items = items.where((item) => item.currentPrice <= maxPrice).toList();
    }

    if (location != null && location.isNotEmpty) {
      items = items.where((item) =>
        item.location?.toLowerCase().contains(location.toLowerCase()) ?? false
      ).toList();
    }

    return items;
  }

  List<VendorMarketplaceItem> getFeaturedMarketplaceItems() {
    return _marketplaceItems.where((item) => item.featured && item.isActive).toList();
  }

  // Utility methods
  void clearAllData() {
    _collaborationRequests.clear();
    _partnerships.clear();
    _groups.clear();
    _referrals.clear();
    _marketplaceItems.clear();
    _allVendors.clear();
    notifyListeners();
  }

  Future<void> refreshData() async {
    _isLoadingRequests = true;
    _isLoadingPartnerships = true;
    _isLoadingGroups = true;
    _isLoadingReferrals = true;
    _isLoadingMarketplace = true;
    notifyListeners();

    try {
      await loadDiscoveryVendors();
    } catch (e) {
      debugPrint('Networking refresh failed: $e');
    }

    _isLoadingRequests = false;
    _isLoadingPartnerships = false;
    _isLoadingGroups = false;
    _isLoadingReferrals = false;
    _isLoadingMarketplace = false;
    notifyListeners();
  }
}
