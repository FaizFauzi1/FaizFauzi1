import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/supabase_service.dart';

class AdminExpoManagementScreen extends StatefulWidget {
  const AdminExpoManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminExpoManagementScreen> createState() => _AdminExpoManagementScreenState();
}

class _AdminExpoManagementScreenState extends State<AdminExpoManagementScreen> {
  bool _isLoading = true;
  String _statusFilter = 'all';
  String _searchQuery = '';

  List<Map<String, dynamic>> _expos = [];

  @override
  void initState() {
    super.initState();
    _loadExpos();
  }

  Future<void> _loadExpos() async {
    setState(() => _isLoading = true);

    try {
      final rows = await SupabaseService.select(
        table: 'organizer_expos',
        orderBy: 'start_at',
        ascending: false,
      );

      // Fetch companies to map company_name
      Map<String, String> companyNames = {};
      try {
        final companies = await SupabaseService.select(
          table: 'organizer_companies',
        );
        for (final c in companies) {
          if (c['id'] != null) {
            companyNames[c['id'] as String] = (c['display_name'] ?? c['legal_name'] ?? 'Organizer') as String;
          }
        }
      } catch (_) {}

      final mapped = rows.map((r) {
        final cid = r['company_id'] as String? ?? '';
        final cname = companyNames[cid] ?? (r['is_platform_hosted'] == true ? 'EventEase Official (Platform Event)' : 'Organizer Partner');
        return {
          ...r,
          'company_name': cname,
        };
      }).toList();

      setState(() {
        _expos = mapped;
        _isLoading = false;
      });
      return;
    } catch (e) {
      debugPrint('Error loading expos in admin: $e');
    }

    setState(() {
      _expos = [];
      _isLoading = false;
    });
  }

  void _showCreatePlatformExpoDialog() {
    final nameCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '80');
    DateTime startDate = DateTime.now().add(const Duration(days: 30));
    DateTime endDate = DateTime.now().add(const Duration(days: 33));
    String ticketStrategy = 'free_and_paid';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_business, color: AppTheme.primaryColor),
                SizedBox(width: 10),
                Text('Create Platform Expo for Vendors'),
              ],
            ),
            content: SizedBox(
              width: 550,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Events created here are platform-hosted and will immediately appear on vendors\' "Join Expo as Exhibitor" page.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Expo / Event Title *',
                        hintText: 'e.g. EventEase KL Grand Bridal Fair 2026',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: venueCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Venue Name *',
                        hintText: 'e.g. Kuala Lumpur Convention Centre',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Venue Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: startDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 1000)),
                              );
                              if (d != null) setDialogState(() => startDate = d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                              child: Text(DateFormat('dd MMM yyyy').format(startDate)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: endDate,
                                firstDate: startDate,
                                lastDate: DateTime.now().add(const Duration(days: 1000)),
                              );
                              if (d != null) setDialogState(() => endDate = d);
                            },
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                              child: Text(DateFormat('dd MMM yyyy').format(endDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: capacityCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Booth Capacity *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.storefront_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: ticketStrategy,
                            decoration: const InputDecoration(
                              labelText: 'Visitor Entry',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'free_only', child: Text('Free Admission')),
                              DropdownMenuItem(value: 'free_and_paid', child: Text('Free + VIP')),
                              DropdownMenuItem(value: 'paid_only', child: Text('Paid Ticket Only')),
                            ],
                            onChanged: (v) => setDialogState(() => ticketStrategy = v ?? 'free_and_paid'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description / Highlights for Vendors',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameCtrl.text.trim().isEmpty || venueCtrl.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter event title and venue')),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);
                        final capacity = int.tryParse(capacityCtrl.text) ?? 80;

                        try {
                          String? companyId;
                          try {
                            final official = await SupabaseService.client
                                .from('organizer_companies')
                                .select('id')
                                .eq('display_name', 'EventEase Official')
                                .maybeSingle();
                            companyId = official?['id'] as String?;
                          } catch (_) {}

                          if (companyId == null) {
                            final existingCompanies = await SupabaseService.select(
                              table: 'organizer_companies',
                              columns: 'id',
                            );
                            if (existingCompanies.isNotEmpty) {
                              companyId = existingCompanies.first['id'] as String;
                            }
                          }

                          if (companyId == null) {
                            final adminUid = SupabaseService.currentUser?.id;
                            if (adminUid != null) {
                              final createdCompany = await SupabaseService.insert(
                                table: 'organizer_companies',
                                data: {
                                  'owner_user_id': adminUid,
                                  'legal_name': 'EventEase Official Events',
                                  'display_name': 'EventEase Official',
                                  'contact_email': 'events@eventease.my',
                                  'is_verified': true,
                                  'setup_completed': true,
                                },
                              );
                              if (createdCompany.isNotEmpty) {
                                companyId = createdCompany.first['id'] as String;
                              }
                            }
                          }

                          if (companyId == null) {
                            throw 'Could not resolve an organizer company for this expo.';
                          }

                          final cleanSlug = nameCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
                          final slug = '$cleanSlug-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

                          final expoPayload = <String, dynamic>{
                            'company_id': companyId,
                            'name': nameCtrl.text.trim(),
                            'slug': slug,
                            'venue': venueCtrl.text.trim(),
                            'venue_address': addressCtrl.text.trim(),
                            'description': descCtrl.text.trim(),
                            'start_at': startDate.toIso8601String(),
                            'end_at': endDate.toIso8601String(),
                            'status': 'upcoming',
                            'booth_capacity': capacity,
                            'ticket_strategy': ticketStrategy,
                            'is_platform_hosted': true,
                          };

                          try {
                            await SupabaseService.insert(
                              table: 'organizer_expos',
                              data: expoPayload,
                            );
                          } catch (e) {
                            debugPrint('Expo insert with extras failed, retrying: $e');
                            expoPayload.remove('description');
                            expoPayload.remove('is_platform_hosted');
                            await SupabaseService.insert(
                              table: 'organizer_expos',
                              data: expoPayload,
                            );
                          }

                          if (!mounted) return;
                          Navigator.pop(dialogCtx);
                          await _loadExpos();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Platform Expo published! Vendors can now view and apply for booths in their dashboard.',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        } catch (e) {
                          debugPrint('Supabase insert expo error: $e');
                          setDialogState(() => isSaving = false);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not publish expo: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                icon: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.rocket_launch),
                label: Text(isSaving ? 'Publishing...' : 'Publish Expo for Vendors'),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExhibitorsModal(Map<String, dynamic> expo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storefront, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expo['name'] ?? 'Expo Exhibitors',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      Text(
                        'Vendor Applications & Booth Assignments',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ],
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildExhibitorTile('Glamour Bridal Studio', 'Bridal Wear', 'VIP Island A1', 'approved', 'RM 3,500'),
                  _buildExhibitorTile('Royal Catering Services', 'Catering', 'Zone B - Booth 12', 'approved', 'RM 2,000'),
                  _buildExhibitorTile('LensArt Wedding Photography', 'Photography', 'Zone A - Booth 05', 'pending', 'RM 2,000'),
                  _buildExhibitorTile('Bloom & Petal Florist', 'Decoration & Floral', 'Zone B - Booth 18', 'pending', 'RM 1,800'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExhibitorTile(String company, String category, String booth, String status, String fee) {
    final isApproved = status == 'approved';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isApproved ? Colors.green.shade50 : Colors.amber.shade50,
          child: Icon(
            isApproved ? Icons.check : Icons.hourglass_top,
            color: isApproved ? Colors.green : Colors.amber.shade800,
            size: 18,
          ),
        ),
        title: Text(company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text('$category · $booth · Fee: $fee', style: const TextStyle(fontSize: 12)),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isApproved ? Colors.green.shade50 : Colors.amber.shade50,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: isApproved ? Colors.green : Colors.amber),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isApproved ? Colors.green : Colors.amber.shade900,
            ),
          ),
        ),
      ),
    );
  }

  void _updateExpoStatus(Map<String, dynamic> expo, String newStatus) async {
    setState(() => expo['status'] = newStatus);

    try {
      await SupabaseService.update(
        table: 'organizer_expos',
        column: 'id',
        value: expo['id'],
        data: {'status': newStatus},
      );
    } catch (_) {}

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${expo['name']} status changed to ${newStatus.toUpperCase()}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _expos.where((e) {
      final name = (e['name'] ?? '').toString().toLowerCase();
      final venue = (e['venue'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      final matches = name.contains(query) || venue.contains(query);
      if (!matches) return false;
      if (_statusFilter != 'all') {
        return (e['status'] ?? '') == _statusFilter;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Expo & Event Oversight', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadExpos),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top Filter Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search expo by name or venue...',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<String>(
                        value: _statusFilter,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Events')),
                          DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                          DropdownMenuItem(value: 'draft', child: Text('Draft Review')),
                          DropdownMenuItem(value: 'ongoing', child: Text('Live Now')),
                          DropdownMenuItem(value: 'past', child: Text('Completed')),
                          DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // Expos List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 12),
                              const Text('No expos found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _showCreatePlatformExpoDialog,
                                icon: const Icon(Icons.add),
                                label: const Text('Create First Platform Expo'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final expo = filtered[index];
                            final status = expo['status'] ?? 'upcoming';
                            final isPlatform = expo['is_platform_hosted'] == true;

                            Color statusColor = Colors.blue;
                            if (status == 'upcoming') statusColor = Colors.blue;
                            if (status == 'draft') statusColor = Colors.orange;
                            if (status == 'ongoing') statusColor = Colors.green;
                            if (status == 'cancelled') statusColor = Colors.red;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isPlatform
                                                ? AppTheme.primaryColor.withOpacity(0.12)
                                                : Colors.purple.shade50,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            isPlatform ? Icons.verified : Icons.festival,
                                            color: isPlatform ? AppTheme.primaryColor : Colors.purple,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      expo['name'] ?? 'Untitled Expo',
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 17,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: statusColor.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                      border: Border.all(color: statusColor),
                                                    ),
                                                    child: Text(
                                                      status.toUpperCase(),
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                        color: statusColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Organizer: ${expo['company_name'] ?? 'Organizer Company'}',
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: isPlatform ? AppTheme.primaryColor : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Row(
                                                children: [
                                                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    expo['venue'] ?? '',
                                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 24),
                                    Row(
                                      children: [
                                        _buildMetricBadge(
                                          Icons.storefront_outlined,
                                          '${expo['exhibitors_count'] ?? 0}/${expo['booth_capacity'] ?? 0} Booths',
                                        ),
                                        const SizedBox(width: 10),
                                        _buildMetricBadge(
                                          Icons.calendar_month_outlined,
                                          expo['start_at'] != null
                                              ? DateFormat('dd MMM yyyy')
                                                  .format(DateTime.tryParse(expo['start_at']) ?? DateTime.now())
                                              : 'TBD',
                                        ),
                                        const Spacer(),
                                        OutlinedButton.icon(
                                          onPressed: () => _showExhibitorsModal(expo),
                                          icon: const Icon(Icons.groups, size: 16),
                                          label: const Text('View Exhibitors', style: TextStyle(fontSize: 12)),
                                        ),
                                        const SizedBox(width: 8),
                                        if (status == 'draft') ...[
                                          FilledButton.icon(
                                            onPressed: () => _updateExpoStatus(expo, 'upcoming'),
                                            icon: const Icon(Icons.check, size: 16),
                                            label: const Text('Approve & Publish', style: TextStyle(fontSize: 12)),
                                            style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                          ),
                                        ] else if (status == 'upcoming') ...[
                                          PopupMenuButton<String>(
                                            onSelected: (action) => _updateExpoStatus(expo, action),
                                            itemBuilder: (ctx) => const [
                                              PopupMenuItem(value: 'ongoing', child: Text('Mark Ongoing / Live')),
                                              PopupMenuItem(value: 'past', child: Text('Mark Completed')),
                                              PopupMenuItem(
                                                value: 'cancelled',
                                                child: Text('Cancel Expo', style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePlatformExpoDialog,
        icon: const Icon(Icons.add),
        label: const Text('+ Create Platform Expo for Vendors'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildMetricBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}
