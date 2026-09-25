import 'package:equatable/equatable.dart';

class ChecklistItem extends Equatable {
  final String id;
  final String eventId;
  final String userId;
  final String title;
  final String category;
  final bool isDone;
  final DateTime? dueDate;
  final bool isEssential;
  final DateTime createdAt;

  const ChecklistItem({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.title,
    this.category = 'General',
    this.isDone = false,
    this.dueDate,
    this.isEssential = false,
    required this.createdAt,
  });

  factory ChecklistItem.fromSupabase(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      eventId: json['event_id'],
      userId: json['user_id'] ?? '',
      title: json['title'],
      category: json['category'] ?? 'General',
      isDone: json['is_done'] ?? false,
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      isEssential: json['is_essential'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'event_id': eventId,
      'user_id': userId,
      'title': title,
      'category': category,
      'is_done': isDone,
      'due_date': dueDate?.toIso8601String(),
      'is_essential': isEssential,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ChecklistItem copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? title,
    String? category,
    bool? isDone,
    DateTime? dueDate,
    bool? isEssential,
    DateTime? createdAt,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate ?? this.dueDate,
      isEssential: isEssential ?? this.isEssential,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, eventId, userId, title, category, isDone, dueDate, isEssential, createdAt];
}

class TimelineEvent extends Equatable {
  final String id;
  final String eventId;
  final String userId;
  final String title;
  final String category;
  final DateTime date;
  final String notes;
  final String audience; // 'all', 'host', 'guest'
  final DateTime createdAt;

  const TimelineEvent({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.title,
    required this.category,
    required this.date,
    this.notes = '',
    this.audience = 'all',
    required this.createdAt,
  });

  factory TimelineEvent.fromSupabase(Map<String, dynamic> json) {
    return TimelineEvent(
      id: json['id'],
      eventId: json['event_id'],
      userId: json['user_id'] ?? '',
      title: json['title'],
      category: json['category'],
      date: DateTime.parse(json['event_date']),
      notes: json['notes'] ?? '',
      audience: json['audience'] ?? 'all',
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'event_id': eventId,
      'title': title,
      'category': category,
      'event_date': date.toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TimelineEvent copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? title,
    String? category,
    DateTime? date,
    String? notes,
    String? audience,
    DateTime? createdAt,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      audience: audience ?? this.audience,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [id, eventId, userId, title, category, date, notes, audience, createdAt];
}
