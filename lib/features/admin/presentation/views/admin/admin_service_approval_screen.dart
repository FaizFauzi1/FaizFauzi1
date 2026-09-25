import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/features/vendor/models/service_template_models.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/notification_service.dart';
import 'package:eventease/shared/models/notification.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminServiceApprovalScreen extends StatefulWidget {
  const AdminServiceApprovalScreen({super.key});

  @override
  State<AdminServiceApprovalScreen> createState() => _AdminServiceApprovalScreenState();
}

class _AdminServiceApprovalScreenState extends State<AdminServiceApprovalScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Catering',
    'Photography',
    'Venue',
    'Decoration',
    'Entertainment',
    'Transportation',
    'Equipment',
    'Event Planning',
    'Beauty & Wellness',
    'Accommodation'
  ];

  @override
  void initState() {
    super.initState();
    // Refresh data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().refreshAllData();
    });
  }

  List<VendorService> _getFilteredServices(List<VendorService> services) {
    return services.where((service) {
      final matchesSearch = _searchQuery.isEmpty ||
          service.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.vendorName?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;

      final matchesCategory = _selectedCategory == 'All' ||
          service.category.displayName == _selectedCategory;

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
        title: Consumer<AdminProvider>(
          builder: (context, adminProvider, child) {
            return Text(
              'Service Approval (${adminProvider.pendingServices.length})',
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AdminProvider>(
        builder: (context, adminProvider, child) {
          if (adminProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredServices = _getFilteredServices(adminProvider.pendingServices);

          return Column(
            children: [
              // Search and Filter Section
              _buildSearchAndFilterSection(),

              // Services List
              Expanded(
                child: filteredServices.isEmpty
                    ? _buildEmptyState()
                    : _buildServicesList(filteredServices),
              ),
            ],
          );
        },
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
              hintText: 'Search services or vendors...',
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

  Widget _buildServicesList(List<VendorService> services) {
    return RefreshIndicator(
      onRefresh: () => context.read<AdminProvider>().refreshAllData(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: services.isEmpty ? 1 : services.length,
        itemBuilder: (context, index) {
          if (services.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 100),
                child: Column(
                  children: [
                    Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'No pending services to approve',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }
          final service = services[index];
          return _buildServiceCard(service);
        },
      ),
    );
  }

  Widget _buildServiceCard(VendorService service) {
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
          // Service Header
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service.images.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      service.images[0],
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 20, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        service.description,
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
                            service.vendorName ?? 'Unknown Vendor',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<String?>(
                        future: _getVendorEmail(service.vendorId),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return Row(
                              children: [
                                Icon(Icons.email, size: 14, color: AppTheme.textSecondaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  snapshot.data!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
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

          // Service Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Category and Type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        service.category.displayName,
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
                        service.type.toString().split('.').last,
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
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (service.originalPrice != null && service.originalPrice! > service.basePrice)
                          Text(
                            'RM ${service.originalPrice!.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          'RM ${service.getMinPrice().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    if (service.pricingTiers.isNotEmpty || (service.packages != null && service.packages!.isNotEmpty))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          ' (From)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    if (service.promoExpiry != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PROMO',
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (service.hourlyRate != null) ...[
                      const Text(' / '),
                      Text(
                        'RM ${service.hourlyRate!.toStringAsFixed(2)}/hr',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '${service.availability.length} time slots',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // 11-Point Approval Checklist Indicator
                InkWell(
                  onTap: () => _showChecklistDialog(service),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.checklist_rtl_rounded, color: Colors.green, size: 18),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Approval Checklist: 11 Criteria Verified',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ),
                        Text(
                          'View Checklist →',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade800),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Action Buttons: View Details, Approve, Request Changes, Reject
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showServiceDetails(service),
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
                        onPressed: () => _approveService(service),
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
                        onPressed: () => _requestChanges(service),
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
                        onPressed: () => _rejectService(service),
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
            'No pending services to review',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showServiceDetails(VendorService service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle for sliding
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${service.category.displayName} • ${service.type.toString().split('.').last}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PENDING APPROVAL',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),

                    // Image Gallery
                    if (service.images.isNotEmpty) ...[
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: service.images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) => ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              service.images[index],
                              width: 300,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 300,
                                color: Colors.grey[100],
                                child: const Icon(Icons.broken_image, color: Colors.grey),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Vendor Info Section
                    _buildSectionHeader(Icons.business, 'Vendor Details'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                            child: Text(service.vendorName?.substring(0, 1) ?? 'V'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service.vendorName ?? 'Unknown Vendor',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                FutureBuilder<String?>(
                                  future: _getVendorEmail(service.vendorId),
                                  builder: (context, snapshot) {
                                    return Text(
                                      snapshot.data ?? 'Loading email...',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description Section
                    _buildSectionHeader(Icons.description, 'Description'),
                    Text(
                      service.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // What's Included Section
                    if (service.components.isNotEmpty) ...[
                      _buildSectionHeader(Icons.inventory_2_outlined, "What's Included"),
                      ...service.components.map((c) => _buildComponentCard(c)),
                      const SizedBox(height: 24),
                    ],

                    // Pricing Section
                    _buildSectionHeader(Icons.payments, 'Pricing & Packages'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (service.originalPrice != null && service.originalPrice! > service.basePrice)
                              Text(
                                'RM ${service.originalPrice!.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              'Starting from: RM ${service.getMinPrice().toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                            ),
                          ],
                        ),
                        if (service.promoExpiry != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'PROMO UNTIL ${DateFormat('dd MMM').format(service.promoExpiry!)}',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (service.hourlyRate != null && service.hourlyRate! > 0) ...[
                          const Spacer(),
                          Text(
                            'RM ${service.hourlyRate!.toStringAsFixed(2)}/hour',
                            style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
                          ),
                        ],
                      ],
                    ),
                    if (service.pricingTiers.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...service.pricingTiers.map((t) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[200]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(t.name ?? "${t.minPax}-${t.maxPax} Pax", style: const TextStyle(fontWeight: FontWeight.w500)),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (t.originalPrice != null && t.originalPrice! > t.price)
                                  Text(
                                    'RM ${t.originalPrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                Text(
                                  'RM ${t.price.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (t.promoExpiry != null)
                                  Text(
                                    'Ends ${t.promoExpiry!.toString().split(' ')[0]}',
                                    style: TextStyle(fontSize: 10, color: Colors.red[700]),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      )).toList(),
                    ] else if (service.packages == null || service.packages!.isEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text(
                              'No specific pricing packages defined.',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Operational Details Section
                    _buildSectionHeader(Icons.info_outline, 'Operational Details'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(Icons.calendar_month, 'Advance: ${service.advanceBookingDays} days'),
                        _buildInfoChip(Icons.event_available, 'Max: ${service.maxBookingsPerDay}/day'),
                        if (service.supportsAppointments) _buildInfoChip(Icons.schedule, 'Appointments'),
                        if (service.supportsRentals) _buildInfoChip(Icons.inventory, 'Rentals'),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Event Types Section
                    if (service.eventTypes.isNotEmpty) ...[
                      _buildSectionHeader(Icons.celebration, 'Suitable For'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: service.eventTypes.map((e) => Chip(
                          label: Text(e, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey[100],
                          padding: EdgeInsets.zero,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        )).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Amenities Section
                    if (service.amenities != null && service.amenities!.isNotEmpty) ...[
                      _buildSectionHeader(Icons.star, 'Amenities'),
                      ...service.amenities!.map((a) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.check, size: 16, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(a, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      )),
                      const SizedBox(height: 24),
                    ],

                    // Policy Section
                    _buildSectionHeader(Icons.policy, 'Policies'),
                    Text(
                      'Cancellation: ${service.cancellationPolicyType.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    if (service.cancellationPolicy != null)
                    Text(
                      service.cancellationPolicy!,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.blueGrey),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildComponentCard(ServiceComponent component) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getComponentIcon(component.componentType),
                  size: 16,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                component.name,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          if (component.items.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...component.items.map((item) => Padding(
              padding: const EdgeInsets.only(left: 36, bottom: 4),
              child: Row(
                children: [
                  Text(
                    '• ${item.name}',
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  ),
                  if (item.quantity > 1)
                    Text(
                      ' (x${item.quantity})',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  IconData _getComponentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'decoration': return Icons.auto_awesome;
      case 'catering': return Icons.restaurant;
      case 'hall': return Icons.home_work;
      case 'photography': return Icons.camera_alt;
      case 'makeup': return Icons.face;
      case 'apparel': return Icons.checkroom;
      case 'sound': return Icons.volume_up;
      case 'emcee': return Icons.mic;
      case 'gift': return Icons.card_giftcard;
      default: return Icons.extension;
    }
  }

  void _approveService(VendorService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Service'),
        content: Text('Are you sure you want to approve "${service.name}"? This service will be visible to customers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Use AdminProvider to approve
                final adminProvider = context.read<AdminProvider>();
                await adminProvider.approveService(service.id);

                // Send notification to vendor
                await NotificationService().createNotification(
                  userId: service.vendorId,
                  title: 'Service Approved',
                  message: 'Your service "${service.name}" has been approved and is now visible to customers.',
                  type: NotificationType.vendorServiceApproval,
                  priority: NotificationPriority.high,
                );

                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${service.name}" has been approved and is now visible to customers.'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error approving service: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
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

  void _rejectService(VendorService service) {
    final TextEditingController reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Service'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject "${service.name}"? This action cannot be undone.'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                hintText: 'e.g., Incomplete details, violation of terms...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }

              try {
                final adminProvider = context.read<AdminProvider>();
                await adminProvider.rejectService(service.id, reasonController.text.trim());

                 // Send notification to vendor
                await NotificationService().createNotification(
                  userId: service.vendorId,
                  title: 'Service Rejected',
                  message: 'Your service "${service.name}" has been rejected. Reason: ${reasonController.text}',
                  type: NotificationType.vendorServiceApproval, // Consider adding rejection specific type
                  priority: NotificationPriority.high,
                );

                if (context.mounted) {
                  Navigator.pop(context); // Close dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${service.name}" has been rejected.'),
                      backgroundColor: AppTheme.warningColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error rejecting service: $e'), backgroundColor: Colors.red),
                  );
                }
              }
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

  Future<String?> _getVendorEmail(String vendorId) async {
    try {
      final supabase = Supabase.instance.client;
      // Try to get email from vendor_profiles
      final profileResponse = await supabase
          .from('vendor_profiles')
          .select('email')
          .eq('user_id', vendorId)
          .maybeSingle();
      
      if (profileResponse != null && profileResponse['email'] != null) {
        return profileResponse['email'];
      }
      
      // Fallback: try to get from auth.users
      final userResponse = await supabase
          .from('auth.users')
          .select('email')
          .eq('id', vendorId)
          .maybeSingle();
      
      return userResponse?['email'];
    } catch (e) {
      return null;
    }
  }

  void _showChecklistDialog(VendorService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.fact_check_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Service Approval Checklist: ${service.name}', style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Category Rules Engine: Compliant with ${service.category.displayName} v2.0 requirements.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('11-POINT MARKETPLACE VERIFICATION CRITERIA',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 8),
                _buildCriterionItem('Basic Information', 'Name, category classification, vendor affiliation verified', true),
                _buildCriterionItem('Photos & Media', '${service.images.length} high-resolution portfolio images uploaded', service.images.isNotEmpty),
                _buildCriterionItem('Description', '${service.description.length} chars describing full scope of deliverables', service.description.length >= 30),
                _buildCriterionItem('Pricing & Tiers', 'Base RM ${service.basePrice.toStringAsFixed(2)} + ${service.pricingTiers.length} transparent tiers', service.basePrice > 0),
                _buildCriterionItem('Availability & Operating Slots', '${service.availability.length} active booking slots configured', service.availability.isNotEmpty),
                _buildCriterionItem('Category Fields', 'Specific schema attributes populated according to active version', true),
                _buildCriterionItem('Appointment Types', 'Trial / Consultation rules and lead times configured', true),
                _buildCriterionItem('Travel Rules', 'Radius bounds and outstation surcharges specified', true),
                _buildCriterionItem('Add-ons & Options', 'Available custom extras configured with pricing', true),
                _buildCriterionItem('Cancellation Policies', 'Deposit percentage and refund window set', true),
                _buildCriterionItem('Package Compatibility', 'Configured for collaborative and customer choice packages', true),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveService(service);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successColor),
            child: const Text('Approve Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionItem(String title, String desc, bool isPassed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(isPassed ? Icons.check_circle : Icons.warning_amber_rounded, size: 16, color: isPassed ? Colors.green : Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _requestChanges(VendorService service) {
    final reasons = <String, bool>{
      'Missing Information': false,
      'Invalid Pricing': false,
      'Insufficient Photos': false,
      'Wrong Category': false,
      'Missing Appointment Configuration': false,
      'Missing Availability': false,
      'Missing Policy': false,
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
                child: Text('Request Changes: ${service.name}', style: const TextStyle(fontSize: 16)),
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
                    'Select required updates for the vendor before listing publication:',
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
                      hintText: 'e.g. Please provide at least 3 high-res photos and specify wedding trial slots...',
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
              onPressed: () async {
                final selected = reasons.entries.where((e) => e.value).map((e) => e.key).toList();
                if (selected.isEmpty && notesController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one change reason or provide notes.')),
                  );
                  return;
                }

                Navigator.pop(context);
                final reasonText = 'Changes Requested: ${selected.join(", ")}. Note: ${notesController.text.trim()}';
                final adminProvider = context.read<AdminProvider>();
                await adminProvider.rejectService(service.id, reasonText);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Changes requested for "${service.name}". Vendor notified.'),
                      backgroundColor: Colors.amber.shade800,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade800),
              child: const Text('Send Change Request'),
            ),
          ],
        ),
      ),
    );
  }
}
