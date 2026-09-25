import 'package:equatable/equatable.dart';

enum VendorStatus { pending, approved, suspended, rejected }
enum VendorType { individual, company }

class VendorProfile extends Equatable {
  final String id;
  final String userId;
  final String businessName;
  final String? businessDescription;
  final String? businessAddress;
  final String? businessPhone;
  final String? businessEmail;
  final String? website;
  final String? logoUrl;
  final List<String> businessCategories;
  final VendorType vendorType;
  final VendorStatus status;
  final double? rating;
  final int totalReviews;
  final int totalBookings;
  final double totalEarnings;
  final bool isVerified;
  final Map<String, dynamic> businessHours;
  final List<String> serviceAreas;
  final String? taxId;
  final String? licenseNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorProfile({
    required this.id,
    required this.userId,
    required this.businessName,
    this.businessDescription,
    this.businessAddress,
    this.businessPhone,
    this.businessEmail,
    this.website,
    this.logoUrl,
    required this.businessCategories,
    required this.vendorType,
    this.status = VendorStatus.pending,
    this.rating,
    this.totalReviews = 0,
    this.totalBookings = 0,
    this.totalEarnings = 0.0,
    this.isVerified = false,
    required this.businessHours,
    required this.serviceAreas,
    this.taxId,
    this.licenseNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorProfile.fromJson(Map<String, dynamic> json) {
    return VendorProfile(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      businessName: json['business_name'] as String,
      businessDescription: json['business_description'] as String?,
      businessAddress: json['address'] as String?,
      businessPhone: json['business_phone'] as String?,
      businessEmail: json['business_email'] as String?,
      website: json['website'] as String?,
      logoUrl: json['logo_url'] as String?,
      businessCategories: List<String>.from(json['business_categories'] ?? []),
      vendorType: VendorType.values.firstWhere(
        (type) => type.name == json['vendor_type'],
        orElse: () => VendorType.individual,
      ),
      status: VendorStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => VendorStatus.pending,
      ),
      rating: json['rating']?.toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      totalBookings: json['total_bookings'] ?? 0,
      totalEarnings: (json['total_earnings'] ?? 0).toDouble(),
      isVerified: json['is_verified'] ?? false,
      businessHours: Map<String, dynamic>.from(json['business_hours'] ?? {}),
      serviceAreas: List<String>.from(json['service_areas'] ?? []),
      taxId: json['tax_id'] as String?,
      licenseNumber: json['license_number'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'business_name': businessName,
      'business_description': businessDescription,
      'business_address': businessAddress,
      'business_phone': businessPhone,
      'business_email': businessEmail,
      'website': website,
      'logo_url': logoUrl,
      'business_categories': businessCategories,
      'vendor_type': vendorType.name,
      'status': status.name,
      'rating': rating,
      'total_reviews': totalReviews,
      'total_bookings': totalBookings,
      'total_earnings': totalEarnings,
      'is_verified': isVerified,
      'business_hours': businessHours,
      'service_areas': serviceAreas,
      'tax_id': taxId,
      'license_number': licenseNumber,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VendorProfile copyWith({
    String? id,
    String? userId,
    String? businessName,
    String? businessDescription,
    String? businessAddress,
    String? businessPhone,
    String? businessEmail,
    String? website,
    String? logoUrl,
    List<String>? businessCategories,
    VendorType? vendorType,
    VendorStatus? status,
    double? rating,
    int? totalReviews,
    int? totalBookings,
    double? totalEarnings,
    bool? isVerified,
    Map<String, dynamic>? businessHours,
    List<String>? serviceAreas,
    String? taxId,
    String? licenseNumber,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorProfile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      businessCategories: businessCategories ?? this.businessCategories,
      vendorType: vendorType ?? this.vendorType,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalBookings: totalBookings ?? this.totalBookings,
      totalEarnings: totalEarnings ?? this.totalEarnings,
      isVerified: isVerified ?? this.isVerified,
      businessHours: businessHours ?? this.businessHours,
      serviceAreas: serviceAreas ?? this.serviceAreas,
      taxId: taxId ?? this.taxId,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        businessName,
        businessDescription,
        businessAddress,
        businessPhone,
        businessEmail,
        website,
        logoUrl,
        businessCategories,
        vendorType,
        status,
        rating,
        totalReviews,
        totalBookings,
        totalEarnings,
        isVerified,
        businessHours,
        serviceAreas,
        taxId,
        licenseNumber,
        createdAt,
        updatedAt,
      ];
}
