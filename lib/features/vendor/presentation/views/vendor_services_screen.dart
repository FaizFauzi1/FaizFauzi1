import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/customer/data/providers/favorites_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/booking/presentation/views/booking/booking_screen.dart';
import 'package:eventease/features/chat/presentation/views/messages/messages_screen.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/core/utils/currency_formatter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VendorServicesScreen extends StatefulWidget {
  final Vendor vendor;
  const VendorServicesScreen({super.key, required this.vendor});

  @override
  State<VendorServicesScreen> createState() => _VendorServicesScreenState();
}

class _VendorServicesScreenState extends State<VendorServicesScreen> {
  List<VendorService> _allServices = [];
  List<VendorService> _services = [];
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
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Load services for this specific vendor from the database
      await vendorProvider.loadVendorServices(widget.vendor.id);
      
      final enhancedServices = vendorProvider.getCurrentVendorServicesForId(widget.vendor.id);
      
      // Convert enhanced services back to basic VendorServices for this list view
      // We could also refactor this screen to use enhanced services directly
      final List<VendorService> realServices = [];
      
      for (var enhanced in enhancedServices) {
        // Find if this already exists in samples or just create from enhanced
        realServices.add(VendorService(
          id: enhanced.id,
          vendorId: enhanced.vendorId,
          name: enhanced.name,
          description: enhanced.description,
          category: enhanced.productCategory,
          subcategory: enhanced.subcategory,
          multiLayerPricing: enhanced.multiLayerPricing,
          basePrice: enhanced.price,
          type: enhanced.serviceType,
          images: enhanced.images,
          active: enhanced.isActive,
          status: enhanced.status,
          approvalStatus: enhanced.approvalStatus,
          availability: enhanced.availability,
          options: enhanced.options,
          logistics: enhanced.logistics,
          supportsAppointments: enhanced.supportsAppointments,
          supportsRentals: enhanced.supportsRentals,
          allowedActions: enhanced.allowedActions,
        ));
      }

      setState(() {
        _allServices = realServices;
        _services = _allServices;
        _isLoading = false;
        _applyFilters();
      });
    } catch (e) {
      print('Error fetching services for vendor: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _services = _allServices.where((s) {
        final matchesQuery = _query.isEmpty ||
            s.name.toLowerCase().contains(_query.toLowerCase()) ||
            s.category.displayName.toLowerCase().contains(_query.toLowerCase());
        final matchesActive = !_onlyActive || s.active;
        return matchesQuery && matchesActive;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${widget.vendor.name} Services',
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
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'No services found',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _allServices.isEmpty 
                            ? 'This vendor hasn\'t added any services yet.'
                            : 'Matching services found (${_allServices.length}), but none are currently Live. Your service might be pending admin approval.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppTheme.textSecondaryColor),
                        ),
                        if (_allServices.isNotEmpty && _onlyActive)
                          TextButton(
                            onPressed: () => setState(() { _onlyActive = false; _applyFilters(); }),
                            child: const Text('Show Inactive/Pending Services'),
                          ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _services.length,
                  itemBuilder: (context, index) {
                    final s = _services[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory, color: AppTheme.primaryColor),
                        ),
                        title: Text(s.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(s.category.displayName,
                                style: const TextStyle(
                                    color: AppTheme.textSecondaryColor,
                                    fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  _priceLabel(s),
                                  style: const TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                _buildStatusBadge(s),
                              ],
                            ),
                            if (s.hasDynamicPricing)
                              const Padding(
                                padding: EdgeInsets.only(top: 4.0),
                                child: Text('Seasonal pricing available',
                                    style: TextStyle(
                                        color: AppTheme.textSecondaryColor,
                                        fontSize: 12)),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildStatusBadge(s),
                              ],
                            ),
                          ],
                        ),
                        trailing: Consumer<FavoritesProvider>(
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
                            tooltip: 'Toggle favorite',
                          ),
                        ),
                        onTap: () => _openServiceDetail(s),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }

  String _priceLabel(VendorService s) {
    // Determine price display
    String priceDisplay;
    if (s.hasPackagePricing) {
      // Show price range for package-based pricing
      final minPrice = s.getMinPrice();
      final maxPrice = s.getMaxPrice();
      priceDisplay = '${CurrencyFormatter.symbol} ${minPrice.toStringAsFixed(0)} - ${CurrencyFormatter.symbol} ${maxPrice.toStringAsFixed(0)}';
    } else {
      // Show single price
      priceDisplay = '${CurrencyFormatter.symbol} ${s.basePrice.toStringAsFixed(0)}';
    }
    
    // Add action label based on service type
    switch (s.type) {
      case ServiceType.product:
        return '$priceDisplay • Buy';
      case ServiceType.rental:
        return '$priceDisplay • Rent';
      case ServiceType.service:
      case ServiceType.package:
        return '$priceDisplay • Book';
      default:
        return priceDisplay;
    }
  }

  void _openServiceDetail(VendorService s) {
    // For now reuse BookingScreen as the action entry; in a full app this would
    // branch to product purchase or rental flow.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          vendor: widget.vendor,
          serviceId: s.id,
          eventId: null,
        ),
      ),
    );
  }
  Widget _buildStatusBadge(VendorService s) {
    var attributes = _getStatusAttributes(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: attributes['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: attributes['color'], width: 1),
      ),
      child: Text(
        attributes['label'],
        style: TextStyle(
          color: attributes['color'],
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusAttributes(VendorService s) {
    if (s.status == ServiceStatus.draft) {
      return {'label': 'Draft', 'color': Colors.grey, 'icon': Icons.edit_note};
    }
    if (s.approvalStatus == ApprovalStatus.rejected) {
      return {'label': 'Rejected', 'color': Colors.red, 'icon': Icons.error_outline};
    }
    if (s.approvalStatus == ApprovalStatus.pending) {
      return {'label': 'Reviewing', 'color': Colors.orange, 'icon': Icons.hourglass_empty};
    }
    if (s.status == ServiceStatus.maintenance) {
      return {'label': 'Maintenance', 'color': Colors.amber[700]!, 'icon': Icons.build};
    }
    if (s.active) {
      return {'label': 'Live', 'color': AppTheme.successColor, 'icon': Icons.check_circle};
    } else {
      return {'label': 'Offline', 'color': Colors.grey[600]!, 'icon': Icons.visibility_off};
    }
  }
}


