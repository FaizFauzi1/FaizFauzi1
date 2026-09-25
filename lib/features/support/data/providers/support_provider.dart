import 'dart:async';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/core/services/admin_notification_service.dart';
import 'package:eventease/features/support/data/models/support_ticket.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class SupportProvider extends ChangeNotifier {
  final SupabaseClient _supabase = SupabaseService.client;
  
  // Support Tickets
  List<SupportTicket> _tickets = [];
  List<FAQItem> _faqs = [];
  
  // Real-time subscriptions
  StreamSubscription? _ticketSubscription;
  StreamSubscription? _messageSubscription;
  
  bool _isLoading = false;
  bool _isCreatingTicket = false;
  String? _error;

  // Getters
  List<SupportTicket> get tickets => _tickets;
  List<FAQItem> get faqs => _faqs;
  bool get isLoading => _isLoading;
  bool get isCreatingTicket => _isCreatingTicket;
  String? get error => _error;

  // Computed getters
  List<SupportTicket> get openTickets =>
      _tickets.where((t) => t.status == TicketStatus.open).toList();

  List<SupportTicket> get inProgressTickets =>
      _tickets.where((t) => t.status == TicketStatus.inProgress).toList();

  List<SupportTicket> get resolvedTickets =>
      _tickets.where((t) => t.status == TicketStatus.resolved).toList();

  List<SupportTicket> get myTickets => _tickets; // For customer view

  List<SupportTicket> get assignedTickets =>
      _tickets.where((t) => t.assignedAgentId != null).toList();

  List<SupportTicket> get unassignedTickets =>
      _tickets.where((t) => t.assignedAgentId == null).toList();

  int get totalTickets => _tickets.length;
  int get openTicketsCount => openTickets.length;
  int get resolvedTicketsCount => resolvedTickets.length;

  // Initialize
  SupportProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await loadTickets();
    await loadFAQs();
    _subscribeToTickets();
  }

  // Real-time subscriptions
  void _subscribeToTickets() {
    _ticketSubscription = _supabase
        .from('support_tickets')
        .stream(primaryKey: ['id'])
        .listen((data) {
          _loadTicketsFromData(data);
        });
  }

  Future<void> _loadTicketsFromData(List<Map<String, dynamic>> data) async {
    try {
      // Build a map of ticket IDs to their messages in a more efficient way if needed, 
      // but for now let's at least fix the N+1 issue slightly by using a single query for all messages of these tickets
      final ticketIds = data.map((t) => t['id'] as String).toList();
      
      final allMessages = await _supabase
          .from('support_messages')
          .select()
          .inFilter('ticket_id', ticketIds)
          .order('timestamp', ascending: true);
          
      final ticketsWithMessages = data.map((ticketJson) {
        final messages = (allMessages as List<dynamic>)
            .where((m) => m['ticket_id'] == ticketJson['id'])
            .toList();
        
        ticketJson['support_messages'] = messages;
        return SupportTicket.fromJson(ticketJson);
      }).toList();
      
      _tickets = ticketsWithMessages;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading tickets from stream: $e');
    }
  }

  // Load Methods
  Future<void> loadTickets() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _supabase
          .from('support_tickets')
          .select()
          .order('created_at', ascending: false);

      await _loadTicketsFromData(response as List<Map<String, dynamic>>);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load tickets: $e';
      _isLoading = false;
      debugPrint(_error);
      notifyListeners();
    }
  }

  Future<void> loadFAQs() async {
    try {
      final response = await _supabase
          .from('faq_items')
          .select()
          .eq('is_published', true)
          .order('view_count', ascending: false);

      _faqs = (response as List<dynamic>)
          .map((json) => FAQItem.fromJson(json as Map<String, dynamic>))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading FAQs: $e');
    }
  }

  // Support Ticket Methods
  Future<SupportTicket> createTicket({
    required String customerId,
    required String customerName,
    required String customerEmail,
    required String subject,
    required String description,
    required TicketCategory category,
    required TicketPriority priority,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint(
          '[SupportProvider.createTicket] start: subject="$subject" '
          'category=${category.toString().split('.').last} '
          'priority=${priority.toString().split('.').last} '
          'customerIdLen=${customerId.length}',
        );
      }
      _isCreatingTicket = true;
      _error = null;
      notifyListeners();

      final ticketData = {
        'customer_id': customerId,
        'customer_name': customerName,
        'customer_email': customerEmail,
        'subject': subject,
        'description': description,
        'category': category.toString().split('.').last,
        'priority': priority.toString().split('.').last,
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('support_tickets')
          .insert(ticketData)
          .select()
          .single();

      if (kDebugMode) {
        debugPrint(
          '[SupportProvider.createTicket] inserted support_tickets id=${response['id']}',
        );
      }

      // Create initial message
      await _supabase.from('support_messages').insert({
        'id': const Uuid().v4(),
        'ticket_id': response['id'],
        'sender_id': customerId,
        'sender_name': customerName,
        'message': description,
        'timestamp': DateTime.now().toIso8601String(),
        'is_from_customer': true,
      });

      if (kDebugMode) {
        debugPrint(
          '[SupportProvider.createTicket] done: ticket ${response['id']} + initial message',
        );
      }

      // Notify admin
      try {
        final ticket = SupportTicket.fromJson({
          ...response,
          'support_messages': [],
        });
        await AdminNotificationService().notifyNewSupportTicket(ticket);
      } catch (e) {
        debugPrint('Error triggering admin notification for ticket: $e');
      }

      await loadTickets();
      final finalTicket = _tickets.firstWhere((t) => t.id == response['id']);
      _isCreatingTicket = false;
      notifyListeners();
      return finalTicket;
    } catch (e) {
      _isCreatingTicket = false;
      _error = 'Failed to create ticket: $e';
      debugPrint('[SupportProvider.createTicket] FAILED: $_error');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateTicketStatus(String ticketId, TicketStatus status) async {
    try {
      await _supabase.from('support_tickets').update({
        'status': status.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
        'resolved_at': status == TicketStatus.resolved 
            ? DateTime.now().toIso8601String() 
            : null,
      }).eq('id', ticketId);

      await loadTickets();
    } catch (e) {
      _error = 'Failed to update ticket status: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> assignTicket(String ticketId, String agentId, String agentName) async {
    try {
      await _supabase.from('support_tickets').update({
        'assigned_agent_id': agentId,
        'assigned_agent_name': agentName,
        'status': 'inProgress',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', ticketId);

      await loadTickets();
    } catch (e) {
      _error = 'Failed to assign ticket: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMessageToTicket(String ticketId, SupportMessage message) async {
    try {
      final messageData = message.toJson();
      // Ensure ticket_id is present in the data sent to Supabase
      messageData['ticket_id'] = ticketId;
      
      await _supabase.from('support_messages').insert(messageData);
      
      // Update ticket's updated_at timestamp
      await _supabase.from('support_tickets').update({
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', ticketId);

      await loadTickets();

      // Notify admin if message is from customer
      if (message.isFromCustomer) {
        try {
          await AdminNotificationService().notifyNewSupportMessage(
            ticketId: ticketId,
            customerName: message.senderName,
            messageSnippet: message.message,
          );
        } catch (e) {
          debugPrint('Error triggering admin notification for support message: $e');
        }
      }
    } catch (e) {
      _error = 'Failed to add message: $e';
      debugPrint(_error);
      notifyListeners();
      rethrow;
    }
  }

  // FAQ Methods
  Future<void> addFAQ({
    required String question,
    required String answer,
    required TicketCategory category,
  }) async {
    try {
      await _supabase.from('faq_items').insert({
        'question': question,
        'answer': answer,
        'category': category.toString().split('.').last,
        'view_count': 0,
        'created_at': DateTime.now().toIso8601String(),
        'is_published': true,
      });

      await loadFAQs();
    } catch (e) {
      debugPrint('Error adding FAQ: $e');
      rethrow;
    }
  }

  Future<void> updateFAQ(String faqId, {String? question, String? answer, TicketCategory? category}) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      if (question != null) updates['question'] = question;
      if (answer != null) updates['answer'] = answer;
      if (category != null) updates['category'] = category.toString().split('.').last;

      await _supabase.from('faq_items').update(updates).eq('id', faqId);
      await loadFAQs();
    } catch (e) {
      debugPrint('Error updating FAQ: $e');
      rethrow;
    }
  }

  Future<void> incrementFAQViewCount(String faqId) async {
    try {
      final faq = _faqs.firstWhere((f) => f.id == faqId);
      await _supabase.from('faq_items').update({
        'view_count': faq.viewCount + 1,
      }).eq('id', faqId);
      
      await loadFAQs();
    } catch (e) {
      debugPrint('Error incrementing FAQ view count: $e');
    }
  }

  Future<void> deleteFAQ(String faqId) async {
    try {
      await _supabase.from('faq_items').delete().eq('id', faqId);
      await loadFAQs();
    } catch (e) {
      debugPrint('Error deleting FAQ: $e');
      rethrow;
    }
  }

  // Search and Filter Methods
  List<SupportTicket> searchTickets(String query) {
    if (query.isEmpty) return _tickets;

    return _tickets.where((ticket) {
      return ticket.subject.toLowerCase().contains(query.toLowerCase()) ||
          ticket.description.toLowerCase().contains(query.toLowerCase()) ||
          ticket.customerName.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<SupportTicket> filterTicketsByStatus(TicketStatus status) {
    return _tickets.where((ticket) => ticket.status == status).toList();
  }

  List<SupportTicket> filterTicketsByCategory(TicketCategory category) {
    return _tickets.where((ticket) => ticket.category == category).toList();
  }

  List<SupportTicket> filterTicketsByPriority(TicketPriority priority) {
    return _tickets.where((ticket) => ticket.priority == priority).toList();
  }

  List<FAQItem> searchFAQs(String query) {
    if (query.isEmpty) return _faqs;

    return _faqs.where((faq) {
      return faq.question.toLowerCase().contains(query.toLowerCase()) ||
          faq.answer.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  List<FAQItem> filterFAQsByCategory(TicketCategory category) {
    return _faqs.where((faq) => faq.category == category).toList();
  }

  // Combined filter method for tickets
  List<SupportTicket> filterTickets(List<SupportTicket> tickets, {TicketStatus? status, TicketPriority? priority}) {
    return tickets.where((ticket) {
      final statusMatch = status == null || ticket.status == status;
      final priorityMatch = priority == null || ticket.priority == priority;
      return statusMatch && priorityMatch;
    }).toList();
  }

  // Statistics Methods
  Map<String, int> getTicketStats() {
    return {
      'total': _tickets.length,
      'open': openTickets.length,
      'inProgress': inProgressTickets.length,
      'resolved': resolvedTickets.length,
      'unassigned': unassignedTickets.length,
    };
  }

  Map<TicketCategory, int> getTicketsByCategory() {
    final stats = <TicketCategory, int>{};
    for (final ticket in _tickets) {
      stats[ticket.category] = (stats[ticket.category] ?? 0) + 1;
    }
    return stats;
  }

  Map<TicketPriority, int> getTicketsByPriority() {
    final stats = <TicketPriority, int>{};
    for (final ticket in _tickets) {
      stats[ticket.priority] = (stats[ticket.priority] ?? 0) + 1;
    }
    return stats;
  }

  double getAverageResolutionTime() {
    final resolvedTickets = _tickets.where((t) => t.resolvedAt != null).toList();
    if (resolvedTickets.isEmpty) return 0;

    final totalHours = resolvedTickets.fold<double>(0, (sum, ticket) {
      return sum + ticket.resolvedAt!.difference(ticket.createdAt).inHours;
    });

    return totalHours / resolvedTickets.length;
  }

  @override
  void dispose() {
    _ticketSubscription?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }
}
