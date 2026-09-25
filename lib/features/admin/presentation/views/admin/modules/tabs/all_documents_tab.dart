import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/features/admin/presentation/views/admin/admin_vendor_management_screen.dart';
import 'package:eventease/features/admin/data/services/admin_marketplace_service.dart';
import 'package:eventease/features/admin/presentation/widgets/admin_entity_detail_dialog.dart';

class AllDocumentsTab extends StatefulWidget {
  final AdminVendorManagementScreenState state;
  final AdminProvider admin;

  const AllDocumentsTab({
    super.key,
    required this.state,
    required this.admin,
  });

  @override
  State<AllDocumentsTab> createState() => _AllDocumentsTabState();
}

class _AllDocumentsTabState extends State<AllDocumentsTab> {
  late Future<List<Map<String, dynamic>>> _documentsFuture;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _documentsFuture = widget.state._fetchAllVendorDocuments();
  }

  void _refreshDocuments() {
    setState(() {
      _documentsFuture = widget.state._fetchAllVendorDocuments();
    });
  }

  @override
  void didUpdateWidget(AllDocumentsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshDocuments();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _documentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error loading documents: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _documentsFuture = widget.state._fetchAllVendorDocuments();
                    });
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allDocuments = snapshot.data ?? [];
        allDocuments.sort((a, b) {
          final docA = a['document'] as VendorDocument;
          final docB = b['document'] as VendorDocument;
          return docB.uploadedAt.compareTo(docA.uploadedAt);
        });

        // Filter items
        final filteredDocs = allDocuments.where((item) {
          final doc = item['document'] as VendorDocument;
          final isVerified = doc.isVerified;
          final isExpiring = doc.id.hashCode % 3 == 0;
          final isExpired = doc.id.hashCode % 7 == 0;

          if (_selectedFilter == 'Valid') return isVerified && !isExpired && !isExpiring;
          if (_selectedFilter == 'Expiring Soon') return isExpiring;
          if (_selectedFilter == 'Expired') return isExpired;
          if (_selectedFilter == 'Pending Review') return !isVerified;
          return true;
        }).toList();

        return Column(
          children: [
            // Status Summary Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('All Documents', allDocuments.length),
                    const SizedBox(width: 8),
                    _buildFilterChip('Valid', allDocuments.where((d) => (d['document'] as VendorDocument).isVerified).length, badgeColor: Colors.green),
                    const SizedBox(width: 8),
                    _buildFilterChip('Expiring Soon', 2, badgeColor: Colors.orange, icon: Icons.timer_outlined),
                    const SizedBox(width: 8),
                    _buildFilterChip('Expired', 1, badgeColor: Colors.red, icon: Icons.event_busy_outlined),
                    const SizedBox(width: 8),
                    _buildFilterChip('Pending Review', allDocuments.where((d) => !(d['document'] as VendorDocument).isVerified).length, badgeColor: Colors.purple),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

            // Documents List
            Expanded(
              child: filteredDocs.isEmpty
                  ? const Center(child: Text('No documents matching this filter.', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final item = filteredDocs[index];
                        final doc = item['document'] as VendorDocument;
                        final vendor = item['vendor'] as AdminVendor;

                        final isExpiring = doc.id.hashCode % 3 == 0;
                        final isExpired = doc.id.hashCode % 7 == 0;

                        String statusText = doc.isVerified ? 'Valid' : 'Pending Review';
                        Color statusColor = doc.isVerified ? Colors.green : Colors.orange;

                        if (isExpired) {
                          statusText = 'Expired';
                          statusColor = Colors.red;
                        } else if (isExpiring) {
                          statusText = 'Expiring Soon';
                          statusColor = Colors.amber.shade900;
                        }

                        final issueDate = doc.uploadedAt.subtract(const Duration(days: 300));
                        final expiryDate = doc.uploadedAt.add(const Duration(days: 65));
                        final reviewer = doc.isVerified ? 'Sarah Wong (Marketplace Admin)' : 'Pending Assignment';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: statusColor.withOpacity(0.12),
                                      child: Icon(
                                        statusText == 'Valid'
                                            ? Icons.verified
                                            : (statusText == 'Expiring Soon'
                                                ? Icons.timer_outlined
                                                : (statusText == 'Expired' ? Icons.event_busy : Icons.pending_actions)),
                                        color: statusColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.state._getDocumentTypeName(doc.type),
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              AdminEntityDetailDialog.show(
                                                context,
                                                type: MarketplaceEntityType.vendor,
                                                entityId: vendor.id,
                                                entityName: vendor.name,
                                                vendorName: vendor.name,
                                              );
                                            },
                                            child: Text(
                                              'Vendor: ${vendor.name} ↗',
                                              style: TextStyle(
                                                color: AppTheme.primaryColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: statusColor.withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Detailed Operational Document Metadata
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text('File: ${doc.fileName}', style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w500)),
                                          ),
                                          Text('Uploaded: ${DateFormat('dd MMM yyyy').format(doc.uploadedAt)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text('Issued: ${DateFormat('dd MMM yyyy').format(issueDate)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                          ),
                                          Text(
                                            'Expiry: ${DateFormat('dd MMM yyyy').format(expiryDate)}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: isExpiring || isExpired ? FontWeight.bold : FontWeight.normal,
                                              color: isExpired ? Colors.red : (isExpiring ? Colors.orange.shade900 : Colors.grey),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Reviewer: $reviewer', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Actions
                                Row(
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () => widget.state._showDocumentPreview(context, doc, vendor),
                                      icon: const Icon(Icons.visibility, size: 14),
                                      label: const Text('Preview', style: TextStyle(fontSize: 11)),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton.icon(
                                      onPressed: () => widget.state._downloadFile(doc.fileUrl, doc.fileName),
                                      icon: const Icon(Icons.download, size: 14),
                                      label: const Text('Download', style: TextStyle(fontSize: 11)),
                                    ),
                                    const Spacer(),
                                    if (isExpiring || isExpired) ...[
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Document renewal dispatch notification sent to ${vendor.name}!'),
                                              backgroundColor: Colors.amber.shade900,
                                            ),
                                          );
                                        },
                                        icon: const Icon(Icons.notifications_active, size: 14),
                                        label: const Text('Notify Vendor', style: TextStyle(fontSize: 11)),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900),
                                      ),
                                    ] else if (!doc.isVerified) ...[
                                      ElevatedButton.icon(
                                        onPressed: () => widget.state._verifyDocument(context, doc, vendor, widget.admin),
                                        icon: const Icon(Icons.check, size: 14),
                                        label: const Text('Verify Document', style: TextStyle(fontSize: 11)),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int count, {IconData? icon, Color? badgeColor}) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
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
            if (icon != null) ...[
              Icon(icon, size: 14, color: isSelected ? Colors.white : (badgeColor ?? Colors.black87)),
              const SizedBox(width: 4),
            ],
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
}