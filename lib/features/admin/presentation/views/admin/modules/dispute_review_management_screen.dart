import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/admin_dispute_detail_screen.dart';

/// Enhanced Admin Disputes / Reviews / Appeals Management
class AdminDisputeReviewManagementScreen extends StatefulWidget {
  const AdminDisputeReviewManagementScreen({super.key});

  @override
  State<AdminDisputeReviewManagementScreen> createState() =>
      _AdminDisputeReviewManagementScreenState();
}

class _AdminDisputeReviewManagementScreenState
    extends State<AdminDisputeReviewManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // Search / filter / sort
  String _searchQuery = '';
  String _statusFilter = 'All';
  String _severityFilter = 'All';
  String _sortBy = 'Newest';

  // Bulk selection
  final Set<String> _selectedIds = {};
  bool _bulkMode = false;

  // quick lists for UI
  final List<String> _statusOptions = ['All', 'Open', 'Pending', 'Resolved', 'Dismissed', 'Approved', 'Rejected'];
  final List<String> _severityOptions = ['All', 'Low', 'Medium', 'High', 'Critical'];
  final List<String> _sortOptions = ['Newest', 'Oldest', 'Severity', 'Most Comments'];

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

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) _selectedIds.remove(id);
      else _selectedIds.add(id);
      _bulkMode = _selectedIds.isNotEmpty;
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _bulkMode = false;
    });
  }

  void _performBulkAction(String action, AdminProvider admin, String tabKey) async {
    if (_selectedIds.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$action selected items'),
        content: Text('Are you sure you want to $action ${_selectedIds.length} selected items?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      for (final id in _selectedIds) {
        if (tabKey == 'disputes') {
          if (action == 'Resolve') admin.resolveDispute(id);
          if (action == 'Dismiss') admin.dismissDispute(id);
          if (action == 'Escalate') admin.escalateDispute(id);
        } else if (tabKey == 'reviews') {
          if (action == 'Approve') admin.approveReview(id);
          if (action == 'Reject') admin.rejectReview(id);
        } else if (tabKey == 'appeals') {
          if (action == 'Approve') admin.approveAppeal(id);
          if (action == 'Reject') admin.rejectAppeal(id);
        }
      }

      _showSnack('Bulk action completed', Colors.green);
      _clearSelection();
    } catch (e) {
      _showSnack('Bulk action failed: $e', Colors.red);
    }
  }

  void _showSnack(String message, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: bg));
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Disputes / Reviews / Appeals', style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Disputes', icon: Icon(Icons.gavel)),
            Tab(text: 'Reviews', icon: Icon(Icons.reviews)),
            Tab(text: 'Appeals', icon: Icon(Icons.flag)),
          ],
        ),
        actions: [
          if (_bulkMode)
            IconButton(
              tooltip: 'Clear selection',
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
            ),
        ],
      ),

      body: Column(
        children: [
          // Search + Filters row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Search
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by id, user, vendor or message...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                // Status filter
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _statusFilter,
                    items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                    decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    onChanged: (v) => setState(() => _statusFilter = v ?? 'All'),
                  ),
                ),
                // Severity filter
                SizedBox(
                  width: 140,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _severityFilter,
                    items: _severityOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                    decoration: const InputDecoration(labelText: 'Severity', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    onChanged: (v) => setState(() => _severityFilter = v ?? 'All'),
                  ),
                ),
                // Sort
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _sortBy,
                    items: _sortOptions.map((s) => DropdownMenuItem(value: s, child: Text(s, overflow: TextOverflow.ellipsis))).toList(),
                    decoration: const InputDecoration(labelText: 'Sort', border: OutlineInputBorder(), isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                    onChanged: (v) => setState(() => _sortBy = v ?? 'Newest'),
                  ),
                ),
              ],
            ),
          ),

          // Bulk action bar if in bulk mode
          if (_bulkMode)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${_selectedIds.length} selected', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Resolve / Approve'),
                  onPressed: () {
                    final tabKey = _activeTabKey();
                    _performBulkAction(tabKey == 'reviews' ? 'Approve' : 'Resolve', admin, tabKey);
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Reject / Dismiss'),
                  onPressed: () {
                    final tabKey = _activeTabKey();
                    _performBulkAction(tabKey == 'reviews' ? 'Reject' : 'Dismiss', admin, tabKey);
                  },
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  icon: const Icon(Icons.priority_high, size: 18),
                  label: const Text('Escalate'),
                  onPressed: () {
                    final tabKey = _activeTabKey();
                    _performBulkAction('Escalate', admin, tabKey);
                  },
                ),
              ],
            ),
            ),

          // Content area
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDisputesList(admin),
                _buildReviewsList(admin),
                _buildAppealsList(admin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _activeTabKey() {
    final idx = _tabController.index;
    if (idx == 0) return 'disputes';
    if (idx == 1) return 'reviews';
    return 'appeals';
  }

  /// ---------------- Disputes ----------------
  Widget _buildDisputesList(AdminProvider admin) {
    var list = admin.disputes.toList();

    list = _applyFilters(list, (d) => true,
        statusGetter: (d) => d.status,
        severityGetter: (d) => d.severity,
        commentsGetter: (d) => d.comments.length,
        idGetter: (d) => d.caseId,
        summaryGetter: (d) => d.parties + ' ' + d.note);

    return _buildListForGeneric(
      items: list,
      itemBuilder: (d) => _disputeCard(d, admin),
      emptyMessage: 'No disputes found',
    );
  }

  Widget _disputeCard(dynamic dispute, AdminProvider admin) {
    final id = dispute.caseId;
    final status = dispute.status;
    final severity = dispute.severity;
    final created = DateTime.now();
    final commentsCount = dispute.comments.length;

    final isSelected = _selectedIds.contains(id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () => _openDisputeDetail(dispute, admin),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Checkbox(value: isSelected, onChanged: (_) => _toggleSelect(id)),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
              child: const Icon(Icons.gavel, color: AppTheme.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Case #$id', style: const TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(dispute.parties, style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  Wrap(
                    runSpacing: 4,
                    spacing: 8,
                    children: [
                      _statusChip(status),
                      Chip(label: Text('Severity: $severity'), backgroundColor: _severityColor(severity).withOpacity(0.12)),
                      Chip(label: Text('$commentsCount comments')),
                      Text(_formatDate(created), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _openDisputeDetail(dispute, admin),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'resolve') _confirmAndPerform(() async => admin.resolveDispute(dispute.caseId), 'Resolve dispute');
                    if (v == 'dismiss') _confirmAndPerform(() async => admin.dismissDispute(dispute.caseId), 'Dismiss dispute');
                    if (v == 'escalate') _confirmAndPerform(() async => admin.escalateDispute(dispute.caseId), 'Escalate dispute');
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'resolve', child: Text('Resolve')),
                    const PopupMenuItem(value: 'dismiss', child: Text('Dismiss')),
                    const PopupMenuItem(value: 'escalate', child: Text('Escalate')),
                  ],
                ),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  /// ---------------- Reviews ----------------
  Widget _buildReviewsList(AdminProvider admin) {
    var list = admin.reviewQueue.toList();

    list = _applyFilters(list, (r) => true,
        statusGetter: (r) => 'pending',
        severityGetter: (r) => 'Low',
        commentsGetter: (r) => 0,
        idGetter: (r) => r.id,
        summaryGetter: (r) => r.reason);

    return _buildListForGeneric(items: list, itemBuilder: (r) => _reviewCard(r, admin), emptyMessage: 'No reviews awaiting moderation');
  }

  Widget _reviewCard(dynamic review, AdminProvider admin) {
    final id = review.id;
    final title = review.reviewer;
    final reason = review.reason;
    final created = DateTime.now();
    final isSelected = _selectedIds.contains(id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Checkbox(value: isSelected, onChanged: (_) => _toggleSelect(id)),
          const SizedBox(width: 8),
          CircleAvatar(backgroundColor: AppTheme.primaryColor.withOpacity(0.12), child: const Icon(Icons.reviews, color: AppTheme.primaryColor)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(reason, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [const Chip(label: Text('Pending')), Text(_formatDate(created), style: const TextStyle(color: Colors.grey))]),
            ]),
          ),
          Column(children: [
            IconButton(icon: const Icon(Icons.visibility), onPressed: () => _openReviewDetail(review, admin)),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'approve') _confirmAndPerform(() async => admin.approveReview(review.id), 'Approve review');
                if (v == 'reject') _confirmAndPerform(() async => admin.rejectReview(review.id), 'Reject review');
              },
              itemBuilder: (_) => [const PopupMenuItem(value: 'approve', child: Text('Approve')), const PopupMenuItem(value: 'reject', child: Text('Reject'))],
            ),
          ],)
        ]),
      ),
    );
  }

  /// ---------------- Appeals ----------------
  Widget _buildAppealsList(AdminProvider admin) {
    var list = admin.appeals.toList();

    list = _applyFilters(list, (a) => true,
        statusGetter: (a) => a.status,
        severityGetter: (a) => 'Low',
        commentsGetter: (a) => a.comments.length,
        idGetter: (a) => a.caseId,
        summaryGetter: (a) => a.reason);

    return _buildListForGeneric(items: list, itemBuilder: (a) => _appealCard(a, admin), emptyMessage: 'No appeals found');
  }

  Widget _appealCard(dynamic appeal, AdminProvider admin) {
    final id = appeal.caseId;
    final status = appeal.status;
    final created = DateTime.now();
    final isSelected = _selectedIds.contains(id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Checkbox(value: isSelected, onChanged: (_) => _toggleSelect(id)),
          const SizedBox(width: 8),
          CircleAvatar(backgroundColor: AppTheme.primaryColor.withOpacity(0.12), child: const Icon(Icons.flag, color: AppTheme.primaryColor)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Appeal #$id', style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(appeal.reason, style: TextStyle(color: Colors.grey[700])),
              const SizedBox(height: 6),
              Wrap(spacing: 8, children: [_statusChip(status), Text(_formatDate(created), style: const TextStyle(color: Colors.grey))]),
            ]),
          ),
          Column(children: [
            IconButton(icon: const Icon(Icons.visibility), onPressed: () => _openAppealDetail(appeal, admin)),
            PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'approve') _confirmAndPerform(() async => admin.approveAppeal(appeal.caseId), 'Approve appeal');
                if (v == 'reject') _confirmAndPerform(() async => admin.rejectAppeal(appeal.caseId), 'Reject appeal');
              },
              itemBuilder: (_) => [const PopupMenuItem(value: 'approve', child: Text('Approve')), const PopupMenuItem(value: 'reject', child: Text('Reject'))],
            ),
          ])
        ]),
      ),
    );
  }

  /// Generic list helper
  Widget _buildListForGeneric<T>({required List<T> items, required Widget Function(T) itemBuilder, required String emptyMessage}) {
    if (items.isEmpty) {
      return Center(child: Text(emptyMessage, style: TextStyle(color: Colors.grey[600])));
    }
    return RefreshIndicator(
      onRefresh: () async {
        await Future.delayed(const Duration(milliseconds: 300));
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, idx) => itemBuilder(items[idx]),
      ),
    );
  }

  /// ------------ Detail dialogs ------------
  void _openDisputeDetail(dynamic dispute, AdminProvider admin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminDisputeDetailScreen(disputeId: dispute.caseId),
      ),
    );
  }

  void _openDisputeDetailDialog(dynamic dispute, AdminProvider admin) {
    final id = dispute.caseId;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const Icon(Icons.gavel, size: 28, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Dispute #$id', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Parties: ${dispute.parties}', style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text('Status: ${dispute.status}'),
                      const SizedBox(height: 8),
                      Text('Severity: ${dispute.severity}'),
                      const SizedBox(height: 12),
                      const Text('Description:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(dispute.note, style: const TextStyle(color: Colors.black87)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                    ElevatedButton(
                      onPressed: () => _confirmAndPerform(() async => admin.escalateDispute(dispute.caseId), 'Escalate dispute'),
                      child: const Text('Escalate'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => _confirmAndPerform(() async => admin.dismissDispute(dispute.caseId), 'Dismiss dispute'),
                      child: const Text('Dismiss'),
                    ),
                    ElevatedButton(
                      onPressed: () => _confirmAndPerform(() async => admin.resolveDispute(dispute.caseId), 'Resolve dispute'),
                      child: const Text('Resolve'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReviewDetail(dynamic review, AdminProvider admin) {
    final id = review.id;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12), 
                child: Row(children: [
                  const Icon(Icons.reviews, color: AppTheme.primaryColor), 
                  const SizedBox(width: 12), 
                  Expanded(child: Text('Review $id', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), 
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                ])
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Reviewer: ${review.reviewer}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text('Reason: ${review.reason}'),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                    ElevatedButton(onPressed: () => _confirmAndPerform(() async => admin.approveReview(review.id), 'Approve review'), child: const Text('Approve')),
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => _confirmAndPerform(() async => admin.rejectReview(review.id), 'Reject review'), child: const Text('Reject')),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _openAppealDetail(dynamic appeal, AdminProvider admin) {
    final id = appeal.caseId;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
        child: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12), 
                child: Row(children: [
                  const Icon(Icons.flag, color: AppTheme.primaryColor), 
                  const SizedBox(width: 12), 
                  Expanded(child: Text('Appeal #$id', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), 
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
                ])
              ),
              const Divider(height: 1),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Status: ${appeal.status}', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    const Text('Reason:', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Text(appeal.reason, style: const TextStyle(color: Colors.black87)),
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
                    ElevatedButton(onPressed: () => _confirmAndPerform(() async => admin.approveAppeal(appeal.caseId), 'Approve appeal'), child: const Text('Approve')),
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => _confirmAndPerform(() async => admin.rejectAppeal(appeal.caseId), 'Reject appeal'), child: const Text('Reject')),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _confirmAndPerform(Future<void> Function() action, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: const Text('Are you sure you want to proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await action();
      _showSnack('Operation completed', Colors.green);
    } catch (e) {
      _showSnack('Operation failed: $e', Colors.red);
    }
  }

  List<T> _applyFilters<T>(
    List<T> list,
    bool Function(T) baseFilter, {
    required String Function(T) statusGetter,
    required String Function(T) severityGetter,
    required int Function(T) commentsGetter,
    required String Function(T) idGetter,
    required String Function(T) summaryGetter,
  }) {
    var filtered = list.where((it) {
      if (!_matchesSearch(it, idGetter, summaryGetter)) return false;
      if (_statusFilter != 'All') {
        final s = statusGetter(it).toLowerCase();
        if (s != _statusFilter.toLowerCase()) return false;
      }
      if (_severityFilter != 'All') {
        final sev = severityGetter(it).toLowerCase();
        if (sev != _severityFilter.toLowerCase()) return false;
      }
      return baseFilter(it);
    }).toList();

    switch (_sortBy) {
      case 'Severity':
        filtered.sort((a, b) => _severityRank(severityGetter(b)).compareTo(_severityRank(severityGetter(a))));
        break;
      case 'Most Comments':
        filtered.sort((a, b) => commentsGetter(b).compareTo(commentsGetter(a)));
        break;
      default:
    }

    return filtered;
  }

  bool _matchesSearch<T>(T it, String Function(T) idGetter, String Function(T) summaryGetter) {
    if (_searchQuery.trim().isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return idGetter(it).toString().toLowerCase().contains(q) || summaryGetter(it).toLowerCase().contains(q);
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.deepOrange;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  int _severityRank(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return 4;
      case 'high':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }

  Widget _statusChip(String status) {
    final normalized = status.toLowerCase();
    Color color = Colors.grey;
    if (normalized.contains('open') || normalized.contains('pending')) color = Colors.orange;
    if (normalized.contains('resolved') || normalized.contains('approved')) color = Colors.green;
    if (normalized.contains('rejected') || normalized.contains('dismissed')) color = Colors.red;

    return Chip(label: Text(status, style: const TextStyle(color: Colors.white)), backgroundColor: color);
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
