import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/utils/constants/image_constants.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';
import 'package:eventease/shared/widgets/app_footer.dart';
import 'package:eventease/core/services/analytics_service.dart';

class VendorProfileScreen extends StatefulWidget {
  final String? vendorName;
  final String? vendorId;
  final List<VendorService>? services;

  const VendorProfileScreen({
    super.key,
    this.vendorName,
    this.vendorId,
    this.services,
  });

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  String _selectedCategory = 'All';
  late List<VendorService> _filteredServices;
  bool _isLoading = false;
  String? _loadedVendorName;
  Map<String, dynamic>? _vendorData;

  @override
  void initState() {
    super.initState();
    _loadedVendorName = widget.vendorName;
    if (widget.vendorId != null) {
      AnalyticsService().trackVendorViewed(
        vendorId: widget.vendorId!,
        vendorName: widget.vendorName ?? 'Vendor Profile',
      );
    }
    if (widget.services != null) {
      _filteredServices = widget.services!
          .where((s) => s.active && s.approvalStatus == ApprovalStatus.approved)
          .toList();
    } else if (widget.vendorId != null && (widget.vendorName == null || widget.vendorName!.isEmpty)) {
      _isLoading = true;
      _fetchVendorData(widget.vendorId!);
      _filteredServices = [];
    } else {
      _filteredServices = [];
    }
  }

  Future<void> _fetchVendorData(String id) async {
    try {
      final client = (await Supabase.instance).client;
      final response = await client
          .from('vendor_profiles')
          .select('*, vendor_services(*)')
          .eq('id', id)
          .single();
      
      if (response != null) {
        setState(() {
          _vendorData = response;
          _loadedVendorName = response['business_name'] ?? 'Vendor';
          if (response['vendor_services'] != null) {
            final servicesList = response['vendor_services'] as List;
            final List<VendorService> loadedServices = servicesList
                .map((s) => VendorService.fromJson(s))
                .where((s) => s.active && s.approvalStatus == ApprovalStatus.approved)
                .toList();
            _filteredServices = loadedServices;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching vendor: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadedVendorName = widget.vendorName ?? 'Unknown Vendor';
          _filteredServices = [];
        });
      }
    }
  }

  void _filterServicesByCategory(String category) {
    setState(() {
      _selectedCategory = category;
      final sourceList = widget.services ?? [];
      final activeApprovedList = sourceList
          .where((s) => s.active && s.approvalStatus == ApprovalStatus.approved)
          .toList();
      if (category == 'All') {
        _filteredServices = activeApprovedList;
      } else {
        _filteredServices = activeApprovedList
            .where((service) => service.category.id == category)
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_loadedVendorName ?? 'Vendor Profile', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
      ),
      backgroundColor: AppTheme.backgroundColor,
      body: ResponsiveWrapper(
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: ResponsiveUtils.getScreenPadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor header
              Row(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                    child: const Icon(Icons.store, color: AppTheme.primaryColor, size: 36),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_loadedVendorName ?? 'Vendor', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green[700], size: 18),
                            const SizedBox(width: 4),
                            const Text('Verified Vendor', style: TextStyle(color: Colors.green, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // About section
              const Text('About', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              const Text(
                'This is a sample vendor profile. Here you can show vendor description, contact info, ratings, and more.',
                style: TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 24),

              // Category Filter Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Filter by Category',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
                        ),
                        filled: true,
                        fillColor: Colors.grey.withOpacity(0.05),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'All',
                          child: Text('All Categories'),
                        ),
                        ...EventCategory.values.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Row(
                              children: [
                                Icon(category.icon, size: 16, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Text(category.displayName),
                              ],
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _filterServicesByCategory(value);
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Services section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(
                    '${_filteredServices.length} service${_filteredServices.length != 1 ? 's' : ''}',
                    style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_filteredServices.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'No services found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Try selecting a different category',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: ResponsiveUtils.isWide(context) ? 160 : 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = _filteredServices[index];
                      return _buildServiceCard(
                        service.name,
                        'from RM ${service.getMinPrice().toStringAsFixed(2)}',
                        service.images.isNotEmpty ? service.images[0] : null,
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              // Reviews section
              const Text('Reviews', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              _buildReviewTile('Excellent vendor, highly recommended!', 'Alicia', 5),
              _buildReviewTile('Great service and communication.', 'Ben', 4),
              const SizedBox(height: 32),
              if (kIsWeb) const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(String title, String price, [String? imageUrl]) {
    return Container(
      width: 110,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl ?? ImageConstants.cateringPlaceholder,
                height: 50,
                width: 100,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 50,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.image,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2),
            Text(price, style: const TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewTile(String review, String user, int rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.primaryColor.withOpacity(0.18),
            child: Text(user[0], style: const TextStyle(color: AppTheme.primaryColor)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(user, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Row(
                      children: List.generate(
                        rating,
                        (index) => const Icon(Icons.star, color: Colors.amber, size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(review, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
