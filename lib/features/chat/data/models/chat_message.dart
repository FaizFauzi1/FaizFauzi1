


class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final MessageType type;
  final String? imageUrl;
  bool isRead;
  final Map<String, dynamic>? metadata; // For order, appointment, payment data

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.type = MessageType.text,
    this.imageUrl,
    this.isRead = false,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      senderId: json['senderId'],
      senderName: json['senderName'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      type: MessageType.values[json['type'] ?? 0],
      imageUrl: json['imageUrl'],
      isRead: json['isRead'] ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.index,
      'imageUrl': imageUrl,
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? message,
    DateTime? timestamp,
    MessageType? type,
    String? imageUrl,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum MessageType {
  text,
  image,
  file,
  system,
  orderRequest,
  appointmentRequest,
  paymentRequest,
  quotation, // Added
  vendorResponse,
  groupCreated,
  memberJoined,
  memberLeft,
  memberRemoved,
}

// Base conversation class
abstract class BaseConversation {
  final String id;
  final String customerId;
  final String customerName;
  final List<ChatMessage> messages;
  DateTime lastMessageTime;
  int unreadCount;

  BaseConversation({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.messages,
    required this.lastMessageTime,
    this.unreadCount = 0,
  });

  bool get isGroup;
  String get displayName;
  String get avatarText;
}

class ChatConversation extends BaseConversation {
  final String vendorId;
  final String vendorName;
  final String vendorEmail;
  final String? vendorPhone;
  final String vendorAvatar;
  final bool isOnline;

  ChatConversation({
    required super.id,
    required this.vendorId,
    required this.vendorName,
    required this.vendorEmail,
    required this.vendorPhone,
    required super.customerId,
    required super.customerName,
    required super.messages,
    required super.lastMessageTime,
    super.unreadCount = 0,
    this.vendorAvatar = '',
    this.isOnline = false,
  });

  @override
  bool get isGroup => false;

  @override
  String get displayName => vendorName;

  @override
  String get avatarText => vendorAvatar.isNotEmpty ? vendorAvatar : vendorName.substring(0, 2).toUpperCase();

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'],
      vendorId: json['vendorId'],
      vendorName: json['vendorName'],
      vendorEmail: json['vendorEmail'],
      vendorPhone: json['vendorPhone'] ?? '',
      customerId: json['customerId'],
      customerName: json['customerName'],
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCount: json['unreadCount'] ?? 0,
      vendorAvatar: json['vendorAvatar'] ?? '',
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'vendorName': vendorName,
      'vendorEmail': vendorEmail,
      'vendorPhone': vendorPhone,
      'customerId': customerId,
      'customerName': customerName,
      'messages': messages.map((m) => m.toJson()).toList(),
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'vendorAvatar': vendorAvatar,
      'isOnline': isOnline,
    };
  }

  ChatConversation copyWith({
    String? id,
    String? vendorId,
    String? vendorName,
    String? vendorEmail,
    String? vendorPhone,
    String? customerId,
    String? customerName,
    List<ChatMessage>? messages,
    DateTime? lastMessageTime,
    int? unreadCount,
    String? vendorAvatar,
    bool? isOnline,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
      vendorEmail: vendorEmail ?? this.vendorEmail,
      vendorPhone: vendorPhone ?? this.vendorPhone,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      messages: messages ?? this.messages,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      vendorAvatar: vendorAvatar ?? this.vendorAvatar,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  ChatMessage? get lastMessage {
    if (messages.isEmpty) return null;
    return messages.last;
  }

  String get lastMessageText {
    final message = lastMessage;
    if (message == null) return 'No messages yet';
    switch (message.type) {
      case MessageType.text:
        return message.message;
      case MessageType.image:
        return '📷 Image';
      case MessageType.file:
        return '📎 File';
      case MessageType.system:
        return 'System message';
      case MessageType.orderRequest:
        return '🛒 Order Request';
      case MessageType.appointmentRequest:
        return '📅 Appointment Request';
      case MessageType.paymentRequest:
        return '💳 Payment Request';
      case MessageType.quotation:
        return '📝 Final Quotation';
      case MessageType.vendorResponse:
        return '✅ Vendor Response';
      case MessageType.groupCreated:
        return '👥 Group created';
      case MessageType.memberJoined:
        return '👋 Member joined';
      case MessageType.memberLeft:
        return '👋 Member left';
      default:
        return message.message;
    }
  }
}

// Group Chat Conversation Model
class GroupChatConversation extends BaseConversation {
  final String groupName;
  final String createdBy;
  final List<GroupMember> members;
  final String groupAvatar;

  GroupChatConversation({
    required super.id,
    required this.groupName,
    required this.createdBy,
    required this.members,
    required super.customerId,
    required super.customerName,
    required super.messages,
    required super.lastMessageTime,
    super.unreadCount = 0,
    this.groupAvatar = '',
  });

  @override
  bool get isGroup => true;

  @override
  String get displayName => groupName;

  @override
  String get avatarText => groupAvatar.isNotEmpty ? groupAvatar : '👥';

  factory GroupChatConversation.fromJson(Map<String, dynamic> json) {
    return GroupChatConversation(
      id: json['id'],
      groupName: json['groupName'],
      createdBy: json['createdBy'],
      members: (json['members'] as List)
          .map((m) => GroupMember.fromJson(m))
          .toList(),
      customerId: json['customerId'],
      customerName: json['customerName'],
      messages: (json['messages'] as List)
          .map((m) => ChatMessage.fromJson(m))
          .toList(),
      lastMessageTime: DateTime.parse(json['lastMessageTime']),
      unreadCount: json['unreadCount'] ?? 0,
      groupAvatar: json['groupAvatar'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupName': groupName,
      'createdBy': createdBy,
      'members': members.map((m) => m.toJson()).toList(),
      'customerId': customerId,
      'customerName': customerName,
      'messages': messages.map((m) => m.toJson()).toList(),
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'groupAvatar': groupAvatar,
    };
  }
}

// Group Member Model
class GroupMember {
  final String id;
  final String name;
  final String role; // 'customer', 'vendor'
  final String avatar;
  final bool isOnline;

  GroupMember({
    required this.id,
    required this.name,
    required this.role,
    this.avatar = '',
    this.isOnline = false,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'],
      name: json['name'],
      role: json['role'],
      avatar: json['avatar'] ?? '',
      isOnline: json['isOnline'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'avatar': avatar,
      'isOnline': isOnline,
    };
  }
}
