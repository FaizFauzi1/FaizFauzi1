import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/services/document_upload_service.dart' as DocService;
import 'package:eventease/shared/widgets/document_upload_widget_fixed.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';

class VendorDocumentManagementScreen extends StatefulWidget {
  const VendorDocumentManagementScreen({super.key});

  @override
  State<VendorDocumentManagementScreen> createState() => _VendorDocumentManagementScreenState();
}

class _VendorDocumentManagementScreenState extends State<VendorDocumentManagementScreen> {
  final Map<String, DocService.DocumentUploadResult> _uploadedDocuments = {};
  bool _isLoading = false;
  late final String vendorId;

  final List<String> documentTypes = [
    'business_license',
    'tax_registration',
    'insurance_certificate',
    'halal_certificate',
    'professional_certifications',
  ];

  @override
  void initState() {
    super.initState();
    // Load existing documents from provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadExistingDocuments();
      vendorId = Provider.of<VendorProfileProvider>(context, listen: false).vendorProfile!['id'];
    });
  }

  Future<void> _loadExistingDocuments() async {
    final profileProvider = Provider.of<VendorProfileProvider>(context, listen: false);
    await profileProvider.loadVendorProfile();

    // Convert provider documents to upload results
    final documents = profileProvider.documents;
    setState(() {
      _uploadedDocuments.clear();
      for (final doc in documents) {
        _uploadedDocuments[doc['document_type']] = DocService.DocumentUploadResult(
          id: doc['id'].toString(),
          fileName: doc['file_name'],
          fileSize: doc['file_size'],
          documentType: doc['document_type'],
          fileUrl: doc['file_url'],
          uploadedAt: DateTime.parse(doc['created_at']),
          verificationStatus: doc['status'],
          rejectionReason: doc['rejection_reason'],
        );
      }
    });
  }

  DocService.DocumentType? _mapStringToDocumentType(String type) {
    switch (type) {
      case 'business_license':
        return DocService.DocumentType.businessLicense;
      case 'tax_registration':
        return DocService.DocumentType.taxCertificate;
      case 'insurance_certificate':
        return DocService.DocumentType.insuranceCertificate;
      case 'halal_certificate':
        return DocService.DocumentType.identification;
      case 'professional_certifications':
        return DocService.DocumentType.bankStatement;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: const Color(0xFFF8FAFC),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document Upload',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Upload your business documents for verification. All documents are required for vendor approval.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Upload Progress Summary
              if (_uploadedDocuments.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${_uploadedDocuments.length} of ${DocService.DocumentType.values.length} documents uploaded',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                      Text(
                        '${(_uploadedDocuments.length / DocService.DocumentType.values.length * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),

              // Document Upload Widgets
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
                child: MultiDocumentUploadWidget(
                  documentTypes: documentTypes,
                  vendorId: vendorId,
                  existingDocuments: _uploadedDocuments,
                  onUploadComplete: (documents) {
                    setState(() {
                      // Update the uploaded documents map
                      _uploadedDocuments.clear();
                      for (final doc in documents) {
                        _uploadedDocuments[doc.documentType] = doc;
                      }
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              if (_uploadedDocuments.length == DocService.DocumentType.values.length)
                Container(
                  width: double.infinity,
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
                    children: [
                      const Text(
                        'Ready to Submit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All required documents have been uploaded. Click submit to send for verification.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submitDocuments,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Submit Documents',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 32),

              // Help Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document Guidelines',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '• Ensure all documents are clear and readable\n'
                      '• File size limit: 10MB per document\n'
                      '• Supported formats: PDF, JPG, PNG\n'
                      '• Business license should be current and valid\n'
                      '• ID documents should show full name and photo\n'
                      '• Documents will be reviewed within 2-3 business days',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
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

  Future<void> _submitDocuments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Documents are already saved to Supabase on upload
      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Documents have been uploaded successfully. Your application is now complete and will be reviewed by our team.'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 5),
          ),
        );

        // Navigate back
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to complete submission. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _mapDocumentTypeToString(DocService.DocumentType type) {
    switch (type) {
      case DocService.DocumentType.businessLicense:
        return 'business_license';
      case DocService.DocumentType.taxCertificate:
        return 'tax_registration';
      case DocService.DocumentType.insuranceCertificate:
        return 'insurance_certificate';
      case DocService.DocumentType.identification:
        return 'halal_certificate';
      case DocService.DocumentType.bankStatement:
        return 'professional_certifications';
      case DocService.DocumentType.other:
        return 'other';
    }
  }
}
