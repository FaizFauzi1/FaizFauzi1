import 'package:equatable/equatable.dart';

class ChurnReasons extends Equatable {
  final String id;
  final String userId;
  final String reason;
  final String? description;
  final DateTime churnDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChurnReasons({
    required this.id,
    required this.userId,
    required this.reason,
    this.description,
    required this.churnDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChurnReasons.fromJson(Map<String, dynamic> json) {
    return ChurnReasons(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      reason: json['reason'] as String,
      description: json['description'] as String?,
      churnDate: DateTime.parse(json['churn_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'reason': reason,
      'description': description,
      'churn_date': churnDate.toIso8601String().split('T')[0],
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChurnReasons copyWith({
    String? id,
    String? userId,
    String? reason,
    String? description,
    DateTime? churnDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChurnReasons(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reason: reason ?? this.reason,
      description: description ?? this.description,
      churnDate: churnDate ?? this.churnDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        reason,
        description,
        churnDate,
        createdAt,
        updatedAt,
      ];
}
