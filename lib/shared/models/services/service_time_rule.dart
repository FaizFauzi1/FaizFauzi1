import 'package:equatable/equatable.dart';

enum TimeType {
  fixedSlot('fixed_slot', 'Fixed Slots'),
  flexibleHour('flexible_hour', 'Flexible Hours'),
  session('session', 'Sessions (Morning/Evening)'),
  fullDay('full_day', 'Full Day'),
  dateRange('date_range', 'Date Range (Rental)');

  final String name;
  final String displayName;

  const TimeType(this.name, this.displayName);

  static TimeType fromString(String value) {
    return TimeType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => TimeType.flexibleHour,
    );
  }
}

class ServiceSession extends Equatable {
  final String name;
  final String startTime;
  final String endTime;
  final double priceMultiplier;

  const ServiceSession({
    required this.name,
    required this.startTime,
    required this.endTime,
    this.priceMultiplier = 1.0,
  });

  factory ServiceSession.fromJson(Map<String, dynamic> json) {
    return ServiceSession(
      name: json['name']?.toString() ?? '',
      startTime: json['start']?.toString() ?? '',
      endTime: json['end']?.toString() ?? '',
      priceMultiplier: (json['price_multiplier'] ?? 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'start': startTime,
      'end': endTime,
      'price_multiplier': priceMultiplier,
    };
  }

  @override
  List<Object?> get props => [name, startTime, endTime, priceMultiplier];
}

class ServiceTimeRule extends Equatable {
  final String? id;
  final String serviceId;
  final TimeType timeType;
  
  // Slot Configuration
  final int? slotDurationMinutes;
  
  // Duration Configuration
  final int? minDurationMinutes;
  final int? maxDurationMinutes;
  final int durationStepMinutes;
  
  // Buffer Configuration
  final int bufferBeforeMinutes;
  final int bufferAfterMinutes;
  
  // Session Configuration
  final List<ServiceSession> sessions;
  
  // General Rules
  final bool allowMultiDay;
  final int? maxDays;
  
  // Full Day / Global Hours
  final String? startTime;
  final String? endTime;

  const ServiceTimeRule({
    this.id,
    required this.serviceId,
    this.timeType = TimeType.fullDay,
    this.slotDurationMinutes,
    this.minDurationMinutes,
    this.maxDurationMinutes,
    this.durationStepMinutes = 60,
    this.bufferBeforeMinutes = 0,
    this.bufferAfterMinutes = 0,
    this.sessions = const [],
    this.allowMultiDay = false,
    this.maxDays,
    this.startTime,
    this.endTime,
  });

  factory ServiceTimeRule.fromJson(Map<String, dynamic> json) {
    return ServiceTimeRule(
      id: json['id']?.toString(),
      serviceId: json['service_id']?.toString() ?? '',
      timeType: TimeType.fromString(json['time_type']?.toString() ?? 'full_day'),
      slotDurationMinutes: (json['slot_duration_minutes'] as num?)?.toInt(),
      minDurationMinutes: (json['min_duration_minutes'] as num?)?.toInt(),
      maxDurationMinutes: (json['max_duration_minutes'] as num?)?.toInt(),
      durationStepMinutes: (json['duration_step_minutes'] as num?)?.toInt() ?? 60,
      bufferBeforeMinutes: (json['buffer_before_minutes'] as num?)?.toInt() ?? 0,
      bufferAfterMinutes: (json['buffer_after_minutes'] as num?)?.toInt() ?? 0,
      sessions: (json['sessions'] is List)
              ? (json['sessions'] as List)
                  .map((e) => ServiceSession.fromJson(Map<String, dynamic>.from(e as Map)))
                  .toList()
              : [],
      allowMultiDay: json['allow_multi_day'] ?? false,
      maxDays: json['max_days'] as int?,
      startTime: json['start_time']?.toString(),
      endTime: json['end_time']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'service_id': serviceId,
      'time_type': timeType.name,
      'slot_duration_minutes': slotDurationMinutes,
      'min_duration_minutes': minDurationMinutes,
      'max_duration_minutes': maxDurationMinutes,
      'duration_step_minutes': durationStepMinutes,
      'buffer_before_minutes': bufferBeforeMinutes,
      'buffer_after_minutes': bufferAfterMinutes,
      'sessions': sessions.map((e) => e.toJson()).toList(),
      'allow_multi_day': allowMultiDay,
      'max_days': maxDays,
      'start_time': startTime,
      'end_time': endTime,
    };
  }

  ServiceTimeRule copyWith({
    String? id,
    String? serviceId,
    TimeType? timeType,
    int? slotDurationMinutes,
    int? minDurationMinutes,
    int? maxDurationMinutes,
    int? durationStepMinutes,
    int? bufferBeforeMinutes,
    int? bufferAfterMinutes,
    List<ServiceSession>? sessions,
    bool? allowMultiDay,
    int? maxDays,
    String? startTime,
    String? endTime,
  }) {
    return ServiceTimeRule(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      timeType: timeType ?? this.timeType,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      minDurationMinutes: minDurationMinutes ?? this.minDurationMinutes,
      maxDurationMinutes: maxDurationMinutes ?? this.maxDurationMinutes,
      durationStepMinutes: durationStepMinutes ?? this.durationStepMinutes,
      bufferBeforeMinutes: bufferBeforeMinutes ?? this.bufferBeforeMinutes,
      bufferAfterMinutes: bufferAfterMinutes ?? this.bufferAfterMinutes,
      sessions: sessions ?? this.sessions,
      allowMultiDay: allowMultiDay ?? this.allowMultiDay,
      maxDays: maxDays ?? this.maxDays,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        serviceId,
        timeType,
        slotDurationMinutes,
        minDurationMinutes,
        maxDurationMinutes,
        durationStepMinutes,
        bufferBeforeMinutes,
        bufferAfterMinutes,
        sessions,
        allowMultiDay,
        maxDays,
        startTime,
        endTime,
      ];

  double get totalHours {
    if (startTime == null || endTime == null) return 0;
    try {
      final startParts = startTime!.split(':');
      final endParts = endTime!.split(':');
      final start = DateTime(2000, 1, 1, int.parse(startParts[0]), int.parse(startParts[1]));
      final end = DateTime(2000, 1, 1, int.parse(endParts[0]), int.parse(endParts[1]));
      
      var diff = end.difference(start).inMinutes;
      if (diff < 0) diff += 24 * 60; // Handle overnight
      
      return diff / 60.0;
    } catch (_) {
      return 0;
    }
  }
}
