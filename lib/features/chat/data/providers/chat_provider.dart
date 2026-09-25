import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/chat/data/models/chat_message.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/providers/appointment_provider.dart';
import 'package:eventease/features/booking/data/providers/payment_provider.dart';
import 'package:eventease/features/booking/data/models/appointment.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/shared/models/payment.dart';
import 'package:uuid/uuid.dart';
import 'package:eventease/core/services/anti_bypass_service.dart';
import 'package:eventease/core/services/bypass_incident_recorder.dart';

class ChatProvider extends ChangeNotifier {
  final List<BaseConversation> _conversations = [];
  VendorProvider? _vendorProvider;
  final Map<String, String> _userNameCache = {};
  StreamSubscription? _messagesSubscription;
  StreamSubscription? _authSubscription;
  
  String get _currentUserId => Supabase.instance.client.auth.currentUser?.id ?? 'guest';

  List<BaseConversation> get conversations => _conversations;

  List<BaseConversation> get activeConversations =>
      _conversations.where((c) => c.messages.isNotEmpty).toList();

  BaseConversation? getConversationWithVendor(String vendorId) {
    return _conversations.where((c) => c is ChatConversation && (c as ChatConversation).vendorId == vendorId).cast<BaseConversation?>().firstWhere(
      (c) => c != null,
      orElse: () => null,
    );
  }

  BaseConversation? getGroupConversation(String groupId) {
    return _conversations.where((c) => c is GroupChatConversation && c.id == groupId).cast<BaseConversation?>().firstWhere(
      (c) => c != null,
      orElse: () => null,
    );
  }

  BaseConversation createConversation({
    required String vendorId,
    required String vendorName,
    required String vendorEmail,
    String? vendorPhone,
    String? vendorAvatar,
  }) {
    // Check if conversation already exists
    final existing = getConversationWithVendor(vendorId);
    if (existing != null) {
      return existing;
    }

    // Cache the name if it's not a generic ID
    if (!vendorName.contains('User (')) {
      _userNameCache[vendorId] = vendorName;
    }

    final conversation = ChatConversation(
      id: 'chat_${vendorId}_${_currentUserId}',
      vendorId: vendorId,
      vendorName: vendorName,
      vendorEmail: vendorEmail,
      vendorPhone: vendorPhone,
      customerId: _currentUserId,
      customerName: 'You', // In a real app, get from user profile
      messages: [],
      lastMessageTime: DateTime.now(),
      vendorAvatar: vendorAvatar ?? '',
      isOnline: true, // In a real app, check vendor online status
    );

    _conversations.add(conversation);
    notifyListeners();
    return conversation;
  }

  // Create group chat with selected vendors
  BaseConversation createGroupChat({
    required String groupName,
    required List<Map<String, String>> selectedVendors, // List of {'id': vendorId, 'name': vendorName}
  }) {
    // Check if group already exists (by name for now, could be improved)
    final existing = _conversations.where((c) =>
      c is GroupChatConversation && (c as GroupChatConversation).groupName == groupName
    ).cast<BaseConversation?>().firstWhere(
      (c) => c != null,
      orElse: () => null,
    );
    if (existing != null) {
      return existing;
    }

    // Create group members from selected vendors + customer
    final members = <GroupMember>[];

    // Add customer as member
    members.add(GroupMember(
      id: _currentUserId,
      name: 'You',
      role: 'customer',
      avatar: '',
      isOnline: true,
    ));

    // Add selected vendors as members
    for (final vendor in selectedVendors) {
      final vId = vendor['id']!;
      final vName = vendor['name']!;
      _userNameCache[vId] = vName;
      
      members.add(GroupMember(
        id: vId,
        name: vName,
        role: 'vendor',
        avatar: vName.substring(0, 2).toUpperCase(),
        isOnline: true, // In real app, check online status
      ));
    }

    final groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';

    final groupConversation = GroupChatConversation(
      id: groupId,
      groupName: groupName,
      createdBy: _currentUserId,
      members: members,
      customerId: _currentUserId,
      customerName: 'You',
      messages: [
        // Add system message for group creation
        ChatMessage(
          id: 'msg_group_created_${DateTime.now().millisecondsSinceEpoch}',
          senderId: 'system',
          senderName: 'System',
          message: 'Group "$groupName" created with ${selectedVendors.length} vendors',
          timestamp: DateTime.now(),
          type: MessageType.groupCreated,
          isRead: true,
        ),
      ],
      lastMessageTime: DateTime.now(),
    );

    _conversations.add(groupConversation);
    notifyListeners();
    return groupConversation;
  }

  void sendMessage({
    String? vendorId,
    String? groupId,
    required String message,
    MessageType type = MessageType.text,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    assert(vendorId != null || groupId != null, 'Either vendorId or groupId must be provided');

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // Anti-bypass scan
    final scan = AntiBypassService.scan(message);
    final finalMessage = scan.maskedMessage;
    final flagMetadata = scan.shouldFlag
        ? {'bypass_flags': scan.flags.map((f) => f.type.name).toList(), 'flagged': true}
        : null;

    if (scan.shouldFlag) {
      BypassIncidentRecorder.record(
        conversationId: vendorId ?? groupId ?? 'unknown',
        senderId: userId,
        senderRole: 'customer',
        flagTypes: scan.flags.map((f) => f.type.name).toList(),
        severity: scan.flags.any((f) => f.severity.index >= 2) ? 'high' : 'medium',
        originalMessage: message,
        maskedMessage: finalMessage,
      );
    }

    BaseConversation? conversation;

    if (vendorId != null) {
      conversation = getConversationWithVendor(vendorId) ??
          createConversation(
            vendorId: vendorId,
            vendorName: 'Vendor', 
            vendorEmail: 'vendor@example.com',
            vendorPhone: '+1234567890',
          );
    } else if (groupId != null) {
      conversation = getGroupConversation(groupId);
    }

    if (conversation == null) return;

    final chatMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: userId,
      senderName: 'You',
      message: finalMessage,
      timestamp: DateTime.now(),
      type: type,
      imageUrl: imageUrl,
      metadata: {...?metadata, ...?flagMetadata},
    );

    // 1. Add locally for immediate feedback
    conversation.messages.add(chatMessage);
    conversation.lastMessageTime = DateTime.now();
    conversation.unreadCount = 0;
    notifyListeners();

    // 2. Persist to Supabase
    _persistMessageToSupabase(conversation.id, userId, finalMessage, type, imageUrl, {...?metadata, ...?flagMetadata});
  }

  Future<void> _persistMessageToSupabase(String conversationId, String senderId, String content, MessageType type, String? imageUrl, Map<String, dynamic>? metadata) async {
    try {
      String finalConversationId = conversationId;

      // If it's a mock ID (chat_...), we need to ensure a real conversation exists
      if (conversationId.startsWith('chat_')) {
        finalConversationId = await _ensureSupabaseConversation(conversationId);
      }

      print('--- Supabase Update: Sending Message ---');
      print('Conversation ID: $finalConversationId');
      print('Content: $content');
      
      // Safety check: Don't attempt to sync mock/invalid IDs to Supabase
      if (!_isValidUuid(finalConversationId)) {
        print('Skipping persistence: $finalConversationId is not a valid UUID.');
        return;
      }
      
      await Supabase.instance.client.from('chat_messages').insert({
        'conversation_id': finalConversationId,
        'sender_id': senderId,
        'message_type': type.toString().split('.').last,
        'content': content,
        'metadata': metadata ?? {},
      });
      print('Success: Message persisted to chat_messages table');
    } catch (e) {
      print('Error persisting message: $e');
    }
  }

  bool _isValidUuid(String id) {
    if (id.isEmpty) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(id);
  }

  Future<String> _ensureSupabaseConversation(String mockId) async {
    final parts = mockId.split('_');
    if (parts.length < 3) return mockId; // Should not happen
    
    final vendorId = parts[1];
    final customerId = parts[2];

    // Defensive check: if IDs are not UUIDs, they won't exist in Supabase tables
    if (!_isValidUuid(vendorId) || !_isValidUuid(customerId)) {
      print('Warning: Mock IDs detected in _ensureSupabaseConversation: $vendorId, $customerId. Returning mockId.');
      return mockId;
    }

    String resolvedVendorId = vendorId;
    try {
      final profileResult = await Supabase.instance.client
          .from('vendor_profiles')
          .select('user_id')
          .eq('id', vendorId)
          .maybeSingle();
      
      if (profileResult != null && profileResult['user_id'] != null) {
        resolvedVendorId = profileResult['user_id'];
      }
    } catch (e) {
      print('Error resolving vendor ID: $e');
    }

    // 1. Check if conversation already exists for this pair
    // Get all conversations where the customer is a member
    final customerMemberships = await Supabase.instance.client
        .from('chat_group_members')
        .select('conversation_id')
        .eq('user_id', customerId);
    
    final customerConvIds = (customerMemberships as List).map((m) => m['conversation_id']).toList();

    if (customerConvIds.isNotEmpty) {
      // Check if the vendor is also in any of those conversations
      final commonMembership = await Supabase.instance.client
          .from('chat_group_members')
          .select('conversation_id, chat_conversations!inner(type)')
          .eq('user_id', resolvedVendorId)
          .eq('chat_conversations.type', 'direct')
          .filter('conversation_id', 'in', '(${customerConvIds.join(',')})')
          .maybeSingle();

      if (commonMembership != null) {
        print('Found existing Supabase conversation: ${commonMembership['conversation_id']}');
        return commonMembership['conversation_id'];
      }
    }

    print('--- Supabase Update: Creating New Conversation ---');
    // 2. Create new conversation
    final newConv = await Supabase.instance.client.from('chat_conversations').insert({
      'type': 'direct',
      'created_by': customerId,
    }).select().single();

    final newId = newConv['id'];
    print('Created conversation record: $newId');

    // 3. Add members
    print('Adding members to conversation...');
    await Supabase.instance.client.from('chat_group_members').insert([
      {'conversation_id': newId, 'user_id': customerId, 'role': 'member'},
      {'conversation_id': newId, 'user_id': resolvedVendorId, 'role': 'member'},
    ]);
    print('Success: Customer ($customerId) and Vendor ($resolvedVendorId) added to chat_group_members');

    return newId;

    return newId;
  }

  // Send order request through chat
  void sendOrderRequest({
    required String vendorId,
    required String serviceId,
    required String serviceName,
    required int quantity,
    required double price,
    double tax = 0.0,
    double serviceFee = 0.0,
    double discount = 0.0,
    String? packageName,
    String? duration,
    String? bookingTime,
    String? location,
    String? notes,
    DateTime? eventDate,
    String? imageUrl,
  }) {
    final totalAmount = (price * quantity) + tax + serviceFee - discount;
    final metadata = {
      'serviceId': serviceId,
      'serviceName': serviceName,
      'quantity': quantity,
      'price': price,
      'tax': tax,
      'serviceFee': serviceFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'packageName': packageName ?? 'Base Package',
      'duration': duration ?? '1 hour',
      'bookingTime': bookingTime ?? '10:00',
      'location': location ?? '',
      'notes': notes,
      'eventDate': eventDate?.toIso8601String(),
      'status': 'pending', // pending, accepted, rejected
      if (imageUrl != null) 'imageUrl': imageUrl,
    };

    sendMessage(
      vendorId: vendorId,
      message: 'Order Request: $serviceName (Qty: $quantity)',
      type: MessageType.orderRequest,
      imageUrl: imageUrl,
      metadata: metadata,
    );
  }

  // Send formal quotation through chat
  void sendQuotation({
    required String vendorId,
    required String customerId,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    double taxAmount = 0.0,
    double taxRate = 0.0,
    double serviceFee = 0.0,
    double discount = 0.0,
    double subtotal = 0.0,
    String? notes,
    DateTime? expiryDate,
    String? serviceId,
  }) {
    final metadata = {
      'customerId': customerId,
      'vendorId': vendorId,
      'serviceId': serviceId,
      'items': items,
      'subtotal': subtotal,
      'taxRate': taxRate,
      'taxAmount': taxAmount,
      'serviceFee': serviceFee,
      'discount': discount,
      'totalAmount': totalAmount,
      'expiryDate': expiryDate?.toIso8601String(),
      'notes': notes,
      'status': 'pending', // pending, accepted, rejected
      'createdAt': DateTime.now().toIso8601String(),
    };

    sendMessage(
      vendorId: vendorId,
      message: 'Final Quotation: RM ${totalAmount.toStringAsFixed(2)}',
      type: MessageType.quotation,
      metadata: metadata,
    );

    // Send notification to customer
    _createInAppNotification(
      userId: customerId,
      title: 'New Quotation Received',
      message: 'A vendor has sent you a final quotation for RM ${totalAmount.toStringAsFixed(2)}',
      type: 'quotation',
      relatedId: vendorId,
    );
  }

  // Send appointment request through chat
  Future<void> sendAppointmentRequest({
    required String vendorId,
    required DateTime appointmentDate,
    required String serviceType,
    String? notes,
    int? durationHours,
    String? serviceId,
    String? location,
    double? cost,
  }) async {
    String actualServiceId = await _ensureValidServiceId(vendorId, serviceId);

    // Also create actual appointment in database
    String? createdAppointmentId;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final appointmentProvider = AppointmentProvider();
        final appt = await appointmentProvider.createAppointmentFromChatRequest(
          vendorId: vendorId,
          customerId: user.id,
          serviceId: actualServiceId,
          scheduledDate: appointmentDate,
          type: AppointmentType.consultation,
          duration: Duration(hours: durationHours ?? 1),
          location: location ?? 'To be confirmed',
          notes: notes,
          cost: cost,
          customerName: user.userMetadata?['full_name'] ?? 'Customer',
          customerEmail: user.email,
          serviceName: serviceType,
        );
        createdAppointmentId = appt?.id;
        debugPrint('✅ Appointment created from chat request with ID: $createdAppointmentId');
      }
    } catch (e) {
      debugPrint('❌ Error creating appointment from chat: $e');
    }

    final metadata = {
      'appointmentDate': appointmentDate.toIso8601String(),
      'serviceType': serviceType,
      'notes': notes,
      'durationHours': durationHours,
      'status': 'pending', // pending, accepted, rejected, counter-offer
      'serviceId': actualServiceId,
      'appointmentId': createdAppointmentId,
    };

    // Send chat message
    sendMessage(
      vendorId: vendorId,
      message: 'Appointment Request: $serviceType on ${appointmentDate.toString().split(' ')[0]}',
      type: MessageType.appointmentRequest,
      metadata: metadata,
    );
  }

  // Send payment request through chat
  void sendPaymentRequest({
    required String vendorId,
    required double amount,
    required String description,
    String? paymentMethod,
    DateTime? dueDate,
  }) {
    final metadata = {
      'amount': amount,
      'description': description,
      'paymentMethod': paymentMethod,
      'dueDate': dueDate?.toIso8601String(),
      'status': 'pending', // pending, paid, failed
    };

    sendMessage(
      vendorId: vendorId,
      message: 'Payment Request: RM${amount.toStringAsFixed(2)} for $description',
      type: MessageType.paymentRequest,
      metadata: metadata,
    );
  }

  // Handle vendor response to requests with system integration
  Future<void> handleVendorResponse({
    required String vendorId,
    required String messageId,
    required String response, // 'accepted', 'rejected', 'counter-offer'
    String? counterOfferDetails,
    double? counterOfferAmount,
    DateTime? counterOfferDate,
    required BuildContext context, // Add context to access providers
  }) async {
    final conversation = getConversationWithVendor(vendorId);
    if (conversation == null) return;

    // Find the original request message
    final requestMessageIndex = conversation.messages.indexWhere(
      (msg) => msg.id == messageId,
    );

    if (requestMessageIndex == -1) return;

    final requestMessage = conversation.messages[requestMessageIndex];
    if (requestMessage.metadata == null) return;

    // Update the request message status
    final updatedMetadata = Map<String, dynamic>.from(requestMessage.metadata!);
    updatedMetadata['status'] = response;
    if (counterOfferDetails != null) {
      updatedMetadata['counterOfferDetails'] = counterOfferDetails;
    }
    if (counterOfferAmount != null) {
      updatedMetadata['counterOfferAmount'] = counterOfferAmount;
    }
    if (counterOfferDate != null) {
      updatedMetadata['counterOfferDate'] = counterOfferDate.toIso8601String();
    }

    // Create a new message with updated metadata
    final updatedMessage = ChatMessage(
      id: requestMessage.id,
      senderId: requestMessage.senderId,
      senderName: requestMessage.senderName,
      message: requestMessage.message,
      timestamp: requestMessage.timestamp,
      type: requestMessage.type,
      imageUrl: requestMessage.imageUrl,
      isRead: requestMessage.isRead,
      metadata: updatedMetadata,
    );

    // Replace the message in the list
    conversation.messages[requestMessageIndex] = updatedMessage;

    // Persist to Supabase (await so the stream doesn't race against us)
    await updateMessageMetadata(messageId, updatedMetadata);

    // Integrate with system providers based on message type
    // Guard against using context after async gap if widget was disposed
    if (!context.mounted) return;
    await _integrateWithSystemProviders(
      context: context,
      messageId: messageId,
      messageType: requestMessage.type,
      response: response,
      vendorId: vendorId,
      customerId: conversation.customerId, // Use conversation customerId
      metadata: updatedMetadata,
      counterOfferAmount: counterOfferAmount,
      counterOfferDate: counterOfferDate,
    );

    // Send vendor response message
    String responseMessage = '';
    switch (response) {
      case 'accepted':
        responseMessage = '✅ Request accepted!';
        break;
      case 'rejected':
        responseMessage = '❌ Request declined.';
        break;
      case 'counter-offer':
        responseMessage = '💬 Counter-offer: $counterOfferDetails';
        break;
    }

    final vendorResponse = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: vendorId,
      senderName: (conversation as ChatConversation).vendorName,
      message: responseMessage,
      timestamp: DateTime.now(),
      type: MessageType.vendorResponse,
      metadata: {
        'originalMessageId': messageId,
        'response': response,
        'counterOfferDetails': counterOfferDetails,
        'counterOfferAmount': counterOfferAmount,
        'counterOfferDate': counterOfferDate?.toIso8601String(),
      },
    );

    conversation.messages.add(vendorResponse);
    conversation.lastMessageTime = DateTime.now();
    conversation.unreadCount++;

    // Persist vendor response to Supabase
    _persistMessageToSupabase(
      conversation.id,
      vendorId,
      responseMessage,
      MessageType.vendorResponse,
      null,
      vendorResponse.metadata,
    );

    notifyListeners();
  }

  Future<String> _ensureValidServiceId(String vendorId, String? currentId) async {
    if (currentId != null && _isValidUuid(currentId) && currentId != '00000000-0000-0000-0000-000000000000') {
      return currentId;
    }
    
    try {
      // 1. Try to get a service for this vendor
      final vendorService = await Supabase.instance.client
          .from('vendor_services')
          .select('id')
          .eq('vendor_id', vendorId)
          .limit(1);
      if (vendorService.isNotEmpty) {
        return vendorService[0]['id'];
      }
      
      // 2. Try to get ANY service to satisfy FK constraint temporarily
      final anyService = await Supabase.instance.client
          .from('vendor_services')
          .select('id')
          .limit(1);
      if (anyService.isNotEmpty) {
        return anyService[0]['id'];
      }
      
      // 3. Last resort: Insert a dummy service for this vendor
      final newService = await Supabase.instance.client
          .from('vendor_services')
          .insert({
            'vendor_id': vendorId,
            'name': 'General Service',
            'description': 'System generated service',
            'category': 'other',
            'base_price': 0.0,
            'price_type': 'fixed',
            'duration_hours': 1,
            'max_guests': 10,
            'features': [],
            'service_type': 'service',
            'is_featured': false,
            'active': true,
            'approval_status': 'approved',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select('id')
          .single();
      return newService['id'];
    } catch (e) {
      debugPrint('Failed to ensure valid service ID: $e');
      return '00000000-0000-0000-0000-000000000000';
    }
  }

  Future<void> updateMessageMetadata(String messageId, Map<String, dynamic> newMetadata) async {
    try {
      // Create a clean, JSON-serializable map
      final sanitizedMetadata = <String, dynamic>{};
      newMetadata.forEach((key, value) {
        if (value != null) {
          sanitizedMetadata[key] = value;
        }
      });

      await Supabase.instance.client
          .from('chat_messages')
          .update({'metadata': sanitizedMetadata})
          .eq('id', messageId);
      
      // Local update to sync UI
      for (var conversation in _conversations) {
        final index = conversation.messages.indexWhere((m) => m.id == messageId);
        if (index != -1) {
          final message = conversation.messages[index];
          if (message is ChatMessage) {
            conversation.messages[index] = message.copyWith(metadata: sanitizedMetadata);
          }
          break;
        }
      }
      
      // Notify listeners AFTER local updates are fully complete
      notifyListeners();
      
      // Trigger notification if quotation accepted
      if (sanitizedMetadata['status'] == 'accepted') {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        final targetVendorId = sanitizedMetadata['vendorId']?.toString();
        if (userId != null && targetVendorId != null && targetVendorId.isNotEmpty) {
          // If customer accepted, notify vendor
          _createInAppNotification(
            userId: targetVendorId,
            title: 'Quotation Accepted',
            message: 'A customer has accepted your quotation.',
            type: 'quotation',
            relatedId: userId,
          );
        }
      }

      print('Success: Updated metadata for message $messageId');
    } catch (e) {
      print('Error updating message metadata: $e');
    }
  }

  // Helper to create notifications directly via Supabase
  Future<void> _createInAppNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? relatedId,
  }) async {
    try {
      await Supabase.instance.client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type,
        'severity': 'info',
        'channel': 'inapp',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'related_id': relatedId,
      });
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Integrate chat responses with system providers
  Future<void> _integrateWithSystemProviders({
    required BuildContext context,
    required String messageId,
    required MessageType messageType,
    required String response,
    required String vendorId,
    required String customerId,
    required Map<String, dynamic> metadata,
    double? counterOfferAmount,
    DateTime? counterOfferDate,
  }) async {
    try {
      switch (messageType) {
        case MessageType.appointmentRequest:
          final appointmentProvider = Provider.of<AppointmentProvider>(context, listen: false);
          final existingApptId = metadata['appointmentId']?.toString();

          if (response == 'accepted') {
            if (existingApptId != null && existingApptId.isNotEmpty) {
              await appointmentProvider.confirmAppointment(existingApptId);
              debugPrint('✅ Confirmed existing appointment from chat');
            } else {
              // Fallback if metadata didn't have the ID
              String acceptedServiceId = await _ensureValidServiceId(vendorId, metadata['serviceId']);
              final newAppointment = await appointmentProvider.createAppointmentFromChatRequest(
                vendorId: vendorId,
                customerId: customerId,
                serviceId: acceptedServiceId,
                scheduledDate: DateTime.parse(metadata['appointmentDate']),
                type: AppointmentType.values.firstWhere(
                  (e) => e.toString().split('.').last == metadata['serviceType'],
                  orElse: () => AppointmentType.consultation,
                ),
                duration: metadata['durationHours'] != null 
                    ? Duration(hours: metadata['durationHours']) 
                    : null,
                location: metadata['location'] ?? 'TBD',
                notes: metadata['notes'],
                cost: metadata['cost']?.toDouble(),
              );
              if (newAppointment != null) {
                await appointmentProvider.confirmAppointment(newAppointment.id);
              }
            }
          } else if (response == 'rejected') {
            if (existingApptId != null && existingApptId.isNotEmpty) {
              await appointmentProvider.cancelAppointment(existingApptId);
              debugPrint('✅ Cancelled rejected appointment from chat');
            }
          }
          break;

        case MessageType.paymentRequest:
          final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
          if (response == 'accepted') {
            // Process the payment
            paymentProvider.processPayment(
              bookingId: _isValidUuid(metadata['bookingId'] ?? '') ? metadata['bookingId'] : '00000000-0000-0000-0000-000000000000',
              customerId: customerId,
              vendorId: vendorId,
              amount: metadata['amount']?.toDouble() ?? 0.0,
              method: PaymentMethod.onlineBanking,
              email: 'customer@example.com', // Placeholder
              mobile: '0123456789', // Placeholder
              name: 'Chat User', // Placeholder
              description: 'Payment Request from Chat',
              metadata: {'source': 'chat_response'},
            );
          }
          break;

        case MessageType.orderRequest:
          final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
          if (response == 'accepted') {
            // Check if booking already exists
            String? bookingId = metadata['bookingId'];
            if (bookingId == null || bookingId.startsWith('temp_') || !_isValidUuid(bookingId)) {
              // Create a new formal booking
              final newBooking = Booking(
                id: const Uuid().v4(),
                vendorId: vendorId,
                customerId: customerId,
                serviceId: metadata['serviceId'] ?? '',
                serviceName: metadata['serviceName'] ?? 'Service',
                customerName: 'Chat Customer', // Fallback, real name should be fetched
                customerPhone: '',
                customerEmail: '',
                bookingDate: metadata['eventDate'] != null 
                    ? DateTime.parse(metadata['eventDate']) 
                    : DateTime.now(),
                bookingTime: _parseTimeOfDay(metadata['bookingTime'] ?? '10:00'),
                duration: metadata['duration'] ?? '1 hour',
                packageName: metadata['packageName'] ?? 'Base Package',
                amount: (metadata['totalAmount'] as num?)?.toDouble() ?? 
                    ((metadata['price'] as num?)?.toDouble() ?? 0.0) * 
                    ((metadata['quantity'] as num?)?.toInt() ?? 1),
                location: metadata['location'] ?? '',
                notes: metadata['notes'] ?? '',
                guestCount: (metadata['quantity'] as num?)?.toInt() ?? 1,
                status: BookingStatus.awaitingPayment,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              
              await bookingProvider.addBooking(newBooking);
              
              // Update message metadata with the NEW booking ID
              metadata['bookingId'] = newBooking.id;
              await updateMessageMetadata(messageId, metadata);
            } else {
              // Update existing booking status
              await bookingProvider.updateBookingStatus(bookingId, BookingStatus.awaitingPayment);
            }
          }
          break;

        default:
          // No integration needed for other message types
          break;
      }
    } catch (e) {
      // Log error but don't crash the app
      debugPrint('Error integrating chat response with system: $e');
    }
  }

  static TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        final hour = int.tryParse(parts[0]) ?? 10;
        final minute = int.tryParse(parts[1]) ?? 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (e) {
      // ignore
    }
    return const TimeOfDay(hour: 10, minute: 0);
  }



  void markConversationAsRead(String vendorId) {
    final conversation = getConversationWithVendor(vendorId);
    if (conversation != null) {
      conversation.unreadCount = 0;
      for (final message in conversation.messages) {
        message.isRead = true;
      }
      notifyListeners();
    }
  }

  void deleteConversation(String vendorId) {
    _conversations.removeWhere((c) => c is ChatConversation && (c as ChatConversation).vendorId == vendorId);
    notifyListeners();
  }

  int getTotalUnreadCount() {
    return _conversations.fold(0, (sum, c) => sum + c.unreadCount);
  }

  // Mock data for demonstration
  void loadMockConversations() {
    if (_conversations.isNotEmpty) return; // Don't reload if already loaded

    final mockConversations = [
      ChatConversation(
        id: 'chat_venue_001_customer_001',
        vendorId: 'venue_001',
        vendorName: 'Grand Ballroom KL',
        vendorEmail: 'info@grandballroom.com',
        vendorPhone: '+60123456789',
        customerId: _currentUserId,
        customerName: 'You',
        messages: [
          ChatMessage(
            id: 'msg_1',
            senderId: 'venue_001',
            senderName: 'Grand Ballroom KL',
            message: 'Thank you for your inquiry. We have availability on your requested date.',
            timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
            isRead: false,
          ),
          ChatMessage(
            id: 'msg_2',
            senderId: _currentUserId,
            senderName: 'You',
            message: 'Great! Can you send me the pricing details?',
            timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
            isRead: true,
          ),
        ],
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 3)),
        unreadCount: 1,
        vendorAvatar: 'GB',
        isOnline: true,
      ),
      ChatConversation(
        id: 'chat_catering_001_customer_001',
        vendorId: 'catering_001',
        vendorName: 'Elegant Catering',
        vendorEmail: 'hello@elegantcatering.com',
        vendorPhone: '+60198765432',
        customerId: _currentUserId,
        customerName: 'You',
        messages: [
          ChatMessage(
            id: 'msg_3',
            senderId: 'catering_001',
            senderName: 'Elegant Catering',
            message: 'We can customize the menu according to your preferences.',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
            isRead: true,
          ),
        ],
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 1)),
        unreadCount: 0,
        vendorAvatar: 'EC',
        isOnline: false,
      ),
    ];

    _conversations.addAll(mockConversations);
    notifyListeners();
  }

  // Initialize
  ChatProvider() {
    _loadInitialData();
    _setupRealtimeListeners();
    _listenToAuthChanges();
  }
  void _listenToAuthChanges() {
    _authSubscription?.cancel();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.initialSession) {
        print('Auth Event: User signed in, re-initializing chat...');
        loadConversationsFromSupabase();
        _setupRealtimeListeners();
      } else if (event == AuthChangeEvent.signedOut) {
        print('Auth Event: User signed out, clearing chat data.');
        _conversations.clear();
        _messagesSubscription?.cancel();
        notifyListeners();
      }
    });
  }

  void updateVendorProvider(VendorProvider provider) {
    _vendorProvider = provider;
    // Optionally trigger a reload of names if needed
    if (_conversations.isNotEmpty) {
      loadConversationsFromSupabase();
    }
  }

  bool get mounted => true; // Simple mock for logic compatibility

  Future<String?> _resolveAndCacheName(String userId) async {
    if (_userNameCache.containsKey(userId)) return _userNameCache[userId];

    // 1. Try VendorProvider (for customers looking at vendors)
    if (_vendorProvider != null) {
      final vendor = await _vendorProvider!.fetchVendorById(userId);
      if (vendor != null) {
        _userNameCache[userId] = vendor.name;
        _updateConversationsFromCache();
        return vendor.name;
      }
    }

    // 2. Try customer_user table
    try {
      final res = await Supabase.instance.client
          .from('customer_user')
          .select('name')
          .eq('id', userId)
          .maybeSingle();
      if (res != null && res['name'] != null) {
        _userNameCache[userId] = res['name'];
        _updateConversationsFromCache();
        return res['name'];
      }
    } catch (_) {}

    // 3. Try vendor_user table
    try {
      final res = await Supabase.instance.client
          .from('vendor_user')
          .select('name')
          .eq('id', userId)
          .maybeSingle();
      if (res != null && res['name'] != null) {
        _userNameCache[userId] = res['name'];
        _updateConversationsFromCache();
        return res['name'];
      }
    } catch (_) {}

    // 4. Try admin_user table
    try {
      final res = await Supabase.instance.client
          .from('admin_user')
          .select('name')
          .eq('id', userId)
          .maybeSingle();
      if (res != null && res['name'] != null) {
        _userNameCache[userId] = res['name'];
        _updateConversationsFromCache();
        return res['name'];
      }
    } catch (_) {}

    // 5. Try vendor_profiles directly
    try {
      final res = await Supabase.instance.client
          .from('vendor_profiles')
          .select('business_name')
          .eq('user_id', userId)
          .maybeSingle();
      if (res != null && res['business_name'] != null) {
        _userNameCache[userId] = res['business_name'];
        _updateConversationsFromCache();
        return res['business_name'];
      }
    } catch (_) {}

    return null;
  }

  void _updateConversationsFromCache() {
    bool hasUpdates = false;
    for (int i = 0; i < _conversations.length; i++) {
        final conv = _conversations[i];
        if (conv is ChatConversation) {
            String? cachedName = _userNameCache[conv.vendorId];
            
            // Update messages in this conversation
            bool messagesUpdated = false;
            final updatedMessages = conv.messages.map((m) {
                String? senderName = _userNameCache[m.senderId];
                if (senderName != null && m.senderName != senderName && m.senderName != 'You') {
                    messagesUpdated = true;
                    return m.copyWith(senderName: senderName);
                }
                return m;
            }).toList();

            if ((cachedName != null && conv.vendorName != cachedName) || messagesUpdated) {
                _conversations[i] = conv.copyWith(
                    vendorName: cachedName ?? conv.vendorName,
                    messages: updatedMessages,
                    vendorAvatar: cachedName != null ? cachedName.substring(0, 1).toUpperCase() : conv.vendorAvatar,
                );
                hasUpdates = true;
            }
        } else if (conv is GroupChatConversation) {
            bool membersUpdated = false;
            final updatedMembers = conv.members.map((m) {
                String? cachedName = _userNameCache[m.id];
                if (cachedName != null && m.name != cachedName && m.name != 'You') {
                    membersUpdated = true;
                    return GroupMember(
                        id: m.id,
                        name: cachedName,
                        role: m.role,
                        avatar: cachedName.substring(0, 1).toUpperCase(),
                        isOnline: m.isOnline,
                    );
                }
                return m;
            }).toList();

            bool messagesUpdated = false;
            final updatedMessages = conv.messages.map((m) {
                String? senderName = _userNameCache[m.senderId];
                if (senderName != null && m.senderName != senderName && m.senderName != 'You') {
                    messagesUpdated = true;
                    return m.copyWith(senderName: senderName);
                }
                return m;
            }).toList();

            if (membersUpdated || messagesUpdated) {
                _conversations[i] = GroupChatConversation(
                    id: conv.id,
                    groupName: conv.groupName,
                    createdBy: conv.createdBy,
                    members: updatedMembers,
                    customerId: conv.customerId,
                    customerName: conv.customerName,
                    messages: updatedMessages,
                    lastMessageTime: conv.lastMessageTime,
                    unreadCount: conv.unreadCount,
                    groupAvatar: conv.groupAvatar,
                );
                hasUpdates = true;
            }
        }
    }
    
    if (hasUpdates && mounted) {
        notifyListeners();
    }
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  void _loadInitialData() {
    loadConversationsFromSupabase();
  }

  void _setupRealtimeListeners() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _messagesSubscription?.cancel();

    // Listen for new messages
    print('--- Supabase Setup: Starting Real-time Listener ---');
    _messagesSubscription = Supabase.instance.client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .listen((List<Map<String, dynamic>> data) {
          if (data.isNotEmpty) {
            print('Supabase Event: Received ${data.length} messages via Real-time Stream');
            _handleIncomingMessages(data);
          }
        });
  }

  void _handleIncomingMessages(List<Map<String, dynamic>> data) {
    bool hasChanges = false;
    for (var msgJson in data) {
      final convId = msgJson['conversation_id'];
      final conversation = _conversations.firstWhere(
        (c) => c.id == convId,
        orElse: () => null as dynamic,
      );

      if (conversation != null) {
        final messageId = msgJson['id'];
        final existingIndex = conversation.messages.indexWhere((m) => m.id == messageId);

        if (existingIndex == -1) {
          // New message — add it
          final newMessage = ChatMessage(
            id: messageId,
            senderId: msgJson['sender_id'],
            senderName: msgJson['sender_id'] == _currentUserId 
                ? 'You' 
                : (_userNameCache[msgJson['sender_id']] ?? 'User'),
            message: msgJson['content'] ?? '',
            timestamp: DateTime.parse(msgJson['created_at'] ?? DateTime.now().toIso8601String()),
            type: _parseMessageType(msgJson['message_type']),
            isRead: msgJson['is_read'] ?? false,
            metadata: msgJson['metadata'] as Map<String, dynamic>?,
          );
          conversation.messages.add(newMessage);
          conversation.lastMessageTime = newMessage.timestamp;
          if (newMessage.senderId != _currentUserId) {
            conversation.unreadCount++;
          }
          print('Sync Event: New message added to ${conversation.id} -> ${newMessage.message}');
          hasChanges = true;
        } else {
          // Existing message — check if metadata changed and update if so
          final existingMessage = conversation.messages[existingIndex];
          final incomingMetadata = msgJson['metadata'] as Map<String, dynamic>?;
          final incomingStatus = incomingMetadata?['status'];
          final existingStatus = existingMessage.metadata?['status'];

          if (incomingMetadata != null && incomingStatus != existingStatus) {
            // Protect against stale stream data reverting local state
            bool isStaleReversion = (existingStatus == 'accepted' || existingStatus == 'rejected') && incomingStatus == 'pending';
            
            if (!isStaleReversion) {
              // Metadata changed (e.g., pending -> accepted), update in-memory message
              final updatedMessage = ChatMessage(
                id: existingMessage.id,
                senderId: existingMessage.senderId,
                senderName: existingMessage.senderName,
                message: existingMessage.message,
                timestamp: existingMessage.timestamp,
                type: existingMessage.type,
                imageUrl: existingMessage.imageUrl,
                isRead: existingMessage.isRead,
                metadata: incomingMetadata,
              );
              conversation.messages[existingIndex] = updatedMessage;
              print('Sync Event: Updated metadata for message $messageId -> status: $incomingStatus');
              hasChanges = true;
            }
          }
        }
      } else {
        // If we get a message for a conversation we don't have yet, reload all
        loadConversationsFromSupabase();
        return;
      }
    }
    if (hasChanges) {
      notifyListeners();
    }
  }

  Future<void> loadConversationsFromSupabase() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // 1. Get all conversations where user is a member
      final memberResults = await Supabase.instance.client
          .from('chat_group_members')
          .select('conversation_id')
          .eq('user_id', userId);

      final conversationIds = (memberResults as List).map((m) => m['conversation_id']).toList();

      if (conversationIds.isEmpty) return;

      // 2. Fetch conversation details and messages
      final conversationsData = await Supabase.instance.client
          .from('chat_conversations')
          .select('*, chat_messages(*), chat_group_members(*)')
          .filter('id', 'in', '(${conversationIds.join(',')})');

      print('Supabase: Found ${(conversationsData as List).length} conversations for user $userId');

      _conversations.clear();
      for (var convData in (conversationsData as List)) {
        final messages = (convData['chat_messages'] as List).map((m) {
          return ChatMessage(
            id: m['id'],
            senderId: m['sender_id'],
            senderName: m['sender_id'] == userId 
                ? 'You' 
                : (_userNameCache[m['sender_id']] ?? 'User'),
            message: m['content'] ?? '',
            timestamp: DateTime.parse(m['created_at']),
            type: _parseMessageType(m['message_type']),
            isRead: m['is_read'] ?? false,
            metadata: m['metadata'] as Map<String, dynamic>?,
          );
        }).toList();

        final membersData = convData['chat_group_members'] as List;
        final otherMember = membersData.firstWhere((m) => m['user_id'] != userId, orElse: () => null);

        if (convData['type'] == 'direct') {
          final otherUserId = otherMember?['user_id'] ?? 'unknown';
          
          // Use cached name or placeholder
          String displayName = _userNameCache[otherUserId] ?? 'User (${otherUserId.toString().substring(0, 5)})';
          String displayEmail = '';
          String displayAvatar = '';

          // Proactively resolve the name if not cached
          if (!_userNameCache.containsKey(otherUserId)) {
            _resolveAndCacheName(otherUserId).then((name) {
              if (name != null && mounted) {
                notifyListeners(); // Refresh UI when name is found
              }
            });
          }

          final conversation = ChatConversation(
            id: convData['id'],
            vendorId: otherUserId,
            vendorName: displayName,
            vendorEmail: displayEmail,
            vendorPhone: '',
            customerId: userId,
            customerName: 'You',
            messages: messages,
            lastMessageTime: DateTime.parse(convData['updated_at'] ?? convData['created_at']),
            unreadCount: messages.where((m) => !m.isRead && m.senderId != userId).length,
            vendorAvatar: displayAvatar,
          );
          _conversations.add(conversation);
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error loading conversations from Supabase: $e');
    }
  }

  // Mark all conversations as read
  void markAllConversationsAsRead() {
    for (final conversation in _conversations) {
      conversation.unreadCount = 0;
    }
    notifyListeners();
  }

  // Clear all conversations
  void clearAllConversations() {
    _conversations.clear();
    notifyListeners();
  }

  // Parse @mentions from message text
  List<String> _parseMentions(String message) {
    final mentionRegex = RegExp(r'@(\w+)');
    final matches = mentionRegex.allMatches(message);
    return matches.map((match) => match.group(1)!).toList();
  }

  // Add member to group chat
  void addMemberToGroup({
    required String groupId,
    required String memberId,
    required String memberName,
    required String role,
  }) {
    final conversation = getGroupConversation(groupId);
    if (conversation == null || conversation is! GroupChatConversation) return;

    // Check if member already exists
    if (conversation.members.any((m) => m.id == memberId)) return;

    final newMember = GroupMember(
      id: memberId,
      name: memberName,
      role: role,
      avatar: memberName.substring(0, 2).toUpperCase(),
      isOnline: true,
    );

    conversation.members.add(newMember);

    // Add system message
    final systemMessage = ChatMessage(
      id: 'msg_member_added_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'system',
      senderName: 'System',
      message: '$memberName was added to the group',
      timestamp: DateTime.now(),
      type: MessageType.memberJoined,
      isRead: true,
    );

    conversation.messages.add(systemMessage);
    conversation.lastMessageTime = DateTime.now();

    notifyListeners();
  }

  // Remove member from group chat
  void removeMemberFromGroup({
    required String groupId,
    required String memberId,
  }) {
    final conversation = getGroupConversation(groupId);
    if (conversation == null || conversation is! GroupChatConversation) return;

    final memberIndex = conversation.members.indexWhere((m) => m.id == memberId);
    if (memberIndex == -1) return;

    final removedMember = conversation.members[memberIndex];
    conversation.members.removeAt(memberIndex);

    // Add system message
    final systemMessage = ChatMessage(
      id: 'msg_member_removed_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'system',
      senderName: 'System',
      message: '${removedMember.name} was removed from the group',
      timestamp: DateTime.now(),
      type: MessageType.memberRemoved,
      isRead: true,
    );

    conversation.messages.add(systemMessage);
    conversation.lastMessageTime = DateTime.now();

    notifyListeners();
  }

  // Leave group chat
  void leaveGroup(String groupId) {
    final conversation = getGroupConversation(groupId);
    if (conversation == null || conversation is! GroupChatConversation) return;

    // Remove current user from members
    conversation.members.removeWhere((m) => m.id == _currentUserId);

    // Add system message
    final systemMessage = ChatMessage(
      id: 'msg_member_left_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'system',
      senderName: 'System',
      message: 'You left the group',
      timestamp: DateTime.now(),
      type: MessageType.memberLeft,
      isRead: true,
    );

    conversation.messages.add(systemMessage);
    conversation.lastMessageTime = DateTime.now();

    // If no members left, delete the group
    if (conversation.members.isEmpty) {
      _conversations.remove(conversation);
    }

    notifyListeners();
  }

  // Update receiveMessage for groups
  void receiveMessage({
    String? vendorId,
    String? groupId,
    required String senderId,
    required String senderName,
    required String message,
    MessageType type = MessageType.text,
    String? imageUrl,
  }) {
    assert(vendorId != null || groupId != null, 'Either vendorId or groupId must be provided');

    BaseConversation? conversation;

    if (vendorId != null) {
      conversation = getConversationWithVendor(vendorId) ??
          createConversation(
            vendorId: vendorId,
            vendorName: senderName,
            vendorEmail: 'vendor@example.com',
            vendorPhone: '+1234567890',
          );
    } else if (groupId != null) {
      conversation = getGroupConversation(groupId);
      if (conversation == null) {
        throw Exception('Group conversation not found: $groupId');
      }
    }

    if (conversation == null) {
      throw Exception('Conversation not found');
    }

    final chatMessage = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: DateTime.now(),
      type: type,
      imageUrl: imageUrl,
      isRead: false,
    );

    // Add message to conversation
    conversation.messages.add(chatMessage);
    conversation.lastMessageTime = DateTime.now();
    conversation.unreadCount++;

    notifyListeners();
  }

  MessageType _parseMessageType(String? type) {
    if (type == null) return MessageType.text;
    
    // Handle both enum string representation and plain strings
    final typeName = type.contains('.') ? type.split('.').last : type;
    
    return MessageType.values.firstWhere(
      (e) => e.toString().split('.').last == typeName,
      orElse: () => MessageType.text,
    );
  }
}
