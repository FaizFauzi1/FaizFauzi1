import 'package:eventease/shared/models/region.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegionManagementScreen extends StatefulWidget {
  const RegionManagementScreen({super.key});

  @override
  State<RegionManagementScreen> createState() => _RegionManagementScreenState();
}

class _RegionManagementScreenState extends State<RegionManagementScreen> {
  String _searchQuery = '';
  String _filterType = 'All';
  String _filterStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final regions = admin.regions;
    final regionsMap = {for (var r in regions) r.id: r};

    final filteredRegions = _filterRegions(regions, regionsMap);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Region Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRegionDialog(context, admin),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchFilterBar(),
          Expanded(
            child: filteredRegions.isEmpty
                ? const Center(child: Text('No regions found'))
                : ListView(
                    padding: const EdgeInsets.all(12),
                    children: _buildHierarchy(filteredRegions, regionsMap, admin),
                  ),
          ),
        ],
      ),
    );
  }

  // -------------------------------
  // 🔎 Search + Filter Bar
  // -------------------------------
  Widget _buildSearchFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search regions by name, code, or path...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _filterType,
                  items: ['All', 'Country', 'State', 'City']
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _filterType = value!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _filterStatus,
                  items: ['All', 'Active', 'Inactive']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _filterStatus = value!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------
  // 🌍 Hierarchy Builder (Tree View)
  // -------------------------------
  List<Widget> _buildHierarchy(List<Region> regions, Map<String, Region> regionsMap, AdminProvider admin) {
    final countries = regions.where((r) => r.type == RegionType.country).toList();

    return countries.map((country) {
      return _buildRegionExpansion(country, regionsMap, admin);
    }).toList();
  }

  Widget _buildRegionExpansion(Region region, Map<String, Region> regionsMap, AdminProvider admin, {Set<String>? visitedIds}) {
    // Cycle detection
    final currentVisited = Set<String>.from(visitedIds ?? {});
    if (currentVisited.contains(region.id)) {
      return ListTile(
        leading: const Icon(Icons.error_outline, color: Colors.orange),
        title: Text('${region.name} (Circular Reference Detected)'),
        subtitle: const Text('This region is already in the hierarchy path'),
      );
    }
    currentVisited.add(region.id);

    final children = region.getChildren(regionsMap.values.toList());
    
    // Calculate vendor count for this region (including sub-regions)
    final int vendorCount = _calculateVendorCountForRegion(region, regionsMap, admin.vendors);

    return ExpansionTile(
      leading: Icon(_getRegionIcon(region.type), color: AppTheme.primaryColor),
      title: Row(
        children: [
          Expanded(child: Text(region.name, style: const TextStyle(fontWeight: FontWeight.bold))),
          // Vendor Count Badge
          Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.storefront, size: 12, color: Colors.blue),
                  const SizedBox(width: 4),
                  Text(
                    '$vendorCount',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: region.isActive ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              region.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: region.isActive ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      subtitle: Text('${region.type.toString().split('.').last} • Code: ${region.code ?? '-'}'),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () => _showRegionActions(region, admin),
      ),
      children: children.isEmpty
          ? [ListTile(title: Text('No sub-regions under ${region.name}'))]
          : children.map((child) => _buildRegionExpansion(child, regionsMap, admin, visitedIds: currentVisited)).toList(),
    );
  }

  // -------------------------------
  // 📊 Vendor Count Calculation
  // -------------------------------
  int _calculateVendorCountForRegion(Region region, Map<String, Region> regionsMap, List<AdminVendor> vendors) {
    // Collect all region names that fall under this region (including itself)
    final Set<String> validRegionNames = {region.name.trim().toLowerCase()};
    
    // Add all children region names recursively
    void addChildrenNames(Region currentRegion) {
      final children = currentRegion.getChildren(regionsMap.values.toList());
      for (final child in children) {
        validRegionNames.add(child.name.trim().toLowerCase());
        addChildrenNames(child); // recurse
      }
    }
    
    addChildrenNames(region);

    // Count vendors whose service areas intersect with the valid region names
    int count = 0;
    for (final vendor in vendors) {
      // Check if any of the vendor's service areas match our region or its sub-regions
      final isOperatingInRegion = vendor.serviceAreas.any((area) => 
          validRegionNames.contains(area.toLowerCase().trim()));
          
      if (isOperatingInRegion) {
        count++;
      }
    }
    
    return count;
  }

  // -------------------------------
  // 📋 Filters

  // -------------------------------
  List<Region> _filterRegions(List<Region> regions, Map<String, Region> regionsMap) {
    if (_searchQuery.isEmpty && _filterType == 'All' && _filterStatus == 'All') {
      return regions;
    }

    final Set<String> matchedIds = {};
    
    // 1. Identify directly matching regions
    for (final region in regions) {
      final matchesSearch = region.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (region.code?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          region.getFullPath(regionsMap).toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesType = _filterType == 'All' ||
          region.type.toString().split('.').last.toUpperCase() == _filterType.toUpperCase();

      final matchesStatus = _filterStatus == 'All' ||
          (_filterStatus == 'Active' && region.isActive) ||
          (_filterStatus == 'Inactive' && !region.isActive);

      if (matchesSearch && matchesType && matchesStatus) {
        matchedIds.add(region.id);
        
        // 2. Add all ancestors of this match to ensure it appears in the hierarchy
        String? currentParentId = region.parentId;
        while (currentParentId != null) {
          if (matchedIds.contains(currentParentId)) break; // Already added
          matchedIds.add(currentParentId);
          currentParentId = regionsMap[currentParentId]?.parentId;
        }
      }
    }

    return regions.where((r) => matchedIds.contains(r.id)).toList();
  }

  // -------------------------------
  // ⚙️ Actions
  // -------------------------------
  void _showRegionActions(Region region, AdminProvider admin) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit'),
            onTap: () {
              Navigator.pop(context);
              _showEditRegionDialog(region, admin);
            },
          ),
          if (region.type != RegionType.city)
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Sub-Region'),
              onTap: () {
                Navigator.pop(context);
                _showAddSubRegionDialog(region, admin);
              },
            ),
          ListTile(
            leading: Icon(region.isActive ? Icons.block : Icons.check_circle,
                color: region.isActive ? Colors.red : Colors.green),
            title: Text(region.isActive ? 'Deactivate' : 'Activate'),
            onTap: () {
              admin.toggleRegionStatus(region.id);
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Delete'),
            onTap: () {
              Navigator.pop(context);
              _showDeleteConfirmation(region, admin);
            },
          ),
        ],
      ),
    );
  }

  void _showAddRegionDialog(BuildContext context, AdminProvider admin) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Country'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name (e.g. Malaysia)')),
            const SizedBox(height: 10),
            TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code (e.g. MY)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                admin.addRegion(
                  name: nameController.text,
                  type: RegionType.country,
                  code: codeController.text.isNotEmpty ? codeController.text : null,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditRegionDialog(Region region, AdminProvider admin) {
    final nameController = TextEditingController(text: region.name);
    final codeController = TextEditingController(text: region.code ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Region'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              admin.updateRegion(region.id, name: nameController.text, code: codeController.text);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddSubRegionDialog(Region parent, AdminProvider admin) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    RegionType subType = parent.type == RegionType.country ? RegionType.state : RegionType.city;
    String typeName = subType == RegionType.state ? 'State' : 'City';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $typeName under ${parent.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: InputDecoration(labelText: '$typeName Name')),
            if (subType == RegionType.state) ...[
              const SizedBox(height: 10),
              TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Code (optional)')),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                admin.addRegion(
                  name: nameController.text,
                  type: subType,
                  code: codeController.text.isNotEmpty ? codeController.text : null,
                  parentId: parent.id,
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Region region, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Region'),
        content: Text('Are you sure you want to delete ${region.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              admin.deleteRegion(region.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  IconData _getRegionIcon(RegionType type) {
    switch (type) {
      case RegionType.country:
        return Icons.public;
      case RegionType.state:
        return Icons.location_city;
      case RegionType.city:
        return Icons.location_on;
    }
  }
}
