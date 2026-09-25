import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/pdf_generator_service.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/vendor_service_enhanced.dart';
import '../../data/providers/vendor_provider_updated.dart';
import 'enhanced_service_creation_screen.dart';
import 'vendor_availability_management_screen.dart';
import '../widgets/service_review_summary.dart';


class VendorServiceManagementListView extends StatefulWidget {
  const VendorServiceManagementListView({super.key});

  @override
  State<VendorServiceManagementListView> createState() => _VendorServiceManagementListViewState();
}

class _VendorServiceManagementListViewState extends State<VendorServiceManagementListView> {
  bool _isLoading = true;
  bool _isInitialized = false;

  final TextEditingController _searchController = TextEditingController();

  EventCategory? _selectedFilter;
  ServiceType? _selectedType;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadVendorData();
      _isInitialized = true;
    }
  }

  Future<void> _loadVendorData() async {
    try {
      final provider = Provider.of<VendorProvider>(context, listen: false);
      await provider.loadCurrentVendorFromSupabase();
    } catch (e) {
      print('Error loading vendor data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<VendorServiceEnhanced> _getFilteredItems(VendorProvider provider) {
    final services = provider.getCurrentVendorServices();
    return services.where((item) {
      final categoryMatch = _selectedFilter == null || item.productCategory == _selectedFilter;
      final typeMatch = _selectedType == null || item.serviceType == _selectedType;
      final searchMatch = _searchController.text.isEmpty ||
          item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchController.text.toLowerCase());
      return categoryMatch && typeMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('My Products & Services',
              style: TextStyle(
                  color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final provider = Provider.of<VendorProvider>(context);
    final filtered = _getFilteredItems(provider);

    final allServices = provider.getCurrentVendorServices();
    final activeItems = allServices.where((item) => item.isActive == true).toList();
    final totalStock = allServices.fold<int>(0, (int sum, item) => sum + item.inventory);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Products & Services',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          PopupMenuButton<ServiceType?>(
            icon: const Icon(Icons.filter_alt, color: AppTheme.primaryColor),
            onSelected: (type) => setState(() => _selectedType = type),
            itemBuilder: (context) => [
              const PopupMenuItem(value: null, child: Text('All Types')),
              PopupMenuItem(value: ServiceType.product, child: Text('Products')),
              PopupMenuItem(value: ServiceType.rental, child: Text('Rentals')),
              PopupMenuItem(value: ServiceType.package, child: Text('Packages')),
              PopupMenuItem(value: ServiceType.consultation, child: Text('Consultations')),
            ],
          ),
          IconButton(
              icon: const Icon(Icons.add, color: AppTheme.primaryColor),
              onPressed: () => _showAddItemDialog(provider))
        ],
      ),
      body: Column(
        children: [
          // Summary header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildSummaryCard(
                    title: "Total Stock", value: totalStock.toString()),
                const SizedBox(width: 12),
                _buildSummaryCard(
                    title: "Active Services", value: activeItems.length.toString()),
              ],
            ),
          ),

          // Category Filter Chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildFilterChip(null),
                ...EventCategory.values.take(5).map((category) => _buildFilterChip(category)),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text("No items found",
                        style: TextStyle(color: AppTheme.textSecondaryColor)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) =>
                        _buildItemTile(filtered[i], provider),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({required String title, required String value}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2)),
            ]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 4),
            Text(value,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(EventCategory? category) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category?.displayName ?? 'All'),
        selected: _selectedFilter == category,
        onSelected: (v) => setState(() => _selectedFilter = category),
      ),
    );
  }

  Widget _buildItemTile(VendorServiceEnhanced item, VendorProvider provider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Text(item.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textPrimaryColor)),
            ),
            _buildStatusBadge(item),
            const SizedBox(width: 8),
            Switch(
                value: item.isActive,
                onChanged: (v) => provider.toggleCustomServiceStatus(item.id)),
          ]),
          Text('${item.productCategory.displayName}${item.subcategory != null ? ' • ${item.subcategory}' : ''} • ${_getPriceDisplay(item)}',
              style: const TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
          const SizedBox(height: 4),
          Text(item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondaryColor)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildInfoChip(Icons.image, '${item.images.length} images'),
              if (item.serviceType == ServiceType.product)
                _buildInfoChip(Icons.inventory, '${item.inventory} in stock'),
              if (item.options.containsKey('addOns'))
                _buildInfoChip(Icons.add_circle_outline, 'Add-ons'),
              if (item.options.containsKey('variations'))
                _buildInfoChip(Icons.layers_outlined, 'Variations'),
              if (item.venueAddress != null && item.venueAddress!.isNotEmpty)
                _buildInfoChip(Icons.location_on_outlined, 'Venue'),
              if (item.coverageArea != null && item.coverageArea!.isNotEmpty)
                _buildInfoChip(Icons.map_outlined, 'Service Area'),
              if (item.multiLayerPricing.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text('Prices: {${item.multiLayerPricing.entries.map((e) => '${e.key}: ${e.value.toStringAsFixed(0)}').join(', ')}}', 
                    style: const TextStyle(fontSize: 11, color: Colors.teal, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // IconButton(
              //     onPressed: () => provider.duplicateCustomService(item.id),
              //     icon: const Icon(Icons.copy, color: AppTheme.secondaryColor)),
              IconButton(
                  onPressed: () => _editItem(item, provider),
                  icon: const Icon(Icons.edit, color: AppTheme.primaryColor)),
              IconButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VendorAvailabilityManagementScreen(service: item))),
                  icon: const Icon(Icons.schedule, color: AppTheme.primaryColor)),
              IconButton(
                  onPressed: () => _generateQuotation(item, provider),
                  icon: const Icon(Icons.description, color: AppTheme.secondaryColor)),
              IconButton(
                  onPressed: () => _showPreview(item),
                  icon: const Icon(Icons.visibility, color: AppTheme.secondaryColor)),
              IconButton(
                  onPressed: () async {
                    try {
                      await provider.removeCustomService(item.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Item deleted successfully')));
                      }
                    } catch (e) {
                      print('Error deleting service: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Error deleting item: $e')));
                      }
                    }
                  },
                  icon: const Icon(Icons.delete, color: AppTheme.errorColor)),
            ],
          )
        ]),
      ),
    );
  }

  Widget _buildStatusBadge(VendorServiceEnhanced service) {
    var attributes = _getStatusAttributes(service);
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

  Map<String, dynamic> _getStatusAttributes(VendorServiceEnhanced service) {
    if (service.status == ServiceStatus.draft) {
      return {'label': 'Draft', 'color': Colors.grey, 'icon': Icons.edit_note};
    }
    if (service.approvalStatus == ApprovalStatus.rejected) {
      return {'label': 'Rejected', 'color': Colors.red, 'icon': Icons.error_outline};
    }
    if (service.approvalStatus == ApprovalStatus.pending) {
      return {'label': 'Reviewing', 'color': Colors.orange, 'icon': Icons.hourglass_empty};
    }
    if (service.status == ServiceStatus.maintenance) {
      return {'label': 'Maintenance', 'color': Colors.amber[700]!, 'icon': Icons.build};
    }
    if (service.isActive) {
      return {'label': 'Live', 'color': AppTheme.successColor, 'icon': Icons.check_circle};
    } else {
      return {'label': 'Offline', 'color': Colors.grey[600]!, 'icon': Icons.visibility_off};
    }
  }

  void _showAddItemDialog(VendorProvider provider) {
    if (provider.currentVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor information not available')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EnhancedServiceCreationScreen(existingService: null, vendorId: provider.currentVendor!.id)),
    );
  }

  void _editItem(VendorServiceEnhanced item, VendorProvider provider) {
    if (provider.currentVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor information not available')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EnhancedServiceCreationScreen(existingService: item, vendorId: provider.currentVendor!.id)),
    );
  }

  String _getPriceDisplay(VendorServiceEnhanced item) {
    final base = item.basePrice;
    if (base == 0) return 'Contact for Price';
    
    String priceStr = 'RM ${base.toStringAsFixed(2)}';
    if (item.multiLayerPricing.isNotEmpty || item.hasVariations) {
      priceStr = 'Starts from $priceStr';
    }
    return priceStr;
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
        ],
      ),
    );
  }

  void _showPreview(VendorServiceEnhanced item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.name),
        content: SizedBox(
          width: double.maxFinite,
          child: ServiceReviewSummary(service: item),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              final provider = Provider.of<VendorProvider>(context, listen: false);
              _editItem(item, provider);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }


  void _generateQuotation(VendorServiceEnhanced item, VendorProvider provider) async {
    print('DEBUG: _generateQuotation called for ${item.name}');
    if (provider.currentVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor information not available')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating quotation...')),
    );

    try {
      await PdfGeneratorService().generateAndShareQuotation(item, provider.currentVendor!);
    } catch (e) {
      print('Error generating quotation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating quotation: $e')),
        );
      }
    }
  }
}
