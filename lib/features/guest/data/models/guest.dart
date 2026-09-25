class Guest {
  final String id;
  final String eventId;
  final String invitationId;
  final String name;
  final String email;
  final String? phone;
  final bool isAttending;
  final int numberOfGuests;
  final String? dietaryPreferences;
  final String? seatingPreference;
  final String? mealChoice;
  final String? notes;
  final double? costPerGuest;
  final bool hasPlusOne;
  final String? plusOneName;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Guest({
    required this.id,
    required this.eventId,
    required this.invitationId,
    required this.name,
    required this.email,
    this.phone,
    required this.isAttending,
    required this.numberOfGuests,
    this.dietaryPreferences,
    this.seatingPreference,
    this.mealChoice,
    this.notes,
    this.costPerGuest,
    this.hasPlusOne = false,
    this.plusOneName,
    required this.createdAt,
    required this.updatedAt,
  });

  Guest copyWith({
    String? id,
    String? eventId,
    String? invitationId,
    String? name,
    String? email,
    String? phone,
    bool? isAttending,
    int? numberOfGuests,
    String? dietaryPreferences,
    String? seatingPreference,
    String? mealChoice,
    String? notes,
    double? costPerGuest,
    bool? hasPlusOne,
    String? plusOneName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Guest(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      invitationId: invitationId ?? this.invitationId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isAttending: isAttending ?? this.isAttending,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      seatingPreference: seatingPreference ?? this.seatingPreference,
      mealChoice: mealChoice ?? this.mealChoice,
      notes: notes ?? this.notes,
      costPerGuest: costPerGuest ?? this.costPerGuest,
      hasPlusOne: hasPlusOne ?? this.hasPlusOne,
      plusOneName: plusOneName ?? this.plusOneName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'invitationId': invitationId,
      'name': name,
      'email': email,
      'phone': phone,
      'isAttending': isAttending,
      'numberOfGuests': numberOfGuests,
      'dietaryPreferences': dietaryPreferences,
      'seatingPreference': seatingPreference,
      'mealChoice': mealChoice,
      'notes': notes,
      'costPerGuest': costPerGuest,
      'hasPlusOne': hasPlusOne,
      'plusOneName': plusOneName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Guest.fromJson(Map<String, dynamic> json) {
    return Guest(
      id: json['id'],
      eventId: json['eventId'] ?? '',
      invitationId: json['invitationId'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      isAttending: json['isAttending'] ?? false,
      numberOfGuests: json['numberOfGuests'] ?? 0,
      dietaryPreferences: json['dietaryPreferences'],
      seatingPreference: json['seatingPreference'],
      mealChoice: json['mealChoice'],
      notes: json['notes'],
      costPerGuest: json['costPerGuest']?.toDouble(),
      hasPlusOne: json['hasPlusOne'] ?? false,
      plusOneName: json['plusOneName'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Create from Supabase JSON (snake_case)
  factory Guest.fromSupabase(Map<String, dynamic> json) {
    return Guest(
      id: json['id'],
      eventId: json['event_id'] ?? '',
      invitationId: json['invitation_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      isAttending: json['is_attending'] ?? false,
      numberOfGuests: json['number_of_guests'] ?? 0,
      dietaryPreferences: json['dietary_preferences'],
      seatingPreference: json['seating_preference'],
      mealChoice: json['meal_choice'],
      notes: json['notes'],
      costPerGuest: (json['cost_per_guest'] as num?)?.toDouble(),
      hasPlusOne: json['has_plus_one'] ?? false,
      plusOneName: json['plus_one_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  // Convert to Supabase JSON (snake_case)
  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'event_id': eventId,
      'invitation_id': invitationId,
      'name': name,
      'email': email,
      'phone': phone,
      'is_attending': isAttending,
      'number_of_guests': numberOfGuests,
      'dietary_preferences': dietaryPreferences,
      'seating_preference': seatingPreference,
      'meal_choice': mealChoice,
      'notes': notes,
      'cost_per_guest': costPerGuest,
      'has_plus_one': hasPlusOne,
      'plus_one_name': plusOneName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Guest.sample() {
    return Guest(
      id: 'guest_1',
      eventId: 'event_1',
      invitationId: 'inv_1',
      name: 'Jane Smith',
      email: 'customer2@eventease.com',
      phone: '+60 12-345 6789',
      isAttending: true,
      numberOfGuests: 1,
      dietaryPreferences: 'Vegetarian',
      seatingPreference: 'Near stage',
      mealChoice: 'Vegan',
      notes: 'Allergic to nuts',
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      updatedAt: DateTime.now(),
    );
  }
}
