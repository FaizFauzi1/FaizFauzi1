import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eventease/core/services/supabase_service.dart';
import '../../../../shared/models/vendor_collaboration_request_fixed.dart';
import '../../../../shared/models/vendor_partnership.dart';
import '../../../../shared/models/vendor_group.dart';
import '../../../../shared/models/vendor_referral.dart';
import '../../../../shared/models/vendor_marketplace_item.dart';
import '../../data/models/vendor.dart';

class VendorNetworkingProvider extends ChangeNotifier {
  static const _discoveryCacheKey = 'vendor_networking_discovery';

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

  Future<void> loadDiscoveryVendors() async {
    _isLoadingDiscovery = true;
    notifyListeners();

    await _restoreCachedDiscoveryVendors();
    try {
      final data = await SupabaseService.select(
        table: 'vendor_profiles',
        orderBy: 'priority_score',
        ascending: false,
      );

      _allVendors.clear();
      _allVendors.addAll(data.map((json) => Vendor.fromSupabase(json)));
      await _cacheDiscoveryVendors(data);
    } catch (e) {
      debugPrint('Error loading discovery vendors from Supabase: $e');
    } finally {
      _isLoadingDiscovery = false;
      notifyListeners();
    }
  }

  Future<void> _restoreCachedDiscoveryVendors() async {
    if (_allVendors.isNotEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedVendors = prefs.getString(_discoveryCacheKey);
      if (cachedVendors == null) return;

      final rows = jsonDecode(cachedVendors) as List;
      _allVendors.addAll(rows.map((row) => Vendor.fromSupabase(
            Map<String, dynamic>.from(row as Map),
          )));
      notifyListeners();
    } catch (e) {
      debugPrint('Error restoring vendor discovery cache: $e');
    }
  }

  Future<void> _cacheDiscoveryVendors(List<Map<String, dynamic>> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_discoveryCacheKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error caching vendor discovery data: $e');
    }
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
