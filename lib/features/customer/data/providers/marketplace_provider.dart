import 'package:flutter/foundation.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/features/customer/data/models/transfer_listing.dart';
import 'package:eventease/features/customer/data/models/item_listing.dart';

class MarketplaceProvider extends ChangeNotifier {
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
    } catch (e) {
      _errorMessage = e.toString();
      print('Error loading transfer listings: $e');
      // Load fallback/sample data in case of DB connection issues
      _loadSampleTransferListings();
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
    } catch (e) {
      _errorMessage = e.toString();
      print('Error loading item listings: $e');
      _loadSampleItemListings();
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

  void _loadSampleTransferListings() {
    _transferListings = [
      TransferListing(
        id: 'sample-t-1',
        customerId: 'customer_sample',
        vendorId: 'vendor_sample_1',
        bookingId: 'booking_sample_1',
        category: 'Wedding venue',
        vendorName: 'The Grand Ballroom Hotel',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        originalBookingPrice: 15000.0,
        sellingPrice: 11000.0,
        packageDescription: 'Includes grand hall rental for 5 hours, audio-visual system, and basic decoration package.',
        images: ['https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=800&q=80'],
        reason: 'Change of event location to another state.',
        proofUrl: '',
        transferApprovalStatus: TransferApprovalStatus.approved,
        listingStatus: TransferListingStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now(),
      ),
      TransferListing(
        id: 'sample-t-2',
        customerId: 'customer_sample',
        vendorId: null,
        bookingId: null,
        category: 'Catering package',
        vendorName: 'Delicious Feast Catering (External)',
        eventDate: DateTime.now().add(const Duration(days: 45)),
        originalBookingPrice: 6500.0,
        sellingPrice: 5000.0,
        packageDescription: 'Premium buffet catering for 200 guests with Malaysian & Western fusion menu.',
        images: ['https://images.unsplash.com/photo-1555244162-803834f70033?auto=format&fit=crop&w=800&q=80'],
        reason: 'Reduced guest list size.',
        proofUrl: 'https://example.com/receipt.pdf',
        transferApprovalStatus: TransferApprovalStatus.pending,
        listingStatus: TransferListingStatus.active, // Shows as External Vendor
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        updatedAt: DateTime.now(),
      )
    ];
  }

  void _loadSampleItemListings() {
    _itemListings = [
      ItemListing(
        id: 'sample-i-1',
        customerId: 'customer_sample',
        category: 'Bridal wear',
        itemName: 'Vintage Lace Wedding Dress',
        description: 'Stunning vintage A-line wedding gown with full French lace overlay and sweetheart neckline. Worn once, dry cleaned immediately.',
        condition: ItemCondition.likeNew,
        quantity: 1,
        size: 'M / UK 10',
        brand: 'Lillian West',
        price: 1800.0,
        images: ['https://images.unsplash.com/photo-1594552072238-b8a33785b261?auto=format&fit=crop&w=800&q=80'],
        location: 'Kuala Lumpur',
        deliveryOption: 'both',
        listingStatus: ItemListingStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        updatedAt: DateTime.now(),
      ),
      ItemListing(
        id: 'sample-i-2',
        customerId: 'customer_sample',
        category: 'Wedding decorations',
        itemName: 'Fairy Lights Backdrop with Metal Arch',
        description: 'Complete 3m x 3m copper wedding arch with 40m LED warm fairy lights, artificial flower panels, and sheer white drapes.',
        condition: ItemCondition.newCondition,
        quantity: 1,
        size: '3m x 3m',
        brand: 'Handmade / Custom',
        price: 350.0,
        images: ['https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=800&q=80'],
        location: 'Petaling Jaya',
        deliveryOption: 'pickup',
        listingStatus: ItemListingStatus.active,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now(),
      )
    ];
  }
}
