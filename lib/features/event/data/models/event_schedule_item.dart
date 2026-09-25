import 'package:flutter/material.dart';

enum ScheduleItemType {
  ceremony,
  reception,
  dinner,
  dancing,
  speech,
  photoSession,
  cakeCutting,
  games,
  entertainment,
  networking,
  custom,
}

class EventScheduleItem {
  final String id;
  final String eventId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final ScheduleItemType type;
  final String? location;
  final String? speaker;
  final bool isRequired;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventScheduleItem({
    required this.id,
    required this.eventId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.type,
    this.location,
    this.speaker,
    required this.isRequired,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  EventScheduleItem copyWith({
    String? id,
    String? eventId,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    ScheduleItemType? type,
    String? location,
    String? speaker,
    bool? isRequired,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventScheduleItem(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      location: location ?? this.location,
      speaker: speaker ?? this.speaker,
      isRequired: isRequired ?? this.isRequired,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type.toString().split('.').last,
      'location': location,
      'speaker': speaker,
      'isRequired': isRequired,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory EventScheduleItem.fromJson(Map<String, dynamic> json) {
    return EventScheduleItem(
      id: json['id'],
      eventId: json['eventId'],
      title: json['title'],
      description: json['description'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      type: ScheduleItemType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => ScheduleItemType.custom,
      ),
      location: json['location'],
      speaker: json['speaker'],
      isRequired: json['isRequired'] ?? true,
      order: json['order'] ?? 0,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  factory EventScheduleItem.sample({
    required String eventId,
    required int order,
    required ScheduleItemType type,
    required String title,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    return EventScheduleItem(
      id: 'schedule_${eventId}_${order}',
      eventId: eventId,
      title: title,
      description: _getDefaultDescription(type),
      startTime: startTime,
      endTime: endTime,
      type: type,
      location: _getDefaultLocation(type),
      speaker: _getDefaultSpeaker(type),
      isRequired: true,
      order: order,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static String? _getDefaultDescription(ScheduleItemType type) {
    switch (type) {
      case ScheduleItemType.ceremony:
        return 'The main wedding ceremony where vows are exchanged';
      case ScheduleItemType.reception:
        return 'Welcome drinks and mingling with guests';
      case ScheduleItemType.dinner:
        return 'Sit-down dinner service';
      case ScheduleItemType.dancing:
        return 'Dance floor opens for celebration';
      case ScheduleItemType.speech:
        return 'Speeches from family and friends';
      case ScheduleItemType.photoSession:
        return 'Professional photography session';
      case ScheduleItemType.cakeCutting:
        return 'Traditional cake cutting ceremony';
      case ScheduleItemType.games:
        return 'Fun games and activities for guests';
      case ScheduleItemType.entertainment:
        return 'Live entertainment and performances';
      case ScheduleItemType.networking:
        return 'Networking and socializing time';
      case ScheduleItemType.custom:
        return null;
    }
  }

  static String? _getDefaultLocation(ScheduleItemType type) {
    switch (type) {
      case ScheduleItemType.ceremony:
        return 'Main Hall';
      case ScheduleItemType.reception:
        return 'Garden Terrace';
      case ScheduleItemType.dinner:
        return 'Banquet Hall';
      case ScheduleItemType.dancing:
        return 'Dance Floor';
      case ScheduleItemType.speech:
        return 'Main Stage';
      case ScheduleItemType.photoSession:
        return 'Photo Area';
      case ScheduleItemType.cakeCutting:
        return 'Cake Table';
      case ScheduleItemType.games:
        return 'Activity Area';
      case ScheduleItemType.entertainment:
        return 'Performance Stage';
      case ScheduleItemType.networking:
        return 'Lounge Area';
      case ScheduleItemType.custom:
        return null;
    }
  }

  static String? _getDefaultSpeaker(ScheduleItemType type) {
    switch (type) {
      case ScheduleItemType.speech:
        return 'Best Man & Maid of Honor';
      case ScheduleItemType.entertainment:
        return 'DJ/Musician';
      default:
        return null;
    }
  }

  IconData get icon {
    switch (type) {
      case ScheduleItemType.ceremony:
        return Icons.church;
      case ScheduleItemType.reception:
        return Icons.wine_bar;
      case ScheduleItemType.dinner:
        return Icons.restaurant;
      case ScheduleItemType.dancing:
        return Icons.music_note;
      case ScheduleItemType.speech:
        return Icons.mic;
      case ScheduleItemType.photoSession:
        return Icons.camera_alt;
      case ScheduleItemType.cakeCutting:
        return Icons.cake;
      case ScheduleItemType.games:
        return Icons.games;
      case ScheduleItemType.entertainment:
        return Icons.theater_comedy;
      case ScheduleItemType.networking:
        return Icons.people;
      case ScheduleItemType.custom:
        return Icons.schedule;
    }
  }

  Color get color {
    switch (type) {
      case ScheduleItemType.ceremony:
        return const Color(0xFF8B5CF6); // Purple
      case ScheduleItemType.reception:
        return const Color(0xFFF59E0B); // Amber
      case ScheduleItemType.dinner:
        return const Color(0xFFEF4444); // Red
      case ScheduleItemType.dancing:
        return const Color(0xFF06B6D4); // Cyan
      case ScheduleItemType.speech:
        return const Color(0xFF10B981); // Emerald
      case ScheduleItemType.photoSession:
        return const Color(0xFFF97316); // Orange
      case ScheduleItemType.cakeCutting:
        return const Color(0xFFEC4899); // Pink
      case ScheduleItemType.games:
        return const Color(0xFF84CC16); // Lime
      case ScheduleItemType.entertainment:
        return const Color(0xFF6366F1); // Indigo
      case ScheduleItemType.networking:
        return const Color(0xFF6B7280); // Gray
      case ScheduleItemType.custom:
        return const Color(0xFF374151); // Dark Gray
    }
  }
}
