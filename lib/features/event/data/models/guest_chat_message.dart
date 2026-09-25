enum MessageType {
  text,
  image,
  emoji,
  system,
}

class GuestChatMessage {
  final String id;
  final String eventId;
  final String senderId;
  final String senderName;
  final String? senderAvatar;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final bool isRead;
  final List<String> readBy;
  final String? replyToMessageId;
  final Map<String, dynamic> metadata;

  const GuestChatMessage({
    required this.id,
    required this.eventId,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.isRead,
    required this.readBy,
    this.replyToMessageId,
    required this.metadata,
  });

  GuestChatMessage copyWith({
    String? id,
    String? eventId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    bool? isRead,
    List<String>? readBy,
    String? replyToMessageId,
    Map<String, dynamic>? metadata,
  }) {
    return GuestChatMessage(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      readBy: readBy ?? this.readBy,
      replyToMessageId: replyToMessageId ?? this.replyToMessageId,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'senderId': senderId,
      'senderName': senderName,
      'senderAvatar': senderAvatar,
      'content': content,
      'type': type.toString(),
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'readBy': readBy,
      'replyToMessageId': replyToMessageId,
      'metadata': metadata,
    };
  }

  factory GuestChatMessage.fromJson(Map<String, dynamic> json) {
    return GuestChatMessage(
      id: json['id'],
      eventId: json['eventId'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderAvatar: json['senderAvatar'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      readBy: List<String>.from(json['readBy'] ?? []),
      replyToMessageId: json['replyToMessageId'],
      metadata: json['metadata'] ?? {},
    );
  }

  // Supabase for GuestChatMessage
  factory GuestChatMessage.fromSupabase(Map<String, dynamic> json) {
    return GuestChatMessage(
      id: json['id'],
      eventId: json['event_id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      senderAvatar: json['sender_avatar'],
      content: json['content'],
      type: MessageType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => MessageType.text,
      ),
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
      readBy: List<String>.from(json['read_by'] ?? []),
      replyToMessageId: json['reply_to_message_id'],
      metadata: json['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'event_id': eventId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'content': content,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'read_by': readBy,
      'reply_to_message_id': replyToMessageId,
      'metadata': metadata,
    };
  }

  factory GuestChatMessage.sample() {
    return GuestChatMessage(
      id: 'msg_1',
      eventId: 'event_1',
      senderId: 'guest_1',
      senderName: 'John Doe',
      senderAvatar: 'https://via.placeholder.com/50x50?text=JD',
      content: 'Congratulations Sarah and John! Wishing you a lifetime of happiness! 🎉',
      type: MessageType.text,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: true,
      readBy: ['guest_1', 'guest_2', 'host_1'],
      metadata: {},
    );
  }

  factory GuestChatMessage.systemSample() {
    return GuestChatMessage(
      id: 'msg_system_1',
      eventId: 'event_1',
      senderId: 'system',
      senderName: 'System',
      content: 'Sarah Johnson joined the chat',
      type: MessageType.system,
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      isRead: true,
      readBy: [],
      metadata: {'systemMessage': true},
    );
  }
}
