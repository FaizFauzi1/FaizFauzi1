import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/features/support/data/models/support_ticket.dart';
import 'package:eventease/features/support/data/providers/support_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class VendorSupportTicketsScreen extends StatefulWidget {
  const VendorSupportTicketsScreen({super.key});

  @override
  State<VendorSupportTicketsScreen> createState() => _VendorSupportTicketsScreenState();
}

class _VendorSupportTicketsScreenState extends State<VendorSupportTicketsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  
  // Create Ticket State
  final _createTicketFormKey = GlobalKey<FormState>();
  String _subject = '';
  String _description = '';
  TicketCategory _category = TicketCategory.general;
  TicketPriority _priority = TicketPriority.medium;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Support Tickets', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'My Tickets'),
            Tab(text: 'Create Ticket'),
            Tab(text: 'Help Center'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyTicketsTab(),
          _buildCreateTicketTab(),
          _buildHelpCenterTab(),
        ],
      ),
    );
  }

  Widget _buildMyTicketsTab() {
    final supportProvider = Provider.of<SupportProvider>(context);
    final tickets = supportProvider.myTickets;

    return Column(
      children: [
        // Filter tabs
        _buildFilterTabs(tickets),

        // Tickets list
        Expanded(
          child: supportProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : tickets.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: tickets.length,
                      itemBuilder: (context, index) => _buildTicketCard(tickets[index]),
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterTabs(List<SupportTicket> tickets) {
    final filters = ['All', 'Open', 'In Progress', 'Resolved'];

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter;
            final count = filter == 'All'
                ? tickets.length
                : tickets.where((t) => t.status.toString().split('.').last == filter.replaceAll(' ', '')).length;

            return Container(
              margin: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text('$filter ($count)'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter);
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                checkmarkColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket) {
    final statusColor = _getStatusColor(ticket.status);
    final priorityColor = _getPriorityColor(ticket.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Status indicator
              Container(
                width: 12,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),

              // Ticket details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ticket.subject,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ticket.priority.toString().split('.').last.toUpperCase(),
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket.description,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'ID: ${ticket.id.substring(0, 8)}',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          DateFormat('MMM dd, yyyy').format(ticket.createdAt),
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          ticket.category.toString().split('.').last.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  ticket.status.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewTicketDetails(ticket),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View Details'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addMessage(ticket),
                  icon: const Icon(Icons.message, size: 16),
                  label: const Text('Reply'),
                ),
              ),
            ],
          ),
        ],
      ),
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
              style: TextStyle(color: AppTheme.textSecondaryColor),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                        customerName: user.userMetadata?['full_name'] ?? 'Vendor',
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

                        _tabController.animateTo(0); // Switch to My Tickets tab
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

  Widget _buildHelpCenterTab() {
    final supportProvider = Provider.of<SupportProvider>(context);
    final faqs = supportProvider.faqs;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: faqs.length,
      itemBuilder: (context, index) {
        final faq = faqs[index];
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
                  style: const TextStyle(color: AppTheme.textPrimaryColor),
                ),
              ),
            ],
            onExpansionChanged: (expanded) {
              if (expanded) {
                supportProvider.incrementFAQViewCount(faq.id);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
          const Text(
            'No support tickets yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first ticket to get help',
            style: TextStyle(color: AppTheme.textSecondaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _tabController.animateTo(1),
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

  Color _getStatusColor(TicketStatus status) {
    switch (status) {
      case TicketStatus.open:
        return Colors.orange;
      case TicketStatus.inProgress:
        return Colors.blue;
      case TicketStatus.resolved:
        return Colors.green;
      case TicketStatus.closed:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(TicketPriority priority) {
    switch (priority) {
      case TicketPriority.urgent:
        return Colors.red;
      case TicketPriority.high:
        return Colors.orange;
      case TicketPriority.medium:
        return Colors.blue;
      case TicketPriority.low:
        return Colors.green;
    }
  }

  void _viewTicketDetails(SupportTicket ticket) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTicketDetailsSheet(ticket),
    );
  }

  Widget _buildTicketDetailsSheet(SupportTicket ticket) {
    final messageController = TextEditingController();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    ticket.subject,
                    style: const TextStyle(
                      fontSize: 18,
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
          ),

          // Messages
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: ticket.messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(ticket.messages[index]),
            ),
          ),

          // Reply input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton(
                  onPressed: () async {
                    if (messageController.text.trim().isEmpty) return;

                    final supportProvider = Provider.of<SupportProvider>(context, listen: false);
                    final user = SupabaseService.client.auth.currentUser;
                    
                    if (user != null) {
                      final message = SupportMessage(
                        id: '',
                        senderId: user.id,
                        senderName: user.userMetadata?['full_name'] ?? 'Vendor',
                        message: messageController.text.trim(),
                        timestamp: DateTime.now(),
                        isFromCustomer: true,
                      );

                      await supportProvider.addMessageToTicket(ticket.id, message);
                      messageController.clear();
                    }
                  },
                  mini: true,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage message) {
    final isFromUser = message.isFromCustomer;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isFromUser ? AppTheme.primaryColor : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.message,
                  style: TextStyle(
                    color: isFromUser ? Colors.white : AppTheme.textPrimaryColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, hh:mm a').format(message.timestamp),
                  style: TextStyle(
                    color: isFromUser ? Colors.white.withOpacity(0.7) : AppTheme.textSecondaryColor,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addMessage(SupportTicket ticket) {
    _viewTicketDetails(ticket);
  }
}
