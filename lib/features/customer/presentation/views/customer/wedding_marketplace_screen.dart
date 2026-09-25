import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/customer/data/providers/marketplace_provider.dart';
import 'package:eventease/features/customer/data/models/transfer_listing.dart';
import 'package:eventease/features/customer/data/models/item_listing.dart';
import 'package:eventease/features/customer/presentation/views/customer/listing_detail_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/create_transfer_listing_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/create_item_listing_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeddingMarketplaceScreen extends StatefulWidget {
  const WeddingMarketplaceScreen({super.key});

  @override
  State<WeddingMarketplaceScreen> createState() => _WeddingMarketplaceScreenState();
}

class _WeddingMarketplaceScreenState extends State<WeddingMarketplaceScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // Filters
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedLocation;
  double _minPrice = 0;
  double _maxPrice = 50000;
  DateTimeRange? _selectedDateRange;

  // Categories list
  final List<String> _bookingCategories = [
    'Wedding venue',
    'Bridal package',
    'Catering package',
    'Photography/videography',
    'Makeup artist',
    'Decoration package',
    'Entertainment services',
    'Wedding planner services'
  ];

  final List<String> _itemCategories = [
    'Bridal wear',
    'Groom suit',
    'Wedding shoes',
    'Accessories',
    'Doorgifts',
    'Wedding decorations',
    'Invitation cards',
    'Wedding props',
    'Other wedding items'
  ];

  final List<String> _locations = [
    'Kuala Lumpur',
    'Petaling Jaya',
    'Shah Alam',
    'Penang',
    'Johor Bahru',
    'Malacca',
    'Ipoh'
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedCategory = null; // Reset category filter on tab switch
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<MarketplaceProvider>(context, listen: false);
      provider.loadTransferListings();
      provider.loadItemListings();
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        provider.loadMyListings(user.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isBookingTab = _tabController.index == 0;
            final categories = isBookingTab ? _bookingCategories : _itemCategories;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Listings',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategory = null;
                            _selectedLocation = null;
                            _minPrice = 0;
                            _maxPrice = 50000;
                            _selectedDateRange = null;
                          });
                        },
                        child: const Text('Reset All'),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Category Dropdown
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    hint: const Text('Select Category'),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: categories.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        _selectedCategory = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location Dropdown
                  const Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedLocation,
                    hint: const Text('Select Location'),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _locations.map((loc) {
                      return DropdownMenuItem(value: loc, child: Text(loc));
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        _selectedLocation = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Price Range Slider
                  Text(
                    'Price Range (RM ${_minPrice.round()} - RM ${_maxPrice.round()})',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  RangeSlider(
                    values: RangeValues(_minPrice, _maxPrice),
                    min: 0,
                    max: 50000,
                    divisions: 100,
                    activeColor: AppTheme.primaryColor,
                    labels: RangeLabels(
                      'RM ${_minPrice.round()}',
                      'RM ${_maxPrice.round()}',
                    ),
                    onChanged: (values) {
                      setModalState(() {
                        _minPrice = values.start;
                        _maxPrice = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date Filter (Only for booking transfers)
                  if (isBookingTab) ...[
                    const Text('Event Date Range', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                          initialDateRange: _selectedDateRange,
                        );
                        if (picked != null) {
                          setModalState(() {
                            _selectedDateRange = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDateRange == null
                                  ? 'Select Date Range'
                                  : '${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}',
                              style: TextStyle(
                                color: _selectedDateRange == null ? Colors.grey.shade600 : Colors.black,
                              ),
                            ),
                            const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  ElevatedButton(
                    onPressed: () {
                      setState(() {}); // Apply filters to parent screen state
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply Filters', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Wedding Marketplace',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Booking Transfers'),
            Tab(text: 'Wedding Items'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search & Filter Header Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search listings...',
                        prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (_selectedCategory != null || _selectedLocation != null || _selectedDateRange != null)
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.tune,
                      color: (_selectedCategory != null || _selectedLocation != null || _selectedDateRange != null)
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tab content views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBookingTransfersTab(),
                _buildWeddingItemsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateTransferListingScreen()),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateItemListingScreen()),
            );
          }
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tabController.index == 0 ? 'Transfer Booking' : 'Sell Item',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBookingTransfersTab() {
    return Consumer<MarketplaceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          print('*****************************************************');
          print('WeddingMarketplaceScreen Error (Transfers): ${provider.errorMessage}');
          print('*****************************************************');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${provider.errorMessage}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Apply filters
        var filteredList = provider.transferListings.where((l) {
          final matchesSearch = l.vendorName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              l.packageDescription.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategory == null || l.category == _selectedCategory;
          final matchesLocation = _selectedLocation == null; // Add location logic if booking details contain it
          final matchesPrice = l.sellingPrice >= _minPrice && l.sellingPrice <= _maxPrice;
          
          bool matchesDate = true;
          if (_selectedDateRange != null) {
            matchesDate = l.eventDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
                l.eventDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
          }

          return matchesSearch && matchesCategory && matchesLocation && matchesPrice && matchesDate;
        }).toList();

        if (filteredList.isEmpty) {
          return const Center(
            child: Text('No booking transfers found matching filters.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final item = filteredList[index];
            return _buildTransferCard(item);
          },
        );
      },
    );
  }

  Widget _buildWeddingItemsTab() {
    return Consumer<MarketplaceProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.errorMessage != null) {
          print('*****************************************************');
          print('WeddingMarketplaceScreen Error (Items): ${provider.errorMessage}');
          print('*****************************************************');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${provider.errorMessage}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Apply filters
        var filteredList = provider.itemListings.where((l) {
          final matchesSearch = l.itemName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              l.description.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesCategory = _selectedCategory == null || l.category == _selectedCategory;
          final matchesLocation = _selectedLocation == null || l.location.toLowerCase().contains(_selectedLocation!.toLowerCase());
          final matchesPrice = l.price >= _minPrice && l.price <= _maxPrice;

          return matchesSearch && matchesCategory && matchesLocation && matchesPrice;
        }).toList();

        if (filteredList.isEmpty) {
          return const Center(
            child: Text('No wedding items found matching filters.'),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final item = filteredList[index];
            return _buildItemCard(item);
          },
        );
      },
    );
  }

  Widget _buildTransferCard(TransferListing listing) {
    final hasVendor = listing.vendorId != null;
    final formattedDate = DateFormat('MMM dd, yyyy').format(listing.eventDate);
    final discount = ((listing.originalBookingPrice - listing.sellingPrice) / listing.originalBookingPrice * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailScreen(transferListing: listing),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                  child: listing.images.isNotEmpty
                      ? Image.network(listing.images.first, height: 160, width: double.infinity, fit: BoxFit.cover)
                      : Container(color: Colors.grey.shade200, height: 160, width: double.infinity, child: const Icon(Icons.image, size: 50)),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: hasVendor ? AppTheme.successColor : Colors.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      hasVendor ? 'EventEase Verified' : 'External - Verification Required',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (discount > 0)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '-$discount%',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        listing.category.toUpperCase(),
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 0.5),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    listing.vendorName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    listing.packageDescription,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RM ${listing.originalBookingPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: AppTheme.textSecondaryColor,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            'RM ${listing.sellingPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Consumer<MarketplaceProvider>(
                        builder: (context, mProvider, child) {
                          final isFav = mProvider.isListingFavorited(listing.id);
                          return IconButton(
                            icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : AppTheme.textSecondaryColor),
                            onPressed: () => mProvider.toggleFavorite(listing.id),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(ItemListing item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ListingDetailScreen(itemListing: item),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
                    child: item.images.isNotEmpty
                        ? Image.network(item.images.first, height: double.infinity, width: double.infinity, fit: BoxFit.cover)
                        : Container(color: Colors.grey.shade200, width: double.infinity, child: const Icon(Icons.image, size: 40)),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        item.condition == ItemCondition.newCondition ? 'New' : item.condition == ItemCondition.likeNew ? 'Like New' : 'Used',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Details
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category.toUpperCase(),
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 9, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.itemName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'RM ${item.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Consumer<MarketplaceProvider>(
                        builder: (context, mProvider, child) {
                          final isFav = mProvider.isListingFavorited(item.id);
                          return SizedBox(
                            width: 32,
                            height: 32,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, size: 20, color: isFav ? Colors.red : AppTheme.textSecondaryColor),
                              onPressed: () => mProvider.toggleFavorite(item.id),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
