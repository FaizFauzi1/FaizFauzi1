import 'package:equatable/equatable.dart';

class VendorAnalytics extends Equatable {
  final String id;
  final String vendorId;
  final DateTime date;
  final int totalViews;
  final int profileViews;
  final int serviceViews;
  final int contactClicks;
  final int bookingsCount;
  final double revenue;
  final double totalRevenue;
  final int totalOrders;
  final Map<String, dynamic> customerSegments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorAnalytics({
    required this.id,
    required this.vendorId,
    required this.date,
    this.totalViews = 0,
    this.profileViews = 0,
    this.serviceViews = 0,
    this.contactClicks = 0,
    this.bookingsCount = 0,
    this.revenue = 0.0,
    this.totalRevenue = 0.0,
    this.totalOrders = 0,
    required this.customerSegments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorAnalytics.fromJson(Map<String, dynamic> json) {
    return VendorAnalytics(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      date: DateTime.parse(json['date']),
      totalViews: json['total_views'] ?? 0,
      profileViews: json['profile_views'] ?? 0,
      serviceViews: json['service_views'] ?? 0,
      contactClicks: json['contact_clicks'] ?? 0,
      bookingsCount: json['bookings_count'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      totalRevenue: (json['total_revenue'] ?? 0).toDouble(),
      totalOrders: json['total_orders'] ?? 0,
      customerSegments: Map<String, dynamic>.from(json['customer_segments'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'date': date.toIso8601String().split('T')[0],
      'total_views': totalViews,
      'profile_views': profileViews,
      'service_views': serviceViews,
      'contact_clicks': contactClicks,
      'bookings_count': bookingsCount,
      'revenue': revenue,
      'total_revenue': totalRevenue,
      'total_orders': totalOrders,
      'customer_segments': customerSegments,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VendorAnalytics copyWith({
    String? id,
    String? vendorId,
    DateTime? date,
    int? totalViews,
    int? profileViews,
    int? serviceViews,
    int? contactClicks,
    int? bookingsCount,
    double? revenue,
    double? totalRevenue,
    int? totalOrders,
    Map<String, dynamic>? customerSegments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorAnalytics(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      date: date ?? this.date,
      totalViews: totalViews ?? this.totalViews,
      profileViews: profileViews ?? this.profileViews,
      serviceViews: serviceViews ?? this.serviceViews,
      contactClicks: contactClicks ?? this.contactClicks,
      bookingsCount: bookingsCount ?? this.bookingsCount,
      revenue: revenue ?? this.revenue,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalOrders: totalOrders ?? this.totalOrders,
      customerSegments: customerSegments ?? this.customerSegments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        date,
        totalViews,
        profileViews,
        serviceViews,
        contactClicks,
        bookingsCount,
        revenue,
        totalRevenue,
        totalOrders,
        customerSegments,
        createdAt,
        updatedAt,
      ];
}
