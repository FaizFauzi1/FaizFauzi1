import 'package:eventease/features/support/data/models/support_ticket.dart';
import 'package:eventease/features/support/data/providers/support_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class SupportAgentDashboard extends StatefulWidget {
  const SupportAgentDashboard({super.key});

  @override
  State<SupportAgentDashboard> createState() => _SupportAgentDashboardState();
}

class _SupportAgentDashboardState extends State<SupportAgentDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedStatus = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final supportProvider = Provider.of<SupportProvider>(context);
    final stats = supportProvider.getTicketStats();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Support Agent Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'My Tickets'),
            Tab(text: 'All Tickets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(stats),
          _buildMyTicketsTab(),
          _buildAllTicketsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, int> stats) {
    final supportProvider = Provider.of<SupportProvider>(context);
    final categoryStats = supportProvider.getTicketsByCategory();
    final priorityStats = supportProvider.getTicketsByPriority();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Tickets',
                  stats['total'].toString(),
                  Icons.confirmation_number,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Open Tickets',
                  stats['open'].toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'In Progress',
                  stats['inProgress'].toString(),
                  Icons.work,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Resolved',
                  stats['resolved'].toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Tickets by Category
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
                  'Tickets by Category',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ...categoryStats.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          entry.key.toString().split('.').last.toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Tickets by Priority
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
                  'Tickets by Priority',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ...priorityStats.entries.map((entry) {
                  Color priorityColor;
                  switch (entry.key) {
                    case TicketPriority.low:
                      priorityColor = Colors.green;
                      break;
                    case TicketPriority.medium:
                      priorityColor = Colors.orange;
                      break;
                    case TicketPriority.high:
                      priorityColor = Colors.red;
                      break;
                    case TicketPriority.urgent:
                      priorityColor = Colors.purple;
                      break;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.circle,
                              size: 12,
                              color: priorityColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.key.toString().split('.').last.toUpperCase(),
                              style: const TextStyle(
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: priorityColor,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Actions
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
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showBulkAssignDialog(),
                        icon: const Icon(Icons.assignment),
                        label: const Text('Bulk Assign'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _generateReport(),
                        icon: const Icon(Icons.analytics),
                        label: const Text('Generate Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
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

  Widget _buildMyTicketsTab() {
    final supportProvider = Provider.of<SupportProvider>(context);
    List<SupportTicket> myTickets = supportProvider.assignedTickets;

    // Filter tickets based on search, status, and priority
    myTickets = supportProvider.filterTickets(
      myTickets,
      status: _selectedStatus == 'All' ? null : TicketStatus.values.firstWhere((e) => e.name == _selectedStatus),
      priority: _selectedFilter == 'All' ? null : TicketPriority.values.firstWhere((e) => e.name == _selectedFilter),
    );

    if (_searchController.text.isNotEmpty) {
      myTickets = myTickets.where((ticket) =>
        ticket.subject.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        ticket.description.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        ticket.customerName.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

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
                  hintText: 'Search tickets...',
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
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['All', 'open', 'inProgress', 'resolved', 'closed']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedStatus = value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFilter,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['All', 'low', 'medium', 'high', 'urgent']
                          .map((priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedFilter = value!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Tickets List
        Expanded(
          child: myTickets.isEmpty
              ? _buildEmptyState('No assigned tickets', 'Tickets assigned to you will appear here')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: myTickets.length,
                  itemBuilder: (context, index) {
                    return _buildTicketCard(myTickets[index], true);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAllTicketsTab() {
    final supportProvider = Provider.of<SupportProvider>(context);

    // Filter tickets based on search, status, and priority
    List<SupportTicket> filteredTickets = supportProvider.filterTickets(
      supportProvider.tickets,
      status: _selectedStatus == 'All' ? null : TicketStatus.values.firstWhere((e) => e.name == _selectedStatus),
      priority: _selectedFilter == 'All' ? null : TicketPriority.values.firstWhere((e) => e.name == _selectedFilter),
    );

    if (_searchController.text.isNotEmpty) {
      filteredTickets = filteredTickets.where((ticket) =>
        ticket.subject.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        ticket.description.toLowerCase().contains(_searchController.text.toLowerCase()) ||
        ticket.customerName.toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

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
                  hintText: 'Search all tickets...',
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
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['All', 'open', 'inProgress', 'resolved', 'closed']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedStatus = value!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFilter,
                      decoration: InputDecoration(
                        labelText: 'Priority',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: ['All', 'low', 'medium', 'high', 'urgent']
                          .map((priority) => DropdownMenuItem(
                                value: priority,
                                child: Text(priority.toUpperCase()),
                              ))
                          .toList(),
                      onChanged: (value) => setState(() => _selectedFilter = value!),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Tickets List
        Expanded(
          child: filteredTickets.isEmpty
              ? _buildEmptyState('No tickets found', 'Try adjusting your search or filters')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredTickets.length,
                  itemBuilder: (context, index) {
                    return _buildTicketCard(filteredTickets[index], false);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket, bool isMyTicket) {
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

    Color priorityColor;
    switch (ticket.priority) {
      case TicketPriority.low:
        priorityColor = Colors.green;
        break;
      case TicketPriority.medium:
        priorityColor = Colors.orange;
        break;
      case TicketPriority.high:
        priorityColor = Colors.red;
        break;
      case TicketPriority.urgent:
        priorityColor = Colors.purple;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showTicketDetails(ticket, isMyTicket),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
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
                  if (ticket.subject == 'Live Support Session') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 8),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    ticket.customerName,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.category, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 4),
                  Text(
                    ticket.category.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.flag, size: 16, color: priorityColor),
                  const SizedBox(width: 4),
                  Text(
                    ticket.priority.toString().split('.').last.toUpperCase(),
                    style: TextStyle(
                      color: priorityColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(ticket.createdAt),
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (isMyTicket && ticket.assignedAgentName != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.assignment_ind, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      'Assigned to: ${ticket.assignedAgentName}',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
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
        ],
      ),
    );
  }

  void _showBulkAssignDialog() {
    final supportProvider = Provider.of<SupportProvider>(context, listen: false);
    final unassignedTickets = supportProvider.unassignedTickets;
    final selectedTickets = <String>{};

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Bulk Assign Tickets'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unassignedTickets.isEmpty)
                  const Text('No unassigned tickets available')
                else ...[
                  const Text('Select tickets to assign:'),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: unassignedTickets.length,
                      itemBuilder: (context, index) {
                        final ticket = unassignedTickets[index];
                        return CheckboxListTile(
                          title: Text(ticket.subject),
                          subtitle: Text(ticket.customerName),
                          value: selectedTickets.contains(ticket.id),
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                selectedTickets.add(ticket.id);
                              } else {
                                selectedTickets.remove(ticket.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            if (unassignedTickets.isNotEmpty)
              ElevatedButton(
                onPressed: selectedTickets.isEmpty
                    ? null
                    : () {
                        // Use the real authenticated user ID
                        final user = SupabaseService.client.auth.currentUser;
                        final agentId = user?.id ?? '00000000-0000-0000-0000-000000000000';
                        final agentName = user?.userMetadata?['full_name'] ?? 'Support Agent';

                        for (final ticketId in selectedTickets) {
                          supportProvider.assignTicket(ticketId, agentId, agentName);
                        }

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${selectedTickets.length} tickets assigned successfully'),
                          ),
                        );
                      },
                child: const Text('Assign'),
              ),
          ],
        ),
      ),
    );
  }

  void _generateReport() {
    final supportProvider = Provider.of<SupportProvider>(context, listen: false);
    final stats = supportProvider.getTicketStats();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support Report'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Tickets: ${stats['total']}'),
              Text('Open Tickets: ${stats['open']}'),
              Text('In Progress: ${stats['inProgress']}'),
              Text('Resolved: ${stats['resolved']}'),
              Text('Unassigned: ${stats['unassigned']}'),
              const SizedBox(height: 16),
              Text('Average Resolution Time: ${supportProvider.getAverageResolutionTime().toStringAsFixed(1)} hours'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // In a real app, this would generate and download a PDF report
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report generated successfully')),
              );
              Navigator.pop(context);
            },
            child: const Text('Download Report'),
          ),
        ],
      ),
    );
  }

  void _showTicketDetails(SupportTicket ticket, bool isMyTicket) {
    final TextEditingController messageController = TextEditingController();
    final ScrollController scrollController = ScrollController();
    bool showFullDetails = false;

    // Auto-scroll to bottom after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.92,
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header Bar & Handle
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 8),
                  height: 4,
                  width: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // AppBar-like Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.subject,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                            Text(
                              'Ticket #${ticket.id.substring(0, 8)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setModalState(() => showFullDetails = !showFullDetails);
                        },
                        icon: Icon(
                          showFullDetails ? Icons.info : Icons.info_outline,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Collapsible Details Section
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  height: showFullDetails ? null : 0,
                  child: showFullDetails
                      ? Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.grey[50],
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('Customer', ticket.customerName),
                              _buildInfoRow('Email', ticket.customerEmail),
                              _buildInfoRow('Category', ticket.category.toString().split('.').last.toUpperCase()),
                              _buildInfoRow('Priority', ticket.priority.toString().split('.').last.toUpperCase()),
                              _buildInfoRow('Status', ticket.status.toString().split('.').last.toUpperCase()),
                              const SizedBox(height: 8),
                              const Text(
                                'Initial Description:',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                ticket.description,
                                style: TextStyle(color: Colors.grey[700], fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              
                              // Status Update Dropdown in Details
                              DropdownButtonFormField<TicketStatus>(
                                value: ticket.status,
                                decoration: InputDecoration(
                                  labelText: 'Update Status',
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: TicketStatus.values.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(status.toString().split('.').last.toUpperCase()),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    final supportProvider = Provider.of<SupportProvider>(context, listen: false);
                                    supportProvider.updateTicketStatus(ticket.id, value);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Ticket status updated')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),

                // Messages List (Immersive)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      itemCount: ticket.messages.length,
                      itemBuilder: (context, index) {
                        final message = ticket.messages[index];
                        return _buildMessageBubble(message);
                      },
                    ),
                  ),
                ),

                // Reply Area
                if (isMyTicket || ticket.assignedAgentId == null)
                  Container(
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -2),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: messageController,
                            decoration: InputDecoration(
                              hintText: 'Type your message...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                            maxLines: 4,
                            minLines: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () async {
                            if (messageController.text.trim().isNotEmpty) {
                              final user = SupabaseService.client.auth.currentUser;
                              if (user == null) return;
                              
                              final supportProvider = Provider.of<SupportProvider>(context, listen: false);
                                try {
                                  if (ticket.assignedAgentId == null) {
                                    await supportProvider.assignTicket(
                                      ticket.id, 
                                      user.id, 
                                      user.userMetadata?['full_name'] ?? 'Support Agent'
                                    );
                                  }

                                  final message = SupportMessage(
                                    id: const Uuid().v4(),
                                    senderId: user.id,
                                    senderName: user.userMetadata?['full_name'] ?? 'Support Agent',
                                    message: messageController.text.trim(),
                                    timestamp: DateTime.now(),
                                    isFromCustomer: false,
                                  );

                                  await supportProvider.addMessageToTicket(ticket.id, message);
                                  messageController.clear();
                                  
                                  // Scroll to bottom
                                  Future.delayed(const Duration(milliseconds: 100), () {
                                    if (scrollController.hasClients) {
                                      scrollController.animateTo(
                                        scrollController.position.maxScrollExtent,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  });
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Failed to reply: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                            }
                          },
                          child: Container(
                            height: 48,
                            width: 48,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Text(
                      'This ticket is assigned to another agent.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(SupportMessage message) {
    final bool isFromCustomer = message.isFromCustomer;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment: isFromCustomer ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          // Name label
          Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 12, right: 12),
            child: Text(
              isFromCustomer ? message.senderName : 'You',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          Row(
            mainAxisAlignment: isFromCustomer ? MainAxisAlignment.start : MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (isFromCustomer) 
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Text(
                    message.senderName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isFromCustomer ? Colors.white : AppTheme.primaryColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isFromCustomer ? 4 : 16),
                      bottomRight: Radius.circular(isFromCustomer ? 16 : 4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.message,
                        style: TextStyle(
                          color: isFromCustomer ? AppTheme.textPrimaryColor : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          fontSize: 9,
                          color: isFromCustomer 
                              ? Colors.grey[400] 
                              : Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (!isFromCustomer)
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: AppTheme.primaryColor,
                  child: Icon(Icons.person, size: 14, color: Colors.white),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
