import 'package:equatable/equatable.dart';

enum MessageType { text, image, file, system }
enum MessageStatus { sent, delivered, read }

class ChatMessage extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final MessageType messageType;
  final String content;
  final String? fileUrl;
  final String? fileName;
  final MessageStatus status;
  final bool isEdited;
  final DateTime? editedAt;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.messageType = MessageType.text,
    required this.content,
    this.fileUrl,
    this.fileName,
    this.status = MessageStatus.sent,
    this.isEdited = false,
    this.editedAt,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      messageType: MessageType.values.firstWhere(
        (type) => type.name == json['message_type'],
        orElse: () => MessageType.text,
      ),
      content: json['content'] as String,
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      status: MessageStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      isEdited: json['is_edited'] ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'])
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'message_type': messageType.name,
      'content': content,
      'file_url': fileUrl,
      'file_name': fileName,
      'status': status.name,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    MessageType? messageType,
    String? content,
    String? fileUrl,
    String? fileName,
    MessageStatus? status,
    bool? isEdited,
    DateTime? editedAt,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      messageType: messageType ?? this.messageType,
      content: content ?? this.content,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      status: status ?? this.status,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        messageType,
        content,
        fileUrl,
        fileName,
        status,
        isEdited,
        editedAt,
        metadata,
        createdAt,
        updatedAt,
      ];
}
