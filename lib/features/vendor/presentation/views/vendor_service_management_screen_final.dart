import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/presentation/widgets/vendor_drawer.dart';
import 'package:eventease/features/customer/presentation/views/customer/wedding_package_detail_screen.dart';
import 'package:eventease/features/vendor/presentation/widgets/vendor_drawer.dart';
import '../../data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/data/providers/subscription_provider.dart';

class VendorServiceManagementScreenFinal extends StatefulWidget {
  final Vendor vendor;

  const VendorServiceManagementScreenFinal({super.key, required this.vendor});

  @override
  State<VendorServiceManagementScreenFinal> createState() => _VendorServiceManagementScreenFinalState();
}

class _VendorServiceManagementScreenFinalState extends State<VendorServiceManagementScreenFinal> {
  late List<VendorServiceEnhanced> _services;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _selectedActions = ['book']; // Default selected actions

  final List<String> _categories = [
    'All',
    'Catering',
    'Photography',
    'Venue',
    'Decoration',
    'Entertainment',
    'Transportation',
    'Equipment',
    'Event Planning',
    'Beauty & Wellness',
    'Accommodation'
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
    
    // Explicitly load services from Supabase to ensure fresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      vendorProvider.loadVendorServices(widget.vendor.id).then((_) {
        if (mounted) {
          setState(() {
            _loadServices();
          });
        }
      });
    });
  }

  void _loadServices() {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    _services = vendorProvider.getServicesForVendor(widget.vendor.id);
  }

  List<VendorServiceEnhanced> get _filteredServices {
    return _services.where((service) {
      final matchesSearch = _searchQuery.isEmpty ||
          service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final category = service.category;
      final matchesCategory = _selectedCategory == 'All' ||
          (category.displayName ?? '') == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('${widget.vendor.name} - Service Management',
            style: const TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () => _navigateToServiceCreation(),
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            label: const Text(
              'Add New Service',
              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      drawer: VendorDrawer.build(context),
      body: Column(
        children: [
          // Search and Filter Section
          _buildSearchAndFilterSection(),

          // Summary Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              children: [
                Text(
                  'Total Services: ${_services.length}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const Spacer(),
                Text(
                  'Showing: ${_filteredServices.length}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Services List
          Expanded(
            child: _filteredServices.isEmpty
                ? _buildEmptyState()
                : _buildServicesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search services...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Category Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = selected ? category : 'All';
                      });
                    },
                    backgroundColor: AppTheme.backgroundColor,
                    selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                    checkmarkColor: AppTheme.primaryColor,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredServices.length,
      itemBuilder: (context, index) {
        final service = _filteredServices[index];
        return _buildServiceCard(service);
      },
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
          // Service Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: service.isActive ? AppTheme.successColor.withOpacity(0.1) : AppTheme.warningColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: service.isActive ? AppTheme.successColor : AppTheme.warningColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    service.isActive ? 'Active' : 'Inactive',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Service Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Category and Type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(service.category.icon ?? Icons.category, size: 14, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            service.category.displayName ?? 'Unknown',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
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
                        service.serviceType.toString().split('.').last,
                        style: TextStyle(
                          color: AppTheme.secondaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Allowed Actions
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: service.allowedActions.map((action) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        action.toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Pricing Information
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (service.originalPrice != null && service.originalPrice! > service.basePrice)
                          Text(
                            'RM ${service.originalPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          'RM ${service.basePrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (service.hourlyRate != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '/ RM ${service.hourlyRate!.toStringAsFixed(2)}/hr',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                    if (service.promoExpiry != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PROMO',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '${service.availability.length} time slots',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _editService(service),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _toggleServiceStatus(service),
                        icon: Icon(service.isActive ? Icons.visibility_off : Icons.visibility, size: 18),
                        label: Text(service.isActive ? 'Hide' : 'Show'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: service.isActive ? AppTheme.warningColor : AppTheme.successColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'preview') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => WeddingPackageDetailScreen(
                                service: service.toVendorService(),
                              ),
                            ),
                          );
                        } else if (value == 'duplicate') {
                          _duplicateService(service);
                        } else if (value == 'delete') {
                          _deleteService(service);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'preview',
                          child: Row(
                            children: [
                              Icon(Icons.remove_red_eye_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Preview as Customer'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'duplicate',
                          child: Row(
                            children: [
                              Icon(Icons.copy, size: 20),
                              SizedBox(width: 8),
                              Text('Duplicate'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(Icons.more_vert, size: 20, color: AppTheme.textSecondaryColor),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No services found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first service',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToServiceCreation,
            icon: const Icon(Icons.add),
            label: const Text('Add New Service'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AddServiceDialog(
        vendor: widget.vendor,
        onServiceAdded: (service) {
          // For now, show success message
          // In the updated VendorProvider, this would call addCustomService
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Service added successfully! (Demo - not persisted)'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          // Refresh the list (in real implementation, this would update the provider)
          setState(() {});

          final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
          vendorProvider.addCustomService(service);
        },
      ),
    );
  }

  void _editService(VendorServiceEnhanced service) {
    Navigator.pushNamed(
      context, 
      '/service-creation',
      arguments: {
        'vendorId': widget.vendor.id,
        'existingService': service.toVendorService(),
      },
    ).then((result) {
      if (result == true) {
        _loadServices();
      }
    });
  }

  Future<void> _deleteService(VendorServiceEnhanced service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: Text('Are you sure you want to delete "${service.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      await vendorProvider.removeCustomService(service.id, vendorId: widget.vendor.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service deleted successfully'), backgroundColor: Colors.green),
        );
        _loadServices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting service: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _duplicateService(VendorServiceEnhanced service) async {
    final newService = service.copyWith(
      id: '', // New ID will be generated by Supabase
      name: '${service.name} (Copy)',
      status: ServiceStatus.draft,
      isActive: false,
    );

    try {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      await vendorProvider.addCustomService(newService);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service duplicated as draft'), backgroundColor: Colors.green),
        );
        _loadServices();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error duplicating service: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _toggleServiceStatus(VendorServiceEnhanced service) async {
    try {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      await vendorProvider.toggleCustomServiceStatus(service.id, vendorId: widget.vendor.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              service.isActive ? 'Service deactivated successfully!' : 'Service activated successfully!',
            ),
            backgroundColor: service.isActive ? AppTheme.warningColor : AppTheme.successColor,
          ),
        );
        
        // Refresh the services list
        setState(() {
          _loadServices();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _navigateToServiceCreation() async {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);

    await subscriptionProvider.loadSubscriptionData(widget.vendor.id);
    final maxListings = subscriptionProvider.maxListings;
    final currentListings = vendorProvider.services.length;

    if (maxListings != -1 && currentListings >= maxListings) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Limit Reached'),
            content: Text('Your current plan allows up to $maxListings services. Please upgrade your subscription to add more.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // In a robust implementation, navigate to subscription upgrade screen
                  // Navigator.pushNamed(context, '/vendor-subscription');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Upgrade Plan'),
              ),
            ],
          ),
        );
      }
      return;
    }

    print('DEBUG: Navigating to Service Creation Wizard');
    if (mounted) {
      Navigator.pushNamed(
        context, 
        '/service-creation',
        arguments: {'vendorId': widget.vendor.id},
      ).then((result) {
        if (result == true) {
          _loadServices();
        }
      });
    }
  }
}

