import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/features/customer/data/models/item_listing.dart';
import 'package:eventease/features/customer/presentation/views/customer/listing_detail_screen.dart';

class SellerProfileScreen extends StatefulWidget {
  final String sellerId;
  final String sellerName;
  final String? sellerAvatar;
  final bool isVerified;

  const SellerProfileScreen({
    super.key,
    required this.sellerId,
    this.sellerName = 'Wedding Seller',
    this.sellerAvatar,
    this.isVerified = true,
  });

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  bool _isLoading = true;
  List<ItemListing> _listings = [];
  Map<String, dynamic>? _sellerProfile;

  @override
  void initState() {
    super.initState();
    _loadSellerDataFromSupabase();
  }

  Future<void> _loadSellerDataFromSupabase() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch real listings from Supabase
      if (widget.sellerId.isNotEmpty) {
        final listingsData = await SupabaseService.select(
          table: 'item_listings',
          filters: {'customer_id': widget.sellerId},
          orderBy: 'created_at',
          ascending: false,
        );

        _listings = listingsData.map((d) => ItemListing.fromMap(d)).toList();

        // 2. Fetch seller profile info if available
        final userProfile = await SupabaseService.select(
          table: 'users',
          filters: {'id': widget.sellerId},
        );

        if (userProfile.isNotEmpty) {
          _sellerProfile = userProfile.first;
        }
      }
    } catch (e) {
      debugPrint('Error loading seller profile from Supabase: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _sellerProfile?['full_name'] ?? _sellerProfile?['name'] ?? widget.sellerName;
    final memberSince = _sellerProfile?['created_at'] != null
        ? DateFormat('MMMM yyyy').format(DateTime.parse(_sellerProfile!['created_at']))
        : 'Member';

    final activeListings = _listings.where((l) => l.listingStatus == ItemListingStatus.active).toList();
    final soldListings = _listings.where((l) => l.listingStatus == ItemListingStatus.sold).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Seller Profile',
          style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: _loadSellerDataFromSupabase,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSellerDataFromSupabase,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Seller Header Card
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                            backgroundImage: widget.sellerAvatar != null ? NetworkImage(widget.sellerAvatar!) : null,
                            child: widget.sellerAvatar == null
                                ? Text(
                                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'S',
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                displayName,
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              if (widget.isVerified) ...[
                                const SizedBox(width: 6),
                                const Icon(Icons.verified, color: AppTheme.primaryColor, size: 18),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Member since $memberSince',
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                          ),
                          const SizedBox(height: 16),

                          // Trust Markers Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTrustBadge(Icons.inventory_2_outlined, '${_listings.length} Listings'),
                              _buildTrustBadge(Icons.check_circle_outline, '${soldListings.length} Sold'),
                              _buildTrustBadge(Icons.verified_user_outlined, widget.isVerified ? 'Verified Seller' : 'Standard'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Listings Section
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Active Listings (${activeListings.length})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                              ),
                              if (soldListings.isNotEmpty)
                                Text(
                                  '${soldListings.length} Sold',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          if (_listings.isEmpty)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(32),
                              child: const Column(
                                children: [
                                  Icon(Icons.storefront_outlined, size: 48, color: Colors.grey),
                                  SizedBox(height: 12),
                                  Text('No listings posted by this seller yet.', style: TextStyle(color: AppTheme.textSecondaryColor)),
                                ],
                              ),
                            )
                          else
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 0.75,
                              ),
                              itemCount: _listings.length,
                              itemBuilder: (context, index) {
                                final listing = _listings[index];
                                return _buildListingGridTile(context, listing);
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor),
        ),
      ],
    );
  }

  Widget _buildListingGridTile(BuildContext context, ItemListing listing) {
    final isAvailable = listing.listingStatus == ItemListingStatus.active;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ListingDetailScreen(itemListing: listing)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: listing.images.isNotEmpty
                      ? Image.network(
                          listing.images.first,
                          height: 110,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(height: 110, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                        )
                      : Container(height: 110, color: Colors.grey.shade200, child: const Icon(Icons.image)),
                ),
                if (!isAvailable)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                      child: const Text('SOLD', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.itemName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${listing.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
