import 'package:equatable/equatable.dart';

enum AvailabilityType { general, specific_date, recurring }

class VendorAvailability extends Equatable {
  final String id;
  final String vendorId;
  final AvailabilityType availabilityType;
  final DateTime? specificDate;
  final String? recurringPattern;
  final String? startTime;
  final String? endTime;
  final bool isAvailable;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorAvailability({
    required this.id,
    required this.vendorId,
    required this.availabilityType,
    this.specificDate,
    this.recurringPattern,
    this.startTime,
    this.endTime,
    this.isAvailable = true,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VendorAvailability.fromJson(Map<String, dynamic> json) {
    return VendorAvailability(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      availabilityType: AvailabilityType.values.firstWhere(
        (type) => type.name == json['availability_type'],
        orElse: () => AvailabilityType.general,
      ),
      specificDate: json['specific_date'] != null ? DateTime.parse(json['specific_date']) : null,
      recurringPattern: json['recurring_pattern'] as String?,
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      isAvailable: json['is_available'] ?? true,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'availability_type': availabilityType.name,
      'specific_date': specificDate?.toIso8601String(),
      'recurring_pattern': recurringPattern,
      'start_time': startTime,
      'end_time': endTime,
      'is_available': isAvailable,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VendorAvailability copyWith({
    String? id,
    String? vendorId,
    AvailabilityType? availabilityType,
    DateTime? specificDate,
    String? recurringPattern,
    String? startTime,
    String? endTime,
    bool? isAvailable,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorAvailability(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      availabilityType: availabilityType ?? this.availabilityType,
      specificDate: specificDate ?? this.specificDate,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAvailable: isAvailable ?? this.isAvailable,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        availabilityType,
        specificDate,
        recurringPattern,
        startTime,
        endTime,
        isAvailable,
        notes,
        createdAt,
        updatedAt,
      ];
}
