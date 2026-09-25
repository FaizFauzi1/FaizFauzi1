import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/features/vendor/presentation/views/enhanced_service_creation_screen.dart';
import 'package:eventease/features/vendor/presentation/views/service_creation/service_creation_wizard.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/utils/constants/image_constants.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_portfolio_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/vendor_services_screen.dart' as CustomerView;
import 'package:eventease/core/services/pdf_generator_service.dart';
import 'package:eventease/core/utils/currency_formatter.dart';
import '../../data/providers/vendor_provider_updated.dart';
import '../../../../shared/data/vendor_services_data.dart';
import 'vendor_service_availability_screen.dart';

class VendorServiceManagementScreen extends StatefulWidget {
  final Vendor vendor;

  const VendorServiceManagementScreen({super.key, required this.vendor});

  @override
  State<VendorServiceManagementScreen> createState() => _VendorServiceManagementScreenState();
}

class _VendorServiceManagementScreenState extends State<VendorServiceManagementScreen> {
  late List<VendorServiceEnhanced> _services;
  String _searchQuery = '';
  String _selectedCategory = 'All';

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
  }

  void _loadServices() {
    // Get services from the vendor provider
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    _services = vendorProvider.getCurrentVendorServices();
  }

  void _refreshServices() {
    setState(() {
      _loadServices();
    });
  }

  void _generateQuotation(VendorServiceEnhanced service) async {
    print('DEBUG: _generateQuotation called for ${service.name}');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating quotation...')),
    );

    try {
      await PdfGeneratorService().generateAndShareQuotation(service, widget.vendor);
    } catch (e) {
      print('Error generating quotation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating quotation: $e')),
        );
      }
    }
  }

  List<VendorServiceEnhanced> get _filteredServices {
    return _services.where((service) {
      final matchesSearch = _searchQuery.isEmpty ||
          service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = _selectedCategory == 'All' ||
          service.category.displayName == _selectedCategory;

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
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: _refreshServices,
            tooltip: 'Refresh Services',
          ),
          IconButton(
            icon: const Icon(Icons.photo_library, color: AppTheme.primaryColor),
            onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => VendorPortfolioScreen(vendorId: widget.vendor.id)));
            },
            tooltip: 'Manage Portfolio',
          ),
          IconButton(
            icon: const Icon(Icons.visibility, color: AppTheme.primaryColor),
             onPressed: () {
               Navigator.push(context, MaterialPageRoute(builder: (_) => CustomerView.VendorServicesScreen(
                 vendorId: widget.vendor.id,
                 vendorName: widget.vendor.name,
                 vendorCategory: widget.vendor.category,
                 vendorDescription: widget.vendor.description,
                 vendorImage: widget.vendor.images.isNotEmpty ? widget.vendor.images.first : null,
               )));
            },
            tooltip: 'Preview Store',
          ),
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: () => _showAddServiceDialog(),
            tooltip: 'Add New Service',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          _buildSearchAndFilterSection(),

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
              color: service.isActive ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.warningColor.withValues(alpha: 0.1),
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
                  _buildStatusBadge(service),
                ],
              ),
            ),


            
            // Service Image
            if (service.images.isNotEmpty)
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  image: DecorationImage(
                    image: NetworkImage(service.images.first),
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                       // Handled by UI showing grey background if fails
                    },
                  ),
                ),
                child: service.images.length > 1
                    ? Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '+${service.images.length - 1} more',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      )
                    : null,
              ),

            // Service Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Category and Type
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                                Icon(service.category.icon, size: 14, color: AppTheme.primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  service.category.displayName,
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
                          if (service.supportsAppointments == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, size: 12, color: AppTheme.primaryColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Appointments',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (service.supportsRentals == true) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.inventory, size: 12, color: AppTheme.accentColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Rentals',
                                    style: TextStyle(
                                      color: AppTheme.accentColor,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (service.installmentEnabled) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.indigo.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.payment, size: 12, color: Colors.indigo),
                                  SizedBox(width: 4),
                                  Text(
                                    'Installments',
                                    style: TextStyle(
                                      color: Colors.indigo,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (service.subcategory != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            service.subcategory!,
                            style: TextStyle(
                              color: AppTheme.accentColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Pricing Information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.payments, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pricing',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                service.multiLayerPricing.isNotEmpty
                                  ? '${CurrencyFormatter.symbol} ${service.basePrice.toStringAsFixed(0)} - ${CurrencyFormatter.symbol} ${service.multiLayerPricing.values.reduce((a, b) => a > b ? a : b).toStringAsFixed(0)}'
                                  : '${CurrencyFormatter.symbol} ${service.basePrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (service.multiLayerPricing.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Multi-tier',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Logistics Information (Address, Coverage, Event Types)
                  _buildLogisticsInfo(service),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _editService(service),
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Info'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: AppTheme.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                         child: OutlinedButton.icon(
                          onPressed: () => _editAvailability(service),
                          icon: const Icon(Icons.event_available),
                          label: const Text('Availability'),
                           style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.blue.shade700),
                            foregroundColor: Colors.blue.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                       Expanded(
                         child: OutlinedButton.icon(
                          onPressed: () => _generateQuotation(service),
                          icon: const Icon(Icons.description, size: 18),
                          label: const Text('Quote'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.orange.shade700),
                            foregroundColor: Colors.orange.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: OutlinedButton.icon(
                          onPressed: () => _duplicateService(service),
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Duplicate'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: Colors.blueGrey),
                            foregroundColor: Colors.blueGrey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                       ),
                       const SizedBox(width: 8),
                       Expanded(
                         child: OutlinedButton.icon(
                          onPressed: () => _deleteService(service),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.red.shade700),
                            foregroundColor: Colors.red.shade700,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                       ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: _buildActionStatusButton(service),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Moved methods out of nested scope
  Widget _buildStatusBadge(VendorServiceEnhanced service) {
    var attributes = _getStatusAttributes(service);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: attributes['color'],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(attributes['icon'], size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            attributes['label'],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionStatusButton(VendorServiceEnhanced service) {
     bool isActive = service.isActive;
     return ElevatedButton.icon(
        onPressed: () => _toggleServiceStatus(service),
        icon: Icon(isActive ? Icons.visibility_off : Icons.visibility),
        label: Text(isActive ? 'Deactivate' : 'Activate'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: isActive ? AppTheme.warningColor : AppTheme.successColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
  }

  Map<String, dynamic> _getStatusAttributes(VendorServiceEnhanced service) {
    // 1. DRAFT
    if (service.status == ServiceStatus.draft) {
       return {
         'label': 'Draft',
         'color': Colors.grey,
         'icon': Icons.edit_note,
       };
    }
    
    // 2. REJECTED
    if (service.approvalStatus == ApprovalStatus.rejected) {
       return {
         'label': 'Rejected',
         'color': Colors.red,
         'icon': Icons.error_outline,
       };
    }

    // 3. PENDING REVIEW (Reviewing)
    if (service.approvalStatus == ApprovalStatus.pending) {
       return {
         'label': 'Reviewing',
         'color': Colors.orange,
         'icon': Icons.hourglass_empty,
       };
    }

    // 4. MAINTENANCE
    if (service.status == ServiceStatus.maintenance) {
      return {
        'label': 'Maintenance',
        'color': Colors.amber[700]!,
        'icon': Icons.build,
      };
    }
    
    // 5. LIVE / OFFLINE (Controlled by Vendor)
    if (service.isActive) {
      return {
        'label': 'Live',
        'color': AppTheme.successColor,
        'icon': Icons.check_circle,
      };
    } else {
      return {
        'label': 'Offline',
        'color': Colors.grey[600]!,
        'icon': Icons.visibility_off,
      };
    }
  }

  Widget _buildLogisticsInfo(VendorServiceEnhanced service) {
    final isVenue = service.category == EventCategory.venue;
    final address = service.venueAddress;
    final coverage = service.coverageArea;
    final eventTypes = service.options['eventTypes'] as List?;

    bool hasAddress = isVenue && address != null && address.isNotEmpty;
    bool hasCoverage = !isVenue && coverage != null && coverage.isNotEmpty;
    bool hasEventTypes = eventTypes != null && eventTypes.isNotEmpty;

    if (!hasAddress && !hasCoverage && !hasEventTypes) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasAddress) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
            if (hasEventTypes) const SizedBox(height: 8),
          ],
          if (hasCoverage) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.map, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Service Area: $coverage",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
             if (hasEventTypes) const SizedBox(height: 8),
          ],
          if (hasEventTypes) ...[
            const Text(
              "Suitable for:",
              style: TextStyle(
                fontSize: 12, 
                color: AppTheme.textSecondaryColor, 
                fontWeight: FontWeight.w600
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: eventTypes!.map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.teal.withOpacity(0.2)),
                ),
                child: Text(
                  e.toString(),
                  style: TextStyle(fontSize: 11, color: Colors.teal[800]),
                ),
              )).toList(),
            ),
          ],
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
            onPressed: _showAddServiceDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Service'),
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceCreationWizard(
          vendorId: widget.vendor.id,
        ),
      ),
    ).then((_) {
      _refreshServices();
    });
  }

  void _editService(VendorServiceEnhanced service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedServiceCreationScreen(
          vendorId: widget.vendor.id,
          existingService: service,
        ),
      ),
    ).then((_) {
      _refreshServices();
    });
  }

  void _editAvailability(VendorServiceEnhanced service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorServiceAvailabilityScreen(
          service: service,
        ),
      ),
    ).then((_) {
      _refreshServices();
    });
  }

  void _toggleServiceStatus(VendorServiceEnhanced service) async {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    
    // Optimistic update
    setState(() {
      final index = _services.indexWhere((s) => s.id == service.id);
      if (index != -1) {
        _services[index] = service.copyWith(isActive: !service.isActive);
      }
    });

    try {
      // Use the dedicated toggle method for better performance and reliability
      await vendorProvider.toggleCustomServiceStatus(service.id, vendorId: widget.vendor.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              !service.isActive ? 'Service activated successfully' : 'Service deactivated successfully',
            ),
            backgroundColor: !service.isActive ? AppTheme.successColor : AppTheme.warningColor,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert on error
      setState(() {
        final index = _services.indexWhere((s) => s.id == service.id);
        if (index != -1) {
          _services[index] = service; // Revert to original
        }
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update service status: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _duplicateService(VendorServiceEnhanced service) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Service?'),
        content: Text('This will create a new draft copy of "${service.name}". All details, pricing, and components will be copied.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Duplicate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      );

      try {
        final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
        await vendorProvider.duplicateService(service.id);
        
        if (!mounted) return;
        Navigator.pop(context); // Close loading indicator
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully duplicated "${service.name}"'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        
        _refreshServices();
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading indicator
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error duplicating service: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _deleteService(VendorServiceEnhanced service) async {
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      await vendorProvider.removeCustomService(service.id, vendorId: widget.vendor.id);
      
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service deleted successfully'), backgroundColor: AppTheme.successColor),
        );
        _refreshServices();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting service: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }
}

class AddServiceDialog extends StatefulWidget {
  final Vendor vendor;

  const AddServiceDialog({super.key, required this.vendor});

  @override
  State<AddServiceDialog> createState() => _AddServiceDialogState();
}

class _AddServiceDialogState extends State<AddServiceDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _description = '';
  EventCategory _category = EventCategory.catering;
  String? _subcategory;
  ServiceType _type = ServiceType.service;
  double _basePrice = 0.0;
  double? _hourlyRate;
  double? _dailyRate;
  bool _active = true;
  List<String> _imageUrls = [];
  bool _isUploading = false;
  bool _supportsAppointments = false;
  bool _supportsRentals = false;
  
  // Package-based pricing
  bool _hasPackagePricing = false;
  Map<int, double> _paxPricing = {};
  final List<int> _commonPaxOptions = [50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 600, 700, 800];
  final TextEditingController _paxController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  int? _selectedPax;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Service',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable content area with flexible height
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Service Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                        onSaved: (value) => _name = value!,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                        onSaved: (value) => _description = value!,
                      ),

                      const SizedBox(height: 16),

                      // Image Upload Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.image, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Service Images',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Add up to 5 images to showcase your service',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Image Preview Grid
                            if (_imageUrls.isNotEmpty) ...[
                              Container(
                                height: 100,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _imageUrls.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        image: DecorationImage(
                                          image: NetworkImage(_imageUrls[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      child: Stack(
                                        children: [
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () => _removeImage(index),
                                              child: Container(
                                                padding: const EdgeInsets.all(4),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.withOpacity(0.8),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.close,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Upload Button
                            if (_imageUrls.length < 5) ...[
                              ElevatedButton.icon(
                                onPressed: _isUploading ? null : _pickImages,
                                icon: _isUploading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.add_photo_alternate),
                                label: Text(_isUploading ? 'Uploading...' : 'Add Images'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Maximum 5 images allowed',
                                      style: TextStyle(color: Colors.orange[700]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<EventCategory>(
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        value: _category,
                        items: EventCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(category.icon, size: 18),
                                const SizedBox(width: 8),
                                Text(category.displayName),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _category = value!;
                            _subcategory = null; // Reset subcategory when category changes
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Subcategory dropdown removed as it is now handled dynamically
                      const SizedBox(height: 16),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<ServiceType>(
                        decoration: const InputDecoration(
                          labelText: 'Service Type',
                          border: OutlineInputBorder(),
                        ),
                        value: _type,
                        items: ServiceType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toString().split('.').last),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _type = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Service Options Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.settings, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  'Service Options',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Enable additional features for your service',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Appointments Option
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _supportsAppointments ? AppTheme.primaryColor.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _supportsAppointments ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _supportsAppointments,
                                    onChanged: (value) {
                                      setState(() {
                                        _supportsAppointments = value ?? false;
                                      });
                                    },
                                    activeColor: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Supports Appointments',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                        Text(
                                          'Allow customers to book appointments for this service',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.schedule,
                                    color: _supportsAppointments ? AppTheme.primaryColor : Colors.grey,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Rentals Option
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _supportsRentals ? AppTheme.secondaryColor.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _supportsRentals ? AppTheme.secondaryColor : Colors.grey.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _supportsRentals,
                                    onChanged: (value) {
                                      setState(() {
                                        _supportsRentals = value ?? false;
                                      });
                                    },
                                    activeColor: AppTheme.secondaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Supports Rentals',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textPrimaryColor,
                                          ),
                                        ),
                                        Text(
                                          'Allow customers to rent items/equipment for this service',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.textSecondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.inventory,
                                    color: _supportsRentals ? AppTheme.secondaryColor : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Package Pricing Section
                      _buildPackagePricingSection(),

                      const SizedBox(height: 16),

                      // Base Price (only if not using package pricing)
                      if (!_hasPackagePricing)
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Base Price (${CurrencyFormatter.symbol})',
                            border: const OutlineInputBorder(),
                            prefixText: '${CurrencyFormatter.symbol} ',
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (!_hasPackagePricing && (value?.isEmpty ?? true)) {
                              return 'Please enter a base price or enable package pricing';
                            }
                            if (!_hasPackagePricing) {
                              final price = double.tryParse(value!);
                              if (price == null || price < 0) {
                                return 'Please enter a valid price';
                              }
                            }
                            return null;
                          },
                          onSaved: (value) => _basePrice = value?.isEmpty ?? true ? 0 : double.parse(value!),
                        ),

                      if (!_hasPackagePricing)
                        const SizedBox(height: 16),

                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Hourly Rate (${CurrencyFormatter.symbol}) - Optional',
                          border: const OutlineInputBorder(),
                          prefixText: '${CurrencyFormatter.symbol} ',
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => _hourlyRate = value?.isEmpty ?? true ? null : double.parse(value!),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Daily Rate (${CurrencyFormatter.symbol}) - Optional',
                          border: const OutlineInputBorder(),
                          prefixText: '${CurrencyFormatter.symbol} ',
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => _dailyRate = value?.isEmpty ?? true ? null : double.parse(value!),
                      ),

                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Active'),
                        value: _active,
                        onChanged: (value) {
                          setState(() {
                            _active = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Fixed bottom buttons
              Container(
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: AppTheme.textSecondaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveService,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Add Service'),
                      ),
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

  Widget _buildPackagePricingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              const Text(
                'Package Pricing (Pax-based)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              Switch(
                value: _hasPackagePricing,
                onChanged: (value) {
                  setState(() {
                    _hasPackagePricing = value;
                    if (!value) _paxPricing.clear();
                  });
                },
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
          if (_hasPackagePricing) ...[
            const SizedBox(height: 12),
            Text(
              'Set prices for different guest counts (like KT Sakura packages)',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'Pax',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedPax,
                    items: _commonPaxOptions
                        .where((pax) => !_paxPricing.containsKey(pax))
                        .map((pax) => DropdownMenuItem(value: pax, child: Text('$pax pax')))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPax = value;
                        if (value != null) _paxController.text = value.toString();
                      });
                    },
                    hint: const Text('Select pax'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price (${CurrencyFormatter.symbol})',
                      border: const OutlineInputBorder(),
                      prefixText: '${CurrencyFormatter.symbol} ',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final pax = int.tryParse(_paxController.text);
                    final price = double.tryParse(_priceController.text);
                    if (pax != null && price != null && pax > 0 && price > 0) {
                      setState(() {
                        _paxPricing[pax] = price;
                        _paxController.clear();
                        _priceController.clear();
                        _selectedPax = null;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
            if (_paxPricing.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('Pricing Tiers:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _paxPricing.entries.map((entry) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${entry.key} pax: ${CurrencyFormatter.symbol}${entry.value.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => setState(() => _paxPricing.remove(entry.key)),
                          child: const Icon(Icons.close, size: 16, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _saveService() {
    if (_hasPackagePricing && _paxPricing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one pax pricing tier or disable package pricing'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      try {
        // Convert pax pricing to string keys for multiLayerPricing
        Map<String, double> multiLayerPricing = {};
        if (_hasPackagePricing) {
          _paxPricing.forEach((pax, price) {
            multiLayerPricing['${pax}pax'] = price;
          });
        }

        // Create new service object
        final newService = VendorServiceEnhanced(
          id: 'service_${DateTime.now().millisecondsSinceEpoch}',
          name: _name,
          productCategory: _category,
          serviceTypes: [_type],
          description: _description,
          subcategory: _subcategory,
          price: _basePrice,
          hourlyRate: _hourlyRate,
          dailyRate: _dailyRate,
          isActive: _active,
          images: _imageUrls,
          supportsAppointments: _supportsAppointments,
          supportsRentals: _supportsRentals,
          multiLayerPricing: multiLayerPricing,
          vendorId: widget.vendor.id,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Get vendor provider and add the service
        final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
        vendorProvider.addCustomService(newService);

        String message = 'Service "$_name" added successfully!';
        if (_hasPackagePricing) {
          message += ' with ${_paxPricing.length} pax pricing tiers';
        }
        if (_supportsAppointments) {
          message += ' (Appointments enabled)';
        }
        if (_supportsRentals) {
          message += ' (Rentals enabled)';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 3),
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add service: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
  
  @override
  void dispose() {
    _paxController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        // In a real app, you would upload these images to a server
        // For now, we'll use placeholder URLs
        List<String> newUrls = [];
        for (var image in images) {
          if (_imageUrls.length < 5) {
            // Simulate upload delay
            await Future.delayed(const Duration(milliseconds: 500));
            // In real implementation, upload to Firebase Storage or similar
            newUrls.add(ImageConstants.getDefaultImageUrl(_category));
          }
        }

        setState(() {
          _imageUrls.addAll(newUrls);
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newUrls.length} image(s) added successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}

class EditServiceDialog extends StatefulWidget {
  final VendorServiceEnhanced service;

  const EditServiceDialog({super.key, required this.service});

  @override
  State<EditServiceDialog> createState() => _EditServiceDialogState();
}

class _EditServiceDialogState extends State<EditServiceDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _basePriceController;
  late TextEditingController _hourlyRateController;
  late TextEditingController _dailyRateController;
  late EventCategory _category;
  late String? _subcategory;
  late ServiceType _type;
  late bool _active;
  List<String> _imageUrls = [];
  bool _isUploading = false;
  late bool _supportsAppointments;
  late bool _supportsRentals;
  
  // Package-based pricing
  bool _hasPackagePricing = false;
  Map<int, double> _paxPricing = {};
  final List<int> _commonPaxOptions = [50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 600, 700, 800];
  final TextEditingController _paxController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  int? _selectedPax;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.service.name);
    _descriptionController = TextEditingController(text: widget.service.description);
    _basePriceController = TextEditingController(text: widget.service.basePrice.toString());
    _hourlyRateController = TextEditingController(text: widget.service.hourlyRate?.toString() ?? '');
    _dailyRateController = TextEditingController(text: widget.service.dailyRate?.toString() ?? '');
    _category = widget.service.category;
    _type = widget.service.serviceType;
    _active = widget.service.isActive;
    _imageUrls = List.from(widget.service.images);
    _supportsAppointments = widget.service.supportsAppointments;
    _supportsRentals = widget.service.supportsRentals;
    
    // Load package pricing if available
    if (widget.service.multiLayerPricing.isNotEmpty) {
      _hasPackagePricing = true;
      // Assuming multiLayerPricing can be mapped to pax pricing; adjust as needed
      _paxPricing = {}; // Placeholder; implement mapping if necessary
    }

    // Ensure subcategory is valid for the current category
    _subcategory = _validateSubcategory(widget.service.subcategory, _category);
  }

  String? _validateSubcategory(String? subcategory, EventCategory category) {
    if (subcategory == null || subcategory.isEmpty) {
      return null;
    }
    // Check if the subcategory exists in the category's subcategories
    if (category.subcategories.contains(subcategory)) {
      return subcategory;
    }
    // If not found, return null to avoid dropdown assertion error
    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _paxController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit ${widget.service.name}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            // Scrollable content area with flexible height
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Service Name',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),

                    // Image Upload Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.image, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Service Images',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Add up to 5 images to showcase your service',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Image Preview Grid
                          if (_imageUrls.isNotEmpty) ...[
                            Container(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _imageUrls.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(_imageUrls[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    child: Stack(
                                      children: [
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _removeImage(index),
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.8),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close,
                                                size: 12,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Upload Button
                          if (_imageUrls.length < 5) ...[
                            ElevatedButton.icon(
                              onPressed: _isUploading ? null : _pickImages,
                              icon: _isUploading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add_photo_alternate),
                              label: Text(_isUploading ? 'Uploading...' : 'Add Images'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Maximum 5 images allowed',
                                    style: TextStyle(color: Colors.orange[700]),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<EventCategory>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: _category,
                      items: EventCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Icon(category.icon, size: 18),
                              const SizedBox(width: 8),
                              Text(category.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _category = value!;
                          _subcategory = null; // Reset subcategory when category changes
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    if (_category != null && _category!.subcategories.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Subcategory',
                          border: OutlineInputBorder(),
                        ),
                        value: _subcategory,
                        items: _category!.subcategories.map((subcategory) {
                          return DropdownMenuItem(
                            value: subcategory,
                            child: Text(subcategory),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _subcategory = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    DropdownButtonFormField<ServiceType>(
                      decoration: const InputDecoration(
                        labelText: 'Service Type',
                        border: OutlineInputBorder(),
                      ),
                      value: _type,
                      items: ServiceType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.toString().split('.').last),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _type = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // Service Options Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.settings, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Service Options',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enable additional features for your service',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Appointments Option
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _supportsAppointments ? AppTheme.primaryColor.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _supportsAppointments ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _supportsAppointments,
                                  onChanged: (value) {
                                    setState(() {
                                      _supportsAppointments = value ?? false;
                                    });
                                  },
                                  activeColor: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Supports Appointments',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        'Allow customers to book appointments for this service',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.schedule,
                                  color: _supportsAppointments ? AppTheme.primaryColor : Colors.grey,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Rentals Option
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _supportsRentals ? AppTheme.secondaryColor.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _supportsRentals ? AppTheme.secondaryColor : Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _supportsRentals,
                                  onChanged: (value) {
                                    setState(() {
                                      _supportsRentals = value ?? false;
                                    });
                                  },
                                  activeColor: AppTheme.secondaryColor,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Supports Rentals',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                      Text(
                                        'Allow customers to rent items/equipment for this service',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.inventory,
                                  color: _supportsRentals ? AppTheme.secondaryColor : Colors.grey,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Package Pricing Section for Edit
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              const Text(
                                'Package Pricing (Pax-based)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const Spacer(),
                              Switch(
                                value: _hasPackagePricing,
                                onChanged: (value) {
                                  setState(() {
                                    _hasPackagePricing = value;
                                    if (!value) {
                                      _paxPricing.clear();
                                    }
                                  });
                                },
                                activeColor: AppTheme.primaryColor,
                              ),
                            ],
                          ),
                          if (_hasPackagePricing) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Set different prices for different guest counts',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    decoration: const InputDecoration(
                                      labelText: 'Pax',
                                      border: OutlineInputBorder(),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    value: _selectedPax,
                                    items: _commonPaxOptions
                                        .where((pax) => !_paxPricing.containsKey(pax))
                                        .map((pax) => DropdownMenuItem(
                                              value: pax,
                                              child: Text('$pax pax'),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedPax = value;
                                        if (value != null) {
                                          _paxController.text = value.toString();
                                        }
                                      });
                                    },
                                    hint: const Text('Select pax'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _priceController,
                                    decoration: InputDecoration(
                                      labelText: 'Price',
                                      border: const OutlineInputBorder(),
                                      prefixText: '${CurrencyFormatter.symbol} ',
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    final pax = int.tryParse(_paxController.text);
                                    final price = double.tryParse(_priceController.text);
                                    if (pax != null && price != null && pax > 0 && price > 0) {
                                      setState(() {
                                        _paxPricing[pax] = price;
                                        _paxController.clear();
                                        _priceController.clear();
                                        _selectedPax = null;
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  child: const Icon(Icons.add, color: Colors.white),
                                ),
                              ],
                            ),
                            if (_paxPricing.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Text(
                                'Pricing Tiers:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _paxPricing.entries.map((entry) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${entry.key} pax: ${CurrencyFormatter.symbol}${entry.value.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _paxPricing.remove(entry.key);
                                            });
                                          },
                                          child: const Icon(
                                            Icons.close,
                                            size: 16,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (!_hasPackagePricing)
                      TextField(
                        controller: _basePriceController,
                        decoration: InputDecoration(
                          labelText: 'Base Price (${CurrencyFormatter.symbol})',
                          border: const OutlineInputBorder(),
                          prefixText: '${CurrencyFormatter.symbol} ',
                        ),
                        keyboardType: TextInputType.number,
                      ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _hourlyRateController,
                      decoration: InputDecoration(
                        labelText: 'Hourly Rate (${CurrencyFormatter.symbol}) - Optional',
                        border: const OutlineInputBorder(),
                        prefixText: '${CurrencyFormatter.symbol} ',
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _dailyRateController,
                      decoration: InputDecoration(
                        labelText: 'Daily Rate (${CurrencyFormatter.symbol}) - Optional',
                        border: const OutlineInputBorder(),
                        prefixText: '${CurrencyFormatter.symbol} ',
                      ),
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 16),

                    SwitchListTile(
                      title: const Text('Active'),
                      value: _active,
                      onChanged: (value) {
                        setState(() {
                          _active = value;
                        });
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Fixed bottom buttons
            Container(
              padding: const EdgeInsets.only(top: 16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.textSecondaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveChanges,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveChanges() {
    try {
      // Convert pax pricing to string keys for multiLayerPricing
      Map<String, double> multiLayerPricing = {};
      if (_hasPackagePricing) {
        _paxPricing.forEach((pax, price) {
          multiLayerPricing['${pax}pax'] = price;
        });
      } else {
        multiLayerPricing = widget.service.multiLayerPricing;
      }

      // Create updated service object
      final updatedService = VendorServiceEnhanced(
        id: widget.service.id,
        name: _nameController.text.trim(),
        productCategory: _category,
        serviceTypes: [_type],
        description: _descriptionController.text.trim(),
        subcategory: _subcategory,
        price: double.tryParse(_basePriceController.text) ?? widget.service.basePrice,
        hourlyRate: _hourlyRateController.text.isNotEmpty ? double.tryParse(_hourlyRateController.text) : null,
        dailyRate: _dailyRateController.text.isNotEmpty ? double.tryParse(_dailyRateController.text) : null,
        isActive: _active,
        images: _imageUrls,
        supportsAppointments: _supportsAppointments,
        supportsRentals: _supportsRentals,
        multiLayerPricing: multiLayerPricing,
        vendorId: widget.service.vendorId,
        createdAt: widget.service.createdAt,
        updatedAt: DateTime.now(),
      );

      // Get vendor provider and update the service
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);

      // If this service exists in the sample dataset, update it in-place
      final allSampleServices = VendorServicesData.getAllServices();
      final isSample = allSampleServices.any((s) => s.id == widget.service.id);

      if (isSample) {
        // Update sample service in shared seed data (in-memory)
        final replaced = VendorServicesData.updateServiceFromEnhanced(updatedService);
        if (replaced) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Service "${_nameController.text.trim()}" updated successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        } else {
          // Fallback: create or update custom service
          final customServices = vendorProvider.getCustomServices();
          final existingCustom = customServices.firstWhere((s) => s.id == widget.service.id, orElse: () => updatedService);
          if (existingCustom.id == updatedService.id) {
            vendorProvider.updateCustomService(updatedService.id, updatedService);
          } else {
            vendorProvider.addCustomService(updatedService);
          }
        }
      } else {
        // Handle custom services as before
        final customServices = vendorProvider.getCustomServices();
        final isCustomService = customServices.any((s) => s.id == widget.service.id);

        if (isCustomService) {
          // Update existing custom service
          vendorProvider.updateCustomService(widget.service.id, updatedService);
        } else {
          // Create a new custom version with updated details
          final customService = VendorServiceEnhanced(
            id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
            name: _nameController.text.trim(),
            productCategory: _category,
            serviceTypes: [_type],
            description: _descriptionController.text.trim(),
            subcategory: _subcategory,
            price: double.tryParse(_basePriceController.text) ?? widget.service.basePrice,
            hourlyRate: _hourlyRateController.text.isNotEmpty ? double.tryParse(_hourlyRateController.text) : null,
            dailyRate: _dailyRateController.text.isNotEmpty ? double.tryParse(_dailyRateController.text) : null,
            isActive: _active,
            images: _imageUrls,
            supportsAppointments: _supportsAppointments,
            supportsRentals: _supportsRentals,
            multiLayerPricing: multiLayerPricing,
            vendorId: widget.service.vendorId,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          vendorProvider.addCustomService(customService);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service "${_nameController.text.trim()}" updated successfully!${_supportsAppointments ? ' (Supports Appointments)' : ''}${_supportsRentals ? ' (Supports Rentals)' : ''}'),
          backgroundColor: AppTheme.successColor,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update service: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _pickImages() async {
    try {
      setState(() {
        _isUploading = true;
      });

      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        // In a real app, you would upload these images to a server
        // For now, we'll use placeholder URLs
        List<String> newUrls = [];
        for (var image in images) {
          if (_imageUrls.length < 5) {
            // Simulate upload delay
            await Future.delayed(const Duration(milliseconds: 500));
            // In real implementation, upload to Firebase Storage or similar
            newUrls.add('https://images.unsplash.com/photo-${DateTime.now().millisecondsSinceEpoch}?w=400&h=400&fit=crop');
          }
        }

        setState(() {
          _imageUrls.addAll(newUrls);
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newUrls.length} image(s) added successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Image removed'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}
