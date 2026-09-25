import 'package:eventease/shared/models/event/event_category.dart';

enum RequestStatus {
  pending('pending', 'Pending'),
  offered('offered', 'Offered'),
  accepted('accepted', 'Accepted'),
  rejected('rejected', 'Rejected'),
  completed('completed', 'Completed');

  const RequestStatus(this.id, this.displayName);

  final String id;
  final String displayName;
}

class CustomerRequest {
  final String id;
  final String customerId;
  final String customerName;
  final EventCategory eventCategory;
  final String eventType; // e.g., Wedding, Birthday
  final DateTime eventDate;
  final double budget;
  final String description;
  final String location;
  final int guestCount;
  final String? guestCountRange;
  final String? contactPhone;
  final String? contactEmail;
  final RequestStatus status;
  final DateTime createdAt;
  final List<RequestOffer> offers;

  CustomerRequest({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.eventCategory,
    required this.eventType,
    required this.eventDate,
    required this.budget,
    required this.description,
    required this.location,
    required this.guestCount,
    this.guestCountRange,
    this.contactPhone,
    this.contactEmail,
    required this.status,
    required this.createdAt,
    required this.offers,
  });

  factory CustomerRequest.fromJson(Map<String, dynamic> json) {
    return CustomerRequest(
      id: json['id'],
      customerId: json['customer_id'] ?? json['customerId'],
      customerName: json['customer_name'] ?? json['customerName'],
      eventCategory: EventCategory.values.firstWhere(
        (e) => e.id == json['event_category'] ?? json['eventCategory'],
      ),
      eventType: json['event_type'] ?? json['eventType'],
      eventDate: DateTime.parse(json['event_date'] ?? json['eventDate']),
      budget: (json['budget'] ?? 0).toDouble(),
      description: json['description'],
      location: json['location'],
      guestCount: json['guest_count'] ?? json['guestCount'] ?? 0,
      guestCountRange: json['guest_count_range'] ?? json['guestCountRange'],
      contactPhone: json['contact_phone'] ?? json['contactPhone'],
      contactEmail: json['contact_email'] ?? json['contactEmail'],
      status: RequestStatus.values.firstWhere(
        (e) => e.id == json['status'],
        orElse: () => RequestStatus.pending,
      ),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      offers: (json['offers'] as List<dynamic>?)
              ?.map((e) => RequestOffer.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'event_category': eventCategory.id,
      'event_type': eventType,
      'event_date': eventDate.toIso8601String(),
      'budget': budget,
      'description': description,
      'location': location,
      'guest_count': guestCount,
      'guest_count_range': guestCountRange,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'status': status.id,
      'created_at': createdAt.toIso8601String(),
      'offers': offers.map((e) => e.toJson()).toList(),
    };
  }

  CustomerRequest copyWith({
    String? id,
    String? customerId,
    String? customerName,
    EventCategory? eventCategory,
    String? eventType,
    DateTime? eventDate,
    double? budget,
    String? description,
    String? location,
    int? guestCount,
    String? guestCountRange,
    String? contactPhone,
    String? contactEmail,
    RequestStatus? status,
    DateTime? createdAt,
    List<RequestOffer>? offers,
  }) {
    return CustomerRequest(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      eventCategory: eventCategory ?? this.eventCategory,
      eventType: eventType ?? this.eventType,
      eventDate: eventDate ?? this.eventDate,
      budget: budget ?? this.budget,
      description: description ?? this.description,
      location: location ?? this.location,
      guestCount: guestCount ?? this.guestCount,
      guestCountRange: guestCountRange ?? this.guestCountRange,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      offers: offers ?? this.offers,
    );
  }

  // Sample data
  static List<CustomerRequest> getSampleRequests() {
    return [
      CustomerRequest(
        id: '1',
        customerId: 'customer1',
        customerName: 'Alice Johnson',
        eventCategory: EventCategory.catering,
        eventType: 'Wedding Reception',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        budget: 5000.0,
        description: 'Looking for catering services for a wedding reception with 100 guests. Need buffet style with vegetarian options.',
        location: 'Grand Ballroom, Kuala Lumpur',
        guestCount: 100,
        status: RequestStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        offers: [],
      ),
      CustomerRequest(
        id: '2',
        customerId: 'customer2',
        customerName: 'Bob Smith',
        eventCategory: EventCategory.photography,
        eventType: 'Corporate Event',
        eventDate: DateTime.now().add(const Duration(days: 15)),
        budget: 2000.0,
        description: 'Need professional photography for a corporate seminar. Include group photos and presentations.',
        location: 'Convention Center, Penang',
        guestCount: 200,
        status: RequestStatus.offered,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        offers: [
          RequestOffer(
            id: 'offer1',
            vendorId: 'vendor1',
            vendorName: 'PhotoPro Studios',
            price: 1800.0,
            message: 'We can provide comprehensive photography coverage for your event.',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ],
      ),
    ];
  }
}

class RequestOffer {
  final String id;
  final String vendorId;
  final String vendorName;
  final double price;
  final String message;
  final DateTime createdAt;

  RequestOffer({
    required this.id,
    required this.vendorId,
    required this.vendorName,
    required this.price,
    required this.message,
    required this.createdAt,
  });

  factory RequestOffer.fromJson(Map<String, dynamic> json) {
    return RequestOffer(
      id: json['id'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      price: json['price'].toDouble(),
      message: json['message'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'price': price,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
