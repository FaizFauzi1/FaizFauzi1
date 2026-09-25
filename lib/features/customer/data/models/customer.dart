import 'package:eventease/features/booking/data/models/booking.dart';

enum CustomerSegment {
  newCustomer,
  regularCustomer,
  vipCustomer,
  inactiveCustomer,
}

enum CustomerStatus {
  active,
  inactive,
  blocked,
}

class Customer {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final String? profileImage;
  final DateTime createdAt;
  final DateTime lastActive;
  final CustomerStatus status;
  final CustomerSegment segment;
  final Map<String, dynamic> preferences;
  final List<String> favoriteCategories;
  final double totalSpent;
  final int totalBookings;
  final double averageRating;
  final int reviewCount;
  final Map<String, dynamic> analytics;
  final bool isPremium;
  final String subscriptionTier; // 'free', 'silver', 'gold'
  final DateTime? subscriptionExpiry;
  final DateTime? birthday;

  const Customer({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    this.profileImage,
    required this.createdAt,
    required this.lastActive,
    required this.status,
    required this.segment,
    required this.preferences,
    required this.favoriteCategories,
    required this.totalSpent,
    required this.totalBookings,
    required this.averageRating,
    required this.reviewCount,
    required this.analytics,
    this.isPremium = false,
    this.subscriptionTier = 'free',
    this.subscriptionExpiry,
    this.birthday,
  });

  // Create from booking data
  factory Customer.fromBookingData(String customerEmail, List<Booking> bookings) {
    final customerBookings = bookings.where((b) => b.customerEmail == customerEmail).toList();

    double totalSpent = 0;
    double totalRating = 0;
    int ratingCount = 0;

    for (final booking in customerBookings) {
      // Calculate spending using amount property
      totalSpent += booking.amount;

      // For now, we'll simulate ratings since they're not in the Booking model
      // In a real app, ratings would be stored separately or added to Booking model
      if (booking.status == BookingStatus.completed) {
        // Simulate ratings for completed bookings (4.0 to 5.0 range)
        final simulatedRating = 4.0 + (customerEmail.hashCode % 10) / 10.0;
        totalRating += simulatedRating;
        ratingCount++;
      }
    }

    final averageRating = ratingCount > 0 ? totalRating / ratingCount : 0.0;

    // Determine customer segment based on spending and booking count
    CustomerSegment segment;
    if (totalSpent >= 5000) {
      segment = CustomerSegment.vipCustomer;
    } else if (customerBookings.length >= 5) {
      segment = CustomerSegment.regularCustomer;
    } else if (customerBookings.isNotEmpty) {
      segment = CustomerSegment.newCustomer;
    } else {
      segment = CustomerSegment.inactiveCustomer;
    }

    // Premium status based on segment
    final isPremium = segment == CustomerSegment.vipCustomer;

    return Customer(
      id: customerEmail,
      email: customerEmail,
      name: customerEmail.split('@').first, // Placeholder name
      phone: null,
      profileImage: null,
      createdAt: customerBookings.isNotEmpty
          ? customerBookings.map((b) => b.createdAt).reduce((a, b) => a.isBefore(b) ? a : b)
          : DateTime.now(),
      lastActive: customerBookings.isNotEmpty
          ? customerBookings.map((b) => b.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b)
          : DateTime.now(),
      status: CustomerStatus.active,
      segment: segment,
      preferences: {},
      favoriteCategories: [], // Would need to be calculated from booking data
      totalSpent: totalSpent,
      totalBookings: customerBookings.length,
      averageRating: averageRating,
      reviewCount: ratingCount,
      analytics: {
        'bookingFrequency': customerBookings.length,
        'averageOrderValue': customerBookings.isNotEmpty ? totalSpent / customerBookings.length : 0,
        'lastBookingDate': customerBookings.isNotEmpty
            ? customerBookings.map((b) => b.createdAt).reduce((a, b) => a.isAfter(b) ? a : b).toIso8601String()
            : null,
        'preferredServices': [], // Would need to be calculated
      },
      isPremium: isPremium,
      subscriptionTier: isPremium ? 'gold' : 'free', // Default logic based on premium status
      subscriptionExpiry: null,
      birthday: null,
    );
  }

  // Copy with method for updates
  Customer copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? profileImage,
    DateTime? createdAt,
    DateTime? lastActive,
    CustomerStatus? status,
    CustomerSegment? segment,
    Map<String, dynamic>? preferences,
    List<String>? favoriteCategories,
    double? totalSpent,
    int? totalBookings,
    double? averageRating,
    int? reviewCount,
    Map<String, dynamic>? analytics,
    bool? isPremium,
    String? subscriptionTier,
    DateTime? subscriptionExpiry,
    DateTime? birthday,
  }) {
    return Customer(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      status: status ?? this.status,
      segment: segment ?? this.segment,
      preferences: preferences ?? this.preferences,
      favoriteCategories: favoriteCategories ?? this.favoriteCategories,
      totalSpent: totalSpent ?? this.totalSpent,
      totalBookings: totalBookings ?? this.totalBookings,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      analytics: analytics ?? this.analytics,
      isPremium: isPremium ?? this.isPremium,
      subscriptionTier: subscriptionTier ?? this.subscriptionTier,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      birthday: birthday ?? this.birthday,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'createdAt': createdAt.toIso8601String(),
      'lastActive': lastActive.toIso8601String(),
      'status': status.toString(),
      'segment': segment.toString(),
      'preferences': preferences,
      'favoriteCategories': favoriteCategories,
      'totalSpent': totalSpent,
      'totalBookings': totalBookings,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'analytics': analytics,
      'isPremium': isPremium,
      'subscriptionTier': subscriptionTier,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      'birthday': birthday?.toIso8601String(),
    };
  }

  // Create from JSON
  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      phone: json['phone'],
      profileImage: json['profileImage'],
      createdAt: DateTime.parse(json['createdAt']),
      lastActive: DateTime.parse(json['lastActive']),
      status: CustomerStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => CustomerStatus.active,
      ),
      segment: CustomerSegment.values.firstWhere(
        (e) => e.toString() == json['segment'],
        orElse: () => CustomerSegment.newCustomer,
      ),
      preferences: json['preferences'] ?? {},
      favoriteCategories: List<String>.from(json['favoriteCategories'] ?? []),
      totalSpent: json['totalSpent'] ?? 0.0,
      totalBookings: json['totalBookings'] ?? 0,
      averageRating: json['averageRating'] ?? 0.0,
      reviewCount: json['reviewCount'] ?? 0,
      analytics: json['analytics'] ?? {},
      isPremium: json['isPremium'] ?? false,
      subscriptionTier: json['subscriptionTier'] ?? 'free',
      subscriptionExpiry: json['subscriptionExpiry'] != null ? DateTime.parse(json['subscriptionExpiry']) : null,
      birthday: json['birthday'] != null ? DateTime.parse(json['birthday']) : null,
    );
  }
}
