import 'package:flutter/material.dart';

/// Team capacity configuration for a service
class TeamCapacityConfig {
  final int totalTeamsAvailable;
  final int maxEventsPerDay;
  final int minGapBetweenEventsMinutes;
  final bool allowConcurrentBookings;

  TeamCapacityConfig({
    required this.totalTeamsAvailable,
    required this.maxEventsPerDay,
    this.minGapBetweenEventsMinutes = 60,
    this.allowConcurrentBookings = false,
  });

  factory TeamCapacityConfig.fromJson(Map<String, dynamic> json) {
    return TeamCapacityConfig(
      totalTeamsAvailable: json['total_teams_available'] ?? 1,
      maxEventsPerDay: json['max_events_per_day'] ?? 1,
      minGapBetweenEventsMinutes: json['min_gap_between_events_minutes'] ?? 60,
      allowConcurrentBookings: json['allow_concurrent_bookings'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_teams_available': totalTeamsAvailable,
      'max_events_per_day': maxEventsPerDay,
      'min_gap_between_events_minutes': minGapBetweenEventsMinutes,
      'allow_concurrent_bookings': allowConcurrentBookings,
    };
  }

  /// Check if a new booking can be accommodated on a given date
  bool canAccommodateBooking({
    required int existingBookingsCount,
    required int teamsAlreadyBooked,
  }) {
    // Check team availability
    if (!allowConcurrentBookings && teamsAlreadyBooked >= totalTeamsAvailable) {
      return false;
    }

    // Check max events per day
    if (existingBookingsCount >= maxEventsPerDay) {
      return false;
    }

    return true;
  }
}

/// Predefined time slot for a service
class TimeSlot {
  final String id;
  final String name;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<String> applicableEventTypes;
  final double? priceModifier; // Optional price adjustment for this slot

  TimeSlot({
    required this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    this.applicableEventTypes = const [],
    this.priceModifier,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      startTime: _parseTimeOfDay(json['start_time']),
      endTime: _parseTimeOfDay(json['end_time']),
      applicableEventTypes: (json['applicable_event_types'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      priceModifier: (json['price_modifier'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'start_time': _formatTimeOfDay(startTime),
      'end_time': _formatTimeOfDay(endTime),
      'applicable_event_types': applicableEventTypes,
      'price_modifier': priceModifier,
    };
  }

  static TimeOfDay _parseTimeOfDay(dynamic value) {
    if (value == null) return const TimeOfDay(hour: 9, minute: 0);
    if (value is String) {
      final parts = value.split(':');
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  static String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Get duration in minutes
  int getDurationMinutes() {
    final startMinutes = startTime.hour * 60 + startTime.minute;
    final endMinutes = endTime.hour * 60 + endTime.minute;
    return endMinutes - startMinutes;
  }

  /// Check if this slot is applicable for a given event type
  bool isApplicableFor(String eventType) {
    if (applicableEventTypes.isEmpty) return true;
    return applicableEventTypes.contains(eventType);
  }
}

/// Availability slot configuration for a service
class AvailabilitySlotConfig {
  final int slotDurationMinutes;
  final int maxEventsPerDay;
  final int gapBetweenEventsMinutes;
  final List<TimeSlot> predefinedSlots;
  final bool autoGenerateSlots;
  final TimeOfDay? defaultStartTime;
  final TimeOfDay? defaultEndTime;

  AvailabilitySlotConfig({
    required this.slotDurationMinutes,
    required this.maxEventsPerDay,
    this.gapBetweenEventsMinutes = 60,
    this.predefinedSlots = const [],
    this.autoGenerateSlots = false,
    this.defaultStartTime,
    this.defaultEndTime,
  });

  factory AvailabilitySlotConfig.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlotConfig(
      slotDurationMinutes: json['slot_duration_minutes'] ?? 180,
      maxEventsPerDay: json['max_events_per_day'] ?? 2,
      gapBetweenEventsMinutes: json['gap_between_events_minutes'] ?? 60,
      predefinedSlots: (json['predefined_slots'] as List?)
              ?.map((e) => TimeSlot.fromJson(e))
              .toList() ??
          [],
      autoGenerateSlots: json['auto_generate_slots'] ?? false,
      defaultStartTime: json['default_start_time'] != null
          ? TimeSlot._parseTimeOfDay(json['default_start_time'])
          : null,
      defaultEndTime: json['default_end_time'] != null
          ? TimeSlot._parseTimeOfDay(json['default_end_time'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'slot_duration_minutes': slotDurationMinutes,
      'max_events_per_day': maxEventsPerDay,
      'gap_between_events_minutes': gapBetweenEventsMinutes,
      'predefined_slots': predefinedSlots.map((e) => e.toJson()).toList(),
      'auto_generate_slots': autoGenerateSlots,
      'default_start_time': defaultStartTime != null
          ? TimeSlot._formatTimeOfDay(defaultStartTime!)
          : null,
      'default_end_time': defaultEndTime != null
          ? TimeSlot._formatTimeOfDay(defaultEndTime!)
          : null,
    };
  }

  /// Generate time slots for a day based on configuration
  List<TimeSlot> generateSlotsForDay() {
    if (!autoGenerateSlots || defaultStartTime == null || defaultEndTime == null) {
      return predefinedSlots;
    }

    final slots = <TimeSlot>[];
    final startMinutes = defaultStartTime!.hour * 60 + defaultStartTime!.minute;
    final endMinutes = defaultEndTime!.hour * 60 + defaultEndTime!.minute;
    
    int currentMinutes = startMinutes;
    int slotIndex = 1;

    while (currentMinutes + slotDurationMinutes <= endMinutes) {
      final slotStart = TimeOfDay(
        hour: currentMinutes ~/ 60,
        minute: currentMinutes % 60,
      );
      final slotEnd = TimeOfDay(
        hour: (currentMinutes + slotDurationMinutes) ~/ 60,
        minute: (currentMinutes + slotDurationMinutes) % 60,
      );

      slots.add(TimeSlot(
        id: 'auto_slot_$slotIndex',
        name: 'Slot $slotIndex',
        startTime: slotStart,
        endTime: slotEnd,
      ));

      currentMinutes += slotDurationMinutes + gapBetweenEventsMinutes;
      slotIndex++;
    }

    return slots;
  }
}
