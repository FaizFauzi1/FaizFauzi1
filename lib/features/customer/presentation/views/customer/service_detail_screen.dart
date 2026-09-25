import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/booking/presentation/views/booking/booking_screen.dart';
import 'package:eventease/features/chat/presentation/views/messages/messages_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:eventease/shared/widgets/read_only_calendar_availability.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';
import 'package:eventease/shared/widgets/app_footer.dart';

class ServiceDetailScreen extends StatefulWidget {
  final VendorService service;
  final Vendor vendor;
  const ServiceDetailScreen({super.key, required this.service, required this.vendor});

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  bool _isFavorite = false;
  bool _isExpanded = false;
  String? _selectedTierId;

  @override
  void initState() {
    super.initState();
    if (widget.service.pricingTiers.isNotEmpty) {
      _selectedTierId = widget.service.pricingTiers.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = ResponsiveUtils.isWide(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: isWide ? _buildDesktopAppBar() : null,
      body: ResponsiveWrapper(
        padding: EdgeInsets.zero,
        child: isWide ? _buildWideLayout() : _buildMobileLayout(),
      ),
      floatingActionButton: isWide ? null : _buildActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  PreferredSizeWidget _buildDesktopAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        widget.service.name,
        style: const TextStyle(color: AppTheme.textPrimaryColor, fontSize: 18, fontWeight: FontWeight.bold),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : AppTheme.textSecondaryColor,
          ),
          onPressed: () {
            setState(() => _isFavorite = !_isFavorite);
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, color: AppTheme.textSecondaryColor),
          onPressed: _shareService,
        ),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildServiceImages(),
              _buildServiceInfo(),
              _buildServiceDescription(),
              _buildEventTypes(),
              _buildLogisticsAndLocation(),
              _buildPricingTiers(),
              _buildPricingTransparency(),
              _buildServiceComponents(),
              _buildServiceOptions(),
              _buildAvailabilityCalendar(),
              _buildAppointmentRentalOptions(),
              _buildVendorInfo(),
              _buildReviews(),
              const SizedBox(height: 100),
              if (kIsWeb) const AppFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWideLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Visuals and Main Content
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceImages(),
                const SizedBox(height: 16),
                _buildServiceDescription(),
                _buildEventTypes(),
                _buildServiceComponents(),
                _buildReviews(),
                const SizedBox(height: 48),
                const AppFooter(),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Column: Booking and Logistics (Sticky-like)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildServiceInfo(),
                const SizedBox(height: 16),
                _buildActionButtonsDesktop(),
                const SizedBox(height: 16),
                _buildPricingTiers(),
                _buildPricingTransparency(),
                _buildLogisticsAndLocation(),
                _buildAvailabilityCalendar(),
                _buildVendorInfo(),
                _buildAppointmentRentalOptions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsDesktop() {
    final isDirectoryMode = !widget.service.allowedActions.contains('book') && 
                            !widget.service.allowedActions.contains('buy') && 
                            !widget.service.allowedActions.contains('rent');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          if (isDirectoryMode) ...[
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.storefront, color: Colors.teal.shade800),
                      const SizedBox(width: 8),
                      Text(
                        'Directory Showcase Only',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This service is listed as a directory portfolio showcase only. Online booking/transactions are disabled. Please contact the vendor directly via chat to inquire.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal.shade900,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _chatWithVendor(),
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text(
                  'Inquire / Chat with Vendor',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: widget.service.active ? _bookService : null,
                icon: const Icon(Icons.book_online),
                label: const Text('Book Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: widget.service.active ? AppTheme.primaryColor : Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _chatWithVendor(),
                icon: const Icon(Icons.chat),
                label: const Text('Chat with Vendor'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: Icon(
            _isFavorite ? Icons.favorite : Icons.favorite_border,
            color: _isFavorite ? Colors.red : AppTheme.textSecondaryColor,
          ),
          onPressed: () {
            setState(() {
              _isFavorite = !_isFavorite;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_isFavorite ? 'Added to favorites' : 'Removed from favorites'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share, color: AppTheme.textSecondaryColor),
          onPressed: _shareService,
        ),
      ],
    );
  }

  Widget _buildServiceImages() {
    return Container(
      height: 300,
      width: double.infinity,
      child: PageView.builder(
        itemCount: widget.service.images.length,
        itemBuilder: (context, index) {
          return Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
            ),
            child: Image.network(
              widget.service.images[index],
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image,
                        size: 64,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.service.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.service.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.service.category.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.service.originalPrice != null && widget.service.originalPrice! > widget.service.price)
                    Text(
                      'RM ${widget.service.originalPrice!.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                  Text(
                    'RM ${widget.service.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  if (widget.service.promoExpiry != null)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Ends: ${DateFormat('dd MMM').format(widget.service.promoExpiry!)}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade900,
                        ),
                      ),
                    ),
                  if (widget.service.hasDynamicPricing)
                    Text(
                      'Starting from',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  
                  // Display Duration if available
                  if (widget.service.options['duration'] != null && widget.service.options['durationUnit'] != null) ...[
                     const SizedBox(height: 4),
                     Row(
                      mainAxisSize: MainAxisSize.min,
                       children: [
                         const Icon(Icons.timer_outlined, size: 14, color: AppTheme.primaryColor),
                         const SizedBox(width: 4),
                         Text(
                           '${widget.service.options['duration']} ${widget.service.options['durationUnit']}',
                           style: const TextStyle(
                             fontSize: 12,
                             fontWeight: FontWeight.bold,
                             color: AppTheme.primaryColor,
                           ),
                         ),
                       ],
                     ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '${widget.vendor.rating}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${widget.vendor.reviewCount} reviews)',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.service.active ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.service.active ? 'Available' : 'Unavailable',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDescription() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                child: Text(_isExpanded ? 'Show Less' : 'Show More'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            widget.service.description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
            maxLines: _isExpanded ? null : 3,
            overflow: _isExpanded ? null : TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }



  Widget _buildEventTypes() {
    if (widget.service.eventTypes.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suitable For',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.service.eventTypes.map((type) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                type,
                style: const TextStyle(
                  color: AppTheme.primaryColor, 
                  fontWeight: FontWeight.w500,
                  fontSize: 12
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceOptions() {
    if (widget.service.options.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...widget.service.options.entries.map((entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCalendar() {
    // Parse availability data from service options
    final availabilityData = widget.service.options['availability'];
    if (availabilityData == null) return const SizedBox.shrink();

    Set<DateTime> availableDates = {};
    Set<DateTime> unavailableDates = {};
    bool useWhitelist = false;

    // Parse availability data
    if (availabilityData is Map) {
      final mode = availabilityData['mode'] as String?;
      useWhitelist = mode == 'whitelist';
      
      final dates = availabilityData['dates'] as List?;
      if (dates != null) {
        for (var dateStr in dates) {
          try {
            final date = DateTime.parse(dateStr as String);
            if (useWhitelist) {
              availableDates.add(date);
            } else {
              unavailableDates.add(date);
            }
          } catch (e) {
            // Skip invalid dates
          }
        }
      }
    }

    // Only show if there are dates configured
    if (availableDates.isEmpty && unavailableDates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: ReadOnlyCalendarAvailability(
        availableDates: availableDates,
        unavailableDates: unavailableDates,
        useWhitelist: useWhitelist,
        title: 'Service Availability',
      ),
    );
  }

  Widget _buildAppointmentRentalOptions() {
    final hasAppointments = widget.service.supportsAppointments == true;
    final hasRentals = widget.service.supportsRentals == true;

    if (!hasAppointments && !hasRentals) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (hasAppointments) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.schedule,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Appointments Available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Book a consultation or appointment for this service',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _bookAppointment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Book Appointment'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (hasRentals) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.inventory,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Equipment Rental Available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Rent equipment or items for your event',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _rentEquipment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('View Rentals'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogisticsAndLocation() {
    final logistics = widget.service.logisticsConfig;
    final timeRule = widget.service.timeRule;
    final hasLogistics = logistics != null;
    final hasTimeRule = timeRule != null;
    final hasAddress = widget.service.venueAddress != null && widget.service.venueAddress!.isNotEmpty;
    final hasCoverage = widget.service.coverageArea != null && widget.service.coverageArea!.isNotEmpty;
    final hasAmenities = widget.service.amenities != null && widget.service.amenities!.isNotEmpty;

    if (!hasLogistics && !hasTimeRule && !hasAddress && !hasCoverage && !hasAmenities) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Specifications & Logistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          
          if (hasAddress) 
            _buildLogisticsItem(Icons.location_on, 'Venue Address', widget.service.venueAddress!),
          
          if (hasCoverage)
            _buildLogisticsItem(Icons.map, 'Coverage Area', widget.service.coverageArea!),

          if (hasLogistics) ...[
            if (logistics.defaultCrewCount > 0)
              _buildLogisticsItem(Icons.groups, 'Crew Members', '${logistics.defaultCrewCount} pax'),
            if (logistics.defaultSetupTime > 0)
              _buildLogisticsItem(Icons.build, 'Setup Time', '${logistics.defaultSetupTime} hours'),
            if (logistics.defaultTeardownTime > 0)
              _buildLogisticsItem(Icons.cleaning_services, 'Teardown Time', '${logistics.defaultTeardownTime} hours'),
            if (logistics.freeRadiusKm > 0)
              _buildLogisticsItem(Icons.local_shipping, 'Free Delivery', 'Within ${logistics.freeRadiusKm} km'),
          ],

          if (hasTimeRule) ...[
            if (timeRule.slotDurationMinutes != null && timeRule.slotDurationMinutes! > 0)
              _buildLogisticsItem(Icons.timer, 'Slot Duration', '${timeRule.slotDurationMinutes} minutes'),
            if (timeRule.minDurationMinutes != null && timeRule.minDurationMinutes! > 0)
              _buildLogisticsItem(Icons.hourglass_bottom, 'Minimum Booking', '${timeRule.minDurationMinutes} minutes'),
          ],

          if (hasAmenities) ...[
            const SizedBox(height: 12),
            const Text(
              'Amenities & Facilities',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.service.amenities!.map((amenity) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blueGrey.shade100),
                ),
                child: Text(
                  amenity,
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade800),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogisticsItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vendor Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Text(
                  widget.vendor.name[0].toUpperCase(),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vendor.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.vendor.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.vendor.rating} (${widget.vendor.reviewCount} reviews)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewVendorProfile(),
                  icon: const Icon(Icons.person, size: 16),
                  label: const Text('View Profile'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _chatWithVendor(),
                  icon: const Icon(Icons.chat, size: 16),
                  label: const Text('Chat'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    // Mock reviews data
    final reviews = [
      {'name': 'John D.', 'rating': 5, 'comment': 'Excellent service! Very professional and timely.'},
      {'name': 'Sarah M.', 'rating': 4, 'comment': 'Great quality, would recommend to others.'},
      {'name': 'Mike R.', 'rating': 5, 'comment': 'Perfect for our event. Highly satisfied!'},
    ];

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Customer Reviews',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _viewAllReviews,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...reviews.take(2).map((review) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      review['name'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: List.generate(5, (index) => Icon(
                        index < (review['rating'] as int) ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 16,
                      )),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  review['comment'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isDirectoryMode = !widget.service.allowedActions.contains('book') && 
                            !widget.service.allowedActions.contains('buy') && 
                            !widget.service.allowedActions.contains('rent');

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (isDirectoryMode) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _chatWithVendor(),
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text('Inquire / Chat with Vendor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _chatWithVendor(),
                icon: const Icon(Icons.chat),
                label: const Text('Chat'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: widget.service.active ? _bookService : null,
                icon: const Icon(Icons.book_online),
                label: const Text('Book Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: widget.service.active ? AppTheme.primaryColor : Colors.grey,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _shareService() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sharing service...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _viewVendorProfile() {
    // Navigate to vendor profile screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening vendor profile...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _chatWithVendor() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagesScreen(),
      ),
    );
  }

  void _bookService() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          vendor: widget.vendor,
          serviceId: widget.service.id,
          eventId: null,
          service: widget.service,
        ),
      ),
    );
  }

  void _viewAllReviews() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Reviews'),
        content: const Text('This would show all reviews for this service.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _bookAppointment() {
    // Navigate to appointment booking screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening appointment booking...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to appointment booking screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => AppointmentBookingScreen(
    //       service: widget.service,
    //       vendor: widget.vendor,
    //     ),
    //   ),
    // );
  }

  void _rentEquipment() {
    // Navigate to rental screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening equipment rental...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Navigate to rental screen
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => RentalScreen(
    //       service: widget.service,
    //       vendor: widget.vendor,
    //     ),
    //   ),
    // );
  }

  Widget _buildPricingTiers() {
    if (widget.service.pricingTiers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Rates / Packages',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 4),
          const Text('Select a package to see what\'s included', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          ...widget.service.pricingTiers.map((tier) {
             final hasPax = tier.minPax > 0 || (tier.maxPax != null && tier.maxPax! > 0);
             final isSelected = _selectedTierId == tier.id;
             return Padding(
               padding: const EdgeInsets.only(bottom: 12),
               child: InkWell(
                 onTap: () => setState(() => _selectedTierId = tier.id),
                 child: Container(
                   padding: const EdgeInsets.all(12),
                   decoration: BoxDecoration(
                     border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3), width: isSelected ? 2 : 1),
                     borderRadius: BorderRadius.circular(8),
                     color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.white,
                     boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                   ),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Expanded(
                             child: Row(
                               children: [
                                 if (isSelected) const Icon(Icons.check_circle, size: 18, color: AppTheme.primaryColor),
                                 if (isSelected) const SizedBox(width: 8),
                                 Text(
                                   tier.name ?? "Package",
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                 ),
                               ],
                             ),
                           ),
                           Column(
                             crossAxisAlignment: CrossAxisAlignment.end,
                             children: [
                               if (tier.originalPrice != null && tier.originalPrice! > tier.price)
                                 Text(
                                   "RM ${tier.originalPrice!.toStringAsFixed(2)}",
                                   style: const TextStyle(
                                     decoration: TextDecoration.lineThrough,
                                     color: Colors.grey,
                                     fontSize: 12,
                                   ),
                                 ),
                               Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                 decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                 child: Text(
                                   "RM ${tier.price.toStringAsFixed(2)}",
                                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                                 ),
                               ),
                               if (tier.promoExpiry != null) ...[
                                 const SizedBox(height: 2),
                                 Builder(
                                   builder: (context) {
                                     final daysLeft = tier.promoExpiry!.difference(DateTime.now()).inDays;
                                     if (daysLeft < 0) return const SizedBox.shrink();
                                     return Text(
                                       daysLeft == 0 ? "Ends Today" : "$daysLeft days left",
                                       style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                                     );
                                   },
                                 ),
                               ],
                             ],
                           ),
                         ],
                       ),
                       if (hasPax) ...[
                         const SizedBox(height: 4),
                         Row(
                           children: [
                             const Icon(Icons.people_outline, size: 14, color: Colors.grey),
                             const SizedBox(width: 4),
                             Text("${tier.minPax} - ${tier.maxPax ?? 'Unlimited'} Pax", style: const TextStyle(fontSize: 13, color: Colors.grey)),
                           ],
                         ),
                       ],
                       if (tier.description != null && tier.description!.isNotEmpty)
                         Padding(
                           padding: const EdgeInsets.only(top: 8),
                           child: Text(tier.description!, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                         ),
                     ],
                   ),
                 ),
               ),
             );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildServiceComponents() {
    if (widget.service.components.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Included Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 4),
          if (_selectedTierId != null)
             Text(
               "Showing items for: ${widget.service.pricingTiers.firstWhere((t) => t.id == _selectedTierId).name ?? 'Selected Package'}",
               style: const TextStyle(fontSize: 12, color: Colors.teal, fontWeight: FontWeight.w500),
             ),
          const SizedBox(height: 12),
          ...widget.service.components.map((comp) {
             // Filter items based on selected tier
             final filteredItems = comp.items.where((item) {
               if (_selectedTierId == null) return true;
               // If item has no tier restrictions, it's universal
               if (item.applicableTierIds.isEmpty) return true;
               // Check if it belongs to selected tier
               return item.applicableTierIds.contains(_selectedTierId);
             }).toList();

             if (filteredItems.isEmpty) return const SizedBox.shrink();

             return Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   comp.name,
                   style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.primaryColor),
                 ),
                 const SizedBox(height: 12),
                 ...filteredItems.map((item) => Padding(
                   padding: const EdgeInsets.only(left: 8, bottom: 16),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Row(
                         children: [
                           const Icon(Icons.check_circle, size: 16, color: Colors.green),
                           const SizedBox(width: 12),
                           Expanded(
                             child: Text(
                               "${item.quantity}x ${item.name}", 
                               style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)
                             ),
                           ),
                           if (item.pdfUrl != null)
                             TextButton.icon(
                               onPressed: () => _openPdf(item.pdfUrl!),
                               icon: const Icon(Icons.picture_as_pdf, size: 16, color: Colors.red),
                               label: const Text("Menu/Docs", style: TextStyle(fontSize: 12, color: Colors.red)),
                             ),
                         ],
                       ),
                       if (item.description != null && item.description!.isNotEmpty)
                         Padding(
                           padding: const EdgeInsets.only(left: 28, top: 4),
                           child: Text(
                             item.description!,
                             style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                           ),
                         ),
                       if (item.galleryUrls.isNotEmpty)
                         Padding(
                           padding: const EdgeInsets.only(left: 28, top: 12),
                           child: SizedBox(
                             height: 100,
                             child: ListView.builder(
                               scrollDirection: Axis.horizontal,
                               itemCount: item.galleryUrls.length,
                               itemBuilder: (context, index) => GestureDetector(
                                 onTap: () => _showFullScreenGallery(item.galleryUrls, index),
                                 child: Container(
                                   margin: const EdgeInsets.only(right: 8),
                                   width: 100,
                                   decoration: BoxDecoration(
                                     borderRadius: BorderRadius.circular(8),
                                     image: DecorationImage(
                                       image: NetworkImage(item.galleryUrls[index]),
                                       fit: BoxFit.cover,
                                     ),
                                   ),
                                 ),
                               ),
                             ),
                           ),
                         ),
                     ],
                   ),
                 )).toList(),
               ],
             );
          }).where((comp) => comp is! SizedBox).toList(),
        ],
      ),
    );
  }

  void _showFullScreenGallery(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Stack(
          children: [
            PageView.builder(
              itemCount: images.length,
              controller: PageController(initialPage: initialIndex),
              itemBuilder: (context, index) => InteractiveViewer(
                child: Image.network(images[index], fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPdf(String url) async {
    // Note: Assuming url_launcher is available
    final uri = Uri.parse(url);
    // await launchUrl(uri);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening PDF: $url')),
    );
  }

  Widget _buildPricingTransparency() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.primaryColor),
              const SizedBox(width: 12),
              const Text(
                'Pricing Transparency',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Details on what is included in the base price.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 20),
          
          _buildTransparencyItem(
            Icons.local_shipping_outlined,
            'Transport / Mileage',
            widget.service.isTransportIncluded,
          ),
          const Divider(height: 24),
          _buildTransparencyItem(
            Icons.hotel_outlined,
            'Accommodation',
            widget.service.isAccommodationIncluded,
          ),
          const Divider(height: 24),
          _buildTransparencyItem(
            Icons.build_circle_outlined,
            'Setup & Teardown',
            widget.service.isSetupIncluded,
          ),
          
          if (widget.service.otherFeesDescription != null && widget.service.otherFeesDescription!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blueGrey.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 20, color: Colors.blueGrey.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Additional Fee Notes',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.service.otherFeesDescription!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransparencyItem(IconData icon, String label, bool isIncluded) {
    return Row(
      children: [
        Icon(icon, size: 24, color: AppTheme.textSecondaryColor),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isIncluded ? Colors.green.shade50 : Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isIncluded ? Icons.check_circle : Icons.cancel,
                size: 14,
                color: isIncluded ? Colors.green.shade700 : Colors.red.shade700,
              ),
              const SizedBox(width: 4),
              Text(
                isIncluded ? 'Included' : 'Not Included',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isIncluded ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


}





