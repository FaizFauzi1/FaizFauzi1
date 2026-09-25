import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/document_upload_service.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textPrimaryColor = Color(0xFF1E293B);
  static const Color textSecondaryColor = Color(0xFF64748B);
  static const Color successColor = Color(0xFF10B981);
  static const Color borderColor = Color(0xFFE2E8F0);
}

class DocumentUploadWidget extends StatefulWidget {
  final String documentType;
  final String vendorId;
  final String title;
  final String description;
  final IconData icon;
  final Function(DocumentUploadResult)? onUploadComplete;
  final DocumentUploadResult? existingDocument;
  final bool showProgress;

  const DocumentUploadWidget({
    super.key,
    required this.documentType,
    required this.vendorId,
    required this.title,
    required this.description,
    required this.icon,
    this.onUploadComplete,
    this.existingDocument,
    this.showProgress = true,
  });

  @override
  State<DocumentUploadWidget> createState() => _DocumentUploadWidgetState();
}

class _DocumentUploadWidgetState extends State<DocumentUploadWidget> {
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  DocumentUploadResult? _uploadedDocument;

  @override
  void initState() {
    super.initState();
    _uploadedDocument = widget.existingDocument;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _uploadedDocument != null
              ? AppTheme.successColor
              : AppTheme.borderColor,
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
                  color: _uploadedDocument != null
                      ? AppTheme.successColor.withOpacity(0.1)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  widget.icon,
                  color: _uploadedDocument != null
                      ? AppTheme.successColor
                      : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (_uploadedDocument != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _uploadedDocument!.verificationStatus == 'approved'
                        ? AppTheme.successColor
                        : _uploadedDocument!.verificationStatus == 'rejected'
                            ? Colors.red
                            : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _uploadedDocument!.verificationStatus == 'approved'
                        ? 'Verified'
                        : _uploadedDocument!.verificationStatus == 'rejected'
                            ? 'Rejected'
                            : 'Pending Review',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Upload Progress
          if (_isUploading && widget.showProgress)
            Column(
              children: [
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploading... ${(_uploadProgress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),

          // Uploaded Document Info
          if (_uploadedDocument != null && !_isUploading)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.successColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.description,
                    color: AppTheme.successColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _uploadedDocument!.fileName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        if (_uploadedDocument!.id != null)
                          Text(
                            'ID: ${_uploadedDocument!.id}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.textSecondaryColor.withOpacity(0.7),
                              fontFamily: 'monospace',
                            ),
                          ),
                        Text(
                          '${(_uploadedDocument!.fileSize / 1024).toStringAsFixed(1)} KB • ${DocumentUploadService.getDocumentTypeName(_mapStringToType(_uploadedDocument!.documentType))}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'replace') {
                        _uploadDocument();
                      } else if (value == 'delete') {
                        _deleteDocument();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'replace',
                        child: Text('Replace Document'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete Document'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Upload Button
          if (_uploadedDocument == null || !_isUploading)
            const SizedBox(height: 16),

          if (_uploadedDocument == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadDocument,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Document'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

          // Replace Button
          if (_uploadedDocument != null && !_isUploading)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _uploadDocument,
                icon: const Icon(Icons.refresh),
                label: const Text('Replace Document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
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
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Supported formats: PDF, JPG, PNG (Max: 10MB)',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadDocument() async {
    // Pick file
    final PlatformFile? file = await DocumentUploadService.pickDocument(
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (file == null) return;

    // Validate file
    if (!DocumentUploadService.validateFile(file)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File size too large or unsupported format'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Start upload
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Upload document
      final result = await DocumentUploadService.uploadDocumentFile(
        file: file,
        documentType: widget.documentType,
        vendorId: widget.vendorId,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      setState(() {
        _uploadedDocument = result;
        _isUploading = false;
      });

      // Notify parent
      widget.onUploadComplete?.call(result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.title} uploaded successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteDocument() {
    setState(() {
      _uploadedDocument = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.title} deleted'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  DocumentType _mapStringToType(String type) {
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
      default:
        return DocumentType.other;
    }
  }
}

// Multi-document upload widget
class MultiDocumentUploadWidget extends StatefulWidget {
  final List<String> documentTypes;
  final String vendorId;
  final Function(List<DocumentUploadResult>)? onUploadComplete;
  final Map<String, DocumentUploadResult>? existingDocuments;

  const MultiDocumentUploadWidget({
    super.key,
    required this.documentTypes,
    required this.vendorId,
    this.onUploadComplete,
    this.existingDocuments,
  });

  @override
  State<MultiDocumentUploadWidget> createState() => _MultiDocumentUploadWidgetState();
}

class _MultiDocumentUploadWidgetState extends State<MultiDocumentUploadWidget> {
  final Map<String, DocumentUploadResult> _uploadedDocuments = {};

  @override
  void initState() {
    super.initState();
    if (widget.existingDocuments != null) {
      _uploadedDocuments.addAll(widget.existingDocuments!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.documentTypes.map((type) {
        final documentConfig = _getDocumentConfig(type);
        final existingDoc = _uploadedDocuments[type];

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DocumentUploadWidget(
            documentType: type,
            vendorId: widget.vendorId,
            title: documentConfig['title']!,
            description: documentConfig['description']!,
            icon: documentConfig['icon'] as IconData,
            existingDocument: existingDoc,
            onUploadComplete: (result) {
              setState(() {
                _uploadedDocuments[type] = result;
              });
              widget.onUploadComplete?.call(_uploadedDocuments.values.toList());
            },
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _getDocumentConfig(String type) {
    switch (type) {
      case 'business_license':
        return {
          'title': 'Business License',
          'description': 'Required for all vendors',
          'icon': Icons.description,
        };
      case 'tax_registration':
        return {
          'title': 'Tax Registration',
          'description': 'Required for business operations',
          'icon': Icons.receipt,
        };
      case 'insurance_certificate':
        return {
          'title': 'Insurance Certificate',
          'description': 'Required for liability coverage',
          'icon': Icons.security,
        };
      case 'halal_certificate':
        return {
          'title': 'Halal Certificate',
          'description': 'Required for food vendors',
          'icon': Icons.restaurant,
        };
      case 'professional_certifications':
        return {
          'title': 'Professional Certifications',
          'description': 'Optional but recommended',
          'icon': Icons.verified,
        };
      default:
        return {
          'title': 'Other Document',
          'description': 'Additional supporting documents',
          'icon': Icons.attach_file,
        };
    }
  }
}
