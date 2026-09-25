class CartItem {
  final String id;
  final String serviceId;
  final String title;
  final String description;
  final String price;
  final String category;
  final String vendor;
  final String? vendorId;
  final String? vendorEmail;
  final String imageUrl;
  int quantity;
  final DateTime addedAt;
  final DateTime? eventDate;
  final DateTime? readyDate;
  final DateTime? rentalEndDate;

  CartItem({
    required this.id,
    required this.serviceId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.vendor,
    this.vendorId,
    this.vendorEmail,
    required this.imageUrl,
    this.quantity = 1,
    DateTime? addedAt,
    this.eventDate,
    this.readyDate,
    this.rentalEndDate,
  }) : addedAt = addedAt ?? DateTime.now();

  // Parse price string to double (remove RM and convert)
  double get priceValue {
    final cleanPrice = price.replaceAll('RM', '').replaceAll(' ', '').trim();
    return double.tryParse(cleanPrice) ?? 0.0;
  }

  // Calculate total price for this item
  double get totalPrice => priceValue * quantity;

  // Create copy with updated quantity
  CartItem copyWith({
    int? quantity,
    DateTime? eventDate,
    DateTime? readyDate,
    DateTime? rentalEndDate,
  }) {
    return CartItem(
      id: id,
      serviceId: serviceId,
      title: title,
      description: description,
      price: price,
      category: category,
      vendor: vendor,
      vendorId: vendorId,
      vendorEmail: vendorEmail,
      imageUrl: imageUrl,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt,
      eventDate: eventDate ?? this.eventDate,
      readyDate: readyDate ?? this.readyDate,
      rentalEndDate: rentalEndDate ?? this.rentalEndDate,
    );
  }

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'serviceId': serviceId,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'vendor': vendor,
      'vendorId': vendorId,
      'vendorEmail': vendorEmail,
      'imageUrl': imageUrl,
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'eventDate': eventDate?.toIso8601String(),
      'readyDate': readyDate?.toIso8601String(),
      'rentalEndDate': rentalEndDate?.toIso8601String(),
    };
  }

  // Create from JSON
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      serviceId: json['serviceId'],
      title: json['title'],
      description: json['description'],
      price: json['price'],
      category: json['category'],
      vendor: json['vendor'],
      vendorId: json['vendorId'],
      vendorEmail: json['vendorEmail'],
      imageUrl: json['imageUrl'],
      quantity: json['quantity'] ?? 1,
      addedAt: DateTime.parse(json['addedAt']),
      eventDate: json['eventDate'] != null ? DateTime.tryParse(json['eventDate']) : null,
      readyDate: json['readyDate'] != null ? DateTime.tryParse(json['readyDate']) : null,
      rentalEndDate: json['rentalEndDate'] != null ? DateTime.tryParse(json['rentalEndDate']) : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
