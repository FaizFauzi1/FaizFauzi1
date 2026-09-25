import 'package:equatable/equatable.dart';

enum MaintenanceType { database, server, api, security, performance }

class MaintenanceLog extends Equatable {
  final String id;
  final MaintenanceType maintenanceType;
  final String title;
  final String description;
  final DateTime scheduledStart;
  final DateTime? scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final String? performedBy;
  final String status;
  final String? impact;
  final List<String> affectedServices;
  final Map<String, dynamic> details;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MaintenanceLog({
    required this.id,
    required this.maintenanceType,
    required this.title,
    required this.description,
    required this.scheduledStart,
    this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    this.performedBy,
    required this.status,
    this.impact,
    this.affectedServices = const [],
    this.details = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceLog.fromJson(Map<String, dynamic> json) {
    return MaintenanceLog(
      id: json['id'] as String,
      maintenanceType: MaintenanceType.values.firstWhere(
        (type) => type.name == json['maintenance_type'],
        orElse: () => MaintenanceType.database,
      ),
      title: json['title'] as String,
      description: json['description'] as String,
      scheduledStart: DateTime.parse(json['scheduled_start']),
      scheduledEnd: json['scheduled_end'] != null ? DateTime.parse(json['scheduled_end']) : null,
      actualStart: json['actual_start'] != null ? DateTime.parse(json['actual_start']) : null,
      actualEnd: json['actual_end'] != null ? DateTime.parse(json['actual_end']) : null,
      performedBy: json['performed_by'] as String?,
      status: json['status'] as String,
      impact: json['impact'] as String?,
      affectedServices: List<String>.from(json['affected_services'] ?? []),
      details: Map<String, dynamic>.from(json['details'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maintenance_type': maintenanceType.name,
      'title': title,
      'description': description,
      'scheduled_start': scheduledStart.toIso8601String(),
      'scheduled_end': scheduledEnd?.toIso8601String(),
      'actual_start': actualStart?.toIso8601String(),
      'actual_end': actualEnd?.toIso8601String(),
      'performed_by': performedBy,
      'status': status,
      'impact': impact,
      'affected_services': affectedServices,
      'details': details,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MaintenanceLog copyWith({
    String? id,
    MaintenanceType? maintenanceType,
    String? title,
    String? description,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    DateTime? actualStart,
    DateTime? actualEnd,
    String? performedBy,
    String? status,
    String? impact,
    List<String>? affectedServices,
    Map<String, dynamic>? details,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MaintenanceLog(
      id: id ?? this.id,
      maintenanceType: maintenanceType ?? this.maintenanceType,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      actualStart: actualStart ?? this.actualStart,
      actualEnd: actualEnd ?? this.actualEnd,
      performedBy: performedBy ?? this.performedBy,
      status: status ?? this.status,
      impact: impact ?? this.impact,
      affectedServices: affectedServices ?? this.affectedServices,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        maintenanceType,
        title,
        description,
        scheduledStart,
        scheduledEnd,
        actualStart,
        actualEnd,
        performedBy,
        status,
        impact,
        affectedServices,
        details,
        createdAt,
        updatedAt,
      ];
}
