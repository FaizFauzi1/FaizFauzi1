import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
class VendorServicesData {
  // Static cache (now empty)
  static List<VendorService>? _cachedAllServices;

  // Static map to track updated approval statuses
  static final Map<String, ApprovalStatus> _updatedStatuses = {};

  // Update service approval status
  static void updateServiceApprovalStatus(String serviceId, ApprovalStatus status) {
    _updatedStatuses[serviceId] = status;
    _cachedAllServices = null;
  }

  // Get effective approval status
  static ApprovalStatus getEffectiveApprovalStatus(VendorService service) {
    return _updatedStatuses[service.id] ?? service.approvalStatus;
  }

  // Mockup data removal: All getters now return empty lists.
  // Use VendorProvider or SupabaseService to fetch real data.

  static List<VendorService> getCateringServices() => [];
  static List<VendorService> getPhotographyServices() => [];
  static List<VendorService> getVenueServices() => [];
  static List<VendorService> getEntertainmentServices() => [];
  static List<VendorService> getDecorationServices() => [];
  static List<VendorService> getGiftServices() => [];
  static List<VendorService> getRentalServices() => [];
  static List<VendorService> getOtherServices() => [];
  static List<VendorService> getPackageServices() => [];
  
  static List<VendorService> getAllServices() {
    if (_cachedAllServices != null) return _cachedAllServices!;
    _cachedAllServices = [];
    return _cachedAllServices!;
  }

  static VendorService? getServiceById(String id) {
    return null;
  }

  static List<VendorService> getServicesByCategory(EventCategory category) {
    return [];
  }

  static List<VendorService> getServicesByCategoryName(String categoryName) {
    return [];
  }

  static List<VendorService> getFeaturedServices() {
    return [];
  }

  static List<VendorService> getServicesByVendor(String vendorId) {
    return [];
  }

  static List<VendorService> searchServices(String query) {
    return [];
  }

  /// Legacy helper for updating in-memory sample services.
  /// In the current implementation we no longer keep a mutable sample dataset,
  /// so this is effectively a no-op that simply reports "not replaced".
  static bool updateServiceFromEnhanced(VendorServiceEnhanced updated) {
    // If a cached list ever gets repopulated in the future, this can be
    // extended to replace the matching entry by ID.
    return false;
  }
}
