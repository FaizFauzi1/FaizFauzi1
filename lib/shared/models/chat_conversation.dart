import 'package:equatable/equatable.dart';

enum ConversationType { direct, group }
enum ConversationStatus { active, archived, blocked }

class ChatConversation extends Equatable {
  final String id;
  final String? bookingId;
  final ConversationType conversationType;
  final String? title;
  final String? description;
  final ConversationStatus status;
  final DateTime? lastMessageAt;
  final String? lastMessagePreview;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatConversation({
    required this.id,
    this.bookingId,
    this.conversationType = ConversationType.direct,
    this.title,
    this.description,
    this.status = ConversationStatus.active,
    this.lastMessageAt,
    this.lastMessagePreview,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String?,
      conversationType: ConversationType.values.firstWhere(
        (type) => type.name == json['conversation_type'],
        orElse: () => ConversationType.direct,
      ),
      title: json['title'] as String?,
      description: json['description'] as String?,
      status: ConversationStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => ConversationStatus.active,
      ),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      lastMessagePreview: json['last_message_preview'] as String?,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'conversation_type': conversationType.name,
      'title': title,
      'description': description,
      'status': status.name,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_preview': lastMessagePreview,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatConversation copyWith({
    String? id,
    String? bookingId,
    ConversationType? conversationType,
    String? title,
    String? description,
    ConversationStatus? status,
    DateTime? lastMessageAt,
    String? lastMessagePreview,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      conversationType: conversationType ?? this.conversationType,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        bookingId,
        conversationType,
        title,
        description,
        status,
        lastMessageAt,
        lastMessagePreview,
        metadata,
        createdAt,
        updatedAt,
      ];
}
