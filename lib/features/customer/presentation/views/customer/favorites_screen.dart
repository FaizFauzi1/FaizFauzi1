import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/customer/presentation/views/customer/product_detail_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/vendor_services_screen.dart';
import 'package:eventease/features/customer/data/providers/favorites_provider.dart';
import 'package:eventease/shared/models/other/venue.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/data/vendor_services_data.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:provider/provider.dart';
import 'package:eventease/shared/utils/constants/image_constants.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';
import 'package:eventease/shared/widgets/app_footer.dart';

class CustomerFavoritesScreen extends StatelessWidget {
  const CustomerFavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Favorites',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ResponsiveWrapper(
        padding: EdgeInsets.zero,
        child: Consumer<FavoritesProvider>(
          builder: (context, favoritesProvider, child) {
            final favoriteItems = favoritesProvider.favoriteItems;

            if (favoriteItems.isEmpty) {
              return _buildEmptyState(context);
            }

            // Group favorites by type
            final serviceFavorites = favoritesProvider.getFavoritesByType(FavoriteType.service);
            final vendorFavorites = favoritesProvider.getFavoritesByType(FavoriteType.vendor);
            final venueFavorites = favoritesProvider.getFavoritesByType(FavoriteType.venue);

            return SingleChildScrollView(
              padding: ResponsiveUtils.getScreenPadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (serviceFavorites.isNotEmpty) ...[
                    _buildSectionHeader('Services', serviceFavorites.length),
                    ...serviceFavorites.map((item) => _buildServiceCard(context, item)),
                    const SizedBox(height: 24),
                  ],
                  if (vendorFavorites.isNotEmpty) ...[
                    _buildSectionHeader('Vendors', vendorFavorites.length),
                    ...vendorFavorites.map((item) => _buildVendorCard(context, item)),
                    const SizedBox(height: 24),
                  ],
                  if (venueFavorites.isNotEmpty) ...[
                    _buildSectionHeader('Venues', venueFavorites.length),
                    ...venueFavorites.map((item) => _buildVenueCard(context, item)),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 32),
                  if (kIsWeb) const AppFooter(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start exploring and add items to your favorites!',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to search screen
              Navigator.pushNamed(context, '/search');
            },
            icon: const Icon(Icons.search),
            label: const Text('Explore Services'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(BuildContext context, FavoriteItem favoriteItem) {
    final service = VendorServicesData.getAllServices()
        .cast<VendorService>()
        .firstWhere(
          (s) => s.id == favoriteItem.id,
          orElse: () => VendorService(
            id: favoriteItem.id,
            vendorId: 'unknown',
            name: 'Service Not Found',
            description: 'This service may have been removed.',
            category: EventCategory.catering,
            types: const [ServiceType.service],
            basePrice: 0.0,
            active: false,
            availability: {},
            maxBookingsPerDay: 0,
            advanceBookingDays: 0,
            images: [],
            options: {},
            requirements: {},
            logistics: {},
            status: ServiceStatus.inactive,
            approvalStatus: ApprovalStatus.pending,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            amenities: [],
            cancellationPolicy: '',
            reviews: [],
          ),
        );

    final String imageUrl = service.images.isNotEmpty
        ? service.images.first
        : ImageConstants.getDefaultImageUrl(service.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(vendorService: service),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.business, color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '4.5 (120)', // Placeholder rating
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'RM ${service.basePrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Consumer<FavoritesProvider>(
                builder: (context, favoritesProvider, child) {
                  return IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      favoritesProvider.toggleFavorite(favoriteItem.id, FavoriteType.service);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from favorites')),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorCard(BuildContext context, FavoriteItem favoriteItem) {
    final vendorProvider = context.watch<VendorProvider>();
    final vendor = vendorProvider.vendors.cast<Vendor>().firstWhere(
          (v) => v.id == favoriteItem.id,
          orElse: () => Vendor(
            id: favoriteItem.id,
            name: 'Vendor Not Found',
            categories: [],
            subcategories: [],
            description: 'This vendor may have been removed.',
            location: '',
            images: [],
            rating: 0.0,
            reviewCount: 0,
            status: VendorStatus.approved,
            documents: {},
            subscriptionTier: SubscriptionTier.free,
            logistics: {},
            contactInfo: {},
            sampleServiceIds: [],
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final String imageUrl = (vendor.images != null && vendor.images.isNotEmpty)
        ? vendor.images.first
        : ImageConstants.avatarPlaceholder;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VendorServicesScreen(
                vendorId: vendor.id,
                vendorName: vendor.name ?? 'Vendor',
                vendorCategory: vendor.category ?? 'General',
                vendorDescription: vendor.description,
                vendorImage: vendor.images?.isNotEmpty == true ? vendor.images!.first : null,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.store, color: AppTheme.secondaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.name ?? 'Unknown Vendor',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendor.description ?? 'No description available',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vendor.location ?? 'Location not specified',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${vendor.rating?.toStringAsFixed(1) ?? 'N/A'} (${vendor.reviewCount ?? 0})',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vendor.category ?? 'Service',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Consumer<FavoritesProvider>(
                builder: (context, favoritesProvider, child) {
                  return IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      favoritesProvider.toggleFavorite(favoriteItem.id, FavoriteType.vendor);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from favorites')),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVenueCard(BuildContext context, FavoriteItem favoriteItem) {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final venue = vendorProvider.venues.firstWhere(
          (v) => v.id == favoriteItem.id,
          orElse: () => Venue(
            id: favoriteItem.id,
            vendorId: 'unknown',
            name: 'Venue Not Found',
            description: 'This venue may have been removed.',
            location: '',
            pricePerPerson: 0.0,
            rating: 0.0,
            reviewCount: 0,
            images: [],
            categories: [],
            amenities: [],
            contactInfo: {},
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );

    final String imageUrl = (venue.images != null && venue.images.isNotEmpty)
        ? venue.images.first
        : ImageConstants.defaultVenueImage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // Create a mock VendorService for venue navigation
          final venueService = VendorService(
            id: venue.id,
            vendorId: venue.id,
            name: venue.name ?? 'Venue Service',
            description: venue.description ?? 'No description provided.',
            category: EventCategory.venue,
            types: [ServiceType.rental],
            basePrice: venue.pricePerPerson ?? 0.0,
            active: true,
            availability: {
              'monday': {'start': '00:00', 'end': '23:59', 'available': true},
              'tuesday': {'start': '00:00', 'end': '23:59', 'available': true},
              'wednesday': {'start': '00:00', 'end': '23:59', 'available': true},
              'thursday': {'start': '00:00', 'end': '23:59', 'available': true},
              'friday': {'start': '00:00', 'end': '23:59', 'available': true},
              'saturday': {'start': '00:00', 'end': '23:59', 'available': true},
              'sunday': {'start': '00:00', 'end': '23:59', 'available': true},
            },
            maxBookingsPerDay: 1,
            advanceBookingDays: 180,
            images: venue.images ?? [],
            options: {},
            requirements: {},
            logistics: {},
            status: ServiceStatus.active,
            approvalStatus: ApprovalStatus.approved,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            amenities: venue.amenities ?? ['Spacious Hall', 'Modern Facilities', 'Parking Available'],
            cancellationPolicy: 'Free cancellation up to 60 days before event. 25% fee for cancellations within 60 days. 50% fee within 30 days.',
            reviews: [
              {'rating': 5, 'comment': 'Beautiful venue, perfect for our wedding!', 'user': 'Maria G.', 'date': '2024-01-18'},
              {'rating': 4, 'comment': 'Great location and facilities.', 'user': 'Robert T.', 'date': '2024-01-12'},
              {'rating': 5, 'comment': 'Excellent service and ambiance.', 'user': 'Jennifer M.', 'date': '2024-01-08'},
            ],
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailScreen(vendorService: venueService),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name ?? 'Unknown Venue',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      venue.description ?? 'No description available',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            venue.location ?? 'Location not specified',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${venue.rating?.toStringAsFixed(1) ?? 'N/A'} (${venue.reviewCount ?? 0})',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'RM ${venue.pricePerPerson?.toInt() ?? 0}/person',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Consumer<FavoritesProvider>(
                builder: (context, favoritesProvider, child) {
                  return IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      favoritesProvider.toggleFavorite(favoriteItem.id, FavoriteType.venue);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from favorites')),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
