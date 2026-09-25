import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/customer/presentation/views/customer/service_detail_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/product_detail_screen.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/shared/models/other/venue.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/features/booking/data/models/rental.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:provider/provider.dart';
import 'package:eventease/shared/utils/constants/image_constants.dart';

class CustomerShopScreen extends StatelessWidget {
  const CustomerShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'name': 'Wedding Doorgift', 'price': 5},
      {'name': 'Floral Centerpiece', 'price': 120},
      {'name': 'Stage Backdrop', 'price': 850},
      {'name': 'LED Fairy Lights', 'price': 60},
    ];

    // Get recently added items (combine venues and vendors)
    final vendorProvider = context.watch<VendorProvider>();
    final allVenues = vendorProvider.venues;
    final recentlyAdded = [...allVenues, ...vendorProvider.vendors].take(5).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Shop',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recently Added Section
            if (recentlyAdded.isNotEmpty) _buildRecentlyAddedSection(context, recentlyAdded),

            // Rental Items Section
            _buildRentalItemsSection(context),

            // Shop Items Grid
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Shop Items',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.9),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final item = items[i];
                      return Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2)),
                            ]),
                        child:
                            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.shopping_bag,
                                  color: AppTheme.primaryColor, size: 36)),
                          const SizedBox(height: 10),
                          Text(item['name'].toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor)),
                          const SizedBox(height: 6),
                          Text('RM ${item['price']}',
                              style: const TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          ElevatedButton(
                              onPressed: () {
                                // Get related services from provider
                                final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
                                final allServices = vendorProvider.getCustomServices();
                                final relatedServices = allServices.take(4).toList();

                                // Mock data for shop items
                                final mockAmenities = ['High Quality', 'Professional Craftsmanship', 'Event Ready'];
                                final mockCancellationPolicy = 'Free cancellation up to 24 hours before delivery. 50% refund for cancellations within 24 hours.';
                                final mockReviews = [
                                  {'rating': 5, 'comment': 'Excellent quality and fast delivery!', 'user': 'Sarah M.', 'date': '2024-01-15'},
                                  {'rating': 4, 'comment': 'Good value for money.', 'user': 'John D.', 'date': '2024-01-10'},
                                  {'rating': 5, 'comment': 'Perfect for our wedding!', 'user': 'Lisa K.', 'date': '2024-01-08'},
                                ];

                                // Create a mock VendorService for the shop item
                                final mockVendorService = VendorService(
                                  id: 'shop-item-${item['name']}',
                                  vendorId: 'eventease-store',
                                  name: item['name'].toString(),
                                  description: 'Beautiful ${item['name'].toString().toLowerCase()} perfect for your special event. High quality and professionally crafted.',
                                  category: EventCategory.decoration,
                                  types: [ServiceType.product],
                                  basePrice: item['price'] as double,
                                  active: true,
                                  availability: {
                                    'monday': {'start': '08:00', 'end': '18:00', 'available': true},
                                    'tuesday': {'start': '08:00', 'end': '18:00', 'available': true},
                                    'wednesday': {'start': '08:00', 'end': '18:00', 'available': true},
                                    'thursday': {'start': '08:00', 'end': '18:00', 'available': true},
                                    'friday': {'start': '08:00', 'end': '18:00', 'available': true},
                                    'saturday': {'start': '08:00', 'end': '18:00', 'available': true},
                                    'sunday': {'start': '08:00', 'end': '18:00', 'available': true},
                                  },
                                  maxBookingsPerDay: 10,
                                  advanceBookingDays: 7,
                                  images: [ImageConstants.decorationPlaceholder],
                                  options: {},
                                  requirements: {},
                                  logistics: {},
                                  status: ServiceStatus.active,
                                  approvalStatus: ApprovalStatus.approved,
                                  createdAt: DateTime.now(),
                                  updatedAt: DateTime.now(),
                                  amenities: mockAmenities,
                                  cancellationPolicy: mockCancellationPolicy,
                                  reviews: mockReviews,
                                );

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductDetailScreen(
                                      vendorService: mockVendorService,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white),
                              child: const Text('View Details')),
                        ]),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyAddedSection(BuildContext context, List<dynamic> recentlyAdded) {
    return Container(
      height: 280,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Recently Added',
                  style: TextStyle(
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
                    'NEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    // Navigate to view all recently added
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('View all recently added items')),
                    );
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: recentlyAdded.length,
              itemBuilder: (context, index) {
                final item = recentlyAdded[index];
                return _buildRecentlyAddedCard(context, item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyAddedCard(BuildContext context, dynamic item) {
    String imageUrl;
    String title;
    String subtitle;
    String price;
    String category;

    if (item is Venue) {
      imageUrl = (item.images != null && item.images.isNotEmpty)
          ? item.images.first
          : ImageConstants.defaultVenueImage;
      title = item.name ?? 'Unknown Venue';
      subtitle = item.location ?? 'Location not specified';
      price = 'RM ${item.pricePerPerson?.toStringAsFixed(2) ?? '0.00'}';
      category = 'Venue';
    } else if (item is Vendor) {
      imageUrl = (item.images != null && item.images.isNotEmpty)
          ? item.images.first
          : ImageConstants.avatarPlaceholder;
      title = item.name ?? 'Unknown Vedor';
      subtitle = item.location ?? 'Location not specified';
      price = 'From RM 500.00'; // Placeholder price for vendors
      category = item.category ?? 'Service';
    } else {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Mock data based on item type
        List<String> mockAmenities;
        String mockCancellationPolicy;
        List<Map<String, dynamic>> mockReviews;

        if (item is Venue) {
          mockAmenities = ['Spacious Hall', 'Modern Facilities', 'Parking Available', 'Catering Kitchen', 'Sound System'];
          mockCancellationPolicy = 'Free cancellation up to 60 days before event. 25% fee for cancellations within 60 days. 50% fee within 30 days.';
          mockReviews = [
            {'rating': 5, 'comment': 'Beautiful venue, perfect for our wedding!', 'user': 'Maria G.', 'date': '2024-01-18'},
            {'rating': 4, 'comment': 'Great location and facilities.', 'user': 'Robert T.', 'date': '2024-01-12'},
            {'rating': 5, 'comment': 'Excellent service and ambiance.', 'user': 'Jennifer M.', 'date': '2024-01-08'},
          ];
        } else {
          mockAmenities = ['Professional Service', 'Experienced Team', 'Quality Equipment', 'Flexible Scheduling'];
          mockCancellationPolicy = 'Free cancellation up to 48 hours before service. 25% fee for cancellations within 48 hours.';
          mockReviews = [
            {'rating': 5, 'comment': 'Excellent service and very professional!', 'user': 'Sarah L.', 'date': '2024-01-15'},
            {'rating': 4, 'comment': 'Good quality work and timely delivery.', 'user': 'Mike T.', 'date': '2024-01-10'},
            {'rating': 5, 'comment': 'Highly recommend for events!', 'user': 'Anna R.', 'date': '2024-01-05'},
          ];
        }

        // Create a mock VendorService for the recently added item
        final mockVendorService = VendorService(
          id: item.id,
          vendorId: item.id,
          name: title,
          description: item is Venue ? (item.description ?? 'No description provided.') : (item is Vendor ? item.description ?? 'No description provided.' : 'Service details'),
          category: item is Venue ? EventCategory.venue : EventCategory.catering,
          types: [ServiceType.service],
          basePrice: double.tryParse(price.replaceAll('RM ', '').replaceAll(',', '')) ?? 500.0,
          active: true,
          availability: {
            'monday': {'start': '08:00', 'end': '18:00', 'available': true},
            'tuesday': {'start': '08:00', 'end': '18:00', 'available': true},
            'wednesday': {'start': '08:00', 'end': '18:00', 'available': true},
            'thursday': {'start': '08:00', 'end': '18:00', 'available': true},
            'friday': {'start': '08:00', 'end': '18:00', 'available': true},
            'saturday': {'start': '08:00', 'end': '18:00', 'available': true},
            'sunday': {'start': '08:00', 'end': '18:00', 'available': true},
          },
          maxBookingsPerDay: 10,
          advanceBookingDays: 7,
          images: [imageUrl],
          options: {},
          requirements: {},
          logistics: {},
          status: ServiceStatus.active,
          approvalStatus: ApprovalStatus.approved,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          amenities: mockAmenities,
          cancellationPolicy: mockCancellationPolicy,
          reviews: mockReviews,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              vendorService: mockVendorService,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: Icon(
                    item is Venue ? Icons.location_on : Icons.store,
                    size: 32,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalItemsSection(BuildContext context) {
    // Mock rental items data - in real app, this would come from a provider or API
    final rentalItems = [
      RentalItem(
        id: '1',
        vendorId: 'vendor_123',
        name: 'Elegant Wedding Dress',
        description: 'Beautiful white wedding dress with lace details',
        category: 'Suits & Gowns',
        images: ['https://via.placeholder.com/300x400?text=Wedding+Dress'],
        sizes: {'dress': ['S', 'M', 'L', 'XL']},
        dailyRate: 150.0,
        weeklyRate: 800.0,
        deposit: 300.0,
        status: RentalStatus.available,
        tags: ['wedding', 'elegant', 'lace'],
        specifications: {'color': 'white', 'material': 'lace'},
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      RentalItem(
        id: '2',
        vendorId: 'vendor_123',
        name: 'Crystal Centerpieces',
        description: 'Set of 10 crystal centerpieces for tables',
        category: 'Decorations',
        images: ['https://via.placeholder.com/300x300?text=Centerpieces'],
        sizes: {},
        dailyRate: 50.0,
        weeklyRate: 250.0,
        deposit: 100.0,
        status: RentalStatus.available,
        tags: ['wedding', 'crystal', 'elegant'],
        specifications: {'pieces': 10, 'material': 'crystal'},
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      RentalItem(
        id: '3',
        vendorId: 'vendor_123',
        name: 'Groom\'s Tuxedo',
        description: 'Classic black tuxedo for grooms',
        category: 'Suits & Gowns',
        images: ['https://via.placeholder.com/300x400?text=Tuxedo'],
        sizes: {'suit': ['S', 'M', 'L', 'XL'], 'shoes': ['8', '9', '10', '11']},
        dailyRate: 100.0,
        weeklyRate: 500.0,
        deposit: 200.0,
        status: RentalStatus.available,
        tags: ['wedding', 'tuxedo', 'classic'],
        specifications: {'color': 'black', 'material': 'wool'},
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
    ];

    return Container(
      height: 280,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Text(
                  'Available for Rent',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'RENT',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/rentals');
                  },
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: rentalItems.length,
              itemBuilder: (context, index) {
                final item = rentalItems[index];
                return _buildRentalItemCard(context, item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRentalItemCard(BuildContext context, RentalItem item) {
    return GestureDetector(
      onTap: () {
        // Mock data for rental items
        final mockAmenities = ['Professional Quality', 'Well Maintained', 'Insurance Included', 'Delivery Available'];
        final mockCancellationPolicy = 'Free cancellation up to 48 hours before rental period. 25% fee for cancellations within 48 hours.';
        final mockReviews = [
          {'rating': 5, 'comment': 'Perfect condition and great service!', 'user': 'Mike R.', 'date': '2024-01-12'},
          {'rating': 4, 'comment': 'Good quality rental item.', 'user': 'Anna P.', 'date': '2024-01-05'},
          {'rating': 5, 'comment': 'Highly recommend for events!', 'user': 'David L.', 'date': '2024-01-01'},
        ];

        // Create a mock VendorService for the rental item
        final mockVendorService = VendorService(
          id: item.id,
          vendorId: item.vendorId,
          name: item.name,
          description: item.description,
          category: EventCategory.equipment,
          types: [ServiceType.service],
          basePrice: item.dailyRate,
          active: true,
          availability: {
            'monday': {'start': '08:00', 'end': '18:00', 'available': true},
            'tuesday': {'start': '08:00', 'end': '18:00', 'available': true},
            'wednesday': {'start': '08:00', 'end': '18:00', 'available': true},
            'thursday': {'start': '08:00', 'end': '18:00', 'available': true},
            'friday': {'start': '08:00', 'end': '18:00', 'available': true},
            'saturday': {'start': '08:00', 'end': '18:00', 'available': true},
            'sunday': {'start': '08:00', 'end': '18:00', 'available': true},
          },
          maxBookingsPerDay: 10,
          advanceBookingDays: 7,
          images: item.images.isNotEmpty ? item.images : ['https://via.placeholder.com/300x300?text=Rental+Item'],
          options: {},
          requirements: {},
          logistics: {},
          status: ServiceStatus.active,
          approvalStatus: ApprovalStatus.approved,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          amenities: mockAmenities,
          cancellationPolicy: mockCancellationPolicy,
          reviews: mockReviews,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(
              vendorService: mockVendorService,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                item.images.isNotEmpty ? item.images.first : 'https://via.placeholder.com/300x300?text=Rental+Item',
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: Icon(
                    _getRentalItemIcon(item.category),
                    size: 32,
                    color: AppTheme.secondaryColor,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'RENTAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondaryColor,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'RM ${item.dailyRate.toStringAsFixed(0)}/day',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRentalItemIcon(String category) {
    switch (category) {
      case 'Suits & Gowns':
        return Icons.checkroom;
      case 'Decorations':
        return Icons.celebration;
      case 'Accessories':
        return Icons.watch;
      default:
        return Icons.inventory;
    }
  }
}
