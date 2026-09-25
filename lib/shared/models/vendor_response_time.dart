import 'package:equatable/equatable.dart';

class VendorResponseTime extends Equatable {
  final String id;
  final String vendorId;
  final double averageResponseTimeHours;
  final int totalResponses;
  final int onTimeResponses;
  final double onTimePercentage;
  final DateTime lastResponseAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorResponseTime({
    required this.id,
    required this.vendorId,
    this.averageResponseTimeHours = 0.0,
    this.totalResponses = 0,
    this.onTimeResponses = 0,
    this.onTimePercentage = 0.0,
    required this.lastResponseAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorResponseTime.fromJson(Map<String, dynamic> json) {
    return VendorResponseTime(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      averageResponseTimeHours: (json['average_response_time_hours'] ?? 0).toDouble(),
      totalResponses: json['total_responses'] ?? 0,
      onTimeResponses: json['on_time_responses'] ?? 0,
      onTimePercentage: (json['on_time_percentage'] ?? 0).toDouble(),
      lastResponseAt: DateTime.parse(json['last_response_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'average_response_time_hours': averageResponseTimeHours,
      'total_responses': totalResponses,
      'on_time_responses': onTimeResponses,
      'on_time_percentage': onTimePercentage,
      'last_response_at': lastResponseAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VendorResponseTime copyWith({
    String? id,
    String? vendorId,
    double? averageResponseTimeHours,
    int? totalResponses,
    int? onTimeResponses,
    double? onTimePercentage,
    DateTime? lastResponseAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorResponseTime(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      averageResponseTimeHours: averageResponseTimeHours ?? this.averageResponseTimeHours,
      totalResponses: totalResponses ?? this.totalResponses,
      onTimeResponses: onTimeResponses ?? this.onTimeResponses,
      onTimePercentage: onTimePercentage ?? this.onTimePercentage,
      lastResponseAt: lastResponseAt ?? this.lastResponseAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        averageResponseTimeHours,
        totalResponses,
        onTimeResponses,
        onTimePercentage,
        lastResponseAt,
        createdAt,
        updatedAt,
      ];
}
