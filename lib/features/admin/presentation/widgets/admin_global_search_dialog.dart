import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/admin/data/services/admin_marketplace_service.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/features/admin/data/providers/admin_marketplace_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_workflow_provider.dart';
import 'package:eventease/features/admin/presentation/widgets/admin_entity_detail_dialog.dart';

/// Global Admin Search Dialog accessible from the Admin header
class AdminGlobalSearchDialog extends StatefulWidget {
  const AdminGlobalSearchDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const AdminGlobalSearchDialog(),
    );
  }

  @override
  State<AdminGlobalSearchDialog> createState() => _AdminGlobalSearchDialogState();
}

class _AdminGlobalSearchDialogState extends State<AdminGlobalSearchDialog> {
  final _searchController = TextEditingController();
  List<AdminSearchResult> _results = [];
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    final admin = Provider.of<AdminProvider>(context, listen: false);
    final workflow = Provider.of<VendorWorkflowProvider>(context, listen: false);
    final mkt = Provider.of<AdminMarketplaceProvider>(context, listen: false);

    final hits = mkt.searchMarketplace(
      query: query,
      admin: admin,
      workflowServices: workflow.services,
      workflowPackages: workflow.packages,
      workflowAppointments: workflow.appointments,
    );

    setState(() {
      _results = hits;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 60 : 16,
        vertical: 36,
      ),
      child: Container(
        width: isDesktop ? 780 : double.infinity,
        height: isDesktop ? 600 : MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Search Input Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppTheme.primaryColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search EventEase (vendors, services, packages, bookings, appointments, transactions)...',
                        hintStyle: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Content / Results List
            Expanded(
              child: _buildSearchBody(),
            ),

            // Footer Tips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(top: BorderSide(color: Colors.grey.shade200)),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.keyboard_outlined, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  const Text(
                    'Tip: Type vendor name (e.g. "Catering"), booking ID ("BK-"), or service name to filter directly.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    '${_results.length} results',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBody() {
    if (!_hasSearched) {
      return _buildQuickPicks();
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No matches found for "${_searchController.text}"',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try searching by vendor name, customer email, service title, or reference ID.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Group results by MarketplaceEntityType
    final Map<MarketplaceEntityType, List<AdminSearchResult>> grouped = {};
    for (final r in _results) {
      grouped.putIfAbsent(r.type, () => []).add(r);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: grouped.entries.map((entry) {
        final type = entry.key;
        final list = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(type.icon, size: 16, color: type.color),
                  const SizedBox(width: 6),
                  Text(
                    type.label.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: type.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${list.length}',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: type.color),
                    ),
                  ),
                ],
              ),
            ),
            ...list.map((res) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(type.icon, size: 18, color: type.color),
                  ),
                  title: Text(
                    res.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  subtitle: Text(
                    res.subtitle,
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                  ),
                  trailing: res.status != null
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            res.status!,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    AdminEntityDetailDialog.show(
                      context,
                      type: res.type,
                      entityId: res.id,
                      data: res.metadata[res.type.name],
                    );
                  },
                ),
              );
            }),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildQuickPicks() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK SUGGESTIONS & FREQUENT SEARCHES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSearchChip('ABC Catering'),
              _buildSearchChip('Glam Studio'),
              _buildSearchChip('BK-10492'),
              _buildSearchChip('Royal Wedding'),
              _buildSearchChip('Food Tasting'),
              _buildSearchChip('Makeup Trial'),
              _buildSearchChip('TX-84921'),
              _buildSearchChip('CASE-4091'),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'SEARCHABLE PLATFORM ENTITIES',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: MarketplaceEntityType.values.map((type) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: type.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: type.color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(type.icon, size: 14, color: type.color),
                    const SizedBox(width: 6),
                    Text(
                      type.label,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: type.color),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchChip(String label) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      avatar: const Icon(Icons.history, size: 14, color: Colors.grey),
      backgroundColor: Colors.grey.shade100,
      onPressed: () {
        _searchController.text = label;
      },
    );
  }
}
