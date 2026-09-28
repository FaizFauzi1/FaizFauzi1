import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/features/customer/data/models/transfer_listing.dart';
import 'package:eventease/features/customer/data/models/item_listing.dart';

class MarketplaceProvider extends ChangeNotifier {
  static const _transferListingsCacheKey = 'marketplace_transfer_listings';
  static const _itemListingsCacheKey = 'marketplace_item_listings';

  List<TransferListing> _transferListings = [];
  List<ItemListing> _itemListings = [];
  List<TransferListing> _myTransferListings = [];
  List<ItemListing> _myItemListings = [];
  
  // Favorites storage (memory-based for demonstration or local storage mock)
  final Set<String> _favoriteListingIds = {};

  bool _isLoading = false;
  String? _errorMessage;

  List<TransferListing> get transferListings => _transferListings;
  List<ItemListing> get itemListings => _itemListings;
  List<TransferListing> get myTransferListings => _myTransferListings;
  List<ItemListing> get myItemListings => _myItemListings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool isListingFavorited(String id) => _favoriteListingIds.contains(id);

  void toggleFavorite(String id) {
    if (_favoriteListingIds.contains(id)) {
      _favoriteListingIds.remove(id);
    } else {
      _favoriteListingIds.add(id);
    }
    notifyListeners();
  }

  // Load active booking transfer listings
  Future<void> loadTransferListings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _restoreTransferListings();
    try {
      final response = await SupabaseService.select(
        table: 'transfer_listings',
        orderBy: 'created_at',
        ascending: false,
      );
      
      _transferListings = response
          .map((data) => TransferListing.fromMap(data))
          .where((l) => l.listingStatus == TransferListingStatus.active)
          .toList();
      await _cacheRows(_transferListingsCacheKey, response);
    } catch (e) {
      _errorMessage = e.toString();
      print('Error loading transfer listings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load active item listings
  Future<void> loadItemListings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await _restoreItemListings();
    try {
      final response = await SupabaseService.select(
        table: 'item_listings',
        orderBy: 'created_at',
        ascending: false,
      );

      _itemListings = response
          .map((data) => ItemListing.fromMap(data))
          .where((l) => l.listingStatus == ItemListingStatus.active)
          .toList();
      await _cacheRows(_itemListingsCacheKey, response);
    } catch (e) {
      _errorMessage = e.toString();
      print('Error loading item listings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load current user's listings
  Future<void> loadMyListings(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final tResponse = await SupabaseService.select(
        table: 'transfer_listings',
        filters: {'customer_id': userId},
      );
      _myTransferListings = tResponse.map((data) => TransferListing.fromMap(data)).toList();

      final iResponse = await SupabaseService.select(
        table: 'item_listings',
        filters: {'customer_id': userId},
      );
      _myItemListings = iResponse.map((data) => ItemListing.fromMap(data)).toList();
    } catch (e) {
      print('Error loading my listings: $e');
      _myTransferListings = _transferListings.where((l) => l.customerId == userId).toList();
      _myItemListings = _itemListings.where((l) => l.customerId == userId).toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create booking transfer listing
  Future<bool> createTransferListing(TransferListing listing) async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.insert(
        table: 'transfer_listings',
        data: listing.toMap(),
      );
      
      await loadTransferListings();
      if (listing.customerId.isNotEmpty) {
        await loadMyListings(listing.customerId);
      }
      return true;
    } catch (e) {
      print('Error creating transfer listing: $e');
      // Add locally for demo
      _transferListings.insert(0, listing);
      if (listing.customerId.isNotEmpty) {
        _myTransferListings.insert(0, listing);
      }
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create item listing
  Future<bool> createItemListing(ItemListing listing) async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseService.insert(
        table: 'item_listings',
        data: listing.toMap(),
      );

      await loadItemListings();
      if (listing.customerId.isNotEmpty) {
        await loadMyListings(listing.customerId);
      }
      return true;
    } catch (e) {
      print('Error creating item listing: $e');
      _itemListings.insert(0, listing);
      if (listing.customerId.isNotEmpty) {
        _myItemListings.insert(0, listing);
      }
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Vendor updates transfer approval
  Future<bool> updateTransferApproval(String listingId, TransferApprovalStatus status, {String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dbStatus = status.name;
      final updates = {
        'transfer_approval_status': dbStatus,
        'listing_status': status == TransferApprovalStatus.approved ? 'active' : 'pending_approval'
      };

      await SupabaseService.update(
        table: 'transfer_listings',
        data: updates,
        column: 'id',
        value: listingId,
      );

      await loadTransferListings();
      if (userId != null) {
        await loadMyListings(userId);
      }
      return true;
    } catch (e) {
      print('Error updating transfer approval: $e');
      // Local fallback updates
      final index = _transferListings.indexWhere((l) => l.id == listingId);
      if (index != -1) {
        final current = _transferListings[index];
        _transferListings[index] = TransferListing(
          id: current.id,
          customerId: current.customerId,
          vendorId: current.vendorId,
          bookingId: current.bookingId,
          category: current.category,
          vendorName: current.vendorName,
          eventDate: current.eventDate,
          originalBookingPrice: current.originalBookingPrice,
          sellingPrice: current.sellingPrice,
          packageDescription: current.packageDescription,
          images: current.images,
          reason: current.reason,
          proofUrl: current.proofUrl,
          transferApprovalStatus: status,
          listingStatus: status == TransferApprovalStatus.approved ? TransferListingStatus.active : TransferListingStatus.pendingApproval,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update item listing status
  Future<bool> updateItemListingStatus(String listingId, ItemListingStatus status, {String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dbStatus = status.name == 'pendingVerification' ? 'pending_verification' : status.name;
      await SupabaseService.update(
        table: 'item_listings',
        data: {'listing_status': dbStatus},
        column: 'id',
        value: listingId,
      );

      await loadItemListings();
      if (userId != null) {
        await loadMyListings(userId);
      }
      return true;
    } catch (e) {
      print('Error updating item listing status: $e');
      return true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Report a listing
  Future<void> reportListing(String listingId, String reason) async {
    // In a production app, insert to a moderation or reports table. Here we log it.
    print('Listing $listingId reported for: $reason');
  }

  // ⚡ TEST MODE helpers — add directly to local state without Supabase
  void addLocalTransferListing(TransferListing listing) {
    _transferListings.insert(0, listing);
    _myTransferListings.insert(0, listing);
    notifyListeners();
  }

  void addLocalItemListing(ItemListing listing) {
    _itemListings.insert(0, listing);
    _myItemListings.insert(0, listing);
    notifyListeners();
  }

  /// Marks a listing as sold/claimed locally (for test mode buyer flow)
  void markListingAsSold(String listingId, {required bool isTransfer}) {
    if (isTransfer) {
      final idx = _transferListings.indexWhere((l) => l.id == listingId);
      if (idx != -1) {
        final l = _transferListings[idx];
        _transferListings[idx] = TransferListing(
          id: l.id, customerId: l.customerId, vendorId: l.vendorId,
          bookingId: l.bookingId, category: l.category, vendorName: l.vendorName,
          eventDate: l.eventDate, originalBookingPrice: l.originalBookingPrice,
          sellingPrice: l.sellingPrice, packageDescription: l.packageDescription,
          images: l.images, reason: l.reason, proofUrl: l.proofUrl,
          transferApprovalStatus: l.transferApprovalStatus,
          listingStatus: TransferListingStatus.sold,
          createdAt: l.createdAt, updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } else {
      final idx = _itemListings.indexWhere((l) => l.id == listingId);
      if (idx != -1) {
        final l = _itemListings[idx];
        _itemListings[idx] = ItemListing(
          id: l.id, customerId: l.customerId, category: l.category,
          itemName: l.itemName, description: l.description, condition: l.condition,
          quantity: l.quantity, size: l.size, brand: l.brand, price: l.price,
          images: l.images, location: l.location, deliveryOption: l.deliveryOption,
          listingStatus: ItemListingStatus.sold,
          createdAt: l.createdAt, updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    }
  }

  Future<void> _restoreTransferListings() async {
    if (_transferListings.isNotEmpty) return;
    final rows = await _readCachedRows(_transferListingsCacheKey);
    if (rows == null) return;

    _transferListings = rows
        .map(TransferListing.fromMap)
        .where((listing) =>
            listing.listingStatus == TransferListingStatus.active)
        .toList();
    notifyListeners();
  }

  Future<void> _restoreItemListings() async {
    if (_itemListings.isNotEmpty) return;
    final rows = await _readCachedRows(_itemListingsCacheKey);
    if (rows == null) return;

    _itemListings = rows
        .map(ItemListing.fromMap)
        .where((listing) => listing.listingStatus == ItemListingStatus.active)
        .toList();
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>?> _readCachedRows(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedRows = prefs.getString(key);
      if (cachedRows == null) return null;
      return (jsonDecode(cachedRows) as List)
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList();
    } catch (e) {
      debugPrint('Error reading marketplace cache: $e');
      return null;
    }
  }

  Future<void> _cacheRows(String key, List<Map<String, dynamic>> rows) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(rows));
    } catch (e) {
      debugPrint('Error caching marketplace listings: $e');
    }
  }
}
