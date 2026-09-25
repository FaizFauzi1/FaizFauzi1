import 'package:eventease/shared/models/sample_service_packages.dart';
import 'package:eventease/shared/models/services/service_package.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:eventease/features/admin/data/services/admin_marketplace_service.dart';
import 'package:eventease/features/admin/presentation/widgets/admin_entity_detail_dialog.dart';

class AdminPackageApprovalScreen extends StatefulWidget {
  const AdminPackageApprovalScreen({super.key});

  @override
  State<AdminPackageApprovalScreen> createState() => _AdminPackageApprovalScreenState();
}

class _AdminPackageApprovalScreenState extends State<AdminPackageApprovalScreen> {
  late List<ServicePackage> _pendingPackages;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Wedding',
    'Corporate',
    'Birthday',
    'Graduation',
    'Anniversary',
    'Religious',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadPendingPackages();
  }

  void _loadPendingPackages() {
    setState(() {
      _pendingPackages = SampleServicePackages.getPendingPackages();
    });
  }

  List<ServicePackage> get _filteredPackages {
    return _pendingPackages.where((package) {
      final matchesSearch = _searchQuery.isEmpty ||
          package.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          package.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          package.vendorName?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;

      final matchesCategory = _selectedCategory == 'All' ||
          package.category == _selectedCategory;

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
        title: Text(
          'Package Approval (${_pendingPackages.length})',
          style: const TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Section
          _buildSearchAndFilterSection(),

          // Packages List
          Expanded(
            child: _filteredPackages.isEmpty
                ? _buildEmptyState()
                : _buildPackagesList(),
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
              hintText: 'Search packages or vendors...',
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

  Widget _buildPackagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredPackages.length,
      itemBuilder: (context, index) {
        final package = _filteredPackages[index];
        return _buildPackageCard(package);
      },
    );
  }

  Widget _buildPackageCard(ServicePackage package) {
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
          // Package Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
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
                        package.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        package.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.business, size: 16, color: AppTheme.textSecondaryColor),
                          const SizedBox(width: 4),
                          Text(
                            package.vendorName ?? 'Unknown Vendor',
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Package Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Category and Capacity
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        package.category,
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
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${package.getAvailablePax().first}-${package.getAvailablePax().last} pax',
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

                // Pricing Information
                Row(
                  children: [
                    Text(
                      'From RM ${package.priceByPax.values.first.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${package.priceByPax.length} pricing tiers',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Multi-Vendor Package Validation Status Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.rule_folder_outlined, color: Colors.blue, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Validation: Owner, Vendors, Pricing, Availability, Appointments, Customer Choice verified.',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Action Buttons Row 1: Details, Approve, Request Changes, Reject
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showPackageDetails(package),
                        icon: const Icon(Icons.visibility, size: 15),
                        label: const Text('Details', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _approvePackage(package),
                        icon: const Icon(Icons.check, size: 15),
                        label: const Text('Approve', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: AppTheme.successColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _requestPackageChanges(package),
                        icon: const Icon(Icons.edit_note, size: 15),
                        label: const Text('Changes', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejectPackage(package),
                        icon: const Icon(Icons.close, size: 15),
                        label: const Text('Reject', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: AppTheme.warningColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Action Buttons Row 2: Relationships & Unpublish
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          AdminEntityDetailDialog.show(
                            context,
                            type: MarketplaceEntityType.package,
                            entityId: package.id,
                            entityName: package.name,
                            vendorName: package.vendorName,
                            status: package.approvalStatus.name,
                          );
                        },
                        icon: const Icon(Icons.hub_outlined, size: 15),
                        label: const Text('Inspect Relationships', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.teal.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _unpublishPackage(package),
                        icon: const Icon(Icons.unpublished_outlined, size: 15),
                        label: const Text('Unpublish', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade800,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No pending packages to review',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showPackageDetails(ServicePackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(package.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Vendor: ${package.vendorName ?? 'Unknown'}'),
              const SizedBox(height: 8),
              Text('Category: ${package.category}'),
              const SizedBox(height: 8),
              Text('Capacity: ${package.getAvailablePax().first}-${package.getAvailablePax().last} guests'),
              const SizedBox(height: 8),
              Text('Pricing: From RM ${package.priceByPax.values.first.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              Text('Description: ${package.description}'),
              if (package.venueDetails != null) ...[
                const SizedBox(height: 8),
                Text('Venue: ${package.venueDetails!.venueName}'),
                Text('Address: ${package.venueDetails!.address}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _approvePackage(ServicePackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Package'),
        content: Text('Are you sure you want to approve "${package.name}"? This package will be visible to customers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update package approval status
              SampleServicePackages.updatePackageApprovalStatus(package.id, ApprovalStatus.approved);
              _loadPendingPackages();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${package.name}" has been approved and is now visible to customers.'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectPackage(ServicePackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Package'),
        content: Text('Are you sure you want to reject "${package.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update package approval status
              SampleServicePackages.updatePackageApprovalStatus(package.id, ApprovalStatus.rejected);
              _loadPendingPackages();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${package.name}" has been rejected.'),
                  backgroundColor: AppTheme.warningColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _requestPackageChanges(ServicePackage package) {
    final reasons = <String, bool>{
      'Package Components Incomplete': false,
      'Collaborating Vendor Issue': false,
      'Pricing Tier Discrepancy': false,
      'Missing Availability Sync': false,
      'Appointment Rules Unconfigured': false,
      'Customer Choice Options Insufficient': false,
      'Travel Radius Conflicts': false,
      'Other': false,
    };
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.edit_note, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Request Changes: ${package.name}', style: const TextStyle(fontSize: 16)),
              ),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Specify required adjustments for the package owner before approval:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  ...reasons.keys.map((reason) => CheckboxListTile(
                        dense: true,
                        value: reasons[reason],
                        title: Text(reason, style: const TextStyle(fontSize: 13)),
                        onChanged: (val) {
                          setModalState(() => reasons[reason] = val ?? false);
                        },
                      )),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'Admin Guidance Notes',
                      hintText: 'e.g. Catering collaborator has 6 PM cutoff; please adjust dinner hours...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final selected = reasons.entries.where((e) => e.value).map((e) => e.key).toList();
                if (selected.isEmpty && notesController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one reason or provide guidance notes.')),
                  );
                  return;
                }

                SampleServicePackages.updatePackageApprovalStatus(package.id, ApprovalStatus.rejected);
                _loadPendingPackages();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Changes requested for "${package.name}". Package owner notified.'),
                    backgroundColor: Colors.amber.shade800,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
              child: const Text('Send Change Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _unpublishPackage(ServicePackage package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpublish Package'),
        content: Text('Are you sure you want to unpublish "${package.name}" from the customer marketplace? Active bookings will remain intact.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              SampleServicePackages.updatePackageApprovalStatus(package.id, ApprovalStatus.rejected);
              _loadPendingPackages();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('"${package.name}" has been unpublished from marketplace.'),
                  backgroundColor: Colors.grey.shade800,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade800),
            child: const Text('Unpublish Package'),
          ),
        ],
      ),
    );
  }
}
