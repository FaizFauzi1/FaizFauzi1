import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:eventease/core/services/document_upload_service.dart';
import 'package:eventease/core/services/admin_notification_service.dart';
import 'package:eventease/features/referral/data/referral_service.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';

class VendorProfileProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DocumentUploadService _documentService = DocumentUploadService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _vendorProfile;
  List<Map<String, dynamic>> _documents = [];

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get vendorProfile => _vendorProfile;
  List<Map<String, dynamic>> get documents => _documents;

  int get profileCompletionPercentage {
    if (_vendorProfile == null) return 0;
    return _vendorProfile!['profile_completion_percentage'] ?? 0;
  }

  String get profileStatus {
    if (_vendorProfile == null) return 'incomplete';
    return _vendorProfile!['profile_completion_status'] ?? 'incomplete';
  }

  /// Load vendor profile for current user or impersonated vendor
  Future<void> loadVendorProfile({String? targetVendorId}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final effectiveTarget = targetVendorId ??
          (AdminImpersonationService.instance.isImpersonating
              ? AdminImpersonationService.instance.impersonatingUserId
              : _supabase.auth.currentUser?.id);

      if (effectiveTarget == null) {
        throw Exception('User not authenticated');
      }

      // Fetch profile with related tables (try user_id first, then fallback to id)
      Map<String, dynamic>? response = await _supabase
          .from('vendor_profiles')
          .select('*, vendor_owners(*), vendor_banking(*)')
          .eq('user_id', effectiveTarget)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        response = await _supabase
            .from('vendor_profiles')
            .select('*, vendor_owners(*), vendor_banking(*)')
            .eq('id', effectiveTarget)
            .limit(1)
            .maybeSingle();
      }

      _vendorProfile = response;

      if (_vendorProfile != null) {
        // Parse JSON fields that might be stored as strings
        if (_vendorProfile!['categories'] is String) {
          try {
            _vendorProfile!['categories'] = jsonDecode(_vendorProfile!['categories']);
          } catch (e) {
            _vendorProfile!['categories'] = [];
          }
        }
        if (_vendorProfile!['subcategories'] is String) {
          try {
            _vendorProfile!['subcategories'] = jsonDecode(_vendorProfile!['subcategories']);
          } catch (e) {
            _vendorProfile!['subcategories'] = [];
          }
        }
        
        // Load documents
        await _loadDocuments();

        // Recalculate completion percentage dynamically to ensure it matches strict requirements
        final calculatedPercentage = _calculateCompletionPercentage(_vendorProfile!);
        final storedPercentage = _vendorProfile!['profile_completion_percentage'] ?? 0;
        
        if (calculatedPercentage != storedPercentage) {
          _vendorProfile!['profile_completion_percentage'] = calculatedPercentage;
          _vendorProfile!['profile_completion_status'] = calculatedPercentage == 100 ? 'complete' : 'incomplete';
          
          // Background update to sync database
          _supabase.from('vendor_profiles').update({
            'profile_completion_percentage': calculatedPercentage,
            'profile_completion_status': calculatedPercentage == 100 ? 'complete' : 'incomplete',
          }).eq('id', _vendorProfile!['id']).then((_) {});
        }
      }
    } catch (e) {
       _error = 'Failed to load vendor profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Claim an unclaimed vendor profile using a claim code
  Future<bool> claimVendor(String claimCode) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      debugPrint('PROVIDER: Starting claim process for code: $claimCode');

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('PROVIDER ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }
      debugPrint('PROVIDER: Authenticated as user: $userId');

      debugPrint('PROVIDER: Fetching vendor by claim code...');
      final vendor = await _supabase
          .from('vendor_profiles')
          .select('id, is_claimed')
          .eq('claim_code', claimCode)
          .limit(1)
          .maybeSingle();

      if (vendor == null) {
        debugPrint('PROVIDER ERROR: No vendor found for code: $claimCode');
        throw Exception('Invalid claim code');
      }
      debugPrint('PROVIDER: Found vendor ID: ${vendor['id']}, is_claimed: ${vendor['is_claimed']}');

      if (vendor['is_claimed'] == true) {
        debugPrint('PROVIDER ERROR: Business already claimed');
        throw Exception('This business has already been claimed');
      }

      // 0. Check if user already has a vendor profile
      final existingProfile = await _supabase
          .from('vendor_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (existingProfile == null) {
        // Fallback: If for some reason the trigger didn't create a profile, 
        // we can just link the unclaimed one as before.
        debugPrint('PROVIDER: No existing profile found, linking unclaimed profile directly.');
        await _supabase
            .from('vendor_profiles')
            .update({
              'user_id': userId,
              'is_claimed': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', vendor['id']);
      } else {
        debugPrint('PROVIDER: Existing profile found. Merging admin data into profile ID: ${existingProfile['id']}');
        
        final String existingId = existingProfile['id'];
        final String unclaimedId = vendor['id'];

        // 1. Fetch full details of the unclaimed profile
        final fullVendorData = await _supabase
            .from('vendor_profiles')
            .select()
            .eq('id', unclaimedId)
            .single();

        // 2. Prepare update data for the profile itself
        final Map<String, dynamic> updateData = Map<String, dynamic>.from(fullVendorData);
        updateData.remove('id');
        updateData.remove('user_id');
        updateData.remove('created_at');
        updateData.remove('claim_code');
        updateData.remove('is_claimed');
        
        updateData['is_claimed'] = true;
        updateData['user_id'] = userId;
        updateData['updated_at'] = DateTime.now().toIso8601String();

        // 3. Perform the updates in order
        
        // A. Update the existing profile with admin-provided business data
        await _supabase
            .from('vendor_profiles')
            .update(updateData)
            .eq('id', existingId);

        // B. Re-link all related data from the unclaimed profile to the vendor's permanent ID
        debugPrint('PROVIDER: Re-linking associated services, documents, and info...');
        
        final tablesToRelink = [
          'vendor_services',
          'vendor_documents',
          'vendor_owners',
          'vendor_banking',
          'vendor_analytics',
          'vendor_featured_posts'
        ];

        for (final table in tablesToRelink) {
          try {
            final foreignKeyColumn = table == 'vendor_documents' ? 'vendor_profile_id' : 'vendor_id';
            await _supabase
                .from(table)
                .update({foreignKeyColumn: existingId})
                .eq(foreignKeyColumn, unclaimedId);
          } catch (e) {
            debugPrint('PROVIDER: Note - No data to re-link for table $table or error: $e');
          }
        }

        // 4. Finally, remove the unclaimed placeholder record
        debugPrint('PROVIDER: Removing the now-empty unclaimed placeholder...');
        await _supabase
            .from('vendor_profiles')
            .delete()
            .eq('id', unclaimedId);
      }

      // 3. Load the newly claimed/merged profile
      debugPrint('PROVIDER: Loading the merged profile...');
      await loadVendorProfile();
      debugPrint('PROVIDER: Claim process complete');
      return true;
    } catch (e, stackTrace) {
      debugPrint('PROVIDER EXCEPTION: $e');
      debugPrint('PROVIDER STACKTRACE: $stackTrace');
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create or update vendor profile (Legacy method, kept for compatibility)

  Future<bool> saveVendorProfile(Map<String, dynamic> profileData) async {
      return saveProfessionalOnboardingData(profileData);
  }

  /// Save full professional onboarding data
  Future<bool> saveProfessionalOnboardingData(Map<String, dynamic> allData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // 1. Extract and Save/Update Vendor Profile (Main Table)
      // Extract profile-specific fields
      final profileFields = [
        'business_name', 'description', 'phone', 'email', 'address', 'website', 
        'categories', 'subcategories', 'venueType', 'location', 
        'legal_business_name', 'trading_name', 'business_type', 'ssm_number', 'ssm_expiry_date',
        'business_registration_address', 'operating_address', 'social_instagram', 'social_tiktok',
        'business_start_year', 'staff_count', 'peak_season_capacity_per_month',
        'coverage_area_state', 'coverage_area_city', 'coverage_radius_km', 'service_max_pax',
        'country', 'country_code', 'city', 'state', 'postal_code',
        'min_order_amount', 'setup_time_hours', 'breakdown_time_hours', 'team_size_per_event',
        'equipment_provided', 'backup_team_available', 'starting_price', 'price_per_pax',
        'weekend_surcharge_percent', 'peak_season_surcharge_percent', 'overtime_rate_per_hour',
        'travel_fee_per_km', 'deposit_required_percent', 'cancellation_policy_days',
        'cancellation_refund_percent', 'reschedule_allowed', 'damage_policy',
        'operating_days', 'operating_hours_start', 'operating_hours_end', 'max_bookings_per_day',
        'lead_time_days', 'same_day_booking_allowed',
        'ic_upload_url', 'ssm_cert_url', 'bank_statement_url', 'insurance_policy_url', 'halal_cert_url',
        'social_facebook', 'social_twitter', 'social_linkedin',
        'agreed_to_terms', 'agreed_to_sla'
      ];
      
      final profileData = Map<String, dynamic>.from(allData)
          ..removeWhere((key, value) => !profileFields.contains(key));
          
      // Calculate completion
      final completionPercentage = _calculateCompletionPercentage(allData);
      
      profileData['user_id'] = userId;
      profileData['profile_completion_percentage'] = completionPercentage;
      profileData['profile_completion_status'] = completionPercentage == 100 ? 'complete' : 'incomplete';
      profileData['updated_at'] = DateTime.now().toIso8601String();

      Map<String, dynamic> savedProfile;
      
      if (_vendorProfile != null && _vendorProfile!['id'] != null) {
        // Update
        savedProfile = await _supabase
            .from('vendor_profiles')
            .update(profileData)
            .eq('id', _vendorProfile!['id'])
            .select()
            .single();
      } else {
        // Insert
        profileData['created_at'] = DateTime.now().toIso8601String();
        savedProfile = await _supabase
            .from('vendor_profiles')
            .insert(profileData)
            .select()
            .single();
      }
      _vendorProfile = savedProfile;
      final vendorId = savedProfile['id'];

      // 2. Save/Update Vendor Owners
      // We assume one owner for now, or we'd need a list handling logic
      if (allData.containsKey('vendor_owners') && allData['vendor_owners'] is List && (allData['vendor_owners'] as List).isNotEmpty) {
         final ownerMap = Map<String, dynamic>.from((allData['vendor_owners'] as List).first);
         if (ownerMap.isNotEmpty) {
             ownerMap['vendor_id'] = vendorId;
             ownerMap.remove('id'); // Prevent primary key collision
             // Check if exists
             final existingOwner = await _supabase.from('vendor_owners').select().eq('vendor_id', vendorId).limit(1).maybeSingle();
             if (existingOwner != null) {
                 await _supabase.from('vendor_owners').update(ownerMap).eq('id', existingOwner['id']);
             } else {
                 await _supabase.from('vendor_owners').insert(ownerMap);
             }
         }
      }

      // 3. Save/Update Vendor Banking
      if (allData.containsKey('vendor_banking') && allData['vendor_banking'] is List && (allData['vendor_banking'] as List).isNotEmpty) {
         final bankingMap = Map<String, dynamic>.from((allData['vendor_banking'] as List).first);
         if (bankingMap.isNotEmpty) {
             bankingMap['vendor_id'] = vendorId;
             bankingMap.remove('id'); // Prevent primary key collision
             final existingBank = await _supabase.from('vendor_banking').select().eq('vendor_id', vendorId).limit(1).maybeSingle();
             if (existingBank != null) {
                 await _supabase.from('vendor_banking').update(bankingMap).eq('id', existingBank['id']);
             } else {
                 await _supabase.from('vendor_banking').insert(bankingMap);
             }
         }
      }
      
      // Reload to get full state
      await loadVendorProfile();
      
      // Notify Admin
      final vendorName = profileData['business_name'] ?? 'A Vendor';
      await AdminNotificationService().notifyNewVendorRegistration(vendorId, vendorName);

      return true;

    } catch (e) {
      _error = 'Failed to save professional profile: $e';
      print("SAVE ERROR: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update vendor address specifically (subset of profile)
  Future<bool> updateVendorAddress({
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    required String country,
    String? fullAddress,
    double? latitude,
    double? longitude,
    String? businessAddress,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Build address update map
      final addressData = {
        'address_line1': addressLine1,
        'city': city,
        'state': state,
        'postal_code': postalCode,
        'country': country,
        'updated_at': DateTime.now().toIso8601String(),
        if (addressLine2 != null) 'address_line2': addressLine2,
        if (fullAddress != null) 'full_address': fullAddress,
        if (fullAddress != null) 'address': fullAddress,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (businessAddress != null) 'business_address': businessAddress,
      };

      // Update vendor_profiles table
      final response = await _supabase
          .from('vendor_profiles')
          .update(addressData)
          .eq('user_id', userId)
          .select()
          .single();

      _vendorProfile = response;
      return true;
    } catch (e) {
      _error = 'Failed to update address: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Submit profile for review (direct status update)
  Future<bool> submitForReview() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_vendorProfile == null) {
        throw Exception('No vendor profile found');
      }

      final profileId = _vendorProfile!['id'];
      if (profileId == null) {
        throw Exception('Vendor profile ID is missing');
      }

      // Update profile status directly
      await _supabase.from('vendor_profiles').update({
        'profile_completion_status': 'pending_review',
        'submitted_at': DateTime.now().toIso8601String(),
      }).eq('id', profileId);

      // Update local profile
      _vendorProfile!['profile_completion_status'] = 'pending_review';
      _vendorProfile!['submitted_at'] = DateTime.now().toIso8601String();

      final userId = _vendorProfile!['user_id'] as String?;
      if (userId != null) {
        await ReferralService.qualifyReferral(userId, 'profile_complete');
      }

      return true;
    } catch (e) {
      print('Error submitting for review: $e');
      _error = 'Failed to submit for review: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload document
  Future<bool> uploadDocument({
    String? filePath,
    Uint8List? fileBytes,
    required String documentType,
    required String fileName,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_vendorProfile == null) {
        throw Exception('Vendor profile not found');
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      String fileUrl;
      int fileSize;
      String mimeType;

      if (filePath != null) {
        // Upload from file path
        final file = File(filePath);
        fileUrl = await _documentService.uploadDocument(
          file: file,
          vendorId: userId,
          documentType: documentType,
        );
        fileSize = await file.length();
        mimeType = _documentService.getMimeType(filePath);
      } else if (fileBytes != null) {
        // Upload from bytes (web platform)
        fileUrl = await _documentService.uploadDocumentFromBytes(
          fileBytes: fileBytes,
          fileName: fileName,
          vendorId: userId,
          documentType: documentType,
        );
        fileSize = fileBytes.length;
        mimeType = _documentService.getMimeType(fileName);
      } else {
        throw Exception('No file data provided');
      }

      // Save document record to database
      final documentData = {
        'vendor_profile_id': _vendorProfile!['id'],
        'document_type': documentType,
        'file_name': fileName,
        'file_url': fileUrl,
        'file_size': fileSize,
        'mime_type': mimeType,
      };

      await _supabase.from('vendor_documents').insert(documentData);

      // Reload documents
      await _loadDocuments();

      // Update profile completion if needed
      await _updateProfileCompletion();

      return true;
    } catch (e) {
      _error = 'Failed to upload document: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete document
  Future<bool> deleteDocument(String documentId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Get document details
      final document = _documents.firstWhere((doc) => doc['id'] == documentId);

      // Delete from storage
      await _documentService.deleteDocument(document['file_url']);

      // Delete from database
      await _supabase.from('vendor_documents').delete().eq('id', documentId);

      // Reload documents
      await _loadDocuments();

      // Update profile completion
      await _updateProfileCompletion();

      return true;
    } catch (e) {
      _error = 'Failed to delete document: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load documents for current vendor profile
  Future<void> _loadDocuments() async {
    if (_vendorProfile == null) {
      _documents = [];
      return;
    }

    try {
      final response = await _supabase
          .from('vendor_documents')
          .select()
          .eq('vendor_profile_id', _vendorProfile!['id']);

      _documents = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      _error = 'Failed to load documents: $e';
      _documents = [];
    }
  }

  /// Calculate profile completion percentage
  int _calculateCompletionPercentage(Map<String, dynamic> profileData) {
    int score = 0;
    final totalSteps = 6;

    // 1. Basic info (Overview tab)
    bool hasBasicInfo = profileData['business_name']?.toString().isNotEmpty == true &&
        profileData['description']?.toString().isNotEmpty == true &&
        profileData['phone']?.toString().isNotEmpty == true &&
        profileData['email']?.toString().isNotEmpty == true &&
        profileData['address']?.toString().isNotEmpty == true;
    if (hasBasicInfo) score++;

    // 2. Business/Owner info (Business Tab & Owner Tab)
    bool hasLegalInfo = profileData['legal_business_name']?.toString().isNotEmpty == true &&
        profileData['ssm_number']?.toString().isNotEmpty == true;
        
    bool hasOwnerInfo = false;
    if (profileData['vendor_owners'] != null && (profileData['vendor_owners'] as List).isNotEmpty) {
      final owner = (profileData['vendor_owners'] as List).first;
      hasOwnerInfo = owner['full_name']?.toString().isNotEmpty == true;
    }
    
    if (hasLegalInfo && hasOwnerInfo) score++;

    // 3. Banking Info (Banking Tab)
    bool hasBanking = false;
    if (profileData['vendor_banking'] != null && (profileData['vendor_banking'] as List).isNotEmpty) {
      final banking = (profileData['vendor_banking'] as List).first;
      hasBanking = banking['bank_name']?.toString().isNotEmpty == true &&
          banking['account_number']?.toString().isNotEmpty == true;
    }
    if (hasBanking) score++;

    // 4. Capability (Capability Tab)
    bool hasCapability = profileData['coverage_area_state']?.toString().isNotEmpty == true;
    if (hasCapability) score++;

    // 5. Pricing (Pricing Tab)
    bool hasPricing = profileData['starting_price'] != null && profileData['starting_price'].toString().isNotEmpty == true;
    if (hasPricing) score++;

    // 6. Documents
    bool hasRequiredDocs = profileData['ssm_cert_url'] != null || 
                           profileData['ic_upload_url'] != null || 
                           profileData['bank_statement_url'] != null;
                           
    // Also check the separate vendor_documents table if populated in the provider
    if (!hasRequiredDocs && _documents.isNotEmpty) {
      hasRequiredDocs = true;
    }
    
    if (hasRequiredDocs) score++;

    return ((score / totalSteps) * 100).round();
  }

  /// Update profile completion percentage
  Future<void> _updateProfileCompletion() async {
    if (_vendorProfile == null) return;

    final completionPercentage =
        _calculateCompletionPercentage(_vendorProfile!);

    await _supabase.from('vendor_profiles').update({
      'profile_completion_percentage': completionPercentage,
      'profile_completion_status':
          completionPercentage == 100 ? 'complete' : 'incomplete',
    }).eq('id', _vendorProfile!['id']);

    _vendorProfile!['profile_completion_percentage'] = completionPercentage;
  }

  /// Resubmit profile for review
  Future<bool> resubmitProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_vendorProfile == null) {
        throw Exception('No vendor profile found');
      }

      await _supabase.from('vendor_profiles').update({
        'profile_completion_status': 'pending_review',
        'submitted_at': DateTime.now().toIso8601String(),
        'rejection_reason': null, // Clear previous rejection reason
        'rejected_at': null,
      }).eq('id', _vendorProfile!['id']);

      _vendorProfile!['profile_completion_status'] = 'pending_review';
      _vendorProfile!['submitted_at'] = DateTime.now().toIso8601String();
      _vendorProfile!['rejection_reason'] = null;
      _vendorProfile!['rejected_at'] = null;

      return true;
    } catch (e) {
      _error = 'Failed to resubmit profile: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Check if document type is uploaded
  bool isDocumentUploaded(String documentType) {
    return _documents.any((doc) => doc['document_type'] == documentType);
  }

  /// Get document by type
  Map<String, dynamic>? getDocumentByType(String documentType) {
    try {
      return _documents.firstWhere(
        (doc) => doc['document_type'] == documentType,
      );
    } catch (e) {
      return null;
    }
  }

  /// Upload profile picture
  Future<bool> uploadProfilePicture(
      Map<String, dynamic> profilePictureData) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_vendorProfile == null) {
        throw Exception('Vendor profile not found');
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if profile picture is already uploaded (has publicUrl)
      String? existingUrl = profilePictureData['publicUrl'];
      if (existingUrl != null && existingUrl.isNotEmpty) {
        // Picture already uploaded, just update the profile
        await _supabase
            .from('vendor_profiles')
            .update({'profile_picture_url': existingUrl}).eq(
                'id', _vendorProfile!['id']);

        _vendorProfile!['profile_picture_url'] = existingUrl;
        return true;
      }

      // Otherwise, upload new picture
      String? filePath = profilePictureData['filePath'];
      Uint8List? fileBytes = profilePictureData['fileBytes'];
      String fileName = profilePictureData['fileName'];

      if (filePath == null && fileBytes == null) {
        throw Exception('No file data provided');
      }

      // Upload to Supabase Storage
      final fileUrl = await _documentService.uploadProfilePicture(
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        vendorId: userId,
      );

      // Update profile with picture URL
      await _supabase.from('vendor_profiles').update(
          {'profile_picture_url': fileUrl}).eq('id', _vendorProfile!['id']);

      _vendorProfile!['profile_picture_url'] = fileUrl;

      return true;
    } catch (e) {
      _error = 'Failed to upload profile picture: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload a file for onboarding and return its URL
  Future<String?> uploadFileForOnboarding({
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    required String folder,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      String fileUrl;
      if (filePath != null) {
         final file = File(filePath);
         fileUrl = await _documentService.uploadDocument(
            file: file, 
            vendorId: userId, 
            documentType: folder // Use folder as type for path organization
         );
      } else if (fileBytes != null) {
         fileUrl = await _documentService.uploadDocumentFromBytes(
            fileBytes: fileBytes,
            fileName: fileName,
            vendorId: userId,
            documentType: folder
         );
      } else {
         return null;
      }
      return fileUrl;
    } catch (e) {
      _error = 'Upload failed: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save documents (batch save for document management screen)
  Future<bool> saveDocuments(List<Map<String, dynamic>> documents) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      if (_vendorProfile == null) {
        throw Exception('Vendor profile not found');
      }

      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Insert documents into database
      for (final doc in documents) {
        final documentData = {
          'vendor_profile_id': _vendorProfile!['id'],
          'document_type': doc['document_type'],
          'file_name': doc['file_name'],
          'file_url': doc['file_url'],
          'file_size': doc['file_size'],
          'created_at': doc['created_at'],
        };

        await _supabase.from('vendor_documents').insert(documentData);
      }

      // Reload documents
      await _loadDocuments();

      // Update profile completion
      await _updateProfileCompletion();

      return true;
    } catch (e) {
      _error = 'Failed to save documents: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Featured Social Media Posts Actions
  Future<List<Map<String, dynamic>>> getFeaturedPosts() async {
    try {
      if (_vendorProfile == null) return [];
      final response = await _supabase
          .from('vendor_featured_posts')
          .select()
          .eq('vendor_id', _vendorProfile!['id'])
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching featured posts: $e');
      return [];
    }
  }

  Future<bool> addFeaturedPost(String platform, String postUrl) async {
    try {
      _isLoading = true;
      notifyListeners();

      if (_vendorProfile == null) throw Exception('Vendor profile not found');

      // Enforce max 3 posts
      final currentPosts = await getFeaturedPosts();
      if (currentPosts.length >= 3) {
        throw Exception('Maximum of 3 featured posts allowed');
      }

      await _supabase.from('vendor_featured_posts').insert({
        'vendor_id': _vendorProfile!['id'],
        'platform': platform,
        'post_url': postUrl,
      });

      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeFeaturedPost(String postId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _supabase.from('vendor_featured_posts').delete().eq('id', postId);
      return true;
    } catch (e) {
      _error = 'Failed to remove post: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
