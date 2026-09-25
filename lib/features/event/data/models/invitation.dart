
enum InvitationStatus {
  sent,
  viewed,
  accepted,
  declined,
  pending,
}

class Invitation {
  final String id;
  final String eventId;
  final String guestEmail;
  final String? guestName;
  final String? guestPhone;
  final InvitationStatus status;
  final String invitationCode; // Unique code for the invitation link
  final String? personalMessage;
  final bool allowPlusOne;
  final int maxPlusOnes;
  final DateTime sentAt;
  final DateTime? viewedAt;
  final DateTime? respondedAt;
  final String? rsvpResponse;
  final List<String> plusOneNames;
  final Map<String, dynamic> additionalData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Invitation({
    required this.id,
    required this.eventId,
    required this.guestEmail,
    this.guestName,
    this.guestPhone,
    required this.status,
    required this.invitationCode,
    this.personalMessage,
    required this.allowPlusOne,
    required this.maxPlusOnes,
    required this.sentAt,
    this.viewedAt,
    this.respondedAt,
    this.rsvpResponse,
    required this.plusOneNames,
    required this.additionalData,
    required this.createdAt,
    required this.updatedAt,
  });

  // Copy with method for updates
  Invitation copyWith({
    String? id,
    String? eventId,
    String? guestEmail,
    String? guestName,
    String? guestPhone,
    InvitationStatus? status,
    String? invitationCode,
    String? personalMessage,
    bool? allowPlusOne,
    int? maxPlusOnes,
    DateTime? sentAt,
    DateTime? viewedAt,
    DateTime? respondedAt,
    String? rsvpResponse,
    List<String>? plusOneNames,
    Map<String, dynamic>? additionalData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invitation(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      guestEmail: guestEmail ?? this.guestEmail,
      guestName: guestName ?? this.guestName,
      guestPhone: guestPhone ?? this.guestPhone,
      status: status ?? this.status,
      invitationCode: invitationCode ?? this.invitationCode,
      personalMessage: personalMessage ?? this.personalMessage,
      allowPlusOne: allowPlusOne ?? this.allowPlusOne,
      maxPlusOnes: maxPlusOnes ?? this.maxPlusOnes,
      sentAt: sentAt ?? this.sentAt,
      viewedAt: viewedAt ?? this.viewedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      rsvpResponse: rsvpResponse ?? this.rsvpResponse,
      plusOneNames: plusOneNames ?? this.plusOneNames,
      additionalData: additionalData ?? this.additionalData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'guestEmail': guestEmail,
      'guestName': guestName,
      'guestPhone': guestPhone,
      'status': status.toString(),
      'invitationCode': invitationCode,
      'personalMessage': personalMessage,
      'allowPlusOne': allowPlusOne,
      'maxPlusOnes': maxPlusOnes,
      'sentAt': sentAt.toIso8601String(),
      'viewedAt': viewedAt?.toIso8601String(),
      'respondedAt': respondedAt?.toIso8601String(),
      'rsvpResponse': rsvpResponse,
      'plusOneNames': plusOneNames,
      'additionalData': additionalData,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'],
      eventId: json['eventId'],
      guestEmail: json['guestEmail'],
      guestName: json['guestName'],
      guestPhone: json['guestPhone'],
      status: InvitationStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => InvitationStatus.sent,
      ),
      invitationCode: json['invitationCode'],
      personalMessage: json['personalMessage'],
      allowPlusOne: json['allowPlusOne'] ?? false,
      maxPlusOnes: json['maxPlusOnes'] ?? 0,
      sentAt: DateTime.parse(json['sentAt']),
      viewedAt: json['viewedAt'] != null ? DateTime.parse(json['viewedAt']) : null,
      respondedAt: json['respondedAt'] != null ? DateTime.parse(json['respondedAt']) : null,
      rsvpResponse: json['rsvpResponse'],
      plusOneNames: List<String>.from(json['plusOneNames'] ?? []),
      additionalData: json['additionalData'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Create from Supabase JSON (snake_case)
  factory Invitation.fromSupabase(Map<String, dynamic> json) {
    return Invitation(
      id: json['id'],
      eventId: json['event_id'],
      guestEmail: json['guest_email'],
      guestName: json['guest_name'],
      guestPhone: json['guest_phone'],
      status: InvitationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => InvitationStatus.sent,
      ),
      invitationCode: json['invitation_code'],
      personalMessage: json['personal_message'],
      allowPlusOne: json['allow_plus_one'] ?? false,
      maxPlusOnes: json['max_plus_ones'] ?? 0,
      sentAt: DateTime.parse(json['sent_at']),
      viewedAt: json['viewed_at'] != null ? DateTime.parse(json['viewed_at']) : null,
      respondedAt: json['responded_at'] != null ? DateTime.parse(json['responded_at']) : null,
      rsvpResponse: json['rsvp_response'],
      plusOneNames: List<String>.from(json['plus_one_names'] ?? []),
      additionalData: json['additional_data'] ?? {},
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Convert to Supabase JSON (snake_case)
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'event_id': eventId,
      'guest_email': guestEmail,
      'guest_name': guestName,
      'guest_phone': guestPhone,
      'status': status.toString().split('.').last,
      'invitation_code': invitationCode,
      'personal_message': personalMessage,
      'allow_plus_one': allowPlusOne,
      'max_plus_ones': maxPlusOnes,
      'sent_at': sentAt.toIso8601String(),
      'viewed_at': viewedAt?.toIso8601String(),
      'responded_at': respondedAt?.toIso8601String(),
      'rsvp_response': rsvpResponse,
      'plus_one_names': plusOneNames,
      'additional_data': additionalData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Sample invitation
  factory Invitation.sample() {
    return Invitation(
      id: 'inv_1',
      eventId: 'event_1',
      guestEmail: 'john.doe@email.com',
      guestName: 'John Doe',
      guestPhone: '+60 12-345 6789',
      status: InvitationStatus.sent,
      invitationCode: 'ABC123XYZ',
      personalMessage: 'We would love to have you at our wedding!',
      allowPlusOne: true,
      maxPlusOnes: 1,
      sentAt: DateTime.now().subtract(const Duration(days: 7)),
      plusOneNames: [],
      additionalData: {},
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      updatedAt: DateTime.now(),
    );
  }
}
