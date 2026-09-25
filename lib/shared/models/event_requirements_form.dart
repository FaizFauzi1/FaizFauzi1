import 'package:equatable/equatable.dart';

enum RequirementsStatus { draft, submitted, reviewed, matched }

class EventRequirementsForm extends Equatable {
  final String id;
  final String userId;
  final String? eventTypeId;
  final DateTime eventDate;
  final int guestCount;
  final String budgetRange;
  final String venueType;
  final String? theme;
  final String? specialRequests;
  final List<String> preferredVendors;
  final Map<String, dynamic> timelineRequirements;
  final RequirementsStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventRequirementsForm({
    required this.id,
    required this.userId,
    this.eventTypeId,
    required this.eventDate,
    required this.guestCount,
    required this.budgetRange,
    required this.venueType,
    this.theme,
    this.specialRequests,
    this.preferredVendors = const [],
    this.timelineRequirements = const {},
    this.status = RequirementsStatus.draft,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventRequirementsForm.fromJson(Map<String, dynamic> json) {
    return EventRequirementsForm(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      eventTypeId: json['event_type_id'] as String?,
      eventDate: DateTime.parse(json['event_date']),
      guestCount: json['guest_count'] as int,
      budgetRange: json['budget_range'] as String,
      venueType: json['venue_type'] as String,
      theme: json['theme'] as String?,
      specialRequests: json['special_requests'] as String?,
      preferredVendors: List<String>.from(json['preferred_vendors'] ?? []),
      timelineRequirements: Map<String, dynamic>.from(json['timeline_requirements'] ?? {}),
      status: RequirementsStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RequirementsStatus.draft,
      ),
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'event_type_id': eventTypeId,
      'event_date': eventDate.toIso8601String(),
      'guest_count': guestCount,
      'budget_range': budgetRange,
      'venue_type': venueType,
      'theme': theme,
      'special_requests': specialRequests,
      'preferred_vendors': preferredVendors,
      'timeline_requirements': timelineRequirements,
      'status': status.name,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  EventRequirementsForm copyWith({
    String? id,
    String? userId,
    String? eventTypeId,
    DateTime? eventDate,
    int? guestCount,
    String? budgetRange,
    String? venueType,
    String? theme,
    String? specialRequests,
    List<String>? preferredVendors,
    Map<String, dynamic>? timelineRequirements,
    RequirementsStatus? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventRequirementsForm(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventTypeId: eventTypeId ?? this.eventTypeId,
      eventDate: eventDate ?? this.eventDate,
      guestCount: guestCount ?? this.guestCount,
      budgetRange: budgetRange ?? this.budgetRange,
      venueType: venueType ?? this.venueType,
      theme: theme ?? this.theme,
      specialRequests: specialRequests ?? this.specialRequests,
      preferredVendors: preferredVendors ?? this.preferredVendors,
      timelineRequirements: timelineRequirements ?? this.timelineRequirements,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        eventTypeId,
        eventDate,
        guestCount,
        budgetRange,
        venueType,
        theme,
        specialRequests,
        preferredVendors,
        timelineRequirements,
        status,
        reviewedBy,
        reviewedAt,
        createdAt,
        updatedAt,
      ];
}
