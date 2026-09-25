import 'package:equatable/equatable.dart';

enum DeviceType { ios, android, web }

class UserDeviceTokens extends Equatable {
  final String id;
  final String userId;
  final String deviceToken;
  final DeviceType deviceType;
  final String? deviceModel;
  final String? appVersion;
  final bool isActive;
  final DateTime lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserDeviceTokens({
    required this.id,
    required this.userId,
    required this.deviceToken,
    required this.deviceType,
    this.deviceModel,
    this.appVersion,
    this.isActive = true,
    required this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDeviceTokens.fromJson(Map<String, dynamic> json) {
    return UserDeviceTokens(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      deviceToken: json['device_token'] as String,
      deviceType: DeviceType.values.firstWhere(
        (type) => type.name == json['device_type'],
        orElse: () => DeviceType.android,
      ),
      deviceModel: json['device_model'] as String?,
      appVersion: json['app_version'] as String?,
      isActive: json['is_active'] ?? true,
      lastUsedAt: DateTime.parse(json['last_used_at']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_token': deviceToken,
      'device_type': deviceType.name,
      'device_model': deviceModel,
      'app_version': appVersion,
      'is_active': isActive,
      'last_used_at': lastUsedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserDeviceTokens copyWith({
    String? id,
    String? userId,
    String? deviceToken,
    DeviceType? deviceType,
    String? deviceModel,
    String? appVersion,
    bool? isActive,
    DateTime? lastUsedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserDeviceTokens(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deviceToken: deviceToken ?? this.deviceToken,
      deviceType: deviceType ?? this.deviceType,
      deviceModel: deviceModel ?? this.deviceModel,
      appVersion: appVersion ?? this.appVersion,
      isActive: isActive ?? this.isActive,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        deviceToken,
        deviceType,
        deviceModel,
        appVersion,
        isActive,
        lastUsedAt,
        createdAt,
        updatedAt,
      ];
}
