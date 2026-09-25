import 'package:equatable/equatable.dart';

class ConversionFunnels extends Equatable {
  final String id;
  final String name;
  final String description;
  final List<String> steps;
  final Map<String, dynamic> stepMetrics;
  final double conversionRate;
  final int totalVisitors;
  final int totalConversions;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ConversionFunnels({
    required this.id,
    required this.name,
    this.description = '',
    required this.steps,
    required this.stepMetrics,
    this.conversionRate = 0.0,
    this.totalVisitors = 0,
    this.totalConversions = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ConversionFunnels.fromJson(Map<String, dynamic> json) {
    return ConversionFunnels(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] ?? '',
      steps: List<String>.from(json['steps'] ?? []),
      stepMetrics: Map<String, dynamic>.from(json['step_metrics'] ?? {}),
      conversionRate: (json['conversion_rate'] ?? 0).toDouble(),
      totalVisitors: json['total_visitors'] ?? 0,
      totalConversions: json['total_conversions'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'steps': steps,
      'step_metrics': stepMetrics,
      'conversion_rate': conversionRate,
      'total_visitors': totalVisitors,
      'total_conversions': totalConversions,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ConversionFunnels copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? steps,
    Map<String, dynamic>? stepMetrics,
    double? conversionRate,
    int? totalVisitors,
    int? totalConversions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ConversionFunnels(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      steps: steps ?? this.steps,
      stepMetrics: stepMetrics ?? this.stepMetrics,
      conversionRate: conversionRate ?? this.conversionRate,
      totalVisitors: totalVisitors ?? this.totalVisitors,
      totalConversions: totalConversions ?? this.totalConversions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        steps,
        stepMetrics,
        conversionRate,
        totalVisitors,
        totalConversions,
        createdAt,
        updatedAt,
      ];
}
