import 'package:equatable/equatable.dart';

class ChatGroupMembers extends Equatable {
  final String id;
  final String groupId;
  final String userId;
  final String role;
  final bool isActive;
  final DateTime joinedAt;
  final DateTime? leftAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatGroupMembers({
    required this.id,
    required this.groupId,
    required this.userId,
    this.role = 'member',
    this.isActive = true,
    required this.joinedAt,
    this.leftAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatGroupMembers.fromJson(Map<String, dynamic> json) {
    return ChatGroupMembers(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] ?? 'member',
      isActive: json['is_active'] ?? true,
      joinedAt: DateTime.parse(json['joined_at']),
      leftAt: json['left_at'] != null ? DateTime.parse(json['left_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'group_id': groupId,
      'user_id': userId,
      'role': role,
      'is_active': isActive,
      'joined_at': joinedAt.toIso8601String(),
      'left_at': leftAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatGroupMembers copyWith({
    String? id,
    String? groupId,
    String? userId,
    String? role,
    bool? isActive,
    DateTime? joinedAt,
    DateTime? leftAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatGroupMembers(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      joinedAt: joinedAt ?? this.joinedAt,
      leftAt: leftAt ?? this.leftAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        groupId,
        userId,
        role,
        isActive,
        joinedAt,
        leftAt,
        createdAt,
        updatedAt,
      ];
}
