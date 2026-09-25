import 'package:equatable/equatable.dart';

class ServiceReview extends Equatable {
  final String id;
  final String serviceId;
  final String customerId;
  final String? customerName;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const ServiceReview({
    required this.id,
    required this.serviceId,
    required this.customerId,
    this.customerName,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory ServiceReview.fromJson(Map<String, dynamic> json) {
    return ServiceReview(
      id: json['id'] ?? '',
      serviceId: json['service_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      customerName: json['customer_name'] ?? json['user']?['full_name'],
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: json['comment'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'customer_id': customerId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, serviceId, customerId, rating, comment, createdAt];
}
