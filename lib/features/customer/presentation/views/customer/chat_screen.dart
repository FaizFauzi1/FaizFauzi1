import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/chat/data/models/chat_message.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:provider/provider.dart';
import 'package:eventease/shared/data/vendor_services_data.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:eventease/features/vendor/data/models/vendor_order_settings.dart';
import 'package:eventease/features/customer/presentation/views/customer/order_status_screen.dart';
import 'package:eventease/features/vendor/presentation/views/quotation_builder_screen.dart';
import 'package:intl/intl.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_booking_status_update_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomerChatScreen extends StatefulWidget {
  final BaseConversation conversation;
  final Map<String, dynamic>? initialOrderRequest;

  const CustomerChatScreen({
    super.key,
    required this.conversation,
    this.initialOrderRequest,
  });

  @override
  State<CustomerChatScreen> createState() => _CustomerChatScreenState();
}

class _CustomerChatScreenState extends State<CustomerChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Mark conversation as read when opened (only for individual chats)
    if (!widget.conversation.isGroup) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context
            .read<ChatProvider>()
            .markConversationAsRead((widget.conversation as ChatConversation).vendorId);
        
        // If there's an initial order request (e.g., from Product Detail), prefill the message input
        if (widget.initialOrderRequest != null) {
          final notes = widget.initialOrderRequest!['notes'] ?? 'Hi, I would like to inquire about this service.';
          _messageController.text = notes;
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    final authProvider = context.read<AuthProvider>();

    if (widget.conversation.isGroup) {
      context.read<ChatProvider>().sendMessage(
            groupId: widget.conversation.id,
            message: message,
          );
    } else {
      context.read<ChatProvider>().sendMessage(
            vendorId: (widget.conversation as ChatConversation).vendorId,
            message: message,
          );
    }

    _messageController.clear();

    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isVendor = auth.isVendor || auth.isAdmin || auth.isSuperAdmin;
    
    // Additional context check for 1-on-1 chats: identify if current user is the vendor
    bool isConversationVendor = false;
    if (!widget.conversation.isGroup) {
      final conv = widget.conversation as ChatConversation;
      isConversationVendor = auth.userId == conv.vendorId;
    }
    
    final showQuotationTool = isVendor || isConversationVendor;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, _) {
            // Find the updated version of this conversation from the provider
            final currentConv = chatProvider.conversations.firstWhere(
              (c) => c.id == widget.conversation.id,
              orElse: () => widget.conversation,
            );

            return Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      currentConv.avatarText,
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentConv.displayName,
                        style: const TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (currentConv.isGroup)
                        Text(
                          '${(currentConv as GroupChatConversation).members.length} members',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        )
                      else
                        Text(
                          'Vendor',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          if (showQuotationTool)
            IconButton(
              icon: const Icon(Icons.description, color: AppTheme.primaryColor),
              onPressed: _showQuotationDialog,
              tooltip: 'Send Final Quotation',
            ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppTheme.textPrimaryColor),
            onPressed: () => _showChatOptions(showQuotationTool),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final conversation = widget.conversation.isGroup
                    ? chatProvider.getGroupConversation(widget.conversation.id)
                    : chatProvider.getConversationWithVendor((widget.conversation as ChatConversation).vendorId);
                if (conversation == null || conversation.messages.isEmpty) {
                  return _buildEmptyChat();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: conversation.messages.length,
                  itemBuilder: (context, index) {
                    final message = conversation.messages[index];
                    return _buildMessageBubble(message);
                  },
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Action buttons row
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (showQuotationTool) ...[
                              _buildActionButton(
                                icon: Icons.description,
                                label: 'Quotation',
                                onPressed: _showQuotationDialog,
                              ),
                              const SizedBox(width: 8),
                            ],
                            _buildActionButton(
                              icon: Icons.calendar_today,
                              label: 'Schedule',
                              onPressed: _showAppointmentDialog,
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.shopping_cart,
                              label: 'Order',
                              onPressed: _showOrderDialog,
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.call,
                              label: 'Call',
                              onPressed: _showCallDialog,
                            ),
                            const SizedBox(width: 8),
                            _buildActionButton(
                              icon: Icons.share,
                              label: 'Share',
                              onPressed: _shareChat,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Message input row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                              color:
                                  AppTheme.textSecondaryColor.withOpacity(0.6)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: AppTheme.textSecondaryColor
                                    .withOpacity(0.3)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(
                                color: AppTheme.textSecondaryColor
                                    .withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide:
                                const BorderSide(color: AppTheme.primaryColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.conversation.isGroup
                ? 'Start the conversation in ${widget.conversation.displayName}'
                : 'Start the conversation with ${widget.conversation.displayName}',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageBubble(ChatMessage message, bool isFromMe) {
    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        clipBehavior: Clip.antiAlias,
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            message.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: message.imageUrl!,
                    placeholder: (context, url) => Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[100],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.image, size: 100),
            Positioned(
              bottom: 4,
              right: 8,
              child: Text(
                _formatMessageTime(message.timestamp),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentQRBubble(ChatMessage message, bool isFromMe) {
    final amount = message.metadata?['amount'] as double?;
    
    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 2),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text(
                  'Scan to Pay',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!, width: 4),
              ),
              clipBehavior: Clip.antiAlias,
              child: message.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: message.imageUrl!,
                      width: 200,
                      height: 200,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        width: 200,
                        color: Colors.grey[100],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error, size: 50),
                    )
                  : Container(
                      width: 200,
                      height: 200,
                      color: Colors.grey[100],
                      child: const Icon(Icons.qr_code, size: 100, color: Colors.grey),
                    ),
            ),
            if (amount != null && amount > 0) ...[
              const SizedBox(height: 16),
              const Text('Amount Due', style: TextStyle(color: AppTheme.textSecondaryColor)),
              Text(
                'RM ${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatMessageTime(message.timestamp),
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isFromMe = message.senderId == currentUserId;

    // Special handling for specialized message types
    if (message.type == MessageType.orderRequest) {
      return _buildOrderRequestBubble(message, isFromMe);
    } else if (message.type == MessageType.paymentRequest) {
      return _buildPaymentRequestBubble(message, isFromMe);
    } else if (message.type == MessageType.quotation) {
      return _buildQuotationBubble(message, isFromMe);
    } else if (message.type == MessageType.appointmentRequest) {
      return _buildAppointmentRequestBubble(message, isFromMe);
    } else if (message.type == MessageType.image) {
      if (message.metadata?['isPaymentQR'] == true) {
        return _buildPaymentQRBubble(message, isFromMe);
      }
      return _buildImageBubble(message, isFromMe);
    }

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isFromMe ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isFromMe
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
              isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatMessageTime(message.timestamp),
              style: TextStyle(
                color: isFromMe
                    ? Colors.white.withOpacity(0.7)
                    : AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderRequestBubble(ChatMessage message, bool isFromMe) {
    final metadata = message.metadata;
    if (metadata == null) return _buildMessageBubble(message); // Fallback

    final serviceName = metadata['serviceName'] as String? ?? '';
    final quantity = metadata['quantity'] as int? ?? 1;
    final price = metadata['price'] as double? ?? 0.0;
    final tax = (metadata['tax'] as num?)?.toDouble() ?? 0.0;
    final serviceFee = (metadata['serviceFee'] as num?)?.toDouble() ?? 0.0;
    final discount = (metadata['discount'] as num?)?.toDouble() ?? 0.0;
    final totalAmount = (metadata['totalAmount'] as num?)?.toDouble() ?? (quantity * price);

    final notes = metadata['notes'] as String?;
    final eventDateString = metadata['eventDate'] as String?;
    final status = metadata['status'] as String? ?? 'pending';
    final bookingId = metadata['bookingId'] as String?;

    // Parse category from serviceName format: '[category] serviceName'
    final categoryMatch = RegExp(r'^\[([^\]]+)\]').firstMatch(serviceName);
    final category = categoryMatch?.group(1) ?? 'General';
    final actualServiceName = serviceName.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '');
    
    // Get vendor ID from conversation
    final vendorId = (widget.conversation as ChatConversation).vendorId;

    // Find the service to get images
    final vendorServices = VendorServicesData.getServicesByVendor(vendorId);
    final service = vendorServices.firstWhere(
      (s) => s.name == actualServiceName,
      orElse: () => VendorService(
        id: 'temp',
        vendorId: vendorId,
        name: actualServiceName,
        description: '',
        category: EventCategory.values.firstWhere(
          (c) => c.name == category.toLowerCase(),
          orElse: () => EventCategory.venue,
        ),
        basePrice: price,
        types: [ServiceType.product],
        active: true,
        approvalStatus: ApprovalStatus.approved,
        availability: const {},
        maxBookingsPerDay: 1,
        advanceBookingDays: 0,
        images: const [],
        options: const {},
        requirements: const {},
        logistics: const {},
        status: ServiceStatus.active,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        supportsAppointments: true,
        supportsRentals: false,
        allowedActions: const ['book'],
      ),
    );

    // Service images (if available and depending on category)
    final bubbleImageUrl = metadata['imageUrl'] as String?;
    final imagesToShow = bubbleImageUrl != null ? [bubbleImageUrl] : service.images;

    final totalPrice = quantity * price;
    final eventDate = eventDateString != null ? DateTime.parse(eventDateString) : null;

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFromMe ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isFromMe
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: isFromMe ? Colors.white : AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Request',
                  style: TextStyle(
                    color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(status, isFromMe),
              ],
            ),
            const SizedBox(height: 12),

            if (imagesToShow.isNotEmpty && (bubbleImageUrl != null || _shouldShowImages(category))) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: imagesToShow.length,
                  itemBuilder: (context, index) {
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: NetworkImage(imagesToShow[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Service details
            Text(
              actualServiceName,
              style: TextStyle(
                color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),

            // Price Breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isFromMe ? Colors.white.withOpacity(0.1) : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isFromMe ? Colors.white24 : Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  _buildPriceRow('Items ($quantity)', 'RM ${(quantity * price).toStringAsFixed(2)}', isFromMe),
                  if (tax > 0) _buildPriceRow('Tax', 'RM ${tax.toStringAsFixed(2)}', isFromMe),
                  if (serviceFee > 0) _buildPriceRow('Service Fee', 'RM ${serviceFee.toStringAsFixed(2)}', isFromMe),
                  if (discount > 0) _buildPriceRow('Discount', '-RM ${discount.toStringAsFixed(2)}', isFromMe, isDiscount: true),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: TextStyle(
                          color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'RM ${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: isFromMe ? Colors.white : AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Details
            if (eventDate != null)
              _buildDetailItem(Icons.calendar_today, 'Date: ${_formatEventDate(eventDate)}', isFromMe),
            if (metadata['location'] != null && metadata['location'].toString().isNotEmpty)
              _buildDetailItem(Icons.location_on, 'At: ${metadata['location']}', isFromMe),
            if (notes != null && notes.isNotEmpty)
              _buildDetailItem(Icons.notes, notes, isFromMe, isItalic: true),

            // Booking Link
            if (status == 'accepted' && bookingId != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OrderStatusScreen()),
                    );
                  },
                  icon: const Icon(Icons.receipt_long, size: 18),
                  label: const Text('View Booking Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFromMe ? Colors.white : AppTheme.primaryColor,
                    foregroundColor: isFromMe ? AppTheme.primaryColor : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],

            // Timestamp
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatMessageTime(message.timestamp),
                style: TextStyle(
                  color: isFromMe ? Colors.white70 : AppTheme.textSecondaryColor,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationBubble(ChatMessage message, bool isFromMe) {
    final metadata = message.metadata;
    if (metadata == null) return _buildMessageBubble(message);

    final List<dynamic> items = metadata['items'] ?? [];
    final totalAmount = metadata['totalAmount'] as double? ?? 0.0;
    final taxAmount = metadata['taxAmount'] as double? ?? 0.0;
    final serviceFee = metadata['serviceFee'] as double? ?? 0.0;
    final discount = metadata['discount'] as double? ?? 0.0;
    final subtotal = metadata['subtotal'] as double? ?? 0.0;
    final notes = metadata['notes'] as String?;
    final expiryDateString = metadata['expiryDate'] as String?;
    final status = metadata['status'] as String? ?? 'pending';

    final expiryDate = expiryDateString != null ? DateTime.parse(expiryDateString) : null;
    final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFromMe ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isFromMe ? null : Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          boxShadow: isFromMe
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.description,
                  color: isFromMe ? Colors.white : AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Final Quotation',
                  style: TextStyle(
                    color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(isExpired ? 'expired' : status, isFromMe),
              ],
            ),
            const Divider(height: 24, color: Colors.white24),

            // Line Items
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item['description']} x${item['quantity']}',
                      style: TextStyle(
                        color: isFromMe ? Colors.white.withOpacity(0.9) : AppTheme.textSecondaryColor,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    'RM ${(item['total'] as num).toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )),

            const Divider(height: 24, color: Colors.white24),

            // Totals
            _buildPriceRow('Subtotal', 'RM ${subtotal.toStringAsFixed(2)}', isFromMe),
            if (taxAmount > 0) _buildPriceRow('Tax', 'RM ${taxAmount.toStringAsFixed(2)}', isFromMe),
            if (serviceFee > 0) _buildPriceRow('Service Fee', 'RM ${serviceFee.toStringAsFixed(2)}', isFromMe),
            if (discount > 0) _buildPriceRow('Discount', '-RM ${discount.toStringAsFixed(2)}', isFromMe, isDiscount: true),
            
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: TextStyle(
                    color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'RM ${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isFromMe ? Colors.white : AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),

            if (expiryDate != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: isFromMe ? Colors.white70 : Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Valid until: ${DateFormat('yyyy-MM-dd').format(expiryDate)}',
                    style: TextStyle(
                      color: isFromMe ? Colors.white70 : Colors.grey,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],

            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Notes: $notes',
                style: TextStyle(
                  color: isFromMe ? Colors.white.withOpacity(0.8) : AppTheme.textSecondaryColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // Customer Actions
            if (!isFromMe && status == 'pending' && !isExpired) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleAcceptQuotation(message),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Accept & Book Now'),
                ),
              ),
            ],

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatMessageTime(message.timestamp),
                style: TextStyle(
                  color: isFromMe ? Colors.white70 : AppTheme.textSecondaryColor,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool isFromMe, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isFromMe ? Colors.white70 : AppTheme.textSecondaryColor, fontSize: 13)),
          Text(value, style: TextStyle(color: isDiscount ? (isFromMe ? Colors.lightGreenAccent : Colors.green) : (isFromMe ? Colors.white : AppTheme.textPrimaryColor), fontSize: 13, fontWeight: isDiscount ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text, bool isFromMe, {bool isItalic = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isFromMe ? Colors.white70 : AppTheme.textSecondaryColor, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isFromMe ? Colors.white.withOpacity(0.9) : AppTheme.textSecondaryColor,
                fontSize: 13,
                fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRequestBubble(ChatMessage message, bool isFromMe) {
    final metadata = message.metadata;
    final amount = metadata?['amount'] as double? ?? 0.0;
    final description = metadata?['description'] as String? ?? 'Payment Request';
    final status = metadata?['status'] as String? ?? 'unpaid';

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFromMe ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isFromMe
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: isFromMe ? Colors.white : AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Request',
                  style: TextStyle(
                    color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(status, isFromMe),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'RM ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: isFromMe ? Colors.white : AppTheme.primaryColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (!isFromMe && status == 'unpaid')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Logic to open payment gateway
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Pay Now'),
                ),
              ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatMessageTime(message.timestamp),
                style: TextStyle(
                  color: isFromMe ? Colors.white70 : AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentRequestBubble(ChatMessage message, bool isFromMe) {
    final metadata = message.metadata;
    final serviceType = metadata?['serviceType'] as String? ?? 'Consultation';
    final appointmentDateString = metadata?['appointmentDate'] as String?;
    final notes = metadata?['notes'] as String?;
    final duration = metadata?['durationHours'] as int?;
    final status = metadata?['status'] as String? ?? 'pending';

    final appointmentDate = appointmentDateString != null ? DateTime.parse(appointmentDateString) : null;

    return Align(
      alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isFromMe ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isFromMe
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.event,
                  color: isFromMe ? Colors.white : AppTheme.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Appointment Request',
                  style: TextStyle(
                    color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(status, isFromMe),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              serviceType,
              style: TextStyle(
                color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (appointmentDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: isFromMe ? Colors.white70 : AppTheme.textSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${appointmentDate.day}/${appointmentDate.month}/${appointmentDate.year}',
                    style: TextStyle(
                      color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            if (duration != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: isFromMe ? Colors.white70 : AppTheme.textSecondaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$duration Hours',
                    style: TextStyle(
                      color: isFromMe ? Colors.white : AppTheme.textPrimaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: $notes',
                style: TextStyle(
                  color: isFromMe ? Colors.white.withOpacity(0.8) : AppTheme.textSecondaryColor,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (!isFromMe && status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Logic to reject
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isFromMe ? Colors.white : Colors.red,
                        side: BorderSide(color: isFromMe ? Colors.white : Colors.red),
                      ),
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Logic to accept
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFromMe ? Colors.white : AppTheme.primaryColor,
                        foregroundColor: isFromMe ? AppTheme.primaryColor : Colors.white,
                      ),
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                _formatMessageTime(message.timestamp),
                style: TextStyle(
                  color: isFromMe ? Colors.white.withOpacity(0.7) : AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, bool isFromMe) {
    Color statusColor;
    String statusText;

    switch (status.toLowerCase()) {
      case 'accepted':
        statusColor = Colors.green;
        statusText = 'Accepted';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Rejected';
        break;
      case 'expired':
        statusColor = Colors.grey;
        statusText = 'Expired';
        break;
      case 'pending':
      default:
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  bool _shouldShowImages(String category) {
    // Show images for categories that benefit from visual representation
    final imageCategories = ['catering', 'decoration', 'photography', 'entertainment', 'venue'];
    return imageCategories.contains(category.toLowerCase());
  }

  bool _shouldShowDate(String category) {
    // Show date prominently for event-related categories
    final dateCategories = ['venue', 'catering', 'decoration', 'entertainment', 'photography'];
    return dateCategories.contains(category.toLowerCase());
  }

  String _formatEventDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _showChatOptions(bool showQuotationTool) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showQuotationTool)
              ListTile(
                leading: const Icon(Icons.description, color: AppTheme.primaryColor),
                title: const Text('Send Final Quotation'),
                subtitle: const Text('Create a formal payable offer'),
                onTap: () {
                  Navigator.pop(context);
                  _showQuotationDialog();
                },
              ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Vendor Info'),
              onTap: () {
                Navigator.pop(context);
                _showVendorInfo();
              },
            ),
            ListTile(
              leading: const Icon(Icons.clear),
              title: const Text('Clear Chat'),
              onTap: () {
                Navigator.pop(context);
                _clearChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.block),
              title: const Text('Block Vendor'),
              onTap: () {
                Navigator.pop(context);
                _blockVendor();
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: Colors.red),
              title: const Text('Report Vendor', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _reportVendor();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVendorInfo() {
    final chatConversation = widget.conversation as ChatConversation;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vendor Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${chatConversation.vendorName}'),
            Text('Email: ${chatConversation.vendorEmail}'),
            Text(
                'Status: ${chatConversation.isOnline ? 'Online' : 'Offline'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
            'Are you sure you want to clear all messages in this chat?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (widget.conversation.isGroup) {
                // For group chats, we might want to clear messages but keep the group
                // For now, we'll just show a message that group chats can't be cleared
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Group chats cannot be cleared')),
                );
              } else {
                context
                    .read<ChatProvider>()
                    .deleteConversation((widget.conversation as ChatConversation).vendorId);
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to previous screen
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _blockVendor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Vendor'),
        content: const Text(
            'Are you sure you want to block this vendor? You won\'t receive messages from them anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // In a real app, implement blocking functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vendor blocked successfully')),
              );
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _reportVendor() {
    if (widget.conversation.isGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can only report individual vendors')),
      );
      return;
    }

    final chatConversation = widget.conversation as ChatConversation;
    String? selectedReason;
    final TextEditingController descController = TextEditingController();
    bool isSubmitting = false;

    final List<String> reasons = [
      'Scam / Fraud',
      'Inappropriate behaviour',
      'Fake information',
      'Harassment',
      'Poor service / No delivery',
      'Other',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.flag_outlined, color: Colors.red),
              const SizedBox(width: 10),
              Text('Report ${chatConversation.vendorName}'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a reason for your report:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                ...reasons.map((reason) => RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  activeColor: Colors.red,
                  onChanged: (val) => setDialogState(() => selectedReason = val),
                )),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Additional details (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting || selectedReason == null
                  ? null
                  : () async {
                      setDialogState(() => isSubmitting = true);
                      try {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final reportedByUserId = authProvider.userId;
                        if (reportedByUserId == null) throw Exception('Not logged in');

                        // Look up the vendor's auth user ID via their vendor profile ID
                        final vendorProfileResult = await Supabase.instance.client
                            .from('vendor_profiles')
                            .select('user_id')
                            .eq('id', chatConversation.vendorId)
                            .maybeSingle();

                        final reportedUserId = vendorProfileResult?['user_id'] as String?;
                        if (reportedUserId == null) throw Exception('Vendor not found');

                        await Supabase.instance.client.from('reported_users').insert({
                          'reported_user_id': reportedUserId,
                          'reported_by': reportedByUserId,
                          'reason': selectedReason,
                          'description': descController.text.trim().isEmpty
                              ? null
                              : descController.text.trim(),
                          'status': 'pending',
                        });

                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('✅ Report submitted. Our team will review it shortly.'),
                              backgroundColor: Colors.green.shade700,
                            ),
                          );
                        }
                      } catch (e) {
                        print('Report vendor error: \$e');
                        setDialogState(() => isSubmitting = false);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Failed to submit report: \${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit Report'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        foregroundColor: AppTheme.primaryColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  void _showAppointmentDialog({String? prefilledServiceType}) {
    if (widget.conversation.isGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointments can only be scheduled with individual vendors')),
      );
      return;
    }

    final TextEditingController serviceController = TextEditingController(text: prefilledServiceType ?? '');
    final TextEditingController notesController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    int? durationHours;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Schedule Appointment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: serviceController,
                  decoration: const InputDecoration(
                    labelText: 'Service Type',
                    hintText: 'e.g., Wedding Planning, Venue Tour',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Date & Time: '),
                    TextButton(
                      onPressed: () async {
                        final pickedDate = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null) {
                          if (context.mounted) {
                            final pickedTime = await showTimePicker(
                              context: context,
                              initialTime: const TimeOfDay(hour: 10, minute: 0),
                              helpText: 'Select Business Time',
                            );
                            if (pickedTime != null) {
                              setState(() {
                                selectedDate = DateTime(
                                  pickedDate.year,
                                  pickedDate.month,
                                  pickedDate.day,
                                  pickedTime.hour,
                                  pickedTime.minute,
                                );
                              });
                            }
                          }
                        }
                      },
                      child: Text(
                        '${selectedDate.day}/${selectedDate.month}/${selectedDate.year} ${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: durationHours,
                  hint: const Text('Select duration'),
                  decoration: const InputDecoration(labelText: 'Duration (hours)'),
                  items: [1, 2, 3, 4, 5, 6, 8].map((hours) {
                    return DropdownMenuItem(
                      value: hours,
                      child: Text('$hours hours'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => durationHours = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    hintText: 'Any special requirements...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (serviceController.text.isNotEmpty) {
                  context.read<ChatProvider>().sendAppointmentRequest(
                        vendorId: (widget.conversation as ChatConversation).vendorId,
                        appointmentDate: selectedDate,
                        serviceType: serviceController.text,
                        notes: notesController.text.isNotEmpty
                            ? notesController.text
                            : null,
                        durationHours: durationHours,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Appointment request sent!')),
                  );
                }
              },
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDialog({Map<String, dynamic>? initialData}) async {
    if (widget.conversation.isGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orders can only be placed with individual vendors')),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Restrict selection to this vendor's approved services/products
    String vendorId = (widget.conversation as ChatConversation).vendorId;
    String resolvedProfileId = vendorId;

    // Attempt to resolve Profile ID if vendorId is an Auth ID
    try {
      final profileCheck = await Supabase.instance.client
          .from('vendor_profiles')
          .select('id')
          .eq('id', vendorId)
          .maybeSingle();

      if (profileCheck == null) {
        final authCheck = await Supabase.instance.client
            .from('vendor_profiles')
            .select('id')
            .eq('user_id', vendorId)
            .maybeSingle();
        
        if (authCheck != null) {
          resolvedProfileId = authCheck['id'];
        }
      }
    } catch (e) {
      print('DEBUG: Error resolving Profile ID: $e');
    }

    // Load vendor order settings using resolved profile id
    VendorOrderSettings? vendorSettings;
    try {
      final response = await Supabase.instance.client
          .from('vendor_order_settings')
          .select()
          .eq('vendor_id', resolvedProfileId)
          .maybeSingle();
      
      if (response != null) {
        vendorSettings = VendorOrderSettings.fromSupabase(response);
      }
    } catch (e) {
      print('Error loading vendor settings: $e');
    }

    vendorSettings ??= VendorOrderSettings.defaultSettings(resolvedProfileId);

    // Load approved services for this vendor from Supabase using resolved profile id
    List<VendorService> vendorServices = [];
    try {
      final servicesResponse = await Supabase.instance.client
          .from('vendor_services')
          .select()
          .eq('vendor_id', resolvedProfileId)
          .eq('approval_status', 'approved');
      
      if (servicesResponse != null && servicesResponse is List) {
        vendorServices = servicesResponse
            .map((json) {
              try {
                return VendorService.fromJson(json);
              } catch (e) {
                return null;
              }
            })
            .whereType<VendorService>()
            .where((s) => s.active && s.status == ServiceStatus.active) // Strict check to prevent drafts
            .toList();
      }
    } catch (e) {
      print('DEBUG: Error loading vendor services from Supabase: $e');
      // Fallback to mock data if there's an error
      vendorServices = VendorServicesData.getServicesByVendor(vendorId)
          .where((s) => s.approvalStatus.name == 'approved')
          .toList();
    }

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
    }

    if (vendorServices.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This vendor has no available services right now.')),
        );
      }
      return;
    }

    final TextEditingController serviceController = TextEditingController(text: initialData?['serviceName']);
    final TextEditingController quantityController =
        TextEditingController(text: (initialData?['quantity'] ?? vendorSettings.minOrderQuantity).toString());
    final TextEditingController priceController = TextEditingController(text: initialData?['price']?.toString());
    final TextEditingController notesController = TextEditingController(text: initialData?['notes']);
    final TextEditingController deliveryAddressController =
        TextEditingController(text: initialData?['location']);
    final TextEditingController specialRequirementsController =
        TextEditingController();

    String? selectedCategory = initialData?['category'];
    String? deliveryMethod = initialData?['deliveryMethod'] ?? 'Pickup';
    DateTime? eventDate = initialData?['eventDate'];
    TimeOfDay? eventTime = initialData?['eventTime'];
    double totalPrice = (initialData?['price'] ?? 0.0) * (initialData?['quantity'] ?? 1);
    String? selectedImageUrl = initialData?['imageUrl'];
    String? selectedServiceId = initialData?['serviceId'];

    // Derive categories from vendor's services to keep choices in-vendor
    final List<String> categories =
        vendorServices.map((s) => s.category.name).toSet().toList()..sort();

    // Validate initials to prevent dropdown crashes
    if (selectedCategory != null && !categories.contains(selectedCategory)) {
      selectedCategory = null;
    }

    final availableServicesForCategory = vendorServices
        .where((s) => selectedCategory == null || s.category.name == selectedCategory)
        .toList();

    if (serviceController.text.isNotEmpty &&
        !availableServicesForCategory.any((s) => s.name == serviceController.text)) {
      serviceController.text = '';
      priceController.text = '';
      totalPrice = 0.0;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final currentAvailableServices = vendorServices
              .where((s) => selectedCategory == null || s.category.name == selectedCategory)
              .toList();

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.shopping_cart, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                const Text('Place Order'),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Category
                    DropdownButtonFormField<String>(
                      value: categories.contains(selectedCategory) ? selectedCategory : null,
                      hint: const Text('Select a category'),
                      decoration: const InputDecoration(
                        labelText: 'Service Category',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedCategory = value;
                          serviceController.text = '';
                          priceController.text = '';
                          totalPrice = 0.0;
                          selectedImageUrl = null;
                          selectedServiceId = null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Service/Item from this vendor only
                    DropdownButtonFormField<String>(
                      value: serviceController.text.isEmpty ? null : serviceController.text,
                      hint: const Text('Select a service/product'),
                      decoration: const InputDecoration(
                        labelText: 'Service/Item',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      isExpanded: true,
                      items: currentAvailableServices.map((s) => DropdownMenuItem(
                            value: s.name,
                            child: Text(s.name, overflow: TextOverflow.ellipsis),
                          )).toList(),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          serviceController.text = value;
                          final sel = currentAvailableServices.firstWhere((s) => s.name == value);
                          final base = sel.getMinPrice();
                          selectedServiceId = sel.id;
                          priceController.text = base.toStringAsFixed(2);
                          final qty = int.tryParse(quantityController.text) ?? 1;
                          totalPrice = qty * base;
                          selectedImageUrl = sel.images.isNotEmpty ? sel.images.first : null;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Selected Service Image Preview
                    if (selectedImageUrl != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            selectedImageUrl!,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: 120,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),

                    // Quantity and Price Row
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Qty',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => setState(() {
                              final qty = int.tryParse(value) ?? 1;
                              final price = double.tryParse(priceController.text) ?? 0.0;
                              totalPrice = qty * price;
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: priceController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Price (RM)',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Total Price Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Estimated Total:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'RM ${totalPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Event Details
                    const Text('Event Details', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: eventDate ?? DateTime.now().add(const Duration(days: 7)),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (picked != null) setState(() => eventDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              eventDate != null ? '${eventDate!.day}/${eventDate!.month}/${eventDate!.year}' : 'Date',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: eventTime ?? const TimeOfDay(hour: 10, minute: 0),
                              );
                              if (picked != null) setState(() => eventTime = picked);
                            },
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(
                              eventTime != null ? eventTime!.format(context) : 'Time',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Message to vendor (optional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final quantity = int.tryParse(quantityController.text) ?? 1;
                  final price = double.tryParse(priceController.text) ?? 0.0;

                  if (serviceController.text.isNotEmpty && price > 0 && quantity > 0) {
                    final combinedNotes = [
                      if (eventDate != null) 'Event Date: ${eventDate!.day}/${eventDate!.month}/${eventDate!.year}',
                      if (eventTime != null) 'Event Time: ${eventTime!.format(context)}',
                      if (notesController.text.isNotEmpty) 'Notes: ${notesController.text}',
                    ].join('\n');

                    context.read<ChatProvider>().sendOrderRequest(
                          vendorId: resolvedProfileId,
                          serviceId: selectedServiceId ?? 'unknown',
                          serviceName: '[${selectedCategory ?? "Uncategorized"}] ${serviceController.text}',
                          quantity: quantity,
                          price: price,
                          tax: 0.0,
                          serviceFee: 0.0,
                          discount: 0.0,
                          packageName: 'Standard Package',
                          duration: '1 hour',
                          bookingTime: eventTime != null ? '${eventTime!.hour.toString().padLeft(2, '0')}:${eventTime!.minute.toString().padLeft(2, '0')}' : null,
                          location: deliveryMethod,
                          notes: combinedNotes.isNotEmpty ? combinedNotes : null,
                          eventDate: eventDate,
                          imageUrl: selectedImageUrl,
                        );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Order request for ${serviceController.text} sent!'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select a service before sending'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                child: const Text('Send Order'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaymentDialog() {
    final TextEditingController amountController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    String? paymentMethod;
    DateTime? dueDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Request Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Amount (RM)',
                    hintText: 'e.g., 500.00',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What is this payment for?',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: paymentMethod,
                  decoration: const InputDecoration(
                      labelText: 'Payment Method (optional)'),
                  items: [
                    'Online Banking',
                    'Credit Card',
                    'Cash',
                    'Bank Transfer'
                  ].map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => paymentMethod = value),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Due Date (optional): '),
                    TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dueDate ??
                              DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 90)),
                        );
                        if (picked != null) {
                          setState(() => dueDate = picked);
                        }
                      },
                      child: Text(
                        dueDate != null
                            ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                            : 'Select Date',
                        style: const TextStyle(color: AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text) ?? 0.0;

                if (amount > 0 && descriptionController.text.isNotEmpty) {
                  context.read<ChatProvider>().sendPaymentRequest(
                        vendorId: (widget.conversation as ChatConversation).vendorId,
                        amount: amount,
                        description: descriptionController.text,
                        paymentMethod: paymentMethod,
                        dueDate: dueDate,
                      );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payment request sent!')),
                  );
                }
              },
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCallDialog() {
    if (widget.conversation.isGroup) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calls can only be made with individual vendors')),
      );
      return;
    }

    final chatConversation = widget.conversation as ChatConversation;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.call, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Call Vendor'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Call ${chatConversation.vendorName}?'),
            const SizedBox(height: 8),
            Text(
              'This will initiate a call with the vendor.',
              style: TextStyle(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // In a real app, implement calling functionality (e.g., using url_launcher for phone call)
              // For now, show a placeholder message
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${chatConversation.vendorName}...'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            icon: const Icon(Icons.call),
            label: const Text('Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _shareChat() {
    final String shareText = widget.conversation.isGroup
        ? 'Check out this group chat: ${widget.conversation.displayName} on EventEase!'
        : 'Check out this vendor: ${widget.conversation.displayName} on EventEase!';

    Share.share(shareText, subject: 'EventEase Chat');
  }

  void _showQuotationDialog() async {
    final chatConversation = widget.conversation as ChatConversation;
    
    // Navigate to Quotation Builder
    final metadata = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => QuotationBuilderScreen(
          customerId: chatConversation.customerId,
          customerName: chatConversation.customerName,
          vendorId: chatConversation.vendorId,
        ),
      ),
    );

    if (metadata != null) {
      // Send the quotation via ChatProvider
      context.read<ChatProvider>().sendQuotation(
        vendorId: metadata['vendorId'],
        customerId: metadata['customerId'],
        items: List<Map<String, dynamic>>.from(metadata['items']),
        totalAmount: metadata['totalAmount'],
        taxAmount: metadata['taxAmount'],
        taxRate: metadata['taxRate'],
        serviceFee: metadata['serviceFee'],
        discount: metadata['discount'],
        subtotal: metadata['subtotal'],
        notes: metadata['notes'],
        expiryDate: metadata['expiryDate'] != null ? DateTime.parse(metadata['expiryDate']) : null,
        serviceId: metadata['serviceId'],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Final Quotation sent successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _handleAcceptQuotation(ChatMessage message) async {
    final metadata = message.metadata;
    if (metadata == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Quotation'),
        content: const Text('Are you sure you want to accept this quotation and proceed to booking?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Accept & Book'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 1. Update Quotation Status
    final updatedMetadata = Map<String, dynamic>.from(metadata);
    updatedMetadata['status'] = 'accepted';
    
    // 2. Create Booking
    final bookingProvider = context.read<BookingProvider>();
    final newBooking = Booking(
      id: const Uuid().v4(),
      vendorId: metadata['vendorId'],
      customerId: metadata['customerId'],
      serviceId: metadata['serviceId'] ?? '',
      serviceName: 'Quotation Order',
      customerName: widget.conversation.customerName,
      customerPhone: '',
      customerEmail: '',
      bookingDate: DateTime.now().add(const Duration(days: 30)), // Placeholder
      bookingTime: const TimeOfDay(hour: 10, minute: 0),
      duration: 'Standard',
      packageName: 'Full Package',
      amount: metadata['totalAmount'],
      location: '',
      notes: metadata['notes'] ?? 'Order from Quotation',
      status: BookingStatus.awaitingPayment,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      selectedOptions: {'quotation_items': metadata['items']},
    );

    try {
      await bookingProvider.addBooking(newBooking);
      
      // Update the message metadata in ChatProvider
      await context.read<ChatProvider>().updateMessageMetadata(message.id, updatedMetadata);
      
      // Optional: Add a system message or notification
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quotation accepted! Booking created.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
