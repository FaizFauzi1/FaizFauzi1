import 'package:eventease/shared/models/services/service_enums.dart';
import 'services/service_package.dart';

class SampleServicePackages {
  // Mockup data removal: All getters now return empty lists.
  // Use Supabase 'service_packages' table to fetch real data.

  static final Map<String, ApprovalStatus> _updatedStatuses = {};

  static void updatePackageApprovalStatus(String packageId, ApprovalStatus status) {
    _updatedStatuses[packageId] = status;
  }

  static List<ServicePackage> getVenuePackages() => [];

  static ServicePackage? getSamplePackage() => null;

  static List<ServicePackage> getPackagesByCategory(String category) => [];

  static List<ServicePackage> getApprovedPackages() => [];

  static List<ServicePackage> getAllPackages() => [];

  static List<ServicePackage> getPendingPackages() => [];
}
