import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/document_upload_service.dart';
import '../../core/utils/app_theme.dart';

class DocumentUploadWidget extends StatefulWidget {
   final DocumentType documentType;
   final String title;
   final String description;
   final IconData icon;
   final Function(DocumentUploadResult)? onUploadComplete;
   final Function()? onDelete;
   final DocumentUploadResult? existingDocument;
   final bool showProgress;

   const DocumentUploadWidget({
     super.key,
     required this.documentType,
     required this.title,
     required this.description,
     required this.icon,
     this.onUploadComplete,
     this.onDelete,
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
                    color: AppTheme.successColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Uploaded',
                    style: TextStyle(
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
                        Text(
                          '${(_uploadedDocument!.fileSize / 1024).toStringAsFixed(1)} KB • ${DocumentUploadService.getDocumentTypeName(_uploadedDocument!.type)}',
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
      // Simulate upload
      final result = await DocumentUploadService.uploadDocumentFile(
        file: file,
        type: widget.documentType,
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

    widget.onDelete?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.title} deleted'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}

// Multi-document upload widget
class MultiDocumentUploadWidget extends StatefulWidget {
  final List<DocumentType> documentTypes;
  final Function(List<DocumentUploadResult>)? onUploadComplete;
  final Map<DocumentType, DocumentUploadResult>? existingDocuments;

  const MultiDocumentUploadWidget({
    super.key,
    required this.documentTypes,
    this.onUploadComplete,
    this.existingDocuments,
  });

  @override
  State<MultiDocumentUploadWidget> createState() => _MultiDocumentUploadWidgetState();
}

class _MultiDocumentUploadWidgetState extends State<MultiDocumentUploadWidget> {
  final Map<DocumentType, DocumentUploadResult> _uploadedDocuments = {};

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
            onDelete: () {
              setState(() {
                _uploadedDocuments.remove(type);
              });
              widget.onUploadComplete?.call(_uploadedDocuments.values.toList());
            },
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> _getDocumentConfig(DocumentType type) {
    switch (type) {
      case DocumentType.businessLicense:
        return {
          'title': 'Business License',
          'description': 'Required for all vendors',
          'icon': Icons.description,
        };
      case DocumentType.taxCertificate:
        return {
          'title': 'Tax Registration',
          'description': 'Required for business operations',
          'icon': Icons.receipt,
        };
      case DocumentType.insuranceCertificate:
        return {
          'title': 'Insurance Certificate',
          'description': 'Required for liability coverage',
          'icon': Icons.security,
        };
      case DocumentType.identification:
        return {
          'title': 'Owner Identification',
          'description': 'Government-issued ID',
          'icon': Icons.perm_identity,
        };
      case DocumentType.bankStatement:
        return {
          'title': 'Bank Statement',
          'description': 'Recent bank statement',
          'icon': Icons.account_balance,
        };
      case DocumentType.other:
        return {
          'title': 'Other Document',
          'description': 'Additional supporting documents',
          'icon': Icons.attach_file,
        };
    }
  }
}
