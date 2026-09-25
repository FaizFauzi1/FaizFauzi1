import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class VendorInfoScreen extends StatefulWidget {
  final String vendorId;

  const VendorInfoScreen({super.key, required this.vendorId});

  @override
  State<VendorInfoScreen> createState() => _VendorInfoScreenState();
}

class _VendorInfoScreenState extends State<VendorInfoScreen> {
  List<Map<String, dynamic>> _verifiedDocuments = [];
  bool _loadingDocuments = true;

  @override
  void initState() {
    super.initState();
    _loadVerifiedDocuments();
  }

  Future<void> _loadVerifiedDocuments() async {
    try {
      final docs = await SupabaseService.select(
        table: 'vendor_documents',
        filters: {'vendor_profile_id': widget.vendorId, 'verification_status': 'approved'},
      );
      setState(() {
        _verifiedDocuments = docs;
        _loadingDocuments = false;
      });
    } catch (e) {
      print('Error loading verified documents: $e');
      setState(() {
        _loadingDocuments = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Vendor Information',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<VendorProvider>(
        builder: (context, vendorProvider, child) {
          final vendor = vendorProvider.vendors.firstWhere(
            (v) => v.id == widget.vendorId,
            orElse: () => Vendor(
              id: '',
              name: 'Unknown',
              categories: [],
              subcategories: [],
              description: '',
              location: '',
              images: [],
              rating: 0,
              reviewCount: 0,
              status: VendorStatus.pending,
              documents: {},
              subscriptionTier: SubscriptionTier.free,
              logistics: {},
              contactInfo: {},
              sampleServiceIds: [],
              planningHorizon: 0,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

          if (vendor.id.isEmpty) {
            return const Center(child: Text('Vendor not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('About the Vendor'),
                const SizedBox(height: 8),
                _buildInfoCard(
                  child: Text(
                    vendor.description.isNotEmpty
                        ? vendor.description
                        : 'No description available.',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Contact Information'),
                const SizedBox(height: 8),
                _buildInfoCard(
                  child: Column(
                    children: [
                      _buildContactRow(Icons.email, vendor.contactInfo['email'] ?? 'Not available'),
                      const SizedBox(height: 12),
                      _buildContactRow(Icons.phone, vendor.contactInfo['phone'] ?? 'Not available'),
                      const SizedBox(height: 12),
                      _buildContactRow(Icons.location_on, vendor.location),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Business Hours Section
                if (vendor.businessHours != null && vendor.businessHours!.isNotEmpty) ...[
                  _buildSectionTitle('Business Hours'),
                  const SizedBox(height: 8),
                  _buildInfoCard(
                    child: Column(
                      children: _buildBusinessHoursList(vendor.businessHours!),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                _buildSectionTitle('Availability & Logistics'),
                const SizedBox(height: 8),
                _buildInfoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Planning Horizon', '${vendor.planningHorizon} days in advance'),
                      if (vendor.logistics['delivery_radius'] != null) ...[
                        const SizedBox(height: 12),
                        _buildDetailRow('Delivery Radius', '${vendor.logistics['delivery_radius']} km'),
                      ],
                      if (vendor.serviceAreas.isNotEmpty) ...[
                         const SizedBox(height: 12),
                         _buildDetailRow('Service Areas', vendor.serviceAreas.join(', ')),
                      ]
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildSectionTitle('Certifications & Documents'),
                const SizedBox(height: 8),
                _buildInfoCard(
                  child: _loadingDocuments
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : _verifiedDocuments.isEmpty
                          ? const Text(
                              'No verified documents available.',
                              style: TextStyle(color: AppTheme.textSecondaryColor),
                            )
                          : Column(
                              children: _verifiedDocuments.map((doc) {
                                final docType = doc['document_type'] ?? 'Unknown';
                                final docName = _getDocumentDisplayName(docType);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.verified_user, color: AppTheme.primaryColor, size: 24),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          docName,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      const Icon(Icons.check_circle, color: Colors.green, size: 22),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
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
      child: child,
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBusinessHoursList(Map<String, dynamic> businessHours) {
    final daysOfWeek = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayLabels = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    
    List<Widget> hourWidgets = [];
    
    for (int i = 0; i < daysOfWeek.length; i++) {
      final day = daysOfWeek[i];
      final dayLabel = dayLabels[i];
      final dayData = businessHours[day];
      
      String hoursText = 'Closed';
      Color hoursColor = AppTheme.textSecondaryColor;
      
      if (dayData != null && dayData is Map) {
        // Match vendor profile logic: check 'closed' field, not 'isOpen'
        final isClosed = dayData['closed'] == true;
        if (!isClosed) {
          final openTime = dayData['open'] ?? '';
          final closeTime = dayData['close'] ?? '';
          if (openTime.isNotEmpty && closeTime.isNotEmpty) {
            hoursText = '$openTime - $closeTime';
            hoursColor = AppTheme.textPrimaryColor;
          }
        }
      }
      
      hourWidgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: i < daysOfWeek.length - 1 ? 12.0 : 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayLabel,
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                hoursText,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: hoursColor,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return hourWidgets;
  }

  String _getDocumentDisplayName(String docType) {
    switch (docType.toLowerCase()) {
      case 'business_license':
        return 'Business License';
      case 'tax_registration':
        return 'Tax Registration';
      case 'insurance_certificate':
        return 'Insurance Certificate';
      case 'halal_certificate':
        return 'Halal Certificate';
      case 'professional_certifications':
        return 'Professional Certifications';
      case 'food_safety_certificate':
        return 'Food Safety Certificate';
      case 'health_permit':
        return 'Health Permit';
      default:
        return docType.replaceAll('_', ' ').split(' ').map((word) => 
          word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1)
        ).join(' ');
    }
  }
}
