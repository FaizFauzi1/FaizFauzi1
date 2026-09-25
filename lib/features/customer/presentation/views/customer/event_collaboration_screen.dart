import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/event/data/models/event_collaborator.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/budget/data/providers/budget_provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/shared/models/planner_models.dart';
import 'package:share_plus/share_plus.dart';

class EventCollaborationScreen extends StatefulWidget {
  final String eventId;

  const EventCollaborationScreen({super.key, required this.eventId});

  @override
  State<EventCollaborationScreen> createState() => _EventCollaborationScreenState();
}

class _EventCollaborationScreenState extends State<EventCollaborationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  CollaboratorRole _selectedRole = CollaboratorRole.coHost;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAllEventData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _loadAllEventData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final budgetProvider = Provider.of<BudgetProvider>(context, listen: false);
      eventProvider.loadCollaborators(widget.eventId);
      eventProvider.loadEventDetails(widget.eventId);
      budgetProvider.loadBudgetForEvent(widget.eventId);
    });
  }

  String _getRoleDescription(CollaboratorRole role) {
    switch (role) {
      case CollaboratorRole.coHost:
        return 'Can manage all aspects of the event, including guests, budget, and vendors.';
      case CollaboratorRole.planner:
        return 'Can manage timeline, vendors, and checklist. Cannot delete the event.';
      case CollaboratorRole.vendor:
        return 'Can view timeline and specific logistics related to vendors.';
      case CollaboratorRole.viewer:
        return 'Can only view event details. No editing permissions.';
    }
  }

  void _inviteViaEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final code = EventCollaborator.generateCode();
      final collabo = EventCollaborator(
        eventId: widget.eventId,
        email: email,
        role: _selectedRole,
        inviteCode: code,
      );

      await Provider.of<EventProvider>(context, listen: false).addCollaborator(collabo);
      
      _emailController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collaborator invitation sent successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error inviting collaborator: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _generateInviteCode() async {
    setState(() => _isLoading = true);
    try {
      final code = EventCollaborator.generateCode();
      final collabo = EventCollaborator(
        eventId: widget.eventId,
        role: _selectedRole,
        inviteCode: code,
      );

      await Provider.of<EventProvider>(context, listen: false).addCollaborator(collabo);
      
      if (mounted) {
        _showCodeDialog(code);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating code: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Invitation Code Generated', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this 6-digit code with your collaborator to join:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
              ),
              child: Text(
                code,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppTheme.primaryColor),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Share.share('Join my event planning team on EventEase! Enter this code: $code');
              Navigator.pop(ctx);
            },
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Share Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _updateRole(EventCollaborator collaborator, CollaboratorRole newRole) async {
    try {
      final updated = collaborator.copyWith(role: newRole);
      await Provider.of<EventProvider>(context, listen: false).updateCollaborator(updated);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated to ${newRole.displayName}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating role: $e')),
        );
      }
    }
  }

  void _removeCollaborator(EventCollaborator collaborator) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Collaborator'),
        content: Text('Are you sure you want to remove ${collaborator.email ?? 'this collaborator'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await Provider.of<EventProvider>(context, listen: false).removeCollaborator(collaborator.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Collaborator removed')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing collaborator: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Co-Host & Collaboration Hub',
          style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Team & Permissions', icon: Icon(Icons.people)),
            Tab(text: 'Shared Checklist', icon: Icon(Icons.checklist_rtl)),
            Tab(text: 'Budget Splits', icon: Icon(Icons.pie_chart_outline)),
            Tab(text: 'Vendor Shortlist', icon: Icon(Icons.how_to_vote_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamTab(),
          _buildChecklistTab(),
          _buildBudgetSplitTab(),
          _buildVendorShortlistTab(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB 1: Team & Permissions (Supabase Loaded)
  // ─────────────────────────────────────────────────────────
  Widget _buildTeamTab() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        final collaborators = eventProvider.getCollaboratorsForEvent(widget.eventId);

        return RefreshIndicator(
          onRefresh: () async {
            await eventProvider.loadCollaborators(widget.eventId);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInviteSection(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Active Collaborators (${collaborators.length})',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => eventProvider.loadCollaborators(widget.eventId),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (collaborators.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.group_add_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No collaborators invited yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Invite your spouse, co-host, or planner above to start planning together.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: collaborators.length,
                    itemBuilder: (context, index) => _buildCollaboratorCard(collaborators[index]),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInviteSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invite Team Member',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Role: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<CollaboratorRole>(
                  value: _selectedRole,
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: CollaboratorRole.values.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role.displayName, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _getRoleDescription(_selectedRole),
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Collaborator Email',
              hintText: 'partner@example.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _inviteViaEmail,
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('Send Invite'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : _generateInviteCode,
                icon: const Icon(Icons.qr_code, size: 16),
                label: const Text('Get Code'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCollaboratorCard(EventCollaborator c) {
    final title = c.email ?? c.userId ?? 'Joined via Code';
    final isPending = c.status == CollaboratorStatus.pending;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isPending ? Colors.amber.shade100 : Colors.green.shade100,
            child: Icon(
              isPending ? Icons.hourglass_empty : Icons.check,
              color: isPending ? Colors.amber.shade800 : Colors.green.shade700,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                if (c.inviteCode != null && isPending) ...[
                  Text('Code: ${c.inviteCode}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 2),
                ],
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        c.role.displayName,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue.shade800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      c.status.displayName,
                      style: TextStyle(
                        fontSize: 11,
                        color: isPending ? Colors.orange : Colors.green,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'remove') {
                _removeCollaborator(c);
              } else if (value.startsWith('role_')) {
                final roleName = value.split('_')[1];
                final newRole = CollaboratorRole.values.firstWhere((r) => r.name == roleName);
                _updateRole(c, newRole);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'role_coHost', child: Text('Make Co-Host')),
              const PopupMenuItem(value: 'role_planner', child: Text('Make Planner')),
              const PopupMenuItem(value: 'role_vendor', child: Text('Make Vendor')),
              const PopupMenuItem(value: 'role_viewer', child: Text('Make Viewer')),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove Collaborator', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB 2: Shared Checklist (Real Supabase persistence)
  // ─────────────────────────────────────────────────────────
  Widget _buildChecklistTab() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        final checklists = eventProvider.getChecklistForEvent(widget.eventId);

        return RefreshIndicator(
          onRefresh: () async {
            await eventProvider.loadEventDetails(widget.eventId);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shared Checklist (${checklists.where((c) => c.isDone).length}/${checklists.length})',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddChecklistDialog(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Task'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (checklists.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.checklist, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text(
                        'No checklist tasks created yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Tap "Add Task" to create shared deliverables for your team.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                )
              else
                ...checklists.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: item.isDone,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (val) {
                          final updated = item.copyWith(isDone: val ?? false);
                          eventProvider.updateChecklistItem(updated);
                        },
                      ),
                      title: Text(
                        item.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: item.isDone ? TextDecoration.lineThrough : null,
                          color: item.isDone ? Colors.grey : AppTheme.textPrimaryColor,
                        ),
                      ),
                      subtitle: Text(
                        '${item.category} ${item.dueDate != null ? '• Due ${DateFormat('d MMM yyyy').format(item.dueDate!)}' : ''}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                        onPressed: () => eventProvider.deleteChecklistItem(item.id),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  void _showAddChecklistDialog(BuildContext context) {
    final titleController = TextEditingController();
    String selectedCategory = 'General';
    DateTime? selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Shared Task', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Task Title',
                  hintText: 'e.g. Confirm Halal catering menu',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: ['General', 'Venue', 'Catering', 'Photography', 'Florist', 'Attire', 'Music'].map((cat) {
                        return DropdownMenuItem(value: cat, child: Text(cat));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedCategory = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 730)),
                      );
                      if (picked != null) setModalState(() => selectedDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      selectedDate != null ? DateFormat('d MMM').format(selectedDate!) : 'Due Date',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  final text = titleController.text.trim();
                  if (text.isEmpty) return;

                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final item = ChecklistItem(
                    id: const Uuid().v4(),
                    eventId: widget.eventId,
                    userId: authProvider.userId ?? '',
                    title: text,
                    category: selectedCategory,
                    dueDate: selectedDate,
                    isDone: false,
                    createdAt: DateTime.now(),
                  );

                  Provider.of<EventProvider>(context, listen: false).addChecklistItem(item);
                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Save Task to Supabase', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB 3: Budget Splits (Real Supabase Budget Provider)
  // ─────────────────────────────────────────────────────────
  Widget _buildBudgetSplitTab() {
    return Consumer2<EventProvider, BudgetProvider>(
      builder: (context, eventProvider, budgetProvider, _) {
        final event = eventProvider.getEventById(widget.eventId);
        final budget = budgetProvider.getBudgetForEvent(widget.eventId);

        final totalBudget = budget?.totalBudget ?? ((event?.additionalInfo['budget'] as num?)?.toDouble() ?? 0.0);
        final totalSpent = budget?.spentBudget ?? 0.0;
        final remaining = totalBudget - totalSpent;
        final currency = (event?.additionalInfo['currency'] as String?) ?? 'RM';

        return RefreshIndicator(
          onRefresh: () async {
            await budgetProvider.loadBudgetForEvent(widget.eventId);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Real Budget Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Event Budget', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      '$currency ${totalBudget.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: totalBudget > 0 ? (totalSpent / totalBudget).clamp(0.0, 1.0) : 0.0,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          totalSpent > totalBudget ? Colors.redAccent : Colors.greenAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent: $currency ${totalSpent.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Remaining: $currency ${remaining.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Category Allocations from Supabase',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 10),

              if (budget == null || budget.categories.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'No budget categories configured yet for this event.',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  ),
                )
              else
                ...budget.categories.map((cat) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text(
                          '$currency ${cat.allocatedAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // TAB 4: Vendor Shortlist & Voting (Real Event State)
  // ─────────────────────────────────────────────────────────
  Widget _buildVendorShortlistTab() {
    return Consumer<EventProvider>(
      builder: (context, eventProvider, _) {
        final event = eventProvider.getEventById(widget.eventId);
        final vendorIds = (event?.additionalInfo['vendorIds'] as List?)?.cast<String>() ?? (event?.tags ?? []);

        return RefreshIndicator(
          onRefresh: () async {
            await eventProvider.loadEventDetails(widget.eventId);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Shortlisted Event Vendors',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 4),
              const Text(
                'Collaborate and review shortlisted vendors with your event co-hosts.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 16),
              if (vendorIds.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.storefront_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'No vendors shortlisted yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Browse the EventEase Vendor Directory and add candidates to your event.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                )
              else
                ...vendorIds.map((vendorId) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          child: const Icon(Icons.storefront, color: AppTheme.primaryColor, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Vendor ID: $vendorId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              const Text('Shortlisted candidate for event', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                          child: Text('Shortlisted', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }
}
