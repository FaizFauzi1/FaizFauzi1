import 'package:equatable/equatable.dart';

enum RoomType { hall, room, outdoor, indoor }

class VenueRoom extends Equatable {
  final String id;
  final String vendorId;
  final String roomName;
  final RoomType roomType;
  final int capacity;
  final double? sizeSqm;
  final String? description;
  final double? basePrice;
  final List<String> images;
  final List<String> amenities;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VenueRoom({
    required this.id,
    required this.vendorId,
    required this.roomName,
    required this.roomType,
    required this.capacity,
    this.sizeSqm,
    this.description,
    this.basePrice,
    this.images = const [],
    this.amenities = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VenueRoom.fromJson(Map<String, dynamic> json) {
    return VenueRoom(
      id: json['id'] as String,
      vendorId: json['vendor_id'] as String,
      roomName: json['room_name'] as String,
      roomType: RoomType.values.firstWhere(
        (type) => type.name == json['room_type'],
        orElse: () => RoomType.room,
      ),
      capacity: json['capacity'] as int,
      sizeSqm: json['size_sqm'] != null ? (json['size_sqm'] as num).toDouble() : null,
      description: json['description'] as String?,
      basePrice: json['base_price'] != null ? (json['base_price'] as num).toDouble() : null,
      images: List<String>.from(json['images'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendor_id': vendorId,
      'room_name': roomName,
      'room_type': roomType.name,
      'capacity': capacity,
      'size_sqm': sizeSqm,
      'description': description,
      'base_price': basePrice,
      'images': images,
      'amenities': amenities,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  VenueRoom copyWith({
    String? id,
    String? vendorId,
    String? roomName,
    RoomType? roomType,
    int? capacity,
    double? sizeSqm,
    String? description,
    double? basePrice,
    List<String>? images,
    List<String>? amenities,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VenueRoom(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      roomName: roomName ?? this.roomName,
      roomType: roomType ?? this.roomType,
      capacity: capacity ?? this.capacity,
      sizeSqm: sizeSqm ?? this.sizeSqm,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      images: images ?? this.images,
      amenities: amenities ?? this.amenities,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        vendorId,
        roomName,
        roomType,
        capacity,
        sizeSqm,
        description,
        basePrice,
        images,
        amenities,
        isActive,
        createdAt,
        updatedAt,
      ];
}
