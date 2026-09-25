import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'dart:async';
import 'dart:math';
import 'package:eventease/shared/data/vendor_services_data.dart';
import 'package:eventease/shared/models/other/venue.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/booking/presentation/views/booking/booking_screen.dart'; // Added import for BookingScreen
import 'package:eventease/features/customer/presentation/views/customer/service_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:eventease/features/customer/presentation/views/customer/product_detail_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/vendor_profile_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/vendor_services_screen.dart';
import 'package:eventease/features/customer/data/providers/favorites_provider.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/shared/widgets/common_navbar.dart';
import 'package:eventease/shared/widgets/package_selection_widget.dart';
import 'package:eventease/shared/models/sample_service_packages.dart';
import 'package:eventease/features/customer/presentation/views/customer/chat_screen.dart';
import 'package:eventease/features/support/data/providers/request_provider.dart';
import 'package:eventease/features/support/data/models/customer_request.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/shared/widgets/ad_widgets.dart';
import 'package:eventease/core/providers/ad_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:eventease/shared/widgets/app_footer.dart';
import 'package:eventease/shared/utils/constants/image_constants.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';
import 'package:eventease/shared/widgets/service_video_player.dart';

class SearchScreen extends StatefulWidget {
  final String? initialCategory;

  const SearchScreen({super.key, this.initialCategory});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _filteredResults = [];
  List<dynamic> _allResults = [];
  List<Map<String, dynamic>> _packages = [];
  String _selectedPackageId = '';

  bool _isLoading = true;

  int _selectedTabIndex =
      0; // 0: All, 1: Venues, 2: Vendors, 3: Services, 4: Products/Items, 5: Packages
  // Mudah.my Style Location Filter (State -> District)
  String _selectedState = 'All';
  String _selectedDistrict = 'All';
  String _selectedLocation = 'All';

  static const Map<String, List<String>> _malaysiaStateDistricts = {
    'Kuala Lumpur': [
      'KLCC',
      'Bukit Bintang',
      'Cheras',
      'Kepong',
      'Setapak',
      'Mont Kiara',
      'Ampang',
      'Bangsar',
      'TTDI',
      'Wangsa Maju',
    ],
    'Selangor': [
      'Petaling Jaya',
      'Shah Alam',
      'Subang Jaya',
      'Cyberjaya',
      'Puchong',
      'Klang',
      'Rawang',
      'Kajang',
      'Sepang',
    ],
    'Penang': [
      'George Town',
      'Bayan Lepas',
      'Seberang Perai',
      'Butterworth',
      'Batu Ferringhi',
    ],
    'Johor': [
      'Johor Bahru',
      'Iskandar Puteri',
      'Skudai',
      'Batu Pahat',
      'Muar',
      'Kluang',
    ],
    'Kedah': [
      'Langkawi',
      'Alor Setar',
      'Sungai Petani',
    ],
    'Melaka': [
      'Melaka City',
      'Ayer Keroh',
      'Alor Gajah',
    ],
    'Perak': [
      'Ipoh',
      'Taiping',
      'Teluk Intan',
      'Manjung',
    ],
    'Pahang': [
      'Kuantan',
      'Cameron Highlands',
      'Genting Highlands',
    ],
    'Sabah': [
      'Kota Kinabalu',
      'Sandakan',
      'Tawau',
    ],
    'Sarawak': [
      'Kuching',
      'Miri',
      'Sibu',
    ],
    'Negeri Sembilan': [
      'Seremban',
      'Port Dickson',
    ],
    'Terengganu': [
      'Kuala Terengganu',
    ],
    'Kelantan': [
      'Kota Bharu',
    ],
    'Putrajaya': [
      'Putrajaya',
    ],
    'Singapore': [
      'Central',
      'East Coast',
      'Jurong',
    ],
  };

  String _selectedPriceRange = 'All';
  String _selectedRating = 'All';
  String _selectedAvailability = 'All';
  DateTime? _selectedAvailabilityDate;

  // New filters
  int? _selectedPax;
  String _selectedVenueType = 'All';
  String _selectedEventType = 'All';
  String _selectedCategory = 'All';
  List<String> _selectedAmenities = [];

  // Additional Filters
  bool _verifiedOnly = false;
  bool _hasDiscountOnly = false;

  // Global Unified Sorting
  String _globalSortBy = 'recommended'; // 'recommended', 'rating_desc', 'price_asc', 'price_desc', 'popular', 'recently_added', 'name_asc'

  // Stable seed for rotating listed vendors without jitter during filtering
  late final int _sessionSeed;

  // Sorting for tabs
  String _vendorSortBy = 'recommended';
  String _venueSortBy = 'recommended';
  String _servicesSortBy = 'recommended';

  final List<String> _tabLabels = [
    'All',
    'Venues',
    'Vendors',
    'Services',
    'Products/Items',
    'Packages',
  ];

  /// Dynamically extracts unique locations (states/cities/countries) from actual registered vendors & services
  List<String> get _dynamicLocations {
    final Set<String> locSet = {};

    // 1. Extract from search results
    for (final item in _allResults) {
      if (item is Vendor && item.location.isNotEmpty) {
        _extractCleanLocations(item.location, locSet);
      } else if (item is Venue && item.location.isNotEmpty) {
        _extractCleanLocations(item.location, locSet);
      } else if (item is VendorService) {
        if (item.venueAddress != null && item.venueAddress!.isNotEmpty) {
          _extractCleanLocations(item.venueAddress!, locSet);
        }
        final vendor = context.read<VendorProvider>().getVendorById(item.vendorId);
        if (vendor != null && vendor.location.isNotEmpty) {
          _extractCleanLocations(vendor.location, locSet);
        }
      }
    }

    // 2. Extract from all vendors registered in VendorProvider
    try {
      final vendors = context.read<VendorProvider>().vendors;
      for (final v in vendors) {
        if (v.location.isNotEmpty) {
          _extractCleanLocations(v.location, locSet);
        }
      }
    } catch (_) {}

    final sortedList = locSet.toList()..sort();
    if (sortedList.isEmpty) {
      return [
        'All',
        'Kuala Lumpur',
        'Petaling Jaya',
        'Cyberjaya',
        'Langkawi',
        'Penang',
        'Malacca',
        'Johor Bahru',
        'Selangor',
        'Sabah',
        'Sarawak',
      ];
    }
    return ['All', ...sortedList];
  }

  void _extractCleanLocations(String rawLocation, Set<String> locSet) {
    final parts = rawLocation.split(RegExp(r'[,;/]'));
    for (var part in parts) {
      final cleaned = part.trim();
      // Exclude numbers and short postal codes
      if (cleaned.length >= 3 && !RegExp(r'^\d+$').hasMatch(cleaned)) {
        locSet.add(cleaned);
      }
    }
    final full = rawLocation.trim();
    if (full.isNotEmpty && full.length <= 35) {
      locSet.add(full);
    }
  }

  final List<String> _priceRanges = [
    'All',
    'Under RM50',
    'RM50 - RM100',
    'RM100 - RM200',
    'RM200 - RM500',
    'RM500 - RM1000',
    'Above RM1000',
  ];

  final List<String> _ratingFilters = [
    'All',
    '4.5+ Stars',
    '4.0+ Stars',
    '3.5+ Stars',
    '3.0+ Stars',
  ];

  final List<String> _availabilityFilters = [
    'All',
    'Available Today',
    'Available This Week',
    'Available Next Week',
    'Select Date',
  ];

  // New filter options
  final List<int> _paxOptions = [10, 20, 50, 100, 200, 300, 500];
  final List<String> _venueTypes = [
    'All',
    'Ballroom',
    'Garden',
    'Restaurant',
    'Convention Center',
    'Hotel',
  ];
  final List<String> _eventTypes = [
    'All',
    'Wedding',
    'Corporate',
    'Birthday',
    'Anniversary',
    'Party',
    'Conference',
    'Seminar',
    'Graduation',
    'Retirement',
    'Other',
  ];
  final List<String> _amenitiesOptions = [
    'Parking',
    'WiFi',
    'Sound System',
    'Lighting',
    'Catering Kitchen',
    'Air Conditioning',
    'Stage',
    'Dance Floor',
  ];

  final List<String> _categoryOptions = [
    'All',
    'Venues',
    'Catering',
    'Photography',
    'Decoration',
    'Music',
    'Florist',
    'Cake',
    'Fashion Boutique',
    'Hotel',
    'Beauty',
    'Event Planner',
    'Makeup Artist',
  ];

  Set<String> _chatVendors = {};

  // View mode toggle: true = grid, false = list
  bool _isGridView = true;

  // Helper method to get approved services for a vendor
  List<dynamic> _getApprovedServicesForVendor(String vendorId) {
    try {
      final vendorProvider = context.read<VendorProvider>();
      final services = vendorProvider.getServicesForVendor(vendorId);
      
      // Filter for approved ones if they have that property, otherwise assume they are allowed to be shown
      return services.where((s) {
        // Handle both VendorService and VendorServiceEnhanced
        try {
          // Both types have an approvalStatus property or equivalent
          // For VendorServiceEnhanced it might be in status or approvalStatus
          final status = (s as dynamic).approvalStatus;
          return status == ApprovalStatus.approved;
        } catch (e) {
          return true; // fallback
        }
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    _sessionSeed = DateTime.now().millisecondsSinceEpoch;
    _fetchResultsFromSupabase();
    // Show interstitial ad when search screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      InterstitialAdManager.showInterstitial('search_interstitial_entry', context);
    });
  }

  Timer? _searchDebounce;

  void _onSearchChanged(String query) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _fetchResultsFromSupabase();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _initializePackages() {
    _packages = [];
    final allServices = VendorServicesData.getAllServices()
        .cast<VendorService>()
        .where((service) => service.approvalStatus == ApprovalStatus.approved);
    final vendorProvider = context.read<VendorProvider>();
    final addedPackageIds = <String>{};
    for (var service in allServices) {
      final hasPackagesInOptions = service.options.containsKey('packages');
      final hasPackagesField = service.packages != null && service.packages!.isNotEmpty;
      final isPackageType = service.type == ServiceType.package;

      if (hasPackagesInOptions || hasPackagesField || isPackageType) {
        if (!addedPackageIds.add(service.id)) continue; // skip duplicates

        final vendors = vendorProvider.vendors.cast<Vendor>();
        final vendor = vendors.firstWhere((v) => v.id == service.vendorId,
            orElse: () => Vendor(
                id: '',
                name: 'Unknown',
                categories: [],
                subcategories: [],
                description: '',
                location: '',
                images: [],
                rating: 0,
                reviewCount: 0,
                status: VendorStatus.approved,
                documents: {},
                subscriptionTier: SubscriptionTier.free,
                logistics: {},
                contactInfo: {},
                sampleServiceIds: [],
                createdAt: DateTime.now(),
                updatedAt: DateTime.now()));

        _packages.add({
          'id': service.id,
          'name': service.name,
          'description': service.description,
          'price': service.basePrice,
          'service': service,
          'vendor': vendor,
        });
      }
    }

    // Also include standalone sample packages from SampleServicePackages
    try {
      final samplePackages = SampleServicePackages.getAllPackages();
      final vendors = vendorProvider.vendors.cast<Vendor>();
      for (final pkg in samplePackages) {
        // Try to find vendor by vendorName in the package, fallback to first vendor
        // Prefer exact vendorId matching when available
        Vendor vendor;
        if (pkg.vendorId != null && pkg.vendorId!.isNotEmpty) {
          vendor = vendors.firstWhere(
            (v) => v.id == pkg.vendorId,
            orElse: () => vendors.isNotEmpty
                ? vendors.first
                : Vendor(
                    id: pkg.vendorId!,
                    name: pkg.vendorName ?? 'Unknown',
                    categories: [],
                    subcategories: [],
                    description: '',
                    location: '',
                    images: [],
                    rating: 0,
                    reviewCount: 0,
                    status: VendorStatus.approved,
                    documents: {},
                    subscriptionTier: SubscriptionTier.free,
                    logistics: {},
                    contactInfo: {},
                    sampleServiceIds: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
          );
        } else {
          final vendorName = pkg.vendorName ?? '';
          vendor = vendors.firstWhere(
            (v) => v.name.toLowerCase() == vendorName.toLowerCase(),
            orElse: () => vendors.isNotEmpty
                ? vendors.first
                : Vendor(
                    id: '',
                    name: vendorName.isNotEmpty ? vendorName : 'Unknown',
                    categories: [],
                    subcategories: [],
                    description: '',
                    location: '',
                    images: [],
                    rating: 0,
                    reviewCount: 0,
                    status: VendorStatus.approved,
                    documents: {},
                    subscriptionTier: SubscriptionTier.free,
                    logistics: {},
                    contactInfo: {},
                    sampleServiceIds: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
          );
        }

        // Create a VendorService wrapper so ProductDetailScreen can accept it
        final vendorService = VendorService(
          id: pkg.id,
          vendorId: vendor.id.isNotEmpty ? vendor.id : 'vendor_${pkg.id}',
          vendorName: vendor.name,
          name: pkg.name,
          description: pkg.description,
          category: EventCategory.package,
          basePrice: pkg.priceByPax.isNotEmpty ? pkg.priceByPax.values.first : 0.0,
          approvalStatus: ApprovalStatus.approved,
          active: true,
          images: pkg.venueDetails != null ? [pkg.venueDetails!.address] : [],
          options: {},
          requirements: {},
          logistics: {},
          availability: {},
          maxBookingsPerDay: 1,
          advanceBookingDays: 30,
          types: [ServiceType.service],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          amenities: [],
          cancellationPolicy: '',
          reviews: [],
          packages: [pkg],
        );

        _packages.add({
          'id': pkg.id,
          'name': pkg.name,
          'description': pkg.description,
          'price': pkg.priceByPax.isNotEmpty ? pkg.priceByPax.values.first : 0.0,
          'service': vendorService,
          'vendor': vendor,
        });
      }
    } catch (e) {
      // ignore package loading errors
      print('Error loading sample packages into search: $e');
    }
  }

  Future<void> _fetchResultsFromSupabase() async {
    setState(() => _isLoading = true);
    
    try {
      final vendorProvider = context.read<VendorProvider>();
      
      // Perform search with current tab
      final results = await vendorProvider.performSupabaseSearch(
        _searchController.text,
        categoryTab: _tabLabels[_selectedTabIndex]
      );

      if (!mounted) return;

      setState(() {
        _allResults = results;
        _isLoading = false;
        _filterResults(); // Apply local filters on top of search results
      });

      // After loading results, IF on Vendors tab, trigger loading services for each vendor
      // to populate the Alibaba-style preview row
      if (_selectedTabIndex == 2 || _selectedTabIndex == 0) {
        for (var result in results) {
          if (result is Vendor) {
            // This is async but we don't need to await it; it will populate the provider's cache 
            // and trigger rebuilds via notifyListeners if we match the widget structure
            vendorProvider.loadVendorServices(result.id);
          }
        }
      }
    } catch (e) {
      print('Error in _fetchResultsFromSupabase: $e');
      setState(() => _isLoading = false);
    }
  }

  List<String> _getActiveFilters() {
    List<String> active = [];
    if (_selectedTabIndex != 0) {
      active.add('Tab: ${_tabLabels[_selectedTabIndex]}');
    }
    if (_selectedLocation != 'All') {
      active.add('Location: $_selectedLocation');
    }
    if (_selectedPriceRange != 'All') {
      active.add('Price: $_selectedPriceRange');
    }
    if (_selectedRating != 'All') {
      active.add('Rating: $_selectedRating');
    }
    if (_selectedAvailability != 'All') {
      active.add('Availability: $_selectedAvailability');
    }
    if (_selectedPax != null) {
      active.add('Pax: $_selectedPax');
    }
    if (_selectedVenueType != 'All') {
      active.add('Venue Type: $_selectedVenueType');
    }
    if (_selectedEventType != 'All') {
      active.add('Event Type: $_selectedEventType');
    }
    if (_selectedCategory != 'All') {
      active.add('Category: $_selectedCategory');
    }
    if (_selectedAmenities.isNotEmpty) {
      active.add('Amenities: ${_selectedAmenities.join(', ')}');
    }
    if (_verifiedOnly) {
      active.add('Verified Vendors Only');
    }
    if (_hasDiscountOnly) {
      active.add('Deals & Offers Only');
    }
    return active;
  }

  void _clearFilter(String filter) {
    if (filter.startsWith('Tab:')) {
      setState(() {
        _selectedTabIndex = 0;
      });
    } else if (filter.startsWith('Location:')) {
      setState(() {
        _selectedState = 'All';
        _selectedDistrict = 'All';
        _selectedLocation = 'All';
      });
    } else if (filter.startsWith('Price:')) {
      setState(() {
        _selectedPriceRange = 'All';
      });
    } else if (filter.startsWith('Rating:')) {
      setState(() {
        _selectedRating = 'All';
      });
    } else if (filter.startsWith('Availability:')) {
      setState(() {
        _selectedAvailability = 'All';
        _selectedAvailabilityDate = null;
      });
    } else if (filter.startsWith('Pax:')) {
      setState(() {
        _selectedPax = null;
      });
    } else if (filter.startsWith('Venue Type:')) {
      setState(() {
        _selectedVenueType = 'All';
      });
    } else if (filter.startsWith('Event Type:')) {
      setState(() {
        _selectedEventType = 'All';
      });
    } else if (filter.startsWith('Category:')) {
      setState(() {
        _selectedCategory = 'All';
      });
    } else if (filter.startsWith('Amenities:')) {
      setState(() {
        _selectedAmenities = [];
      });
    } else if (filter.startsWith('Verified')) {
      setState(() {
        _verifiedOnly = false;
      });
    } else if (filter.startsWith('Deals')) {
      setState(() {
        _hasDiscountOnly = false;
      });
    }
    _fetchResultsFromSupabase();
  }

  double _ratingForSearchItem(dynamic item) {
    if (item is Vendor) return item.rating;
    if (item is VendorService) {
      return context.read<VendorProvider>().getVendorById(item.vendorId)?.rating ??
          0;
    }
    return 0;
  }

  DateTime _createdAtForSearchItem(dynamic item) {
    if (item is Vendor) return item.createdAt;
    if (item is VendorService) return item.createdAt;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  /// `vendor_profiles.priority_score` (manual marketplace ranking); services use vendor + embed.
  double _priorityForSearchItem(dynamic item) {
    if (item is Vendor) return item.priorityScore;
    if (item is VendorService) {
      final v = context.read<VendorProvider>().getVendorById(item.vendorId);
      return v?.priorityScore ?? item.vendorPriorityScore;
    }
    return 0;
  }

  bool _matchesVerifiedFilter(dynamic item) {
    if (!_verifiedOnly) return true;
    if (item is Vendor) {
      return item.priorityScore > 0 || item.status == VendorStatus.approved;
    } else if (item is VendorService) {
      final v = context.read<VendorProvider>().getVendorById(item.vendorId);
      return (v?.priorityScore ?? 0) > 0 || item.approvalStatus == ApprovalStatus.approved;
    }
    return true;
  }

  bool _matchesDiscountFilter(dynamic item) {
    if (!_hasDiscountOnly) return true;
    if (item is VendorService) {
      return item.options.containsKey('discount') ||
          (item.packages != null && item.packages!.isNotEmpty);
    } else if (item is Vendor) {
      final services = _getApprovedServicesForVendor(item.id);
      return services.any((s) => (s as dynamic).options?.containsKey('discount') == true);
    }
    return true;
  }

  int _compareRecommended(dynamic a, dynamic b) {
    final p = _priorityForSearchItem(b).compareTo(_priorityForSearchItem(a));
    if (p != 0) return p;
    return _createdAtForSearchItem(b).compareTo(_createdAtForSearchItem(a));
  }

  void _shuffleSamePriority(List<dynamic> list, Random random) {
    if (list.length <= 1) return;
    int start = 0;
    while (start < list.length) {
      int end = start + 1;
      final pStart = _priorityForSearchItem(list[start]);
      while (end < list.length && _priorityForSearchItem(list[end]) == pStart) {
        end++;
      }
      if (end > start + 1) {
        final sublist = list.sublist(start, end);
        sublist.shuffle(random);
        list.replaceRange(start, end, sublist);
      }
      start = end;
    }
  }

  int _compareItemsBySort(dynamic a, dynamic b, String sortBy) {
    switch (sortBy) {
      case 'rating_desc':
        final rA = _ratingForSearchItem(a);
        final rB = _ratingForSearchItem(b);
        if (rA != rB) return rB.compareTo(rA);
        return _priorityForSearchItem(b).compareTo(_priorityForSearchItem(a));

      case 'price_asc':
        final pA = _priceForSearchItem(a);
        final pB = _priceForSearchItem(b);
        return pA.compareTo(pB);

      case 'price_desc':
        final pA = _priceForSearchItem(a);
        final pB = _priceForSearchItem(b);
        return pB.compareTo(pA);

      case 'popular':
        final revA = _reviewCountForSearchItem(a);
        final revB = _reviewCountForSearchItem(b);
        if (revA != revB) return revB.compareTo(revA);
        return _ratingForSearchItem(b).compareTo(_ratingForSearchItem(a));

      case 'recently_added':
        return _createdAtForSearchItem(b).compareTo(_createdAtForSearchItem(a));

      case 'name_asc':
        final nA = _nameForSearchItem(a);
        final nB = _nameForSearchItem(b);
        return nA.toLowerCase().compareTo(nB.toLowerCase());

      case 'recommended':
      default:
        return _compareRecommended(a, b);
    }
  }

  double _priceForSearchItem(dynamic item) {
    if (item is Venue) return item.pricePerPerson;
    if (item is VendorService) return item.basePrice;
    if (item is Vendor) {
      final services = _getApprovedServicesForVendor(item.id);
      if (services.isNotEmpty) {
        return (services.first as dynamic).basePrice ?? 0.0;
      }
    }
    return 0.0;
  }

  int _reviewCountForSearchItem(dynamic item) {
    if (item is Vendor) return item.reviewCount;
    if (item is Venue) return item.reviewCount;
    if (item is VendorService) {
      final v = context.read<VendorProvider>().getVendorById(item.vendorId);
      return v?.reviewCount ?? 0;
    }
    return 0;
  }

  String _nameForSearchItem(dynamic item) {
    if (item is Vendor) return item.name;
    if (item is Venue) return item.name ?? '';
    if (item is VendorService) return item.name;
    return '';
  }

  void _filterResults() {
    try {
      setState(() {
        _filteredResults = _allResults.where((item) {
          try {
            bool matchesSearch = _matchesSearchQuery(item);
            bool matchesCategory = _matchesCategoryFilter(item);
            bool matchesLocation = _matchesLocationFilter(item);
            bool matchesPrice = _matchesPriceRange(item);
            bool matchesRating = _matchesRatingFilter(item);
            bool matchesAvailability = _matchesAvailabilityFilter(item);

            // New filters
            bool matchesPax = _matchesPaxFilter(item);
            bool matchesVenueType = _matchesVenueTypeFilter(item);
            bool matchesEventType = _matchesEventTypeFilter(item);
            bool matchesSelectedCategory = _matchesSelectedCategoryFilter(item);
            bool matchesAmenities = _matchesAmenitiesFilter(item);
            bool matchesVerified = _matchesVerifiedFilter(item);
            bool matchesDiscount = _matchesDiscountFilter(item);

            return matchesSearch &&
                matchesCategory &&
                matchesLocation &&
                matchesPrice &&
                matchesRating &&
                matchesAvailability &&
                matchesPax &&
                matchesVenueType &&
                matchesEventType &&
                matchesSelectedCategory &&
                matchesAmenities &&
                matchesVerified &&
                matchesDiscount;
          } catch (e) {
            print('Error filtering item: $e');
            return false;
          }
        }).toList();

        // Listing order: Apply chosen sort
        final stableRandom = Random(_sessionSeed);
        
        final currentSort = _selectedTabIndex == 1
            ? _venueSortBy
            : (_selectedTabIndex == 2 || _selectedTabIndex == 4
                ? _vendorSortBy
                : (_selectedTabIndex == 3 ? _servicesSortBy : _globalSortBy));

        _filteredResults.sort((a, b) => _compareItemsBySort(a, b, currentSort));

        if (currentSort == 'recommended') {
          _shuffleSamePriority(_filteredResults, stableRandom);
        }
      });
    } catch (e) {
      print('Error in _filterResults: $e');
      setState(() {
        _filteredResults = [];
      });
    }
  }

  bool _matchesSearchQuery(dynamic item) {
    try {
      final query = _searchController.text.toLowerCase().trim();
      if (query.isEmpty) return true;

      if (item is VendorService && item.category == EventCategory.venue) {
        return item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query);
      } else if (item is Vendor) {
        return item.name.toLowerCase().contains(query) ||
            item.description.toLowerCase().contains(query) ||
            item.location.toLowerCase().contains(query) ||
            item.subcategories.any((sub) => sub.toLowerCase().contains(query));
      }
      return false;
    } catch (e) {
      print('Error in _matchesSearchQuery: $e');
      return false;
    }
  }

  bool _matchesCategoryFilter(dynamic item) {
    if (item is VendorService) {
      final category = item.category;
      switch (_selectedTabIndex) {
        case 0: // All
          return true;
        case 1: // Venues
          return category == EventCategory.venue;
        case 3: // Services
          // Professional services: Everything that is NOT a Venue, Package, or identified Product category
          return category != EventCategory.venue && 
                 category != EventCategory.package &&
                 category != EventCategory.doorgift &&
                 category != EventCategory.fashion &&
                 category != EventCategory.equipment &&
                 category != EventCategory.other;
        case 4: // Products/Items
          // Physical items & rentals
          return category == EventCategory.fashion ||
                 category == EventCategory.doorgift ||
                 category == EventCategory.equipment ||
                 category == EventCategory.other;
        case 5: // Packages
          return category == EventCategory.package;
        default:
          return false;
      }
    } else if (item is Vendor) {
      switch (_selectedTabIndex) {
        case 0: // All
          return true;
        case 2: // Vendors
          return true;
        case 4: // Products/Items (Vendors who primarily sell products)
          return item.category == 'Fashion' || item.category == 'Decoration' || item.category == 'Gift';
        default:
          return false;
      }
    }
    return true;
  }

  bool _matchesPaxFilter(dynamic item) {
    if (_selectedPax == null) return true;
    try {
      if (item is VendorService && item.category == EventCategory.venue) {
        // Check if the venue service has capacity options
        if (item.options.containsKey('capacity')) {
          final capacities = item.options['capacity'];
          if (capacities is List) {
            for (var capacity in capacities) {
              if (capacity is int && capacity >= _selectedPax!) {
                return true;
              }
            }
          }
        }
        return false;
      } else if (item is Vendor) {
        // Check if any approved service has guestCount option >= selected pax
        final services = _getApprovedServicesForVendor(item.id);
        for (var service in services) {
          if (service.options.containsKey('guestCount')) {
            final guestCounts = service.options['guestCount'];
            if (guestCounts is List) {
              for (var count in guestCounts) {
                if (count is int && count >= _selectedPax!) {
                  return true;
                }
              }
            }
          }
        }
        return false;
      }
      return false;
    } catch (e) {
      print('Error in _matchesPaxFilter: $e');
      return false;
    }
  }

  bool _matchesVenueTypeFilter(dynamic item) {
    if (_selectedVenueType == 'All') return true;
    try {
      if (item is VendorService) {
        return (item.subcategory?.toLowerCase() ?? '').contains(_selectedVenueType.toLowerCase()) ||
            item.name.toLowerCase().contains(_selectedVenueType.toLowerCase());
      } else if (item is Vendor) {
        return item.category.toLowerCase().contains(_selectedVenueType.toLowerCase());
      } else if (item is Venue) {
        return (item.name ?? '').toLowerCase().contains(_selectedVenueType.toLowerCase());
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  bool _matchesEventTypeFilter(dynamic item) {
    if (_selectedEventType == 'All') return true;
    try {
      final evt = _selectedEventType.toLowerCase();
      if (item is VendorService) {
        return item.name.toLowerCase().contains(evt) ||
            item.description.toLowerCase().contains(evt) ||
            (item.subcategory?.toLowerCase() ?? '').contains(evt) ||
            item.category.displayName.toLowerCase().contains(evt);
      } else if (item is Vendor) {
        return item.subcategories.any((sub) => sub.toLowerCase().contains(evt)) ||
            item.category.toLowerCase().contains(evt);
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  bool _matchesAmenitiesFilter(dynamic item) {
    if (_selectedAmenities.isEmpty) return true;
    try {
      List<String> amenities = [];
      if (item is VendorService) {
        amenities = item.amenities ?? [];
      } else if (item is Vendor) {
        final services = _getApprovedServicesForVendor(item.id);
        for (var service in services) {
          if (service is VendorService && service.amenities != null) {
            amenities.addAll(service.amenities!);
          }
        }
        amenities = amenities.toSet().toList();
      }
      if (amenities.isEmpty) return true; // Don't strictly exclude items with unspecified amenities
      for (var selectedAmenity in _selectedAmenities) {
        if (!amenities.any((a) => a.toLowerCase().contains(selectedAmenity.toLowerCase()))) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  bool _matchesSelectedCategoryFilter(dynamic item) {
    if (_selectedCategory == 'All') return true;
    try {
      final cat = _selectedCategory.toLowerCase();
      if (item is Venue) {
        return cat.contains('venue');
      } else if (item is Vendor) {
        return item.category.toLowerCase().contains(cat) ||
            item.categories.any((c) => c.toLowerCase().contains(cat));
      } else if (item is VendorService) {
        return item.category.displayName.toLowerCase().contains(cat) ||
            (item.subcategory?.toLowerCase() ?? '').contains(cat);
      }
      return true;
    } catch (e) {
      return true;
    }
  }

  Map<String, int> _getVendorCountsByLocation() {
    final Map<String, int> counts = {};

    List<dynamic> itemsToScan = [..._allResults];
    try {
      final vendors = context.read<VendorProvider>().vendors;
      itemsToScan.addAll(vendors);
    } catch (_) {}

    for (final item in itemsToScan) {
      String locText = '';
      if (item is Vendor) {
        locText = item.location.toLowerCase();
      } else if (item is Venue) {
        locText = item.location.toLowerCase();
      } else if (item is VendorService) {
        final v = context.read<VendorProvider>().getVendorById(item.vendorId);
        locText = '${item.venueAddress ?? ''} ${item.coverageArea ?? ''} ${v?.location ?? ''}'.toLowerCase();
      }

      if (locText.isEmpty) continue;

      _malaysiaStateDistricts.forEach((state, districts) {
        final stateLower = state.toLowerCase();
        bool stateMatches = locText.contains(stateLower);

        if (!stateMatches) {
          stateMatches = districts.any((d) => locText.contains(d.toLowerCase()));
        }

        if (stateMatches) {
          counts['state_$state'] = (counts['state_$state'] ?? 0) + 1;
        }

        for (var d in districts) {
          if (locText.contains(d.toLowerCase())) {
            counts['district_${state}_$d'] = (counts['district_${state}_$d'] ?? 0) + 1;
          }
        }
      });
    }

    return counts;
  }

  bool _matchesLocationFilter(dynamic item) {
    try {
      if (_selectedState == 'All' && _selectedDistrict == 'All' && _selectedLocation == 'All') {
        return true;
      }

      String locText = '';
      if (item is Venue) {
        locText = item.location.toLowerCase();
      } else if (item is Vendor) {
        locText = item.location.toLowerCase();
      } else if (item is VendorService) {
        final v = context.read<VendorProvider>().getVendorById(item.vendorId);
        locText = '${item.venueAddress ?? ''} ${item.coverageArea ?? ''} ${v?.location ?? ''} ${item.vendorName ?? ''}'.toLowerCase();
      }

      if (locText.isEmpty) return true;

      // 1. Specific District selected
      if (_selectedDistrict != 'All') {
        if (locText.contains(_selectedDistrict.toLowerCase())) return true;
        return false;
      }

      // 2. Specific State selected
      if (_selectedState != 'All') {
        if (locText.contains(_selectedState.toLowerCase())) return true;
        final districts = _malaysiaStateDistricts[_selectedState] ?? [];
        for (var d in districts) {
          if (locText.contains(d.toLowerCase())) return true;
        }
        return false;
      }

      // 3. Fallback string matching
      if (_selectedLocation != 'All') {
        return locText.contains(_selectedLocation.toLowerCase());
      }

      return true;
    } catch (e) {
      return true;
    }
  }

  bool _matchesPriceRange(dynamic item) {
    try {
      if (_selectedPriceRange == 'All') return true;

      double price;
      if (item is Venue) {
        price = item.pricePerPerson;
      } else if (item is VendorService) {
        price = item.basePrice;
      } else if (item is Vendor) {
        final services = _getApprovedServicesForVendor(item.id);
        if (services.isNotEmpty) {
          price = (services.first as dynamic).basePrice ?? 300.0;
        } else {
          price = 300.0;
        }
      } else {
        return true;
      }

      switch (_selectedPriceRange) {
        case 'Under RM50':
          return price < 50;
        case 'RM50 - RM100':
          return price >= 50 && price <= 100;
        case 'RM100 - RM200':
          return price >= 100 && price <= 200;
        case 'RM200 - RM500':
          return price >= 200 && price <= 500;
        case 'RM500 - RM1000':
          return price >= 500 && price <= 1000;
        case 'Above RM1000':
          return price > 1000;
        default:
          return true;
      }
    } catch (e) {
      return true;
    }
  }

  bool _matchesRatingFilter(dynamic item) {
    try {
      if (_selectedRating == 'All') return true;

      double rating;
      if (item is Venue) {
        rating = item.rating;
      } else if (item is Vendor) {
        rating = item.rating;
      } else if (item is VendorService) {
        final vendor = context.read<VendorProvider>().getVendorById(item.vendorId);
        rating = vendor?.rating ?? 4.5;
      } else {
        return true;
      }

      switch (_selectedRating) {
        case '4.5+ Stars':
          return rating >= 4.5;
        case '4.0+ Stars':
          return rating >= 4.0;
        case '3.5+ Stars':
          return rating >= 3.5;
        case '3.0+ Stars':
          return rating >= 3.0;
        default:
          return true;
      }
    } catch (e) {
      return true;
    }
  }

  bool _matchesAvailabilityFilter(dynamic item) {
    try {
      if (_selectedAvailability == 'All') return true;
      // Placeholder availability logic - always return true for now
      return true;
    } catch (e) {
      print('Error in _matchesAvailabilityFilter: $e');
      return false;
    }
  }

  void _openChat(String vendorId, String vendorName) {
    setState(() {
      _chatVendors.add(vendorId);
    });

    // Create or get existing conversation
    final chatConversation = context.read<ChatProvider>().createConversation(
          vendorId: vendorId,
          vendorName: vendorName,
          vendorEmail:
              'info@${vendorName.toLowerCase().replaceAll(' ', '')}.com',
          vendorAvatar: vendorName.substring(0, 2).toUpperCase(),
        );

    // Navigate to chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerChatScreen(
          conversation: chatConversation,
        ),
      ),
    );
  }

  void _showVendorDetails(dynamic item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildVendorDetailsSheet(item),
    );
  }

  void _bookVenue(Venue venue) {
    // Create a mock vendor for venue booking
    final vendor = Vendor(
      id: 'venue_${venue.id}',
      name: venue.name,
      categories: ['Venues'],
  subcategories: venue.categories,
      description: venue.description,
      location: venue.location,
      images: venue.images,
      rating: venue.rating,
      reviewCount: venue.reviewCount,
      status: VendorStatus.approved,
      documents: {},
      subscriptionTier: SubscriptionTier.premium,
      logistics: {},
      contactInfo: venue.contactInfo,
      sampleServiceIds: [],
      createdAt: venue.createdAt,
      updatedAt: venue.updatedAt,
    );

    // Navigate to booking screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(
          vendor: vendor,
          serviceId: 'venue_service_${venue.id}',
          eventId: null,
        ),
      ),
    );
  }

  void _navigateToVenueDetail(Venue venue) {
    // Show interstitial ad before navigation
    if (InterstitialAdManager.shouldShowInterstitial('search_interstitial', context)) {
      InterstitialAdManager.showInterstitial('search_interstitial', context).then((_) {
        _navigateToVenueDetailInternal(venue);
      });
    } else {
      _navigateToVenueDetailInternal(venue);
    }
  }

  void _navigateToVenueDetailInternal(Venue venue) {
    final String imageUrl = (venue.images != null && venue.images.isNotEmpty)
        ? venue.images.first
        : ImageConstants.defaultVenueImage;

    // Create a VendorService object from venue data
    final venueService = VendorService(
      id: venue.id,
      vendorId: venue.id,
  name: venue.name,
  description: venue.description,
      category: EventCategory.venue,
      types: [ServiceType.rental],
  basePrice: venue.pricePerPerson,
      active: true,
      availability: {
        'monday': {'start': '00:00', 'end': '23:59', 'available': true},
        'tuesday': {'start': '00:00', 'end': '23:59', 'available': true},
        'wednesday': {'start': '00:00', 'end': '23:59', 'available': true},
        'thursday': {'start': '00:00', 'end': '23:59', 'available': true},
        'friday': {'start': '00:00', 'end': '23:59', 'available': true},
        'saturday': {'start': '00:00', 'end': '23:59', 'available': true},
        'sunday': {'start': '00:00', 'end': '23:59', 'available': true},
      },
      maxBookingsPerDay: 1,
      advanceBookingDays: 180,
  images: venue.images,
      options: {},
      requirements: {},
      logistics: {},
      status: ServiceStatus.active,
      approvalStatus: ApprovalStatus.approved,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      amenities: venue.amenities ??
          [
            'Spacious Hall',
            'Modern Facilities',
            'Parking Available',
            'Catering Kitchen',
            'Sound System'
          ],
      cancellationPolicy:
          'Free cancellation up to 60 days before event. 25% fee for cancellations within 60 days. 50% fee within 30 days.',
      reviews: [
        {
          'rating': 5,
          'comment': 'Beautiful venue, perfect for our wedding!',
          'user': 'Maria G.',
          'date': '2024-01-18'
        },
        {
          'rating': 4,
          'comment': 'Great location and facilities.',
          'user': 'Robert T.',
          'date': '2024-01-12'
        },
        {
          'rating': 5,
          'comment': 'Excellent service and ambiance.',
          'user': 'Jennifer M.',
          'date': '2024-01-08'
        },
      ],
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          vendorService: venueService,
        ),
      ),
    );
  }

  void _navigateToVendorServiceDetail(Vendor vendor) {
    // Show interstitial ad before navigation
    if (InterstitialAdManager.shouldShowInterstitial('search_interstitial', context)) {
      InterstitialAdManager.showInterstitial('search_interstitial', context).then((_) {
        _navigateToVendorServiceDetailInternal(vendor);
      });
    } else {
      _navigateToVendorServiceDetailInternal(vendor);
    }
  }

  void _navigateToVendorServiceDetailInternal(Vendor vendor) {
    // Get the first approved service from the vendor
    final vendorServices = _getApprovedServicesForVendor(vendor.id);

    if (vendorServices.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(
            vendorService: vendorServices.first,
          ),
        ),
      );
    } else {
      // If no approved services, show vendor details instead
      _showVendorDetails(vendor);
    }
  }

  void _navigateToVenueServiceDetail(VendorService venueService) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          vendorService: venueService,
        ),
      ),
    );
  }

  void _bookVenueService(VendorService venueService) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          vendorService: venueService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // We handle targeted rebuilds using Consumers for better performance
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Search',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sort Results',
            icon: const Icon(Icons.sort_rounded, color: AppTheme.primaryColor),
            onSelected: (value) {
              setState(() {
                _globalSortBy = value;
                _venueSortBy = value;
                _vendorSortBy = value;
                _servicesSortBy = value;
                _filterResults();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recommended',
                child: Row(
                  children: [
                    Icon(Icons.star_outline_rounded, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Text('Recommended (Priority Score)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'rating_desc',
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 18),
                    SizedBox(width: 8),
                    Text('Highest Rating'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'popular',
                child: Row(
                  children: [
                    Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 18),
                    SizedBox(width: 8),
                    Text('Most Popular & Reviews'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'price_asc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text('Price: Low to High'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'price_desc',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded, color: Colors.indigo, size: 18),
                    SizedBox(width: 8),
                    Text('Price: High to Low'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'recently_added',
                child: Row(
                  children: [
                    Icon(Icons.new_releases_outlined, color: Colors.purple, size: 18),
                    SizedBox(width: 8),
                    Text('Recently Added'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'name_asc',
                child: Row(
                  children: [
                    Icon(Icons.sort_by_alpha_rounded, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text('Alphabetical (A - Z)'),
                  ],
                ),
              ),
            ],
          ),
          // Grid/List view toggle
          IconButton(
            tooltip: _isGridView ? 'Switch to List View' : 'Switch to Grid View',
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
              child: Icon(
                _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
                key: ValueKey(_isGridView),
                color: AppTheme.primaryColor,
              ),
            ),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.filter_list,
                color: AppTheme.textSecondaryColor),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: ResponsiveWrapper(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _buildSearchBar(),
            _buildQuickFilterBar(),
            BannerAdWidget(placementId: 'search_banner_top'),
            _buildActiveFiltersDisplay(),
            _buildCategoryTabs(),
            Expanded(
              child: _selectedPackageId.isEmpty
                  ? _buildResultsList()
                  : _buildPackageDetails(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search vendors, services, or locations...',
          prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear, color: AppTheme.textSecondaryColor),
            onPressed: () {
              _searchController.clear();
              _fetchResultsFromSupabase();
            },
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildQuickFilterBar() {
    final activeCount = _getActiveFilters().length;

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // All Filters Button
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: activeCount > 0 ? AppTheme.primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: activeCount > 0 ? AppTheme.primaryColor : Colors.grey.shade300,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: activeCount > 0 ? Colors.white : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: activeCount > 0 ? Colors.white : AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (activeCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$activeCount',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // 1. Location (Mudah.my State -> District modal)
          _buildQuickFilterChip(
            label: _selectedLocation == 'All' ? 'Location' : _selectedLocation,
            icon: Icons.location_on_outlined,
            isSelected: _selectedLocation != 'All',
            onTap: _showMudahLocationModal,
          ),

          // 2. Event Type
          _buildQuickFilterChip(
            label: _selectedEventType == 'All' ? 'Event Type' : _selectedEventType,
            icon: Icons.event_available_outlined,
            isSelected: _selectedEventType != 'All',
            onTap: () => _showQuickMenu('Event Type', _eventTypes, _selectedEventType, (val) {
              setState(() => _selectedEventType = val);
              _filterResults();
            }),
          ),

          // 3. Category
          _buildQuickFilterChip(
            label: _selectedCategory == 'All' ? 'Category' : _selectedCategory,
            icon: Icons.category_outlined,
            isSelected: _selectedCategory != 'All',
            onTap: () => _showQuickMenu('Category', _categoryOptions, _selectedCategory, (val) {
              setState(() => _selectedCategory = val);
              _filterResults();
            }),
          ),

          // 4. Related Filters: Price
          _buildQuickFilterChip(
            label: _selectedPriceRange == 'All' ? 'Price' : _selectedPriceRange,
            icon: Icons.attach_money_outlined,
            isSelected: _selectedPriceRange != 'All',
            onTap: () => _showQuickMenu('Price', _priceRanges, _selectedPriceRange, (val) {
              setState(() => _selectedPriceRange = val);
              _filterResults();
            }),
          ),

          // 4. Related Filters: Rating
          _buildQuickFilterChip(
            label: _selectedRating == 'All' ? 'Rating' : _selectedRating,
            icon: Icons.star_outline_rounded,
            isSelected: _selectedRating != 'All',
            onTap: () => _showQuickMenu('Rating', _ratingFilters, _selectedRating, (val) {
              setState(() => _selectedRating = val);
              _filterResults();
            }),
          ),

          // 4. Related Filters: Guests / Pax
          _buildQuickFilterChip(
            label: _selectedPax == null ? 'Guests' : '$_selectedPax+ pax',
            icon: Icons.people_outline_rounded,
            isSelected: _selectedPax != null,
            onTap: () => _showQuickMenu(
              'Guests',
              ['All', ..._paxOptions.map((p) => '$p+ pax')],
              _selectedPax == null ? 'All' : '$_selectedPax+ pax',
              (val) {
                setState(() {
                  if (val == 'All') {
                    _selectedPax = null;
                  } else {
                    _selectedPax = int.tryParse(val.replaceAll('+ pax', ''));
                  }
                });
                _filterResults();
              },
            ),
          ),

          // 4. Related Filters: Verified Only
          GestureDetector(
            onTap: () {
              setState(() => _verifiedOnly = !_verifiedOnly);
              _filterResults();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _verifiedOnly ? Colors.blue.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _verifiedOnly ? Colors.blue : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified_user_rounded, size: 14, color: _verifiedOnly ? Colors.blue : Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Verified Only',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _verifiedOnly ? FontWeight.bold : FontWeight.w500,
                      color: _verifiedOnly ? Colors.blue : AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Related Filters: Deals & Offers
          GestureDetector(
            onTap: () {
              setState(() => _hasDiscountOnly = !_hasDiscountOnly);
              _filterResults();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _hasDiscountOnly ? Colors.amber.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _hasDiscountOnly ? Colors.amber.shade700 : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.local_offer_rounded, size: 14, color: _hasDiscountOnly ? Colors.amber.shade800 : Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Deals & Offers',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: _hasDiscountOnly ? FontWeight.bold : FontWeight.w500,
                      color: _hasDiscountOnly ? Colors.amber.shade900 : AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),



          // Reset All button if active
          if (activeCount > 0)
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedLocation = 'All';
                  _selectedPriceRange = 'All';
                  _selectedRating = 'All';
                  _selectedAvailability = 'All';
                  _selectedPax = null;
                  _selectedVenueType = 'All';
                  _selectedEventType = 'All';
                  _selectedCategory = 'All';
                  _selectedAmenities = [];
                });
                _filterResults();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.close_rounded, size: 14, color: Colors.red),
                    SizedBox(width: 4),
                    Text(
                      'Reset',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 16, color: isSelected ? AppTheme.primaryColor : Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  void _showMudahLocationModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String searchLocQuery = '';
        String? activeTabState = _selectedState == 'All' ? null : _selectedState;

        return StatefulBuilder(
          builder: (context, setModalState) {
            final vendorCounts = _getVendorCountsByLocation();

            // Filter states based on search query
            List<String> statesToShow = _malaysiaStateDistricts.keys.where((s) {
              if (searchLocQuery.isEmpty) return true;
              final q = searchLocQuery.toLowerCase();
              if (s.toLowerCase().contains(q)) return true;
              final districts = _malaysiaStateDistricts[s] ?? [];
              return districts.any((d) => d.toLowerCase().contains(q));
            }).toList();

            // Sort states so those with vendors appear first!
            statesToShow.sort((a, b) {
              final cA = vendorCounts['state_$a'] ?? 0;
              final cB = vendorCounts['state_$b'] ?? 0;
              if (cA != cB) return cB.compareTo(cA);
              return a.compareTo(b);
            });

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Modal Header (Mudah.my style)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      children: [
                        if (activeTabState != null)
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                            onPressed: () => setModalState(() => activeTabState = null),
                          ),
                        const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            activeTabState == null ? 'Select Location (Malaysia)' : 'Districts in $activeTabState',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedState = 'All';
                              _selectedDistrict = 'All';
                              _selectedLocation = 'All';
                            });
                            _filterResults();
                            Navigator.pop(context);
                          },
                          child: const Text('Entire Malaysia', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),

                  // Search Input
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search state, city or area...',
                        prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setModalState(() => searchLocQuery = val);
                      },
                    ),
                  ),

                  const Divider(height: 1),

                  // Main Content: State List vs District List
                  Expanded(
                    child: activeTabState == null
                        ? ListView.separated(
                            itemCount: statesToShow.length + 1,
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                final isAllSelected = _selectedState == 'All';
                                return ListTile(
                                  leading: const Icon(Icons.map_rounded, color: AppTheme.primaryColor),
                                  title: const Text('Entire Malaysia', style: TextStyle(fontWeight: FontWeight.bold)),
                                  trailing: isAllSelected ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedState = 'All';
                                      _selectedDistrict = 'All';
                                      _selectedLocation = 'All';
                                    });
                                    _filterResults();
                                    Navigator.pop(context);
                                  },
                                );
                              }

                              final state = statesToShow[index - 1];
                              final count = vendorCounts['state_$state'] ?? 0;
                              final isSelected = _selectedState == state;

                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: count > 0 ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade100,
                                  child: Icon(Icons.location_city_rounded, size: 16, color: count > 0 ? AppTheme.primaryColor : Colors.grey),
                                ),
                                title: Text(state, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                                subtitle: Text(
                                  count > 0 ? '$count registered vendors/services' : 'No vendors registered yet',
                                  style: TextStyle(fontSize: 12, color: count > 0 ? Colors.grey.shade700 : Colors.grey.shade400),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (count > 0)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                      ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                  ],
                                ),
                                onTap: () {
                                  setModalState(() {
                                    activeTabState = state;
                                  });
                                },
                              );
                            },
                          )
                        : ListView.separated(
                            itemCount: (_malaysiaStateDistricts[activeTabState] ?? []).length + 1,
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (context, index) {
                              final stateDistricts = _malaysiaStateDistricts[activeTabState] ?? [];
                              if (index == 0) {
                                final isEntireState = _selectedState == activeTabState && _selectedDistrict == 'All';
                                final totalStateCount = vendorCounts['state_$activeTabState'] ?? 0;
                                return ListTile(
                                  tileColor: AppTheme.primaryColor.withOpacity(0.04),
                                  leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                                  title: Text('All $activeTabState', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text('$totalStateCount vendors available state-wide', style: const TextStyle(fontSize: 12)),
                                  trailing: isEntireState ? const Icon(Icons.check_circle, color: AppTheme.primaryColor) : null,
                                  onTap: () {
                                    setState(() {
                                      _selectedState = activeTabState!;
                                      _selectedDistrict = 'All';
                                      _selectedLocation = activeTabState!;
                                    });
                                    _filterResults();
                                    Navigator.pop(context);
                                  },
                                );
                              }

                              final district = stateDistricts[index - 1];
                              final dCount = vendorCounts['district_${activeTabState}_$district'] ?? 0;
                              final isSelected = _selectedState == activeTabState && _selectedDistrict == district;

                              return ListTile(
                                title: Text(district, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                                subtitle: Text(
                                  dCount > 0 ? '$dCount vendors/services' : 'Area available',
                                  style: TextStyle(fontSize: 12, color: dCount > 0 ? AppTheme.primaryColor : Colors.grey),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle, color: AppTheme.primaryColor)
                                    : (dCount > 0
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text('$dCount', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                          )
                                        : null),
                                onTap: () {
                                  setState(() {
                                    _selectedState = activeTabState!;
                                    _selectedDistrict = district;
                                    _selectedLocation = '$district, $activeTabState';
                                  });
                                  _filterResults();
                                  Navigator.pop(context);
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showQuickMenu(
    String title,
    List<String> options,
    String currentValue,
    Function(String) onSelect,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select $title',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((opt) {
                  final isSel = opt == currentValue;
                  return ChoiceChip(
                    label: Text(opt),
                    selected: isSel,
                    onSelected: (selected) {
                      if (selected) {
                        onSelect(opt);
                        Navigator.pop(ctx);
                      }
                    },
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.grey.shade100,
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : AppTheme.textPrimaryColor,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveFiltersDisplay() {
    final activeFilters = _getActiveFilters();
    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Filters:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: activeFilters.map((filter) {
              return Chip(
                label: Text(
                  filter,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                deleteIcon: const Icon(Icons.close,
                    size: 16, color: AppTheme.primaryColor),
                onDeleted: () => _clearFilter(filter),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DefaultTabController(
        length: _tabLabels.length,
        initialIndex: _selectedTabIndex,
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
              _fetchResultsFromSupabase();
            });
          },
          tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
      String label, String value, Function(String) onChanged) {
    return PopupMenuButton<String>(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.primaryColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: $value',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down,
                color: AppTheme.primaryColor, size: 20),
          ],
        ),
      ),
      itemBuilder: (context) {
        List<String> options;
        switch (label) {
          case 'Category':
            options = _tabLabels;
            break;
          case 'Location':
            options = _dynamicLocations;
            break;
          case 'Price':
            options = _priceRanges;
            break;
          default:
            options = [];
        }

        return options
            .map((option) => PopupMenuItem(
                  value: option,
                  child: Text(option),
                ))
            .toList();
      },
      onSelected: onChanged,
    );
  }

  Widget _buildResultsList() {
    final int crossAxisCount = ResponsiveUtils.getGridColumnCount(context, mobile: 2, tablet: 3, desktop: 4);

    if (_selectedTabIndex == 5) {
      // Packages tab — always grid
      return CustomScrollView(
        slivers: [
          SliverPadding(
            padding: ResponsiveUtils.getScreenPadding(context),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 400,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = _filteredResults[index];
                  if (item is VendorService) {
                    return _buildPackageCardFromService(item);
                  }
                  return const SizedBox.shrink();
                },
                childCount: _filteredResults.length,
              ),
            ),
          ),
          if (kIsWeb)
            const SliverToBoxAdapter(child: AppFooter()),
        ],
      );
    }

    final double cardHeight = (_selectedTabIndex == 0 || _selectedTabIndex == 2 || _selectedTabIndex == 4) ? 620 : 420;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: ResponsiveUtils.getScreenPadding(context),
          sliver: _isGridView
              ? SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: cardHeight,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 3) {
                        return NativeAdWidget(placementId: 'search_native_feed');
                      }
                      final itemIndex = index > 3 ? index - 1 : index;
                      if (itemIndex >= _filteredResults.length) return const SizedBox.shrink();
                      return _buildResultCard(_filteredResults[itemIndex]);
                    },
                    childCount: _filteredResults.length + 1,
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == 3) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: NativeAdWidget(placementId: 'search_native_feed_list'),
                        );
                      }
                      final itemIndex = index > 3 ? index - 1 : index;
                      if (itemIndex >= _filteredResults.length) return const SizedBox.shrink();
                      final item = _filteredResults[itemIndex];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildResultListTile(item),
                      );
                    },
                    childCount: _filteredResults.length + 1,
                  ),
                ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        const SliverToBoxAdapter(child: AppFooter()),
      ],
    );
  }

  /// Compact horizontal list-view card for list mode
  Widget _buildResultListTile(dynamic item) {
    String title = '';
    String subtitle = '';
    String? imageUrl;
    double? price;
    double? rating;
    VoidCallback? onTap;

    if (item is Vendor) {
      title = item.name;
      subtitle = item.category;
      imageUrl = item.imageUrl ?? (item.images.isNotEmpty ? item.images.first : null);
      rating = item.rating;
      onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorServicesScreen(
        vendorId: item.id,
        vendorName: item.name,
        vendorCategory: item.category,
      )));
    } else if (item is VendorService) {
      title = item.name;
      subtitle = item.category.name;
      imageUrl = item.images.isNotEmpty ? item.images.first : null;
      price = item.basePrice;
      onTap = () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(vendorService: item)));
    } else {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
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
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildListTilePlaceholder(),
                    )
                  : _buildListTilePlaceholder(),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (rating != null) ...[
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (price != null)
                        Text(
                          'From RM ${price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildListTilePlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey[200],
      child: const Icon(Icons.store_rounded, color: Colors.grey, size: 36),
    );
  }

  Widget _buildResultCard(dynamic item) {
    if (item is VendorService && item.category == EventCategory.venue) {
      return _buildVenueServiceCard(item);
    } else if (item is Vendor) {
      return _buildVendorCard(item);
    } else if (item is VendorService) {
      return _buildServiceCard(item);
    }
    return const SizedBox.shrink();
  }

  Widget _buildPackageCardFromService(VendorService service) {
    final String imageUrl = service.images.isNotEmpty
        ? service.images.first
        : 'https://images.unsplash.com/photo-1511578314322-379afb476865';
    final bool hasVideo = service.videoUrl != null && service.videoUrl!.isNotEmpty;

    // Try to get vendor details from provider for rating
    final vendor = context.read<VendorProvider>().getVendorById(service.vendorId);
    final rating = vendor?.rating ?? 4.5;
    final reviewCount = vendor?.reviewCount ?? 10;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Package Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 140,
                color: Colors.grey[200],
                child: Icon(hasVideo ? Icons.videocam : Icons.inventory_2,
                    size: 48, color: AppTheme.primaryColor),
              ),
            ),
          ),
          if (hasVideo)
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Package Name and Favorite Button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        service.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    Consumer<FavoritesProvider>(
                      builder: (context, favoritesProvider, child) {
                        final isFavorited =
                            favoritesProvider.isServiceFavorited(service.id);
                        return IconButton(
                          icon: Icon(
                            isFavorited
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: isFavorited
                                ? Colors.red
                                : AppTheme.textSecondaryColor,
                            size: 20,
                          ),
                          onPressed: () {
                            favoritesProvider.toggleFavorite(service.id, FavoriteType.service);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(isFavorited
                                    ? 'Removed from favorites'
                                    : 'Added to favorites'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Vendor Name
                Row(
                  children: [
                    Icon(Icons.business,
                        size: 14, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        service.vendorName ?? 'Unknown Vendor',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Package Description
                Text(
                  service.description,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Rating and Price Row
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${rating.toStringAsFixed(1)} ($reviewCount reviews)',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'RM ${service.basePrice}',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(
                                vendorService: service,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info, size: 16),
                        label: const Text('Details'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primaryColor),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showInquiryDialog({
                          'service': service,
                          'vendor': vendor,
                        }),
                        icon: const Icon(Icons.request_quote, size: 16),
                        label: const Text('Inquiry'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.secondaryColor),
                          foregroundColor: AppTheme.secondaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (vendor != null) {
                            _openChat(vendor.id, vendor.name);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Vendor information not available for chat')),
                            );
                          }
                        },
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('Chat'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.secondaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 8),
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

  Widget _buildVenueCard(Venue venue) {
    final String imageUrl = (venue.images != null && venue.images.isNotEmpty)
        ? venue.images.first
        : 'https://images.unsplash.com/photo-1465101046530-73398c7f28ca';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 180,
                    color: Colors.grey[100],
                    child: const Icon(Icons.location_on, size: 48, color: AppTheme.primaryColor),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, child) {
                      final isFavorited = favoritesProvider.isServiceFavorited(venue.id);
                      return GestureDetector(
                        onTap: () => favoritesProvider.toggleFavorite(venue.id, FavoriteType.venue),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Icon(
                            isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: isFavorited ? Colors.red : AppTheme.textSecondaryColor,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'RM ${venue.pricePerPerson.toInt()} /pax',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        venue.name ?? '-',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          venue.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        venue.location ?? '-',
                        style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  venue.description ?? '-',
                  style: TextStyle(color: AppTheme.textSecondaryColor.withOpacity(0.8), fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _navigateToVenueDetail(venue),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildCircledActionButton(
                      icon: Icons.request_quote_outlined,
                      onTap: () => _showInquiryDialog(venue),
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    _buildCircledActionButton(
                      icon: Icons.book_online_outlined,
                      onTap: () => _bookVenue(venue),
                      color: Colors.blueGrey,
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

  Widget _buildCircledActionButton({required IconData icon, required VoidCallback onTap, required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(10),
          color: color.withOpacity(0.05),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _buildVenueServiceCard(VendorService venueService) {
    final String imageUrl = venueService.images.isNotEmpty
        ? venueService.images.first
        : 'https://images.unsplash.com/photo-1511578314322-379afb476865';
    final bool hasVideo = venueService.videoUrl != null && venueService.videoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                if (hasVideo && venueService.images.isEmpty)
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: ServiceVideoPlayer(videoUrl: venueService.videoUrl!),
                  )
                else ...[
                  Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[100],
                      child: Icon(hasVideo ? Icons.videocam : Icons.event, size: 48, color: AppTheme.primaryColor),
                    ),
                  ),
                  if (hasVideo)
                    Positioned(
                      top: 70,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                ],
                Positioned(
                  top: 12,
                  right: 12,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, child) {
                      final isFavorited = favoritesProvider.isServiceFavorited(venueService.id);
                      return GestureDetector(
                        onTap: () => favoritesProvider.toggleFavorite(venueService.id, FavoriteType.service),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Icon(
                            isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: isFavorited ? Colors.red : AppTheme.textSecondaryColor,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                   bottom: 12,
                   left: 12,
                   child: Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                     decoration: BoxDecoration(
                       color: AppTheme.secondaryColor.withOpacity(0.9),
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                     ),
                     child: Text(
                       'RM ${venueService.basePrice.toStringAsFixed(2)}',
                       style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                     ),
                   ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  venueService.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        venueService.subcategory ?? 'Venue Service',
                        style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  venueService.description,
                  style: TextStyle(color: AppTheme.textSecondaryColor.withOpacity(0.8), fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _navigateToVenueServiceDetail(venueService),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildCircledActionButton(
                      icon: Icons.request_quote_outlined,
                      onTap: () => _showInquiryDialog(venueService),
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    _buildCircledActionButton(
                      icon: Icons.calendar_today_outlined,
                      onTap: () => _bookVenueService(venueService),
                      color: Colors.blueGrey,
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

  Widget _buildServiceCard(VendorService service) {
    final String imageUrl = service.images.isNotEmpty
        ? service.images.first
        : 'https://images.unsplash.com/photo-1511578314322-379afb476865';
    final bool hasVideo = service.videoUrl != null && service.videoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                if (hasVideo && service.images.isEmpty)
                  SizedBox(
                    height: 180,
                    width: double.infinity,
                    child: ServiceVideoPlayer(videoUrl: service.videoUrl!),
                  )
                else ...[
                  Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: Colors.grey[100],
                      child: Icon(hasVideo ? Icons.videocam : Icons.event_available, size: 48, color: AppTheme.primaryColor),
                    ),
                  ),
                  if (hasVideo)
                    Positioned(
                      top: 70,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
                        ),
                      ),
                    ),
                ],
                Positioned(
                  top: 12,
                  right: 12,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, child) {
                      final isFavorited = favoritesProvider.isServiceFavorited(service.id);
                      return GestureDetector(
                        onTap: () => favoritesProvider.toggleFavorite(service.id, FavoriteType.service),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Icon(
                            isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: isFavorited ? Colors.red : AppTheme.textSecondaryColor,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: Text(
                      'RM ${service.basePrice.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        service.subcategory ?? 'Service',
                        style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  service.description,
                  style: TextStyle(color: AppTheme.textSecondaryColor.withOpacity(0.8), fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _navigateToVenueServiceDetail(service),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('View Details', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildCircledActionButton(
                      icon: Icons.request_quote_outlined,
                      onTap: () => _showInquiryDialog(service),
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    _buildCircledActionButton(
                      icon: Icons.calendar_today_outlined,
                      onTap: () => _bookVenueService(service),
                      color: Colors.blueGrey,
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

  Widget _buildVendorCard(Vendor vendor) {
    final String imageUrl = (vendor.images != null && vendor.images.isNotEmpty)
        ? vendor.images.first
        : 'https://images.unsplash.com/photo-1519125323398-675f0ddb6308';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Stack(
              children: [
                Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 160,
                    color: Colors.grey[100],
                    child: const Icon(Icons.storefront, size: 48, color: AppTheme.secondaryColor),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Consumer<FavoritesProvider>(
                    builder: (context, favoritesProvider, child) {
                      final isFavorited = favoritesProvider.isFavorited(vendor.id);
                      return GestureDetector(
                        onTap: () => favoritesProvider.toggleFavorite(vendor.id, FavoriteType.vendor),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                          ),
                          child: Icon(
                            isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: isFavorited ? Colors.red : AppTheme.textSecondaryColor,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      vendor.category,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        vendor.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          vendor.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        vendor.location,
                        style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  vendor.description,
                  style: TextStyle(color: AppTheme.textSecondaryColor.withOpacity(0.8), fontSize: 13, height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => VendorServicesScreen(
                             vendorId: vendor.id, vendorName: vendor.name, vendorCategory: vendor.category,
                             vendorDescription: vendor.description, vendorImage: vendor.images.isNotEmpty ? vendor.images.first : null,
                           )));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Browse Services', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildCircledActionButton(
                      icon: Icons.chat_bubble_outline,
                      onTap: () => _openChat(vendor.id, vendor.name),
                      color: AppTheme.secondaryColor,
                    ),
                    const SizedBox(width: 8),
                    _buildCircledActionButton(
                      icon: Icons.request_quote_outlined,
                      onTap: () => _showInquiryDialog(vendor),
                      color: Colors.blueGrey,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Consumer<VendorProvider>(
                  builder: (context, vendorProvider, child) {
                    return _buildVendorServicesPreviewRow(vendor);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorServicesPreviewRow(Vendor vendor) {
    final services = _getApprovedServicesForVendor(vendor.id);
    
    // If services are empty, it might be because they haven't loaded yet
    if (services.isEmpty) {
       // Return a small loading indicator or empty space
       return const SizedBox.shrink();
    }

    // Take up to 4 services for mini preview
    final previewServices = services.take(4).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: Colors.grey.withOpacity(0.2)),
        const SizedBox(height: 8),
        Text(
          'Featured Services',
          style: TextStyle(
            color: AppTheme.textPrimaryColor.withOpacity(0.8),
            fontWeight: FontWeight.bold,
            fontSize: 12,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160, // image + title + price max bounds
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: previewServices.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final service = previewServices[index];
              final String imageUrl = service.images.isNotEmpty 
                  ? service.images.first 
                  : 'https://images.unsplash.com/photo-1511578314322-379afb476865';
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductDetailScreen(
                        serviceId: (service as dynamic).id,
                      ),
                    ),
                  );
                },
                child: SizedBox(
                  width: 100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          height: 80,
                          width: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 80,
                            width: 100,
                            color: Colors.grey[200],
                            child: const Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        service.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      Text(
                        'RM ${(service as dynamic).price is num ? (service as dynamic).price.toStringAsFixed(2) : ((service as dynamic).basePrice is num ? (service as dynamic).basePrice.toStringAsFixed(2) : "0.00")}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getVendorIcon(String category) {
    switch (category) {
      case 'Catering':
        return Icons.restaurant;
      case 'Photography':
        return Icons.camera_alt;
      case 'Venues':
        return Icons.location_city;
      case 'Fashion':
        return Icons.checkroom;
      case 'Decoration':
        return Icons.celebration;
      case 'Entertainment':
        return Icons.music_note;
      case 'Transportation':
        return Icons.directions_car;
      case 'Beauty & Makeup':
        return Icons.face;
      case 'Music & DJ':
        return Icons.headphones;
      default:
        return Icons.business;
    }
  }

  Widget _buildFeaturedPostsSection(String vendorId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client
          .from('vendor_featured_posts')
          .select()
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }
        
        final posts = snapshot.data!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Recent Works & Posts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            ...posts.map((post) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Icon(
                  post['platform'] == 'Instagram' ? Icons.camera_alt : 
                  post['platform'] == 'Facebook' ? Icons.facebook : 
                  post['platform'] == 'LinkedIn' ? Icons.business : 
                  post['platform'] == 'Twitter' ? Icons.chat_bubble : Icons.public,
                  color: AppTheme.primaryColor,
                ),
                title: Text('View on ${post['platform']}'),
                subtitle: const Text('Tap to view post', style: TextStyle(fontSize: 12)),
                trailing: const Icon(Icons.open_in_new, size: 16),
                onTap: () async {
                  final url = Uri.parse(post['post_url']);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            )).toList(),
          ],
        );
      },
    );
  }

  Widget _buildVendorDetailsSheet(dynamic item) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item is Venue ? item.name : item.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item is Venue) ...[
                    _buildDetailSection('Description', item.description),
                    _buildDetailSection('Location', item.location),
                    _buildDetailSection(
                        'Categories', item.categories.join(', ')),
                    _buildDetailSection(
                        'Price', 'RM ${item.pricePerPerson.toInt()}/person'),
                    _buildDetailSection('Rating',
                        '${item.rating} (${item.reviewCount} reviews)'),
                  ] else if (item is Vendor) ...[
                    _buildDetailSection('Description', item.description),
                    _buildDetailSection('Location', item.location),
                    _buildDetailSection('Category', item.category),
                    _buildDetailSection(
                        'Subcategories', item.subcategories.join(', ')),
                    _buildDetailSection('Rating',
                        '${item.rating} (${item.reviewCount} reviews)'),
                    _buildDetailSection('Subscription',
                        item.subscriptionTier.toString().split('.').last),
                    _buildFeaturedPostsSection(item.id),
                  ],
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        if (item is Venue) {
                          _navigateToVenueDetail(item);
                        } else if (item is Vendor) {
                          _navigateToVendorServiceDetail(item);
                        }
                      },
                      icon: const Icon(Icons.book_online),
                      label: const Text('Book Now'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
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
            Icons.search_off,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria or filters',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageDetails() {
    final selectedPackage = _packages.firstWhere(
      (pkg) => pkg['id'] == _selectedPackageId,
      orElse: () => {},
    );

    if (selectedPackage.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Package Details',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _selectedPackageId = '';
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          PackageSelectionWidget(
            packages: _packages,
            selectedPackageId: _selectedPackageId,
            onPackageSelected: (packageId) {
              setState(() {
                _selectedPackageId = packageId;
              });
            },
            showAsCards: true,
          ),
          const SizedBox(height: 24),
          Text(
            'Included Services:',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildIncludedServices(selectedPackage),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Navigate to booking with selected package
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Booking ${selectedPackage['name']} package'),
                  ),
                );
              },
              icon: const Icon(Icons.book_online),
              label: const Text('Book Package'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncludedServices(Map<String, dynamic> package) {
    // Mock included services based on package
    List<String> services = [];
    if (package['name'] == 'Basic Package') {
      services = ['Venue Setup', 'Basic Catering', 'Sound System'];
    } else if (package['name'] == 'Standard Package') {
      services = [
        'Venue Setup',
        'Full Catering',
        'Sound System',
        'Photography',
        'Decoration'
      ];
    } else if (package['name'] == 'Premium Package') {
      services = [
        'Venue Setup',
        'Premium Catering',
        'Professional Sound System',
        'Photography & Videography',
        'Luxury Decoration',
        'Entertainment',
        'Transportation'
      ];
    }

    return Column(
      children: services
          .map((service) => ListTile(
                leading: const Icon(Icons.check, color: AppTheme.primaryColor),
                title: Text(service),
              ))
          .toList(),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_rounded, color: AppTheme.primaryColor),
                        const SizedBox(width: 8),
                        const Text(
                          'Filter Options',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _selectedTabIndex = 0;
                              _selectedState = 'All';
                              _selectedDistrict = 'All';
                              _selectedLocation = 'All';
                              _selectedPriceRange = 'All';
                              _selectedRating = 'All';
                              _selectedAvailability = 'All';
                              _selectedPax = null;
                              _selectedVenueType = 'All';
                              _selectedEventType = 'All';
                              _selectedCategory = 'All';
                              _selectedAmenities = [];
                              _verifiedOnly = false;
                              _hasDiscountOnly = false;
                            });
                            _filterResults();
                            setSheetState(() {});
                          },
                          icon: const Icon(Icons.refresh, size: 16, color: Colors.red),
                          label: const Text('Reset All', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Location (Mudah.my style launcher)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Location (State & District)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () {
                                  _showMudahLocationModal();
                                  setSheetState(() {});
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedDistrict != 'All'
                                              ? '$_selectedDistrict, $_selectedState'
                                              : (_selectedState != 'All' ? _selectedState : (_selectedLocation == 'All' ? 'Entire Malaysia' : _selectedLocation)),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 2. Event Type
                          _buildStringFilterSection(
                            'Event Type', _eventTypes, _selectedEventType, (value) {
                              setState(() => _selectedEventType = value);
                              _filterResults();
                              setSheetState(() {});
                            },
                          ),
                          const SizedBox(height: 20),

                          // 3. Category
                          _buildStringFilterSection(
                            'Category', _categoryOptions, _selectedCategory, (value) {
                              setState(() => _selectedCategory = value);
                              _filterResults();
                              setSheetState(() {});
                            },
                          ),
                          const SizedBox(height: 20),

                          // 4. Related Filters: Price Range
                          _buildStringFilterSection(
                            'Price Range', _priceRanges, _selectedPriceRange, (value) {
                              setState(() => _selectedPriceRange = value);
                              _filterResults();
                              setSheetState(() {});
                            },
                          ),
                          const SizedBox(height: 20),

                          // 4. Related Filters: Rating
                          _buildStringFilterSection(
                            'Minimum Rating', _ratingFilters, _selectedRating, (value) {
                              setState(() => _selectedRating = value);
                              _filterResults();
                              setSheetState(() {});
                            },
                          ),
                          const SizedBox(height: 20),

                          // 4. Related Filters: Pax / Guests
                          _buildPaxFilterSectionStateful(setSheetState),
                          const SizedBox(height: 20),

                          // 4. Related Filters: Verified & Offers Toggles
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Row(
                                    children: [
                                      Icon(Icons.verified_user_rounded, size: 18, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Verified Vendors Only', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  subtitle: const Text('Show only verified profiles & top priority vendors', style: TextStyle(fontSize: 12)),
                                  value: _verifiedOnly,
                                  onChanged: (val) {
                                    setState(() => _verifiedOnly = val);
                                    _filterResults();
                                    setSheetState(() {});
                                  },
                                ),
                                const Divider(height: 1),
                                SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Row(
                                    children: [
                                      Icon(Icons.local_offer_rounded, size: 18, color: Colors.amber),
                                      SizedBox(width: 8),
                                      Text('Deals & Promotional Offers Only', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    ],
                                  ),
                                  subtitle: const Text('Show services with package discounts or active promotions', style: TextStyle(fontSize: 12)),
                                  value: _hasDiscountOnly,
                                  onChanged: (val) {
                                    setState(() => _hasDiscountOnly = val);
                                    _filterResults();
                                    setSheetState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // 4. Related Filters: Amenities
                          _buildAmenitiesFilterSectionStateful(setSheetState),
                        ],
                      ),
                    ),
                  ),
                  // Bottom Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: () {
                          _filterResults();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Show ${_filteredResults.length} Results',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterSection(String title, List<String> options,
      int selectedIndex, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = selectedIndex == index;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) => onChanged(index),
              backgroundColor:
                  isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaxFilterSectionStateful(StateSetter setSheetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pax / Guest Count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paxOptions.map((pax) {
            final isSelected = _selectedPax == pax;
            return ChoiceChip(
              label: Text('$pax+ pax'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedPax = selected ? pax : null;
                });
                _filterResults();
                setSheetState(() {});
              },
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenitiesFilterSectionStateful(StateSetter setSheetState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _amenitiesOptions.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
                _filterResults();
                setSheetState(() {});
              },
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStringFilterSection(String title, List<String> options,
      String selectedValue, Function(String) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) => onChanged(option),
              backgroundColor:
                  isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPaxFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pax / Guest Count',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paxOptions.map((pax) {
            final isSelected = _selectedPax == pax;
            return ChoiceChip(
              label: Text(pax.toString()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedPax = selected ? pax : null;
                });
              },
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAmenitiesFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Amenities',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _amenitiesOptions.map((amenity) {
            final isSelected = _selectedAmenities.contains(amenity);
            return FilterChip(
              label: Text(amenity),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              },
              selectedColor: AppTheme.primaryColor,
              backgroundColor: Colors.grey.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDatePickerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          IconButton(
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedAvailabilityDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (picked != null) {
                setState(() {
                  _selectedAvailabilityDate = picked;
                });
              }
            },
            icon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _selectedAvailabilityDate == null
                  ? 'Select a date'
                  : '${_selectedAvailabilityDate!.day}/${_selectedAvailabilityDate!.month}/${_selectedAvailabilityDate!.year}',
              style: TextStyle(
                color: _selectedAvailabilityDate == null
                    ? AppTheme.textSecondaryColor
                    : AppTheme.textPrimaryColor,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, color: AppTheme.textSecondaryColor),
      ],
    );
  }

  void _showInquiryDialog(dynamic item) {
    showDialog(
      context: context,
      builder: (context) => _InquiryDialog(
        item: item,
        onSubmit: (request) {
          final requestProvider =
              Provider.of<RequestProvider>(context, listen: false);
          requestProvider.addRequest(request);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Inquiry sent successfully!')),
          );
        },
      ),
    );
  }
}


class _InquiryDialog extends StatefulWidget {
  final dynamic item;
  final Function(CustomerRequest) onSubmit;

  const _InquiryDialog({required this.item, required this.onSubmit});

  @override
  State<_InquiryDialog> createState() => _InquiryDialogState();
}

class _InquiryDialogState extends State<_InquiryDialog> {
  final _formKey = GlobalKey<FormState>();
  String _eventType = '';
  DateTime? _eventDate;
  double? _budget;
  String _description = '';
  int? _guestCount;

  Future<void> _selectEventDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _eventDate) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  void _submitInquiry() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_eventDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select event date')),
        );
        return;
      }
      _formKey.currentState?.save();

      // Get customer info from auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final customerId = authProvider.userId ?? '';
      final customerName = authProvider.userName.isNotEmpty ? authProvider.userName : 'John Doe';

      // Determine category based on item type
      EventCategory eventCategory;
      String vendorId;
      String vendorName;

      if (widget.item is Vendor) {
        final vendor = widget.item as Vendor;
        eventCategory = EventCategory.values.firstWhere(
          (cat) =>
              cat.displayName.toLowerCase() == vendor.category?.toLowerCase(),
          orElse: () => EventCategory.catering,
        );
        vendorId = vendor.id;
  vendorName = vendor.name;
      } else if (widget.item is Venue) {
        eventCategory = EventCategory.venue;
        final venue = widget.item as Venue;
        vendorId = venue.id;
  vendorName = venue.name;
      } else {
        return;
      }

      final request = CustomerRequest(
        id: const Uuid().v4(),
        customerId: customerId,
        customerName: customerName,
        eventCategory: eventCategory,
        eventType: _eventType.isEmpty ? 'General Event' : _eventType,
        eventDate: _eventDate!,
        budget: _budget ?? 0,
        description: _description.isEmpty
            ? 'Inquiry for ${widget.item is Vendor ? (widget.item as Vendor).name : (widget.item as Venue).name}'
            : _description,
        location: widget.item is Vendor
            ? (widget.item as Vendor).location
            : (widget.item as Venue).location,
        guestCount: _guestCount ?? 0,
        status: RequestStatus.pending,
        createdAt: DateTime.now(),
        offers: [],
      );

      widget.onSubmit(request);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemName = widget.item is Vendor
        ? (widget.item as Vendor).name
        : (widget.item as Venue).name;

    return AlertDialog(
      title: Text('Request Quote from $itemName'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Event Type (Optional)'),
                onSaved: (value) => _eventType = value?.trim() ?? '',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _eventDate == null
                          ? 'Select Event Date'
                          : 'Date: ${_eventDate!.toLocal().toString().split(' ')[0]}',
                    ),
                  ),
                  TextButton(
                    onPressed: () => _selectEventDate(context),
                    child: const Text('Choose Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Budget (RM) (Optional)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _budget = double.tryParse(value ?? ''),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Guest Count (Optional)'),
                keyboardType: TextInputType.number,
                onSaved: (value) => _guestCount = int.tryParse(value ?? ''),
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                    labelText: 'Additional Details (Optional)'),
                maxLines: 3,
                onSaved: (value) => _description = value?.trim() ?? '',
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitInquiry,
          child: const Text('Send Inquiry'),
        ),
      ],
    );
  }
}
