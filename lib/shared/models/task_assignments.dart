import 'package:equatable/equatable.dart';

enum TaskStatus { pending, in_progress, completed, cancelled }

enum TaskPriority { low, medium, high, urgent }

class TaskAssignments extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String assignedTo;
  final String assignedBy;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final Map<String, dynamic>? metadata;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TaskAssignments({
    required this.id,
    required this.title,
    this.description,
    required this.assignedTo,
    required this.assignedBy,
    this.status = TaskStatus.pending,
    this.priority = TaskPriority.medium,
    this.dueDate,
    this.metadata,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskAssignments.fromJson(Map<String, dynamic> json) {
    return TaskAssignments(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      assignedTo: json['assigned_to'] as String,
      assignedBy: json['assigned_by'] as String,
      status: TaskStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => TaskStatus.pending,
      ),
      priority: TaskPriority.values.firstWhere(
        (priority) => priority.name == json['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'assigned_by': assignedBy,
      'status': status.name,
      'priority': priority.name,
      'due_date': dueDate?.toIso8601String(),
      'metadata': metadata,
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TaskAssignments copyWith({
    String? id,
    String? title,
    String? description,
    String? assignedTo,
    String? assignedBy,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    Map<String, dynamic>? metadata,
    DateTime? completedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TaskAssignments(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedBy: assignedBy ?? this.assignedBy,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      metadata: metadata ?? this.metadata,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        assignedTo,
        assignedBy,
        status,
        priority,
        dueDate,
        metadata,
        completedAt,
        createdAt,
        updatedAt,
      ];
}
