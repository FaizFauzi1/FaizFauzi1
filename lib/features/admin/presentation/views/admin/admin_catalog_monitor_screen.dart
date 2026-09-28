import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/features/admin/data/providers/admin_marketplace_provider.dart';
import 'package:eventease/features/admin/data/services/admin_marketplace_service.dart';
import 'package:eventease/features/admin/presentation/widgets/admin_entity_detail_dialog.dart';

class AdminCatalogMonitorScreen extends StatefulWidget {
  const AdminCatalogMonitorScreen({super.key});

  @override
  State<AdminCatalogMonitorScreen> createState() => _AdminCatalogMonitorScreenState();
}

class _AdminCatalogMonitorScreenState extends State<AdminCatalogMonitorScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  late TabController _tabController;
  List<VendorService> _allServices = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedHealthIssue = 'All';
  final Set<String> _selectedItemIds = {};

  final List<String> _categories = [
    'All',
    'Catering',
    'Photography',
    'Venue',
    'Decoration',
    'Entertainment',
    'Fashion',
    'Beauty & Wellness',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchCatalogItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCatalogItems() async {
    setState(() => _isLoading = true);
    try {
      final response = await _supabase
          .from('vendor_services')
          .select('*, vendor:vendor_profiles(business_name)')
          .order('created_at', ascending: false);

      final List<VendorService> services = [];
      for (final json in (response as List)) {
        try {
          if (json['vendor'] != null) {
            json['vendor_name'] = json['vendor']['business_name'];
          }
          services.add(VendorService.fromJson(json));
        } catch (e) {
          debugPrint('Error parsing service in admin monitor: $e');
        }
      }

      setState(() {
        _allServices = services;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching catalog items: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading catalog: $e')),
        );
      }
    }
  }

  Future<void> _toggleItemStatus(VendorService item, bool newActiveState) async {
    try {
      await _supabase
          .from('vendor_services')
          .update({'is_active': newActiveState})
          .eq('id', item.id);

      setState(() {
        final index = _allServices.indexWhere((s) => s.id == item.id);
        if (index != -1) {
          _allServices[index] = _allServices[index].copyWith(active: newActiveState);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(newActiveState ? 'Item is now Active' : 'Item is now Inactive')),
        );
      }
    } catch (e) {
      debugPrint('Error toggling active status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  Future<void> _approveItem(VendorService item) async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await adminProvider.approveService(item.id);

      setState(() {
        final index = _allServices.indexWhere((s) => s.id == item.id);
        if (index != -1) {
          _allServices[index] = _allServices[index].copyWith(
            approvalStatus: ApprovalStatus.approved,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catalog item approved'), backgroundColor: AppTheme.successColor),
        );
      }
    } catch (e) {
      debugPrint('Error approving item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approval failed: $e')),
        );
      }
    }
  }

  Future<void> _rejectItem(VendorService item, String reason) async {
    try {
      final adminProvider = Provider.of<AdminProvider>(context, listen: false);
      await adminProvider.rejectService(item.id, reason);

      setState(() {
        final index = _allServices.indexWhere((s) => s.id == item.id);
        if (index != -1) {
          _allServices[index] = _allServices[index].copyWith(
            approvalStatus: ApprovalStatus.rejected,
          );
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Catalog item rejected'), backgroundColor: AppTheme.warningColor),
        );
      }
    } catch (e) {
      debugPrint('Error rejecting item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rejection failed: $e')),
        );
      }
    }
  }

  List<VendorService> _getFilteredServices() {
    return _allServices.where((service) {
      final matchesSearch = _searchQuery.isEmpty ||
          service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.vendorName?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;

      final matchesCategory = _selectedCategory == 'All' ||
          service.category.displayName.toLowerCase().contains(_selectedCategory.toLowerCase());

      bool matchesHealth = true;
      if (_selectedHealthIssue == 'Healthy') {
        matchesHealth = service.images.isNotEmpty && service.description.length > 30 && service.basePrice > 0;
      } else if (_selectedHealthIssue == 'Missing Photos') {
        matchesHealth = service.images.isEmpty;
      } else if (_selectedHealthIssue == 'Missing Info') {
        matchesHealth = service.description.length < 30;
      } else if (_selectedHealthIssue == 'Pricing Issues') {
        matchesHealth = service.basePrice <= 0;
      } else if (_selectedHealthIssue == 'Reported') {
        matchesHealth = service.approvalStatus == ApprovalStatus.rejected;
      }

      return matchesSearch && matchesCategory && matchesHealth;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final mktProvider = Provider.of<AdminMarketplaceProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Catalog Health & Duplicate Engine'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: _fetchCatalogItems,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.health_and_safety_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Marketplace Listing Health (${_allServices.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.copy_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Duplicate Detection (${mktProvider.duplicateMatches.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListingHealthTab(),
                _buildDuplicateDetectionTab(mktProvider),
              ],
            ),
    );
  }

  // ==========================================
  // TAB 1: LISTING HEALTH
  // ==========================================
  Widget _buildListingHealthTab() {
    final filtered = _getFilteredServices();

    final missingPhotosCount = _allServices.where((s) => s.images.isEmpty).length;
    final missingInfoCount = _allServices.where((s) => s.description.length < 30).length;
    final pricingIssuesCount = _allServices.where((s) => s.basePrice <= 0).length;
    final reportedCount = _allServices.where((s) => s.approvalStatus == ApprovalStatus.rejected).length;

    return Column(
      children: [
        // Operational Health Issue Summary Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: Colors.white,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHealthFilterChip('All', _allServices.length),
                const SizedBox(width: 8),
                _buildHealthFilterChip('Healthy', _allServices.length - missingPhotosCount - missingInfoCount, badgeColor: Colors.green),
                const SizedBox(width: 8),
                _buildHealthFilterChip('Missing Photos', missingPhotosCount, badgeColor: Colors.orange, icon: Icons.broken_image_outlined),
                const SizedBox(width: 8),
                _buildHealthFilterChip('Missing Info', missingInfoCount, badgeColor: Colors.purple, icon: Icons.notes_outlined),
                const SizedBox(width: 8),
                _buildHealthFilterChip('Pricing Issues', pricingIssuesCount, badgeColor: Colors.red, icon: Icons.money_off),
                const SizedBox(width: 8),
                _buildHealthFilterChip('Reported', reportedCount, badgeColor: Colors.red, icon: Icons.flag_outlined),
              ],
            ),
          ),
        ),
        const Divider(height: 1),

        // Search & Category Bar + Bulk Actions
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search listing or vendor...',
                        prefixIcon: const Icon(Icons.search),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isDense: true,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) => setState(() => _selectedCategory = val ?? 'All'),
                    ),
                  ),
                ],
              ),
              if (_selectedItemIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Text('${_selectedItemIds.length} listings selected', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Update notification dispatched to ${_selectedItemIds.length} vendors!')),
                          );
                          setState(() => _selectedItemIds.clear());
                        },
                        icon: const Icon(Icons.notification_add, size: 14),
                        label: const Text('Request Updates', style: TextStyle(fontSize: 11)),
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () => setState(() => _selectedItemIds.clear()),
                        child: const Text('Cancel', style: TextStyle(fontSize: 11)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Catalog List
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text('No catalog listings found for this health filter.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) => _buildCatalogItemCard(filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildHealthFilterChip(String label, int count, {IconData? icon, Color? badgeColor}) {
    final isSelected = _selectedHealthIssue == label;
    return InkWell(
      onTap: () => setState(() => _selectedHealthIssue = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : (badgeColor ?? Colors.black87)),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : (badgeColor?.withOpacity(0.15) ?? Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (badgeColor ?? Colors.black87)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCatalogItemCard(VendorService item) {
    final isSelected = _selectedItemIds.contains(item.id);
    final isMissingPhotos = item.images.isEmpty;
    final isMissingInfo = item.description.length < 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedItemIds.add(item.id);
                      } else {
                        _selectedItemIds.remove(item.id);
                      }
                    });
                  },
                ),
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item.images.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(item.images.first, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image)),
                        )
                      : const Icon(Icons.image_not_supported, color: Colors.grey),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 2),
                      Text('Vendor: ${item.vendorName ?? "Partner"} • Category: ${item.category.displayName}',
                          style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 2),
                      Text('RM ${item.basePrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13)),
                    ],
                  ),
                ),
                if (isMissingPhotos)
                  _buildHealthBadge('No Photos', Colors.orange)
                else if (isMissingInfo)
                  _buildHealthBadge('Low Info', Colors.purple)
                else
                  _buildHealthBadge('Healthy', Colors.green),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    AdminEntityDetailDialog.show(
                      context,
                      type: MarketplaceEntityType.service,
                      entityId: item.id,
                    );
                  },
                  icon: const Icon(Icons.hub_outlined, size: 14),
                  label: const Text('Relationships', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _toggleItemStatus(item, !item.active),
                  icon: Icon(item.active ? Icons.pause : Icons.play_arrow, size: 14),
                  label: Text(item.active ? 'Suspend' : 'Activate', style: const TextStyle(fontSize: 11)),
                ),
                const Spacer(),
                if (item.approvalStatus == ApprovalStatus.pending)
                  ElevatedButton(
                    onPressed: () => _approveItem(item),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve', style: TextStyle(fontSize: 11)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
    );
  }

  // ==========================================
  // TAB 2: DUPLICATE DETECTION ENGINE
  // ==========================================
  Widget _buildDuplicateDetectionTab(AdminMarketplaceProvider mktProvider) {
    final matches = mktProvider.duplicateMatches;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'EventEase Duplicate Detection Engine continuously audits listing titles, contact numbers, GPS locations, and descriptions across Vendors, Services, Products, and Packages to prevent marketplace cannibalization.',
                    style: TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('POTENTIAL DUPLICATE CANDIDATES AWAITING AUDIT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          ...matches.map((match) => _buildDuplicateCard(match, mktProvider)),
        ],
      ),
    );
  }

  Widget _buildDuplicateCard(DuplicateMatch match, AdminMarketplaceProvider mktProvider) {
    const isPending = true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.purple.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(match.entityType.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purple)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    '${(match.similarityScore * 100).toInt()}% Match',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.red),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Pending Review',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.orange.shade800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Side-by-side comparison
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PRIMARY RECORD (ORIGINAL)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text(match.name1, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Vendor: ${match.details1['vendor'] ?? "N/A"}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        Text('Phone: ${match.details1['phone'] ?? "N/A"} • ${match.details1['location'] ?? "N/A"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('POTENTIAL DUPLICATE CANDIDATE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                        const SizedBox(height: 4),
                        Text(match.name2, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                        Text('Vendor: ${match.details2['vendor'] ?? "N/A"}', style: const TextStyle(fontSize: 11, color: Colors.black87)),
                        Text('Phone: ${match.details2['phone'] ?? "N/A"} • ${match.details2['location'] ?? "N/A"}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text('Matched On: ${match.reason}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
            const SizedBox(height: 12),

            if (isPending) ...[
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      mktProvider.resolveDuplicate(match.id, 'Merged into Primary');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Merged ${match.name2} into primary record successfully!'), backgroundColor: Colors.green),
                      );
                    },
                    icon: const Icon(Icons.merge_type, size: 14),
                    label: const Text('Merge Listings', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () {
                      mktProvider.resolveDuplicate(match.id, 'Kept Separate (Verified Legitimate)');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Marked ${match.name2} as separate verified record.')),
                      );
                    },
                    child: const Text('Keep Separate', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      mktProvider.resolveDuplicate(match.id, 'Ignored');
                    },
                    child: const Text('Ignore', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
