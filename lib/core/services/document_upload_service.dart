import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

enum DocumentType {
  businessLicense,
  taxCertificate,
  insuranceCertificate,
  identification,
  bankStatement,
  other
}
class DocumentUploadResult {
  final String? id;
  final String fileName;
  final int fileSize;
  final String documentType;
  final String fileUrl;
  final DateTime uploadedAt;
  final String? verificationStatus;
  final String? rejectionReason;

  DocumentUploadResult({
    this.id,
    required this.fileName,
    required this.fileSize,
    required this.documentType,
    required this.fileUrl,
    required this.uploadedAt,
    this.verificationStatus,
    this.rejectionReason,
  });
}

class DocumentUploadService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload a document file to Supabase Storage
  /// Returns the public URL of the uploaded file
  Future<String> uploadDocument({
    required File file,
    required String vendorId,
    required String documentType,
  }) async {
    try {
      // Create a unique file name
      final fileExtension = path.extension(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${documentType}_${timestamp}$fileExtension';

      // Storage path: vendor-documents/vendorId/documentType/fileName
      final storagePath = 'vendor-documents/$vendorId/$documentType/$fileName';

      // Upload file to Supabase Storage
      await _supabase.storage
          .from('documents')
          .upload(storagePath, file);

      // Get public URL
      final publicUrl = _supabase.storage
          .from('documents')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Delete a document from Supabase Storage
  Future<void> deleteDocument(String fileUrl) async {
    try {
      // Extract the file path from the URL
      final uri = Uri.parse(fileUrl);
      final pathSegments = uri.pathSegments;

      // Find the path after 'documents/'
      final documentsIndex = pathSegments.indexOf('documents');
      if (documentsIndex == -1) {
        throw Exception('Invalid document URL format');
      }

      final filePath = pathSegments.sublist(documentsIndex + 1).join('/');

      await _supabase.storage
          .from('documents')
          .remove([filePath]);
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  /// Get file size from file
  Future<int> getFileSize(File file) async {
    return await file.length();
  }

  /// Validate file type for documents
  bool isValidDocumentType(File file) {
    final allowedExtensions = ['.pdf', '.jpg', '.jpeg', '.png', '.doc', '.docx'];
    final fileExtension = path.extension(file.path).toLowerCase();
    return allowedExtensions.contains(fileExtension);
  }

  /// Validate file size (max 10MB)
  bool isValidFileSize(File file) {
    const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
    return file.lengthSync() <= maxSizeInBytes;
  }

  /// Get MIME type from file extension
  String getMimeType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  /// Pick a document file using file picker
  static Future<PlatformFile?> pickDocument({
    List<String>? allowedExtensions,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files.first;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick document: $e');
    }
  }

  /// Validate file (type and size)
  static bool validateFile(PlatformFile file) {
    // Check file size (max 10MB)
    const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
    if (file.size > maxSizeInBytes) {
      return false;
    }

    // Check file extension
    final allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];
    final fileExtension = file.extension?.toLowerCase();
    return allowedExtensions.contains(fileExtension);
  }

  /// Upload document and return DocumentUploadResult
  static Future<DocumentUploadResult> uploadDocumentFile({
    required PlatformFile file,
    required String documentType,
    required String vendorId,
    Function(double)? onProgress,
  }) async {
    try {
      final service = DocumentUploadService();
      final url = await service.uploadDocumentFromBytes(
        fileBytes: file.bytes!,
        fileName: file.name,
        vendorId: vendorId,
        documentType: documentType,
      );

      // Create result
      final result = DocumentUploadResult(
        fileName: file.name,
        fileSize: file.size,
        documentType: documentType,
        fileUrl: url,
        uploadedAt: DateTime.now(),
      );

      return result;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Upload profile picture to Supabase Storage
  /// Returns the public URL of the uploaded file
  Future<String> uploadProfilePicture({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String vendorId,
  }) async {
    try {
      // Create a unique file name
      final fileExtension = fileName.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageFileName = 'profile_${vendorId}_${timestamp}.$fileExtension';

      // Storage path: profile-pictures/vendorId/fileName
      final storagePath = 'profile-pictures/$vendorId/$storageFileName';

      // Upload file to Supabase Storage
      if (fileBytes != null) {
        // Upload from bytes (web)
        await _supabase.storage
            .from('documents')
            .uploadBinary(storagePath, fileBytes);
      } else if (filePath != null) {
        // Upload from file path (mobile/desktop)
        final file = File(filePath);
        await _supabase.storage
            .from('documents')
            .upload(storagePath, file);
      } else {
        throw Exception('No file data provided');
      }

      // Get public URL
      final publicUrl = _supabase.storage
          .from('documents')
          .getPublicUrl(storagePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload profile picture: $e');
    }
  }

  /// Get document type name for display
  static String getDocumentTypeName(DocumentType type) {
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
    }
  }

  /// Upload document from bytes (for web platform)
  Future<String> uploadDocumentFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    required String vendorId,
    required String documentType,
  }) async {
    try {
      print('DEBUG: Starting uploadDocumentFromBytes for $documentType, vendor: $vendorId');
      // Create a unique file name
      final fileExtension = fileName.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageFileName = '${documentType}_${timestamp}.$fileExtension';

      // Storage path: vendor-documents/vendorId/documentType/fileName
      final storagePath = 'vendor-documents/$vendorId/$documentType/$storageFileName';
      print('DEBUG: Storage path: $storagePath');

      // Upload bytes to Supabase Storage
      print('DEBUG: Uploading to bucket: documents');
      await _supabase.storage
          .from('documents')
          .uploadBinary(storagePath, fileBytes);
      print('DEBUG: Upload to storage successful');

      // Get public URL
      final publicUrl = _supabase.storage
          .from('documents')
          .getPublicUrl(storagePath);
      print('DEBUG: Public URL: $publicUrl');

      return publicUrl;
    } catch (e) {
      print('DEBUG: Failed to upload document from bytes: $e');
      throw Exception('Failed to upload document from bytes: $e');
    }
  }
}
