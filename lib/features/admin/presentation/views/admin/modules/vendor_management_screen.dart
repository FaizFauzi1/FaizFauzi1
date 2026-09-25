library vendor_management;

import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/data/vendor_services_data.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/shared/models/services/service_enums.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/vendor/presentation/views/enhanced_service_creation_screen.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_installment_settings_screen.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_dashboard_screen.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';


part 'tabs/all_vendors_tab.dart';
part 'tabs/pending_approval_tab.dart';
  

class VendorManagementScreen extends StatefulWidget {
  const VendorManagementScreen({super.key});

  @override
  State<VendorManagementScreen> createState() => _VendorManagementScreenState();
}

class _VendorManagementScreenState extends State<VendorManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterCategory = 'All';
  String _filterStatus = 'All';
  int _documentsRefreshKey = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
  }
@override
void dispose() {
_tabController.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    final vendors = admin.vendors;
    final vendorUsers = admin.users.where((user) => user.role == 'vendor').toList();

    // Combine vendors and vendor users to ensure vendor users are counted as vendors
    final allVendors = [...vendors];
    for (final user in vendorUsers) {
      if (!allVendors.any((v) => v.id == user.id)) {
        final docs = admin.getVendorUserDocuments(user.id);
        allVendors.add(AdminVendor(
          user.id,
          user.name,
          'Vendor', // Default category for vendor users
          false, // verified
          false, // suspended
          0.0, // rating
          0, // reviews
          0, // bookings
          [], // serviceAreas
          false, // pendingApproval
          documents: docs,
          documentsVerified: docs.isNotEmpty && docs.every((d) => d.isVerified),
        ));
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Vendor Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _exportVendorsToCSV(context),
            tooltip: 'Export Vendors',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText:
                        'Search vendors by name, category, or location...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _filterCategory,
                        items: [
                          'All',
                          'Catering',
                          'Photography',
                          'Venues',
                          'Fashion',
                          'Decoration'
                        ]
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _filterCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _filterStatus,
                        items: ['All', 'Active', 'Pending', 'Suspended']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _filterStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'All Vendors'),
              Tab(text: 'Pending Approval'),
              Tab(text: 'Document Review'),
              Tab(text: 'All Documents'),
              Tab(text: 'Suspended'),
              Tab(text: 'Performance'),
              Tab(text: 'Services & Packages'),
              Tab(text: 'Reports'),
              Tab(text: 'Analytics'),
              Tab(text: 'Vendor Users'),
            ],
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AllVendorsTab(vendors: allVendors, admin: admin, state: this),
                _buildPendingApprovalTab(allVendors.where((v) => v.pendingApproval).toList(), admin),
                _buildDocumentReviewTab(allVendors, admin),
                _buildAllDocumentsTab(allVendors, admin),
                _buildSuspendedTab(
                    allVendors.where((v) => v.suspended).toList(), admin),
                _buildPerformanceTab(allVendors, admin),
                _buildServicesPackagesTab(allVendors, admin),
                _buildReportsTab(allVendors, admin),
                _buildAnalyticsTab(allVendors, admin),
                _buildVendorUsersTab(allVendors, admin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllVendorsTab(List<AdminVendor> vendors, AdminProvider admin) {
    final vendorUsers = admin.users.where((user) => user.role == 'vendor').toList();

    // Combine vendors and vendor users to ensure vendor users are counted as vendors
    final allVendors = [...vendors];
    for (final user in vendorUsers) {
      if (!allVendors.any((v) => v.id == user.id)) {
        // Get cached documents for vendor users
        final docs = admin.getVendorUserDocuments(user.id);
        allVendors.add(AdminVendor(
          user.id,
          user.name,
          'Vendor', // Default category for vendor users
          false, // verified
          false, // suspended
          0.0, // rating
          0, // reviews
          0, // bookings
          [], // serviceAreas
          false, // pendingApproval
          documents: docs,
          documentsVerified: docs.isNotEmpty && docs.every((d) => d.isVerified),
        ));
      }
    }

    final filteredVendors = _filterVendors(allVendors);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredVendors.length,
      itemBuilder: (context, index) {
        final vendor = filteredVendors[index];
        return _buildVendorCard(
          context, 
          vendor, 
          admin, 
          showActions: true,
          isPending: vendor.pendingApproval,
          isSuspended: vendor.suspended,
        );
      },
    );
  }

  Widget _buildPendingApprovalTab(List<AdminVendor> vendors, AdminProvider admin) {
    if (vendors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 64,
              color: Colors.green[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Pending Approvals',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All vendors have been reviewed and approved.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vendors.length,
      itemBuilder: (context, index) {
        final vendor = vendors[index];
        return _buildVendorCard(context, vendor, admin,
            showActions: true, isPending: true);
      },
    );
  }

  Widget _buildSuspendedTab(List<AdminVendor> vendors, AdminProvider admin) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vendors.length,
      itemBuilder: (context, index) {
        final vendor = vendors[index];
        return _buildVendorCard(
          context, 
          vendor, 
          admin,
          showActions: true, 
          isPending: false,
          isSuspended: true,
        );
      },
    );
  }

  Widget _buildDocumentReviewTab(List<AdminVendor> vendors, AdminProvider admin) {
    final vendorsNeedingReview = vendors.where((v) =>
        v.documents.isNotEmpty &&
        !v.documentsVerified &&
        v.documents.any((doc) => !doc.isVerified)).toList();

    if (vendorsNeedingReview.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified,
              size: 64,
              color: Colors.green[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'No Documents to Review',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'All vendor documents have been reviewed and verified.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vendorsNeedingReview.length,
      itemBuilder: (context, index) {
        final vendor = vendorsNeedingReview[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.business,
                        color: AppTheme.primaryColor,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            vendor.category,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '${vendor.documents.length} documents uploaded',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Documents List
                const Text(
                  'Documents to Review:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...vendor.documents.map((doc) => _buildDocumentReviewItem(context, doc, vendor, admin)),

                const SizedBox(height: 16),

                // Document Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDocumentDetails(context, vendor),
                    icon: const Icon(Icons.description),
                    label: const Text('View All Documents'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _rejectAllDocuments(context, vendor, admin),
                            icon: const Icon(Icons.cancel),
                            label: const Text('Reject All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _verifyAllDocuments(context, vendor, admin),
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Verify All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showDocumentDetails(context, vendor),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllDocumentsTab(List<AdminVendor> vendors, AdminProvider admin) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: ValueKey(_documentsRefreshKey),
      future: _fetchAllVendorDocuments(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading documents: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final allDocuments = snapshot.data ?? [];

        // Sort documents by upload date (newest first)
        allDocuments.sort((a, b) {
          final docA = a['document'] as VendorDocument;
          final docB = b['document'] as VendorDocument;
          return docB.uploadedAt.compareTo(docA.uploadedAt);
        });

        return Column(
          children: [
            // Summary Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Total Documents',
                      allDocuments.length.toString(),
                      Icons.description,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Verified',
                      allDocuments.where((d) => (d['document'] as VendorDocument).isVerified).length.toString(),
                      Icons.verified,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Pending Review',
                      allDocuments.where((d) => !(d['document'] as VendorDocument).isVerified).length.toString(),
                      Icons.pending,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            // Documents List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: allDocuments.length,
                itemBuilder: (context, index) {
                  final item = allDocuments[index];
                  final doc = item['document'] as VendorDocument;
                  final vendor = item['vendor'] as AdminVendor;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: doc.isVerified ? Colors.green[100] : Colors.orange[100],
                        child: Icon(
                          doc.isVerified ? Icons.verified : Icons.pending,
                          color: doc.isVerified ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getDocumentTypeName(doc.type),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: doc.isVerified ? Colors.green[100] : Colors.orange[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              doc.isVerified ? 'Verified' : 'Pending',
                              style: TextStyle(
                                color: doc.isVerified ? Colors.green[800] : Colors.orange[800],
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vendor: ${vendor.name}',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'File: ${doc.fileName}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Uploaded: ${doc.uploadedAt.toLocal().toString().split(' ')[0]}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          if (doc.verificationNotes != null && doc.verificationNotes!.isNotEmpty)
                            Text(
                              'Notes: ${doc.verificationNotes}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility, size: 20),
                            onPressed: () => _showDocumentPreview(context, doc, vendor),
                            tooltip: 'Preview Document',
                          ),
                          IconButton(
                            icon: const Icon(Icons.download, size: 20),
                            onPressed: () => _downloadFile(doc.fileUrl, doc.fileName),
                            tooltip: 'Download Document',
                          ),
                          if (!doc.isVerified)
                            IconButton(
                              icon: const Icon(Icons.check_circle, size: 20, color: Colors.green),
                              onPressed: () => _verifyDocument(context, doc, vendor, admin),
                              tooltip: 'Verify Document',
                            ),
                        ],
                      ),
                      onTap: () => _showDocumentDetails(context, vendor),
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

  Future<List<Map<String, dynamic>>> _fetchAllVendorDocuments() async {
    try {
      final supabase = Supabase.instance.client;
      final documents = <Map<String, dynamic>>[];

      // 1. Fetch from vendor_documents (for regular vendor users)
      final regularDocsResponse = await supabase
          .from('vendor_documents')
          .select('*')
          .order('uploaded_at', ascending: false);

      for (final docData in regularDocsResponse) {
        final vendorDocument = VendorDocument(
          id: docData['id'].toString(),
          type: _parseDocumentType(docData['document_type']),
          fileName: docData['file_name'] ?? '',
          fileUrl: docData['file_url'] ?? '',
          uploadedAt: DateTime.parse(docData['uploaded_at']),
          isVerified: docData['status'] == 'approved',
          verifiedAt: docData['reviewed_at'] != null ? DateTime.parse(docData['reviewed_at']) : null,
          verificationNotes: docData['rejection_reason'],
        );

        String vendorName = 'Unknown Vendor';
        try {
          final profileResponse = await supabase
              .from('vendor_profiles')
              .select('business_name, email')
              .eq('id', docData['vendor_profile_id'])
              .maybeSingle();

          if (profileResponse != null) {
            vendorName = profileResponse['business_name'] ??
                        profileResponse['email'] ??
                        'Unknown Vendor';
          }
        } catch (e) {
          print('Error fetching profile for doc ${docData['id']}: $e');
        }

        final vendor = AdminVendor(
          docData['vendor_profile_id'].toString(),
          vendorName,
          'Vendor',
          false,
          false,
          0.0,
          0,
          0,
          [],
          false,
          documents: [vendorDocument],
          documentsVerified: vendorDocument.isVerified,
        );

        documents.add({
          'document': vendorDocument,
          'vendor': vendor,
        });
      }

      // 2. Fetch from admin_vendor_documents (for admin-created vendors)
      final adminDocsResponse = await supabase
          .from('admin_vendor_documents')
          .select('*')
          .order('uploaded_at', ascending: false);

      for (final docData in adminDocsResponse) {
        final vendorDocument = VendorDocument(
          id: docData['id'].toString(),
          type: _parseDocumentType(docData['document_type']),
          fileName: docData['file_name'] ?? '',
          fileUrl: docData['file_url'] ?? '',
          uploadedAt: DateTime.parse(docData['uploaded_at']),
          isVerified: docData['status'] == 'approved',
          verifiedAt: docData['reviewed_at'] != null ? DateTime.parse(docData['reviewed_at']) : null,
          verificationNotes: docData['rejection_reason'],
        );

        String vendorName = 'Unknown Admin Vendor';
        try {
          final vendorResponse = await supabase
              .from('admin_vendors')
              .select('name')
              .eq('id', docData['admin_vendor_id'])
              .maybeSingle();

          if (vendorResponse != null) {
            vendorName = vendorResponse['name'] ?? 'Unknown Admin Vendor';
          }
        } catch (e) {
          print('Error fetching admin vendor for doc ${docData['id']}: $e');
        }

        final vendor = AdminVendor(
          docData['admin_vendor_id'].toString(),
          vendorName,
          'Admin Vendor',
          false,
          false,
          0.0,
          0,
          0,
          [],
          false,
          documents: [vendorDocument],
          documentsVerified: vendorDocument.isVerified,
        );

        documents.add({
          'document': vendorDocument,
          'vendor': vendor,
        });
      }

      return documents;
    } catch (e) {
      print('Error fetching vendor documents: $e');
      throw Exception('Failed to load vendor documents: $e');
    }
  }

  DocumentType _parseDocumentType(String typeString) {
    switch (typeString) {
      case 'business_license':
        return DocumentType.businessLicense;
      case 'tax_registration':
      case 'tax_certificate':
        return DocumentType.taxCertificate;
      case 'insurance_certificate':
        return DocumentType.insuranceCertificate;
      case 'identification':
        return DocumentType.identification;
      case 'bank_statement':
        return DocumentType.bankStatement;
      case 'halal_certificate':
      case 'professional_certifications':
      case 'other':
      default:
        return DocumentType.other;
    }
  }

Widget _buildDocumentReviewItem(BuildContext context, VendorDocument doc, AdminVendor vendor, AdminProvider admin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: doc.isVerified ? Colors.green[50] : Colors.orange[50],
      child: ListTile(
        leading: Icon(
          doc.isVerified ? Icons.check_circle : Icons.pending,
          color: doc.isVerified ? Colors.green : Colors.orange,
        ),
        title: Text(_getDocumentTypeName(doc.type)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(doc.fileName),
            Text(
              'Uploaded: ${doc.uploadedAt.toLocal().toString().split(' ')[0]}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: Image.network(
                doc.fileUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
              ),
            ),
            if (doc.verificationNotes != null)
              Text(
                'Notes: ${doc.verificationNotes}',
                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: doc.isVerified
            ? const Icon(Icons.verified, color: Colors.green)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () => _rejectDocument(context, doc, vendor, admin),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    child: const Text('Reject'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _verifyDocument(context, doc, vendor, admin),
                    child: const Text('Verify'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPerformanceTab(List<AdminVendor> vendors, AdminProvider admin) {
    // Sort vendors by performance (rating * bookings)
    final sortedVendors = List<AdminVendor>.from(vendors)
      ..sort(
          (a, b) => (b.rating * b.bookings).compareTo(a.rating * a.bookings));

    if (sortedVendors.isEmpty) {
      return const Center(
        child: Text(
          'No vendors available for performance analysis',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Performance Summary Cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildPerformanceStatCard(
                  'Top Performer',
                  sortedVendors.first.name,
                  '${sortedVendors.first.rating}★',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPerformanceStatCard(
                  'Most Bookings',
                  sortedVendors
                      .reduce((a, b) => a.bookings > b.bookings ? a : b)
                      .name,
                  '${sortedVendors.reduce((a, b) => a.bookings > b.bookings ? a : b).bookings}',
                  Colors.blue,
                ),
              ),
            ],
          ),
        ),

        // Performance List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedVendors.length,
            itemBuilder: (context, index) {
              final vendor = sortedVendors[index];
              final performanceScore = vendor.rating * vendor.bookings;
              return _buildPerformanceCard(vendor, performanceScore, index + 1);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVendorCard(
    BuildContext context,
    AdminVendor vendor,
    AdminProvider admin, {
    bool showActions = false,
    bool isPending = true,
    bool isSuspended = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.store,
                    color: AppTheme.primaryColor,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                if (vendor.documents.any((doc) => doc.type == DocumentType.businessLicense))
                  Builder(
                    builder: (context) {
                      final businessLicenseDoc = vendor.documents.firstWhere((doc) => doc.type == DocumentType.businessLicense);
                      return SizedBox(
                        width: 50,
                        height: 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: businessLicenseDoc.fileUrl != null && businessLicenseDoc.fileUrl.isNotEmpty
                            ? Image.network(
                                businessLicenseDoc.fileUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                              )
                            : const Icon(Icons.image_not_supported),
                        ),
                      );
                    },
                  ),
                if (vendor.documents.any((doc) => doc.type == DocumentType.businessLicense))
                  const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vendor.category,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            ' ${vendor.rating.toStringAsFixed(1)} (${vendor.reviews} reviews)',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: vendor.completionPercentage / 100,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  vendor.completionPercentage == 100 
                                      ? Colors.green 
                                      : AppTheme.primaryColor,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${vendor.completionPercentage}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      if (!vendor.isClaimed && vendor.claimCode != null) ...[
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: vendor.claimCode ?? ''));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Claim Code copied to clipboard!')),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              border: Border.all(color: Colors.blue),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.key, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  'Claim Code: ${vendor.claimCode}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.copy, size: 14, color: Colors.blue),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isPending)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Pending',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                else if (isSuspended)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Suspended',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                else if (vendor.verified)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Verified',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: vendor.registrationSource == 'admin' ? Colors.purple : Colors.blueGrey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vendor.registrationSource == 'admin' ? 'Admin Created' : 'Self-Registered',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Vendor Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Bookings',
                    '${vendor.bookings}',
                    Icons.book_online,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Service Areas',
                    '${vendor.serviceAreas.length}',
                    Icons.location_on,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Status',
                    vendor.suspended ? 'Suspended' : 'Active',
                    vendor.suspended ? Icons.block : Icons.check_circle,
                    vendor.suspended ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Document Status
            if (vendor.documents.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: vendor.documentsVerified
                      ? Colors.green[50]
                      : vendor.documents.any((doc) => !doc.isVerified)
                          ? Colors.orange[50]
                          : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: vendor.documentsVerified
                        ? Colors.green[200]!
                        : vendor.documents.any((doc) => !doc.isVerified)
                            ? Colors.orange[200]!
                            : Colors.blue[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          vendor.documentsVerified
                              ? Icons.verified
                              : vendor.documents.any((doc) => !doc.isVerified)
                                  ? Icons.pending
                                  : Icons.description,
                          color: vendor.documentsVerified
                              ? Colors.green[700]
                              : vendor.documents.any((doc) => !doc.isVerified)
                                  ? Colors.orange[700]
                                  : Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Documents',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: vendor.documentsVerified
                                ? Colors.green[700]
                                : vendor.documents.any((doc) => !doc.isVerified)
                                    ? Colors.orange[700]
                                    : Colors.blue[700],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${vendor.documents.where((doc) => doc.isVerified).length}/${vendor.documents.length} verified',
                          style: TextStyle(
                            fontSize: 12,
                            color: vendor.documentsVerified
                                ? Colors.green[600]
                                : vendor.documents.any((doc) => !doc.isVerified)
                                    ? Colors.orange[600]
                                    : Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showDocumentDetails(context, vendor),
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        if (vendor.documents.any((doc) => !doc.isVerified)) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _verifyAllDocuments(context, vendor, admin),
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Verify All'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[100],
                                foregroundColor: Colors.green[700],
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],

            if (showActions) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Document Action Button (if vendor has documents)
              if (vendor.documents.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showDocumentDetails(context, vendor),
                    icon: const Icon(Icons.description),
                    label: const Text('View Documents'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Action Buttons
              Row(
                children: [
                  if (isPending) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => admin.approveVendor(vendor.id),
                        icon: const Icon(Icons.check),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => admin.rejectVendor(vendor.id),
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showVendorDetails(vendor),
                        icon: const Icon(Icons.visibility),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showVendorActions(vendor, admin),
                        icon: const Icon(Icons.more_vert),
                        label: const Text('Actions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(AdminVendor vendor, double score, int rank) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: rank <= 3 ? Colors.amber : Colors.grey[300],
          child: Text(
            '$rank',
            style: TextStyle(
              color: rank <= 3 ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(vendor.name),
        subtitle: Text(
            '${vendor.category} • ${vendor.rating}★ • ${vendor.bookings} bookings'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Score: ${score.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              'RM ${(vendor.bookings * 100).toString()}',
              style: TextStyle(color: Colors.green[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceStatCard(
      String title, String value, String subtitle, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.trending_up, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
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
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  List<AdminVendor> _filterVendors(List<AdminVendor> vendors) {
    return vendors.where((vendor) {
      final matchesSearch = vendor.name
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          vendor.category.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesCategory =
          _filterCategory == 'All' || vendor.category == _filterCategory;

      final matchesStatus = _filterStatus == 'All' ||
          (_filterStatus == 'Active' && !vendor.suspended && vendor.verified) ||
          (_filterStatus == 'Pending' && vendor.pendingApproval) ||
          (_filterStatus == 'Suspended' && vendor.suspended);

      return matchesSearch && matchesCategory && matchesStatus;
    }).toList();
  }

  void _showVendorDetails(AdminVendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.business, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Expanded(child: Text(vendor.name)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailSection('Basic Information', [
                  _buildDetailRow('Category', vendor.category),
                  _buildDetailRow('Subcategories', vendor.subcategories.join(', ')),
                  _buildDetailRow('Source', vendor.registrationSource == 'admin' ? 'Admin Created' : 'Self-Registered'),
                  _buildDetailRow('Status', vendor.suspended ? 'Suspended' : 'Active', 
                      color: vendor.suspended ? Colors.red : Colors.green),
                  _buildDetailRow('Verified', vendor.verified ? 'Yes' : 'No',
                      color: vendor.verified ? Colors.green : Colors.orange),
                  _buildDetailRow('Completion', '${vendor.completionPercentage}%'),
                ]),
                const Divider(),
                _buildDetailSection('Contact Information', [
                  _buildDetailRow('Email', vendor.email ?? 'N/A'),
                  _buildDetailRow('Phone', vendor.phone ?? 'N/A'),
                  _buildDetailRow('Address', vendor.address ?? 'N/A'),
                ]),
                const Divider(),
                _buildDetailSection('Legal & Business', [
                  _buildDetailRow('Legal Name', vendor.legalName ?? 'N/A'),
                  _buildDetailRow('SSM Number', vendor.ssmNumber ?? 'N/A'),
                  _buildDetailRow('Business Type', vendor.businessType ?? 'N/A'),
                  _buildDetailRow('Starting Price', vendor.startingPrice != null ? 'RM ${vendor.startingPrice}' : 'N/A'),
                ]),
                const Divider(),
                _buildDetailSection('Performance', [
                  _buildDetailRow('Rating', '${vendor.rating} (${vendor.reviews} reviews)'),
                  _buildDetailRow('Bookings', vendor.bookings.toString()),
                  _buildDetailRow('Priority Score', vendor.priorityScore.toString()),
                  _buildDetailRow('Service Areas', vendor.serviceAreas.join(', ')),
                ]),
                const Divider(),
                _buildDetailSection('Account Status', [
                  _buildDetailRow('Claimed', vendor.isClaimed ? 'Yes' : 'No'),
                  if (!vendor.isClaimed) _buildDetailRow('Claim Code', vendor.claimCode ?? 'N/A'),
                  _buildDetailRow('Subscription', vendor.subscriptionTier.toUpperCase()),
                  if (vendor.subscriptionExpiry != null)
                    _buildDetailRow('Expiry', vendor.subscriptionExpiry!.toLocal().toString().split(' ')[0]),
                  _buildDetailRow('Commission', '${((vendor.commissionRate ?? 0) * 100).toStringAsFixed(1)}% ${vendor.commissionOverride ? '(Override)' : '(Standard)'}'),
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showVendorActions(vendor, context.read<AdminProvider>());
            },
            child: const Text('Manage'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showVendorActions(AdminVendor vendor, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actions for ${vendor.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.switch_account, color: Colors.orange),
              title: const Text(
                'Login as Vendor (Impersonate)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('View and manage app as this vendor'),
              onTap: () async {
                Navigator.pop(context);
                final auth = context.read<AuthProvider>();
                final adminId = auth.userId ?? Supabase.instance.client.auth.currentUser?.id ?? 'admin';
                final adminEmail = auth.userEmail;
                final ok = await AdminImpersonationService.instance.startImpersonation(
                  adminId: adminId,
                  targetUserId: vendor.id,
                  targetRole: 'vendor',
                  vendorName: vendor.name,
                  adminEmail: adminEmail,
                );
                if (ok && context.mounted) {
                  await context.read<VendorProvider>().loadCurrentVendorFromSupabase(force: true);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Impersonating ${vendor.name}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VendorDashboardScreen()),
                    );
                  }
                }
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('View Documents'),
              onTap: () {
                Navigator.pop(context);
                _showDocumentDetails(context, vendor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Colors.amber),
              title: const Text('Boost Listing (Priority Score)'),
              onTap: () {
                Navigator.pop(context);
                _showPriorityScoreDialog(context, vendor, admin);
              },
            ),
            ListTile(
              leading: const Icon(Icons.design_services),
              title: const Text('Manage Services'),
              onTap: () {
                Navigator.pop(context);
                _showVendorServicesManagement(vendor, admin);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                _showEditProfileDialog(context, vendor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Manage Service Areas'),
              onTap: () {
                Navigator.pop(context);
                _showServiceAreasDialog(context, vendor, context.read<AdminProvider>());
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('View Calendar'),
              onTap: () {
                Navigator.pop(context);
                _showVendorCalendar(context, vendor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Performance Report'),
              onTap: () {
                Navigator.pop(context);
                _showPerformanceReport(context, vendor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.payment, color: Colors.blue),
              title: const Text('Manage Installments'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VendorInstallmentSettingsScreen(vendorId: vendor.id),
                  ),
                );
              },
            ),
            if (vendor.suspended)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Activate Vendor'),
                onTap: () {
                  admin.activateVendor(vendor.id);
                  Navigator.pop(context);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Suspend Vendor'),
                onTap: () {
                  admin.suspendVendor(vendor.id, suspended: true);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showPriorityScoreDialog(BuildContext context, AdminVendor vendor, AdminProvider admin) {
    final scoreController = TextEditingController(text: vendor.priorityScore.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Priority Score Manager'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Higher priority scores surface vendors higher in the marketplace. Normal is 0, Featured is +100.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: scoreController,
              decoration: const InputDecoration(
                labelText: 'Priority Score',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Normal (0)'),
                  onPressed: () => scoreController.text = '0.0',
                ),
                ActionChip(
                  label: const Text('New (+30)'),
                  onPressed: () => scoreController.text = '30.0',
                ),
                ActionChip(
                  label: const Text('Featured (+100)'),
                  backgroundColor: Colors.amber[100],
                  onPressed: () => scoreController.text = '100.0',
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newScore = double.tryParse(scoreController.text) ?? 0.0;
              admin.updateVendorPriorityScore(vendor.id, newScore);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Priority score updated!')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Edit Profile Dialog
  void _showEditProfileDialog(BuildContext context, AdminVendor vendor) {
    final nameController = TextEditingController(text: vendor.name);
    final categoryController = TextEditingController(text: vendor.category);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Vendor Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Business Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Update vendor profile
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  final Map<String, Map<String, List<String>>> serviceAreasHierarchy = {
  "Malaysia": {
    "Selangor": ["Petaling Jaya", "Shah Alam", "Subang Jaya"],
    "Kuala Lumpur": ["Cheras", "Wangsa Maju", "Bukit Bintang"],
    "Penang": ["George Town", "Bayan Lepas"],
  },
  "Singapore": {
    "Central Region": ["Orchard", "Marina Bay"],
    "East Region": ["Tampines", "Changi"],
  }
};

  // Service Areas Dialog
  void _showServiceAreasDialog(BuildContext context, AdminVendor vendor, AdminProvider admin) {
  Map<String, Map<String, List<String>>> areas = serviceAreasHierarchy;
  Set<String> selectedAreas = vendor.serviceAreas.toSet();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: const Text('Select Service Areas'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: ListView(
              children: areas.entries.map((countryEntry) {
                final country = countryEntry.key;
                final states = countryEntry.value;

                return ExpansionTile(
                  title: Row(
                    children: [
                      Checkbox(
                        value: states.values
                            .expand((cities) => cities)
                            .every((city) => selectedAreas.contains(city)),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              states.values
                                  .expand((cities) => cities)
                                  .forEach(selectedAreas.add);
                            } else {
                              states.values
                                  .expand((cities) => cities)
                                  .forEach(selectedAreas.remove);
                            }
                          });
                        },
                      ),
                      Text(country),
                    ],
                  ),
                  children: states.entries.map((stateEntry) {
                    final state = stateEntry.key;
                    final cities = stateEntry.value;

                    return ExpansionTile(
                      title: Row(
                        children: [
                          Checkbox(
                            value: cities
                                .every((c) => selectedAreas.contains(c)),
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  cities.forEach(selectedAreas.add);
                                } else {
                                  cities.forEach(selectedAreas.remove);
                                }
                              });
                            },
                          ),
                          Text(state),
                        ],
                      ),
                      children: cities.map((city) {
                        return CheckboxListTile(
                          value: selectedAreas.contains(city),
                          onChanged: (checked) {
                            setState(() {
                              if (checked == true) {
                                selectedAreas.add(city);
                              } else {
                                selectedAreas.remove(city);
                              }
                            });
                          },
                          title: Text(city),
                        );
                      }).toList(),
                    );
                  }).toList(),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  await admin.updateVendorServiceAreas(
                    vendor.id,
                    selectedAreas.toList(),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Service areas updated: ${selectedAreas.join(", ")}'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to update service areas: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    ),
  );
}


// Vendor Calendar View
void _showVendorCalendar(BuildContext context, AdminVendor vendor) {
  // Dummy booking dates contoh – kau boleh ganti dengan data betul dari vendor
  final List<DateTime> bookingDates = [
    DateTime.now(),
    DateTime.now().add(const Duration(days: 2)),
    DateTime.now().add(const Duration(days: 5)),
    DateTime.now().add(const Duration(days: 10)),
  ];

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${vendor.name} - Calendar'),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Column(
          children: [
            Expanded(
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: DateTime.now(),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                availableGestures: AvailableGestures.all,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                ),
                selectedDayPredicate: (day) {
                  // highlight booking dates
                  return bookingDates.any((d) =>
                      d.year == day.year &&
                      d.month == day.month &&
                      d.day == day.day);
                },
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Summary',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('${vendor.bookings} total bookings'),
                  Text('Rating: ${vendor.rating.toStringAsFixed(1)}/5.0'),
                  Text('Service Areas: ${vendor.serviceAreas.join(", ")}'),
                ],
              ),
            ),
          ],
        ),
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


  // Performance Report
  void _showPerformanceReport(BuildContext context, AdminVendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${vendor.name} - Performance Report'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportCard(
                    'Total Bookings', vendor.bookings.toString(), Icons.event),
                _buildReportCard('Average Rating',
                    vendor.rating.toStringAsFixed(1), Icons.star),
                _buildReportCard(
                    'Total Reviews', vendor.reviews.toString(), Icons.reviews),
                _buildReportCard('Service Areas',
                    vendor.serviceAreas.length.toString(), Icons.location_on),
                _buildReportCard(
                    'Status',
                    vendor.suspended ? 'Suspended' : 'Active',
                    vendor.suspended ? Icons.block : Icons.check_circle),
                const SizedBox(height: 16),
                const Text('Performance Metrics:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: vendor.rating / 5.0,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    vendor.rating >= 4.0
                        ? Colors.green
                        : vendor.rating >= 3.0
                            ? Colors.orange
                            : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Rating: ${vendor.rating.toStringAsFixed(1)}/5.0'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Export report functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Report exported successfully')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title),
        trailing:
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _verifyDocument(BuildContext context, VendorDocument doc, AdminVendor vendor, AdminProvider admin) {
    print('DEBUG UI: _verifyDocument clicked for ${doc.fileName} (${doc.id}) for vendor ${vendor.name} (${vendor.id})');
    admin.verifyDocument(vendor.id, doc.id, notes: 'Verified by admin').then((_) {
      print('DEBUG UI: _verifyDocument provider call completed for ${doc.id}');
      // Refresh the documents list after verification
      setState(() {
        _documentsRefreshKey++;
      });
    }).catchError((error) {
      print('DEBUG UI ERROR: _verifyDocument failed: $error');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${doc.fileName} verified successfully')),
    );
  }

  void _verifyAllDocuments(BuildContext context, AdminVendor vendor, AdminProvider admin) {
    print('DEBUG UI: _verifyAllDocuments clicked for vendor ${vendor.name} (${vendor.id})');
    admin.verifyAllDocuments(vendor.id, notes: 'Bulk verification by admin').then((_) {
      print('DEBUG UI: _verifyAllDocuments provider call completed for ${vendor.id}');
      // Refresh the documents list after verification
      setState(() {
        _documentsRefreshKey++;
      });
    }).catchError((error) {
      print('DEBUG UI ERROR: _verifyAllDocuments failed: $error');
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All documents for ${vendor.name} verified successfully')),
    );
  }

  void _rejectDocument(BuildContext context, VendorDocument doc, AdminVendor vendor, AdminProvider admin) {
    print('DEBUG UI: _rejectDocument clicked for ${doc.fileName} (${doc.id}) for vendor ${vendor.name} (${vendor.id})');
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Document'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Rejection Reason'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text;
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              admin.rejectDocument(vendor.id, doc.id, notes: reason).then((_) {
                setState(() => _documentsRefreshKey++);
                Navigator.pop(context);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _rejectAllDocuments(BuildContext context, AdminVendor vendor, AdminProvider admin) {
    print('DEBUG UI: _rejectAllDocuments clicked for vendor ${vendor.name} (${vendor.id})');
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject All Documents'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Rejection Reason'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text;
              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              admin.rejectAllDocuments(vendor.id, notes: reason).then((_) {
                setState(() => _documentsRefreshKey++);
                Navigator.pop(context);
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject All'),
          ),
        ],
      ),
    );
  }


  void _downloadFile(String url, String fileName) {
    if (kIsWeb) {
      // For Flutter Web, open the file URL in a new tab (browser will handle download if file)
      html.window.open(url, '_blank');
    } else {
      // For other platforms, implementation can be extended as needed
      // For now, show notification that download is not supported
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download is not supported on this platform')),
      );
    }
  }

  Future<void> _exportVendorsToCSV(BuildContext context) async {
    try {
      final admin = Provider.of<AdminProvider>(context, listen: false);
      final vendors = admin.vendors;
    
      // Create CSV header
      final csvHeader = 'Name,Category,Rating,Reviews,Bookings,Service Areas,Status,Verified,Suspended\n';
    
      // Create CSV rows
      final csvRows = vendors.map((vendor) {
        final serviceAreas = vendor.serviceAreas.join(';');
        final status = vendor.suspended ? 'Suspended' : 'Active';
        return '${vendor.name},${vendor.category},${vendor.rating},${vendor.reviews},${vendor.bookings},"$serviceAreas",$status,${vendor.verified},${vendor.suspended}';
      }).join('\n');
    
      final csvContent = csvHeader + csvRows;
    
      if (kIsWeb) {
        // For Flutter Web, create a Blob and trigger download
        final bytes = Uint8List.fromList(csvContent.codeUnits);
        final blob = html.Blob([bytes], 'text/csv');
        final url = html.Url.createObjectUrlFromBlob(blob);
    
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'vendors_export_${DateTime.now().millisecondsSinceEpoch}.csv')
          ..click();
    
        html.Url.revokeObjectUrl(url);
      } else {
        // Non-web platforms: existing logic
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'vendors_export_${DateTime.now().millisecondsSinceEpoch}.csv';
        final file = File('${directory.path}/$fileName');
    
        // Write CSV content to file
        await file.writeAsString(csvContent);
    
        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Vendor Management Export',
        );
      }
    
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vendors exported successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
  void _showDocumentDetails(BuildContext context, AdminVendor vendor) {
    final admin = Provider.of<AdminProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<VendorDocument>>(
        future: admin.getVendorDocuments(vendor.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
              content: SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              title: Text('${vendor.name} - Document Details'),
              content: const Text('Error loading documents'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          }

          final documents = snapshot.data ?? [];
          final verifiedCount = documents.where((doc) => doc.isVerified).length;
          final pendingCount = documents.length - verifiedCount;

          return AlertDialog(
            title: Text('${vendor.name} - Documents (${documents.length})'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: documents.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.description_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No documents found',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This vendor has not uploaded any documents yet.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      // Summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDocSummaryItem('Total', documents.length, Colors.blue),
                            _buildDocSummaryItem('Verified', verifiedCount, Colors.green),
                            _buildDocSummaryItem('Pending', pendingCount, Colors.orange),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Documents List
                      Expanded(
                        child: ListView(
                          children: documents.map((doc) {
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  doc.isVerified ? Icons.check_circle : Icons.pending,
                                  color: doc.isVerified ? Colors.green : Colors.orange,
                                ),
                                title: Text(_getDocumentTypeName(doc.type)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('File: ${doc.fileName}'),
                                    Text('Uploaded: ${doc.uploadedAt.toLocal()}'),
                                    if (doc.isVerified && doc.verifiedAt != null)
                                      Text('Verified: ${doc.verifiedAt!.toLocal()}'),
                                    if (doc.verificationNotes != null)
                                      Text('Notes: ${doc.verificationNotes}'),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      height: 100,
                                      child: doc.fileUrl != null && doc.fileUrl.isNotEmpty
                                        ? Image.network(
                                            doc.fileUrl,
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported),
                                          )
                                        : const Icon(Icons.image_not_supported, size: 50),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.download),
                                      onPressed: () {
                                        _downloadFile(doc.fileUrl, doc.fileName);
                                      },
                                    ),
                                    if (!doc.isVerified)
                                      ElevatedButton(
                                        onPressed: () => _verifyDocument(context, doc, vendor, admin),
                                        child: const Text('Verify'),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDocumentPreview(BuildContext context, VendorDocument doc, AdminVendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_getDocumentTypeName(doc.type)} - Preview'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vendor: ${vendor.name}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('File: ${doc.fileName}'),
                    Text('Uploaded: ${doc.uploadedAt.toLocal().toString().split(' ')[0]}'),
                    Text('Status: ${doc.isVerified ? 'Verified' : 'Pending Review'}'),
                    if (doc.verificationNotes != null && doc.verificationNotes!.isNotEmpty)
                      Text('Notes: ${doc.verificationNotes}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Document Preview
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: doc.fileUrl != null && doc.fileUrl.isNotEmpty
                    ? Image.network(
                        doc.fileUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Preview not available', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          );
                        },
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('No preview available', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!doc.isVerified)
            ElevatedButton(
              onPressed: () {
                final admin = Provider.of<AdminProvider>(context, listen: false);
                _verifyDocument(context, doc, vendor, admin);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Verify Document'),
            ),
        ],
      ),
    );
  }

  Widget _buildDocSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _getDocumentTypeName(DocumentType type) {
    switch (type) {
      case DocumentType.businessLicense:
        return 'Business License';
      case DocumentType.taxCertificate:
        return 'Tax Certificate';
      case DocumentType.insuranceCertificate:
        return 'Insurance Certificate';
      case DocumentType.identification:
        return 'Identification';
      case DocumentType.bankStatement:
        return 'Bank Statement';
      case DocumentType.other:
        return 'Other Document';
      default:
        return 'Unknown Document';
    }
  }
  Widget _buildServicesPackagesTab(List<AdminVendor> vendors, AdminProvider admin) {
    Widget _buildServiceStatCard(String title, String value, IconData icon, Color color) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    void _showVendorServicesAndDocuments(AdminVendor vendor, List<VendorService> services, AdminProvider admin) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.business,
                      color: AppTheme.primaryColor,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vendor.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${vendor.category} • ${services.length} services',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Services Section
              const Text(
                'Services',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Service Header
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        service.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        service.category.displayName,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: service.active ? Colors.green[100] : Colors.red[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    service.active ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      color: service.active ? Colors.green[800] : Colors.red[800],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            // Service Price
                            Text(
                              'RM ${service.basePrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Documents Section
                            if (service.requirements != null && service.requirements!['documents'] != null) ...[
                              const Text(
                                'Required Documents:',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: (service.requirements!['documents'] as List<dynamic>)
                                    .map((doc) => Chip(
                                          label: Text(
                                            doc.toString(),
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          backgroundColor: Colors.blue[50],
                                          labelStyle: TextStyle(color: Colors.blue[800]),
                                        ))
                                    .toList(),
                              ),
                            ] else ...[
                              const Text(
                                'No documents required',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    void _approveService(VendorService service, AdminVendor vendor, AdminProvider admin) {
      // In a real app, this would update the service approval status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${service.name} approved successfully')),
      );
    }

    void _rejectService(VendorService service, AdminVendor vendor, AdminProvider admin) {
      // In a real app, this would update the service approval status
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${service.name} rejected')),
      );
    }

    void _viewServiceDetails(VendorService service) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${service.name} Details'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Description: ${service.description}'),
                  const SizedBox(height: 8),
                  Text('Category: ${service.category.displayName}'),
                  Text('Type: ${service.type.toString().split('.').last}'),
                  Text('Base Price: RM ${service.basePrice.toStringAsFixed(0)}'),
                  if (service.hourlyRate != null)
                    Text('Hourly Rate: RM ${service.hourlyRate!.toStringAsFixed(0)}'),
                  Text('Active: ${service.active ? 'Yes' : 'No'}'),
                  Text('Max Bookings/Day: ${service.maxBookingsPerDay}'),
                  Text('Advance Booking Days: ${service.advanceBookingDays}'),
                  const SizedBox(height: 16),
                  const Text('Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Wrap(
                    spacing: 8,
                    children: service.images.map((image) => Chip(label: Text(image.split('/').last))).toList(),
                  ),
                ],
              ),
            ),
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

    void _editService(VendorService service, AdminVendor vendor, AdminProvider admin) {
      // In a real app, this would open an edit dialog or navigate to an edit screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Edit functionality coming soon')),
      );
    }

    void _toggleServiceStatus(VendorService service, AdminVendor vendor, AdminProvider admin) {
      // In a real app, this would update the service status
      final newStatus = !service.active;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${service.name} ${newStatus ? 'activated' : 'deactivated'} successfully'),
        ),
      );
    }


    final allServices = VendorServicesData.getAllServices();

    // Group services by vendor
    final Map<String, List<VendorService>> servicesByVendor = {};
    for (final service in allServices) {
      if (!servicesByVendor.containsKey(service.vendorId)) {
        servicesByVendor[service.vendorId] = [];
      }
      servicesByVendor[service.vendorId]!.add(service);
    }

    // Filter vendors that have services
    final vendorsWithServices = vendors.where((vendor) =>
        servicesByVendor.containsKey(vendor.id) &&
        servicesByVendor[vendor.id]!.isNotEmpty).toList();

    return Column(
      children: [
        // Summary Cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildServiceStatCard(
                  'Total Services',
                  allServices.length.toString(),
                  Icons.design_services,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildServiceStatCard(
                  'Active Services',
                  allServices.whereType<VendorService>().where((s) => s.active).length.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildServiceStatCard(
                  'Pending Approval',
                  allServices.whereType<VendorService>().where((s) => s.approvalStatus.toString() == 'pending').length.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ),

        // Services List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: vendorsWithServices.length,
            itemBuilder: (context, index) {
              final vendor = vendorsWithServices[index];
              final vendorServices = servicesByVendor[vendor.id]!;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.business,
                      color: AppTheme.primaryColor,
                      size: 25,
                    ),
                  ),
                  title: Text(
                    vendor.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${vendor.category} • ${vendorServices.length} services'),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${vendor.rating.toStringAsFixed(1)}'),
                          const SizedBox(width: 16),
                          Text('${vendor.bookings} bookings'),
                        ],
                      ),
                    ],
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () => _showVendorServicesAndDocuments(vendor, vendorServices, admin),
                    icon: const Icon(Icons.more_vert, size: 16),
                    label: const Text('Actions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  children: vendorServices.map((service) => _buildServiceItem(service, vendor, admin)).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportsTab(List<AdminVendor> vendors, AdminProvider admin) {
    final totalVendors = vendors.length;
    final activeVendors = vendors.where((v) => !v.suspended && v.verified).length;
    final suspendedVendors = vendors.where((v) => v.suspended).length;
    final pendingVendors = admin.pendingApprovalVendors.length;
    final totalBookings = vendors.fold<int>(0, (sum, v) => sum + v.bookings);
    final averageRating = vendors.isEmpty ? 0.0 : vendors.map((v) => v.rating).reduce((a, b) => a + b) / vendors.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Vendor Reports & Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Summary Statistics
          const Text(
            'Overall Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildReportStatCard(
                'Total Vendors',
                totalVendors.toString(),
                Icons.business,
                Colors.blue,
              ),
              _buildReportStatCard(
                'Active Vendors',
                activeVendors.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              _buildReportStatCard(
                'Suspended Vendors',
                suspendedVendors.toString(),
                Icons.block,
                Colors.red,
              ),
              _buildReportStatCard(
                'Pending Approval',
                pendingVendors.toString(),
                Icons.pending,
                Colors.orange,
              ),
              _buildReportStatCard(
                'Total Bookings',
                totalBookings.toString(),
                Icons.event,
                Colors.purple,
              ),
              _buildReportStatCard(
                'Average Rating',
                averageRating.toStringAsFixed(1),
                Icons.star,
                Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Report Actions
          const Text(
            'Generate Reports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download, color: AppTheme.primaryColor),
                    title: const Text('Export Vendors to CSV'),
                    subtitle: const Text('Download complete vendor list with all details'),
                    trailing: ElevatedButton(
                      onPressed: () => _exportVendorsToCSV(context),
                      child: const Text('Export'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.analytics, color: AppTheme.primaryColor),
                    title: const Text('Performance Report'),
                    subtitle: const Text('Generate detailed performance analytics'),
                    trailing: ElevatedButton(
                      onPressed: () => _generatePerformanceReport(vendors),
                      child: const Text('Generate'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.assessment, color: AppTheme.primaryColor),
                    title: const Text('Revenue Report'),
                    subtitle: const Text('Export revenue and booking statistics'),
                    trailing: ElevatedButton(
                      onPressed: () => _generateRevenueReport(vendors),
                      child: const Text('Generate'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Category Breakdown
          const Text(
            'Vendors by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: _buildCategoryBreakdown(vendors),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCategoryBreakdown(List<AdminVendor> vendors) {
    final categoryCount = <String, int>{};
    for (final vendor in vendors) {
      categoryCount[vendor.category] = (categoryCount[vendor.category] ?? 0) + 1;
    }

    return categoryCount.entries.map((entry) {
      final percentage = (entry.value / vendors.length * 100).toStringAsFixed(1);
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                entry.key,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Text('${entry.value} vendors (${percentage}%)'),
          ],
        ),
      );
    }).toList();
  }

  void _generatePerformanceReport(List<AdminVendor> vendors) {
    // Sort vendors by performance
    final sortedVendors = List<AdminVendor>.from(vendors)
      ..sort((a, b) => (b.rating * b.bookings).compareTo(a.rating * a.bookings));

    // In a real app, this would generate a PDF or detailed report
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Performance report generated successfully')),
    );
  }

  void _generateRevenueReport(List<AdminVendor> vendors) {
    final totalRevenue = vendors.fold<double>(0, (sum, vendor) => sum + (vendor.bookings * 100));

    // In a real app, this would generate a detailed revenue report
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Revenue report generated. Total estimated revenue: RM ${totalRevenue.toStringAsFixed(0)}')),
    );
  }

  Widget _buildServiceItem(VendorService service, AdminVendor vendor, AdminProvider admin) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${service.category.displayName} • ${service.type.toString().split('.').last}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: service.approvalStatus.toString() == 'approved'
                      ? Colors.green[100]
                      : service.approvalStatus.toString() == 'pending'
                          ? Colors.orange[100]
                          : Colors.red[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  service.approvalStatus.toString().split('.').last.toUpperCase(),
                  style: TextStyle(
                    color: service.approvalStatus.toString() == 'approved'
                        ? Colors.green[800]
                        : service.approvalStatus.toString() == 'pending'
                            ? Colors.orange[800]
                            : Colors.red[800],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Service Details
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RM ${service.basePrice.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (service.hourlyRate != null)
                      Text(
                        'Hourly: RM ${service.hourlyRate!.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    service.active ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: service.active ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Max ${service.maxBookingsPerDay}/day',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Action Buttons
          Row(
            children: [
              if (service.approvalStatus == ApprovalStatus.pending) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveService(service, vendor, admin),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectService(service, vendor, admin),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewServiceDetails(service),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editService(service, vendor, admin),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _approveService(VendorService service, AdminVendor vendor, AdminProvider admin) {
    // In a real app, this would update the service approval status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${service.name} approved successfully')),
    );
  }

  void _rejectService(VendorService service, AdminVendor vendor, AdminProvider admin) {
    // In a real app, this would update the service approval status
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${service.name} rejected')),
    );
  }

  void _viewServiceDetails(VendorService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${service.name} Details'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description: ${service.description}'),
                const SizedBox(height: 8),
                Text('Category: ${service.category.displayName}'),
                Text('Type: ${service.type.toString().split('.').last}'),
                Text('Base Price: RM ${service.basePrice.toStringAsFixed(0)}'),
                if (service.hourlyRate != null)
                  Text('Hourly Rate: RM ${service.hourlyRate!.toStringAsFixed(0)}'),
                Text('Active: ${service.active ? 'Yes' : 'No'}'),
                Text('Max Bookings/Day: ${service.maxBookingsPerDay}'),
                Text('Advance Booking Days: ${service.advanceBookingDays}'),
                const SizedBox(height: 16),
                const Text('Images:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  spacing: 8,
                  children: service.images.map((image) => Chip(label: Text(image.split('/').last))).toList(),
                ),
              ],
            ),
          ),
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

  void _editService(VendorService service, AdminVendor vendor, AdminProvider admin) {
    if (service is VendorService) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedServiceCreationScreen(
            vendorId: vendor.id,
            existingService: service.toEnhanced(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot edit this type of service yet')),
      );
    }
  }

  void _showVendorServicesManagement(AdminVendor vendor, AdminProvider admin) {
    final vendorServices = VendorServicesData.getServicesByVendor(vendor.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${vendor.name} - Service Management'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Column(
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text('Total Services'),
                        Text(vendorServices.length.toString()),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Active'),
                        Text(vendorServices.whereType<VendorService>().where((s) => s.active).length.toString()),
                      ],
                    ),
                    Column(
                      children: [
                        Text('Inactive'),
                        Text(vendorServices.whereType<VendorService>().where((s) => !s.active).length.toString()),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: vendorServices.length,
                  itemBuilder: (context, index) {
                    final service = vendorServices[index];
                    return _buildServiceItem(service, vendor, admin);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context); // Close dialog before navigating
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EnhancedServiceCreationScreen(vendorId: vendor.id),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Service'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showServiceManagementActions(VendorService service, AdminVendor vendor, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actions for ${service.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (service.approvalStatus == ApprovalStatus.pending) ...[
              ListTile(
                leading: const Icon(Icons.check, color: Colors.green),
                title: const Text('Approve Service'),
                onTap: () {
                  Navigator.pop(context);
                  _approveService(service, vendor, admin);
                },
              ),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.red),
                title: const Text('Reject Service'),
                onTap: () {
                  Navigator.pop(context);
                  _rejectService(service, vendor, admin);
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.visibility),
                title: const Text('View Details'),
                onTap: () {
                  Navigator.pop(context);
                  _viewServiceDetails(service);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Service'),
                onTap: () {
                  Navigator.pop(context);
                  _editService(service, vendor, admin);
                },
              ),
              ListTile(
                leading: Icon(
                  service.active ? Icons.block : Icons.check_circle,
                  color: service.active ? Colors.red : Colors.green,
                ),
                title: Text(service.active ? 'Deactivate Service' : 'Activate Service'),
                onTap: () {
                  Navigator.pop(context);
                  _toggleServiceStatus(service, vendor, admin);
                },
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _toggleServiceStatus(VendorService service, AdminVendor vendor, AdminProvider admin) {
    // In a real app, this would update the service status
    final newStatus = !service.active;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${service.name} ${newStatus ? 'activated' : 'deactivated'} successfully'),
      ),
    );
  }

  void _showVendorServicesAndDocuments(AdminVendor vendor, List<VendorService> services, AdminProvider admin) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.business,
                    color: AppTheme.primaryColor,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${vendor.category} • ${services.length} services',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Services Section
            const Text(
              'Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Service Header
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      service.category.displayName,
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: service.active ? Colors.green[100] : Colors.red[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  service.active ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: service.active ? Colors.green[800] : Colors.red[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Service Price
                          Text(
                            'RM ${service.basePrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Documents Section
                          if (service.requirements != null && service.requirements!['documents'] != null) ...[
                            const Text(
                              'Required Documents:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: (service.requirements!['documents'] as List<dynamic>)
                                  .map((doc) => Chip(
                                        label: Text(
                                          doc.toString(),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        backgroundColor: Colors.blue[50],
                                        labelStyle: TextStyle(color: Colors.blue[800]),
                                      ))
                                  .toList(),
                            ),
                          ] else ...[
                            const Text(
                              'No documents required',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab(List<AdminVendor> vendors, AdminProvider admin) {
    final totalVendors = vendors.length;
    final activeVendors = vendors.where((v) => !v.suspended && v.verified).length;
    final totalBookings = vendors.fold<int>(0, (sum, v) => sum + v.bookings);
    final averageRating = vendors.isEmpty ? 0.0 : vendors.map((v) => v.rating).reduce((a, b) => a + b) / vendors.length;
    final totalRevenue = vendors.fold<double>(0, (sum, vendor) => sum + (vendor.bookings * 100));

    // Category analytics
    final categoryStats = <String, Map<String, dynamic>>{};
    for (final vendor in vendors) {
      if (!categoryStats.containsKey(vendor.category)) {
        categoryStats[vendor.category] = {
          'count': 0,
          'totalBookings': 0,
          'totalRating': 0.0,
          'totalRevenue': 0.0,
        };
      }
      categoryStats[vendor.category]!['count']++;
      categoryStats[vendor.category]!['totalBookings'] += vendor.bookings;
      categoryStats[vendor.category]!['totalRating'] += vendor.rating;
      categoryStats[vendor.category]!['totalRevenue'] += vendor.bookings * 100;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Vendor Analytics Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Key Metrics Cards
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsMetricCard(
                  'Total Revenue',
                  'RM ${totalRevenue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsMetricCard(
                  'Avg Rating',
                  averageRating.toStringAsFixed(1),
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsMetricCard(
                  'Total Bookings',
                  totalBookings.toString(),
                  Icons.event,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsMetricCard(
                  'Active Vendors',
                  '$activeVendors/$totalVendors',
                  Icons.business,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Category Performance
          const Text(
            'Category Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...categoryStats.entries.map((entry) {
            final category = entry.key;
            final stats = entry.value;
            final avgRating = stats['totalRating'] / stats['count'];
            final revenue = stats['totalRevenue'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${stats['count']} vendors',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Revenue',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'RM ${revenue.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Avg Rating',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                  Text(
                                    avgRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Bookings',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${stats['totalBookings']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 32),

          // Performance Insights
          const Text(
            'Performance Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInsightItem(
                    'Top Performing Category',
                    categoryStats.entries.isEmpty
                        ? 'N/A'
                        : categoryStats.entries
                            .reduce((a, b) => a.value['totalRevenue'] > b.value['totalRevenue'] ? a : b)
                            .key,
                    Icons.trending_up,
                    Colors.green,
                  ),
                  const Divider(),
                  _buildInsightItem(
                    'Highest Rated Category',
                    categoryStats.entries.isEmpty
                        ? 'N/A'
                        : categoryStats.entries
                            .reduce((a, b) => (a.value['totalRating'] / a.value['count']) > (b.value['totalRating'] / b.value['count']) ? a : b)
                            .key,
                    Icons.star,
                    Colors.amber,
                  ),
                  const Divider(),
                  _buildInsightItem(
                    'Most Active Category',
                    categoryStats.entries.isEmpty
                        ? 'N/A'
                        : categoryStats.entries
                            .reduce((a, b) => a.value['totalBookings'] > b.value['totalBookings'] ? a : b)
                            .key,
                    Icons.event,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightItem(String title, String value, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildVendorUsersTab(List<AdminVendor> vendors, AdminProvider admin) {
    final vendorUsers = admin.users.where((user) => user.role == 'vendor').toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vendorUsers.length,
      itemBuilder: (context, index) {
        final vendorUser = vendorUsers[index];
        return _buildVendorUserCardFromAppUser(vendorUser, admin);
      },
    );
  }

  Widget _buildVendorUserCardFromAppUser(AppUser vendorUser, AdminProvider admin) {
    // Find corresponding AdminVendor if exists
    AdminVendor adminVendor = admin.vendors.firstWhere(
      (v) => v.id == vendorUser.id,
      orElse: () => AdminVendor(
        vendorUser.id,
        vendorUser.name,
        'Vendor', // Default category for vendor users
        false, // verified
        false, // suspended
        0.0, // rating
        0, // reviews
        0, // bookings
        [], // serviceAreas
        false, // pendingApproval
      ),
    );

    // Get cached documents for the vendor user
    final docs = admin.getVendorUserDocuments(vendorUser.id);

    // Update adminVendor with loaded documents
    adminVendor = AdminVendor(
      adminVendor.id,
      adminVendor.name,
      adminVendor.category,
      adminVendor.verified,
      adminVendor.suspended,
      adminVendor.rating,
      adminVendor.reviews,
      adminVendor.bookings,
      adminVendor.serviceAreas,
      adminVendor.pendingApproval,
      contactInfo: adminVendor.contactInfo,
      documents: docs,
      documentsVerified: docs.isNotEmpty && docs.every((d) => d.isVerified),
      documentVerificationNotes: adminVendor.documentVerificationNotes,
      documentsVerifiedAt: adminVendor.documentsVerifiedAt,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor User Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendorUser.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Vendor User',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        vendorUser.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: vendorUser.status == 'active' ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vendorUser.status == 'active' ? 'Active' : 'Inactive',
                    style: TextStyle(
                      color: vendorUser.status == 'active' ? Colors.green[800] : Colors.red[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (docs.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: adminVendor.documentsVerified ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      adminVendor.documentsVerified ? 'Docs Verified' : 'Docs Pending',
                      style: TextStyle(
                        color: adminVendor.documentsVerified ? Colors.green[800] : Colors.orange[800],
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // Vendor User Stats (from AdminVendor if available)
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Bookings',
                    '${adminVendor.bookings}',
                    Icons.book_online,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Category',
                    adminVendor.category,
                    Icons.category,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Rating',
                    adminVendor.rating.toStringAsFixed(1),
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Document Status for Vendor Users
            if (docs.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: adminVendor.documentsVerified
                      ? Colors.green[50]
                      : docs.any((doc) => !doc.isVerified)
                          ? Colors.orange[50]
                          : Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: adminVendor.documentsVerified
                        ? Colors.green[200]!
                        : docs.any((doc) => !doc.isVerified)
                            ? Colors.orange[200]!
                            : Colors.blue[200]!,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          adminVendor.documentsVerified
                              ? Icons.verified
                              : docs.any((doc) => !doc.isVerified)
                                  ? Icons.pending
                                  : Icons.description,
                          color: adminVendor.documentsVerified
                              ? Colors.green[700]
                              : docs.any((doc) => !doc.isVerified)
                                  ? Colors.orange[700]
                                  : Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Documents',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: adminVendor.documentsVerified
                                ? Colors.green[700]
                                : docs.any((doc) => !doc.isVerified)
                                    ? Colors.orange[700]
                                    : Colors.blue[700],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${docs.where((doc) => doc.isVerified).length}/${docs.length} verified',
                          style: TextStyle(
                            fontSize: 12,
                            color: adminVendor.documentsVerified
                                ? Colors.green[600]
                                : docs.any((doc) => !doc.isVerified)
                                    ? Colors.orange[600]
                                    : Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showDocumentDetails(context, adminVendor),
                            icon: const Icon(Icons.visibility, size: 16),
                            label: const Text('View'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                        if (docs.any((doc) => !doc.isVerified)) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _verifyAllDocuments(context, adminVendor, admin),
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Verify All'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[100],
                                foregroundColor: Colors.green[700],
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showVendorUserDetailsFromAppUser(vendorUser, adminVendor),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showVendorUserActionsFromAppUser(vendorUser, adminVendor, admin),
                    icon: const Icon(Icons.more_vert),
                    label: const Text('Actions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVendorUserDetailsFromAppUser(AppUser vendorUser, AdminVendor adminVendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${vendorUser.name} - User Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${vendorUser.name}'),
            Text('Email: ${vendorUser.email}'),
            Text('Role: ${vendorUser.role}'),
            Text('Status: ${vendorUser.status}'),
            const SizedBox(height: 16),
            const Text('Vendor Details:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Category: ${adminVendor.category}'),
            Text('Rating: ${adminVendor.rating}★'),
            Text('Reviews: ${adminVendor.reviews}'),
            Text('Bookings: ${adminVendor.bookings}'),
            Text('Service Areas: ${adminVendor.serviceAreas.join(', ')}'),
            Text('Verified: ${adminVendor.verified ? 'Yes' : 'No'}'),
            Text('Suspended: ${adminVendor.suspended ? 'Yes' : 'No'}'),
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

  void _showVendorUserActionsFromAppUser(AppUser vendorUser, AdminVendor adminVendor, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actions for ${vendorUser.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                _showEditProfileDialog(context, adminVendor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Manage Service Areas'),
              onTap: () {
                Navigator.pop(context);
                _showServiceAreasDialog(context, adminVendor, context.read<AdminProvider>());
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('View Documents'),
              onTap: () {
                Navigator.pop(context);
                _showDocumentDetails(context, adminVendor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Performance Report'),
              onTap: () {
                Navigator.pop(context);
                _showPerformanceReport(context, adminVendor);
              },
            ),
            if (adminVendor.suspended)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Activate User'),
                onTap: () {
                  admin.activateVendor(adminVendor.id);
                  Navigator.pop(context);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Suspend User'),
                onTap: () {
                  admin.suspendVendor(adminVendor.id, suspended: true);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorUserCard(AdminVendor vendor, AdminProvider admin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor User Header
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  child: Icon(
                    Icons.person,
                    color: AppTheme.primaryColor,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vendor.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Vendor User',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(
                            ' ${vendor.rating.toStringAsFixed(1)} (${vendor.reviews} reviews)',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: vendor.verified ? Colors.green[100] : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vendor.verified ? 'Verified' : 'Unverified',
                    style: TextStyle(
                      color: vendor.verified ? Colors.green[800] : Colors.orange[800],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Vendor User Stats
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Bookings',
                    '${vendor.bookings}',
                    Icons.book_online,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Category',
                    vendor.category,
                    Icons.category,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Status',
                    vendor.suspended ? 'Suspended' : 'Active',
                    vendor.suspended ? Icons.block : Icons.check_circle,
                    vendor.suspended ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showVendorUserDetails(vendor),
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Profile'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showVendorUserActions(vendor, admin),
                    icon: const Icon(Icons.more_vert),
                    label: const Text('Actions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showVendorUserDetails(AdminVendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${vendor.name} - User Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${vendor.name}'),
            Text('Category: ${vendor.category}'),
            Text('Rating: ${vendor.rating}★'),
            Text('Reviews: ${vendor.reviews}'),
            Text('Bookings: ${vendor.bookings}'),
            Text('Service Areas: ${vendor.serviceAreas.join(', ')}'),
            Text('Verified: ${vendor.verified ? 'Yes' : 'No'}'),
            Text('Suspended: ${vendor.suspended ? 'Yes' : 'No'}'),
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

  void _showVendorUserActions(AdminVendor vendor, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Actions for ${vendor.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                _showEditProfileDialog(context, vendor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('Manage Service Areas'),
              onTap: () {
                Navigator.pop(context);
                _showServiceAreasDialog(context, vendor, context.read<AdminProvider>());
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Performance Report'),
              onTap: () {
                Navigator.pop(context);
                _showPerformanceReport(context, vendor);
              },
            ),
            if (vendor.suspended)
              ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Activate User'),
                onTap: () {
                  admin.activateVendor(vendor.id);
                  Navigator.pop(context);
                },
              )
            else
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: const Text('Suspend User'),
                onTap: () {
                  admin.suspendVendor(vendor.id, suspended: true);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

}

