import 'package:eventease/features/support/data/models/support_ticket.dart';
import 'package:eventease/features/support/data/providers/support_provider.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class CustomerSupportScreen extends StatefulWidget {
  final bool autoStartLiveChat;
  const CustomerSupportScreen({super.key, this.autoStartLiveChat = false});

  @override
  State<CustomerSupportScreen> createState() => _CustomerSupportScreenState();
}

class _CustomerSupportScreenState extends State<CustomerSupportScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  
  // Create Ticket State
  final _createTicketFormKey = GlobalKey<FormState>();
  String _subject = '';
  String _description = '';
  TicketCategory _category = TicketCategory.general;
  TicketPriority _priority = TicketPriority.medium;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Auto-start live chat if requested from previous screen
    if (widget.autoStartLiveChat) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startLiveChat();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Customer Support'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Help Center'),
            Tab(text: 'My Tickets'),
            Tab(text: 'Create Ticket'),
            Tab(text: 'Contact Us'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHelpCenterTab(),
          _buildMyTicketsTab(),
          _buildCreateTicketTab(),
          _buildContactUsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickHelpDialog(),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.help, color: Colors.white),
      ),
    );
  }

  Widget _buildHelpCenterTab() {
    final supportProvider = Provider.of<SupportProvider>(context);
    final faqs = _selectedCategory == 'All'
        ? supportProvider.faqs
        : supportProvider.filterFAQsByCategory(
            TicketCategory.values.firstWhere(
              (c) => c.toString().split('.').last == _selectedCategory.toLowerCase(),
              orElse: () => TicketCategory.general,
            ),
          );

    return Column(
      children: [
        // Search and Filter
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search FAQs...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('All'),
                    _buildCategoryChip('Booking'),
                    _buildCategoryChip('Payment'),
                    _buildCategoryChip('Vendor'),
                    _buildCategoryChip('Technical'),
                    _buildCategoryChip('General'),
                  ],
                ),
              ),
            ],
          ),
        ),

        // FAQ List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final faq = faqs[index];
              return _buildFAQCard(faq);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMyTicketsTab() {
    final supportProvider = Provider.of<SupportProvider>(context);
    final tickets = supportProvider.myTickets;
    final isLoading = supportProvider.isLoading;

    return Column(
      children: [
        // Ticket Stats
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildTicketStatCard(
                  'Open',
                  supportProvider.openTicketsCount.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTicketStatCard(
                  'In Progress',
                  supportProvider.inProgressTickets.length.toString(),
                  Icons.work,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildTicketStatCard(
                  'Resolved',
                  supportProvider.resolvedTicketsCount.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
        ),

        // Tickets List
        Expanded(
          child: isLoading 
              ? const Center(child: CircularProgressIndicator())
              : tickets.isEmpty
                  ? _buildEmptyState('No support tickets yet', 'Create your first ticket to get help')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) {
                        return _buildTicketCard(tickets[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCreateTicketTab() {
    final supportProvider = Provider.of<SupportProvider>(context);
    final isCreating = supportProvider.isCreatingTicket;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _createTicketFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isCreating)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: AppTheme.primaryColor,
              ),
            const SizedBox(height: 8),
            const Text(
              'Create Support Ticket',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Describe your issue and we\'ll get back to you as soon as possible.',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),

            // Category
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TicketCategory>(
              value: _category,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: TicketCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(cat.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
              onChanged: isCreating ? null : (value) => setState(() => _category = value!),
            ),

            const SizedBox(height: 16),

            // Priority
            const Text(
              'Priority',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<TicketPriority>(
              value: _priority,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: TicketPriority.values.map((pri) {
                return DropdownMenuItem(
                  value: pri,
                  child: Text(pri.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
              onChanged: isCreating ? null : (value) => setState(() => _priority = value!),
            ),

            const SizedBox(height: 16),

            // Subject
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Subject',
                hintText: 'Brief description of your issue',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a subject';
                }
                return null;
              },
              onSaved: (value) => _subject = value!,
              enabled: !isCreating,
            ),

            const SizedBox(height: 16),

            // Description
            TextFormField(
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Detailed description of your issue',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
              onSaved: (value) => _description = value!,
              enabled: !isCreating,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isCreating ? null : () async {
                  if (_createTicketFormKey.currentState!.validate()) {
                    _createTicketFormKey.currentState!.save();

                    // Get current user from Supabase
                    final user = SupabaseService.client.auth.currentUser;
                    if (user == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please log in to create a support ticket')),
                      );
                      return;
                    }

                    try {
                      await supportProvider.createTicket(
                        customerId: user.id,
                        customerName: user.userMetadata?['full_name'] ?? 'User',
                        customerEmail: user.email ?? '',
                        subject: _subject,
                        description: _description,
                        category: _category,
                        priority: _priority,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Support ticket created successfully!')),
                        );

                        _tabController.animateTo(1); // Switch to My Tickets tab
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error creating ticket: $e')),
                        );
                      }
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isCreating 
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Ticket'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactUsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Us',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Get in touch with our support team',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),

          // Contact Methods
          _buildContactCard(
            'Live Chat',
            'Chat with our support agents',
            Icons.chat,
            Colors.green,
            () => _startLiveChat(),
          ),

          _buildContactCard(
            'Phone Support',
            '+60 3-1234 5678',
            Icons.phone,
            Colors.blue,
            () => _callSupport(),
          ),

          _buildContactCard(
            'Email Support',
            'support@eventease.com',
            Icons.email,
            Colors.orange,
            () => _emailSupport(),
          ),

          _buildContactCard(
            'WhatsApp',
            '+60 12-345 6789',
            Icons.message,
            Colors.green,
            () => _whatsappSupport(),
          ),

          const SizedBox(height: 32),

          // Business Hours
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Business Hours',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBusinessHour('Monday - Friday', '9:00 AM - 6:00 PM'),
                _buildBusinessHour('Saturday', '10:00 AM - 4:00 PM'),
                _buildBusinessHour('Sunday', 'Closed'),
                const SizedBox(height: 16),
                const Text(
                  'Response Time: Within 24 hours',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: AppTheme.primaryColor.withOpacity(0.2),
        checkmarkColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildFAQCard(FAQItem faq) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          faq.question,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          faq.category.toString().split('.').last.toUpperCase(),
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 12,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              faq.answer,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
        onExpansionChanged: (expanded) {
          if (expanded) {
            final supportProvider = Provider.of<SupportProvider>(context, listen: false);
            supportProvider.incrementFAQViewCount(faq.id);
          }
        },
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    Color statusColor;
    IconData statusIcon;

    switch (ticket.status) {
      case TicketStatus.open:
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case TicketStatus.inProgress:
        statusColor = Colors.blue;
        statusIcon = Icons.work;
        break;
      case TicketStatus.resolved:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case TicketStatus.closed:
        statusColor = Colors.grey;
        statusIcon = Icons.close;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(
          ticket.subject,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status: ${ticket.status.toString().split('.').last.toUpperCase()}',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
              ),
            ),
            Text(
              'Created: ${_formatDate(ticket.createdAt)}',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _showTicketDetails(ticket),
      ),
    );
  }

  Widget _buildTicketStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildBusinessHour(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
            ),
          ),
          Text(
            hours,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.support_agent,
            size: 80,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _tabController.animateTo(2), // Switch to Create Ticket tab
            icon: const Icon(Icons.add),
            label: const Text('Create Ticket'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showTicketDetails(SupportTicket ticket) {
    final TextEditingController messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ticket.subject,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTicketInfoRow('Status', ticket.status.toString().split('.').last.toUpperCase()),
              _buildTicketInfoRow('Category', ticket.category.toString().split('.').last.toUpperCase()),
              _buildTicketInfoRow('Priority', ticket.priority.toString().split('.').last.toUpperCase()),
              _buildTicketInfoRow('Created', _formatDate(ticket.createdAt)),
              if (ticket.assignedAgentName != null)
                _buildTicketInfoRow('Assigned to', ticket.assignedAgentName!),
              const SizedBox(height: 16),
              const Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ticket.description,
                style: const TextStyle(
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Messages',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: ticket.messages.length,
                  itemBuilder: (context, index) {
                    final message = ticket.messages[index];
                    return _buildMessageBubble(message);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your reply...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (messageController.text.trim().isNotEmpty) {
                        final supportProvider = Provider.of<SupportProvider>(context, listen: false);
                        final message = SupportMessage(
                          id: Uuid().v4(),
                          senderId: ticket.customerId,
                          senderName: ticket.customerName,
                          message: messageController.text.trim(),
                          timestamp: DateTime.now(),
                          isFromCustomer: true,
                        );
                        supportProvider.addMessageToTicket(ticket.id, message);
                        messageController.clear();
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildTicketInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage message) {
    final isFromCustomer = message.isFromCustomer;
    return Align(
      alignment: isFromCustomer ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isFromCustomer ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: isFromCustomer ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDate(message.timestamp),
              style: TextStyle(
                color: isFromCustomer ? Colors.white70 : AppTheme.textSecondaryColor,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Help'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Browse FAQs'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Create Ticket'),
              onTap: () {
                Navigator.pop(context);
                _tabController.animateTo(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Live Chat'),
              onTap: () {
                Navigator.pop(context);
                _startLiveChat();
              },
            ),
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

  Future<void> _startLiveChat() async {
    final supportProvider = Provider.of<SupportProvider>(context, listen: false);
    final user = SupabaseService.client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to start a live chat')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Connecting to live support...')),
    );

    try {
      // 1. Check if there's an existing open "Live Support Session"
      SupportTicket? chatTicket;
      try {
        chatTicket = supportProvider.myTickets.firstWhere(
          (t) => t.subject == 'Live Support Session' && 
                 (t.status == TicketStatus.open || t.status == TicketStatus.inProgress),
        );
      } catch (_) {
        // No existing ticket found
      }

      // 2. If not found, create a new one
      if (chatTicket == null) {
        chatTicket = await supportProvider.createTicket(
          customerId: user.id,
          customerName: user.userMetadata?['full_name'] ?? 'User',
          customerEmail: user.email ?? '',
          subject: 'Live Support Session',
          description: 'User started a new live chat session.',
          category: TicketCategory.general,
          priority: TicketPriority.medium,
        );
      }

      // 3. Open the chat modal
      if (mounted && chatTicket != null) {
        _showTicketDetails(chatTicket);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start live chat: $e')),
        );
      }
    }
  }

  void _callSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Calling support...')),
    );
  }

  void _emailSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening email client...')),
    );
  }

  void _whatsappSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening WhatsApp...')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
