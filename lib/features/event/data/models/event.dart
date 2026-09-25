import 'package:eventease/features/event/data/models/event_type.dart';
import 'package:eventease/shared/models/other/venue.dart';

enum EventStatus {
  draft,
  published,
  ongoing,
  completed,
  cancelled,
}

class Event {
  final String id;
  final String title;
  final String description;
  final EventType type;
  final DateTime date;
  final DateTime startTime;
  final DateTime? endTime;
  final Venue venue;
  final String hostId; // Customer or Vendor ID
  final String hostName;
  final String? hostEmail;
  final String? hostPhone;
  final String? hostProfileImage;
  final EventStatus status;
  final String? theme;
  final String? dressCode;
  final int maxGuests;
  final bool isPublic;
  final String? invitationMessage;
  final String? coverImage;
  final List<String> tags;
  final Map<String, dynamic> additionalInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.date,
    required this.startTime,
    this.endTime,
    required this.venue,
    required this.hostId,
    required this.hostName,
    this.hostEmail,
    this.hostPhone,
    this.hostProfileImage,
    required this.status,
    this.theme,
    this.dressCode,
    required this.maxGuests,
    required this.isPublic,
    this.invitationMessage,
    this.coverImage,
    required this.tags,
    required this.additionalInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  // Copy with method for updates
  Event copyWith({
    String? id,
    String? title,
    String? description,
    EventType? type,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    Venue? venue,
    String? hostId,
    String? hostName,
    String? hostEmail,
    String? hostPhone,
    String? hostProfileImage,
    EventStatus? status,
    String? theme,
    String? dressCode,
    int? maxGuests,
    bool? isPublic,
    String? invitationMessage,
    String? coverImage,
    List<String>? tags,
    Map<String, dynamic>? additionalInfo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      venue: venue ?? this.venue,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostEmail: hostEmail ?? this.hostEmail,
      hostPhone: hostPhone ?? this.hostPhone,
      hostProfileImage: hostProfileImage ?? this.hostProfileImage,
      status: status ?? this.status,
      theme: theme ?? this.theme,
      dressCode: dressCode ?? this.dressCode,
      maxGuests: maxGuests ?? this.maxGuests,
      isPublic: isPublic ?? this.isPublic,
      invitationMessage: invitationMessage ?? this.invitationMessage,
      coverImage: coverImage ?? this.coverImage,
      tags: tags ?? this.tags,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.id,
      'date': date.toIso8601String(),
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'venue': venue.toJson(),
      'hostId': hostId,
      'hostName': hostName,
      'hostEmail': hostEmail,
      'hostPhone': hostPhone,
      'hostProfileImage': hostProfileImage,
      'status': status.toString(),
      'theme': theme,
      'dressCode': dressCode,
      'maxGuests': maxGuests,
      'isPublic': isPublic,
      'invitationMessage': invitationMessage,
      'coverImage': coverImage,
      'tags': tags,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: EventType.fromId(json['type']),
      date: DateTime.parse(json['date']),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      venue: Venue.fromJson(json['venue']),
      hostId: json['hostId'],
      hostName: json['hostName'],
      hostEmail: json['hostEmail'],
      hostPhone: json['hostPhone'],
      hostProfileImage: json['hostProfileImage'],
      status: EventStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => EventStatus.draft,
      ),
      theme: json['theme'],
      dressCode: json['dressCode'],
      maxGuests: json['maxGuests'] ?? 100,
      isPublic: json['isPublic'] ?? false,
      invitationMessage: json['invitationMessage'],
      coverImage: json['coverImage'],
      tags: List<String>.from(json['tags'] ?? []),
      additionalInfo: json['additionalInfo'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Create from Supabase JSON (snake_case)
  factory Event.fromSupabase(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      type: EventType.fromId(json['type']),
      date: DateTime.parse(json['date']),
      startTime: DateTime.parse(json['start_time']),
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      venue: json['venue_data'] != null 
          ? Venue.fromJson(json['venue_data']) 
          : (json['venue'] != null ? Venue.fromJson(json['venue']) : Venue.sample()), // Fallback
      hostId: json['host_id'],
      hostName: json['host_name'],
      hostEmail: json['host_email'],
      hostPhone: json['host_phone'],
      hostProfileImage: json['host_profile_image'],
      status: EventStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => EventStatus.draft,
      ),
      theme: json['theme'],
      dressCode: json['dress_code'],
      maxGuests: json['max_guests'] ?? 100,
      isPublic: json['is_public'] ?? false,
      invitationMessage: json['invitation_message'],
      coverImage: json['cover_image'],
      tags: List<String>.from(json['tags'] ?? []),
      additionalInfo: json['additional_info'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Convert to Supabase JSON (snake_case)
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.id,
      'date': date.toIso8601String(),
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'venue_data': venue.toJson(), // Store venue as JSONB
      'host_id': hostId,
      'host_name': hostName,
      'host_email': hostEmail,
      'host_phone': hostPhone,
      'host_profile_image': hostProfileImage,
      'status': status.toString().split('.').last, // Just the status name
      'theme': theme,
      'dress_code': dressCode,
      'max_guests': maxGuests,
      'is_public': isPublic,
      'invitation_message': invitationMessage,
      'cover_image': coverImage,
      'tags': tags,
      'additional_info': additionalInfo,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Sample data factory
  factory Event.sample() {
    return Event(
      id: 'event_1',
      title: 'Sarah & John\'s Wedding',
      description: 'Join us for our special day as we celebrate our love and commitment.',
      type: EventType.wedding,
      date: DateTime(2024, 6, 15),
      startTime: DateTime(2024, 6, 15, 16, 0),
      endTime: DateTime(2024, 6, 15, 23, 0),
      venue: Venue.sample(),
      hostId: 'customer1@eventease.com',
      hostName: 'Sarah Johnson',
      hostEmail: 'sarah.j@email.com',
      hostPhone: '+60 12-345 6789',
      status: EventStatus.published,
      theme: 'Garden Romance',
      dressCode: 'Semi-formal',
      maxGuests: 150,
      isPublic: false,
      invitationMessage: 'We can\'t wait to celebrate with you!',
      coverImage: null,
      tags: ['wedding', 'celebration', 'love'],
      additionalInfo: {},
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now(),
    );
  }
}
