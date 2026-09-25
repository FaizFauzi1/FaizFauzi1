import 'package:eventease/features/booking/presentation/views/booking/booking_screen_enhanced.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eventease/shared/widgets/service_video_player.dart';
import 'package:eventease/shared/widgets/common_navbar.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/shared/models/services/service_package.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/customer/data/providers/favorites_provider.dart';
import 'package:eventease/features/booking/data/providers/cart_provider.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/features/customer/data/providers/compare_provider.dart';
import 'package:eventease/features/customer/data/providers/save_for_later_provider.dart';
import 'package:eventease/features/customer/presentation/views/customer/saved_for_later_screen.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/customer/presentation/views/home/royal_wedding_package_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/vendor_services_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/chat_screen.dart';
import 'package:eventease/shared/widgets/enhanced_package_selection_widget.dart';
import 'product_detail_booking_widgets.dart';
import 'package:eventease/features/customer/data/providers/review_provider.dart';
import 'package:eventease/shared/models/services/service_review.dart';
import 'package:eventease/features/vendor/presentation/views/package_component_config_screen.dart';
import 'package:badges/badges.dart' as badges;
import 'package:share_plus/share_plus.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/shared/models/services/service_time_rule.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/features/vendor/models/service_template_models.dart';
import 'package:eventease/core/utils/guest_utils.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/shared/models/event/event_type.dart';
import 'package:eventease/shared/utils/constants/image_constants.dart';
import 'package:eventease/features/customer/presentation/views/buyersnav_screens/cart_screen.dart';
import 'universal_booking_widget.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';
import 'package:eventease/shared/widgets/app_footer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProductDetailScreen extends StatefulWidget {
  final VendorService? vendorService;
  final String? serviceId;
  final ServicePackage? servicePackage;

  const ProductDetailScreen({
    super.key,
    this.vendorService,
    this.serviceId,
    this.servicePackage,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ServicePackage? _selectedPackage;
  int? _selectedPax;
  String? _selectedTierId;
  int _selectedImageIndex = 0;
  VendorService? _service;
  bool _isLoading = false;
  final TextEditingController _quantityController = TextEditingController(text: '1');

  // Booking state variables
  DateTime? _selectedDate;
  DateTimeRange? _selectedDateRange;
  String? _selectedEventType; // Added field
  String? _selectedSeatingLayout;
  String? _selectedMenu;
  String? _selectedOutfitSet;
  int _selectedCrew = 1;
  int _coverageHours = 4;
  Map<String, bool> _addOns = {
    'Extra Chairs': false,
    'Projector': false,
    'Sound System': false,
  };
  Map<String, bool> _liveStationAddOns = {
    'Live BBQ': false,
    'Sushi Station': false,
    'Dessert Station': false,
  };
  Map<String, bool> _extraSessions = {
    'Extra Session 1': false,
    'Extra Session 2': false,
  };

  // Track customer selections for package options
  Map<String, List<String>> _selectedItemsByComponent = {};

  @override
  void initState() {
    super.initState();
    if (widget.vendorService != null) {
      _service = widget.vendorService;
      _initializeView();
      // ALWAYS fetch full details to ensure components, pricing tiers, and joins are loaded
      // This handles cases where the service was passed from a list with partial data
      _fetchService(_service!.id);
    } else if (widget.serviceId != null) {
      _isLoading = true;
      _fetchService(widget.serviceId!);
    }
  }

  void _initializeView() {
    if (_service == null) return;
    final packages = _service!.packages;
    _selectedPackage = packages?.isNotEmpty ?? false ? packages!.first : null;
    
    // Combined available pax options from packages OR pricing tiers
    final availablePaxOptions = _service!.getAvailablePaxOptions();
    
    if (_selectedPackage != null) {
      final availablePax = _selectedPackage?.getAvailablePax();
      _selectedPax = (availablePax != null && availablePax.isNotEmpty) ? availablePax.first : null;
    } else if (availablePaxOptions.isNotEmpty) {
      _selectedPax = availablePaxOptions.first;
    }
    
    // Set default menu for catering (Updated logic)
    if (_activeService.category == EventCategory.catering && _selectedMenu == null) {
      final optionalMenus = _activeService.components
          .where((c) => c.componentType == 'catering_section' && c.isOptional)
          .map((c) => c.name)
          .toList();

      if (optionalMenus.isNotEmpty) {
        _selectedMenu = optionalMenus.first;
      } else {
        _selectedMenu = null;
      }
    }
    
    if (_activeService.eventTypes.isNotEmpty && _selectedEventType == null) {
      _selectedEventType = _activeService.eventTypes.first;
    }
    
    _loadVendorData(_service!.vendorId);

    // ═══════════════════════════════════════════════════════════════
    // DEBUG: Product Detail Screen Data
    // ═══════════════════════════════════════════════════════════════
    debugPrint('\n╔═══════════════════════════════════════════════════════════════╗');
    debugPrint('║          PRODUCT DETAIL SCREEN - SERVICE DATA                 ║');
    debugPrint('╚═══════════════════════════════════════════════════════════════╝\n');
    
    // Basic Information
    debugPrint('📋 BASIC INFORMATION');
    debugPrint('├─ Service Name: ${_service!.name}');
    debugPrint('├─ Service ID: ${_service!.id}');
    debugPrint('├─ Vendor ID: ${_service!.vendorId}');
    debugPrint('├─ Category: ${_service!.category.name} (${_service!.category.displayName})');
    debugPrint('└─ Description: ${_service!.description?.substring(0, _service!.description!.length > 50 ? 50 : _service!.description!.length) ?? "No description"}${(_service!.description?.length ?? 0) > 50 ? "..." : ""}\n');
    
    // Pricing Information
    debugPrint('💰 PRICING INFORMATION');
    debugPrint('├─ Base Price: RM ${_service!.price.toStringAsFixed(2)}');
    if (_service!.originalPrice != null) {
      final discount = ((_service!.originalPrice! - _service!.price) / _service!.originalPrice! * 100);
      debugPrint('├─ Original Price: RM ${_service!.originalPrice!.toStringAsFixed(2)} (${discount.toStringAsFixed(2)}% OFF)');
    } else {
      debugPrint('├─ Original Price: None');
    }
    debugPrint('├─ Min Order Qty: ${_activeService.minOrderQty ?? "None"}');
    debugPrint('├─ Production Days: ${_activeService.productionDays ?? "None"}');
    debugPrint('├─ Promo Expiry: ${_service!.promoExpiry != null ? DateFormat('dd MMM yyyy').format(_service!.promoExpiry!) : "No active promotion"}');
    debugPrint('├─ Event Types: ${_activeService.eventTypes.map((e) => PredefinedEventTypes.getDisplayNameByCode(e)).join(", ")}');
    debugPrint('└─ Selected Pax: ${_selectedPax ?? "Not selected"}\n');

    // Initialize default pricing tier
    if (_activeService.pricingTiers.isNotEmpty && _selectedTierId == null) {
      _selectedTierId = _activeService.pricingTiers.first.id;
    }

    // Initialize quantity to MOQ if available (CRITICAL FIX)
    if (_activeService.minOrderQty != null && _activeService.minOrderQty! > 0) {
      if ((_selectedPax ?? 0) < _activeService.minOrderQty!) {
        _selectedPax = _activeService.minOrderQty;
        _quantityController.text = _selectedPax.toString();
        debugPrint('DEBUG: Initialized quantity to MOQ: ${_activeService.minOrderQty}');
      }
    }
    
    // Packages
    debugPrint('📦 PACKAGES (${_service!.packages?.length ?? 0} total)');
    if (_service!.packages != null && _service!.packages!.isNotEmpty) {
      for (var i = 0; i < _service!.packages!.length; i++) {
        final pkg = _service!.packages![i];
        final isLast = i == _service!.packages!.length - 1;
        final prefix = isLast ? '└─' : '├─';
        debugPrint('$prefix Package ${i + 1}: ${pkg.name}');
        debugPrint('${isLast ? "  " : "│ "} ├─ Price Range: RM ${pkg.priceByPax.values.isEmpty ? "N/A" : pkg.priceByPax.values.reduce((a, b) => a < b ? a : b).toStringAsFixed(2)} - RM ${pkg.priceByPax.values.isEmpty ? "N/A" : pkg.priceByPax.values.reduce((a, b) => a > b ? a : b).toStringAsFixed(2)}');
        debugPrint('${isLast ? "  " : "│ "} ├─ Available Pax: ${pkg.getAvailablePax().join(", ")}');
        debugPrint('${isLast ? "  " : "│ "} └─ Description: ${pkg.description?.substring(0, pkg.description!.length > 40 ? 40 : pkg.description!.length) ?? "None"}${(pkg.description?.length ?? 0) > 40 ? "..." : ""}');
      }
    } else {
      debugPrint('└─ No packages available');
    }
    debugPrint('');
    
    // Pricing Tiers
    debugPrint('🎯 PRICING TIERS (${_service!.pricingTiers.length} total)');
    if (_service!.pricingTiers.isNotEmpty) {
      for (var i = 0; i < _service!.pricingTiers.length; i++) {
        final tier = _service!.pricingTiers[i];
        final isLast = i == _service!.pricingTiers.length - 1;
        final prefix = isLast ? '└─' : '├─';
        debugPrint('$prefix Tier ${i + 1}: ${tier.name}');
        debugPrint('${isLast ? "  " : "│ "} ├─ Min Pax: ${tier.minPax} | Max Pax: ${tier.maxPax ?? "Unlimited"}');
        debugPrint('${isLast ? "  " : "│ "} └─ Price: RM ${tier.price.toStringAsFixed(2)}');
      }
    } else {
      debugPrint('└─ No pricing tiers configured');
    }
    debugPrint('');
    
    // Components (What's Included)
    debugPrint('✨ COMPONENTS / INCLUSIONS (${_service!.components.length} total)');
    if (_service!.components.isNotEmpty) {
      for (var i = 0; i < _service!.components.length; i++) {
        final component = _service!.components[i];
        final isLast = i == _service!.components.length - 1;
        final prefix = isLast ? '└─' : '├─';
        debugPrint('$prefix ${component.name}');
        if (component.description != null && component.description!.isNotEmpty) {
          debugPrint('${isLast ? "  " : "│ "} └─ ${component.description}');
        }
      }
    } else {
      debugPrint('└─ No components/inclusions defined');
    }
    debugPrint('');
    
    // Amenities
    debugPrint('🏢 AMENITIES (${_service!.amenities?.length ?? 0} total)');
    if (_service!.amenities != null && _service!.amenities!.isNotEmpty) {
      for (var i = 0; i < _service!.amenities!.length; i++) {
        final amenity = _service!.amenities![i];
        final isLast = i == _service!.amenities!.length - 1;
        debugPrint('${isLast ? "└─" : "├─"} $amenity');
      }
    } else {
      debugPrint('└─ No amenities listed');
    }
    debugPrint('');
    
    // Logistics Configuration
    final logistics = _service!.logisticsConfig;
    debugPrint('🚚 LOGISTICS CONFIGURATION');
    if (logistics != null) {
      debugPrint('├─ Status: ✅ Configured');
      debugPrint('├─ Default Crew Count: ${logistics.defaultCrewCount} person(s)');
      debugPrint('├─ Setup Time: ${logistics.defaultSetupTime} hour(s)');
      debugPrint('├─ Teardown Time: ${logistics.defaultTeardownTime} hour(s)');
      debugPrint('├─ Free Delivery Radius: ${logistics.freeRadiusKm} km');
      debugPrint('└─ Per KM Rate: RM ${logistics.perKmRate.toStringAsFixed(2)}/km');
    } else {
      debugPrint('└─ Status: ❌ Not configured');
    }
    debugPrint('');

    // Time Rule Configuration
    final timeRule = _service!.timeRule;
    debugPrint('⏰ TIME RULE CONFIGURATION');
    if (timeRule != null) {
      debugPrint('├─ Status: ✅ Configured');
      debugPrint('├─ Slot Duration: ${timeRule.slotDurationMinutes ?? "N/A"} minutes');
      debugPrint('├─ Buffer Before: ${timeRule.bufferBeforeMinutes} minutes');
      debugPrint('├─ Buffer After: ${timeRule.bufferAfterMinutes} minutes');
      debugPrint('└─ Time Type: ${timeRule.timeType.displayName}');
    } else {
      debugPrint('└─ Status: ❌ Not configured');
    }
    debugPrint('');
    
    // Images
    debugPrint('🖼️  IMAGES (${_service!.images?.length ?? 0} total)');
    if (_service!.images != null && _service!.images!.isNotEmpty) {
      debugPrint('└─ ${_service!.images!.length} image(s) available');
    } else {
      debugPrint('└─ No images uploaded');
    }
    
    debugPrint('\n╚═══════════════════════════════════════════════════════════════╝\n');
  }

  Future<void> _fetchService(String id) async {
    try {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      // ALWAYS fetch full details to ensure components, pricing tiers, and joins are loaded
      final response = await Supabase.instance.client
          .from('vendor_services')
          .select('*, vendor_profiles(*), service_components(*, service_items(*)), service_pricing_tiers(*)')
          .eq('id', id)
          .single();
      
      if (response != null) {
        if (mounted) {
          setState(() {
            _service = VendorService.fromJson(response);
            _isLoading = false;
            _initializeView();
          });
          
          // Load reviews from ReviewProvider
          if (mounted) {
            Provider.of<ReviewProvider>(context, listen: false).loadReviewsForService(id);
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching service: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading service: $e')),
        );
      }
    }
  }

  void _selectDate() async {
    // Lead time restriction
    final int leadTime = _activeService.productionDays ?? 1;
    final DateTime earliestDate = DateTime.now().add(Duration(days: leadTime));
    
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? earliestDate,
      firstDate: earliestDate,
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)), // 2 years ahead
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _loadVendorData(String vendorId) async {
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    await vendorProvider.fetchVendorById(vendorId);
  }

  String _getYearsInBusiness(Vendor? vendor) {
    if (vendor == null) return 'New';
    final years = DateTime.now().difference(vendor.createdAt).inDays ~/ 365;
    if (years == 0) return 'Less than 1 year';
    if (years == 1) return '1 year';
    return '$years+ years';
  }

  Set<DateTime> _getUnavailableDates() {
    final availability = _activeService.availability;
    if (availability.isEmpty) return {};

    final Set<DateTime> dates = {};
    
    // Parse 'unavailableDates' list if it exists
    if (availability['unavailableDates'] is List) {
      for (final dateStr in availability['unavailableDates']) {
        try {
          dates.add(DateTime.parse(dateStr));
        } catch (e) {
          // Ignore invalid dates
        }
      }
    }
    
    // Parse 'blockedDates' list if it exists
    if (availability['blockedDates'] is List) {
      for (final dateStr in availability['blockedDates']) {
        try {
          dates.add(DateTime.parse(dateStr));
        } catch (e) {
          // Ignore invalid dates
        }
      }
    }

    return dates;
  }

  VendorService get _activeService => _service!;



  Widget _buildSelectedDateIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Text(
            'Selected: ${DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate!)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildEventTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.event, color: AppTheme.primaryColor, size: 20),
            SizedBox(width: 8),
            Text(
              'Event Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: _activeService.eventTypes.map((type) {
              final isSelected = _selectedEventType == type;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedEventType = type;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      PredefinedEventTypes.getDisplayNameByCode(type),
                      style: TextStyle(
                        fontSize: 13,
                        color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInstallmentInfo() {
    final depositPercent = _activeService.depositPercentage ?? 0;
    final maxInstallments = _activeService.maxInstallments ?? 1;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.payments_outlined, color: AppTheme.primaryColor, size: 20),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Payment Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Installments',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildSimpleInfoRow('Initial Deposit', '${depositPercent.toStringAsFixed(2)}%'),
              const SizedBox(height: 8),
              _buildSimpleInfoRow('Max Installments', '$maxInstallments months'),
              const SizedBox(height: 8),
              if (_activeService.paymentDeadlineDays != null)
                _buildSimpleInfoRow('Final Payment By', '${_activeService.paymentDeadlineDays} days before event'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
        ),
      ],
    );
  }

  Widget _buildPreorderInfo() {
    final bool hasMoq = _activeService.minOrderQty != null && _activeService.minOrderQty! > 0;
    final bool hasProdDays = _activeService.productionDays != null && _activeService.productionDays! > 0;
    
    if (!hasMoq && !hasProdDays) return const SizedBox.shrink();
    
    return Container(
      margin: ResponsiveUtils.isWide(context) ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Production & Order Info',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (hasMoq)
                Expanded(
                  child: _buildMetricTile(
                    'Min. Order',
                    '${_activeService.minOrderQty} units',
                    Icons.shopping_basket_outlined,
                  ),
                ),
              if (hasMoq && hasProdDays) const SizedBox(width: 12),
              if (hasProdDays)
                Expanded(
                  child: _buildMetricTile(
                    'Preparation',
                    '${_activeService.productionDays} days',
                    Icons.timer_outlined,
                  ),
                ),
            ],
          ),
          if (hasProdDays) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ready to ship/collect by ${DateFormat('dd MMM').format(DateTime.now().add(Duration(days: _activeService.productionDays!)))} if ordered today.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textPrimaryColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 18),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_service == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Service info')),
        body: const Center(
          child: Text('Service information could not be loaded.'),
        ),
      );
    }

    final categoryName = _activeService.category.id.toLowerCase();
    final bool isWide = ResponsiveUtils.isWide(context);
    
    // Check for Universal Pricing Model
    if (_activeService.pricingModel != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: isWide ? _buildDesktopAppBar(context) : _buildUniversalAppBar(context),
        body: ResponsiveWrapper(
          padding: EdgeInsets.all(0),
          child: isWide ? _buildUniversalWideLayout() : _buildUniversalMobileLayout(),
        ),
        bottomNavigationBar: isWide ? null : _buildCustomNavbar(),
      );
    }

    // Default legacy layout logic
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: isWide ? _buildDesktopAppBar(context) : _buildUniversalAppBar(context),
      body: ResponsiveWrapper(
        padding: EdgeInsets.all(0),
        child: isWide ? _buildWideLayout() : _buildMobileLayout(),
      ),
      bottomNavigationBar: isWide ? null : _buildCustomNavbar(),
    );
  }

  PreferredSizeWidget _buildDesktopAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: false,
      leadingWidth: 400,
      leading: Row(
        children: [
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _activeService.name,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                _activeService.category.displayName,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: _buildAppBarActionsInternal(),
    );
  }

  Widget _buildUniversalMobileLayout() {
    final categoryName = _activeService.category.id.toLowerCase();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageGallery(),
          if (_activeService.cancellationPolicy != null && _activeService.cancellationPolicy!.isNotEmpty)
            _buildCancellationPolicySection(),
          if (categoryName != 'doorgift' && categoryName != 'fashion' && categoryName != 'product')
            _buildAvailabilitySection(),
          UniversalBookingWidget(
            service: _activeService,
            onPriceCalculated: (price, details) {},
          ),
          _buildTierSelection(),
          if (categoryName == 'doorgift' || categoryName == 'fashion' || categoryName == 'product') ...[
            _buildPreorderInfo(),
            _buildProductQuantitySection(),
          ],
          _buildProductInfo(),
           if (_activeService.installmentEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildInstallmentInfo(),
            ),
          _buildServiceComponents(),
          _buildVendorPortfolioSection(),
          _buildReviewsSection(),
          _buildVendorInfo(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildUniversalWideLayout() {
    final categoryName = _activeService.category.id.toLowerCase();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 40),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Images and Description
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageGalleryWide(),
                    const SizedBox(height: 48),
                    _buildProductInfo(),
                    const SizedBox(height: 32),
                    _buildServiceComponents(),
                    const SizedBox(height: 32),
                    _buildVendorPortfolioSection(),
                    const SizedBox(height: 32),
                    if (_activeService.amenities != null && _activeService.amenities!.isNotEmpty)
                      _buildAmenitiesSection(),
                    const SizedBox(height: 32),
                    _buildReviewsSection(),
                  ],
                ),
              ),
              const SizedBox(width: 64),
              // Right Column: Booking Widget & Vendor Summary (Sticky-like)
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 32,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(color: Colors.grey[100]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          UniversalBookingWidget(
                            service: _activeService,
                            onPriceCalculated: (price, details) {},
                          ),
                          const Divider(height: 48),
                          _buildTierSelection(),
                          if (categoryName == 'doorgift' || categoryName == 'fashion' || categoryName == 'product') ...[
                            _buildPreorderInfo(),
                            const SizedBox(height: 16),
                            _buildProductQuantitySection(),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Desktop CTA Buttons
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Builder(
                        builder: (context) {
                          final isDirectoryMode = !_activeService.allowedActions.contains('book') && 
                                                  !_activeService.allowedActions.contains('buy') && 
                                                  !_activeService.allowedActions.contains('rent');
                          if (isDirectoryMode) {
                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.teal.shade100),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.storefront, color: Colors.teal.shade800),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Directory Showcase Only',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.teal.shade900,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'This item is part of the vendor\'s directory showcase portfolio. Direct online booking or purchasing is not available. Please send an inquiry directly to discuss requirements.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.teal.shade900,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _openChatWithVendor,
                                    icon: const Icon(Icons.chat),
                                    label: const Text(
                                      'Inquire / Chat with Vendor',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 20),
                                      backgroundColor: AppTheme.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildChatButton(false)),
                                  if (categoryName == 'doorgift' || categoryName == 'fashion') ...[
                                    const SizedBox(width: 12),
                                    Expanded(child: _buildAddToCartButton(false)),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: _buildBuyBookButtonInternal(false), // Modified to not be expanded
                              ),
                            ],
                          );
                        }
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildVendorSummaryCardWide(),
                    if (_activeService.installmentEnabled)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: _buildInstallmentInfo(),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 100),
            const AppFooter(),
          ],
        ],
      ),
    );
  }

  Widget _buildImageGalleryWide() {
    final List<String> images = _activeService.images ?? [];
    final bool hasVideo = _activeService.videoUrl != null && _activeService.videoUrl!.isNotEmpty;
    final int totalItems = images.length + (hasVideo ? 1 : 0);
    
    if (totalItems == 0) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 600,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasVideo && _selectedImageIndex == 0)
                  ServiceVideoPlayer(videoUrl: _activeService.videoUrl!)
                else
                  Image.network(
                    images[hasVideo ? _selectedImageIndex - 1 : _selectedImageIndex],
                    fit: BoxFit.cover,
                  ),
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '${_selectedImageIndex + 1} / $totalItems',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: totalItems,
              separatorBuilder: (context, index) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final isSelected = _selectedImageIndex == index;
                final isVideo = hasVideo && index == 0;
                final imageUrl = isVideo ? null : images[hasVideo ? index - 1 : index];
                
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.5),
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8)] : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: isVideo 
                        ? Container(
                            color: Colors.black,
                            child: const Icon(Icons.play_circle_outline, color: Colors.white, size: 40),
                          )
                        : Image.network(imageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVendorSummaryCardWide() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.7)]),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 10)],
                ),
                child: const Icon(Icons.storefront, color: Colors.white, size: 30),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vendor',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _activeService.getVendorEmail() ?? 'Professional Provider',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildWideDetailRow(Icons.check_circle_outline, 'Company Verified', 'Business license verified by EventEase'),
          _buildWideDetailRow(Icons.bolt, 'Instant Response', 'Typically responds within 30 minutes'),
          _buildWideDetailRow(Icons.star_outline, 'Top Rated', 'Ranked in top 5% of service providers'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openChatWithVendor,
              icon: const Icon(Icons.chat_bubble_outline, size: 20),
              label: const Text('Send Inquiry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VendorServicesScreen(
                      vendorId: _activeService.vendorId,
                      vendorName: 'Vendor',
                      vendorCategory: _activeService.category.displayName,
                    ),
                  ),
                );
              },
              child: const Text('View Official Profile', style: TextStyle(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideDetailRow(IconData icon, String title, String subtitle) {
     return Padding(
       padding: const EdgeInsets.only(bottom: 20),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
             child: Icon(icon, size: 20, color: Colors.green),
           ),
           const SizedBox(width: 16),
           Expanded(
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                 Text(subtitle, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor)),
               ],
             ),
           ),
         ],
       ),
     );
  }

  Widget _buildVendorPortfolioSection() {
    return Consumer<VendorProvider>(
      builder: (context, vendorProvider, child) {
        final vendorId = _activeService.vendorId;
        final vendor = vendorProvider.getVendorById(vendorId);
        final portfolio = vendor?.portfolio ?? [];

        if (portfolio.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Row(
                children: [
                  const Icon(Icons.collections_outlined, color: AppTheme.primaryColor),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Previous Work',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveUtils.isWide(context) ? 4 : 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.0,
              ),
              itemCount: portfolio.length > 8 ? 8 : portfolio.length,
              itemBuilder: (context, index) {
                return MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _showFullScreenImage(index, portfolio),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          portfolio[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            if (portfolio.length > 8)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VendorServicesScreen(
                            vendorId: vendorId,
                            vendorName: vendor?.name ?? 'Vendor',
                            vendorCategory: vendor?.category ?? 'Services',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.more_horiz),
                    label: const Text('View All Work Samples', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showFullScreenImage(int index, List<String> images) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withOpacity(0.9)),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              width: MediaQuery.of(context).size.width * 0.9,
              child: PageView.builder(
                controller: PageController(initialPage: index),
                itemCount: images.length,
                itemBuilder: (context, i) => InteractiveViewer(child: Image.network(images[i], fit: BoxFit.contain)),
              ),
            ),
            Positioned(top: 40, right: 30, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context))),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final bookingWidget = _buildCategoryBookingWidget();
    final categoryName = _activeService.category.id.toLowerCase();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildImageGallery(),
          if (_activeService.cancellationPolicy != null && _activeService.cancellationPolicy!.isNotEmpty)
            _buildCancellationPolicySection(),
          if (categoryName != 'doorgift' && categoryName != 'fashion' && categoryName != 'product')
            _buildAvailabilitySection(),
          if (_selectedPackage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: EnhancedPackageSelectionWidget(
                packages: _activeService.packages ?? [],
                selectedPackage: _selectedPackage,
                selectedPax: _selectedPax,
                onPackageSelected: (package, pax) {
                  setState(() {
                    _selectedPackage = package;
                    _selectedPax = pax;
                  });
                },
              ),
            ),
          bookingWidget,
          _buildTierSelection(),
          if (categoryName == 'doorgift' || categoryName == 'fashion' || categoryName == 'product') ...[
            _buildPreorderInfo(),
            _buildProductQuantitySection(),
          ],
          if (_activeService.hasPackagePricing)
            _buildPaxSelection(),
          _buildServiceComponents(),
          _buildProductInfo(),
           if (_activeService.installmentEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildInstallmentInfo(),
            ),
          _buildServiceOptions(),
          _buildReviewsSection(),
          _buildVendorPortfolioSection(),
          _buildVendorInfo(),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildWideLayout() {
    return _buildUniversalWideLayout(); // Directing wide layout to universal wide view
  }

  PreferredSizeWidget _buildUniversalAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _activeService.name,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            _activeService.category.displayName ?? _activeService.category.name,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
      actions: _buildAppBarActionsInternal(),
    );
  }
  List<Widget> _buildAppBarActionsInternal() {
    return [
      // Favorite Action
      Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          final isFavorited = favoritesProvider.isFavorited(_activeService.id);
          return IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: isFavorited ? Colors.red : AppTheme.textSecondaryColor,
            ),
            onPressed: () => favoritesProvider.toggleFavorite(_activeService.id, FavoriteType.service),
            tooltip: 'Favorite',
          );
        },
      ),

      // Share Action
      IconButton(
        icon: const Icon(Icons.share, color: AppTheme.textSecondaryColor),
        onPressed: _shareService,
        tooltip: 'Share',
      ),

      // Compare Action
      Consumer<CompareProvider>(
        builder: (context, compareProvider, child) {
          final isInCompare = compareProvider.isInCompareList(_activeService.id);
          final hasItemsToCompare = compareProvider.currentCount > 0;
          
          return Stack(
            children: [
              IconButton(
                icon: Icon(
                  isInCompare ? Icons.compare_arrows : Icons.compare_arrows_outlined,
                  color: isInCompare || hasItemsToCompare ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                ),
                onPressed: () {
                  if (hasItemsToCompare) {
                    Navigator.pushNamed(context, '/compare');
                  } else {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (!authProvider.isAuthenticated) {
                      GuestUtils.promptLogin(context, message: 'Please log in to compare services.');
                      return;
                    }
                    if (compareProvider.canAddToCompare()) {
                      compareProvider.addToCompare(_activeService);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Added to comparison (1/4)'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    }
                  }
                },
              ),
              if (hasItemsToCompare)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 12,
                      minHeight: 12,
                    ),
                    child: Text(
                      compareProvider.currentCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),

      // More Actions Menu
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: AppTheme.textSecondaryColor),
        onSelected: (value) {
          switch (value) {
            case 'report':
              _showReportDialog(context);
              break;
            case 'save_later':
              final saveProvider = Provider.of<SaveForLaterProvider>(context, listen: false);
              final isCurrentlySaved = saveProvider.isServiceSaved(_activeService.id);
              saveProvider.toggleService(_activeService.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isCurrentlySaved ? 'Removed from saved items' : 'Saved for later!'
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
              break;
            case 'view_similar':
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Finding similar services...'),
                  duration: Duration(seconds: 1),
                ),
              );
              break;
            case 'add_to_wishlist':
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Added to wishlist!'),
                  duration: Duration(seconds: 1),
                ),
              );
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'report',
            child: Row(
              children: [
                Icon(Icons.report, size: 20),
                SizedBox(width: 8),
                Text('Report Service'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'save_later',
            child: Row(
              children: [
                Icon(Icons.bookmark_border, size: 20),
                SizedBox(width: 8),
                Text('Save for Later'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'quick_inquiry',
            child: Row(
              children: [
                Icon(Icons.message, size: 20),
                SizedBox(width: 8),
                Text('Quick Inquiry'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'request_quote',
            child: Row(
              children: [
                Icon(Icons.request_quote, size: 20),
                SizedBox(width: 8),
                Text('Request Quote'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'view_similar',
            child: Row(
              children: [
                Icon(Icons.search, size: 20),
                SizedBox(width: 8),
                Text('View Similar'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'add_to_wishlist',
            child: Row(
              children: [
                Icon(Icons.favorite_border, size: 20),
                SizedBox(width: 8),
                Text('Add to Wishlist'),
              ],
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildCategoryBookingWidget() {
    final category = _activeService.category.id.toLowerCase();

    switch (category) {
      case 'all-in package':
        return AllInPackageBookingWidget(
          selectedPax: _selectedPax,
          onPaxChanged: (pax) {
            setState(() {
              _selectedPax = pax;
            });
          },
          selectedDate: _selectedDate,
          onDateChanged: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
          addOns: _addOns,
          onAddOnChanged: (key, value) {
            setState(() {
              _addOns[key] = value;
            });
          },
          paxOptions: _activeService.getAvailablePaxOptions(),
          unavailableDates: _getUnavailableDates(),
        );

      case 'catering':
        final optionalCateringSections = _activeService.components
            .where((c) => c.componentType == 'catering_section' && c.isOptional)
            .map((c) => c.name)
            .toList();

        final menuOptions = optionalCateringSections;
            
        return CateringBookingWidget(
          selectedPax: _selectedPax,
          onPaxChanged: (pax) {
            setState(() {
              _selectedPax = pax;
            });
          },
          selectedMenu: _selectedMenu,
          onMenuChanged: (menu) {
            setState(() {
              _selectedMenu = menu;
            });
          },
          liveStationAddOns: _liveStationAddOns,
          onAddOnChanged: (key, value) {
            setState(() {
              _liveStationAddOns[key] = value;
            });
          },
          paxOptions: _activeService.getAvailablePaxOptions(),
          menuOptions: menuOptions.isNotEmpty ? menuOptions : const ['Standard', 'Premium', 'Vegetarian', 'Halal'],
        );

      case 'venue':
      case 'venues':
        return VenueBookingWidget(
          selectedDateRange: _selectedDateRange,
          onDateRangeChanged: (range) {
            setState(() {
              _selectedDateRange = range;
            });
          },
          selectedSeatingLayout: _selectedSeatingLayout,
          onSeatingLayoutChanged: (layout) {
            setState(() {
              _selectedSeatingLayout = layout;
            });
          },
          addOns: _addOns,
          onAddOnChanged: (key, value) {
            setState(() {
              _addOns[key] = value;
            });
          },
          unavailableDates: _getUnavailableDates(),
        );
      case 'photography':
        return PhotographyBookingWidget(
          selectedCrew: _selectedCrew,
          onCrewChanged: (crew) {
            setState(() {
              _selectedCrew = crew;
            });
          },
          coverageHours: _coverageHours,
          onCoverageHoursChanged: (hours) {
            setState(() {
              _coverageHours = hours;
            });
          },
          addOns: _addOns,
          onAddOnChanged: (key, value) {
            setState(() {
              _addOns[key] = value;
            });
          },
        );
      case 'makeup':
      case 'busana':
      case 'beauty & makeup':
        return MakeupBookingWidget(
          selectedOutfitSet: _selectedOutfitSet,
          onOutfitSetChanged: (set) {
            setState(() {
              _selectedOutfitSet = set;
            });
          },
          extraSessions: _extraSessions,
          onExtraSessionChanged: (key, value) {
            setState(() {
              _extraSessions[key] = value;
            });
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildImageGallery() {
    // Use only actual service images from database
    final List<String> images = _activeService.images?.isNotEmpty ?? false 
        ? _activeService.images! 
        : [];

    final bool hasVideo = _activeService.videoUrl != null && _activeService.videoUrl!.isNotEmpty;
    final int totalItems = images.length + (hasVideo ? 1 : 0);

    // Show placeholder if no media is available
    if (totalItems == 0) {
      return Container(
        height: 300,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Icon(
            Icons.image,
            size: 64,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      );
    }

    return Container(
      height: 300,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: totalItems,
            onPageChanged: (index) {
              setState(() {
                _selectedImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              // If there is a video, it is placed at the first index (index 0)
              if (hasVideo && index == 0) {
                return Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: ServiceVideoPlayer(videoUrl: _activeService.videoUrl!),
                  ),
                );
              }

              // Adjust image index backwards if video is present
              final imageIndex = hasVideo ? index - 1 : index;

              return Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    images[imageIndex],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image,
                          size: 64,
                          color: AppTheme.textSecondaryColor,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          
          if (totalItems > 1)
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  totalItems,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _selectedImageIndex ? 10 : 6,
                    height: index == _selectedImageIndex ? 10 : 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedImageIndex == index
                          ? AppTheme.primaryColor
                          : Colors.white.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaxSelection() {
    // If we have pricing tiers, we hide the manual pax selector 
    // because choosing a tier implicitly chooses the pax count/range.
    if (_activeService.pricingTiers.isNotEmpty) {
      return const SizedBox.shrink();
    }
    
    if (!_activeService.hasPackagePricing) return const SizedBox.shrink();
    
    final availablePax = _activeService.getAvailablePaxOptions();
    
    return Container(
      margin: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Select Guest Count',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availablePax.map((pax) {
              final isSelected = _selectedPax == pax;
              final price = _activeService.getPriceForPax(pax);
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedPax = pax;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$pax pax',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'RM ${price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white : AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceComponents() {
    final components = _activeService.components;
    if (components.isEmpty) return const SizedBox.shrink();

    // Group components by parent to support hierarchy (Phase 6 requirement)
    final Map<String?, List<ServiceComponent>> grouped = {};
    for (var comp in components) {
      grouped.putIfAbsent(comp.parentComponentId, () => <ServiceComponent>[]).add(comp);
    }

    final topLevel = grouped[null] ?? <ServiceComponent>[];

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.list_alt, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                "What's Included",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topLevel.map((comp) => _buildHierarchicalComponent(comp, grouped, 0)),
        ],
      ),
    );
  }

  Widget _buildHierarchicalComponent(
    ServiceComponent component, 
    Map<String?, List<ServiceComponent>> grouped,
    int depth
  ) {
    final children = grouped[component.id] ?? [];
    final bool isSet = component.componentType == 'set';
    
    // Check if this component allows selection
    final bool isSelectable = component.selectionLimit > 0;
    final List<String> currentSelections = _selectedItemsByComponent[component.id] ?? [];

    return Padding(
      padding: EdgeInsets.only(left: depth * 16.0, bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Component Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSet ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: isSet ? null : Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                if (isSet) const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                if (isSet) const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    component.name.toUpperCase(),
                    style: TextStyle(
                      fontSize: depth == 0 ? 15 : 13,
                      fontWeight: FontWeight.bold,
                      color: isSet ? Colors.white : AppTheme.primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (component.selectionLimit > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSet ? Colors.white.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Pick ${component.selectionLimit} (Selected: ${currentSelections.length})",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSet ? Colors.white : AppTheme.primaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          if (component.description != null && component.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8, left: 4),
              child: Text(
                component.description!,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor, fontStyle: FontStyle.italic),
              ),
            ),
          
          const SizedBox(height: 12),

          // Render Items
          if (component.items.isNotEmpty)
            ...component.items.map((item) {
              final bool isItemSelected = currentSelections.contains(item.id);
              final bool isDisabled = !isItemSelected && component.selectionLimit > 0 && currentSelections.length >= component.selectionLimit;
              
              return InkWell(
                onTap: isSelectable && !isDisabled || isItemSelected ? () {
                  setState(() {
                    if (isItemSelected) {
                      currentSelections.remove(item.id);
                    } else {
                      if (component.selectionLimit == 1) {
                        currentSelections.clear();
                        currentSelections.add(item.id!);
                      } else if (currentSelections.length < component.selectionLimit) {
                        currentSelections.add(item.id!);
                      }
                    }
                    _selectedItemsByComponent[component.id!] = List.from(currentSelections);
                  });
                } : null,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isSelectable)
                        Icon(
                          isItemSelected 
                            ? (component.selectionLimit == 1 ? Icons.radio_button_checked : Icons.check_box)
                            : (component.selectionLimit == 1 ? Icons.radio_button_off : Icons.check_box_outline_blank),
                          size: 20,
                          color: isDisabled ? Colors.grey : AppTheme.primaryColor,
                        )
                      else
                        Icon(
                          item.isOptional ? Icons.add_circle_outline : Icons.check_circle_outline, 
                          size: 16, 
                          color: item.isOptional ? AppTheme.secondaryColor : AppTheme.primaryColor
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name + (item.quantity > 1 ? " (x${item.quantity})" : ""),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isItemSelected ? FontWeight.bold : FontWeight.w500,
                                color: isDisabled ? Colors.grey : AppTheme.textPrimaryColor,
                              ),
                            ),
                            if (item.isFree)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  "FREE",
                                  style: TextStyle(
                                    fontSize: 10, 
                                    color: Colors.green, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            else if (item.extraPrice != null && item.extraPrice! > 0)
                              Text(
                                "(+ RM ${item.extraPrice!.toStringAsFixed(2)})",
                                style: TextStyle(
                                  fontSize: 12, 
                                  color: isDisabled ? Colors.grey : AppTheme.secondaryColor, 
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

          // Render Children recursively
          if (children.isNotEmpty)
            ...children.map((child) => _buildHierarchicalComponent(child, grouped, depth + 1)),
            
          if (depth == 0) const Divider(height: 32),
        ],
      ),
    );
  }
  
  Widget _buildServiceOptions() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Available Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ..._activeService.options!.entries.map((entry) {
            final key = entry.key;
            final value = entry.value;
            if (value is List) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: value.map<Widget>((item) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.toString(),
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      )).toList(),
                    ),
                  ],
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      key.replaceAll('_', ' '),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      value.toString(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildPackageInclusions() {
    final includes = _activeService.options!['includes'] as List?;
    if (includes == null || includes.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Package Includes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...includes.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  String _getDisplayPrice() {
    // If a pricing tier is selected, use its price
    if (_selectedTierId != null && _activeService.pricingTiers.isNotEmpty) {
      final tier = _activeService.pricingTiers.firstWhere(
        (t) => t.id == _selectedTierId,
        orElse: () => _activeService.pricingTiers.first,
      );
      if (tier != null) {
        return 'RM ${tier.price.toStringAsFixed(2)}';
      }
    }

    // If has pax pricing and pax is selected
    if (_activeService.hasPackagePricing && _selectedPax != null) {
      return 'RM ${_activeService.getPriceForPax(_selectedPax!).toStringAsFixed(2)}';
    }
    // If has package and pax is selected
    if (_selectedPackage != null && _selectedPax != null) {
      return 'RM ${_selectedPackage!.getPriceForPax(_selectedPax!).toStringAsFixed(2)}';
    }
    // Default base price
    return 'RM ${_activeService.price.toStringAsFixed(2)}';
  }

  Widget _buildPdfBrochureWidget() {
    final pdfUrl = _activeService.options['pdfBrochureUrl'] as String?;
    if (pdfUrl == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.teal.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            final uri = Uri.parse(pdfUrl);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open the brochure.')),
                );
              }
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.picture_as_pdf,
                    color: Colors.teal,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'View Service Brochure',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Tap to download or view PDF',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.teal,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header with Category Badge and Pricing
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _activeService.category.displayName ?? _activeService.category.name,
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Flexible(child: _buildEnhancedPricingDisplay()),
            ],
          ),
          const SizedBox(height: 16),

          // Service Name
          Text(
            _activeService.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            _activeService.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // PDF Brochure Widget
          if (_activeService.options['pdfBrochureUrl'] != null)
            _buildPdfBrochureWidget(),

          // Enhanced Specifications Section
          _buildEnhancedSpecifications(),

          // Certifications and Badges
          if (_activeService.category.name.toLowerCase() == 'catering' ||
              _activeService.category.name.toLowerCase() == 'photography')
            _buildCertificationsSection(),
        ],
      ),
    );
  }

  Widget _buildEnhancedPricingDisplay() {
    final price = _getDisplayPrice();
    final hasPackagePricing = _activeService.hasPackagePricing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Main Price with enhanced formatting
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_activeService.originalPrice != null && _activeService.originalPrice! > _activeService.price)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4, right: 8),
                  child: Text(
                    'RM ${_activeService.originalPrice!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              Text(
                'RM',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                price.replaceAll('RM ', ''),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),

        if (_activeService.promoExpiry != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'PROMO ENDS: ${DateFormat('dd MMM yyyy').format(_activeService.promoExpiry!)}',
              style: TextStyle(
                color: Colors.orange.shade900,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Price Range for Packages with better formatting
        if (hasPackagePricing) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'From RM ${_activeService.getMinPrice().toStringAsFixed(2)} - RM ${_activeService.getMaxPrice().toStringAsFixed(2)}',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],

        // Per Person indicator with better styling
        if (hasPackagePricing) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'per person',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],

        // Additional pricing info for packages
        if (hasPackagePricing) ...[
          const SizedBox(height: 6),
          Text(
            '${_activeService.packages?.isNotEmpty == true ? _activeService.packages!.length : _activeService.pricingTiers.length} options available',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEnhancedSpecifications() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Key Specifications Grid
          Consumer<VendorProvider>(
            builder: (context, vendorProvider, _) {
              final vendor = vendorProvider.getVendorById(_activeService.vendorId);
              final List<Widget> specItems = [
                _buildSpecItem(Icons.business, 'Vendor', vendor?.name ?? _activeService.vendorName ?? 'Unknown'),
              ];
              
              // Add duration if available
              if (_activeService.options['duration'] != null) {
                specItems.add(_buildSpecItem(Icons.access_time, 'Duration', _activeService.options['duration'].toString()));
              }
              
              // Add capacity if available
              if (_activeService.options['capacity'] != null) {
                specItems.add(_buildSpecItem(Icons.people, 'Capacity', _activeService.options['capacity'].toString()));
              }
              
              // Add verification status
              specItems.add(_buildSpecItem(Icons.verified, 'Verified', vendor?.verified == true ? 'Yes' : 'Pending'));
              
              // Add coverage area
              final coverage = _activeService.coverageArea ?? 
                             (_activeService.locations?.isNotEmpty ?? false ? _activeService.locations!.first : null) ??
                             vendor?.location ?? 
                             'Not specified';
              specItems.add(_buildSpecItem(Icons.location_on, 'Coverage', coverage));
              
              // Add rating
              final rating = _activeService.averageRating;
              final reviewCount = _activeService.reviews?.length ?? 0;
              specItems.add(_buildSpecItem(Icons.star, 'Rating', '${rating.toStringAsFixed(1)} ($reviewCount reviews)'));
              
              // NEW: Add Logistics Config
              final logistics = _activeService.logisticsConfig;
              if (logistics != null) {
                if (logistics.defaultCrewCount > 0) {
                  specItems.add(_buildSpecItem(Icons.groups, 'Crew', '${logistics.defaultCrewCount} pax'));
                }
                if (logistics.defaultSetupTime > 0) {
                  specItems.add(_buildSpecItem(Icons.build, 'Setup', '${logistics.defaultSetupTime.toStringAsFixed(1)}h'));
                }
                if (logistics.freeRadiusKm > 0) {
                  specItems.add(_buildSpecItem(Icons.local_shipping, 'Radius', '${logistics.freeRadiusKm.toStringAsFixed(2)}km Free'));
                }
              }

              // NEW: Add Time Rules
              final timeRule = _activeService.timeRule;
              if (timeRule != null) {
                if (timeRule.slotDurationMinutes != null && timeRule.slotDurationMinutes! > 0) {
                  specItems.add(_buildSpecItem(Icons.timer, 'Slot', '${timeRule.slotDurationMinutes}m'));
                }
                if (timeRule.minDurationMinutes != null && timeRule.minDurationMinutes! > 0) {
                  specItems.add(_buildSpecItem(Icons.hourglass_bottom, 'Min', '${timeRule.minDurationMinutes}m'));
                }
              }

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: specItems.map((item) => SizedBox(
                  width: (MediaQuery.of(context).size.width - 48) / 2, // adaptive 2-column feel
                  child: item,
                )).toList(),
              );
            },
          ),

          // Additional Details - only show if we have actual data
          if (_activeService.amenities != null && _activeService.amenities!.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            _buildExpandableSpecSection('Service Features', _activeService.amenities!),
          ],
        ],
      ),
    );
  }

  Widget _buildSpecItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableSpecSection(String title, List<String> items) {
    return ExpansionTile(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            children: items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCertificationsSection() {
    // Only show certifications section if vendor has verified status or documents
    return Consumer<VendorProvider>(
      builder: (context, vendorProvider, _) {
        final vendor = vendorProvider.getVendorById(_activeService.vendorId);
        final List<Widget> badges = [];
        
        // Add verified badge if vendor is verified
        if (vendor?.verified == true) {
          badges.add(_buildCertificationBadge('Verified Vendor', Icons.verified_user));
        }
        
        // Add approved badge if service is approved
        if (_activeService.approvalStatus == ApprovalStatus.approved) {
          badges.add(_buildCertificationBadge('Approved Service', Icons.check_circle));
        }
        
        // Add featured badge if applicable
        if (vendor?.featured == true) {
          badges.add(_buildCertificationBadge('Featured', Icons.star));
        }
        
        // Only show section if there are badges to display
        if (badges.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.only(top: 16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Certifications & Awards',
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
                children: badges,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCertificationBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amenities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ..._activeService.amenities!.map((amenity) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(amenity.toString(), style: const TextStyle(fontSize: 14, color: AppTheme.textPrimaryColor))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCancellationPolicySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
      child: ExpansionTile(
        leading: const Icon(Icons.policy, color: AppTheme.primaryColor),
        title: const Text(
          'Cancellation Policy',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _activeService.cancellationPolicy!,
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Consumer<ReviewProvider>(
      builder: (context, reviewProvider, child) {
        final reviews = reviewProvider.getReviewsForService(_activeService.id);
        final averageRating = reviewProvider.getAverageRating(_activeService.id);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reviews.isEmpty 
                        ? 'No reviews'
                        : '${averageRating.toStringAsFixed(1)} (${reviews.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      _showAddReviewDialog();
                    },
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Review', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                  ),
                ],
              ),
              if (reviews.isNotEmpty) ...[
                const SizedBox(height: 16),
                ...reviews.take(5).map((review) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Row(
                            children: List.generate(5, (index) => Icon(
                              index < review.rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                              size: 14,
                            )),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              review.customerName ?? 'Anonymous',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d').format(review.createdAt), // Shorter date
                            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        review.comment ?? '',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textPrimaryColor),
                      ),
                    ],
                  ),
                )),
                if (reviews.length > 5)
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // TODO: Show all reviews screen
                      },
                      child: const Text('View all reviews'),
                    ),
                  ),
              ] else ...[
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'Be the first to review this service!',
                    style: TextStyle(color: AppTheme.textSecondaryColor, fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAddReviewDialog() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review')),
      );
      return;
    }

    int selectedRating = 5;
    final TextEditingController commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Review'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate your experience:'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  icon: Icon(
                    index < selectedRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setDialogState(() {
                      selectedRating = index + 1;
                    });
                  },
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Write your comment here...',
                  border: OutlineInputBorder(),
                ),
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
                final success = await Provider.of<ReviewProvider>(context, listen: false).addReview(
                  serviceId: _activeService.id,
                  customerId: authProvider.userId!,
                  rating: selectedRating,
                  comment: commentController.text,
                );

                if (success) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review submitted successfully!'), backgroundColor: Colors.green),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to submit review'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Service'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Report functionality coming soon!'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report submitted successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Submit Report'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierSelection() {
    if (_activeService.pricingTiers.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: ResponsiveUtils.isWide(context) ? EdgeInsets.zero : const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Select Pricing Tier',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: _activeService.pricingTiers.map((tier) {
              final isSelected = _selectedTierId == tier.id;
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedTierId = tier.id;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : Colors.grey.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier.name ?? 'Tier',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            if (tier.description != null && tier.description!.isNotEmpty)
                              Text(
                                tier.description!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'RM ${tier.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          if (tier.minPax > 0)
                            Text(
                              'Min ${tier.minPax} pax',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Radio<String?>(
                        value: tier.id,
                        groupValue: _selectedTierId,
                        onChanged: (value) {
                          setState(() {
                            _selectedTierId = value;
                            // Sync internal pax count with tier's minimum pax
                            final selectedTier = _activeService.pricingTiers.firstWhere((t) => t.id == value);
                            _selectedPax = selectedTier.minPax;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vendor Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Consumer<VendorProvider>(
            builder: (context, vendorProvider, _) {
              final vendor = vendorProvider.getVendorById(_activeService.vendorId);
              final displayName = vendor?.name ?? _activeService.vendorName ?? _activeService.vendorId;
              final displayEmail = vendor?.email ?? _activeService.getVendorEmail();

              return Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Text(
                      displayName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        if (displayEmail != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            displayEmail,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor,
                            ),
                          ),
                        ],
                        Text(
                          '${vendor?.verified == true ? "Verified Vendor" : "Vendor"} • ${_getYearsInBusiness(vendor)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildVendorActionButtons(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVendorActionButtons() {
    return Column(
      children: [
        Consumer2<ChatProvider, VendorProvider>(
          builder: (context, chatProvider, vendorProvider, child) {
                      final vendor = vendorProvider.getVendorById(_activeService.vendorId);
                      final resolvedVendorId = vendor?.id ?? _activeService.vendorId; // Use Profile ID
                      final conversation = chatProvider.getConversationWithVendor(resolvedVendorId);
                      final unreadCount = conversation?.unreadCount ?? 0;
                      final isVendorLoading = vendor == null;

                      return Stack(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.chat, 
                              color: isVendorLoading ? Colors.grey : AppTheme.primaryColor
                            ),
                            onPressed: isVendorLoading 
                              ? null 
                              : () {
                                  final vEmail = vendor.email ?? 
                                      vendor.contactInfo['email'] ?? 
                                      _activeService.getVendorEmail() ?? 
                                      'info@${_activeService.vendorId.toLowerCase().replaceAll(' ', '')}.com';
                                  final vName = vendor.name ?? 
                                      _activeService.vendorName ?? 
                                      _activeService.vendorId;
                                  final vAvatar = vName.substring(0, 1).toUpperCase();

                                  // Create or get existing conversation
                                  final chatConversation = chatProvider.createConversation(
                                    vendorId: resolvedVendorId,
                                    vendorName: vName,
                                    vendorEmail: vEmail,
                                    vendorAvatar: vAvatar,
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
                                },
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 80,
                    child: ElevatedButton(
                      onPressed: () {
                        // Get vendor data from provider for accurate information
                        final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
                        final vendor = vendorProvider.getVendorById(_activeService.vendorId);
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VendorServicesScreen(
                              vendorId: _activeService.vendorId,
                              vendorName: vendor?.name ?? _activeService.vendorName ?? _activeService.vendorId,
                              vendorCategory: _activeService.category.name,
                              vendorDescription: vendor?.description ?? 'Professional ${_activeService.category.name} services',
                              vendorImage: vendor?.imageUrl ?? (vendor?.images.isNotEmpty == true ? vendor!.images.first : null) ?? ImageConstants.avatarPlaceholder,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        textStyle: const TextStyle(fontSize: 10),
                      ),
                      child: const Text('Visit Store'),
                    ),
                  ),
      ],
    );
  }

  Widget _buildRelatedServices() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Related Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _activeService.packages?.length ?? 0,
              itemBuilder: (context, index) {
                final service = _activeService.packages![index];
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          (_activeService.images?.isNotEmpty ?? false)
                              ? _activeService.images!.first
                              : ImageConstants.cateringPlaceholder,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, color: AppTheme.textSecondaryColor),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service.name,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              service.getAvailablePax().isNotEmpty 
                                ? 'RM ${service.getPriceForPax(service.getAvailablePax().first).toStringAsFixed(2)}'
                                : (service.priceByPax.isNotEmpty ? 'RM ${service.priceByPax.values.first.toStringAsFixed(2)}' : 'Contact for Price'),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomNavbar() {
    final bool isCompact = MediaQuery.of(context).size.width < 380;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: _getNavbarButtons(isCompact),
          ),
        ),
      ),
    );
  }

  List<Widget> _getNavbarButtons(bool isCompact) {
    final isDirectoryMode = !_activeService.allowedActions.contains('book') && 
                            !_activeService.allowedActions.contains('buy') && 
                            !_activeService.allowedActions.contains('rent');
    if (isDirectoryMode) {
      return [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _openChatWithVendor,
            icon: const Icon(Icons.chat, color: Colors.white),
            label: const Text('Inquire / Chat with Vendor', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ];
    }

    final category = _activeService.category.id.toLowerCase();
    final bool isProduct = category == 'doorgift' || category == 'fashion';

    switch (category) {
      case 'photography':
        return [
          _buildChatButton(isCompact),
          const SizedBox(width: 8),
          _buildViewPortfolioButton(isCompact),
          const SizedBox(width: 8),
          _buildBookSessionButton(isCompact),
        ];
      case 'catering':
        return [
          _buildChatButton(isCompact),
          const SizedBox(width: 8),
          if (isProduct) ...[
            _buildAddToCartButton(isCompact),
            const SizedBox(width: 8),
          ],
          _buildOrderCateringButton(isCompact),
        ];
      case 'beauty & makeup':
      case 'makeup':
      case 'busana':
        return [
          _buildChatButton(isCompact),
          const SizedBox(width: 8),
          _buildBookAppointmentButton(isCompact),
          const SizedBox(width: 8),
          _buildViewServicesButton(isCompact),
        ];
      default:
        return [
          _buildChatButton(isCompact),
          const SizedBox(width: 8),
          if (isProduct) ...[
            _buildAddToCartButton(isCompact),
            const SizedBox(width: 8),
          ],
          _buildBuyBookButton(isCompact),
        ];
    }
  }

  Widget _buildChatButton(bool isCompact) {
    return Expanded(
      flex: isCompact ? 0 : 1,
      child: Consumer2<ChatProvider, VendorProvider>(
        builder: (context, chatProvider, vendorProvider, child) {
          final vendor = vendorProvider.getVendorById(_activeService.vendorId);
          final resolvedVendorId = vendor?.id ?? _activeService.vendorId; // Use Profile ID
          final conversation = chatProvider.getConversationWithVendor(resolvedVendorId);
          final unreadCount = conversation?.unreadCount ?? 0;

          final isVendorLoading = vendor == null;

          return Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(isVendorLoading ? 0.05 : 0.1),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(isVendorLoading ? 0.3 : 1.0)),
            ),
            child: ElevatedButton.icon(
              onPressed: isVendorLoading 
                ? null 
                : () {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    if (!authProvider.isAuthenticated) {
                      GuestUtils.promptLogin(context, message: 'Please log in to chat with the vendor.');
                      return;
                    }
                    final vEmail = vendor.email ?? vendor.contactInfo['email'] ?? _activeService.getVendorEmail() ?? 'info@${_activeService.vendorId.toLowerCase().replaceAll(' ', '')}.com';
                    final vName = vendor.name ?? _activeService.vendorName ?? _activeService.vendorId;
                    final vAvatar = vName.substring(0, 1).toUpperCase();

                    // Create or get existing conversation
                    final chatConversation = chatProvider.createConversation(
                      vendorId: resolvedVendorId,
                      vendorName: vName,
                      vendorEmail: vEmail,
                      vendorAvatar: vAvatar,
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomerChatScreen(
                          conversation: chatConversation,
                          initialOrderRequest: {
                            'serviceId': _activeService.id,
                            'serviceName': _activeService.name,
                            'category': _activeService.category.displayName,
                            'quantity': _selectedPax ?? 1,
                            'price': _activeService.getPriceForPax(_selectedPax ?? 1),
                            'eventDate': _selectedDate,
                            'imageUrl': _activeService.images.isNotEmpty ? _activeService.images.first : null,
                            'notes': 'Inquiry about ${_activeService.name}' + 
                                     (_selectedPackage != null ? '\nPackage: ${_selectedPackage!.name}' : '') +
                                     (_selectedTierId != null ? '\nTier: ${_activeService.pricingTiers.firstWhere((t) => t.id == _selectedTierId).name}' : '') +
                                     (_selectedSeatingLayout != null ? '\nSeating: $_selectedSeatingLayout' : '') +
                                     (_selectedMenu != null ? '\nMenu: $_selectedMenu' : '') +
                                     (_selectedPax != null ? '\nGuest Count: $_selectedPax pax' : ''),
                          },
                        ),
                      ),
                    );
                  },
              icon: isVendorLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
                  )
                : Stack(
                    children: [
                      const Icon(Icons.chat, color: AppTheme.primaryColor),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
              label: isCompact ? const SizedBox.shrink() : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isVendorLoading ? 'Loading...' : 'Chat',
                  style: TextStyle(
                    color: isVendorLoading ? AppTheme.textSecondaryColor : AppTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddToCartButton(bool isCompact) {
    return Expanded(
      flex: isCompact ? 0 : 1,
      child: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final isInCart = cartProvider.isInCart(_activeService.id);
          final quantity = cartProvider.getItemQuantity(_activeService.id);

          return Container(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                if (!authProvider.isAuthenticated) {
                  GuestUtils.promptLogin(context, message: 'Please log in to add items to your cart.');
                  return;
                }
                if (isInCart) {
                  cartProvider.removeItem(_activeService.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from cart'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                } else {
                  // Determine price based on selected tier or min price
                  double finalPrice = _activeService.getMinPrice();
                  if (_selectedTierId != null) {
                    final tier = _activeService.pricingTiers.firstWhere(
                      (t) => t.id == _selectedTierId,
                      orElse: () => _activeService.pricingTiers.first,
                    );
                    finalPrice = tier.price;
                  }

                  String finalDescription = _activeService.description;
                  if (_selectedTierId != null) {
                    final tier = _activeService.pricingTiers.firstWhere(
                      (t) => t.id == _selectedTierId,
                      orElse: () => _activeService.pricingTiers.first,
                    );
                    finalDescription = '${tier.name}: $finalDescription';
                  }

                  cartProvider.addFromProductDetails(
                    serviceId: _activeService.id,
                    title: _activeService.name,
                    description: finalDescription,
                    price: finalPrice.toString(),
                    category: _activeService.category.name,
                    vendor: _activeService.vendorId,
                    vendorId: _activeService.vendorId,
                    vendorEmail: _activeService.getVendorEmail(),
                    imageUrl: (_activeService.images != null && _activeService.images!.isNotEmpty) ? _activeService.images!.first : '',
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Added to cart'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              icon: Icon(
                isInCart ? Icons.shopping_cart : Icons.add_shopping_cart,
                color: Colors.white,
              ),
              label: isCompact ? const SizedBox.shrink() : FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  isInCart ? 'In Cart' : 'Add to Cart',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBuyBookButton(bool isCompact) {
    return Expanded(
      child: _buildBuyBookButtonInternal(isCompact),
    );
  }

  Widget _buildBuyBookButtonInternal([bool isCompact = false]) {
    return Container(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: () {
          _handleBuyOrBook();
        },
        icon: Icon(
          _getBuyBookIcon(),
          color: Colors.white,
        ),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _getBuyBookText(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }

  Widget _buildViewPortfolioButton(bool isCompact) {
    return Expanded(
      flex: isCompact ? 0 : 1,
      child: Container(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Portfolio coming soon!'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.photo_library, color: Colors.white),
          label: isCompact ? const SizedBox.shrink() : const Text(
            'Portfolio', // Shorter label for mobile
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookSessionButton(bool isCompact) {
    return Expanded(
      flex: isCompact ? 0 : 1,
      child: Container(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking system coming soon!'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.event_available, color: Colors.white),
          label: isCompact ? const SizedBox.shrink() : const Text(
            'Book', // Shorter label for mobile
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCateringButton(bool isCompact) {
    return Expanded(
      child: Container(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            _handleBuyOrBook();
          },
          icon: const Icon(Icons.event_available, color: Colors.white),
          label: isCompact ? const SizedBox.shrink() : const Text(
            'Book',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookAppointmentButton(bool isCompact) {
    return Expanded(
      child: Container(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appointment booking coming soon!'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.calendar_today, color: Colors.white),
          label: isCompact ? const SizedBox.shrink() : const Text(
            'Book Appt',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewServicesButton(bool isCompact) {
    return Expanded(
      flex: isCompact ? 0 : 1,
      child: Container(
        height: 48,
        child: ElevatedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Services list coming soon!'),
                duration: Duration(seconds: 1),
              ),
            );
          },
          icon: const Icon(Icons.list, color: Colors.white),
          label: isCompact ? const SizedBox.shrink() : const Text(
            'Services',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getBuyBookIcon() {
    // Determine icon based on vendor category
    switch (_activeService.category.name.toLowerCase()) {
      case 'catering':
      case 'photography':
      case 'fashion':
      case 'decoration':
      case 'entertainment':
      case 'beauty & makeup':
      case 'music & dj':
        return Icons.shopping_bag; // Buy for product-based services
      case 'venue':
      case 'venues':
      case 'transportation':
        return Icons.event_available; // Book for appointment-based services
      default:
        return Icons.shopping_cart; // Default to buy
    }
  }

  String _getBuyBookText() {
    // Determine text based on vendor category
    switch (_activeService.category.name.toLowerCase()) {
      case 'catering':
      case 'photography':
      case 'decoration':
      case 'entertainment':
      case 'beauty & makeup':
      case 'henna artist':
      case 'hennaartist':
      case 'makeup artist':
      case 'music & dj':
      case 'venue':
      case 'venues':
      case 'transportation':
        return 'Book Now'; 
      case 'fashion':
      case 'doorgift':
      case 'product':
        return 'Buy Now';
      default:
        return _activeService.type == ServiceType.service ? 'Book Now' : 'Buy Now';
    }
  }

  void _handleBuyOrBook() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      GuestUtils.promptLogin(context, message: 'Please log in to book this service.');
      return;
    }

    // Check if the service is a product that should go straight to checkout
    final categoryId = _activeService.category.id.toLowerCase();
    final isProductFlow = categoryId == 'doorgift' || categoryId == 'fashion' || categoryId == 'product';

    if (isProductFlow) {
      final cartProvider = Provider.of<CartProvider>(context, listen: false);
      
      double finalPrice = _activeService.getMinPrice();
      String finalDescription = _activeService.description;
      
      if (_selectedTierId != null) {
        final tier = _activeService.pricingTiers.firstWhere(
          (t) => t.id == _selectedTierId,
          orElse: () => _activeService.pricingTiers.first,
        );
        finalPrice = tier.price;
        finalDescription = '${tier.name}: $finalDescription';
      }

      await cartProvider.addFromProductDetails(
        serviceId: _activeService.id,
        title: _activeService.name,
        description: finalDescription,
        price: finalPrice.toString(),
        category: _activeService.category.name,
        vendor: _activeService.vendorId,
        vendorId: _activeService.vendorId,
        vendorEmail: _activeService.getVendorEmail(),
        imageUrl: (_activeService.images != null && _activeService.images!.isNotEmpty) ? _activeService.images!.first : '',
        quantity: _selectedPax ?? 1,
        eventDate: _selectedDate,
        readyDate: _selectedDate != null && _activeService.productionDays != null
            ? _selectedDate!.subtract(Duration(days: _activeService.productionDays!))
            : null,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        );
      }
      return;
    }

    // Get vendor from provider
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    var vendor = vendorProvider.getVendorById(_activeService.vendorId);

    if (vendor == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      vendor = await vendorProvider.fetchVendorById(_activeService.vendorId);
      if (mounted) Navigator.pop(context); // close loading
    }

    if (vendor == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vendor information not available'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (mounted) {
      // Navigate to booking screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookingScreenEnhanced(
            vendor: vendor!,
            serviceId: _activeService.id,
            initialDate: _selectedDate,
            initialDateRange: _selectedDateRange,
            initialEventType: _selectedEventType,
            initialPackageId: _selectedPackage?.id,
            initialPax: _selectedPax,
            initialTierId: _selectedTierId,
            initialSelectedItems: _selectedItemsByComponent,
          ),
        ),
      );
    }
  }

  void _shareService() {
    final serviceName = _activeService.name;
    final category = _activeService.category.displayName ?? _activeService.category.name;
    final price = _getDisplayPrice();
    final description = _activeService.description;
    final vendor = _activeService.vendorId;

    final shareText = '''
Check out this amazing service on EventEase!

📋 Service: $serviceName
🏷️ Category: $category
💰 Price: $price
📝 Description: $description

👨‍💼 Provided by: $vendor

Download EventEase app to book now!
    '''.trim();

    Share.share(shareText);
  }

  // Enhanced venue detail view like Venuerific and AskVenue
  Widget _buildVenueDetailView(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          // Hero Image Section with Overlay
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Image Gallery
                  _buildVenueHeroGallery(),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  // Top Actions Overlay
                  Positioned(
                    top: 40,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withOpacity(0.5),
                          ),
                        ),
                        Row(
                          children: [
                            Consumer<FavoritesProvider>(
                              builder: (context, favoritesProvider, child) {
              final isFavorited = favoritesProvider.isFavorited(_activeService.id);
                                return IconButton(
                                  onPressed: () {
                                    favoritesProvider.toggleFavorite(_activeService.id, FavoriteType.service);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          isFavorited ? 'Removed from favorites' : 'Added to favorites'
                                        ),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  icon: Icon(
                                    isFavorited ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorited ? Colors.red : Colors.white,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black.withOpacity(0.5),
                                  ),
                                );
                              },
                            ),
                            Consumer<CompareProvider>(
                              builder: (context, compareProvider, child) {
                                final isInCompare = compareProvider.isInCompareList(_activeService.id);
                                return IconButton(
                                  onPressed: () {
                                    if (isInCompare) {
                                      compareProvider.removeFromCompare(_activeService.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Removed from comparison'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    } else if (compareProvider.canAddToCompare()) {
                                      compareProvider.addToCompare(_activeService);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Added to comparison (${compareProvider.currentCount}/${compareProvider.maxItems})'),
                                          duration: const Duration(seconds: 1),
                                        ),
                                      );
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Maximum comparison items reached (4)'),
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    isInCompare ? Icons.compare_arrows : Icons.compare_arrows_outlined,
                                    color: isInCompare ? AppTheme.primaryColor : Colors.white,
                                  ),
                                  style: IconButton.styleFrom(
                                    backgroundColor: Colors.black.withOpacity(0.5),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Share functionality coming soon!'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.share, color: Colors.white),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Bottom Info Overlay
                  Positioned(
                    bottom: 20,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating and Reviews
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '4.8',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(120 reviews)',
                                    style: TextStyle(
                                      color: AppTheme.textSecondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Title and Price
                        Text(
                          _activeService.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'Kuala Lumpur, Malaysia',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Price: ${_getDisplayPrice()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Sections
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick Stats
                _buildVenueQuickStats(),

                // Description
                _buildVenueDescription(),

                // Key Features
                _buildVenueKeyFeatures(),

                // Pax Selection (Only show if no pricing tiers)
                if (_activeService.hasPackagePricing && _activeService.pricingTiers.isEmpty)
                  _buildPaxSelection(),

                // What's Included
                _buildServiceComponents(),

                // Location & Map
                _buildVenueLocation(),

                // Availability Calendar
                // Availability Calendar
                _buildAvailabilitySection(),

                // Pricing Details
                _buildVenuePricing(),
                
                // Installment Info
                if (_activeService.installmentEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: _buildInstallmentInfo(),
                  ),
                
                // Tier Selection
                _buildTierSelection(),

                // Reviews
                if (_activeService.reviews != null && _activeService.reviews!.isNotEmpty)
                  _buildReviewsSection(),

                // Similar Venues
                _buildSimilarVenues(),

                // Vendor Info
                _buildVendorInfo(),

                const SizedBox(height: 100), // Space for bottom navbar
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildVenueBottomNavbar(),
    );
  }

  Widget _buildVenueHeroGallery() {
    final List<String> images = [
      (_activeService.images?.isNotEmpty ?? false) ? _activeService.images!.first : '',
      'https://images.unsplash.com/photo-1465495976277-4387d4b0e4a6?w=400&h=300&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?w=400&h=300&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop&crop=center',
      'https://images.unsplash.com/photo-1519741497674-611481863552?w=400&h=300&fit=crop&crop=center',
    ];

    return PageView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Image.network(
          images[index],
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[200],
              child: const Icon(
                Icons.image,
                size: 64,
                color: AppTheme.textSecondaryColor,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVenueQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildVenueStatItem('Capacity', '200 guests', Icons.people),
          _buildVenueStatItem('Area', '2,000 sq ft', Icons.aspect_ratio),
          _buildVenueStatItem('Parking', '50 spaces', Icons.local_parking),
          _buildVenueStatItem('Rooms', '3 halls', Icons.meeting_room),
        ],
      ),
    );
  }

  Widget _buildVenueStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildVenueDescription() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About This Venue',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _activeService.description,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          // Event Types
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'Weddings',
              'Corporate Events',
              'Birthday Parties',
              'Anniversaries',
              'Conferences',
            ].map((type) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                type,
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueKeyFeatures() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Key Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (_activeService.amenities != null && _activeService.amenities!.isNotEmpty)
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 3,
              children: _activeService.amenities!.map((amenity) => Row(
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      amenity,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              )).toList(),
            ),
        ],
    ),
    );
  }

  Widget _buildVenueLocation() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Location & Nearby',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          // Map Placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 48, color: AppTheme.textSecondaryColor),
                  SizedBox(height: 8),
                  Text('Interactive Map Coming Soon'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Address
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '123 Jalan Bukit Bintang, Kuala Lumpur, Malaysia',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Nearby Attractions
          const Text(
            'Nearby Attractions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              'KLCC (2.5 km)',
              'Petronas Towers (2.7 km)',
              'Central Market (1.8 km)',
              'Batu Caves (12 km)',
            ].map((attraction) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.place, color: AppTheme.textSecondaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    attraction,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueAvailability() {
    final timeRule = _activeService.timeRule;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Availability & Booking',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (timeRule != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              timeRule.timeType.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            if (timeRule.startTime != null && timeRule.endTime != null)
                              Text(
                                'Daily: ${timeRule.startTime} - ${timeRule.endTime}',
                                style: const TextStyle(color: AppTheme.textSecondaryColor),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (timeRule.sessions.isNotEmpty) ...[
                    const Divider(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Available Sessions', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    ...timeRule.sessions.map((session) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(session.name, style: const TextStyle(fontSize: 14)),
                          Text('${session.startTime} - ${session.endTime}', 
                               style: const TextStyle(fontSize: 14, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )),
                  ] else if ((_activeService.availability['timeSlots'] ?? _activeService.options['timeSlots']) is List) ...[
                    const Divider(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Available Sessions', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(height: 8),
                    ...((_activeService.availability['timeSlots'] ?? _activeService.options['timeSlots']) as List).map((slot) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(slot['name']?.toString() ?? 'Session', style: const TextStyle(fontSize: 14)),
                          Text('${slot['start']} - ${slot['end']}', 
                               style: const TextStyle(fontSize: 14, color: AppTheme.primaryColor, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    )),
                  ],
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: AppTheme.textSecondaryColor),
                      SizedBox(width: 4),
                      Text('Contact vendor to verify specific dates', 
                           style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                    ],
                  ),
                ],
              ),
            )
          else
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('Standard business hours apply', 
                           style: TextStyle(color: AppTheme.textSecondaryColor)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVenuePricing() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          // Pricing Breakdown
          Container(
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
                if (_activeService.pricingTiers.isNotEmpty)
                  ..._activeService.pricingTiers.map((tier) {
                    final isSelected = _selectedTierId == tier.id;
                    return _buildPricingRow(
                      '${tier.name} (${tier.minPax}+ pax)', 
                      'RM ${tier.price.toStringAsFixed(2)}',
                      isTotal: isSelected,
                    );
                  }).toList()
                else if (_activeService.packages?.isNotEmpty ?? false)
                  ..._activeService.packages!.map((pkg) {
                    final isSelected = _selectedPackage?.id == pkg.id;
                    return _buildPricingRow(
                      pkg.name, 
                      'RM ${pkg.basePrice.toStringAsFixed(2)}',
                      isTotal: isSelected,
                    );
                  }).toList()
                else
                  _buildPricingRow('Base Price', 'RM ${_activeService.price.toStringAsFixed(2)}'),
                
                if (_activeService.logisticsConfig != null)
                  _buildPricingRow('Setup & Logistics', 'Included'),
                
                const Divider(),
                _buildPricingRow(
                  _selectedPax != null ? 'Selected Price' : 'Starting From', 
                  _getDisplayPrice(), 
                  isTotal: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '* Prices are estimates and may vary based on date, time, and specific requirements.',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingRow(String label, String price, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            price,
            style: TextStyle(
              fontSize: isTotal ? 18 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarVenues() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Similar Venues',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          ImageConstants.plannerPlaceholder,
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 100,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image, color: AppTheme.textSecondaryColor),
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Similar Venue ${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'From RM 120/person',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVenueBottomNavbar() {
    return Consumer2<ChatProvider, VendorProvider>(
      builder: (context, chatProvider, vendorProvider, child) {
        final vendor = vendorProvider.getVendorById(_activeService.vendorId);
        final resolvedVendorId = vendor?.id ?? _activeService.vendorId;
        final vName = vendor?.name ?? _activeService.vendorName ?? _activeService.vendorId;
        final vEmail = vendor?.email ?? 
                      vendor?.contactInfo['email'] ?? 
                      _activeService.getVendorEmail() ?? 
                      'info@${_activeService.vendorId.toLowerCase().replaceAll(' ', '')}.com';
        final vAvatar = vName.substring(0, 1).toUpperCase();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Virtual Tour Button
              if (_activeService.category.id.toLowerCase() == 'venue' || _activeService.category.id.toLowerCase() == 'venues')
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppTheme.primaryColor),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Virtual tour coming soon!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: const Icon(Icons.videocam, color: AppTheme.primaryColor),
                      label: const Text(
                        'Tour',
                        style: TextStyle(color: AppTheme.primaryColor, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Contact Button
              Expanded(
                child: Container(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final chatConversation = chatProvider.createConversation(
                        vendorId: resolvedVendorId,
                        vendorName: vName,
                        vendorEmail: vEmail,
                        vendorAvatar: vAvatar,
                      );

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CustomerChatScreen(
                            conversation: chatConversation,
                            initialOrderRequest: {
                              'serviceId': _activeService.id,
                              'serviceName': _activeService.name,
                              'category': _activeService.category.displayName,
                              'quantity': _selectedPax ?? 1,
                              'price': _getDisplayPrice(),
                              'eventDate': _selectedDate,
                              'imageUrl': _activeService.images.isNotEmpty ? _activeService.images.first : null,
                              'notes': 'Inquiry about ${_activeService.name}' + 
                                       (_selectedPackage != null ? '\nPackage: ${_selectedPackage!.name}' : '') +
                                       (_selectedTierId != null ? '\nTier: ${_activeService.pricingTiers.firstWhere((t) => t.id == _selectedTierId).name}' : '') +
                                       (_selectedPax != null ? '\nGuest Count: $_selectedPax pax' : ''),
                            },
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat, color: Colors.white, size: 20),
                    label: const Text(
                      'Chat',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.secondaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Book Now Button
              Expanded(
                child: Container(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _handleBuyOrBook();
                    },
                    icon: const Icon(Icons.event_available, color: Colors.white, size: 20),
                    label: Text(
                      _activeService.type == ServiceType.service ? 'Book Now' : 'Buy Now',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Service Package detailed sections
  Widget _buildVenueDetailsSection() {
    final venueDetails = widget.servicePackage!.venueDetails;
    if (venueDetails == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Venue Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Venue Name and Address
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venueDetails.venueName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      venueDetails.address,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Capacity
          Row(
            children: [
              const Icon(Icons.people, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Capacity: ${venueDetails.minCapacity} - ${venueDetails.maxCapacity} guests',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Event Theme
          Row(
            children: [
              const Icon(Icons.palette, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Theme: ${venueDetails.eventTheme}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Event Times
          if (venueDetails.eventTimes.isNotEmpty) ...[
            const Text(
              'Event Schedule',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...venueDetails.eventTimes.entries.map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${entry.key}: ${entry.value}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Facility Inclusions
          if (venueDetails.facilityInclusions.isNotEmpty) ...[
            const Text(
              'Facility Inclusions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...venueDetails.facilityInclusions.map((facility) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      facility,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Decoration Equipment
          if (venueDetails.decorationEquipment.isNotEmpty) ...[
            const Text(
              'Decoration & Equipment',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: venueDetails.decorationEquipment.map((equipment) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  equipment,
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageMenusSection() {
    final menus = widget.servicePackage!.menus;
    if (menus == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Package Menus',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Main Menu
          if (menus.mainMenu.isNotEmpty) ...[
            const Text(
              'Main Menu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...menus.mainMenu.map((dish) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.restaurant, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dish,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Bridal Dishes
          if (menus.bridalDishes.isNotEmpty) ...[
            const Text(
              'Bridal Dishes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...menus.bridalDishes.map((dish) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.favorite, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dish,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Tea Corner
          if (menus.teaCorner != null) ...[
            const Text(
              'Tea Corner',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Fruits
            if (menus.teaCorner!.fruits.isNotEmpty) ...[
              const Text(
                'Fruits',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: menus.teaCorner!.fruits.map((fruit) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    fruit,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Drinks
            if (menus.teaCorner!.drinks.isNotEmpty) ...[
              const Text(
                'Drinks',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: menus.teaCorner!.drinks.map((drink) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    drink,
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Beverages
            if (menus.teaCorner!.beverages.isNotEmpty) ...[
              const Text(
                'Beverages',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: menus.teaCorner!.beverages.map((beverage) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    beverage,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Snacks
            if (menus.teaCorner!.snacks.isNotEmpty) ...[
              const Text(
                'Snacks',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: menus.teaCorner!.snacks.map((snack) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    snack,
                    style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Desserts
            if (menus.teaCorner!.desserts.isNotEmpty) ...[
              const Text(
                'Desserts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: menus.teaCorner!.desserts.map((dessert) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.pink.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    dessert,
                    style: const TextStyle(
                      color: Colors.pink,
                      fontSize: 12,
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 8),
            ],

            // Water Service
            if (menus.teaCorner!.waterService.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.local_drink, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      menus.teaCorner!.waterService,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ],

          // Side Dishes
          if (menus.sideDishes.isNotEmpty) ...[
            const Text(
              'Side Dishes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...menus.sideDishes.map((dish) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.restaurant_menu, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dish,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildPackageInclusionsSection() {
    final inclusions = widget.servicePackage!.inclusions;
    if (inclusions == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Package Inclusions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),

          // Common Facilities
          if (inclusions.commonFacilities.isNotEmpty) ...[
            const Text(
              'Facilities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...inclusions.commonFacilities.map((facility) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.business, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      facility,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Common Decorations
          if (inclusions.commonDecorations.isNotEmpty) ...[
            const Text(
              'Decorations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...inclusions.commonDecorations.map((decoration) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.palette, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      decoration,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Common Services
          if (inclusions.commonServices.isNotEmpty) ...[
            const Text(
              'Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...inclusions.commonServices.map((service) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.room_service, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      service,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
          ],

          // Photography Services
          if (inclusions.photographyServices.isNotEmpty) ...[
            const Text(
              'Photography Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            ...inclusions.photographyServices.map((photoService) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      photoService,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    final facilities = widget.servicePackage!.facilities;
    if (facilities.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Facilities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...facilities.map((facility) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    facility,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    final services = widget.servicePackage!.services;
    if (services.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...services.map((service) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.room_service, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    service,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPhotographySection() {
    final photography = widget.servicePackage!.photography;
    if (photography.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photography',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...photography.map((photoItem) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.camera_alt, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    photoItem,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildAdditionalDetailsSection() {
    final additionalDetails = widget.servicePackage!.additionalDetails;
    if (additionalDetails.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Additional Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...additionalDetails.entries.map((entry) {
            final key = entry.key;
            final value = entry.value;

            if (value is List) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      key.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...value.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              );
            } else {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 120,
                      child: Text(
                        '${key.replaceAll('_', ' ')}:',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        value.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget _buildProductQuantitySection() {
    return Container(
      margin: ResponsiveUtils.isWide(context) ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor),
               const SizedBox(width: 8),
               const Expanded(
                 child: Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
               ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove),
                        color: AppTheme.primaryColor,
                        onPressed: () {
                          if ((_selectedPax ?? 1) > 1) {
                            setState(() {
                              _selectedPax = (_selectedPax ?? 1) - 1;
                              _quantityController.text = _selectedPax.toString();
                            });
                          }
                        },
                      ),
                      SizedBox(
                        width: 60,
                        child: TextField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (value) {
                            final pax = int.tryParse(value);
                            if (pax != null && pax > 0) {
                              _selectedPax = pax;
                            } else {
                              _selectedPax = 1;
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        color: AppTheme.primaryColor,
                        onPressed: () {
                          setState(() {
                            _selectedPax = (_selectedPax ?? 1) + 1;
                            _quantityController.text = _selectedPax.toString();
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_activeService.minOrderQty != null && _activeService.minOrderQty! > 0) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Minimum Order: ${_activeService.minOrderQty} units',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],

          if (_activeService.productionDays != null && _activeService.productionDays! > 0) ...[
            const SizedBox(height: 8),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Production Time: ${_activeService.productionDays} days',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Divider(height: 32),
          
          // Event Date Selection for Products
          const Row(
            children: [
              Icon(Icons.event, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Event Date',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us when is your event so we can prepare your order.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                   Icon(Icons.calendar_today, color: _selectedDate != null ? AppTheme.primaryColor : Colors.grey),
                   const SizedBox(width: 12),
                   Text(
                    _selectedDate != null 
                        ? DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate!) 
                        : 'Select your event date',
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDate != null ? AppTheme.textPrimaryColor : Colors.grey,
                      fontWeight: _selectedDate != null ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
              ),
            ),
          ),

          if (_selectedDate != null && _activeService.productionDays != null) ...[
             const SizedBox(height: 16),
             _buildSmartLogicFeedback(),
          ],
        ],
      ),
    );
  }

  Widget _buildSmartLogicFeedback() {
    if (_selectedDate == null || _activeService.productionDays == null) return const SizedBox.shrink();
    
    final daysUntilEvent = _selectedDate!.difference(DateTime.now()).inDays;
    final isPossible = daysUntilEvent >= _activeService.productionDays!;
    final readyDate = DateTime.now().add(Duration(days: _activeService.productionDays!));
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPossible ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPossible ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isPossible ? Icons.check_circle : Icons.error_outline,
                color: isPossible ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isPossible 
                      ? '✓ Perfect! Will be ready before your event.' 
                      : '⚠️ Too late to order! Need at least ${_activeService.productionDays} days.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isPossible ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (isPossible)
            Text(
              'Earliest ready date: ${DateFormat('dd MMM').format(readyDate)}',
              style: TextStyle(fontSize: 12, color: Colors.green[600]),
            ),
        ],
      ),
    );
  }

  Widget _buildAvailabilitySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.event_available, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text(
                'Availability & Booking',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Calendar View
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365 * 2)),
            focusedDay: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
            currentDay: DateTime.now(),
            rangeSelectionMode: (_activeService.category == EventCategory.venue || 
                                _activeService.category.id.toLowerCase().contains('venue') ||
                                _activeService.minRentalDays != null ||
                                _activeService.maxRentalDays != null) 
                                ? RangeSelectionMode.enforced 
                                : RangeSelectionMode.disabled,
            rangeStartDay: _selectedDateRange?.start,
            rangeEndDay: _selectedDateRange?.end,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDate, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDate = selectedDay;
                _selectedDateRange = null; // Reset range if single day is picked
              });
            },
            onRangeSelected: (start, end, focusedDay) {
              setState(() {
                _selectedDate = start;
                if (start != null && end != null) {
                   // Check min/max duration if set
                   final duration = end.difference(start).inDays + 1;
                   _selectedDateRange = DateTimeRange(start: start, end: end);
                } else if (start != null) {
                  _selectedDateRange = DateTimeRange(start: start, end: start);
                }
              });
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              rangeStartDecoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              rangeHighlightColor: AppTheme.primaryColor.withOpacity(0.1),
              todayDecoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(color: AppTheme.primaryColor),
              markerDecoration: const BoxDecoration(
                color: AppTheme.accentColor,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
          
          if (_selectedDate != null) ...[
            const SizedBox(height: 16),
            _buildSelectedDateIndicator(),
            if (_selectedDateRange != null && (_activeService.minRentalDays != null || _activeService.maxRentalDays != null))
               Padding(
                 padding: const EdgeInsets.only(top: 12.0),
                 child: _buildRentalDurationFeedback(),
               ),
          ],

          // Event Type Selection
          if (_activeService.eventTypes.isNotEmpty) ...[
            const Divider(height: 32),
            _buildEventTypeSelection(),
          ],

          // Installment Info
          if (_activeService.installmentEnabled) ...[
            const Divider(height: 32),
            _buildInstallmentInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildRentalDurationFeedback() {
    if (_selectedDateRange == null) return const SizedBox.shrink();
    
    final duration = _selectedDateRange!.end.difference(_selectedDateRange!.start).inDays + 1;
    final min = _activeService.minRentalDays ?? 1;
    final max = _activeService.maxRentalDays;
    
    bool isValid = true;
    String message = 'Duration: $duration day${duration > 1 ? "s" : ""}';
    
    if (duration < min) {
      isValid = false;
      message = 'Minimum $min days required for this rental.';
    } else if (max != null && duration > max) {
      isValid = false;
      message = 'Maximum $max days allowed for this rental.';
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isValid ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.info_outline : Icons.warning_amber_rounded,
            color: isValid ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isValid ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openChatWithVendor() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isAuthenticated) {
      GuestUtils.promptLogin(context, message: 'Please log in to chat with the vendor.');
      return;
    }

    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final vendor = await vendorProvider.fetchVendorById(_activeService.vendorId);
    
    if (vendor == null || vendor.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendor chat is currently unavailable.')),
      );
      return;
    }

    if (!mounted) return;
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final conversation = chatProvider.createConversation(
      vendorId: vendor.userId!,
      vendorName: vendor.name,
      vendorEmail: vendor.email ?? vendor.contactInfo['email'] ?? '',
      vendorPhone: vendor.phone ?? vendor.contactInfo['phone'] ?? '+60123456789',
      vendorAvatar: vendor.name.isNotEmpty ? vendor.name.substring(0, 1).toUpperCase() : 'V',
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerChatScreen(conversation: conversation),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryId) {
     categoryId = categoryId.toLowerCase();
     if (categoryId.contains('venue')) return Icons.location_on;
     if (categoryId.contains('catering')) return Icons.restaurant;
     if (categoryId.contains('photo')) return Icons.camera_alt;
     if (categoryId.contains('makeup')) return Icons.face;
     if (categoryId.contains('doorgift')) return Icons.card_giftcard;
     return Icons.stars;
  }
}
