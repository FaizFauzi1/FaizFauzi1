import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/features/vendor/presentation/views/enhanced_service_creation_screen.dart';

/// Canonical entry to create or edit a vendor service.
void openVendorServiceCreation(BuildContext context, {String? serviceId}) {
  final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
  final vendor = vendorProvider.currentVendor;
  if (vendor == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Vendor profile not loaded. Please wait or reload.')),
    );
    return;
  }

  VendorServiceEnhanced? existing;
  if (serviceId != null) {
    final matches = vendorProvider.getCurrentVendorServices().where((s) => s.id == serviceId);
    if (matches.isNotEmpty) existing = matches.first;
  }

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => EnhancedServiceCreationScreen(
        vendorId: vendor.id,
        existingService: existing,
      ),
    ),
  );
}
