class EventWish {
  final String id;
  final String eventId;
  final String? guestId; // Optional, if they are a registered user
  final String guestName;
  final String message;
  final DateTime createdAt;

  const EventWish({
    required this.id,
    required this.eventId,
    this.guestId,
    required this.guestName,
    required this.message,
    required this.createdAt,
  });

  EventWish copyWith({
    String? id,
    String? eventId,
    String? guestId,
    String? guestName,
    String? message,
    DateTime? createdAt,
  }) {
    return EventWish(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'guestId': guestId,
      'guestName': guestName,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory EventWish.fromJson(Map<String, dynamic> json) {
    return EventWish(
      id: json['id'],
      eventId: json['eventId'],
      guestId: json['guestId'],
      guestName: json['guestName'],
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  factory EventWish.fromSupabase(Map<String, dynamic> json) {
    return EventWish(
      id: json['id'],
      eventId: json['event_id'],
      guestId: json['guest_id'],
      guestName: json['guest_name'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'event_id': eventId,
      'guest_id': guestId,
      'guest_name': guestName,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
