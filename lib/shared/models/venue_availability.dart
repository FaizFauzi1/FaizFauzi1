import 'package:equatable/equatable.dart';

enum AvailabilityStatus { available, booked, blocked, maintenance }

class VenueAvailability extends Equatable {
  final String id;
  final String venueId;
  final DateTime date;
  final String? timeSlot;
  final AvailabilityStatus status;
  final String? bookingId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VenueAvailability({
    required this.id,
    required this.venueId,
    required this.date,
    this.timeSlot,
    this.status = AvailabilityStatus.available,
    this.bookingId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VenueAvailability.fromJson(Map<String, dynamic> json) {
    return VenueAvailability(
      id: json['id'] as String,
      venueId: json['venue_id'] as String,
      date: DateTime.parse(json['date']),
      timeSlot: json['time_slot'] as String?,
      status: AvailabilityStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => AvailabilityStatus.available,
      ),
      bookingId: json['booking_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venue_id': venueId,
      'date': date.toIso8601String().split('T')[0],
      'time_slot': timeSlot,
      'status': status.name,
      'booking_id': bookingId,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VenueAvailability copyWith({
    String? id,
    String? venueId,
    DateTime? date,
    String? timeSlot,
    AvailabilityStatus? status,
    String? bookingId,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VenueAvailability(
      id: id ?? this.id,
      venueId: venueId ?? this.venueId,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      status: status ?? this.status,
      bookingId: bookingId ?? this.bookingId,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        venueId,
        date,
        timeSlot,
        status,
        bookingId,
        notes,
        createdAt,
        updatedAt,
      ];
}
