import 'package:equatable/equatable.dart';

class Review extends Equatable {
  final String id;
  final String bookingId;
  final String reviewerId;
  final String vendorId;
  final int rating;
  final String? title;
  final String? comment;
  final List<String>? images;
  final bool isVerified;
  final bool isPublic;
  final Map<String, int> categoryRatings;
  final String? vendorResponse;
  final DateTime? vendorRespondedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Review({
    required this.id,
    required this.bookingId,
    required this.reviewerId,
    required this.vendorId,
    required this.rating,
    this.title,
    this.comment,
    this.images,
    this.isVerified = false,
    this.isPublic = true,
    required this.categoryRatings,
    this.vendorResponse,
    this.vendorRespondedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      reviewerId: json['reviewer_id'] as String,
      vendorId: json['vendor_id'] as String,
      rating: json['rating'] as int,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      isVerified: json['is_verified'] ?? false,
      isPublic: json['is_public'] ?? true,
      categoryRatings: Map<String, int>.from(json['category_ratings'] ?? {}),
      vendorResponse: json['vendor_response'] as String?,
      vendorRespondedAt: json['vendor_responded_at'] != null
          ? DateTime.parse(json['vendor_responded_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'reviewer_id': reviewerId,
      'vendor_id': vendorId,
      'rating': rating,
      'title': title,
      'comment': comment,
      'images': images,
      'is_verified': isVerified,
      'is_public': isPublic,
      'category_ratings': categoryRatings,
      'vendor_response': vendorResponse,
      'vendor_responded_at': vendorRespondedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Review copyWith({
    String? id,
    String? bookingId,
    String? reviewerId,
    String? vendorId,
    int? rating,
    String? title,
    String? comment,
    List<String>? images,
    bool? isVerified,
    bool? isPublic,
    Map<String, int>? categoryRatings,
    String? vendorResponse,
    DateTime? vendorRespondedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      reviewerId: reviewerId ?? this.reviewerId,
      vendorId: vendorId ?? this.vendorId,
      rating: rating ?? this.rating,
      title: title ?? this.title,
      comment: comment ?? this.comment,
      images: images ?? this.images,
      isVerified: isVerified ?? this.isVerified,
      isPublic: isPublic ?? this.isPublic,
      categoryRatings: categoryRatings ?? this.categoryRatings,
      vendorResponse: vendorResponse ?? this.vendorResponse,
      vendorRespondedAt: vendorRespondedAt ?? this.vendorRespondedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        reviewerId,
        vendorId,
        rating,
        title,
        comment,
        images,
        isVerified,
        isPublic,
        categoryRatings,
        vendorResponse,
        vendorRespondedAt,
        createdAt,
        updatedAt,
      ];
}
