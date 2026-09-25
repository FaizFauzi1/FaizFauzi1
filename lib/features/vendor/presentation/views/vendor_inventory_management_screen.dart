import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class VendorInventoryManagementScreen extends StatefulWidget {
  const VendorInventoryManagementScreen({super.key});

  @override
  State<VendorInventoryManagementScreen> createState() => _VendorInventoryManagementScreenState();
}

class _VendorInventoryManagementScreenState extends State<VendorInventoryManagementScreen> {
  final List<Map<String, dynamic>> _inventory = [
    {
      'id': 'INV001',
      'name': 'Wedding Chairs (White)',
      'category': 'Furniture',
      'supplier': 'Furniture Plus',
      'quantity': 150,
      'minStock': 20,
      'unitPrice': 25.0,
      'totalValue': 3750.0,
      'location': 'Warehouse A',
      'lastUpdated': '2024-03-15',
      'status': 'In Stock',
    },
    {
      'id': 'INV002',
      'name': 'Round Tables (6ft)',
      'category': 'Furniture',
      'supplier': 'Table Masters',
      'quantity': 8,
      'minStock': 15,
      'unitPrice': 120.0,
      'totalValue': 960.0,
      'location': 'Warehouse B',
      'lastUpdated': '2024-03-14',
      'status': 'Low Stock',
    },
    {
      'id': 'INV003',
      'name': 'LED String Lights',
      'category': 'Decorations',
      'supplier': 'Light & Bright',
      'quantity': 45,
      'minStock': 10,
      'unitPrice': 15.0,
      'totalValue': 675.0,
      'location': 'Warehouse A',
      'lastUpdated': '2024-03-13',
      'status': 'In Stock',
    },
    {
      'id': 'INV004',
      'name': 'Table Linens (White)',
      'category': 'Linens',
      'supplier': 'Linen World',
      'quantity': 5,
      'minStock': 20,
      'unitPrice': 8.0,
      'totalValue': 40.0,
      'location': 'Warehouse C',
      'lastUpdated': '2024-03-12',
      'status': 'Critical',
    },
    {
      'id': 'INV005',
      'name': 'Sound System Speakers',
      'category': 'Equipment',
      'supplier': 'Audio Tech',
      'quantity': 12,
      'minStock': 5,
      'unitPrice': 200.0,
      'totalValue': 2400.0,
      'location': 'Warehouse B',
      'lastUpdated': '2024-03-11',
      'status': 'In Stock',
    },
  ];

  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final filteredInventory = _inventory.where((item) {
      final matchesSearch = item['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
                           item['supplier'].toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || item['category'] == _selectedCategory;
      final matchesStatus = _selectedStatus == 'All' || item['status'] == _selectedStatus;
      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();

    final totalValue = _inventory.fold<double>(0, (sum, item) => sum + item['totalValue']);
    final lowStockCount = _inventory.where((item) => item['status'] == 'Low Stock' || item['status'] == 'Critical').length;
    final inStockCount = _inventory.where((item) => item['status'] == 'In Stock').length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Inventory Management',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _addNewItem,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          _buildSearchAndFilters(),

          // Inventory stats
          _buildInventoryStats(totalValue, lowStockCount, inStockCount),

          // Inventory list
          Expanded(
            child: filteredInventory.isEmpty
                ? const Center(
                    child: Text(
                      'No inventory items found',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredInventory.length,
                    itemBuilder: (context, index) =>
                        _buildInventoryCard(filteredInventory[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Search inventory...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
          ),
          const SizedBox(height: 12),

          // Filters
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Categories')),
                    DropdownMenuItem(value: 'Furniture', child: Text('Furniture')),
                    DropdownMenuItem(value: 'Decorations', child: Text('Decorations')),
                    DropdownMenuItem(value: 'Linens', child: Text('Linens')),
                    DropdownMenuItem(value: 'Equipment', child: Text('Equipment')),
                  ],
                  onChanged: (value) => setState(() => _selectedCategory = value!),
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Status')),
                    DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
                    DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock')),
                    DropdownMenuItem(value: 'Critical', child: Text('Critical')),
                  ],
                  onChanged: (value) => setState(() => _selectedStatus = value!),
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStats(double totalValue, int lowStock, int inStock) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Value',
              'RM ${totalValue.toStringAsFixed(0)}',
              Icons.attach_money,
              AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Low Stock',
              lowStock.toString(),
              Icons.warning,
              AppTheme.warningColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'In Stock',
              inStock.toString(),
              Icons.inventory,
              AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(Map<String, dynamic> item) {
    final statusColor = _getStatusColor(item['status']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Row(
            children: [
              // Item info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item['status'],
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item['category']} • ${item['supplier']}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Location: ${item['location']}',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Quantity and value
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item['quantity']} units',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'RM ${item['totalValue'].toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '@ RM ${item['unitPrice'].toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar for stock level
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Stock Level',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  Text(
                    '${item['quantity']}/${item['minStock'] * 2}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: item['quantity'] / (item['minStock'] * 2),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editItem(item),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _adjustStock(item),
                  icon: const Icon(Icons.add_circle, size: 16),
                  label: const Text('Adjust'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewHistory(item),
                  icon: const Icon(Icons.history, size: 16),
                  label: const Text('History'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'In Stock':
        return Colors.green;
      case 'Low Stock':
        return Colors.orange;
      case 'Critical':
        return Colors.red;
      default:
        return AppTheme.primaryColor;
    }
  }

  void _addNewItem() {
    // Navigate to add item screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add new inventory item (placeholder)')),
    );
  }

  void _editItem(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${item['name']} (placeholder)')),
    );
  }

  void _adjustStock(Map<String, dynamic> item) {
    final TextEditingController quantityController = TextEditingController();
    String adjustmentType = 'add';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Adjust Stock - ${item['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Add Stock'),
                    value: 'add',
                    groupValue: adjustmentType,
                    onChanged: (value) => setState(() => adjustmentType = value!),
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Remove Stock'),
                    value: 'remove',
                    groupValue: adjustmentType,
                    onChanged: (value) => setState(() => adjustmentType = value!),
                  ),
                ),
              ],
            ),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 0;
              if (quantity > 0) {
                setState(() {
                  if (adjustmentType == 'add') {
                    item['quantity'] += quantity;
                  } else {
                    item['quantity'] -= quantity;
                  }
                  item['totalValue'] = item['quantity'] * item['unitPrice'];
                  item['lastUpdated'] = DateTime.now().toString().substring(0, 10);
                  _updateStockStatus(item);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Stock adjusted for ${item['name']}')),
                );
              }
            },
            child: const Text('Adjust'),
          ),
        ],
      ),
    );
  }

  void _updateStockStatus(Map<String, dynamic> item) {
    final quantity = item['quantity'];
    final minStock = item['minStock'];

    if (quantity <= minStock * 0.5) {
      item['status'] = 'Critical';
    } else if (quantity <= minStock) {
      item['status'] = 'Low Stock';
    } else {
      item['status'] = 'In Stock';
    }
  }

  void _viewHistory(Map<String, dynamic> item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('View history for ${item['name']} (placeholder)')),
    );
  }
}
