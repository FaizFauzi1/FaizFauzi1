import 'package:equatable/equatable.dart';

class VendorPerformanceMetrics extends Equatable {
  final String id;
  final String vendorId;
  final DateTime date;
  final int totalBookings;
  final int completedBookings;
  final int cancelledBookings;
  final double averageRating;
  final int totalReviews;
  final double revenue;
  final double profit;
  final int customerRetentionRate;
  final int responseTimeHours;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorPerformanceMetrics({
    required this.id,
    required this.vendorId,
    required this.date,
    this.totalBookings = 0,
    this.completedBookings = 0,
    this.cancelledBookings = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.revenue = 0.0,
    this.profit = 0.0,
    this.customerRetentionRate = 0,
    this.responseTimeHours = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorPerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return VendorPerformanceMetrics(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      date: DateTime.parse(json['date']),
      totalBookings: json['total_bookings'] ?? 0,
      completedBookings: json['completed_bookings'] ?? 0,
      cancelledBookings: json['cancelled_bookings'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      totalReviews: json['total_reviews'] ?? 0,
      revenue: (json['revenue'] ?? 0).toDouble(),
      profit: (json['profit'] ?? 0).toDouble(),
      customerRetentionRate: json['customer_retention_rate'] ?? 0,
      responseTimeHours: json['response_time_hours'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'date': date.toIso8601String().split('T')[0],
      'total_bookings': totalBookings,
      'completed_bookings': completedBookings,
      'cancelled_bookings': cancelledBookings,
      'average_rating': averageRating,
      'total_reviews': totalReviews,
      'revenue': revenue,
      'profit': profit,
      'customer_retention_rate': customerRetentionRate,
      'response_time_hours': responseTimeHours,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VendorPerformanceMetrics copyWith({
    String? id,
    String? vendorId,
    DateTime? date,
    int? totalBookings,
    int? completedBookings,
    int? cancelledBookings,
    double? averageRating,
    int? totalReviews,
    double? revenue,
    double? profit,
    int? customerRetentionRate,
    int? responseTimeHours,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorPerformanceMetrics(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      date: date ?? this.date,
      totalBookings: totalBookings ?? this.totalBookings,
      completedBookings: completedBookings ?? this.completedBookings,
      cancelledBookings: cancelledBookings ?? this.cancelledBookings,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      revenue: revenue ?? this.revenue,
      profit: profit ?? this.profit,
      customerRetentionRate: customerRetentionRate ?? this.customerRetentionRate,
      responseTimeHours: responseTimeHours ?? this.responseTimeHours,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        date,
        totalBookings,
        completedBookings,
        cancelledBookings,
        averageRating,
        totalReviews,
        revenue,
        profit,
        customerRetentionRate,
        responseTimeHours,
        createdAt,
        updatedAt,
      ];
}
