import 'package:equatable/equatable.dart';

class ProductPerformance extends Equatable {
  final String id;
  final String productId;
  final DateTime date;
  final int views;
  final int clicks;
  final int purchases;
  final double conversionRate;
  final double revenue;
  final int cartAdditions;
  final int wishlists;
  final int shares;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProductPerformance({
    required this.id,
    required this.productId,
    required this.date,
    this.views = 0,
    this.clicks = 0,
    this.purchases = 0,
    this.conversionRate = 0.0,
    this.revenue = 0.0,
    this.cartAdditions = 0,
    this.wishlists = 0,
    this.shares = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductPerformance.fromJson(Map<String, dynamic> json) {
    return ProductPerformance(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      date: DateTime.parse(json['date']),
      views: json['views'] ?? 0,
      clicks: json['clicks'] ?? 0,
      purchases: json['purchases'] ?? 0,
      conversionRate: (json['conversion_rate'] ?? 0).toDouble(),
      revenue: (json['revenue'] ?? 0).toDouble(),
      cartAdditions: json['cart_additions'] ?? 0,
      wishlists: json['wishlists'] ?? 0,
      shares: json['shares'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'date': date.toIso8601String().split('T')[0],
      'views': views,
      'clicks': clicks,
      'purchases': purchases,
      'conversion_rate': conversionRate,
      'revenue': revenue,
      'cart_additions': cartAdditions,
      'wishlists': wishlists,
      'shares': shares,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProductPerformance copyWith({
    String? id,
    String? productId,
    DateTime? date,
    int? views,
    int? clicks,
    int? purchases,
    double? conversionRate,
    double? revenue,
    int? cartAdditions,
    int? wishlists,
    int? shares,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductPerformance(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      date: date ?? this.date,
      views: views ?? this.views,
      clicks: clicks ?? this.clicks,
      purchases: purchases ?? this.purchases,
      conversionRate: conversionRate ?? this.conversionRate,
      revenue: revenue ?? this.revenue,
      cartAdditions: cartAdditions ?? this.cartAdditions,
      wishlists: wishlists ?? this.wishlists,
      shares: shares ?? this.shares,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        date,
        views,
        clicks,
        purchases,
        conversionRate,
        revenue,
        cartAdditions,
        wishlists,
        shares,
        createdAt,
        updatedAt,
      ];
}
