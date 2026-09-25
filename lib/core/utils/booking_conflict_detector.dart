import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:flutter/material.dart';

class BookingConflictDetector {
  static List<BookingConflict> detectConflicts({
    required VendorServiceEnhanced service,
    required DateTime startTime,
    required DateTime endTime,
    required List<Booking> existingBookings,
  }) {
    final conflicts = <BookingConflict>[];

    // Check service availability
    if (!service.isAvailableOnDate(startTime)) {
      conflicts.add(
        BookingConflict(
          type: ConflictType.serviceUnavailable,
          message: 'Service is not available on this date',
          severity: ConflictSeverity.high,
        ),
      );
    }

    // Check unavailable periods
    for (final period in service.unavailablePeriods) {
      final periodStart = DateTime.parse(period['startDate']);
      final periodEnd = DateTime.parse(period['endDate']);

      if (_datesOverlap(startTime, endTime, periodStart, periodEnd)) {
        conflicts.add(
          BookingConflict(
            type: ConflictType.unavailablePeriod,
            message: 'Service is blocked during this period: ${period['reason'] ?? 'Maintenance'}',
            severity: ConflictSeverity.high,
          ),
        );
      }
    }

    // Check existing bookings
    for (final booking in existingBookings) {
      final bookingStart = DateTime(
        booking.bookingDate.year,
        booking.bookingDate.month,
        booking.bookingDate.day,
        booking.bookingTime.hour,
        booking.bookingTime.minute,
      );
      final bookingEnd = _calculateEndTime(bookingStart, booking.duration);

      if (_timeSlotsOverlap(startTime, endTime, bookingStart, bookingEnd)) {
        conflicts.add(
          BookingConflict(
            type: ConflictType.doubleBooking,
            message: 'Time slot conflicts with existing booking',
            severity: ConflictSeverity.critical,
            conflictingBooking: booking,
          ),
        );
      }
    }

    // Check daily booking limits
    final bookingsOnDate = existingBookings.where((booking) =>
      booking.bookingDate.year == startTime.year &&
      booking.bookingDate.month == startTime.month &&
      booking.bookingDate.day == startTime.day
    ).length;

    if (bookingsOnDate >= service.maxBookingsPerDay) {
      conflicts.add(
        BookingConflict(
          type: ConflictType.dailyLimitExceeded,
          message: 'Maximum bookings per day (${service.maxBookingsPerDay}) exceeded',
          severity: ConflictSeverity.high,
        ),
      );
    }

    // Check advance booking requirements
    final daysInAdvance = startTime.difference(DateTime.now()).inDays;
    if (daysInAdvance > service.advanceBookingDays) {
      conflicts.add(
        BookingConflict(
          type: ConflictType.advanceBookingLimit,
          message: 'Booking is too far in advance (max ${service.advanceBookingDays} days)',
          severity: ConflictSeverity.medium,
        ),
      );
    }

    return conflicts;
  }

  static bool _datesOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  static bool _timeSlotsOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  static DateTime _calculateEndTime(DateTime start, String durationStr) {
    final lower = durationStr.toLowerCase();
    if (lower.contains('full day')) {
      return start.add(const Duration(hours: 24));
    } else if (lower.contains('hour')) {
      final hours = int.tryParse(durationStr.split(' ')[0]) ?? 1;
      return start.add(Duration(hours: hours));
    } else if (lower.contains('day')) {
      final days = int.tryParse(durationStr.split(' ')[0]) ?? 1;
      return start.add(Duration(hours: days * 24));
    } else {
      // Default to 1 hour
      return start.add(const Duration(hours: 1));
    }
  }

  static String getConflictSummary(List<BookingConflict> conflicts) {
    if (conflicts.isEmpty) return 'No conflicts detected';

    final critical = conflicts.where((c) => c.severity == ConflictSeverity.critical).length;
    final high = conflicts.where((c) => c.severity == ConflictSeverity.high).length;
    final medium = conflicts.where((c) => c.severity == ConflictSeverity.medium).length;

    return 'Conflicts: $critical critical, $high high, $medium medium priority';
  }

  static bool hasBlockingConflicts(List<BookingConflict> conflicts) {
    return conflicts.any((conflict) =>
      conflict.severity == ConflictSeverity.critical ||
      conflict.severity == ConflictSeverity.high
    );
  }
}

enum ConflictType {
  serviceUnavailable,
  unavailablePeriod,
  doubleBooking,
  dailyLimitExceeded,
  advanceBookingLimit,
}

enum ConflictSeverity {
  critical, // Must be resolved (double booking, unavailable period)
  high,     // Should be resolved (daily limit, service unavailable)
  medium,   // Warning (advance booking limit)
  low,      // Information only
}

class BookingConflict {
  final ConflictType type;
  final String message;
  final ConflictSeverity severity;
  final Booking? conflictingBooking;

  BookingConflict({
    required this.type,
    required this.message,
    required this.severity,
    this.conflictingBooking,
  });

  @override
  String toString() {
    return 'BookingConflict(type: $type, message: $message, severity: $severity)';
  }
}

class ConflictResolutionSuggestion {
  static List<String> getSuggestions(BookingConflict conflict) {
    switch (conflict.type) {
      case ConflictType.serviceUnavailable:
        return [
          'Check the service availability schedule',
          'Choose a different date when the service is available',
          'Contact the vendor to request special availability',
        ];

      case ConflictType.unavailablePeriod:
        return [
          'Select a date outside the blocked period',
          'Check the reason for unavailability',
          'Contact vendor for alternative arrangements',
        ];

      case ConflictType.doubleBooking:
        return [
          'Choose a different time slot',
          'Select a different date',
          'Contact vendor to resolve scheduling conflict',
        ];

      case ConflictType.dailyLimitExceeded:
        return [
          'Choose a different date with available slots',
          'Book for a different time if possible',
          'Contact vendor about increasing daily limits',
        ];

      case ConflictType.advanceBookingLimit:
        return [
          'Book closer to the service date',
          'Check if advance booking limits can be extended',
          'Contact vendor for special arrangements',
        ];

      default:
        return ['Contact vendor to resolve the issue'];
    }
  }
}

class AutomatedSchedulingService {
  static List<TimeSlotSuggestion> suggestAvailableSlots({
    required VendorServiceEnhanced service,
    required DateTime date,
    required Duration duration,
    required List<Booking> existingBookings,
  }) {
    final suggestions = <TimeSlotSuggestion>[];

    if (!service.isAvailableOnDate(date)) {
      return suggestions;
    }

    // Get service hours for the day
    final dayName = _getDayName(date.weekday);
    final daySchedule = service.availability[dayName];

    if (daySchedule == null || !daySchedule['available']) {
      return suggestions;
    }

    final startTimeStr = daySchedule['start'] as String;
    final endTimeStr = daySchedule['end'] as String;

    final startTime = _parseTimeString(startTimeStr);
    final endTime = _parseTimeString(endTimeStr);

    final serviceStart = DateTime(
      date.year,
      date.month,
      date.day,
      startTime.hour,
      startTime.minute,
    );

    final serviceEnd = DateTime(
      date.year,
      date.month,
      date.day,
      endTime.hour,
      endTime.minute,
    );

    // Generate possible time slots
    var currentSlot = serviceStart;
    while (currentSlot.add(duration).isBefore(serviceEnd) ||
           currentSlot.add(duration).isAtSameMomentAs(serviceEnd)) {

      final slotEnd = currentSlot.add(duration);

      // Check for conflicts
      final conflicts = BookingConflictDetector.detectConflicts(
        service: service,
        startTime: currentSlot,
        endTime: slotEnd,
        existingBookings: existingBookings,
      );

      suggestions.add(
        TimeSlotSuggestion(
          startTime: currentSlot,
          endTime: slotEnd,
          conflicts: conflicts,
          isAvailable: !BookingConflictDetector.hasBlockingConflicts(conflicts),
        ),
      );

      currentSlot = currentSlot.add(const Duration(minutes: 30)); // 30-minute intervals
    }

    return suggestions;
  }

  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  static TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
}

class TimeSlotSuggestion {
  final DateTime startTime;
  final DateTime endTime;
  final List<BookingConflict> conflicts;
  final bool isAvailable;

  TimeSlotSuggestion({
    required this.startTime,
    required this.endTime,
    required this.conflicts,
    required this.isAvailable,
  });

  Duration get duration => endTime.difference(startTime);

  String get timeRange => '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

  @override
  String toString() {
    return 'TimeSlotSuggestion(start: $startTime, end: $endTime, available: $isAvailable, conflicts: ${conflicts.length})';
  }
}
