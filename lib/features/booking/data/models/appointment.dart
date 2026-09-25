// Version: 1.0.1 - Fixing Null-Safety
enum AppointmentType {
  foodTasting,
  fitting,
  siteVisit,
  trial,
  consultation,
  pickup,
  delivery,
  returnItem
}

enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  noShow
}

class Appointment {
  final String id;
  final String vendorId;
  final String customerId;
  final String serviceId;
  final String? eventId;
  final AppointmentType type;
  final DateTime scheduledDate;
  final Duration? duration;
  final String location;
  final String notes;
  final AppointmentStatus status;
  final double? cost;
  final bool isPaid;
  final bool reminder;
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // Additional display fields
  final String? customerName;
  final String? customerEmail;
  final String? vendorName;
  final String? serviceName;
  
  // Chat integration
  final String? chatMessageId;
  final String source; // 'manual', 'chat', 'booking'

  Appointment({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.serviceId,
    this.eventId,
    required this.type,
    required this.scheduledDate,
    this.duration,
    required this.location,
    required this.notes,
    required this.status,
    this.cost,
    required this.isPaid,
    required this.reminder,
    required this.createdAt,
    this.updatedAt,
    this.customerName,
    this.customerEmail,
    this.vendorName,
    this.serviceName,
    this.chatMessageId,
    this.source = 'manual',
  });

  // From Supabase (snake_case)
  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] ?? '',
      vendorId: json['vendor_id'] ?? '',
      customerId: json['customer_id'] ?? '',
      serviceId: json['service_id'] ?? '',
      eventId: json['event_id'],
      type: AppointmentType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => AppointmentType.consultation,
      ),
      scheduledDate: DateTime.parse(json['scheduled_date']),
      duration: json['duration_minutes'] != null ? Duration(minutes: json['duration_minutes']) : null,
      location: json['location'] ?? '',
      notes: json['notes'] ?? '',
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AppointmentStatus.pending,
      ),
      cost: json['cost']?.toDouble(),
      isPaid: json['is_paid'] ?? false,
      reminder: json['reminder'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      vendorName: json['vendor_name'],
      serviceName: json['service_name'],
      chatMessageId: json['chat_message_id'],
      source: json['source'] ?? 'manual',
    );
  }

  // Legacy fromMap for backward compatibility
  factory Appointment.fromMap(Map<String, dynamic> map, String id) {
    return Appointment(
      id: id,
      vendorId: map['vendorId'] ?? '',
      customerId: map['customerId'] ?? '',
      serviceId: map['serviceId'] ?? '',
      eventId: map['eventId'],
      type: AppointmentType.values.firstWhere(
        (e) => e.toString() == 'AppointmentType.${map['type']}',
        orElse: () => AppointmentType.consultation,
      ),
      scheduledDate: DateTime.parse(map['scheduledDate']),
      duration: map['durationMinutes'] != null ? Duration(minutes: map['durationMinutes']) : null,
      location: map['location'] ?? '',
      notes: map['notes'] ?? '',
      status: AppointmentStatus.values.firstWhere(
        (e) => e.toString() == 'AppointmentStatus.${map['status']}',
        orElse: () => AppointmentStatus.pending,
      ),
      cost: map['cost']?.toDouble(),
      isPaid: map['isPaid'] ?? false,
      reminder: map['reminder'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  // To Supabase (snake_case)
  Map<String, dynamic> toJson() {
    return {
      'vendor_id': vendorId,
      'customer_id': customerId,
      if (serviceId.isNotEmpty && serviceId != 'null') 'service_id': serviceId,
      'event_id': eventId,
      'type': type.toString().split('.').last,
      'scheduled_date': scheduledDate.toIso8601String(),
      'duration_minutes': duration?.inMinutes,
      'location': location,
      'notes': notes,
      'status': status.toString().split('.').last,
      'cost': cost,
      'is_paid': isPaid,
      'reminder': reminder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'customer_name': customerName,
      'customer_email': customerEmail,
      'vendor_name': vendorName,
      'service_name': serviceName,
      'chat_message_id': chatMessageId,
      'source': source,
    };
  }

  // Legacy toMap for backward compatibility
  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'customerId': customerId,
      if (serviceId.isNotEmpty && serviceId != 'null') 'serviceId': serviceId,
      'eventId': eventId,
      'type': type.toString().split('.').last,
      'scheduledDate': scheduledDate.toIso8601String(),
      'durationMinutes': duration?.inMinutes,
      'location': location,
      'notes': notes,
      'status': status.toString().split('.').last,
      'cost': cost,
      'isPaid': isPaid,
      'reminder': reminder,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Appointment copyWith({
    String? id,
    String? vendorId,
    String? customerId,
    String? serviceId,
    String? eventId,
    AppointmentType? type,
    DateTime? scheduledDate,
    Duration? duration,
    String? location,
    String? notes,
    AppointmentStatus? status,
    double? cost,
    bool? isPaid,
    bool? reminder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? customerName,
    String? customerEmail,
    String? vendorName,
    String? serviceName,
    String? chatMessageId,
    String? source,
  }) {
    return Appointment(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      customerId: customerId ?? this.customerId,
      serviceId: serviceId ?? this.serviceId,
      eventId: eventId ?? this.eventId,
      type: type ?? this.type,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      cost: cost ?? this.cost,
      isPaid: isPaid ?? this.isPaid,
      reminder: reminder ?? this.reminder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      vendorName: vendorName ?? this.vendorName,
      serviceName: serviceName ?? this.serviceName,
      chatMessageId: chatMessageId ?? this.chatMessageId,
      source: source ?? this.source,
    );
  }
}
