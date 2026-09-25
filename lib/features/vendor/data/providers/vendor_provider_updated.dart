import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/services/service_enums.dart';
import '../../../../shared/models/services/service_category.dart';
import '../models/vendor.dart';
import '../../models/vendor_service_enhanced.dart';
import '../../models/vendor_service.dart';
import '../../../../shared/models/other/venue.dart';
import 'vendor_profile_provider.dart';
import '../../models/service_template_models.dart';
import '../models/vendor_installment_settings.dart';
import '../../../../core/services/admin_notification_service.dart';

class VendorProvider extends ChangeNotifier {
  final List<Vendor> _vendors = [];
  final List<Venue> _venues = [];
  final List<ServiceCategory> _serviceCategories = [];
  Vendor? _currentVendor;
  final Map<String, bool> _vendorFavorites = {};
  final Map<String, bool> _venueFavorites = {};
  bool _isLoading = false;
  String? _error;

  // Custom services storage - Map of vendorId to list of custom services
  final Map<String, List<VendorServiceEnhanced>> _customServices = {};

  // Getters
  List<Vendor> get vendors => List.unmodifiable(_vendors);
  List<Venue> get venues => List.unmodifiable(_venues);
  List<ServiceCategory> get serviceCategories => List.unmodifiable(_serviceCategories);
  List<dynamic> get allItems => [..._vendors, ..._venues];
  bool get isLoading => _isLoading;
  String? get error => _error;
  Vendor? get currentVendor => _currentVendor;
  List<VendorServiceEnhanced> get allServices {
    final all = <VendorServiceEnhanced>[];
    for (var list in _customServices.values) {
      all.addAll(list);
    }
    return all;
  }

  VendorProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    await loadVendors();
    await loadVenues();
  }

  Future<void> loadVendors() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await SupabaseService.select(
        table: 'vendor_profiles',
        orderBy: 'priority_score',
        ascending: false,
      );
      _vendors.clear();
      if (data.isNotEmpty) {
        _vendors.addAll(data.map((json) => Vendor.fromSupabase(json)).toList());
      } else {
        // Handle empty state - no vendors found in DB
      }
    } catch (e) {
      print('Error loading vendors: $e');
      _error = 'Failed to load vendors';
      _vendors.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _ensureWeddingPlannerVendors() {
    // This previously merged sample data. Now we only rely on Supabase.
  }

  Future<void> loadVenues() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await SupabaseService.select(
        table: 'vendor_services',
        filters: {'category': 'Venue', 'is_active': true},
      );
      _venues.clear();
      _venues.addAll(data.map((json) => Venue.fromSupabase(json)).toList());
    } catch (e) {
      print('Error loading venues: $e');
      _error = 'Failed to load venues';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get filtered vendors by category
  List<Vendor> getVendorsByCategory(String category) {
    return _vendors
        .where((v) => v.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Wedding & event planners for the home screen section (Wedding Planner + Event Planner)
  List<Vendor> getWeddingPlannerVendors() {
    return _vendors
        .where((v) => v.categories.any((c) {
              final lower = c.toLowerCase();
              return lower == 'wedding planner' || lower == 'event planner';
            }))
        .toList();
  }

  // Get favorite vendors
  List<Vendor> get favoriteVendors =>
      _vendors.where((v) => _vendorFavorites[v.id] == true).toList();

  // Get favorite venues
  List<Venue> get favoriteVenues =>
      _venues.where((v) => _venueFavorites[v.id] == true).toList();

  // Get favorite items
  List<dynamic> get favoriteItems => [...favoriteVendors, ...favoriteVenues];

  // Check if item is favorited
  bool isItemFavorited(String itemId) {
    return _vendorFavorites[itemId] == true || _venueFavorites[itemId] == true;
  }

  // Get vendor by ID
  Vendor? getVendorById(String vendorId) {
    if (_currentVendor?.id == vendorId) return _currentVendor;
    try {
      return _vendors.firstWhere((v) => v.id == vendorId);
    } catch (e) {
      return null;
    }
  }

  // Fetch vendor by ID from Supabase if not in memory
  Future<Vendor?> fetchVendorById(String vendorId) async {
    final existing = getVendorById(vendorId);
    if (existing != null) return existing;

    try {
      final data = await Supabase.instance.client
          .from('vendor_profiles')
          .select()
          .eq('id', vendorId)
          .maybeSingle();

      if (data != null) {
        final vendor = Vendor.fromSupabase(data);
        if (!_vendors.any((v) => v.id == vendor.id)) {
          _vendors.add(vendor);
          notifyListeners();
        }
        return vendor;
      }
    } catch (e) {
      print('Error fetching vendor by ID: $e');
    }
    return null;
  }

  // Get venue by ID
  Venue? getVenueById(String venueId) {
    try {
      return _venues.firstWhere((v) => v.id == venueId);
    } catch (e) {
      return null;
    }
  }

  // Get venues by vendor ID
  List<Venue> getVenuesByVendor(String vendorId) {
    return _venues.where((venue) => venue.vendorId == vendorId).toList();
  }

  // Get vendor by venue ID
  Vendor? getVendorByVenueId(String venueId) {
    final venue = getVenueById(venueId);
    if (venue != null) {
      return getVendorById(venue.vendorId);
    }
    return null;
  }

  // Get item by ID (vendor or venue)
  dynamic getItemById(String itemId) {
     final v = getVendorById(itemId);
     if (v != null) return v;
     return getVenueById(itemId);
  }

  // Load current vendor data from Supabase (Dashboard context)
  Future<void> loadCurrentVendorFromSupabase({bool force = false}) async {
    if (_currentVendor != null && !force) return;
    
    try {
      final profileProvider = VendorProfileProvider();
      await profileProvider.loadVendorProfile();
      
      if (profileProvider.vendorProfile != null) {
        _currentVendor = Vendor.fromSupabase(profileProvider.vendorProfile!);
        await loadVendorServices(_currentVendor!.id);
        _safeNotifyListeners();
      }
    } catch (e) {
      print('Error loading current vendor: $e');
    }
  }

  // Clear current vendor (e.g., on impersonation exit or logout)
  void clearCurrentVendor() {
    _currentVendor = null;
    _safeNotifyListeners();
  }

  // Explicitly set current vendor object (e.g., during impersonation)
  void setCurrentVendorObject(Vendor vendor) {
    _currentVendor = vendor;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  final Map<String, bool> _loadingServices = {};

  // Load services for a specific vendor
  Future<void> loadVendorServices(String vendorId) async {
    if (_loadingServices[vendorId] == true) return;
    _loadingServices[vendorId] = true;
    
    print('DEBUG: loadVendorServices for vendor: $vendorId');
    try {
      final response = await SupabaseService.select(
        table: 'vendor_services',
        filters: {'vendor_id': vendorId},
      );
      
      print('DEBUG: loadVendorServices found ${response.length} services for vendor $vendorId');
      
      List<VendorServiceEnhanced> services;
      if (response.isNotEmpty) {
        services = await Future.wait(response.map((json) async {
           final basic = VendorService.fromJson(json);
           var enhanced = basic.toEnhanced();
           try {
             enhanced = await _loadStructuredServiceData(enhanced);
           } catch (e) {
             print('Error loading structured data for service ${enhanced.id}: $e');
           }
           return enhanced;
        }));
      } else {
        services = [];
      }
      
      _customServices[vendorId] = services;
      _loadingServices[vendorId] = false;
      _safeNotifyListeners();
    } catch (e) {
      print('Error loading vendor services: $e');
      _customServices[vendorId] = [];
      _loadingServices[vendorId] = false;
      _safeNotifyListeners();
    }
  }

  List<VendorServiceEnhanced> getCurrentVendorServices() {
    if (_currentVendor == null) return [];
    return _customServices[_currentVendor!.id] ?? [];
  }

  List<VendorServiceEnhanced> getCurrentVendorServicesForId(String vendorId) {
    return _customServices[vendorId] ?? [];
  }
  
  List<VendorServiceEnhanced> getServicesForVendor(String vendorId) {
    return _customServices[vendorId] ?? [];
  }
  
  List<VendorServiceEnhanced> getCustomServices() {
    return allServices;
  }
  
  void setCurrentVendor(String emailOrId) {
    try {
       if (_vendors.isEmpty) {
         print('No vendors loaded');
         return;
       }
       _currentVendor = _vendors.firstWhere(
        (v) => v.email == emailOrId || v.id == emailOrId,
        orElse: () => _vendors.first,
      );
      loadVendorServices(_currentVendor!.id);
      _safeNotifyListeners();
    } catch (e) {
      print('Vendor not found: $emailOrId');
    }
  }

  Future<void> addCustomService(VendorServiceEnhanced service, {String? vendorId}) async {
    final targetVendorId = vendorId ?? _currentVendor?.id;
    if (targetVendorId == null) {
      throw Exception('Vendor ID is required to add a service');
    }
    
    try {
      final serviceData = {
        'vendor_id': targetVendorId,
        'name': service.name,
        'description': service.description,
        'category': service.productCategory.id,
        'subcategory': service.subcategory,
        'multi_layer_pricing': service.multiLayerPricing,
        'base_price': service.price,
        'is_active': service.isActive,
        'service_type': service.serviceType.name,
        'images': service.images,
        'service_status': service.status.name,
        'approval_status': 'pending', // Always reset to pending for new services
        'options': service.options,
        'availability': service.availability,
        'venue_address': service.venueAddress,
        'coverage_area': service.coverageArea,
        'supports_appointments': service.supportsAppointments,
        'supports_rentals': service.supportsRentals,
        'allowed_actions': service.allowedActions,
        'cancellation_policy': service.cancellationPolicy,
        'cancellation_policy_type': service.cancellationPolicyType,
        'time_rule': service.timeRule?.toJson(),
        'logistics_config': service.logisticsConfig?.toJson(),
        'original_price': service.originalPrice,
        'promo_expiry': service.promoExpiry?.toIso8601String(),
        'installment_enabled': service.installmentEnabled,
        'deposit_percentage': service.depositPercentage,
        'max_installments': service.maxInstallments,
        'payment_deadline_days': service.paymentDeadlineDays,
        'video_url': service.videoUrl,
        'product_logistics': service.productLogistics?.toJson(),
        'bulk_pricing_tiers': service.bulkPricingTiers?.map((e) => e.toJson()).toList(),
        'variations': service.variations?.map((e) => e.toJson()).toList(),
        'pricing_model': service.pricingModel?.toJson(),
      };

      print('SUPABASE: Saving to table "vendor_services"');
      print('DATA: $serviceData');

      final client = Supabase.instance.client;
      final response = await client
          .from('vendor_services')
          .insert(serviceData)
          .select()
          .single();
          
      var newService = VendorService.fromJson(response).toEnhanced();
      
      // Save Structured Data
      await _saveStructuredServiceData(newService.id, service);
      newService = await _loadStructuredServiceData(newService);
      
      if (!_customServices.containsKey(targetVendorId)) {
        _customServices[targetVendorId] = [];
      }
      _customServices[targetVendorId]!.add(newService);
      
      // Notify Admin
      final vendor = getVendorById(targetVendorId);
      await AdminNotificationService().notifyServiceUpdate(
        vendorId: targetVendorId,
        vendorName: vendor?.name ?? 'Unknown Vendor',
        serviceName: newService.name,
        serviceId: newService.id,
        isNew: true,
      );

      notifyListeners();
    } catch (e) {
       print('DEBUG: addCustomService error: $e');
       rethrow;
    }
  }

  Future<void> updateCustomService(String serviceId, VendorServiceEnhanced updatedService, {String? vendorId}) async {
    final targetVendorId = vendorId ?? _currentVendor?.id;
    if (targetVendorId == null) {
      throw Exception('Vendor ID is required to update a service');
    }
    
    try {
       final updateData = {
        'name': updatedService.name,
        'description': updatedService.description,
        'category': updatedService.productCategory.id,
        'subcategory': updatedService.subcategory,
        'multi_layer_pricing': updatedService.multiLayerPricing,
        'base_price': updatedService.price,
        'service_type': updatedService.serviceType.name,
        'images': updatedService.images,
        'service_status': updatedService.status.name,
        'approval_status': 'pending', // Reset to pending on edit for admin review
        'options': updatedService.options,
        'availability': updatedService.availability,
        'venue_address': updatedService.venueAddress,
        'coverage_area': updatedService.coverageArea,
        'supports_appointments': updatedService.supportsAppointments,
        'supports_rentals': updatedService.supportsRentals,
        'allowed_actions': updatedService.allowedActions,
        'cancellation_policy': updatedService.cancellationPolicy,
        'cancellation_policy_type': updatedService.cancellationPolicyType,
        'time_rule': updatedService.timeRule?.toJson(),
        'logistics_config': updatedService.logisticsConfig?.toJson(),
        'original_price': updatedService.originalPrice,
        'promo_expiry': updatedService.promoExpiry?.toIso8601String(),
        'installment_enabled': updatedService.installmentEnabled,
        'deposit_percentage': updatedService.depositPercentage,
        'max_installments': updatedService.maxInstallments,
        'payment_deadline_days': updatedService.paymentDeadlineDays,
        'video_url': updatedService.videoUrl,
        'product_logistics': updatedService.productLogistics?.toJson(),
        'bulk_pricing_tiers': updatedService.bulkPricingTiers?.map((e) => e.toJson()).toList(),
        'variations': updatedService.variations?.map((e) => e.toJson()).toList(),
        'pricing_model': updatedService.pricingModel?.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
       };

       print('SUPABASE: Updating table "vendor_services" with ID $serviceId');
       print('DATA: $updateData');

       final client = Supabase.instance.client;
       final response = await client
          .from('vendor_services')
          .update(updateData)
          .eq('id', serviceId)
          .select()
          .single();

       // Save Structured Data
       await _saveStructuredServiceData(serviceId, updatedService);

       var loadedService = VendorService.fromJson(response).toEnhanced();
       loadedService = await _loadStructuredServiceData(loadedService);

       final services = _customServices[targetVendorId];
       if (services != null) {
          final index = services.indexWhere((s) => s.id == serviceId);
           if (index != -1) {
            services[index] = loadedService;

            // Notify Admin
            final vendor = getVendorById(targetVendorId);
            await AdminNotificationService().notifyServiceUpdate(
              vendorId: targetVendorId,
              vendorName: vendor?.name ?? 'Unknown Vendor',
              serviceName: loadedService.name,
              serviceId: loadedService.id,
              isNew: false,
            );

            notifyListeners();
          }
       }
    } catch (e) {
      print('DEBUG: updateCustomService error: $e');
      rethrow;
    }
  }

  Future<void> removeCustomService(String serviceId, {String? vendorId}) async {
    String? targetVendorId = vendorId;
    
    // If vendorId not provided, try to find it in our map
    if (targetVendorId == null) {
      for (var entry in _customServices.entries) {
        if (entry.value.any((s) => s.id == serviceId)) {
          targetVendorId = entry.key;
          break;
        }
      }
    }
    
    // Fallback to current vendor if still null
    if (targetVendorId == null && _currentVendor != null) {
      targetVendorId = _currentVendor!.id;
    }

    if (targetVendorId == null) {
      print('Error: Could not determine vendor for service deletion $serviceId');
      return;
    }
    
    try {
      final client = Supabase.instance.client;
      await client
        .from('vendor_services')
        .delete()
        .eq('id', serviceId);
        
      final services = _customServices[targetVendorId];
      if (services != null) {
        services.removeWhere((s) => s.id == serviceId);
        notifyListeners();
      }
    } catch (e) {
      print('Error deleting service: $e');
      throw e;
    }
  }

  Future<void> toggleCustomServiceStatus(String serviceId, {String? vendorId}) async {
    String? targetVendorId = vendorId;
    
    // If vendorId not provided, try to find it in our map
    if (targetVendorId == null) {
      for (var entry in _customServices.entries) {
        if (entry.value.any((s) => s.id == serviceId)) {
          targetVendorId = entry.key;
          break;
        }
      }
    }
    
    // Fallback to current vendor if still null
    if (targetVendorId == null && _currentVendor != null) {
      targetVendorId = _currentVendor!.id;
    }
    
    if (targetVendorId == null) {
      print('Error: Could not determine vendor for service $serviceId');
      return;
    }
    
    final services = _customServices[targetVendorId];
    if (services == null) return;
    
    final index = services.indexWhere((s) => s.id == serviceId);
    if (index == -1) return;
    
    final currentService = services[index];
    
    try {
      final newActiveState = !currentService.isActive;
      
      final client = Supabase.instance.client;
      await client
          .from('vendor_services')
          .update({'is_active': newActiveState})
          .eq('id', serviceId);
          
      services[index] = currentService.copyWith(isActive: newActiveState);
      notifyListeners();
    } catch (e) {
      print('Error toggling service status: $e');
      rethrow;
    }
  }

  Future<String?> duplicateService(String serviceId) async {
    final client = Supabase.instance.client;
    try {
      // 1. Fetch source service record with ALL nested relations (Deep fetch)
      final response = await client
          .from('vendor_services')
          .select('*, service_components(*, service_items(*)), service_pricing_tiers(*)')
          .eq('id', serviceId)
          .single();

      if (response == null) throw 'Service not found';

      // 2. Prepare cloned service record
      final Map<String, dynamic> sourceService = Map<String, dynamic>.from(response);
      final List<dynamic> sourceComponents = List<dynamic>.from(sourceService['service_components'] ?? []);
      final List<dynamic> sourceTiers = List<dynamic>.from(sourceService['service_pricing_tiers'] ?? []);

      // Clean up parent record for new insertion
      final Map<String, dynamic> newServiceData = Map<String, dynamic>.from(sourceService);
      newServiceData.remove('id');
      newServiceData.remove('created_at');
      newServiceData.remove('updated_at');
      newServiceData.remove('service_components');
      newServiceData.remove('service_pricing_tiers');
      
      newServiceData['name'] = '${sourceService['name']} (Copy)';
      newServiceData['service_status'] = 'draft';
      newServiceData['is_active'] = false; // Duplicates start as hidden

      // 3. Insert new parent service
      final insertedService = await client
          .from('vendor_services')
          .insert(newServiceData)
          .select()
          .single();

      final String newServiceId = insertedService['id'];

      // 4. Clone Components and their nested Items
      for (var compData in sourceComponents) {
        final Map<String, dynamic> component = Map<String, dynamic>.from(compData as Map);
        final List<dynamic> sourceItems = List<dynamic>.from(component['service_items'] ?? []);
        
        component.remove('id');
        component.remove('created_at');
        component.remove('service_items');
        component['service_id'] = newServiceId;
        
        // Insert component
        final insertedComp = await client
            .from('service_components')
            .insert(component)
            .select()
            .single();
            
        final String newCompId = insertedComp['id'];
        
        // Clone Items for this component
        if (sourceItems.isNotEmpty) {
          final List<Map<String, dynamic>> newItems = sourceItems.map((i) {
            final Map<String, dynamic> item = Map<String, dynamic>.from(i as Map);
            item.remove('id');
            item.remove('created_at');
            item['component_id'] = newCompId;
            return item;
          }).toList();
          
          await client.from('service_items').insert(newItems);
        }
      }

      // 5. Clone Pricing Tiers
      if (sourceTiers.isNotEmpty) {
        final List<Map<String, dynamic>> newTiers = sourceTiers.map((t) {
          final Map<String, dynamic> tier = Map<String, dynamic>.from(t as Map);
          tier.remove('id');
          tier.remove('created_at');
          tier['service_id'] = newServiceId;
          return tier;
        }).toList();

        await client.from('service_pricing_tiers').insert(newTiers);
      }

      // 6. Update local state
      if (_currentVendor != null) {
        // Fetch the fresh full record to ensure all joins are present in the local object
        final freshResponse = await client
            .from('vendor_services')
            .select('*, vendor_profiles(priority_score), service_components(*, service_items(*)), service_pricing_tiers(*)')
            .eq('id', newServiceId)
            .single();
            
        final newService = VendorService.fromJson(freshResponse);
        if (_customServices[_currentVendor!.id] != null) {
          _customServices[_currentVendor!.id]!.add(newService.toEnhanced());
        } else {
          _customServices[_currentVendor!.id] = [newService.toEnhanced()];
        }
        notifyListeners();
      }

      return newServiceId;
    } catch (e) {
      print('DEBUG ERROR: duplicateService failed: $e');
      rethrow;
    }
  }
  
  Future<void> setServiceStatus(String serviceId, ServiceStatus status) async {
     try {
       final client = Supabase.instance.client;
       await client
         .from('vendor_services')
         .update({'service_status': status.name})
         .eq('id', serviceId);
         
       final services = _customServices[_currentVendor!.id];
       if (services != null) {
         final index = services.indexWhere((s) => s.id == serviceId);
         if (index != -1) {
           services[index] = services[index].copyWith(status: status);
           notifyListeners();
         }
       }
     } catch (e) {
       print('Error setting status: $e');
     }
  }

  // Toggle favorite for vendor
  void toggleVendorFavorite(String vendorId) {
    _vendorFavorites[vendorId] = !(_vendorFavorites[vendorId] ?? false);
    notifyListeners();
  }

  // Toggle favorite for venue
  void toggleVenueFavorite(String venueId) {
    _venueFavorites[venueId] = !(_venueFavorites[venueId] ?? false);
    notifyListeners();
  }

  // Toggle favorite for any item
  void toggleItemFavorite(String itemId) {
    if (getVendorById(itemId) != null) {
      toggleVendorFavorite(itemId);
    } else if (getVenueById(itemId) != null) {
      toggleVenueFavorite(itemId);
    }
  }

  // Search vendors and venues (Local search)
  List<dynamic> searchItems(String query) {
    if (query.isEmpty) return allItems;

    final lowercaseQuery = query.toLowerCase();
    return allItems.where((item) {
      if (item is Vendor) {
        return item.name.toLowerCase().contains(lowercaseQuery) ||
            item.category.toLowerCase().contains(lowercaseQuery) ||
            item.description.toLowerCase().contains(lowercaseQuery) ||
            item.location.toLowerCase().contains(lowercaseQuery);
      } else if (item is Venue) {
        return item.name.toLowerCase().contains(lowercaseQuery) ||
            item.description.toLowerCase().contains(lowercaseQuery) ||
            item.location.toLowerCase().contains(lowercaseQuery) ||
            item.categories.any((cat) => cat.toLowerCase().contains(lowercaseQuery));
      }
      return false;
    }).toList();
  }

  /// Performs a real-time search across vendors and services using Supabase
  Future<List<dynamic>> performSupabaseSearch(String query, {String? categoryTab}) async {
    try {
      _isLoading = true;
      notifyListeners();

      final client = Supabase.instance.client;
      List<dynamic> results = [];

      final lowercaseQuery = query.toLowerCase().trim();

      // 1. Search Vendors (if Tab is All or Vendors)
      if (categoryTab == null || categoryTab == 'All' || categoryTab == 'Vendors') {
        var vendorQuery = client
            .from('vendor_profiles')
            .select()
            .eq('is_claimed', true); // Only show claimed vendor profiles to avoid admin-created duplicates
        
        if (lowercaseQuery.isNotEmpty) {
          vendorQuery = vendorQuery.or('business_name.ilike.%$lowercaseQuery%,description.ilike.%$lowercaseQuery%,categories.ilike.%$lowercaseQuery%');
        }

        final vendorData =
            await vendorQuery.order('priority_score', ascending: false);
        results.addAll((vendorData as List).map((json) => Vendor.fromSupabase(json)));
      }

      // 2. Search Services/Venues/Packages (if Tab is All, Venues, Services, Products, or Packages)
      if (categoryTab == null || categoryTab == 'All' || categoryTab == 'Venues' || categoryTab == 'Services' || categoryTab == 'Products/Items' || categoryTab == 'Packages') {
        var serviceQuery = client
            .from('vendor_services')
            .select('*, vendor_profiles(priority_score)');
        
        if (lowercaseQuery.isNotEmpty) {
          serviceQuery = serviceQuery.or('name.ilike.%$lowercaseQuery%,description.ilike.%$lowercaseQuery%,category.ilike.%$lowercaseQuery%');
        }

        if (categoryTab == 'Venues') {
          serviceQuery = serviceQuery.eq('category', 'Venue');
        } else if (categoryTab == 'Services') {
          // Broad Services search: exclude Venue and Package categories
          serviceQuery = serviceQuery.not('category', 'in', '("Venue", "Package")');
        } else if (categoryTab == 'Packages') {
          serviceQuery = serviceQuery.eq('category', 'Package');
        } else if (categoryTab == 'Products/Items') {
          // Products search: focus on Fashion, Doorgift, Equipment, and Other (matching lowercase IDs)
          serviceQuery = serviceQuery.inFilter('category', ['fashion', 'doorgift', 'equipment', 'other']);
        }

        final serviceData = await serviceQuery;
        final services = (serviceData as List)
            .map((json) => VendorService.fromJson(Map<String, dynamic>.from(json as Map)))
            .toList();
        services.sort((a, b) => b.vendorPriorityScore.compareTo(a.vendorPriorityScore));
        results.addAll(services);
      }

      return results;
    } catch (e) {
      print('Error performing Supabase search: $e');
      _error = 'Search failed: $e';
      return [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await _initializeData();
  }

  Future<void> loadSampleVendors() async {
    await loadVendors();
  }

  Future<void> loadServiceCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('service_categories')
          .select()
          .order('name');
      
      _serviceCategories.clear();
      _serviceCategories.addAll(
        (response as List).map((data) => ServiceCategory.fromMap(data)),
      );
      notifyListeners();
    } catch (e) {
      print('Error loading service categories: $e');
    }
  }
  Future<String?> uploadPortfolioImage({required Uint8List bytes, required String fileName}) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
          print('Error: User not logged in');
          return null;
      }
      
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      // Use Auth User ID in path to match RLS policy: auth.uid()/portfolio_images/filename
      final path = '$userId/portfolio_images/$uniqueFileName';
      
      await SupabaseService.uploadFile(
        bucket: 'vendor_assets', 
        path: path,
        fileBytes: bytes,
      );
      
      final publicUrl = SupabaseService.getPublicUrl(bucket: 'vendor_assets', path: path);
      return publicUrl;
    } catch (e) {
      print('Error uploading portfolio image: $e');
      return null;
    }
  }

  Future<void> updateVendorPortfolio(List<String> newPortfolio) async {
    if (_currentVendor == null) return;
    
    try {
      final client = Supabase.instance.client;
      await client
          .from('vendor_profiles')
          .update({'portfolio': newPortfolio})
          .eq('id', _currentVendor!.id);
          
      // Refresh current vendor data to reflect changes
      await loadCurrentVendorFromSupabase(force: true);
    } catch (e) {
      print('Error updating portfolio: $e');
      throw e;
    }
  }

  Future<void> _saveStructuredServiceData(String serviceId, VendorServiceEnhanced service) async {
    final client = Supabase.instance.client;

    // 1. Save Pricing Tiers
    await client.from('service_pricing_tiers').delete().eq('service_id', serviceId);
    
    final Map<String, String> tempToRealTierId = {};

    if (service.pricingTiers.isNotEmpty) {
      final List<Map<String, dynamic>> tiersToInsert = service.pricingTiers.map((t) => {
        'service_id': serviceId,
        'name': t.name,
        'min_pax': t.minPax,
        'max_pax': t.maxPax,
        'price': t.price,
        'original_price': t.originalPrice,
        'promo_expiry': t.promoExpiry?.toIso8601String(),
        'description': t.description ?? '',
      }).toList();

      final List<dynamic> tieredResponse = await client.from('service_pricing_tiers').insert(tiersToInsert).select();
      
      // Map temporary local IDs to real DB UUIDs for item association
      for (int i = 0; i < service.pricingTiers.length; i++) {
        final localTier = service.pricingTiers[i];
        if (localTier.id != null) {
          tempToRealTierId[localTier.id!] = tieredResponse[i]['id'].toString();
        }
      }
    }

    // 2. Save Components & Items
    await client.from('service_components').delete().eq('service_id', serviceId);

    for (final component in service.components) {
      final compResponse = await client.from('service_components').insert({
        'service_id': serviceId,
        'name': component.name,
        'component_type': component.componentType,
      }).select().single();
      
      final componentId = compResponse['id'];

      if (component.items.isNotEmpty) {
        final List<Map<String, dynamic>> itemsToInsert = [];
        
        for (final item in component.items) {
          List<String> finalGalleryUrls = List.from(item.galleryUrls);
          String? finalPdfUrl = item.pdfUrl;
          
          // Map applicable Tier IDs from temporary to real
          final List<String> realApplicableTierIds = item.applicableTierIds
              .map((tempId) => tempToRealTierId[tempId])
              .where((realId) => realId != null)
              .cast<String>()
              .toList();
          
          // Upload new gallery images
          if (item.newGalleryFiles != null && item.newGalleryFiles!.isNotEmpty) {
            for (final file in item.newGalleryFiles!) {
              final bytes = await file.readAsBytes();
              final url = await uploadPortfolioImage(bytes: bytes, fileName: file.name);
              if (url != null) finalGalleryUrls.add(url);
            }
          }
          
          // Upload new PDF
          if (item.newPdfFile != null) {
            final bytes = item.newPdfFile!.bytes;
            if (bytes != null) {
              final url = await uploadPortfolioImage(bytes: bytes, fileName: item.newPdfFile!.name);
              if (url != null) finalPdfUrl = url;
            } else if (item.newPdfFile!.path != null) {
              final fileBytes = await File(item.newPdfFile!.path!).readAsBytes();
              final url = await uploadPortfolioImage(bytes: fileBytes, fileName: item.newPdfFile!.name);
              if (url != null) finalPdfUrl = url;
            }
          }

          itemsToInsert.add({
            'component_id': componentId,
            'name': item.name,
            'quantity': item.quantity,
            'description': item.description ?? '',
            'unit_price': item.unitPrice,
            'gallery_urls': finalGalleryUrls,
            'pdf_url': finalPdfUrl,
            'applicable_tier_ids': realApplicableTierIds,
            'is_optional': item.isOptional,
            'extra_price': item.extraPrice,
            'is_included': item.isIncluded,
          });
        }

        if (itemsToInsert.isNotEmpty) {
          await client.from('service_items').insert(itemsToInsert);
        }
      }
    }
  }

  Future<VendorServiceEnhanced> _loadStructuredServiceData(VendorServiceEnhanced service) async {
    final client = Supabase.instance.client;

    // Load tiers
    final tiersData = await client.from('service_pricing_tiers').select().eq('service_id', service.id);
    final tiers = (tiersData as List).map<ServicePricingTier>((t) => ServicePricingTier.fromJson(t)).toList();

    // Load components
    final componentsData = await client.from('service_components').select('*, service_items(*)').eq('service_id', service.id);
    final components = (componentsData as List).map<ServiceComponent>((c) => ServiceComponent.fromJson(c)).toList();

    return service.copyWith(
      pricingTiers: tiers,
      components: components,
    );
  }

  // --- Installment Settings ---

  Future<VendorInstallmentSettings?> getInstallmentSettings(String vendorId) async {
    if (!VendorInstallmentSettings.isValidVendorUuid(vendorId)) {
      return VendorInstallmentSettings.defaultSettings(vendorId);
    }
    try {
      final response = await Supabase.instance.client
          .from('vendor_installment_settings')
          .select()
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (response != null) {
        return VendorInstallmentSettings.fromSupabase(response);
      }
      return VendorInstallmentSettings.defaultSettings(vendorId);
    } catch (e) {
      print('Error loading installment settings: $e');
      return VendorInstallmentSettings.defaultSettings(vendorId);
    }
  }

  Future<bool> saveInstallmentSettings(VendorInstallmentSettings settings) async {
    if (!VendorInstallmentSettings.isValidVendorUuid(settings.vendorId)) {
      print(
        'Error saving installment settings: vendor_id must be a UUID (got "${settings.vendorId}")',
      );
      return false;
    }
    final client = Supabase.instance.client;
    try {
      await client
          .from('vendor_installment_settings')
          .upsert(settings.toSupabaseJson());
      return true;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('PGRST204') || msg.contains('schema cache')) {
        try {
          await client
              .from('vendor_installment_settings')
              .upsert(settings.toSupabaseJsonModern());
          return true;
        } catch (e2) {
          print('Error saving installment settings (alternate schema): $e2');
          return false;
        }
      }
      print('Error saving installment settings: $e');
      return false;
    }
  }
}
