import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_networking_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/shared/widgets/marketplace_item_card.dart';
import 'package:eventease/shared/models/vendor_marketplace_item.dart';

class VendorMarketplaceScreen extends StatefulWidget {
  const VendorMarketplaceScreen({super.key});

  @override
  State<VendorMarketplaceScreen> createState() => _VendorMarketplaceScreenState();
}

class _VendorMarketplaceScreenState extends State<VendorMarketplaceScreen> {
  final TextEditingController _searchController = TextEditingController();
  MarketplaceItemType? _selectedType;
  String? _selectedCategory = 'All';
  double _maxPrice = 50000.0; // RM 50,000
  String? _selectedLocation = 'All';

  final List<String> _categories = [
    'All',
    'wedding',
    'corporate',
    'birthday',
    'photography',
    'catering',
    'venue',
    'music',
    'decoration',
  ];

  final List<String> _locations = [
    'All',
    'Kuala Lumpur',
    'Petaling Jaya',
    'Shah Alam',
    'Klang',
    'Subang Jaya',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Marketplace',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFiltersDialog(),
            color: AppTheme.primaryColor,
          ),
        ],
      ),
      body: Consumer<VendorNetworkingProvider>(
        builder: (context, provider, child) {
          final filteredItems = _getFilteredItems(provider);

          return Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search marketplace...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),

              // Featured Items
              if (_searchController.text.isEmpty && _selectedType == null && (_selectedCategory == null || _selectedCategory == 'All'))
                Container(
                  height: 480,
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: const Text(
                          'Featured Items',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: provider.getFeaturedMarketplaceItems().length,
                          itemBuilder: (context, index) {
                            final item = provider.getFeaturedMarketplaceItems()[index];
                            return Container(
                              width: 280,
                              margin: const EdgeInsets.only(right: 12),
                              child: MarketplaceItemCard(
                                item: item,
                                onTap: () => _showItemDetails(item),
                                onContactPressed: () => _contactVendor(item),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              // Results Count
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppTheme.backgroundColor,
                child: Row(
                  children: [
                    Text(
                      '${filteredItems.length} items found',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _selectedType = null;
                          _selectedCategory = null;
                          _maxPrice = 50000.0;
                          _selectedLocation = null;
                        });
                      },
                      child: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),

              // Items Grid
              Expanded(
                child: provider.isLoadingMarketplace
                    ? const Center(child: CircularProgressIndicator())
                    : filteredItems.isEmpty
                        ? _buildEmptyState()
                        : GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.45,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final item = filteredItems[index];
                              return MarketplaceItemCard(
                                item: item,
                                onTap: () => _showItemDetails(item),
                                onContactPressed: () => _contactVendor(item),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  List<VendorMarketplaceItem> _getFilteredItems(VendorNetworkingProvider provider) {
    return provider.searchMarketplaceItems(
      _searchController.text,
      type: _selectedType,
      category: _selectedCategory == 'All' ? null : _selectedCategory,
      maxPrice: _maxPrice,
      location: _selectedLocation == 'All' ? null : _selectedLocation,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No items found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Try adjusting your search criteria',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showFiltersDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // Type Filter
              const Text(
                'Item Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: MarketplaceItemType.values.map((type) {
                  final isSelected = _selectedType == type;
                  final displayName = _getTypeDisplayName(type);
                  return FilterChip(
                    label: Text(displayName),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedType = selected ? type : null;
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Category Filter
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category == 'All' ? 'All Categories' : category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Price Range
              const Text(
                'Maximum Price',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text('RM ${_maxPrice.toInt()}'),
              Slider(
                value: _maxPrice,
                min: 100,
                max: 50000,
                divisions: 99,
                label: 'RM ${_maxPrice.toInt()}',
                onChanged: (value) {
                  setState(() {
                    _maxPrice = value;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Location Filter
              const Text(
                'Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: _locations.map((location) {
                  return DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value;
                  });
                },
              ),
              const SizedBox(height: 30),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    this.setState(() {}); // Refresh the main screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Apply Filters'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showItemDetails(VendorMarketplaceItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              // Images
              if (item.images.isNotEmpty)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(item.images.first),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Title and Price
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'RM ${item.currentPrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Vendor and Type
              Row(
                children: [
                  Text(
                    item.vendorName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      item.typeDisplayName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 20),

              // Specifications
              if (item.specifications.isNotEmpty) ...[
                const Text(
                  'Specifications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...item.specifications.entries.map((spec) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            '${spec.key}:',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            spec.value,
                            style: const TextStyle(
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],

              // Tags
              if (item.tags.isNotEmpty) ...[
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.visibility,
                      label: 'Views',
                      value: item.viewCount.toString(),
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      icon: Icons.message,
                      label: 'Inquiries',
                      value: item.inquiryCount.toString(),
                    ),
                  ),
                  if (item.location != null)
                    Expanded(
                      child: _buildStatItem(
                        icon: Icons.location_on,
                        label: 'Location',
                        value: item.location!,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _contactVendor(item);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Contact Vendor'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
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

  void _contactVendor(VendorMarketplaceItem item) {
    // In a real app, this would open a contact form or messaging
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contacting ${item.vendorName}...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showAddItemDialog() {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final currentVendor = vendorProvider.currentVendor;

    if (currentVendor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in as a vendor to add items'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    MarketplaceItemType selectedType = MarketplaceItemType.service;
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController priceController = TextEditingController();
    final TextEditingController discountController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    bool isFeatured = false;

    // Dynamic fields
    final List<Map<String, TextEditingController>> specControllers = [];
    final List<TextEditingController> imageControllers = [TextEditingController()];
    final List<TextEditingController> tagControllers = [TextEditingController()];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              Row(
                children: [
                  const Text(
                    'Add Marketplace Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type
                      const Text('Item Type', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<MarketplaceItemType>(
                        value: selectedType,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        items: MarketplaceItemType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_getTypeDisplayName(type)),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => selectedType = value!),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      const Text('Title', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter item title',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Enter item description',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Price
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Price (RM)', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: '0.00',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Discount Price (RM)', style: TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: discountController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    hintText: 'Optional',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Images
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Images (URLs)', style: TextStyle(fontWeight: FontWeight.w500)),
                          IconButton(
                            onPressed: () => setState(() => imageControllers.add(TextEditingController())),
                            icon: const Icon(Icons.add),
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...imageControllers.map((controller) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'https://example.com/image.jpg',
                                ),
                              ),
                            ),
                            if (imageControllers.length > 1)
                              IconButton(
                                onPressed: () => setState(() => imageControllers.remove(controller)),
                                icon: const Icon(Icons.remove, color: Colors.red),
                              ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),

                      // Specifications
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Specifications', style: TextStyle(fontWeight: FontWeight.w500)),
                          IconButton(
                            onPressed: () => setState(() => specControllers.add({
                              'key': TextEditingController(),
                              'value': TextEditingController(),
                            })),
                            icon: const Icon(Icons.add),
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...specControllers.map((controllers) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controllers['key'],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Key (e.g., Capacity)',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: controllers['value'],
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'Value (e.g., 100 guests)',
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() => specControllers.remove(controllers)),
                              icon: const Icon(Icons.remove, color: Colors.red),
                            ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),

                      // Tags
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tags', style: TextStyle(fontWeight: FontWeight.w500)),
                          IconButton(
                            onPressed: () => setState(() => tagControllers.add(TextEditingController())),
                            icon: const Icon(Icons.add),
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...tagControllers.map((controller) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: 'e.g., wedding, photography',
                                ),
                              ),
                            ),
                            if (tagControllers.length > 1)
                              IconButton(
                                onPressed: () => setState(() => tagControllers.remove(controller)),
                                icon: const Icon(Icons.remove, color: Colors.red),
                              ),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),

                      // Location
                      const Text('Location', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Kuala Lumpur',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Featured
                      Row(
                        children: [
                          Checkbox(
                            value: isFeatured,
                            onChanged: (value) => setState(() => isFeatured = value ?? false),
                          ),
                          const Text('Mark as featured item'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty || descriptionController.text.isEmpty || priceController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final specifications = <String, dynamic>{};
                    for (final controllers in specControllers) {
                      final key = controllers['key']!.text.trim();
                      final value = controllers['value']!.text.trim();
                      if (key.isNotEmpty && value.isNotEmpty) {
                        specifications[key] = value;
                      }
                    }

                    final images = imageControllers
                        .map((c) => c.text.trim())
                        .where((url) => url.isNotEmpty)
                        .toList();

                    final tags = tagControllers
                        .map((c) => c.text.trim().toLowerCase())
                        .where((tag) => tag.isNotEmpty)
                        .toList();

                    final item = VendorMarketplaceItem(
                      id: 'market_${DateTime.now().millisecondsSinceEpoch}',
                      vendorId: currentVendor.id,
                      vendorName: currentVendor.name,
                      type: selectedType,
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      price: double.parse(priceController.text),
                      discountedPrice: discountController.text.isNotEmpty ? discountController.text : null,
                      images: images.isNotEmpty ? images : ['https://via.placeholder.com/300x200?text=No+Image'],
                      status: MarketplaceItemStatus.pending,
                      specifications: specifications,
                      tags: tags,
                      createdAt: DateTime.now(),
                      location: locationController.text.trim().isNotEmpty ? locationController.text.trim() : null,
                      featured: isFeatured,
                    );

                    final provider = context.read<VendorNetworkingProvider>();
                    await provider.createMarketplaceItem(item);

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Item submitted for admin review!'),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Submit for Review'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeDisplayName(MarketplaceItemType type) {
    switch (type) {
      case MarketplaceItemType.service:
        return 'Service';
      case MarketplaceItemType.product:
        return 'Product';
      case MarketplaceItemType.package:
        return 'Package';
      case MarketplaceItemType.promotion:
        return 'Promotion';
    }
  }
}
