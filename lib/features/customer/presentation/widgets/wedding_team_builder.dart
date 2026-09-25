import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/booking/data/models/booking.dart';

class EventTeamBuilderWidget extends StatelessWidget {
  const EventTeamBuilderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, BookingProvider, VendorProvider>(
      builder: (context, authProvider, bookingProvider, vendorProvider, _) {
        if (!authProvider.isAuthenticated) {
          return const SizedBox.shrink();
        }

        final categories = [
          {'id': 'Venue', 'icon': Icons.location_city, 'name': 'Venue'},
          {'id': 'Photography', 'icon': Icons.camera_alt, 'name': 'Photographer'},
          {'id': 'Catering', 'icon': Icons.restaurant, 'name': 'Caterer'},
          {'id': 'Decor', 'icon': Icons.celebration, 'name': 'Decorator'},
          {'id': 'Entertainment', 'icon': Icons.music_note, 'name': 'Entertainment'},
          {'id': 'Makeup', 'icon': Icons.face, 'name': 'Makeup'},
        ];

        // Find which categories are booked by the user
        final bookedCategories = <String, Booking>{};
        
        for (final booking in bookingProvider.customerBookings) {
          // Only consider active/confirmed bookings
          if (booking.status == BookingStatus.confirmed || 
              booking.status == BookingStatus.inProgress || 
              booking.status == BookingStatus.awaitingPayment) {
            
            // Find vendor to get category
            final vendor = vendorProvider.vendors.where((v) => v.id == booking.vendorId).firstOrNull;
            if (vendor != null) {
              // Match category (basic string matching)
              final vendorCat = vendor.category.toLowerCase();
              for (final cat in categories) {
                final catId = (cat['id'] as String).toLowerCase();
                if (vendorCat.contains(catId) || vendorCat == catId) {
                  bookedCategories[cat['id'] as String] = booking;
                  break;
                }
              }
            }
          }
        }

        final progress = bookedCategories.length / categories.length;

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'Let\'s build your event team',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${bookedCategories.length}/${categories.length} Hired',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Personalize your vendor categories, track your progress and watch it all come together.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final String catId = cat['id'] as String;
                    final bool isBooked = bookedCategories.containsKey(catId);
                    final IconData icon = cat['icon'] as IconData;
                    
                    return Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isBooked ? AppTheme.primaryColor.withOpacity(0.05) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isBooked ? AppTheme.primaryColor.withOpacity(0.5) : Colors.grey[200]!,
                          width: isBooked ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isBooked ? AppTheme.primaryColor : Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: isBooked ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    )
                                  ] : null,
                                ),
                                child: Icon(
                                  icon,
                                  color: isBooked ? Colors.white : Colors.grey[400],
                                  size: 24,
                                ),
                              ),
                              if (isBooked)
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            cat['name'] as String,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isBooked ? FontWeight.bold : FontWeight.normal,
                              color: isBooked ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
