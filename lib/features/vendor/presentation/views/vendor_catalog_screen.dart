import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/providers/vendor_provider_updated.dart';
import 'enhanced_service_creation_screen.dart';
import '../widgets/vendor_responsive_scaffold.dart';

class VendorCatalogScreen extends StatefulWidget {
  const VendorCatalogScreen({super.key});

  @override
  State<VendorCatalogScreen> createState() => _VendorCatalogScreenState();
}

class _VendorCatalogScreenState extends State<VendorCatalogScreen> {
  String _searchQuery = '';
  String _selectedSubcategory = 'All';
  String? _selectedCategoryId;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);
    final vendor = vendorProvider.currentVendor;

    if (vendor == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final services = vendorProvider.getCurrentVendorServices();
    
    final categoryIds = vendor.categories.isNotEmpty ? vendor.categories : ['other'];
    final mainCategoryStr = _selectedCategoryId ?? categoryIds.first;
    final eventCategory = EventCategory.fromId(mainCategoryStr);
    final subcategories = ['All', ...eventCategory.subcategories];

    // Filter items
    final filteredServices = services.where((item) {
      final matchesSearch = _searchQuery.isEmpty ||
          item.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory = categoryIds.length <= 1 ||
          item.productCategory.id == eventCategory.id ||
          item.productCategory == eventCategory;

      final matchesSubcategory = _selectedSubcategory == 'All' ||
          item.subcategory == _selectedSubcategory;

      return matchesSearch && matchesCategory && matchesSubcategory;
    }).toList();

    // Stats
    final totalItems = services.length;
    final activeItems = services.where((s) => s.isActive).length;
    final pendingItems = services.where((s) => s.approvalStatus == ApprovalStatus.pending).length;

    return VendorResponsiveScaffold(
      title: 'My Catalog (${eventCategory.displayName})',
      actions: [
        IconButton(
          icon: const Icon(Icons.add, color: AppTheme.primaryColor),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EnhancedServiceCreationScreen(vendorId: vendor.id),
              ),
            );
          },
          tooltip: 'Add Catalog Item',
        ),
      ],
      body: Column(
        children: [
          // Stats Row
          _buildStatsRow(totalItems, activeItems, pendingItems),

          if (categoryIds.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categoryIds.map((id) {
                    final cat = EventCategory.fromId(id);
                    final selected = mainCategoryStr == id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat.displayName),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _selectedCategoryId = id;
                          _selectedSubcategory = 'All';
                        }),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

          // Search and Filters
          _buildSearchAndFilterSection(subcategories),

          // Catalog List
          Expanded(
            child: filteredServices.isEmpty
                ? _buildEmptyState(context, eventCategory)
                : _buildCatalogList(filteredServices, eventCategory),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int total, int active, int pending) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Items', total.toString(), Colors.blue),
          _buildStatItem('Active', active.toString(), Colors.green),
          _buildStatItem('Pending Audit', pending.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterSection(List<String> subcategories) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search catalog...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: subcategories.map((sub) {
                final isSelected = _selectedSubcategory == sub;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(sub),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSubcategory = selected ? sub : 'All';
                      });
                    },
                    selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCatalogList(List<VendorServiceEnhanced> items, EventCategory category) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        if (isWide) {
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              mainAxisExtent: 180,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) => _buildCatalogCard(items[index], category),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          itemBuilder: (context, index) => _buildCatalogCard(items[index], category),
        );
      },
    );
  }

  Widget _buildCatalogCard(VendorServiceEnhanced item, EventCategory category) {
    final vendor = Provider.of<VendorProvider>(context, listen: false).currentVendor;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: item.images.isNotEmpty
                    ? Image.network(
                        item.images.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 40, color: Colors.grey),
                      )
                    : const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
              // Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              item.subcategory ?? 'General',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildStatusBadge(item),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'RM ${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Available',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                    ),
                    Switch(
                      value: item.isActive,
                      onChanged: (val) async {
                        final provider = Provider.of<VendorProvider>(context, listen: false);
                        await provider.toggleCustomServiceStatus(item.id);
                      },
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                      onPressed: () {
                        if (vendor == null) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EnhancedServiceCreationScreen(
                              vendorId: vendor.id,
                              existingService: item,
                            ),
                          ),
                        );
                      },
                      tooltip: 'Edit Item',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                      onPressed: () => _confirmDelete(context, item.id),
                      tooltip: 'Delete Item',
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(VendorServiceEnhanced item) {
    Color color = Colors.grey;
    String label = 'Inactive';
    if (item.isActive) {
      if (item.approvalStatus == ApprovalStatus.pending) {
        color = Colors.orange;
        label = 'Pending Audit';
      } else if (item.approvalStatus == ApprovalStatus.approved) {
        color = Colors.green;
        label = 'Live';
      } else {
        color = Colors.red;
        label = 'Rejected';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, EventCategory category) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_mosaic, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Your Catalog is Empty',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Showcase your products and services here for customers to browse.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddEditItemSheet(context, category, null),
              icon: const Icon(Icons.add),
              label: const Text('Add First Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String serviceId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('Are you sure you want to remove this item from your catalog?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = Provider.of<VendorProvider>(this.context, listen: false);
              try {
                await provider.removeCustomService(serviceId);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    const SnackBar(content: Text('Item deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(content: Text('Failed to delete item: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddEditItemSheet(BuildContext context, EventCategory category, VendorServiceEnhanced? existingItem) {
    final vendor = Provider.of<VendorProvider>(context, listen: false).currentVendor;
    if (vendor == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EnhancedServiceCreationScreen(
          vendorId: vendor.id,
          existingService: existingItem,
        ),
      ),
    );
  }
}

                      final price = double.tryParse(priceText);
                      if (price == null || price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid price')),
                        );
                        return;
                      }

                      setModalState(() => _isSaving = true);
                      final provider = Provider.of<VendorProvider>(this.context, listen: false);

                      try {
                        final images = imageUrl.isNotEmpty ? [imageUrl] : <String>[];
                        
                        if (existingItem == null) {
                          // Create
                          final newItem = VendorServiceEnhanced(
                            id: '', // Will be generated by Supabase
                            name: name,
                            productCategory: category,
                            description: desc,
                            subcategory: selectedSub,
                            price: price,
                            images: images,
                            isActive: isActive,
                            vendorId: provider.currentVendor!.id,
                            status: ServiceStatus.active,
                            approvalStatus: ApprovalStatus.pending, // Audit required
                          );
                          await provider.addCustomService(newItem);
                        } else {
                          // Update
                          final updated = existingItem.copyWith(
                            name: name,
                            description: desc,
                            subcategory: selectedSub,
                            price: price,
                            images: images,
                            isActive: isActive,
                          );
                          await provider.updateCustomService(existingItem.id, updated);
                        }
                        
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(content: Text(existingItem == null ? 'Catalog item created' : 'Catalog item updated')),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error saving catalog item: $e')),
                          );
                        }
                      } finally {
                        setModalState(() => _isSaving = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(existingItem == null ? 'Create Item' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
