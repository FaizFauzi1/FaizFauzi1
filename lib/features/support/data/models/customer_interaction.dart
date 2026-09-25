import 'package:eventease/features/booking/data/models/booking.dart';

enum InteractionType {
  bookingCreated,
  bookingAccepted,
  bookingRejected,
  bookingCompleted,
  bookingCancelled,
  messageSent,
  messageReceived,
  reviewSubmitted,
  favoriteAdded,
  favoriteRemoved,
  profileViewed,
  serviceViewed,
  paymentMade,
  refundRequested,
  complaintFiled,
  inquirySubmitted,
}

enum InteractionChannel {
  app,
  website,
  phone,
  email,
  chat,
  socialMedia,
}

class CustomerInteraction {
  final String id;
  final String customerId;
  final String vendorId;
  final InteractionType type;
  final InteractionChannel channel;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final bool isRead;
  final String? relatedBookingId;
  final String? relatedServiceId;

  const CustomerInteraction({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.type,
    required this.channel,
    required this.description,
    required this.metadata,
    required this.timestamp,
    this.isRead = false,
    this.relatedBookingId,
    this.relatedServiceId,
  });

  // Create from booking event
  factory CustomerInteraction.fromBookingEvent(
    String customerId,
    String vendorId,
    BookingStatus status,
    String bookingId,
    double amount,
  ) {
    InteractionType type;
    String description;

    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.pendingVendor:
        type = InteractionType.bookingCreated;
        description = 'New booking request submitted';
        break;
      case BookingStatus.awaitingPayment:
        type = InteractionType.bookingAccepted;
        description = 'Vendor confirmed availability';
        break;
      case BookingStatus.confirmed:
        type = InteractionType.bookingAccepted;
        description = 'Booking confirmed';
        break;
      case BookingStatus.rejected:
        type = InteractionType.bookingRejected;
        description = 'Booking request rejected';
        break;
      case BookingStatus.completed:
        type = InteractionType.bookingCompleted;
        description = 'Booking completed successfully';
        break;
      case BookingStatus.cancelled:
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByVendor:
        type = InteractionType.bookingCancelled;
        description = 'Booking cancelled';
        break;
      case BookingStatus.expired:
        type = InteractionType.bookingCancelled;
        description = 'Booking expired';
        break;
      case BookingStatus.inProgress:
        type = InteractionType.bookingCreated;
        description = 'Booking in progress';
        break;
      case BookingStatus.changeRequested:
        type = InteractionType.bookingCreated;
        description = 'Booking change requested';
        break;
      case BookingStatus.changeApproved:
        type = InteractionType.bookingAccepted;
        description = 'Booking change approved';
        break;
      case BookingStatus.changeRejected:
        type = InteractionType.bookingRejected;
        description = 'Booking change rejected';
        break;
      case BookingStatus.awaitingAdjustmentPayment:
        type = InteractionType.bookingAccepted;
        description = 'Awaiting payment for booking change';
        break;
    }

    return CustomerInteraction(
      id: 'int_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      vendorId: vendorId,
      type: type,
      channel: InteractionChannel.app,
      description: description,
      metadata: {
        'bookingId': bookingId,
        'amount': amount,
        'status': status.toString(),
      },
      timestamp: DateTime.now(),
      relatedBookingId: bookingId,
    );
  }

  // Create from message event
  factory CustomerInteraction.fromMessageEvent(
    String customerId,
    String vendorId,
    String messageContent,
    bool isFromCustomer,
  ) {
    return CustomerInteraction(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      vendorId: vendorId,
      type: isFromCustomer ? InteractionType.messageSent : InteractionType.messageReceived,
      channel: InteractionChannel.chat,
      description: isFromCustomer ? 'Message sent to vendor' : 'Message received from vendor',
      metadata: {
        'messagePreview': messageContent.length > 50
            ? '${messageContent.substring(0, 50)}...'
            : messageContent,
        'isFromCustomer': isFromCustomer,
      },
      timestamp: DateTime.now(),
    );
  }

  // Create from review event
  factory CustomerInteraction.fromReviewEvent(
    String customerId,
    String vendorId,
    double rating,
    String reviewText,
    String serviceId,
  ) {
    return CustomerInteraction(
      id: 'rev_${DateTime.now().millisecondsSinceEpoch}',
      customerId: customerId,
      vendorId: vendorId,
      type: InteractionType.reviewSubmitted,
      channel: InteractionChannel.app,
      description: 'Review submitted (${rating.toStringAsFixed(1)} stars)',
      metadata: {
        'rating': rating,
        'reviewText': reviewText,
        'serviceId': serviceId,
      },
      timestamp: DateTime.now(),
      relatedServiceId: serviceId,
    );
  }

  // Copy with method
  CustomerInteraction copyWith({
    String? id,
    String? customerId,
    String? vendorId,
    InteractionType? type,
    InteractionChannel? channel,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? timestamp,
    bool? isRead,
    String? relatedBookingId,
    String? relatedServiceId,
  }) {
    return CustomerInteraction(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      vendorId: vendorId ?? this.vendorId,
      type: type ?? this.type,
      channel: channel ?? this.channel,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      relatedBookingId: relatedBookingId ?? this.relatedBookingId,
      relatedServiceId: relatedServiceId ?? this.relatedServiceId,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'vendorId': vendorId,
      'type': type.toString(),
      'channel': channel.toString(),
      'description': description,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'relatedBookingId': relatedBookingId,
      'relatedServiceId': relatedServiceId,
    };
  }

  // Create from JSON
  factory CustomerInteraction.fromJson(Map<String, dynamic> json) {
    return CustomerInteraction(
      id: json['id'],
      customerId: json['customerId'],
      vendorId: json['vendorId'],
      type: InteractionType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => InteractionType.bookingCreated,
      ),
      channel: InteractionChannel.values.firstWhere(
        (e) => e.toString() == json['channel'],
        orElse: () => InteractionChannel.app,
      ),
      description: json['description'],
      metadata: json['metadata'] ?? {},
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      relatedBookingId: json['relatedBookingId'],
      relatedServiceId: json['relatedServiceId'],
    );
  }

  // Get display icon for interaction type
  String getIcon() {
    switch (type) {
      case InteractionType.bookingCreated:
      case InteractionType.bookingAccepted:
      case InteractionType.bookingRejected:
      case InteractionType.bookingCompleted:
      case InteractionType.bookingCancelled:
        return 'event';
      case InteractionType.messageSent:
      case InteractionType.messageReceived:
        return 'chat';
      case InteractionType.reviewSubmitted:
        return 'star';
      case InteractionType.favoriteAdded:
      case InteractionType.favoriteRemoved:
        return 'favorite';
      case InteractionType.profileViewed:
      case InteractionType.serviceViewed:
        return 'visibility';
      case InteractionType.paymentMade:
        return 'payment';
      case InteractionType.refundRequested:
        return 'undo';
      case InteractionType.complaintFiled:
        return 'report';
      case InteractionType.inquirySubmitted:
        return 'help';
      default:
        return 'info';
    }
  }

  // Get color for interaction type
  String getColor() {
    switch (type) {
      case InteractionType.bookingCreated:
        return 'blue';
      case InteractionType.bookingAccepted:
        return 'green';
      case InteractionType.bookingRejected:
      case InteractionType.bookingCancelled:
        return 'red';
      case InteractionType.bookingCompleted:
        return 'purple';
      case InteractionType.messageSent:
      case InteractionType.messageReceived:
        return 'orange';
      case InteractionType.reviewSubmitted:
        return 'amber';
      case InteractionType.favoriteAdded:
        return 'pink';
      case InteractionType.favoriteRemoved:
        return 'grey';
      case InteractionType.profileViewed:
      case InteractionType.serviceViewed:
        return 'teal';
      case InteractionType.paymentMade:
        return 'green';
      case InteractionType.refundRequested:
        return 'orange';
      case InteractionType.complaintFiled:
        return 'red';
      case InteractionType.inquirySubmitted:
        return 'blue';
      default:
        return 'grey';
    }
  }
}
