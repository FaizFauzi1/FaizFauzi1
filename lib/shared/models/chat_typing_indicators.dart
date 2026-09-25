import 'package:equatable/equatable.dart';

class ChatTypingIndicators extends Equatable {
  final String id;
  final String conversationId;
  final String userId;
  final bool isTyping;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatTypingIndicators({
    required this.id,
    required this.conversationId,
    required this.userId,
    this.isTyping = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatTypingIndicators.fromJson(Map<String, dynamic> json) {
    return ChatTypingIndicators(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      isTyping: json['is_typing'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'user_id': userId,
      'is_typing': isTyping,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatTypingIndicators copyWith({
    String? id,
    String? conversationId,
    String? userId,
    bool? isTyping,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatTypingIndicators(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      isTyping: isTyping ?? this.isTyping,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        userId,
        isTyping,
        createdAt,
        updatedAt,
      ];
}
