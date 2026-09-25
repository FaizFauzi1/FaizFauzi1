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

      // Calculate booking end time based on duration
      final bookingEnd = _calculateBookingEndTime(bookingStart, booking.duration);

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

    return conflicts;
  }

  static DateTime _calculateBookingEndTime(DateTime startTime, String duration) {
    final durationLower = duration.toLowerCase();

    if (durationLower.contains('hour')) {
      final hours = double.tryParse(
        durationLower.split('hour')[0].trim().replaceAll('s', '')
      ) ?? 1.0;
      return startTime.add(Duration(hours: hours.round()));
    } else if (durationLower.contains('minute')) {
      final minutes = int.tryParse(
        durationLower.split('minute')[0].trim().replaceAll('s', '')
      ) ?? 60;
      return startTime.add(Duration(minutes: minutes));
    } else {
      return startTime.add(const Duration(hours: 1));
    }
  }

  static bool _datesOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  static bool _timeSlotsOverlap(DateTime start1, DateTime end1, DateTime start2, DateTime end2) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  static String getConflictSummary(List<BookingConflict> conflicts) {
    if (conflicts.isEmpty) return 'No conflicts detected';

    final critical = conflicts.where((c) => c.severity == ConflictSeverity.critical).length;
    final high = conflicts.where((c) => c.severity == ConflictSeverity.high).length;

    return 'Conflicts: $critical critical, $high high priority';
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
}

enum ConflictSeverity {
  critical,
  high,
  medium,
  low,
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

    var currentSlot = serviceStart;
    while (currentSlot.add(duration).isBefore(serviceEnd) ||
           currentSlot.add(duration).isAtSameMomentAs(serviceEnd)) {

      final slotEnd = currentSlot.add(duration);

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

      currentSlot = currentSlot.add(const Duration(minutes: 30));
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
}
