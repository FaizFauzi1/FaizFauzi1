import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:eventease/features/organizer/data/models/expo_summary.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_expo_detail_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_application_status_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_exhibitor_payment_screen.dart';
import 'package:eventease/features/vendor/presentation/views/exhibition/vendor_exhibition_dashboard_screen.dart';

class VendorJoinExhibitorScreen extends StatefulWidget {
  const VendorJoinExhibitorScreen({super.key});

  static const routeName = '/vendor-join-expo';

  @override
  State<VendorJoinExhibitorScreen> createState() => _VendorJoinExhibitorScreenState();
}

class _VendorJoinExhibitorScreenState extends State<VendorJoinExhibitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  List<ExpoSummary> _availableExpos = [];
  List<ExhibitorVendor> _myApplications = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _sortBy = 'date_asc'; // 'date_asc', 'date_desc', 'name_asc', 'slots_desc'

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'date_desc':
        return 'Date: Furthest';
      case 'name_asc':
        return 'Name: A–Z';
      case 'slots_desc':
        return 'Slots: Most';
      case 'date_asc':
      default:
        return 'Date: Nearest';
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Expos from Supabase (all active & platform expos)
      final summaries = await OrganizerRepository.instance.fetchPublicExpoSummaries();
      _availableExpos = summaries;

      // 2. Pre-fill & Fetch Existing Applications
      final vendorProfile = Provider.of<VendorProfileProvider>(context, listen: false).vendorProfile;
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      final auth = Provider.of<AuthProvider>(context, listen: false);

      final currentVendor = vendorProvider.currentVendor;
      final effectiveEmail = vendorProfile?['email'] ?? currentVendor?.email ?? auth.userEmail ?? '';
      final effectiveId = AdminImpersonationService.instance.effectiveUserId ?? auth.userId ?? '';

      final apps = await OrganizerRepository.instance.fetchVendorApplications(
        effectiveEmail.isNotEmpty ? effectiveEmail : effectiveId,
      );

      _myApplications = apps;
    } catch (e) {
      debugPrint('Error loading expo data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<ExhibitorVendor> get _activeApplications {
    return _myApplications.where((a) =>
        a.status == ExhibitorStatus.pending ||
        a.status == ExhibitorStatus.underReview ||
        a.status == ExhibitorStatus.infoRequested ||
        a.status == ExhibitorStatus.approved ||
        a.status == ExhibitorStatus.paymentPending ||
        a.status == ExhibitorStatus.rejected).toList();
  }

  List<ExhibitorVendor> get _confirmedExhibitions {
    return _myApplications.where((a) =>
        a.status == ExhibitorStatus.confirmed ||
        a.status == ExhibitorStatus.completed).toList();
  }

  List<ExpoSummary> get _filteredExpos {
    final list = _availableExpos.where((e) {
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          e.name.toLowerCase().contains(q) ||
          e.venue.toLowerCase().contains(q) ||
          (e.venueCity?.toLowerCase().contains(q) ?? false) ||
          (e.organizerName?.toLowerCase().contains(q) ?? false);

      final matchesCategory = _matchesExpoCategory(e, _selectedCategory);

      return matchesSearch && matchesCategory;
    }).toList();

    switch (_sortBy) {
      case 'date_desc':
        list.sort((a, b) => b.startAt.compareTo(a.startAt));
        break;
      case 'name_asc':
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case 'slots_desc':
        list.sort((a, b) {
          final slotsA = a.boothCapacity - a.boothsBooked;
          final slotsB = b.boothCapacity - b.boothsBooked;
          return slotsB.compareTo(slotsA);
        });
        break;
      case 'date_asc':
      default:
        list.sort((a, b) => a.startAt.compareTo(b.startAt));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Events & Exhibitions', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: const Color(0xFF64748B),
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: [
            const Tab(text: 'Browse Events'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('My Applications'),
                  if (_activeApplications.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_activeApplications.length}',
                        style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('My Exhibitions'),
                  if (_confirmedExhibitions.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_confirmedExhibitions.length}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBrowseEventsTab(),
                  _buildMyApplicationsTab(),
                  _buildMyExhibitionsTab(),
                ],
              ),
            ),
    );
  }

  // ==========================================
  // TAB 1: BROWSE EVENTS
  // ==========================================
  Widget _buildBrowseEventsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search & Filter
            _buildSearchBox(),
            const SizedBox(height: 16),
            _buildCategoryPills(),
            const SizedBox(height: 20),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Upcoming Expos & Fairs (${_filteredExpos.length})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Color(0xFF059669),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Live database events available for vendor exhibition',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                PopupMenuButton<String>(
                  initialValue: _sortBy,
                  tooltip: 'Sort exhibitions',
                  onSelected: (val) {
                    setState(() {
                      _sortBy = val;
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'date_asc',
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF64748B)),
                          SizedBox(width: 8),
                          Text('Date: Nearest First'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'date_desc',
                      child: Row(
                        children: [
                          Icon(Icons.event_outlined, size: 16, color: Color(0xFF64748B)),
                          SizedBox(width: 8),
                          Text('Date: Furthest First'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'name_asc',
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha, size: 16, color: Color(0xFF64748B)),
                          SizedBox(width: 8),
                          Text('Name: A to Z'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'slots_desc',
                      child: Row(
                        children: [
                          Icon(Icons.storefront_outlined, size: 16, color: Color(0xFF64748B)),
                          SizedBox(width: 8),
                          Text('Available Slots: High to Low'),
                        ],
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sort_rounded, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          _getSortLabel(_sortBy),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16, color: Color(0xFF64748B)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Expo Cards List
            if (_filteredExpos.isEmpty)
              _buildEmptyState(
                'No exhibitions found in Supabase.\nExpos published by Admins or Organizers will appear here live.',
                actionLabel: 'Refresh Events',
                onAction: _loadData,
              )
            else
              ..._filteredExpos.map((expo) => _buildExpoCard(expo)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBox() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search expo name, city, venue...',
          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B), size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    final categories = ['All', 'Bridal & Wedding', 'Photography', 'Banquet & Venue', 'Event Tech'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              selected: isSelected,
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              labelStyle: TextStyle(color: isSelected ? AppTheme.primaryColor : const Color(0xFF64748B)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0)),
              ),
              onSelected: (_) => setState(() => _selectedCategory = cat),
            ),
          );
        }).toList(),
      ),
    );
  }

  bool _matchesExpoCategory(ExpoSummary expo, String category) {
    if (category == 'All') return true;
    final haystack = '${expo.name} ${expo.description} ${expo.targetAudience} ${expo.venue}'.toLowerCase();
    switch (category) {
      case 'Bridal & Wedding':
        return haystack.contains('wedding') || haystack.contains('bridal') || haystack.contains('couple');
      case 'Photography':
        return haystack.contains('photo') || haystack.contains('video') || haystack.contains('cinema');
      case 'Banquet & Venue':
        return haystack.contains('banquet') || haystack.contains('venue') || haystack.contains('cater');
      case 'Event Tech':
        return haystack.contains('tech') || haystack.contains('digital') || haystack.contains('app');
      default:
        return haystack.contains(category.toLowerCase());
    }
  }

  List<String> _tagsForExpo(ExpoSummary expo) {
    final tags = <String>[];
    final blob = '${expo.name} ${expo.description} ${expo.targetAudience}'.toLowerCase();
    if (blob.contains('wedding') || blob.contains('bridal')) {
      tags.add('#WeddingExpo');
    } else if (blob.contains('photo')) {
      tags.add('#Photography');
    } else {
      tags.add('#Expo');
    }
    final city = (expo.venueCity ?? expo.venue).split(',').first.trim();
    if (city.isNotEmpty) {
      tags.add('#${city.replaceAll(RegExp(r'[^A-Za-z0-9]'), '')}');
    }
    if (blob.contains('b2b') || blob.contains('trade')) {
      tags.add('#B2B');
    } else {
      tags.add('#B2C');
    }
    return tags.take(3).toList();
  }

  Widget _buildExpoCard(ExpoSummary expo) {
    final formattedDate = '${expo.startAt.day}–${expo.endAt.day} ${DateFormat('MMM yyyy').format(expo.endAt)}';
    final slotsRemaining = expo.boothCapacity - expo.boothsBooked;
    final startingPrice = 'RM ${NumberFormat('#,##0').format(expo.startingPriceRm)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    expo.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VERIFIED EXPO',
                    style: TextStyle(color: Color(0xFF34D399), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),

          // Card Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardIconRow(Icons.calendar_today_rounded, formattedDate),
                const SizedBox(height: 8),
                _cardIconRow(Icons.location_on_rounded, expo.venue),
                const SizedBox(height: 8),
                _cardIconRow(Icons.groups_rounded, 'Expected visitors: ${expo.visitorRegistrations}+'),
                const SizedBox(height: 8),
                _cardIconRow(Icons.storefront_rounded, '${expo.boothCapacity} exhibitor slots (${slotsRemaining > 0 ? "$slotsRemaining left" : "Almost Full"})'),
                const SizedBox(height: 8),
                _cardIconRow(Icons.payments_rounded, 'Booth from $startingPrice'),

                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: Color(0xFFF1F5F9)),
                ),

                // Tags & View Event CTA
                Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: _tagsForExpo(expo).map(_miniTag).toList(),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VendorExpoDetailScreen(expo: expo),
                          ),
                        ).then((_) => _loadData());
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('View Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _cardIconRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155), fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _miniTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
    );
  }

  // ==========================================
  // TAB 2: MY APPLICATIONS
  // ==========================================
  Widget _buildMyApplicationsTab() {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);

    if (_activeApplications.isEmpty) {
      return _buildEmptyState(
        'You have no active exhibitor applications.',
        actionLabel: 'Browse Available Expos',
        onAction: () => _tabController.animateTo(0),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _activeApplications.length,
      itemBuilder: (ctx, i) {
        final app = _activeApplications[i];
        final appliedDateStr = app.appliedAt != null
            ? DateFormat('dd MMM yyyy').format(app.appliedAt!)
            : 'Recently';

        final needsAction = app.status == ExhibitorStatus.infoRequested;
        final isApproved = app.status == ExhibitorStatus.approved || app.status == ExhibitorStatus.paymentPending;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: needsAction
                  ? const Color(0xFFF59E0B)
                  : isApproved
                      ? const Color(0xFF10B981)
                      : const Color(0xFFE2E8F0),
              width: (needsAction || isApproved) ? 1.8 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VendorApplicationStatusScreen(application: app),
                ),
              ).then((_) => _loadData());
            },
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          app.expoName ?? 'Exhibition',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ExhibitorStatusChip(status: app.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Package: ${app.packageName ?? "Standard Booth"} · Fee: ${currency.format(app.boothFeeRm)}',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applied on $appliedDateStr',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),

                  // Callout for info requested
                  if (needsAction) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Action Required: Organiser has requested more details.',
                              style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Callout for approval / payment pending
                  if (isApproved) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Text('🎉', style: TextStyle(fontSize: 16)),
                              SizedBox(width: 8),
                              Text(
                                'Approved! Lock your booth now.',
                                style: TextStyle(fontSize: 12, color: Color(0xFF065F46), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VendorExhibitorPaymentScreen(application: app),
                                ),
                              ).then((_) => _loadData());
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            child: const Text('Pay Now', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'View Details & Timeline →',
                        style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 3: MY EXHIBITIONS
  // ==========================================
  Widget _buildMyExhibitionsTab() {
    if (_confirmedExhibitions.isEmpty) {
      return _buildEmptyState(
        'You have no confirmed exhibitions yet.\nOnce your application is approved and payment is confirmed, your event command center will appear here.',
        actionLabel: 'Browse Upcoming Expos',
        onAction: () => _tabController.animateTo(0),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _confirmedExhibitions.length,
      itemBuilder: (ctx, i) {
        final exhibitor = _confirmedExhibitions[i];
        final isCompleted = exhibitor.status == ExhibitorStatus.completed;

        return Container(
          margin: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCompleted
                        ? [const Color(0xFF334155), const Color(0xFF1E293B)]
                        : [const Color(0xFF065F46), const Color(0xFF047857)],
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isCompleted ? 'COMPLETED EXHIBITION' : 'CONFIRMED BOOTH',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Booth ${exhibitor.boothNumber ?? "Not assigned"}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exhibitor.expoName ?? 'Exhibition',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Hall ${exhibitor.boothHall} · ${exhibitor.boothSize} · ${exhibitor.packageName ?? "Package"}',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 16),

                    // Fast Action Badges
                    Row(
                      children: [
                        _statusIconPill(Icons.badge_rounded, '${exhibitor.staffPasses.length} Staff passes'),
                        const SizedBox(width: 8),
                        _statusIconPill(Icons.check_circle_outline, 'Paid in Full'),
                      ],
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VendorExhibitionDashboardScreen(exhibitor: exhibitor),
                            ),
                          ).then((_) => _loadData());
                        },
                        icon: const Icon(Icons.dashboard_rounded, size: 18),
                        label: const Text('Open Exhibitor Command Center', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCompleted ? const Color(0xFF1E293B) : AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusIconPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF475569)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, {String? actionLabel, VoidCallback? onAction}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_note_rounded, size: 48, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 14, color: Color(0xFF64748B), height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
