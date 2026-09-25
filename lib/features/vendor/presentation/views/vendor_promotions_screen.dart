import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/subscription_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/shared/widgets/upgrade_required_overlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VendorPromotionsScreen extends StatefulWidget {
  const VendorPromotionsScreen({super.key});

  @override
  State<VendorPromotionsScreen> createState() => _VendorPromotionsScreenState();
}

class _VendorPromotionsScreenState extends State<VendorPromotionsScreen> {
  final List<Map<String, dynamic>> _promotions = [
    {
      'name': 'Wedding Discount',
      'type': 'Percentage',
      'value': 10,
      'startDate': '2024-03-01',
      'endDate': '2024-03-31',
      'status': 'Active',
      'target': 'All Customers',
      'description': '10% off on wedding packages'
    },
    {
      'name': 'Corporate Special',
      'type': 'Fixed Amount',
      'value': 500,
      'startDate': '2024-03-15',
      'endDate': '2024-03-20',
      'status': 'Active',
      'target': 'Corporate Clients',
      'description': 'RM500 off on corporate events'
    },
    {
      'name': 'Birthday Promo',
      'type': 'Buy One Get One',
      'value': 0,
      'startDate': '2024-04-01',
      'endDate': '2024-04-30',
      'status': 'Inactive',
      'target': 'All Customers',
      'description': 'Buy one birthday package, get one free'
    },
  ];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedType = 'Percentage';
  String _selectedTarget = 'All Customers';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context);
    final isLocked = !subscriptionProvider.canUsePromoTools;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Promotions & Discounts',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _showAddPromotionDialog,
          ),
        ],
      ),
      body: UpgradeRequiredOverlay(
        isLocked: isLocked,
        title: 'Unlock Promotional Tools',
        description: 'Upgrade to Pro or Business tier to run targeted promotions, offer discounts, and boost your sales.',
        onUpgradePressed: () {
          final vendorId = Provider.of<VendorProvider>(context, listen: false).currentVendor?.id;
          Navigator.pushNamed(context, '/vendor-subscriptions', arguments: vendorId);
        },
        child: Column(
          children: [
            // Summary cards
            IgnorePointer(
              ignoring: isLocked,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    _buildSummaryCard(
                      'Active Promotions',
                      _promotions.where((p) => p['status'] == 'Active').length.toString(),
                      Icons.local_offer,
                      AppTheme.successColor,
                    ),
                    const SizedBox(width: 12),
                    _buildSummaryCard(
                      'Total Promotions',
                      _promotions.length.toString(),
                      Icons.campaign,
                      AppTheme.primaryColor,
                    ),
                  ],
                ),
              ),
            ),
  
            // Filter chips
            IgnorePointer(
              ignoring: isLocked,
              child: SizedBox(
                height: 50,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip('All'),
                    _buildFilterChip('Active'),
                    _buildFilterChip('Inactive'),
                    _buildFilterChip('Percentage'),
                    _buildFilterChip('Fixed Amount'),
                    _buildFilterChip('Buy One Get One'),
                  ],
                ),
              ),
            ),
  
            // Promotions list
            Expanded(
              child: IgnorePointer(
                ignoring: isLocked,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _promotions.length,
                  itemBuilder: (context, index) {
                    return _buildPromotionCard(_promotions[index], index);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
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
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(filter),
        selected: false, // For simplicity, not implementing filter logic
        onSelected: (selected) {
          // Implement filter logic here
        },
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> promotion, int index) {
    Color statusColor = promotion['status'] == 'Active' ? AppTheme.successColor : AppTheme.textSecondaryColor;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                promotion['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  promotion['status'],
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            promotion['description'],
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPromotionDetail('Type', '${promotion['type']} - ${promotion['value']}${promotion['type'] == 'Percentage' ? '%' : 'RM'}'),
              const SizedBox(width: 16),
              _buildPromotionDetail('Target', promotion['target']),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPromotionDetail('Start', promotion['startDate']),
              const SizedBox(width: 16),
              _buildPromotionDetail('End', promotion['endDate']),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _editPromotion(index),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _duplicatePromotion(index),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Duplicate'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _deletePromotion(index),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromotionDetail(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPromotionDialog() {
    _nameController.clear();
    _valueController.clear();
    _descriptionController.clear();
    _selectedType = 'Percentage';
    _selectedTarget = 'All Customers';
    _startDate = null;
    _endDate = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Promotion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Promotion Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'Percentage', child: Text('Percentage Discount')),
                    DropdownMenuItem(value: 'Fixed Amount', child: Text('Fixed Amount Discount')),
                    DropdownMenuItem(value: 'Buy One Get One', child: Text('Buy One Get One')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                  },
                  decoration: const InputDecoration(labelText: 'Discount Type'),
                ),
                const SizedBox(height: 16),
                if (_selectedType != 'Buy One Get One')
                  TextField(
                    controller: _valueController,
                    decoration: InputDecoration(
                      labelText: _selectedType == 'Percentage' ? 'Discount Percentage (%)' : 'Discount Amount (RM)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTarget,
                  items: const [
                    DropdownMenuItem(value: 'All Customers', child: Text('All Customers')),
                    DropdownMenuItem(value: 'New Customers', child: Text('New Customers')),
                    DropdownMenuItem(value: 'Returning Customers', child: Text('Returning Customers')),
                    DropdownMenuItem(value: 'Corporate Clients', child: Text('Corporate Clients')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedTarget = value!);
                  },
                  decoration: const InputDecoration(labelText: 'Target Audience'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_startDate == null ? 'Start Date' : _startDate!.toString().split(' ')[0]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_endDate == null ? 'End Date' : _endDate!.toString().split(' ')[0]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _descriptionController.text.isNotEmpty) {
                  setState(() {
                    _promotions.add({
                      'name': _nameController.text,
                      'type': _selectedType,
                      'value': _selectedType == 'Buy One Get One' ? 0 : int.tryParse(_valueController.text) ?? 0,
                      'startDate': _startDate?.toString().split(' ')[0] ?? '',
                      'endDate': _endDate?.toString().split(' ')[0] ?? '',
                      'status': 'Active',
                      'target': _selectedTarget,
                      'description': _descriptionController.text,
                    });
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Promotion added successfully')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _editPromotion(int index) {
    final promotion = _promotions[index];
    _nameController.text = promotion['name'];
    _valueController.text = promotion['value'].toString();
    _descriptionController.text = promotion['description'];
    _selectedType = promotion['type'];
    _selectedTarget = promotion['target'];
    _startDate = DateTime.tryParse(promotion['startDate']);
    _endDate = DateTime.tryParse(promotion['endDate']);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Promotion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Promotion Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'Percentage', child: Text('Percentage Discount')),
                    DropdownMenuItem(value: 'Fixed Amount', child: Text('Fixed Amount Discount')),
                    DropdownMenuItem(value: 'Buy One Get One', child: Text('Buy One Get One')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                  },
                  decoration: const InputDecoration(labelText: 'Discount Type'),
                ),
                const SizedBox(height: 16),
                if (_selectedType != 'Buy One Get One')
                  TextField(
                    controller: _valueController,
                    decoration: InputDecoration(
                      labelText: _selectedType == 'Percentage' ? 'Discount Percentage (%)' : 'Discount Amount (RM)',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedTarget,
                  items: const [
                    DropdownMenuItem(value: 'All Customers', child: Text('All Customers')),
                    DropdownMenuItem(value: 'New Customers', child: Text('New Customers')),
                    DropdownMenuItem(value: 'Returning Customers', child: Text('Returning Customers')),
                    DropdownMenuItem(value: 'Corporate Clients', child: Text('Corporate Clients')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedTarget = value!);
                  },
                  decoration: const InputDecoration(labelText: 'Target Audience'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_startDate == null ? 'Start Date' : _startDate!.toString().split(' ')[0]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? _startDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_endDate == null ? 'End Date' : _endDate!.toString().split(' ')[0]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty && _descriptionController.text.isNotEmpty) {
                  setState(() {
                    _promotions[index] = {
                      'name': _nameController.text,
                      'type': _selectedType,
                      'value': _selectedType == 'Buy One Get One' ? 0 : int.tryParse(_valueController.text) ?? 0,
                      'startDate': _startDate?.toString().split(' ')[0] ?? '',
                      'endDate': _endDate?.toString().split(' ')[0] ?? '',
                      'status': promotion['status'],
                      'target': _selectedTarget,
                      'description': _descriptionController.text,
                    };
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Promotion updated successfully')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _duplicatePromotion(int index) {
    final promotion = _promotions[index];
    setState(() {
      _promotions.add({
        ...promotion,
        'name': '${promotion['name']} (Copy)',
        'status': 'Inactive',
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Promotion duplicated successfully')),
    );
  }

  void _deletePromotion(int index) {
    setState(() {
      _promotions.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Promotion deleted successfully')),
    );
  }
}
