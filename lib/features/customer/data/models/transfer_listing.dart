import 'package:intl/intl.dart';

enum TransferApprovalStatus {
  pending,
  approved,
  rejected
}

enum TransferListingStatus {
  active,
  pendingApproval,
  sold,
  expired
}

class TransferListing {
  final String id;
  final String customerId;
  final String? vendorId;
  final String? bookingId;
  final String category;
  final String vendorName;
  final DateTime eventDate;
  final double originalBookingPrice;
  final double sellingPrice;
  final String packageDescription;
  final List<String> images;
  final String? reason;
  final String? proofUrl;
  final TransferApprovalStatus transferApprovalStatus;
  final TransferListingStatus listingStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransferListing({
    required this.id,
    required this.customerId,
    this.vendorId,
    this.bookingId,
    required this.category,
    required this.vendorName,
    required this.eventDate,
    required this.originalBookingPrice,
    required this.sellingPrice,
    required this.packageDescription,
    required this.images,
    this.reason,
    this.proofUrl,
    required this.transferApprovalStatus,
    required this.listingStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransferListing.fromMap(Map<String, dynamic> map) {
    return TransferListing(
      id: map['id'] ?? '',
      customerId: map['customer_id'] ?? '',
      vendorId: map['vendor_id'],
      bookingId: map['booking_id'],
      category: map['category'] ?? '',
      vendorName: map['vendor_name'] ?? '',
      eventDate: map['event_date'] != null 
          ? DateTime.tryParse(map['event_date']) ?? DateTime.now() 
          : DateTime.now(),
      originalBookingPrice: (map['original_booking_price'] ?? 0.0).toDouble(),
      sellingPrice: (map['selling_price'] ?? 0.0).toDouble(),
      packageDescription: map['package_description'] ?? '',
      images: map['images'] is List 
          ? List<String>.from(map['images']) 
          : [],
      reason: map['reason'],
      proofUrl: map['proof_url'],
      transferApprovalStatus: _parseApprovalStatus(map['transfer_approval_status']),
      listingStatus: _parseListingStatus(map['listing_status']),
      createdAt: map['created_at'] != null 
          ? DateTime.tryParse(map['created_at']) ?? DateTime.now() 
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.tryParse(map['updated_at']) ?? DateTime.now() 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id.isEmpty ? null : id,
      'customer_id': customerId,
      'vendor_id': vendorId,
      'booking_id': bookingId,
      'category': category,
      'vendor_name': vendorName,
      'event_date': DateFormat('yyyy-MM-dd').format(eventDate),
      'original_booking_price': originalBookingPrice,
      'selling_price': sellingPrice,
      'package_description': packageDescription,
      'images': images,
      'reason': reason,
      'proof_url': proofUrl,
      'transfer_approval_status': transferApprovalStatus.name,
      'listing_status': listingStatus.name == 'pendingApproval' ? 'pending_approval' : listingStatus.name,
    };
  }

  static TransferApprovalStatus _parseApprovalStatus(String? status) {
    switch (status) {
      case 'approved':
        return TransferApprovalStatus.approved;
      case 'rejected':
        return TransferApprovalStatus.rejected;
      default:
        return TransferApprovalStatus.pending;
    }
  }

  static TransferListingStatus _parseListingStatus(String? status) {
    switch (status) {
      case 'active':
        return TransferListingStatus.active;
      case 'sold':
        return TransferListingStatus.sold;
      case 'expired':
        return TransferListingStatus.expired;
      case 'pending_approval':
      default:
        return TransferListingStatus.pendingApproval;
    }
  }
}
