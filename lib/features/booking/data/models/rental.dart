enum RentalStatus {
  available,
  reserved,
  rented,
  maintenance,
  damaged
}

class RentalItem {
  final String id;
  final String vendorId;
  final String name;
  final String description;
  final String category;
  final List<String> images;
  final Map<String, List<String>> sizes; // e.g., {'dress': ['S', 'M', 'L'], 'shoes': ['7', '8', '9']}
  final double dailyRate;
  final double weeklyRate;
  final double deposit;
  final RentalStatus status;
  final DateTime? reservedUntil;
  final DateTime? rentedUntil;
  final String? currentRentalId;
  final List<String> tags;
  final Map<String, dynamic> specifications;
  final DateTime createdAt;
  final DateTime updatedAt;

  RentalItem({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.description,
    required this.category,
    required this.images,
    required this.sizes,
    required this.dailyRate,
    required this.weeklyRate,
    required this.deposit,
    required this.status,
    this.reservedUntil,
    this.rentedUntil,
    this.currentRentalId,
    required this.tags,
    required this.specifications,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RentalItem.fromMap(Map<String, dynamic> map, String id) {
    return RentalItem(
      id: id,
      vendorId: map['vendorId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      images: List<String>.from(map['images'] ?? []),
      sizes: Map<String, List<String>>.from(map['sizes'] ?? {}),
      dailyRate: (map['dailyRate'] ?? 0.0).toDouble(),
      weeklyRate: (map['weeklyRate'] ?? 0.0).toDouble(),
      deposit: (map['deposit'] ?? 0.0).toDouble(),
      status: RentalStatus.values.firstWhere(
        (e) => e.toString() == 'RentalStatus.${map['status']}',
        orElse: () => RentalStatus.available,
      ),
      reservedUntil: map['reservedUntil'] != null 
          ? DateTime.parse(map['reservedUntil']) 
          : null,
      rentedUntil: map['rentedUntil'] != null 
          ? DateTime.parse(map['rentedUntil']) 
          : null,
      currentRentalId: map['currentRentalId'],
      tags: List<String>.from(map['tags'] ?? []),
      specifications: Map<String, dynamic>.from(map['specifications'] ?? {}),
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'name': name,
      'description': description,
      'category': category,
      'images': images,
      'sizes': sizes,
      'dailyRate': dailyRate,
      'weeklyRate': weeklyRate,
      'deposit': deposit,
      'status': status.toString().split('.').last,
      'reservedUntil': reservedUntil?.toIso8601String(),
      'rentedUntil': rentedUntil?.toIso8601String(),
      'currentRentalId': currentRentalId,
      'tags': tags,
      'specifications': specifications,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isAvailable => status == RentalStatus.available;
  bool get isReserved => status == RentalStatus.reserved;
  bool get isRented => status == RentalStatus.rented;

  RentalItem copyWith({
    String? id,
    String? vendorId,
    String? name,
    String? description,
    String? category,
    List<String>? images,
    Map<String, List<String>>? sizes,
    double? dailyRate,
    double? weeklyRate,
    double? deposit,
    RentalStatus? status,
    DateTime? reservedUntil,
    DateTime? rentedUntil,
    String? currentRentalId,
    List<String>? tags,
    Map<String, dynamic>? specifications,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RentalItem(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      images: images ?? this.images,
      sizes: sizes ?? this.sizes,
      dailyRate: dailyRate ?? this.dailyRate,
      weeklyRate: weeklyRate ?? this.weeklyRate,
      deposit: deposit ?? this.deposit,
      status: status ?? this.status,
      reservedUntil: reservedUntil ?? this.reservedUntil,
      rentedUntil: rentedUntil ?? this.rentedUntil,
      currentRentalId: currentRentalId ?? this.currentRentalId,
      tags: tags ?? this.tags,
      specifications: specifications ?? this.specifications,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class RentalBooking {
  final String id;
  final String customerId;
  final String rentalItemId;
  final String vendorId;
  final String? eventId;
  final DateTime pickupDate;
  final DateTime returnDate;
  final Map<String, String> selectedSizes; // e.g., {'dress': 'M', 'shoes': '8'}
  final double totalCost;
  final double deposit;
  final bool depositPaid;
  final bool isCompleted;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  RentalBooking({
    required this.id,
    required this.customerId,
    required this.rentalItemId,
    required this.vendorId,
    this.eventId,
    required this.pickupDate,
    required this.returnDate,
    required this.selectedSizes,
    required this.totalCost,
    required this.deposit,
    required this.depositPaid,
    required this.isCompleted,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RentalBooking.fromMap(Map<String, dynamic> map, String id) {
    return RentalBooking(
      id: id,
      customerId: map['customerId'] ?? '',
      rentalItemId: map['rentalItemId'] ?? '',
      vendorId: map['vendorId'] ?? '',
      eventId: map['eventId'],
      pickupDate: DateTime.parse(map['pickupDate']),
      returnDate: DateTime.parse(map['returnDate']),
      selectedSizes: Map<String, String>.from(map['selectedSizes'] ?? {}),
      totalCost: (map['totalCost'] ?? 0.0).toDouble(),
      deposit: (map['deposit'] ?? 0.0).toDouble(),
      depositPaid: map['depositPaid'] ?? false,
      isCompleted: map['isCompleted'] ?? false,
      notes: map['notes'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'rentalItemId': rentalItemId,
      'vendorId': vendorId,
      'eventId': eventId,
      'pickupDate': pickupDate.toIso8601String(),
      'returnDate': returnDate.toIso8601String(),
      'selectedSizes': selectedSizes,
      'totalCost': totalCost,
      'deposit': deposit,
      'depositPaid': depositPaid,
      'isCompleted': isCompleted,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  int get rentalDays => returnDate.difference(pickupDate).inDays + 1;
  double get totalWithDeposit => totalCost + deposit;
}
