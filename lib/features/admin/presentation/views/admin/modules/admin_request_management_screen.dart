import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/support/data/providers/request_provider.dart';
import 'package:eventease/features/support/data/models/customer_request.dart';
import 'package:eventease/features/admin/data/providers/admin_marketplace_provider.dart';
import 'package:eventease/features/admin/data/services/admin_marketplace_service.dart';
import 'package:eventease/features/admin/presentation/widgets/admin_entity_detail_dialog.dart';

class AdminRequestManagementScreen extends StatefulWidget {
  const AdminRequestManagementScreen({super.key});

  @override
  State<AdminRequestManagementScreen> createState() => _AdminRequestManagementScreenState();
}

class _AdminRequestManagementScreenState extends State<AdminRequestManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _caseFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RequestProvider>(context, listen: false).loadRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mktProvider = Provider.of<AdminMarketplaceProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Customer Requests & Case Management'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.assignment_late_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Active Support Cases (${mktProvider.supportCases.length})'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.request_quote_outlined, size: 18),
                  SizedBox(width: 8),
                  Text('Custom Event Requests'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCasesTab(mktProvider),
          _buildLegacyRequestsTab(),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: OPERATIONAL SUPPORT CASES
  // ==========================================
  Widget _buildCasesTab(AdminMarketplaceProvider mktProvider) {
    var cases = mktProvider.supportCases;

    if (_caseFilter == 'Urgent') {
      cases = cases.where((c) => c.priority == 'Urgent' || c.status == 'Escalated').toList();
    } else if (_caseFilter == 'Payment') {
      cases = cases.where((c) => c.category == 'Payment Problem').toList();
    } else if (_caseFilter == 'Vendor Issue') {
      cases = cases.where((c) => c.category == 'Vendor Issue').toList();
    } else if (_caseFilter == 'Resolved') {
      cases = cases.where((c) => c.status == 'Resolved').toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      cases = cases
          .where((c) =>
              c.id.toLowerCase().contains(q) ||
              c.subject.toLowerCase().contains(q) ||
              c.customerName.toLowerCase().contains(q) ||
              c.vendorName.toLowerCase().contains(q) ||
              c.bookingId.toLowerCase().contains(q))
          .toList();
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // Filter & Search Header
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search cases by ID, customer, vendor, booking...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCaseFilterChip('All', mktProvider.supportCases.length),
                      const SizedBox(width: 8),
                      _buildCaseFilterChip('Urgent', mktProvider.supportCases.where((c) => c.priority == 'Urgent').length, badgeColor: Colors.red),
                      const SizedBox(width: 8),
                      _buildCaseFilterChip('Payment', mktProvider.supportCases.where((c) => c.category == 'Payment Problem').length, badgeColor: Colors.orange),
                      const SizedBox(width: 8),
                      _buildCaseFilterChip('Vendor Issue', mktProvider.supportCases.where((c) => c.category == 'Vendor Issue').length, badgeColor: Colors.purple),
                      const SizedBox(width: 8),
                      _buildCaseFilterChip('Resolved', mktProvider.supportCases.where((c) => c.status == 'Resolved').length, badgeColor: Colors.green),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cases List
          Padding(
            padding: const EdgeInsets.all(16),
            child: cases.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No support cases found for this filter.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cases.length,
                    itemBuilder: (context, idx) {
                      final item = cases[idx];
                      return _buildCaseCard(item, mktProvider);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaseFilterChip(String label, int count, {Color? badgeColor}) {
    final isSelected = _caseFilter == label;
    return InkWell(
      onTap: () => setState(() => _caseFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : (badgeColor?.withOpacity(0.15) ?? Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : (badgeColor ?? Colors.black87),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseCard(AdminSupportCase caseItem, AdminMarketplaceProvider mktProvider) {
    Color statusColor = Colors.orange;
    if (caseItem.status == 'Resolved') statusColor = Colors.green;
    if (caseItem.status == 'Escalated') statusColor = Colors.red;
    if (caseItem.status == 'Waiting for Vendor') statusColor = Colors.purple;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Case ID, Priority, Status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(caseItem.id, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                _buildPriorityBadge(caseItem.priority),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    caseItem.status,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Subject & Category
            Text(
              caseItem.subject,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Category: ${caseItem.category}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Text(
                  'Assigned: ${caseItem.assignedAdmin}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Connected Entity Relationships
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _buildEntityChip(Icons.person_outline, caseItem.customerName, MarketplaceEntityType.customer),
                  _buildEntityChip(Icons.storefront_outlined, caseItem.vendorName, MarketplaceEntityType.vendor),
                  _buildEntityChip(Icons.bookmark_outline, caseItem.bookingId, MarketplaceEntityType.booking),
                  _buildEntityChip(Icons.event_outlined, caseItem.eventName, MarketplaceEntityType.event),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // Internal Notes Snippet
            if (caseItem.internalNotes.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Internal Note: ${caseItem.internalNotes}',
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Actions: Timeline & Relationships
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCaseTimelineDialog(context, caseItem),
                    icon: const Icon(Icons.timeline, size: 16),
                    label: Text('Activity Timeline (${caseItem.timeline.length})', style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AdminEntityDetailDialog.show(
                        context,
                        type: MarketplaceEntityType.supportCase,
                        entityId: caseItem.id,
                        entityName: caseItem.subject,
                        customerName: caseItem.customerName,
                        vendorName: caseItem.vendorName,
                        bookingId: caseItem.bookingId,
                        status: caseItem.status,
                      );
                    },
                    icon: const Icon(Icons.hub_outlined, size: 16),
                    label: const Text('Relationships', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.teal.shade800),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    Color color = Colors.grey;
    if (priority == 'Urgent') color = Colors.red;
    if (priority == 'High') color = Colors.orange;
    if (priority == 'Normal') color = Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
      child: Text(
        priority.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEntityChip(IconData icon, String text, MarketplaceEntityType type) {
    return InkWell(
      onTap: () {
        AdminEntityDetailDialog.show(
          context,
          type: type,
          entityId: text,
          entityName: text,
        );
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: Colors.grey.shade700),
            const SizedBox(width: 4),
            Text(text, style: TextStyle(fontSize: 11, color: Colors.blue.shade800, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showCaseTimelineDialog(BuildContext context, AdminSupportCase caseItem) {
    showDialog(
      context: context,
      builder: (context) {
        final noteController = TextEditingController();
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            title: Row(
              children: [
                const Icon(Icons.support_agent_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${caseItem.id} — ${caseItem.subject}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('Category: ${caseItem.category} • Priority: ${caseItem.priority}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                _buildPriorityBadge(caseItem.priority),
              ],
            ),
            content: SizedBox(
              width: 580,
              height: 520,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Customer: ${caseItem.customerName}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              Text('Vendor: ${caseItem.vendorName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Booking: ${caseItem.bookingId}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                              Text('Event: ${caseItem.eventName}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Text('CASE ACTIVITY & RESOLUTION TIMELINE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: caseItem.timeline.length,
                      itemBuilder: (context, idx) {
                        final item = caseItem.timeline[idx];
                        final isLast = idx == caseItem.timeline.length - 1;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: item.role == 'Customer'
                                      ? Colors.blue.shade100
                                      : (item.role == 'Vendor' ? Colors.purple.shade100 : Colors.green.shade100),
                                  child: Icon(
                                    item.role == 'Customer'
                                        ? Icons.person
                                        : (item.role == 'Vendor' ? Icons.store : Icons.shield),
                                    size: 14,
                                    color: item.role == 'Customer'
                                        ? Colors.blue
                                        : (item.role == 'Vendor' ? Colors.purple : Colors.green),
                                  ),
                                ),
                                if (!isLast) Container(width: 2, height: 40, color: Colors.grey.shade300),
                              ],
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text('${item.actor} (${item.role})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                        const Spacer(),
                                        Text(DateFormat('dd MMM HH:mm').format(item.timestamp), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(item.action, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.primaryColor)),
                                    const SizedBox(height: 2),
                                    Text(item.details, style: const TextStyle(fontSize: 12, color: Colors.black87)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: noteController,
                          decoration: const InputDecoration(
                            hintText: 'Add internal case note or action...',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          if (noteController.text.trim().isNotEmpty) {
                            Provider.of<AdminMarketplaceProvider>(context, listen: false).addCaseTimelineItem(
                              caseItem.id,
                              AdminCaseTimelineItem(
                                actor: 'Admin Team',
                                role: 'Admin',
                                action: 'Internal Note Added',
                                details: noteController.text.trim(),
                                timestamp: DateTime.now(),
                              ),
                            );
                            setDialogState(() {});
                            noteController.clear();
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                        child: const Text('Add Note'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                  AdminEntityDetailDialog.show(
                    context,
                    type: MarketplaceEntityType.supportCase,
                    entityId: caseItem.id,
                    entityName: caseItem.subject,
                    customerName: caseItem.customerName,
                    vendorName: caseItem.vendorName,
                    bookingId: caseItem.bookingId,
                    status: caseItem.status,
                  );
                },
                child: const Text('Inspect Relationships'),
              ),
              if (caseItem.status != 'Resolved')
                ElevatedButton(
                  onPressed: () {
                    Provider.of<AdminMarketplaceProvider>(context, listen: false).updateCaseStatus(caseItem.id, 'Resolved');
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${caseItem.id} marked as Resolved!'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Resolve Case'),
                ),
            ],
          ),
        );
      },
    );
  }

  // ==========================================
  // TAB 2: CUSTOM EVENT REQUESTS
  // ==========================================
  Widget _buildLegacyRequestsTab() {
    return Consumer<RequestProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.requests.isEmpty) {
          return const Center(
            child: Text('No custom event requests found.', style: TextStyle(color: AppTheme.textSecondaryColor)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.requests.length,
          itemBuilder: (context, index) {
            final request = provider.requests[index];
            return _buildAdminRequestCard(context, request, provider);
          },
        );
      },
    );
  }

  Widget _buildAdminRequestCard(BuildContext context, CustomerRequest request, RequestProvider provider) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    request.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _buildLegacyStatusChip(request.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${request.eventCategory.displayName} • ${request.eventType}',
              style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 4),
            Text('Date: ${request.eventDate.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Budget: RM ${request.budget.toStringAsFixed(2)}',
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
            const SizedBox(height: 12),
            Text(
              request.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.location,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _confirmDelete(context, request, provider),
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegacyStatusChip(RequestStatus status) {
    Color color;
    switch (status) {
      case RequestStatus.pending: color = Colors.orange; break;
      case RequestStatus.offered: color = Colors.blue; break;
      case RequestStatus.accepted: color = Colors.green; break;
      case RequestStatus.rejected: color = Colors.red; break;
      case RequestStatus.completed: color = Colors.purple; break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _confirmDelete(BuildContext context, CustomerRequest request, RequestProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Delete'),
        content: const Text('Are you sure you want to remove this request permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await provider.deleteRequest(request.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request deleted by admin')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
