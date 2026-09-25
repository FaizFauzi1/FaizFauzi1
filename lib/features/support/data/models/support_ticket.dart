enum TicketStatus { open, inProgress, resolved, closed }
enum TicketPriority { low, medium, high, urgent }
enum TicketCategory {
  booking,
  payment,
  vendor,
  account,
  technical,
  general,
  refund,
  cancellation
}

class SupportTicket {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String subject;
  final String description;
  final TicketCategory category;
  final TicketPriority priority;
  TicketStatus status;
  final DateTime createdAt;
  DateTime? updatedAt;
  DateTime? resolvedAt;
  String? assignedAgentId;
  String? assignedAgentName;
  final List<SupportMessage> messages;
  final List<String> attachments; // URLs to attached files
  final Map<String, dynamic> metadata; // Additional ticket data

  SupportTicket({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.assignedAgentId,
    this.assignedAgentName,
    this.messages = const [],
    this.attachments = const [],
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_email': customerEmail,
      'subject': subject,
      'description': description,
      'category': category.toString().split('.').last,
      'priority': priority.toString().split('.').last,
      'status': status.toString().split('.').last,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'assigned_agent_id': assignedAgentId,
      'assigned_agent_name': assignedAgentName,
      'attachments': attachments,
      'metadata': metadata,
    };
  }

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'],
      customerId: json['customer_id'],
      customerName: json['customer_name'],
      customerEmail: json['customer_email'],
      subject: json['subject'],
      description: json['description'],
      category: TicketCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => TicketCategory.general,
      ),
      priority: TicketPriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => TicketPriority.medium,
      ),
      status: TicketStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TicketStatus.open,
      ),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      resolvedAt: json['resolved_at'] != null ? DateTime.parse(json['resolved_at']) : null,
      assignedAgentId: json['assigned_agent_id'],
      assignedAgentName: json['assigned_agent_name'],
      messages: (json['support_messages'] as List<dynamic>?)
          ?.map((m) => SupportMessage.fromJson(m))
          .toList() ?? [],
      attachments: List<String>.from(json['attachments'] ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }
}

class SupportMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isFromCustomer;
  final List<String> attachments;

  SupportMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isFromCustomer,
    this.attachments = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'sender_name': senderName,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_from_customer': isFromCustomer,
      'attachments': attachments,
    };
  }

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: json['id'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isFromCustomer: json['is_from_customer'] ?? false,
      attachments: List<String>.from(json['attachments'] ?? []),
    );
  }
}

class FAQItem {
  final String id;
  final String question;
  final String answer;
  final TicketCategory category;
  final int viewCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublished;

  FAQItem({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.viewCount,
    required this.createdAt,
    this.updatedAt,
    this.isPublished = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answer': answer,
      'category': category.toString().split('.').last,
      'view_count': viewCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_published': isPublished,
    };
  }

  factory FAQItem.fromJson(Map<String, dynamic> json) {
    return FAQItem(
      id: json['id'],
      question: json['question'],
      answer: json['answer'],
      category: TicketCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => TicketCategory.general,
      ),
      viewCount: json['view_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isPublished: json['is_published'] ?? true,
    );
  }
}
