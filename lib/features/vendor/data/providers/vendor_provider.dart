import 'package:flutter/material.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/vendor/data/models/vendor_installment_settings.dart';

class VendorProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<AdminVendor> _vendors = [];
  bool _isLoading = false;
  String? _error;

  List<AdminVendor> get vendors => _vendors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  VendorProvider() {
    fetchVendors();
  }

  Future<void> fetchVendors() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('admin_vendors')
          .select('*')
          .order('created_at', ascending: false);

      final List<AdminVendor> loadedVendors = [];

      for (final json in response) {
        // Fetch documents for each vendor
        final docsResponse = await _supabase
            .from('admin_vendor_documents')
            .select('*')
            .eq('vendor_id', json['id'])
            .order('uploaded_at', ascending: false);

        final docs = docsResponse.map((doc) => VendorDocument.fromJson(doc)).toList();

        loadedVendors.add(AdminVendor(
          json['id'],
          json['name'],
          json['category'],
          json['verified'] ?? false,
          json['suspended'] ?? false,
          (json['rating'] ?? 0.0).toDouble(),
          json['reviews'] ?? 0,
          json['bookings'] ?? 0,
          List<String>.from(json['service_areas'] ?? []),
          json['pending_approval'] ?? false,
          contactInfo: json['contact_info'],
          documents: docs,
          documentsVerified: json['documents_verified'] ?? false,
          documentVerificationNotes: json['document_verification_notes'],
          documentsVerifiedAt: json['documents_verified_at'] != null
              ? DateTime.parse(json['documents_verified_at'])
              : null,
        ));
      }

      _vendors = loadedVendors;
    } catch (e) {
      _vendors = [];
      _error = 'Failed to load vendors: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Installment Settings ---

  Future<VendorInstallmentSettings?> getInstallmentSettings(String vendorId) async {
    if (!VendorInstallmentSettings.isValidVendorUuid(vendorId)) {
      return VendorInstallmentSettings.defaultSettings(vendorId);
    }
    try {
      final response = await _supabase
          .from('vendor_installment_settings')
          .select()
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (response != null) {
        return VendorInstallmentSettings.fromSupabase(response);
      }
      return VendorInstallmentSettings.defaultSettings(vendorId);
    } catch (e) {
      print('Error loading installment settings: $e');
      return VendorInstallmentSettings.defaultSettings(vendorId);
    }
  }

  Future<bool> saveInstallmentSettings(VendorInstallmentSettings settings) async {
    if (!VendorInstallmentSettings.isValidVendorUuid(settings.vendorId)) {
      print(
        'Error saving installment settings: vendor_id must be a UUID (got "${settings.vendorId}")',
      );
      return false;
    }
    try {
      await _supabase
          .from('vendor_installment_settings')
          .upsert(settings.toSupabaseJson());
      return true;
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('PGRST204') || msg.contains('schema cache')) {
        try {
          await _supabase
              .from('vendor_installment_settings')
              .upsert(settings.toSupabaseJsonModern());
          return true;
        } catch (e2) {
          print('Error saving installment settings (alternate schema): $e2');
          return false;
        }
      }
      print('Error saving installment settings: $e');
      return false;
    }
  }
}
