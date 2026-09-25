import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/expo_summary.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VendorExhibitorApplyScreen extends StatefulWidget {
  final ExpoSummary expo;
  final ExhibitorPackage? preselectedPackage;

  const VendorExhibitorApplyScreen({
    super.key,
    required this.expo,
    this.preselectedPackage,
  });

  static const routeName = '/vendor-exhibitor-apply';

  @override
  State<VendorExhibitorApplyScreen> createState() => _VendorExhibitorApplyScreenState();
}

class _VendorExhibitorApplyScreenState extends State<VendorExhibitorApplyScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isSubmitting = false;
  bool _agreedToTerms = false;

  // Auto-filled vendor info
  final _businessNameCtrl = TextEditingController();
  final _contactPersonCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _businessRegCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _socialMediaCtrl = TextEditingController();

  // Exhibiting category
  final List<String> _allExhibitingCategories = [
    'Venue', 'Catering', 'Photography', 'Videography',
    'MUA', 'Bridal / Busana', 'Decoration', 'Doorgift', 'Other',
  ];
  final Set<String> _selectedExhibitingCategories = {};

  // Package
  late String _selectedPackageName;
  late double _selectedPackagePrice;

  // Booth Location
  String _preferredLocation = 'Any';
  final _specificBoothCtrl = TextEditingController();
  final List<String> _locationOptions = [
    'Any', 'Entrance', 'Main Stage', 'High Traffic', 'Specific Booth',
  ];

  // Requirements
  final List<String> _allRequirements = [
    'Electricity', 'Water', 'Additional table', 'Additional chairs', 'Internet', 'Display equipment',
  ];
  final Set<String> _selectedRequirements = {};

  // Marketing
  bool _marketingOptIn = true;

  @override
  void initState() {
    super.initState();
    final pkg = widget.preselectedPackage ??
        (widget.expo.packages.isNotEmpty ? widget.expo.packages.first : null);
    _selectedPackageName = pkg?.name ?? 'Standard';
    _selectedPackagePrice = pkg?.priceRm ?? 0;

    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillVendorInfo());
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _contactPersonCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _categoryCtrl.dispose();
    _businessRegCtrl.dispose();
    _websiteCtrl.dispose();
    _socialMediaCtrl.dispose();
    _specificBoothCtrl.dispose();
    super.dispose();
  }

  void _prefillVendorInfo() {
    final vendorProfile = Provider.of<VendorProfileProvider>(context, listen: false).vendorProfile;
    final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentVendor = vendorProvider.currentVendor;

    _businessNameCtrl.text = vendorProfile?['business_name'] ??
        currentVendor?.name ??
        AdminImpersonationService.instance.impersonatingVendorName ??
        '';
    _contactPersonCtrl.text = vendorProfile?['contact_person'] ?? auth.userName ?? '';
    _phoneCtrl.text = vendorProfile?['phone'] ?? currentVendor?.phone ?? '';
    _emailCtrl.text = vendorProfile?['email'] ?? currentVendor?.email ?? auth.userEmail ?? '';
    _categoryCtrl.text = vendorProfile?['category'] ?? currentVendor?.category ?? '';
    _businessRegCtrl.text = vendorProfile?['business_registration'] ?? '';
    _websiteCtrl.text = vendorProfile?['website'] ?? '';
    _socialMediaCtrl.text = vendorProfile?['social_media'] ?? '';
    setState(() {});
  }

  Future<void> _submitApplication() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Exhibitor Participation Terms'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final vendorId = AdminImpersonationService.instance.effectiveUserId ?? auth.userId;

      await OrganizerRepository.instance.submitExhibitorApplication(
        expoId: widget.expo.id,
        expoName: widget.expo.name,
        companyName: _businessNameCtrl.text.trim(),
        category: _categoryCtrl.text.trim().isNotEmpty ? _categoryCtrl.text.trim() : 'General',
        contactName: _contactPersonCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        businessRegistration: _businessRegCtrl.text.trim().isNotEmpty ? _businessRegCtrl.text.trim() : null,
        website: _websiteCtrl.text.trim().isNotEmpty ? _websiteCtrl.text.trim() : null,
        socialMedia: _socialMediaCtrl.text.trim().isNotEmpty ? _socialMediaCtrl.text.trim() : null,
        packageName: _selectedPackageName,
        boothFeeRm: _selectedPackagePrice,
        exhibitingCategory: _selectedExhibitingCategories.join(', '),
        preferredLocation: _preferredLocation == 'Specific Booth'
            ? 'Specific: ${_specificBoothCtrl.text.trim()}'
            : _preferredLocation,
        requirements: _selectedRequirements.toList(),
        marketingOptIn: _marketingOptIn,
        vendorId: vendorId,
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 56),
            ),
            const SizedBox(height: 16),
            const Text(
              'Application Submitted! 🎉',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              'Your exhibitor application for\n${widget.expo.name}\nhas been submitted successfully.\n\nThe organiser will review your application and notify you.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // back to detail
                  Navigator.of(context).pop(); // back to hub
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('View My Applications', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Exhibitor Application'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Stepper Indicator
          _buildStepIndicator(),
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: _buildCurrentStep(),
              ),
            ),
          ),
          // Bottom Buttons
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Vendor Info', 'Exhibition', 'Booth & Needs', 'Review'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      color: Colors.white,
      child: Row(
        children: List.generate(steps.length, (i) {
          final isComplete = _currentStep > i;
          final isActive = _currentStep == i;
          return Expanded(
            child: Row(
              children: [
                Column(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: isComplete
                          ? const Color(0xFF10B981)
                          : isActive
                              ? AppTheme.primaryColor
                              : const Color(0xFFCBD5E1),
                      child: isComplete
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.white : const Color(0xFF64748B),
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      steps[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        color: isActive ? AppTheme.primaryColor : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                if (i < steps.length - 1)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
                      color: isComplete ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    return switch (_currentStep) {
      0 => _buildStep1VendorInfo(),
      1 => _buildStep2Exhibition(),
      2 => _buildStep3BoothAndNeeds(),
      3 => _buildStep4Review(),
      _ => const SizedBox.shrink(),
    };
  }

  // ─── Step 1: Vendor Info (auto-filled) ─────────────────────

  Widget _buildStep1VendorInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Vendor Information', 'Auto-filled from your EventEase profile. Update if needed.'),
        const SizedBox(height: 16),
        _buildTextField(_businessNameCtrl, 'Business Name', Icons.store, required: true),
        _buildTextField(_contactPersonCtrl, 'Contact Person', Icons.person, required: true),
        _buildTextField(_phoneCtrl, 'Phone Number', Icons.phone, required: true),
        _buildTextField(_emailCtrl, 'Email Address', Icons.email, required: true),
        _buildTextField(_categoryCtrl, 'Vendor Category', Icons.category),
        _buildTextField(_businessRegCtrl, 'Business Registration (SSM)', Icons.badge),
        _buildTextField(_websiteCtrl, 'Website', Icons.language),
        _buildTextField(_socialMediaCtrl, 'Social Media Handle', Icons.alternate_email),
      ],
    );
  }

  // ─── Step 2: What are you exhibiting + Package ─────────────

  Widget _buildStep2Exhibition() {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('What are you exhibiting?', 'Select all categories that apply.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allExhibitingCategories.map((cat) {
            final isSelected = _selectedExhibitingCategories.contains(cat);
            return FilterChip(
              label: Text(cat),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedExhibitingCategories.add(cat);
                  } else {
                    _selectedExhibitingCategories.remove(cat);
                  }
                });
              },
              selectedColor: AppTheme.primaryColor.withValues(alpha: 0.15),
              checkmarkColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? AppTheme.primaryColor : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? AppTheme.primaryColor : const Color(0xFFCBD5E1),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        _sectionTitle('Preferred Package', null),
        const SizedBox(height: 12),
        ...widget.expo.packages.map((pkg) {
          final isSelected = _selectedPackageName == pkg.name;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedPackageName = pkg.name;
              _selectedPackagePrice = pkg.priceRm;
            }),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.06) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<String>(
                    value: pkg.name,
                    groupValue: _selectedPackageName,
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedPackageName = val;
                        _selectedPackagePrice = pkg.priceRm;
                      });
                    },
                    activeColor: AppTheme.primaryColor,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          pkg.isCustom ? 'Contact Organiser' : currency.format(pkg.priceRm),
                          style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    pkg.boothDimensions,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ─── Step 3: Booth Location + Requirements ─────────────────

  Widget _buildStep3BoothAndNeeds() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Preferred Booth Location', null),
        const SizedBox(height: 12),
        ...(_locationOptions).map((opt) {
          final isSelected = _preferredLocation == opt;
          return RadioListTile<String>(
            value: opt,
            groupValue: _preferredLocation,
            title: Text(opt, style: const TextStyle(fontSize: 14)),
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
            dense: true,
            onChanged: (val) => setState(() => _preferredLocation = val ?? 'Any'),
          );
        }),
        if (_preferredLocation == 'Specific Booth')
          Padding(
            padding: const EdgeInsets.only(left: 32, top: 4, bottom: 8),
            child: TextFormField(
              controller: _specificBoothCtrl,
              decoration: const InputDecoration(
                hintText: 'e.g. A-05',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
        const SizedBox(height: 24),

        _sectionTitle('Operational Requirements', 'Select all your booth requirements.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allRequirements.map((req) {
            final isSelected = _selectedRequirements.contains(req);
            return FilterChip(
              label: Text(req),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedRequirements.add(req);
                  } else {
                    _selectedRequirements.remove(req);
                  }
                });
              },
              selectedColor: const Color(0xFFDCFCE7),
              checkmarkColor: const Color(0xFF059669),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF059669) : const Color(0xFF475569),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: isSelected ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),

        _sectionTitle('Marketing', null),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Feature my business in EventEase expo marketing and directory?',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9A3412)),
                ),
              ),
              Switch(
                value: _marketingOptIn,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) => setState(() => _marketingOptIn = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Step 4: Review & Submit ───────────────────────────────

  Widget _buildStep4Review() {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Review Your Application', 'Please confirm all details before submitting.'),
        const SizedBox(height: 16),

        _reviewCard('Event', widget.expo.name, Icons.festival),
        _reviewCard('Package', '$_selectedPackageName — ${currency.format(_selectedPackagePrice)}', Icons.workspace_premium),
        _reviewCard('Business', _businessNameCtrl.text, Icons.store),
        _reviewCard('Contact', '${_contactPersonCtrl.text}\n${_phoneCtrl.text}\n${_emailCtrl.text}', Icons.person),
        if (_selectedExhibitingCategories.isNotEmpty)
          _reviewCard('Exhibiting', _selectedExhibitingCategories.join(', '), Icons.category),
        _reviewCard('Location', _preferredLocation == 'Specific Booth'
            ? 'Specific: ${_specificBoothCtrl.text}' : _preferredLocation, Icons.location_on),
        if (_selectedRequirements.isNotEmpty)
          _reviewCard('Requirements', _selectedRequirements.join(', '), Icons.checklist),
        _reviewCard('Marketing', _marketingOptIn ? 'Yes — Feature my business' : 'No', Icons.campaign),

        const SizedBox(height: 20),
        CheckboxListTile(
          value: _agreedToTerms,
          onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: AppTheme.primaryColor,
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'I agree to the Exhibitor Participation Terms and Conditions, including the booth fee, cancellation policy, and organiser guidelines.',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569)),
          ),
        ),
      ],
    );
  }

  Widget _reviewCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B), fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Navigation Bar ────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Back', style: TextStyle(color: Color(0xFF475569))),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () {
                      if (_currentStep < 3) {
                        if (_currentStep == 0 && !_formKey.currentState!.validate()) return;
                        setState(() => _currentStep++);
                      } else {
                        _submitApplication();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _currentStep == 3 ? const Color(0xFF10B981) : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isSubmitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      _currentStep == 3 ? 'Submit Application' : 'Next',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────────

  Widget _sectionTitle(String title, String? subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        ],
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        validator: required ? (val) => val == null || val.trim().isEmpty ? '$label is required' : null : null,
      ),
    );
  }
}
