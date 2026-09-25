import 'package:eventease/core/database/database_helper.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/shared/models/services/service_package.dart';
import 'dart:convert';

class VendorServiceRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Convert VendorService model to Map for database storage
  Map<String, dynamic> _serviceToMap(VendorService service) {
    return {
      'id': service.id,
      'vendorId': service.vendorId,
      'vendorName': service.vendorName,
      'name': service.name,
      'description': service.description,
      'category': service.category.id,
      'subcategory': service.subcategory,
      'basePrice': service.basePrice,
      'hourlyRate': service.hourlyRate,
      'active': service.active ? 1 : 0,
      'approvalStatus': service.approvalStatus.name,
      'availability': service.availability.isNotEmpty
          ? jsonEncode(service.availability)
          : null,
      'maxBookingsPerDay': service.maxBookingsPerDay,
      'advanceBookingDays': service.advanceBookingDays,
      'type': service.type.name,
      'images': service.images.isNotEmpty ? jsonEncode(service.images) : null,
      'options':
          service.options.isNotEmpty ? jsonEncode(service.options) : null,
      'requirements': service.requirements.isNotEmpty
          ? jsonEncode(service.requirements)
          : null,
      'logistics':
          service.logistics.isNotEmpty ? jsonEncode(service.logistics) : null,
      'status': service.status.name,
      'createdAt': service.createdAt.toIso8601String(),
      'updatedAt': service.updatedAt.toIso8601String(),
      'supportsAppointments': service.supportsAppointments ? 1 : 0,
      'supportsRentals': service.supportsRentals ? 1 : 0,
      'amenities':
          service.amenities != null ? jsonEncode(service.amenities!) : null,
      'cancellationPolicy': service.cancellationPolicy,
      'reviews': service.reviews != null ? jsonEncode(service.reviews!) : null,
      'packages': service.packages != null
          ? jsonEncode(service.packages!
              .map((p) => {
                    'id': p.id,
                    'name': p.name,
                    'description': p.description,
                    'category': p.category,
                    'priceByPax': p.priceByPax,
                    'facilities': p.facilities,
                    'services': p.services,
                    'photography': p.photography,
                  })
              .toList())
          : null,
      'allowedActions': service.allowedActions.isNotEmpty
          ? jsonEncode(service.allowedActions)
          : null,
      'locations':
          service.locations != null ? jsonEncode(service.locations!) : null,
    };
  }

  // Convert Map from database to VendorService model
  VendorService _mapToService(Map<String, dynamic> map) {
    return VendorService(
      id: map['id'],
      vendorId: map['vendorId'],
      vendorName: map['vendorName'],
      name: map['name'],
      description: map['description'],
      category: map['category'],
      subcategory: map['subcategory'],
      basePrice: map['basePrice']?.toDouble() ?? 0.0,
      hourlyRate: map['hourlyRate']?.toDouble(),
      active: map['active'] == 1,
      approvalStatus: ApprovalStatus.values.firstWhere(
        (e) => e.name == map['approvalStatus'],
        orElse: () => ApprovalStatus.pending,
      ),
      availability: map['availability'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['availability']))
          : {},
      maxBookingsPerDay: map['maxBookingsPerDay'] ?? 10,
      advanceBookingDays: map['advanceBookingDays'] ?? 7,
      type: ServiceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ServiceType.service,
      ),
      images: map['images'] != null
          ? List<String>.from(jsonDecode(map['images']))
          : [],
      options: map['options'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['options']))
          : {},
      requirements: map['requirements'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['requirements']))
          : {},
      logistics: map['logistics'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['logistics']))
          : {},
      status: ServiceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ServiceStatus.active,
      ),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      supportsAppointments: map['supportsAppointments'] == 1,
      supportsRentals: map['supportsRentals'] == 1,
      amenities: map['amenities'] != null
          ? List<String>.from(jsonDecode(map['amenities']))
          : null,
      cancellationPolicy: map['cancellationPolicy'],
      reviews: map['reviews'] != null
          ? List<Map<String, dynamic>>.from(jsonDecode(map['reviews']))
          : null,
      packages: map['packages'] != null
          ? (jsonDecode(map['packages']) as List)
              .map((p) {
                // Handle both old format (with price) and new format (with priceByPax)
                Map<int, double> priceByPax = {};
                if (p['priceByPax'] != null) {
                  priceByPax = Map<int, double>.from(
                    (p['priceByPax'] as Map).map((k, v) => MapEntry(int.parse(k.toString()), v.toDouble()))
                  );
                } else if (p['price'] != null) {
                  // Legacy format: use a default pax of 1
                  priceByPax = {1: (p['price'] as num).toDouble()};
                }
                
                return ServicePackage(
                  id: p['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
                  name: p['name'] ?? '',
                  description: p['description'] ?? '',
                  category: p['category'] ?? 'Other',
                  priceByPax: priceByPax,
                  facilities: List<String>.from(p['facilities'] ?? []),
                  services: List<String>.from(p['services'] ?? []),
                  photography: List<String>.from(p['photography'] ?? []),
                );
              })
              .toList()
          : null,
      allowedActions: map['allowedActions'] != null
          ? List<String>.from(jsonDecode(map['allowedActions']))
          : [],
      locations: map['locations'] != null
          ? List<String>.from(jsonDecode(map['locations']))
          : null,
    );
  }

  // CRUD Operations
  Future<int> insertService(VendorService service) async {
    return await _dbHelper.insertVendorService(_serviceToMap(service));
  }

  Future<List<VendorService>> getAllServices() async {
    final maps = await _dbHelper.getAllVendorServices();
    return maps.map((map) => _mapToService(map)).toList();
  }

  Future<VendorService?> getServiceById(String id) async {
    final map = await _dbHelper.getVendorServiceById(id);
    return map != null ? _mapToService(map) : null;
  }

  Future<List<VendorService>> getServicesByVendor(String vendorId) async {
    final maps = await _dbHelper.getVendorServicesByVendor(vendorId);
    return maps.map((map) => _mapToService(map)).toList();
  }

  Future<List<VendorService>> getServicesByCategory(String category) async {
    final maps = await _dbHelper.getVendorServicesByCategory(category);
    return maps.map((map) => _mapToService(map)).toList();
  }

  Future<int> updateService(VendorService service) async {
    return await _dbHelper.updateVendorService(
        service.id, _serviceToMap(service));
  }

  Future<int> deleteService(String id) async {
    return await _dbHelper.deleteVendorService(id);
  }

  // Additional helper methods
  Future<List<VendorService>> getActiveServices() async {
    final allServices = await getAllServices();
    return allServices.where((service) => service.active).toList();
  }

  Future<List<VendorService>> getApprovedServices() async {
    final allServices = await getAllServices();
    return allServices
        .where((service) => service.approvalStatus == ApprovalStatus.approved)
        .toList();
  }

  Future<List<VendorService>> getServicesByStatus(ServiceStatus status) async {
    final allServices = await getAllServices();
    return allServices.where((service) => service.status == status).toList();
  }

  Future<List<VendorService>> getServicesByType(ServiceType type) async {
    final allServices = await getAllServices();
    return allServices.where((service) => service.type == type).toList();
  }

  Future<List<VendorService>> searchServices(String query) async {
    final allServices = await getAllServices();
    return allServices.where((service) {
      return service.name.toLowerCase().contains(query.toLowerCase()) ||
          service.description.toLowerCase().contains(query.toLowerCase()) ||
          service.category.displayName
              .toLowerCase()
              .contains(query.toLowerCase());
    }).toList();
  }

  Future<List<VendorService>> getServicesInPriceRange(
      double minPrice, double maxPrice) async {
    final allServices = await getAllServices();
    return allServices.where((service) {
      return service.basePrice >= minPrice && service.basePrice <= maxPrice;
    }).toList();
  }
}
