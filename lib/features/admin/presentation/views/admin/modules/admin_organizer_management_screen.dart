import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/supabase_service.dart';

class AdminOrganizerManagementScreen extends StatefulWidget {
  const AdminOrganizerManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminOrganizerManagementScreen> createState() => _AdminOrganizerManagementScreenState();
}

class _AdminOrganizerManagementScreenState extends State<AdminOrganizerManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedStatusFilter = 'all';

  List<Map<String, dynamic>> _organizers = [];
  List<Map<String, dynamic>> _inquiries = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Fetch Invitations
      List<Map<String, dynamic>> invitations = [];
      try {
        invitations = await SupabaseService.select(
          table: 'organizer_invitations',
          orderBy: 'created_at',
          ascending: false,
        );
      } catch (_) {}

      // 2. Fetch Companies
      List<Map<String, dynamic>> companies = [];
      try {
        companies = await SupabaseService.select(
          table: 'organizer_companies',
          orderBy: 'created_at',
          ascending: false,
        );
      } catch (_) {}

      // 3. Fetch Organizer Users
      List<Map<String, dynamic>> orgUsers = [];
      try {
        orgUsers = await SupabaseService.select(
          table: 'organizer_user',
          orderBy: 'created_at',
          ascending: false,
        );
      } catch (_) {}

      // 4. Fetch Inquiries
      List<Map<String, dynamic>> inquiries = [];
      try {
        inquiries = await SupabaseService.select(
          table: 'organizer_inquiries',
          orderBy: 'created_at',
          ascending: false,
        );
      } catch (_) {}

      // Consolidate organizers into unified list keyed by email
      final Map<String, Map<String, dynamic>> consolidated = {};

      // A) Seed with Invitations
      for (final inv in invitations) {
        final email = (inv['email'] ?? '').toString().toLowerCase().trim();
        if (email.isEmpty) continue;

        final isAccepted = inv['status'] == 'accepted';
        consolidated[email] = {
          'id': inv['id'] ?? 'inv-$email',
          'legal_name': inv['company_name'] ?? 'Organizer',
          'display_name': inv['company_name'] ?? 'Organizer',
          'contact_person': inv['contact_person'] ?? '',
          'contact_email': inv['email'] ?? '',
          'contact_phone': inv['phone'] ?? '',
          'event_type': inv['event_type'] ?? 'Wedding Expo',
          'status': isAccepted ? 'active' : 'pending',
          'is_verified': isAccepted,
          'expos_count': 0,
          'invitation_token': inv['token'],
          'created_at': inv['created_at'] ?? DateTime.now().toIso8601String(),
        };
      }

      // B) Overlay Organizer Users
      for (final u in orgUsers) {
        final email = (u['email'] ?? '').toString().toLowerCase().trim();
        if (email.isEmpty) continue;

        if (consolidated.containsKey(email)) {
          consolidated[email]!['status'] = u['status'] == 'banned' ? 'suspended' : 'active';
          if (u['name'] != null && (u['name'] as String).isNotEmpty) {
            consolidated[email]!['contact_person'] = u['name'];
          }
          if (u['phone'] != null && (u['phone'] as String).isNotEmpty) {
            consolidated[email]!['contact_phone'] = u['phone'];
          }
          if (u['company_name'] != null && (u['company_name'] as String).isNotEmpty) {
            consolidated[email]!['legal_name'] = u['company_name'];
            consolidated[email]!['display_name'] = u['company_name'];
          }
        } else {
          consolidated[email] = {
            'id': u['id'],
            'legal_name': u['company_name'] ?? '${u['name'] ?? 'Organizer'} Events',
            'display_name': u['company_name'] ?? '${u['name'] ?? 'Organizer'} Events',
            'contact_person': u['name'] ?? '',
            'contact_email': u['email'] ?? '',
            'contact_phone': u['phone'] ?? '',
            'event_type': 'Wedding Expo',
            'status': u['status'] == 'banned' ? 'suspended' : 'active',
            'is_verified': true,
            'expos_count': 0,
            'created_at': u['created_at'] ?? DateTime.now().toIso8601String(),
          };
        }
      }

      // C) Overlay Companies
      for (final c in companies) {
        final email = (c['contact_email'] ?? '').toString().toLowerCase().trim();
        final name = (c['legal_name'] ?? c['display_name'] ?? '').toString().toLowerCase();

        String key = email;
        if (key.isEmpty || !consolidated.containsKey(key)) {
          final match = consolidated.keys.firstWhere(
            (k) => (consolidated[k]!['legal_name'] ?? '').toString().toLowerCase() == name,
            orElse: () => '',
          );
          if (match.isNotEmpty) key = match;
        }

        if (key.isNotEmpty && consolidated.containsKey(key)) {
          consolidated[key]!['legal_name'] = c['legal_name'] ?? consolidated[key]!['legal_name'];
          consolidated[key]!['display_name'] = c['display_name'] ?? consolidated[key]!['display_name'];
          consolidated[key]!['status'] = 'active';
          consolidated[key]!['is_verified'] = c['is_verified'] ?? true;
          if (c['contact_phone'] != null && (c['contact_phone'] as String).isNotEmpty) {
            consolidated[key]!['contact_phone'] = c['contact_phone'];
          }
        } else if (email.isNotEmpty) {
          consolidated[email] = {
            'id': c['id'],
            'legal_name': c['legal_name'] ?? 'Organizer Company',
            'display_name': c['display_name'] ?? c['legal_name'] ?? 'Organizer',
            'contact_person': 'Organizer Lead',
            'contact_email': email,
            'contact_phone': c['contact_phone'] ?? '',
            'event_type': 'Wedding Expo',
            'status': 'active',
            'is_verified': c['is_verified'] ?? true,
            'expos_count': 0,
            'created_at': c['created_at'] ?? DateTime.now().toIso8601String(),
          };
        }
      }

      final list = consolidated.values.toList();
      list.sort((a, b) => (b['created_at'] ?? '').toString().compareTo((a['created_at'] ?? '').toString()));

      setState(() {
        _organizers = list;
        _inquiries = inquiries;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AdminOrganizerManagement load error: $e');
      setState(() {
        _organizers = [];
        _inquiries = [];
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getSeedOrganizers() {
    return [];
  }

  List<Map<String, dynamic>> _getSeedInquiries() {
    return [];
  }

  String _generateToken() {
    final random = Random();
    final num = random.nextInt(900000) + 100000;
    return 'INV-$num-ORG';
  }

  void _showAddOrganizerDialog({Map<String, dynamic>? prefillInquiry}) {
    final orgNameCtrl = TextEditingController(text: prefillInquiry?['company_name'] ?? '');
    final contactCtrl = TextEditingController(text: prefillInquiry?['contact_person'] ?? '');
    final emailCtrl = TextEditingController(text: prefillInquiry?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: prefillInquiry?['phone'] ?? '');
    final notesCtrl = TextEditingController(text: prefillInquiry?['notes'] ?? '');
    String eventType = prefillInquiry?['event_type'] ?? 'Wedding Expo';
    String status = 'pending';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.festival, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 12),
                Text(prefillInquiry != null ? 'Approve & Onboard Organizer' : 'Add New Organizer'),
              ],
            ),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create an approved organizer account. An activation invitation code will be generated to allow the organizer to set up their password.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: orgNameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Organization / Company Legal Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: contactCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Contact Person *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Official Email *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: eventType,
                            decoration: const InputDecoration(
                              labelText: 'Event Type',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Wedding Expo', child: Text('Wedding Expo')),
                              DropdownMenuItem(value: 'Bridal Fair', child: Text('Bridal Fair')),
                              DropdownMenuItem(value: 'Festival / Marketplace', child: Text('Festival / Marketplace')),
                              DropdownMenuItem(value: 'Corporate / Other', child: Text('Corporate / Other')),
                            ],
                            onChanged: (v) => setDialogState(() => eventType = v ?? 'Wedding Expo'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: status,
                            decoration: const InputDecoration(
                              labelText: 'Initial Status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'pending', child: Text('Pending Activation')),
                              DropdownMenuItem(value: 'active', child: Text('Active')),
                            ],
                            onChanged: (v) => setDialogState(() => status = v ?? 'pending'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Internal Admin Notes (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        if (orgNameCtrl.text.trim().isEmpty ||
                            contactCtrl.text.trim().isEmpty ||
                            emailCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required fields')),
                          );
                          return;
                        }

                        setDialogState(() => isSubmitting = true);
                        final token = _generateToken();

                        try {
                          // Save invitation to Supabase
                          await SupabaseService.insert(
                            table: 'organizer_invitations',
                            data: {
                              'company_name': orgNameCtrl.text.trim(),
                              'contact_person': contactCtrl.text.trim(),
                              'email': emailCtrl.text.trim(),
                              'phone': phoneCtrl.text.trim(),
                              'event_type': eventType,
                              'token': token,
                              'status': 'pending',
                              'role': 'organizer',
                            },
                          );

                          // If from inquiry, mark inquiry approved
                          if (prefillInquiry != null && prefillInquiry['id'] != null) {
                            try {
                              await SupabaseService.update(
                                table: 'organizer_inquiries',
                                column: 'id',
                                value: prefillInquiry['id'],
                                data: {'status': 'approved'},
                              );
                            } catch (_) {}
                          }
                        } catch (e) {
                          debugPrint('Insert invitation fallback: $e');
                        }

                        final newOrg = {
                          'id': 'org-${DateTime.now().millisecondsSinceEpoch}',
                          'legal_name': orgNameCtrl.text.trim(),
                          'display_name': orgNameCtrl.text.trim(),
                          'contact_person': contactCtrl.text.trim(),
                          'contact_email': emailCtrl.text.trim(),
                          'contact_phone': phoneCtrl.text.trim(),
                          'event_type': eventType,
                          'status': status,
                          'is_verified': true,
                          'expos_count': 0,
                          'invitation_token': token,
                          'created_at': DateTime.now().toIso8601String(),
                        };

                        setState(() {
                          _organizers.insert(0, newOrg);
                          if (prefillInquiry != null) {
                            prefillInquiry['status'] = 'approved';
                          }
                        });

                        if (!mounted) return;
                        Navigator.pop(dialogCtx);
                        _showInvitationSuccessDialog(
                          companyName: orgNameCtrl.text.trim(),
                          email: emailCtrl.text.trim(),
                          token: token,
                        );
                      },
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(isSubmitting ? 'Creating...' : 'Create & Generate Invitation'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showInvitationSuccessDialog({
    required String companyName,
    required String email,
    required String token,
  }) {
    final link = 'https://eventease.my/organizer/activate?token=$token';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Organizer Account Created'),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'An organizer profile has been authorized for $companyName ($email).',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Activation Token:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        token,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy Token',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: token));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Activation token copied to clipboard!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Activation Link:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        link,
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: 'Copy Link',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Activation link copied!')),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Send this activation link or token to the organizer so they can set their password and access the Expo Command Dashboard.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _toggleOrganizerStatus(Map<String, dynamic> org) async {
    final currentStatus = org['status'] ?? 'pending';
    final newStatus = currentStatus == 'active' ? 'suspended' : 'active';

    setState(() {
      org['status'] = newStatus;
    });

    try {
      await SupabaseService.update(
        table: 'organizer_companies',
        column: 'id',
        value: org['id'],
        data: {'is_verified': newStatus == 'active'},
      );
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${org['legal_name']} status updated to $newStatus')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingInquiriesCount = _inquiries.where((i) => i['status'] == 'pending').length;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Organizer Management',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey.shade400,
          tabs: [
            const Tab(
              icon: Icon(Icons.business),
              text: 'Active Organizers',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: pendingInquiriesCount > 0,
                label: Text(pendingInquiriesCount.toString()),
                child: const Icon(Icons.mark_email_unread_outlined),
              ),
              text: 'Inquiries & Applications',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOrganizersTab(),
                _buildInquiriesTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrganizerDialog(),
        icon: const Icon(Icons.add_business),
        label: const Text('+ Add Organizer'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildOrganizersTab() {
    final filtered = _organizers.where((org) {
      final name = (org['legal_name'] ?? org['display_name'] ?? '').toString().toLowerCase();
      final contact = (org['contact_person'] ?? '').toString().toLowerCase();
      final email = (org['contact_email'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();

      final matchesQuery = name.contains(query) || contact.contains(query) || email.contains(query);
      if (!matchesQuery) return false;

      if (_selectedStatusFilter != 'all') {
        return (org['status'] ?? 'pending') == _selectedStatusFilter;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Filter bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search organizer by company, contact, or email...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedStatusFilter,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'active', child: Text('Active Only')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending Activation')),
                  DropdownMenuItem(value: 'suspended', child: Text('Suspended')),
                ],
                onChanged: (v) => setState(() => _selectedStatusFilter = v ?? 'all'),
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.business_center_outlined, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No organizers found',
                        style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showAddOrganizerDialog(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add First Organizer'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final org = filtered[index];
                    final status = org['status'] ?? 'pending';

                    Color statusColor = Colors.orange;
                    if (status == 'active') statusColor = Colors.green;
                    if (status == 'suspended') statusColor = Colors.red;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 1,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                              child: Text(
                                (org['legal_name'] ?? 'O')[0].toUpperCase(),
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          org['legal_name'] ?? org['display_name'] ?? 'Organizer',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: statusColor),
                                        ),
                                        child: Text(
                                          status.toUpperCase(),
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline, size: 15, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        org['contact_person'] ?? 'Unknown contact',
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.email_outlined, size: 15, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        org['contact_email'] ?? 'No email',
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      ),
                                      const SizedBox(width: 16),
                                      const Icon(Icons.phone_outlined, size: 15, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                        org['contact_phone'] ?? 'No phone',
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.purple.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Category: ${org['event_type'] ?? 'Wedding Expo'}',
                                          style: TextStyle(fontSize: 11, color: Colors.purple.shade800),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Expos: ${org['expos_count'] ?? 0}',
                                          style: TextStyle(fontSize: 11, color: Colors.blue.shade800),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (status == 'pending')
                                        OutlinedButton.icon(
                                          onPressed: () {
                                            final token = org['invitation_token'] ?? _generateToken();
                                            _showInvitationSuccessDialog(
                                              companyName: org['legal_name'] ?? 'Organizer',
                                              email: org['contact_email'] ?? '',
                                              token: token,
                                            );
                                          },
                                          icon: const Icon(Icons.link, size: 14),
                                          label: const Text('Copy Invite Link', style: TextStyle(fontSize: 12)),
                                        ),
                                      const SizedBox(width: 8),
                                      TextButton(
                                        onPressed: () => _toggleOrganizerStatus(org),
                                        child: Text(
                                          status == 'active' ? 'Suspend' : 'Activate',
                                          style: TextStyle(
                                            color: status == 'active' ? Colors.red : Colors.green,
                                            fontWeight: FontWeight.bold,
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
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildInquiriesTab() {
    return _inquiries.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                const Text(
                  'No organizer inquiries yet',
                  style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Requests submitted via the "Contact EventEase" registration form will appear here.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _inquiries.length,
            itemBuilder: (context, index) {
              final inq = _inquiries[index];
              final status = inq['status'] ?? 'pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.festival, color: AppTheme.primaryColor, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  inq['company_name'] ?? 'Unnamed Organization',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Contact: ${inq['contact_person'] ?? ''} · ${inq['email'] ?? ''} · ${inq['phone'] ?? ''}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'approved'
                                  ? Colors.green.shade50
                                  : (status == 'rejected' ? Colors.red.shade50 : Colors.amber.shade50),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: status == 'approved'
                                    ? Colors.green
                                    : (status == 'rejected' ? Colors.red : Colors.amber.shade700),
                              ),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: status == 'approved'
                                    ? Colors.green
                                    : (status == 'rejected' ? Colors.red : Colors.amber.shade900),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Chip(
                            label: Text('Type: ${inq['event_type'] ?? 'Wedding Expo'}'),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('Est. Booths: ${inq['estimated_booths'] ?? 20}'),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      if (inq['notes'] != null && (inq['notes'] as String).isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            'Note: ${inq['notes']}',
                            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'pending') ...[
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() => inq['status'] = 'rejected');
                                try {
                                  SupabaseService.update(
                                    table: 'organizer_inquiries',
                                    column: 'id',
                                    value: inq['id'],
                                    data: {'status': 'rejected'},
                                  );
                                } catch (_) {}
                              },
                              icon: const Icon(Icons.close, size: 16, color: Colors.red),
                              label: const Text('Decline', style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: () => _showAddOrganizerDialog(prefillInquiry: inq),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve & Onboard'),
                              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                            ),
                          ] else ...[
                            Text(
                              status == 'approved' ? '✓ Account Created & Invited' : '✗ Declined',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: status == 'approved' ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
  }
}
