import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/data/providers/vendor_networking_provider.dart';
import 'package:eventease/features/vendor/presentation/widgets/vendor_profile_card.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/shared/models/vendor_collaboration_request_fixed.dart';

class VendorFindPartnersScreen extends StatefulWidget {
  const VendorFindPartnersScreen({super.key});

  @override
  State<VendorFindPartnersScreen> createState() => _VendorFindPartnersScreenState();
}

class _VendorFindPartnersScreenState extends State<VendorFindPartnersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedLocation = 'All';
  double _maxDistance = 50.0; // km

  final List<String> _categories = [
    'All',
    'Venues',
    'Catering',
    'Photography',
    'Music & DJ',
    'Decoration',
    'Transportation',
    'Beauty & Spa',
    'Other',
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<VendorProfileProvider>(context, listen: false);
      final networkingProvider = Provider.of<VendorNetworkingProvider>(context, listen: false);

      final currentId = profileProvider.vendorProfile?['id'] ?? auth.userId ?? '';
      if (currentId.isNotEmpty) {
        networkingProvider.setCurrentVendor(currentId);
      }
      networkingProvider.loadDiscoveryVendors();
    });
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
          'Find Partners',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<VendorNetworkingProvider>(
        builder: (context, provider, child) {
          final filteredVendors = _getFilteredVendors(provider);

          return Column(
            children: [
              // Search and Filters
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search vendors...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Filters Row
                    Row(
                      children: [
                        // Category Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Location Filter
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedLocation,
                            decoration: const InputDecoration(
                              labelText: 'Location',
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
                                _selectedLocation = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Distance Slider
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Maximum Distance: ${_maxDistance.round()} km',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Slider(
                          value: _maxDistance,
                          min: 5,
                          max: 200,
                          divisions: 39,
                          label: '${_maxDistance.round()} km',
                          onChanged: (value) {
                            setState(() {
                              _maxDistance = value;
                            });
                          },
                        ),
                      ],
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
                      '${filteredVendors.length} vendors found',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        // Reset filters
                        setState(() {
                          _searchController.clear();
                          _selectedCategory = 'All';
                          _selectedLocation = 'All';
                          _maxDistance = 50.0;
                        });
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear Filters'),
                    ),
                  ],
                ),
              ),

              // Vendors List
              Expanded(
                child: provider.isLoadingDiscovery
                    ? const Center(child: CircularProgressIndicator())
                    : filteredVendors.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredVendors.length,
                            itemBuilder: (context, index) {
                              final vendor = filteredVendors[index];
                              return VendorProfileCard(
                                vendor: vendor,
                                onTap: () => _showVendorDetails(vendor),
                                onConnectPressed: () => _sendConnectionRequest(vendor),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Vendor> _getFilteredVendors(VendorNetworkingProvider provider) {
    var vendors = provider.allVendors;

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      vendors = vendors.where((vendor) {
        return vendor.name.toLowerCase().contains(query) ||
               vendor.category.toLowerCase().contains(query) ||
               vendor.description.toLowerCase().contains(query) ||
               vendor.location.toLowerCase().contains(query) ||
               (vendor.tags?.any((tag) => tag.toLowerCase().contains(query)) ?? false);
      }).toList();
    }

    // Category filter
    if (_selectedCategory != 'All') {
      vendors = vendors.where((vendor) => vendor.category == _selectedCategory).toList();
    }

    // Location filter
    if (_selectedLocation != 'All') {
      vendors = vendors.where((vendor) => vendor.location.contains(_selectedLocation)).toList();
    }

    // Distance filter
    if (_maxDistance < 100 && vendors.length > 2) {
      final count = (vendors.length * (_maxDistance / 100)).round().clamp(1, vendors.length);
      vendors = vendors.take(count).toList();
    }

    return vendors;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'No vendors found',
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

  void _showVendorDetails(Vendor vendor) {
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
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              // Vendor Header
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      image: vendor.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(vendor.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: vendor.imageUrl == null
                          ? AppTheme.primaryColor.withOpacity(0.1)
                          : null,
                    ),
                    child: vendor.imageUrl == null
                        ? Center(
                            child: Text(
                              vendor.name[0].toUpperCase(),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vendor.category,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              vendor.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '(${vendor.reviewCount} reviews)',
                              style: const TextStyle(
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                vendor.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 20),

              // Contact Info
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildContactInfo(Icons.location_on, vendor.location),
              if (vendor.contactInfo['phone'] != null)
                _buildContactInfo(Icons.phone, vendor.contactInfo['phone']),
              if (vendor.contactInfo['email'] != null)
                _buildContactInfo(Icons.email, vendor.contactInfo['email']),

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
                        _sendConnectionRequest(vendor);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Connect'),
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

  Widget _buildContactInfo(IconData icon, String info) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Text(
            info,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _sendConnectionRequest(Vendor vendor) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider = Provider.of<VendorProfileProvider>(context, listen: false);
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);

    final currentId = profileProvider.vendorProfile?['id'] ?? auth.userId ?? 'vendor-me';
    final currentName = profileProvider.vendorProfile?['business_name'] ??
        vendorProvider.currentVendor?.name ??
        (auth.userName.isNotEmpty ? auth.userName : 'My Business');

    CollaborationType selectedType = CollaborationType.oneTime;
    final messageCtrl = TextEditingController(
      text: 'Hi ${vendor.name}, we would love to collaborate with you on upcoming wedding and corporate events!',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.handshake_outlined, color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Propose Collaboration',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Partner: ${vendor.name} (${vendor.category})',
                          style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Collaboration Type',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CollaborationType.values.map((type) {
                  final isSelected = selectedType == type;
                  String label = 'One-time Event';
                  if (type == CollaborationType.partnership) label = 'Long-term Partner';
                  if (type == CollaborationType.referral) label = 'Lead Referral';
                  if (type == CollaborationType.package) label = 'Joint Package';

                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.primaryColor : const Color(0xFF64748B),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (_) => setSheetState(() => selectedType = type),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text(
                'Proposal Message',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: messageCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe how you would like to collaborate...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    final request = VendorCollaborationRequest(
                      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
                      senderVendorId: currentId,
                      receiverVendorId: vendor.id,
                      senderVendorName: currentName,
                      receiverVendorName: vendor.name,
                      type: selectedType,
                      message: messageCtrl.text.trim(),
                      status: CollaborationRequestStatus.pending,
                      createdAt: DateTime.now(),
                    );

                    final provider = context.read<VendorNetworkingProvider>();
                    await provider.sendCollaborationRequest(request);

                    if (!context.mounted) return;
                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Collaboration proposal sent to ${vendor.name}!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Send Collaboration Proposal'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
