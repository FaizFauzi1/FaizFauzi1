import 'package:equatable/equatable.dart';

enum ChecklistPriority { low, medium, high }

class EventChecklist extends Equatable {
  final String id;
  final String userId;
  final String? eventId;
  final String title;
  final String? description;
  final String category;
  final bool isCompleted;
  final DateTime? dueDate;
  final DateTime? completedAt;
  final ChecklistPriority priority;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventChecklist({
    required this.id,
    required this.userId,
    this.eventId,
    required this.title,
    this.description,
    required this.category,
    this.isCompleted = false,
    this.dueDate,
    this.completedAt,
    this.priority = ChecklistPriority.medium,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventChecklist.fromJson(Map<String, dynamic> json) {
    return EventChecklist(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventId: json['event_id'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      isCompleted: json['is_completed'] ?? false,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      priority: ChecklistPriority.values.firstWhere(
        (priority) => priority.name == json['priority'],
        orElse: () => ChecklistPriority.medium,
      ),
      assignedTo: json['assigned_to'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_id': eventId,
      'title': title,
      'description': description,
      'category': category,
      'is_completed': isCompleted,
      'due_date': dueDate?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'priority': priority.name,
      'assigned_to': assignedTo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EventChecklist copyWith({
    String? id,
    String? userId,
    String? eventId,
    String? title,
    String? description,
    String? category,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? completedAt,
    ChecklistPriority? priority,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventChecklist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        eventId,
        title,
        description,
        category,
        isCompleted,
        dueDate,
        completedAt,
        priority,
        assignedTo,
        createdAt,
        updatedAt,
      ];
}
