import 'package:equatable/equatable.dart';

class VendorRating extends Equatable {
  final String id;
  final String vendorId;
  final String customerId;
  final String bookingId;
  final double rating;
  final String? review;
  final Map<String, int> categoryRatings;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorRating({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.bookingId,
    required this.rating,
    this.review,
    required this.categoryRatings,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorRating.fromJson(Map<String, dynamic> json) {
    return VendorRating(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      customerId: json['customer_id'] as String,
      bookingId: json['booking_id'] as String,
      rating: (json['rating'] ?? 0).toDouble(),
      review: json['review'] as String?,
      categoryRatings: Map<String, int>.from(json['category_ratings'] ?? {}),
      isVerified: json['is_verified'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'customer_id': customerId,
      'booking_id': bookingId,
      'rating': rating,
      'review': review,
      'category_ratings': categoryRatings,
      'is_verified': isVerified,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VendorRating copyWith({
    String? id,
    String? vendorId,
    String? customerId,
    String? bookingId,
    double? rating,
    String? review,
    Map<String, int>? categoryRatings,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorRating(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      customerId: customerId ?? this.customerId,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      categoryRatings: categoryRatings ?? this.categoryRatings,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        customerId,
        bookingId,
        rating,
        review,
        categoryRatings,
        isVerified,
        createdAt,
        updatedAt,
      ];
}
