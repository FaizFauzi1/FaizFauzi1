import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/document_upload_service.dart';
import '../../../../shared/widgets/document_upload_widget_fixed.dart';
import '../../data/providers/vendor_profile_provider.dart';
import '../../../admin/data/providers/admin_provider.dart' hide DocumentType;
import '../widgets/vendor_responsive_scaffold.dart';

// --- ENUMS & MODELS ---

enum DocumentCategory {
  legal,
  financial,
  operational,
  certification,
  other,
}

enum DocumentStatus {
  pending,
  uploaded,
  verified,
  rejected,
  expired,
}

class DocumentRequirement {
  final DocumentType type;
  final String title;
  final String description;
  final DocumentCategory category;
  final bool isRequired;
  final bool isRecurring;
  final int validityMonths;
  final IconData icon;

  const DocumentRequirement({
    required this.type,
    required this.title,
    required this.description,
    required this.category,
    this.isRequired = true,
    this.isRecurring = false,
    this.validityMonths = 12,
    required this.icon,
  });
}

class EnhancedDocumentUploadResult extends DocumentUploadResult {
  final DocumentStatus status;
  final String? rejectionReason;
  final DateTime? expiryDate;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final List<String> tags;

  EnhancedDocumentUploadResult({
    super.id,
    required super.fileName,
    required super.fileSize,
    required super.documentType,
    required super.fileUrl,
    required super.uploadedAt,
    this.status = DocumentStatus.uploaded,
    this.rejectionReason,
    this.expiryDate,
    this.verifiedAt,
    this.verifiedBy,
    this.tags = const [],
  });
}

// --- MAIN SCREEN ---

class VendorDocumentManagementScreenEnhanced extends StatefulWidget {
  const VendorDocumentManagementScreenEnhanced({super.key});

  @override
  State<VendorDocumentManagementScreenEnhanced> createState() => _VendorDocumentManagementScreenEnhancedState();
}

class _VendorDocumentManagementScreenEnhancedState extends State<VendorDocumentManagementScreenEnhanced>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, EnhancedDocumentUploadResult> _uploadedDocuments = {};
  bool _isLoading = false;
  DocumentCategory _selectedCategory = DocumentCategory.legal;
  final TextEditingController _searchController = TextEditingController();
  bool _isAdmin = false;
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkAdminStatus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isAdmin) {
        _loadVendorsForAdmin();
      } else {
        _loadExistingDocuments();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingDocuments() async {
    final profileProvider = Provider.of<VendorProfileProvider>(context, listen: false);
    await profileProvider.loadVendorProfile();

    if (!mounted) return;

    final documents = profileProvider.documents;
    setState(() {
      _uploadedDocuments.clear();
      for (final doc in documents) {
        // Only include documents that have valid file URLs and are actually uploaded
        if (doc['file_url'] != null && doc['file_url'].toString().isNotEmpty) {
            _uploadedDocuments[doc['document_type']] = EnhancedDocumentUploadResult(
              id: doc['id'].toString(),
              fileName: doc['file_name'] ?? 'Unknown File',
              fileSize: doc['file_size'] ?? 0,
              documentType: doc['document_type'],
              fileUrl: doc['file_url'],
              uploadedAt: DateTime.parse(doc['created_at'] ?? DateTime.now().toIso8601String()),
            status: _parseDocumentStatus(doc['status']),
            expiryDate: doc['expiry_date'] != null ? DateTime.parse(doc['expiry_date']) : null,
            verifiedAt: doc['verified_at'] != null ? DateTime.parse(doc['verified_at']) : null,
            verifiedBy: doc['verified_by'],
            tags: List<String>.from(doc['tags'] ?? []),
          );
        }
      }
    });

    // Only show dialog if there are actual uploaded documents
    if (_uploadedDocuments.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showExistingDocumentsDialog();
      });
    }
  }

  DocumentStatus _parseDocumentStatus(String? status) {
    switch (status) {
      case 'verified':
      case 'approved':
        return DocumentStatus.verified;
      case 'rejected':
        return DocumentStatus.rejected;
      case 'expired':
        return DocumentStatus.expired;
      case 'pending':
        return DocumentStatus.pending;
      default:
        // For documents that haven't been verified yet, show as uploaded
        return DocumentStatus.uploaded;
    }
  }

  DocumentType _mapStringToDocumentType(String type) {
    switch (type) {
      case 'business_license':
        return DocumentType.businessLicense;
      case 'tax_registration':
        return DocumentType.taxCertificate;
      case 'insurance_certificate':
        return DocumentType.insuranceCertificate;
      case 'halal_certificate':
        return DocumentType.identification;
      case 'professional_certifications':
        return DocumentType.bankStatement;
      case 'bank_statement':
        return DocumentType.bankStatement;
      case 'owner_identification':
        return DocumentType.identification;
      default:
        return DocumentType.other;
    }
  }

  String _getDocumentTypeKey(DocumentType type) {
    switch (type) {
      case DocumentType.businessLicense:
        return 'business_license';
      case DocumentType.taxCertificate:
        return 'tax_registration';
      case DocumentType.insuranceCertificate:
        return 'insurance_certificate';
      case DocumentType.identification:
        return 'halal_certificate';
      case DocumentType.bankStatement:
        return 'professional_certifications';
      case DocumentType.other:
        return 'other';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAdmin) {
      return _buildAdminVendorManagementScreen();
    } else {
      return _buildVendorDocumentManagementScreen();
    }
  }

  Widget _buildAdminVendorManagementScreen() {
    final adminProvider = Provider.of<AdminProvider>(context);
    final vendors = adminProvider.vendors;
    final vendorUsers = adminProvider.users.where((user) => user.role == 'vendor').toList();

    // Combine vendors and vendor users to ensure vendor users are counted as vendors
    final allVendors = [...vendors];
    for (final user in vendorUsers) {
      if (!allVendors.any((v) => v.id == user.id)) {
        // Load documents from Supabase for vendor users
        List<VendorDocument> docs = [];
        try {
          docs = adminProvider.getVendorDocuments(user.id) as List<VendorDocument>;
        } catch (e) {
          docs = [];
        }
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: adminProvider.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: adminProvider.isLoading
                ? null
                : () async {
                    await adminProvider.refreshAllData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vendor data refreshed')),
                    );
                  },
            tooltip: 'Refresh Vendors',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search vendors by name, email, or business...',
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
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Filter by Status',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  value: _filterStatus,
                  items: ['All', 'pending_review', 'approved', 'rejected', 'suspended']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status.replaceAll('_', ' ').toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _filterStatus = value!;
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: filteredVendors.isEmpty
            ? const Center(
                child: Text('No vendors found'),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredVendors.length,
                itemBuilder: (context, index) {
                  final vendor = filteredVendors[index];
                  return _buildVendorCard(vendor, adminProvider);
                },
              ),
      ),
    );
  }

  Widget _buildVendorDocumentManagementScreen() {
    return VendorResponsiveScaffold(
      title: 'Document Management',
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Documents'),
          Tab(text: 'Status'),
        ],
        labelColor: const Color(0xFF6366F1),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF6366F1),
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildDocumentsTab(),
            _buildStatusTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final requirements = _getDocumentRequirements();
    final uploadedCount = _uploadedDocuments.length;
    final verifiedCount = _uploadedDocuments.values.where((doc) => doc.status == DocumentStatus.verified).length;
    final pendingCount = _uploadedDocuments.values.where((doc) => doc.status == DocumentStatus.pending).length;
    final completionPercentage = requirements.isNotEmpty ? (uploadedCount / requirements.length) * 100 : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress Summary
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document Completion',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(
                  value: completionPercentage / 100,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    completionPercentage == 100 ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${completionPercentage.toInt()}% Complete',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCard('Total', requirements.length.toString(), Icons.description),
                    _buildStatCard('Uploaded', uploadedCount.toString(), Icons.upload_file),
                    _buildStatCard('Verified', verifiedCount.toString(), Icons.verified),
                    _buildStatCard('Pending', pendingCount.toString(), Icons.pending),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        'Upload All Required',
                        Icons.upload_file,
                        _uploadAllRequiredDocuments,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        'Check Expiring',
                        Icons.schedule,
                        _checkExpiringDocuments,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionButton(
                        'Download All',
                        Icons.download,
                        _downloadAllDocuments,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickActionButton(
                        'Submit for Review',
                        Icons.send,
                        _submitForReview,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Category Overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Document Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 16),
                ...DocumentCategory.values.map((category) {
                  final categoryRequirements = requirements.where((req) => req.category == category).toList();
                  final categoryUploaded = categoryRequirements.where((req) =>
                    _uploadedDocuments.containsKey(req.type)).length;
                  return _buildCategoryOverview(category, categoryRequirements.length, categoryUploaded);
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildCategoryOverview(DocumentCategory category, int total, int uploaded) {
    final percentage = total > 0 ? (uploaded / total) * 100 : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getCategoryDisplayName(category),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Text(
                '$uploaded/$total',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage == 100 ? const Color(0xFF10B981) : const Color(0xFF6366F1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsTab() {
    final requirements = _getDocumentRequirements();
    final filteredRequirements = requirements.where((req) {
      if (_searchController.text.isEmpty) return req.category == _selectedCategory;
      return req.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
             req.description.toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();

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
                  hintText: 'Search documents...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                ),
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: DocumentCategory.values.map((category) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getCategoryDisplayName(category)),
                        selected: _selectedCategory == category,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF6366F1).withOpacity(0.1),
                        checkmarkColor: const Color(0xFF6366F1),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Documents List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredRequirements.length,
            itemBuilder: (context, index) {
              final requirement = filteredRequirements[index];
              final uploadedDoc = _uploadedDocuments[_getDocumentTypeKey(requirement.type)];

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: EnhancedDocumentUploadWidget(
                  requirement: requirement,
                  existingDocument: uploadedDoc,
                  onUploadComplete: (result) {
                    setState(() {
                      _uploadedDocuments[_getDocumentTypeKey(requirement.type)] = result;
                    });
                  },
                  onDelete: () {
                    setState(() {
                      _uploadedDocuments.remove(requirement.type);
                    });
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTab() {
    final documents = _uploadedDocuments.values.toList();
    final groupedByStatus = <DocumentStatus, List<EnhancedDocumentUploadResult>>{};

    for (final doc in documents) {
      groupedByStatus[doc.status] ??= [];
      groupedByStatus[doc.status]!.add(doc);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: DocumentStatus.values.map((status) {
          final statusDocs = groupedByStatus[status] ?? [];
          if (statusDocs.isEmpty) return const SizedBox.shrink();

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getStatusIcon(status), color: _getStatusColor(status)),
                    const SizedBox(width: 8),
                    Text(
                      _getStatusDisplayName(status),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${statusDocs.length}',
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...statusDocs.map((doc) => _buildStatusDocumentItem(doc)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusDocumentItem(EnhancedDocumentUploadResult doc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(_getDocumentTypeIcon(_mapStringToDocumentType(doc.documentType)), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DocumentUploadService.getDocumentTypeName(_mapStringToDocumentType(doc.documentType)!),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (doc.id != null)
                  Text(
                    'ID: ${doc.id}',
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFF64748B).withOpacity(0.7),
                      fontFamily: 'monospace',
                    ),
                  ),
                Text(
                  'Uploaded ${DateFormat('MMM dd, yyyy').format(doc.uploadedAt)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                if (doc.expiryDate != null)
                  Text(
                    'Expires ${DateFormat('MMM dd, yyyy').format(doc.expiryDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: doc.expiryDate!.isBefore(DateTime.now())
                          ? Colors.red
                          : const Color(0xFF64748B),
                    ),
                  ),
                if (doc.rejectionReason != null)
                  Text(
                    'Reason: ${doc.rejectionReason}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
          if (doc.status == DocumentStatus.verified)
            const Icon(Icons.verified, color: Color(0xFF10B981)),
        ],
      ),
    );
  }

  List<DocumentRequirement> _getDocumentRequirements() {
    return [
      DocumentRequirement(
        type: DocumentType.businessLicense,
        title: 'Business License',
        description: 'Valid business registration certificate',
        category: DocumentCategory.legal,
        isRequired: true,
        isRecurring: true,
        validityMonths: 12,
        icon: Icons.business,
      ),
      DocumentRequirement(
        type: DocumentType.taxCertificate,
        title: 'Tax Registration',
        description: 'Tax registration certificate or TIN',
        category: DocumentCategory.financial,
        isRequired: true,
        isRecurring: false,
        validityMonths: 0,
        icon: Icons.receipt,
      ),
      DocumentRequirement(
        type: DocumentType.insuranceCertificate,
        title: 'Insurance Certificate',
        description: 'Valid liability insurance certificate',
        category: DocumentCategory.legal,
        isRequired: true,
        isRecurring: true,
        validityMonths: 12,
        icon: Icons.security,
      ),
      DocumentRequirement(
        type: DocumentType.identification,
        title: 'Owner Identification',
        description: 'IC, passport, or government-issued ID of business owner',
        category: DocumentCategory.legal,
        isRequired: true,
        isRecurring: false,
        validityMonths: 0,
        icon: Icons.perm_identity,
      ),
      DocumentRequirement(
        type: DocumentType.bankStatement,
        title: 'Bank Statement',
        description: 'Recent bank statement for payment verification',
        category: DocumentCategory.financial,
        isRequired: true,
        isRecurring: true,
        validityMonths: 3,
        icon: Icons.account_balance,
      ),
      DocumentRequirement(
        type: DocumentType.identification,
        title: 'Halal Certificate',
        description: 'Halal certification for food vendors',
        category: DocumentCategory.certification,
        isRequired: false,
        isRecurring: true,
        validityMonths: 12,
        icon: Icons.restaurant,
      ),
      DocumentRequirement(
        type: DocumentType.other,
        title: 'Food Safety Certificate',
        description: 'Food safety and hygiene certification',
        category: DocumentCategory.certification,
        isRequired: false,
        isRecurring: true,
        validityMonths: 12,
        icon: Icons.restaurant_menu,
      ),
      DocumentRequirement(
        type: DocumentType.other,
        title: 'Fire Safety Certificate',
        description: 'Fire safety compliance certificate',
        category: DocumentCategory.certification,
        isRequired: false,
        isRecurring: true,
        validityMonths: 12,
        icon: Icons.fire_extinguisher,
      ),
      DocumentRequirement(
        type: DocumentType.other,
        title: 'Health & Safety Certificate',
        description: 'Health and safety compliance certificate',
        category: DocumentCategory.certification,
        isRequired: false,
        isRecurring: true,
        validityMonths: 12,
        icon: Icons.health_and_safety,
      ),
      DocumentRequirement(
        type: DocumentType.other,
        title: 'Professional Certifications',
        description: 'Additional professional certifications and licenses',
        category: DocumentCategory.certification,
        isRequired: false,
        isRecurring: false,
        validityMonths: 0,
        icon: Icons.verified,
      ),
    ];
  }

  String _getCategoryDisplayName(DocumentCategory category) {
    switch (category) {
      case DocumentCategory.legal:
        return 'Legal Documents';
      case DocumentCategory.financial:
        return 'Financial Documents';
      case DocumentCategory.operational:
        return 'Operational Documents';
      case DocumentCategory.certification:
        return 'Certifications';
      case DocumentCategory.other:
        return 'Other Documents';
    }
  }

  String _getStatusDisplayName(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return 'Pending Review';
      case DocumentStatus.uploaded:
        return 'Uploaded';
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.expired:
        return 'Expired';
    }
  }

  IconData _getStatusIcon(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return Icons.pending;
      case DocumentStatus.uploaded:
        return Icons.upload_file;
      case DocumentStatus.verified:
        return Icons.verified;
      case DocumentStatus.rejected:
        return Icons.error;
      case DocumentStatus.expired:
        return Icons.schedule;
    }
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return Colors.orange;
      case DocumentStatus.uploaded:
        return const Color(0xFF6366F1);
      case DocumentStatus.verified:
        return const Color(0xFF10B981);
      case DocumentStatus.rejected:
        return Colors.red;
      case DocumentStatus.expired:
        return Colors.grey;
    }
  }

  Color _getVendorStatusColor(String status) {
    switch (status) {
      case 'pending_review':
        return Colors.orange;
      case 'approved':
        return const Color(0xFF10B981);
      case 'rejected':
        return Colors.red;
      case 'suspended':
        return Colors.grey;
      default:
        return const Color(0xFF6366F1);
    }
  }

  void _uploadAllRequiredDocuments() {
    // Implementation for batch upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Batch upload feature coming soon')),
    );
  }

  void _checkExpiringDocuments() {
    final expiringDocs = _uploadedDocuments.values.where((doc) {
      return doc.expiryDate != null &&
             doc.expiryDate!.difference(DateTime.now()).inDays <= 30;
    }).toList();

    if (expiringDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No documents expiring soon')),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Expiring Documents'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: expiringDocs.map((doc) {
              return ListTile(
                leading: Icon(_getDocumentTypeIcon(_mapStringToDocumentType(doc.documentType))),
                title: Text(DocumentUploadService.getDocumentTypeName(_mapStringToDocumentType(doc.documentType))),
                subtitle: Text('Expires ${DateFormat('MMM dd, yyyy').format(doc.expiryDate!)}'),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _downloadAllDocuments() {
    // Implementation for downloading all documents
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download feature coming soon')),
    );
  }

  void _submitForReview() {
    final requirements = _getDocumentRequirements();
    final requiredDocs = requirements.where((req) => req.isRequired).toList();
    final uploadedRequired = requiredDocs.where((req) =>
      _uploadedDocuments.containsKey(req.type)).length;

    if (uploadedRequired < requiredDocs.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload all required documents before submitting'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Implementation for submitting documents for review
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Documents submitted for review')),
    );
  }

  IconData _getDocumentTypeIcon(DocumentType type) {
    switch (type) {
      case DocumentType.businessLicense:
        return Icons.business;
      case DocumentType.taxCertificate:
        return Icons.receipt;
      case DocumentType.insuranceCertificate:
        return Icons.security;
      case DocumentType.identification:
        return Icons.perm_identity;
      case DocumentType.bankStatement:
        return Icons.account_balance;
      case DocumentType.other:
        return Icons.attach_file;
      default:
        return Icons.attach_file;
    }
  }

  void _showExistingDocumentsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Existing Documents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _uploadedDocuments.entries.map((entry) {
            return ListTile(
              leading: Icon(_getDocumentTypeIcon(_mapStringToDocumentType(entry.key))),
              title: Text(DocumentUploadService.getDocumentTypeName(_mapStringToDocumentType(entry.key))),
              subtitle: Text('Uploaded: ${DateFormat('MMM dd, yyyy').format(entry.value.uploadedAt)}'),
              trailing: Icon(
                entry.value.status == DocumentStatus.verified ? Icons.verified : Icons.upload_file,
                color: entry.value.status == DocumentStatus.verified ? Colors.green : Colors.blue,
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null && user.userMetadata != null) {
        final role = user.userMetadata!['role'] as String?;
        setState(() {
          _isAdmin = role == 'admin';
        });
      }
    } catch (e) {
      setState(() {
        _isAdmin = false;
      });
    }
  }

  Future<void> _loadVendorsForAdmin() async {
    final adminProvider = Provider.of<AdminProvider>(context, listen: false);
    await adminProvider.refreshAllData();
  }

  List<AdminVendor> _filterVendors(List<AdminVendor> vendors) {
    return vendors.where((vendor) {
      final matchesSearch = _searchQuery.isEmpty ||
          vendor.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          vendor.contactInfo?.toLowerCase().contains(_searchQuery.toLowerCase()) == true;

      final matchesStatus = _filterStatus == 'All' ||
          (_filterStatus == 'pending_review' && vendor.pendingApproval) ||
          (_filterStatus == 'approved' && vendor.verified && !vendor.suspended) ||
          (_filterStatus == 'rejected' && !vendor.verified && !vendor.pendingApproval) ||
          (_filterStatus == 'suspended' && vendor.suspended);

      return matchesSearch && matchesStatus;
    }).toList();
  }

  String _getVendorStatus(AdminVendor vendor) {
    if (vendor.pendingApproval) return 'pending_review';
    if (vendor.suspended) return 'suspended';
    if (vendor.verified) return 'approved';
    return 'rejected';
  }

  Widget _buildVendorCard(AdminVendor vendor, AdminProvider adminProvider) {
    final status = _getVendorStatus(vendor);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: _getVendorStatusColor(status),
                  child: Text(
                    vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V',
                    style: const TextStyle(color: Colors.white),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        vendor.category,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      if (vendor.contactInfo != null)
                        Text(
                          vendor.contactInfo!,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getVendorStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: _getVendorStatusColor(status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewVendorDocuments(vendor),
                    icon: const Icon(Icons.description, size: 16),
                    label: const Text('View Documents'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (status == 'pending_review')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _approveVendor(vendor, adminProvider),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (status == 'pending_review')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _rejectVendor(vendor, adminProvider),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (status == 'approved')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _suspendVendor(vendor, adminProvider),
                      icon: const Icon(Icons.block, size: 16),
                      label: const Text('Suspend'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                if (status == 'suspended')
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _activateVendor(vendor, adminProvider),
                      icon: const Icon(Icons.check_circle, size: 16),
                      label: const Text('Activate'),
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
    );
  }

  void _viewVendorDocuments(AdminVendor vendor) {
    // Navigate to vendor document view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing documents for ${vendor.name}')),
    );
  }

  Future<void> _approveVendor(AdminVendor vendor, AdminProvider adminProvider) async {
    try {
      await adminProvider.approveVendor(vendor.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${vendor.name} approved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to approve vendor: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _rejectVendor(AdminVendor vendor, AdminProvider adminProvider) async {
    try {
      await adminProvider.rejectVendor(vendor.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${vendor.name} rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to reject vendor: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _suspendVendor(AdminVendor vendor, AdminProvider adminProvider) async {
    try {
      await adminProvider.suspendVendor(vendor.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${vendor.name} suspended')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to suspend vendor: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _activateVendor(AdminVendor vendor, AdminProvider adminProvider) async {
    try {
      await adminProvider.activateVendor(vendor.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${vendor.name} activated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to activate vendor: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

// Enhanced Document Upload Widget
class EnhancedDocumentUploadWidget extends StatefulWidget {
  final DocumentRequirement requirement;
  final EnhancedDocumentUploadResult? existingDocument;
  final Function(EnhancedDocumentUploadResult)? onUploadComplete;
  final VoidCallback? onDelete;

  const EnhancedDocumentUploadWidget({
    super.key,
    required this.requirement,
    this.existingDocument,
    this.onUploadComplete,
    this.onDelete,
  });

  @override
  State<EnhancedDocumentUploadWidget> createState() => _EnhancedDocumentUploadWidgetState();
}

class _EnhancedDocumentUploadWidgetState extends State<EnhancedDocumentUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    final existingDoc = widget.existingDocument;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: existingDoc != null
              ? _getStatusBorderColor(existingDoc.status)
              : const Color(0xFFE2E8F0),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: existingDoc != null
                      ? _getStatusColor(existingDoc.status).withOpacity(0.1)
                      : const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.requirement.icon,
                  color: existingDoc != null
                      ? _getStatusColor(existingDoc.status)
                      : const Color(0xFF6366F1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.requirement.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (widget.requirement.isRequired)
                          const Text(
                            ' *',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    Text(
                      widget.requirement.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    if (widget.requirement.isRecurring)
                      Text(
                        'Recurring - Valid for ${widget.requirement.validityMonths} months',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (existingDoc != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(existingDoc.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusDisplayName(existingDoc.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Upload Progress
          if (_isUploading)
            Column(
              children: [
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploading... ${(_uploadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),

          // Document Info
          if (existingDoc != null && !_isUploading)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getStatusColor(existingDoc.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          existingDoc.fileName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (existingDoc.id != null)
                          Text(
                            'ID: ${existingDoc.id}',
                            style: TextStyle(
                              fontSize: 10,
                              color: const Color(0xFF64748B).withOpacity(0.7),
                              fontFamily: 'monospace',
                            ),
                          ),
                        Text(
                          '${(existingDoc.fileSize / 1024).toStringAsFixed(1)} KB • Uploaded ${DateFormat('MMM dd, yyyy').format(existingDoc.uploadedAt)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (existingDoc.expiryDate != null)
                          Text(
                            'Expires: ${DateFormat('MMM dd, yyyy').format(existingDoc.expiryDate!)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: existingDoc.expiryDate!.isBefore(DateTime.now())
                                  ? Colors.red
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        if (existingDoc.verifiedAt != null)
                          Text(
                            'Verified: ${DateFormat('MMM dd, yyyy').format(existingDoc.verifiedAt!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF10B981),
                            ),
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          _viewDocument(existingDoc);
                          break;
                        case 'download':
                          _downloadDocument(existingDoc);
                          break;
                        case 'replace':
                          _uploadDocument();
                          break;
                        case 'delete':
                          _deleteDocument();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Text('View Document'),
                      ),
                      const PopupMenuItem(
                        value: 'download',
                        child: Text('Download'),
                      ),
                      const PopupMenuItem(
                        value: 'replace',
                        child: Text('Replace'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Upload Button
          if (existingDoc == null || !_isUploading)
            const SizedBox(height: 16),

          if (existingDoc == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          // Replace Button
          if (existingDoc != null && !_isUploading)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _uploadDocument,
                icon: const Icon(Icons.refresh),
                label: const Text('Replace Document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF6366F1),
                  side: const BorderSide(color: Color(0xFF6366F1)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          // File Requirements
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Supported formats: PDF, JPG, PNG (Max: 10MB)',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusBorderColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.verified:
        return const Color(0xFF10B981);
      case DocumentStatus.rejected:
        return Colors.red;
      case DocumentStatus.expired:
        return Colors.orange;
      default:
        return const Color(0xFF6366F1);
    }
  }

  Color _getStatusColor(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.verified:
        return const Color(0xFF10B981);
      case DocumentStatus.rejected:
        return Colors.red;
      case DocumentStatus.expired:
        return Colors.orange;
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _getStatusDisplayName(DocumentStatus status) {
    switch (status) {
      case DocumentStatus.pending:
        return 'Pending';
      case DocumentStatus.uploaded:
        return 'Uploaded';
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.rejected:
        return 'Rejected';
      case DocumentStatus.expired:
        return 'Expired';
    }
  }

  Future<void> _uploadDocument() async {
    try {
      final pickedFile = await DocumentUploadService.pickDocument(
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (pickedFile == null || pickedFile.path == null) {
        return;
      }

      final filePath = pickedFile.path!;
      final file = File(filePath);

      // Validate file size (max 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size must be less than 10MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Get vendor profile provider for upload
      final profileProvider = Provider.of<VendorProfileProvider>(context, listen: false);

      // Upload document using the same method as onboarding
      final documentType = _getDocumentTypeKey(widget.requirement.type);
      final uploadSuccess = await profileProvider.uploadDocument(
        filePath: filePath,
        documentType: documentType,
        fileName: pickedFile.name,
      );

      if (!uploadSuccess) {
        throw Exception(profileProvider.error ?? 'Upload failed');
      }

      // Create enhanced result
      final enhancedResult = EnhancedDocumentUploadResult(
        fileName: pickedFile.name,
        fileSize: fileSize,
        documentType: documentType,
        fileUrl: 'uploaded', // Will be updated when profile is reloaded
        uploadedAt: DateTime.now(),
        expiryDate: widget.requirement.isRecurring
            ? DateTime.now().add(Duration(days: widget.requirement.validityMonths * 30))
            : null,
      );

      setState(() {
        _isUploading = false;
      });

      widget.onUploadComplete?.call(enhancedResult);

      // Reload documents to get updated data
      final mainScreenState = context.findAncestorStateOfType<_VendorDocumentManagementScreenEnhancedState>();
      if (mainScreenState != null) {
        await mainScreenState._loadExistingDocuments();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.requirement.title} uploaded successfully'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getDocumentTypeKey(DocumentType type) {
    switch (type) {
      case DocumentType.businessLicense:
        return 'business_license';
      case DocumentType.taxCertificate:
        return 'tax_registration';
      case DocumentType.insuranceCertificate:
        return 'insurance_certificate';
      case DocumentType.identification:
        return 'halal_certificate';
      case DocumentType.bankStatement:
        return 'professional_certifications';
      case DocumentType.other:
        return 'other';
      default:
        return 'other';
    }
  }

  Future<void> _viewDocument(EnhancedDocumentUploadResult doc) async {
    try {
      final Uri url = Uri.parse(doc.fileUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open document')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening document: $e')),
        );
      }
    }
  }

  void _downloadDocument(EnhancedDocumentUploadResult doc) {
    // Implementation for downloading document
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download feature coming soon')),
    );
  }

  void _deleteDocument() {
    widget.onDelete?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.requirement.title} deleted'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
