import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/features/customer/data/providers/favorites_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/features/booking/presentation/views/booking/booking_screen.dart';
import 'package:eventease/features/chat/presentation/views/messages/messages_screen.dart';
import 'package:eventease/shared/widgets/service_image_carousel.dart';
import 'package:eventease/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VendorServicesScreenEnhanced extends StatefulWidget {
  const VendorServicesScreenEnhanced({super.key});

  @override
  State<VendorServicesScreenEnhanced> createState() => _VendorServicesScreenEnhancedState();
}

class _VendorServicesScreenEnhancedState extends State<VendorServicesScreenEnhanced> {
  List<VendorServiceEnhanced> _allServices = [];
  List<VendorServiceEnhanced> _services = [];
  String _query = '';
  bool _onlyActive = true;
  bool _isLoading = true;
  final Set<String> _favoriteServiceIds = <String>{};

  @override
  void initState() {
    super.initState();
    _fetchRealServices();
  }

  Future<void> _fetchRealServices() async {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final currentVendor = vendorProvider.currentVendor;
    
    if (currentVendor == null) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await vendorProvider.loadVendorServices(currentVendor.id);
      final realServices = vendorProvider.getServicesForVendor(currentVendor.id);

      setState(() {
        _allServices = realServices;
        _services = realServices;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      print('Error loading enhanced services: $e');
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    setState(() {
      _services = _allServices.where((s) {
        final matchesQuery = _query.isEmpty ||
            s.name.toLowerCase().contains(_query.toLowerCase()) ||
            s.category.displayName.toLowerCase().contains(_query.toLowerCase());
        final matchesActive = !_onlyActive || s.isActive;
        return matchesQuery && matchesActive;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final currentVendor = vendorProvider.currentVendor;

    if (currentVendor == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('My Services'),
        ),
        body: const Center(
          child: Text('No vendor account found. Please log in as a vendor.'),
        ),
      );
    }

    // Data is now loaded in initState via _fetchRealServices()

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${currentVendor.name} Services',
            style: const TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat, color: AppTheme.textPrimaryColor),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MessagesScreen()),
            ),
          )
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search services or products',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (q) {
                    _query = q;
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('Active'),
                selected: _onlyActive,
                onSelected: (s) {
                  _onlyActive = s;
                  _applyFilters();
                },
              ),
            ]),
          ]),
        ),
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _services.isEmpty
              ? const Center(
                  child: Text('No services found',
                      style: TextStyle(color: AppTheme.textSecondaryColor)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final s = _services[index];
                    return _buildServiceCard(s);
                  },
                ),
        ),
      ]),
    );
  }

  Widget _buildServiceCard(VendorServiceEnhanced service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Carousel
          ServiceImageCarousel(
            images: service.images,
            serviceName: service.name,
            height: 200,
          ),

          // Service Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name and favorite
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    Consumer<FavoritesProvider>(
                      builder: (context, favs, _) => IconButton(
                        icon: Icon(
                          favs.isFavorited(service.id)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: Colors.red,
                        ),
                        onPressed: () {
                          favs.toggleFavorite(service.id, FavoriteType.service);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                favs.isFavorited(service.id)
                                    ? 'Added to favorites'
                                    : 'Removed from favorites',
                              ),
                            ),
                          );
                        },
                        tooltip: 'Toggle favorite',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Category and Status
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    child: Text(
                        service.category.displayName,
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: service.isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: service.isActive ? Colors.green : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  service.description,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 16),

                // Service Features
                _buildServiceFeatures(service),

                const SizedBox(height: 16),

                // Package Options
                if (service.options.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Options',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...service.options.entries.map((entry) {
                          // Safely convert value to string, handling empty lists
                          String valueStr;
                          if (entry.value is List) {
                            final list = entry.value as List;
                            valueStr = list.isNotEmpty ? list.join(', ') : 'None';
                          } else {
                            valueStr = entry.value.toString();
                          }
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${entry.key}: ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 12,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    valueStr,
                                    style: const TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Pricing Information
                _buildPricingInfo(service),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openServiceDetail(service),
                        icon: const Icon(Icons.info_outline),
                        label: const Text('View Details'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _bookService(service),
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Book Now'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceFeatures(VendorServiceEnhanced service) {
    final features = <Widget>[];

    // Add availability info
    if (service.maxBookingsPerDay > 0) {
      features.add(
        Row(
          children: [
            const Icon(Icons.schedule, size: 16, color: AppTheme.textSecondaryColor),
            const SizedBox(width: 4),
            Text(
              'Up to ${service.maxBookingsPerDay} bookings/day',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Add advance booking info
    if (service.advanceBookingDays > 0) {
      features.add(
        Row(
          children: [
            const Icon(Icons.calendar_month, size: 16, color: AppTheme.textSecondaryColor),
            const SizedBox(width: 4),
            Text(
              '${service.advanceBookingDays} days advance booking',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Add delivery info
    if (service.hasDelivery) {
      features.add(
        Row(
          children: [
            const Icon(Icons.local_shipping, size: 16, color: AppTheme.textSecondaryColor),
            const SizedBox(width: 4),
            Text(
              'Delivery available',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    // Add setup info
    if (service.hasSetup) {
      features.add(
        Row(
          children: [
            const Icon(Icons.build, size: 16, color: AppTheme.textSecondaryColor),
            const SizedBox(width: 4),
            Text(
              'Setup included',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (features.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Features:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        ...features.map((feature) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: feature,
        )),
      ],
    );
  }

  Widget _buildPricingInfo(VendorServiceEnhanced service) {
    double minPrice = service.getMinPrice();
    double maxPrice = service.getMaxPrice();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  minPrice > 0 
                    ? (service.hasDynamicPricing && minPrice != maxPrice
                        ? '${CurrencyFormatter.symbol} ${minPrice.toStringAsFixed(0)} - ${CurrencyFormatter.symbol} ${maxPrice.toStringAsFixed(0)}'
                        : 'Starting from ${CurrencyFormatter.symbol} ${minPrice.toStringAsFixed(0)}')
                    : 'Contact for Price',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const Spacer(),
              if (service.hasDynamicPricing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Dynamic Pricing',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          if (service.packageOptions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '${service.packageOptions.length} package options available',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _priceLabel(VendorServiceEnhanced s) {
    switch (s.serviceType) {
      case ServiceType.product:
        return '${CurrencyFormatter.symbol} ${s.basePrice.toStringAsFixed(0)} • Buy';
      case ServiceType.rental:
        return '${CurrencyFormatter.symbol} ${s.basePrice.toStringAsFixed(0)} • Rent';
      case ServiceType.service:
      case ServiceType.package:
        return '${CurrencyFormatter.symbol} ${s.basePrice.toStringAsFixed(0)} • Book';
      default:
        return '${CurrencyFormatter.symbol} ${s.basePrice.toStringAsFixed(0)} • Book';
    }
  }

  void _openServiceDetail(VendorServiceEnhanced s) {
    // Show detailed service information
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  Consumer<FavoritesProvider>(
                    builder: (context, favs, _) => IconButton(
                      icon: Icon(
                        favs.isFavorited(s.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () {
                        favs.toggleFavorite(s.id, FavoriteType.service);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              favs.isFavorited(s.id)
                                  ? 'Added to favorites'
                                  : 'Removed from favorites',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Image Carousel
              ServiceImageCarousel(
                images: s.images,
                serviceName: s.name,
                height: 250,
              ),

              const SizedBox(height: 20),

              // Category and Status
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      s.category.displayName,
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: s.isActive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      s.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: s.isActive ? Colors.green : Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                s.description,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 20),

              // Service Features
              _buildServiceFeatures(s),

              const SizedBox(height: 20),

              // Package Options
              if (s.options.isNotEmpty) ...[
                const Text(
                  'Available Options',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...s.options.entries.map((entry) {
                        // Safely convert value to string, handling empty lists
                        String valueStr;
                        if (entry.value is List) {
                          final list = entry.value as List;
                          valueStr = list.isNotEmpty ? list.join(', ') : 'None';
                        } else {
                          valueStr = entry.value.toString();
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${entry.key}: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                  fontSize: 14,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  valueStr,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Pricing Information
              _buildPricingInfo(s),

              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _bookService(s);
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: const Text('Book Now'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _bookService(VendorServiceEnhanced s) {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final currentVendor = vendorProvider.currentVendor;
    if (currentVendor != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BookingScreen(
            vendor: currentVendor,
            serviceId: s.id,
            eventId: null,
          ),
        ),
      );
    }
  }
}
