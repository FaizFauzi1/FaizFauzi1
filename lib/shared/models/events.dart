import 'package:equatable/equatable.dart';

enum EventType { page_view, button_click, form_submit, search, booking, payment }

class Events extends Equatable {
  final String id;
  final String? userId;
  final String sessionId;
  final EventType eventType;
  final String eventName;
  final Map<String, dynamic>? eventData;
  final String? pageUrl;
  final String? userAgent;
  final String? ipAddress;
  final DateTime createdAt;

  const Events({
    required this.id,
    this.userId,
    required this.sessionId,
    required this.eventType,
    required this.eventName,
    this.eventData,
    this.pageUrl,
    this.userAgent,
    this.ipAddress,
    required this.createdAt,
  });

  factory Events.fromJson(Map<String, dynamic> json) {
    return Events(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      sessionId: json['session_id'] as String,
      eventType: EventType.values.firstWhere(
        (type) => type.name == json['event_type'],
        orElse: () => EventType.page_view,
      ),
      eventName: json['event_name'] as String,
      eventData: json['event_data'] as Map<String, dynamic>?,
      pageUrl: json['page_url'] as String?,
      userAgent: json['user_agent'] as String?,
      ipAddress: json['ip_address'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'session_id': sessionId,
      'event_type': eventType.name,
      'event_name': eventName,
      'event_data': eventData,
      'page_url': pageUrl,
      'user_agent': userAgent,
      'ip_address': ipAddress,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Events copyWith({
    String? id,
    String? userId,
    String? sessionId,
    EventType? eventType,
    String? eventName,
    Map<String, dynamic>? eventData,
    String? pageUrl,
    String? userAgent,
    String? ipAddress,
    DateTime? createdAt,
  }) {
    return Events(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      sessionId: sessionId ?? this.sessionId,
      eventType: eventType ?? this.eventType,
      eventName: eventName ?? this.eventName,
      eventData: eventData ?? this.eventData,
      pageUrl: pageUrl ?? this.pageUrl,
      userAgent: userAgent ?? this.userAgent,
      ipAddress: ipAddress ?? this.ipAddress,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        sessionId,
        eventType,
        eventName,
        eventData,
        pageUrl,
        userAgent,
        ipAddress,
        createdAt,
      ];
}
