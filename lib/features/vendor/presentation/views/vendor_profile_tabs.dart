import 'package:flutter/material.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_installment_settings_screen.dart';


class BusinessInfoTab extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VendorProfileProvider provider;

  const BusinessInfoTab({super.key, required this.profile, required this.provider});

  @override
  State<BusinessInfoTab> createState() => _BusinessInfoTabState();
}

class _BusinessInfoTabState extends State<BusinessInfoTab> {
  late TextEditingController businessNameCtrl;
  late TextEditingController tradingNameCtrl;
  late TextEditingController ssmNumberCtrl;
  late TextEditingController instagramCtrl;
  late TextEditingController tiktokCtrl;

  @override
  void initState() {
    super.initState();
    businessNameCtrl = TextEditingController(text: widget.profile['legal_business_name']);
    tradingNameCtrl = TextEditingController(text: widget.profile['trading_name']);
    ssmNumberCtrl = TextEditingController(text: widget.profile['ssm_number']);
    instagramCtrl = TextEditingController(text: widget.profile['social_instagram']);
    tiktokCtrl = TextEditingController(text: widget.profile['social_tiktok']);
  }

  @override
  void dispose() {
    businessNameCtrl.dispose();
    tradingNameCtrl.dispose();
    ssmNumberCtrl.dispose();
    instagramCtrl.dispose();
    tiktokCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updates = {
      'legal_business_name': businessNameCtrl.text,
      'trading_name': tradingNameCtrl.text,
      'ssm_number': ssmNumberCtrl.text,
      'social_instagram': instagramCtrl.text,
      'social_tiktok': tiktokCtrl.text,
    };
    final updatedProfile = Map<String, dynamic>.from(widget.profile)..addAll(updates);
    
    await widget.provider.saveProfessionalOnboardingData(updatedProfile);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business info updated'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Business Information', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTextField('Legal Business Name', businessNameCtrl),
          _buildTextField('Trading Name', tradingNameCtrl),
          _buildTextField('SSM Number', ssmNumberCtrl),
          _buildTextField('Instagram Handle', instagramCtrl, prefix: '@'),
          _buildTextField('TikTok Handle', tiktokCtrl, prefix: '@'),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? prefix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class CapabilityTab extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VendorProfileProvider provider;

  const CapabilityTab({super.key, required this.profile, required this.provider});

  @override
  State<CapabilityTab> createState() => _CapabilityTabState();
}

class _CapabilityTabState extends State<CapabilityTab> {
  // Malaysia States for Service Areas
  final List<String> _malaysiaStates = [
    'Johor', 'Kedah', 'Kelantan', 'Melaka', 'Negeri Sembilan', 
    'Pahang', 'Penang', 'Perak', 'Perlis', 'Sabah', 
    'Sarawak', 'Selangor', 'Terengganu', 'Kuala Lumpur', 
    'Labuan', 'Putrajaya'
  ];
  List<String> _selectedStates = [];

  late TextEditingController coverageCityCtrl;
  late TextEditingController maxPaxCtrl;
  late TextEditingController teamSizeCtrl;

  @override
  void initState() {
    super.initState();
    final String existingState = widget.profile['coverage_area_state'] ?? '';
    if (existingState.isNotEmpty) {
      _selectedStates = existingState.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    coverageCityCtrl = TextEditingController(text: widget.profile['coverage_area_city']);
    maxPaxCtrl = TextEditingController(text: widget.profile['service_max_pax']?.toString() ?? '');
    teamSizeCtrl = TextEditingController(text: widget.profile['team_size_per_event']?.toString() ?? '');
  }

  @override
  void dispose() {
    coverageCityCtrl.dispose();
    maxPaxCtrl.dispose();
    teamSizeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updates = {
      'coverage_area_state': _selectedStates.join(', '),
      'coverage_area_city': coverageCityCtrl.text,
      'service_max_pax': int.tryParse(maxPaxCtrl.text),
      'team_size_per_event': int.tryParse(teamSizeCtrl.text),
    };
    final updatedProfile = Map<String, dynamic>.from(widget.profile)..addAll(updates);
    
    await widget.provider.saveProfessionalOnboardingData(updatedProfile);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capability updated'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Service Capability', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildStateSelectionUI(),
          const SizedBox(height: 16),
          _buildTextField('Coverage City', coverageCityCtrl),
          _buildTextField('Max Capacity (Pax)', maxPaxCtrl, keyboardType: TextInputType.number),
          _buildTextField('Team Size Per Event', teamSizeCtrl, keyboardType: TextInputType.number),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateSelectionUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Coverage State",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedStates.isEmpty)
                Text(
                  "No states selected. Click to select states.",
                  style: TextStyle(color: Colors.grey.shade600),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedStates.map((area) {
                    return Chip(
                      label: Text(area, style: const TextStyle(fontSize: 12)),
                      onDeleted: () {
                        setState(() {
                          _selectedStates.remove(area);
                        });
                      },
                      deleteIconColor: Colors.red,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      side: BorderSide.none,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: _showStateSelectionDialog,
                icon: const Icon(Icons.add_location_alt, size: 18),
                label: const Text("Select States"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showStateSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Service Areas (States)"),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _malaysiaStates.length,
                  itemBuilder: (context, index) {
                    final stateName = _malaysiaStates[index];
                    final isSelected = _selectedStates.contains(stateName);
                    return CheckboxListTile(
                      title: Text(stateName),
                      value: isSelected,
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            _selectedStates.add(stateName);
                          } else {
                            _selectedStates.remove(stateName);
                          }
                        });
                        setState(() {});
                      },
                      activeColor: AppTheme.primaryColor,
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedStates.clear();
                    });
                    setDialogState(() {});
                  },
                  child: const Text("Clear All", style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text("Done", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class PricingTab extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VendorProfileProvider provider;

  const PricingTab({super.key, required this.profile, required this.provider});

  @override
  State<PricingTab> createState() => _PricingTabState();
}

class _PricingTabState extends State<PricingTab> {
  late TextEditingController startingPriceCtrl;
  late TextEditingController depositCtrl;
  late TextEditingController weekendSurchargeCtrl;

  @override
  void initState() {
    super.initState();
    startingPriceCtrl = TextEditingController(text: widget.profile['starting_price']?.toString() ?? '');
    depositCtrl = TextEditingController(text: widget.profile['deposit_required_percent']?.toString() ?? '');
    weekendSurchargeCtrl = TextEditingController(text: widget.profile['weekend_surcharge_percent']?.toString() ?? '');
  }

  @override
  void dispose() {
    startingPriceCtrl.dispose();
    depositCtrl.dispose();
    weekendSurchargeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updates = {
      'starting_price': double.tryParse(startingPriceCtrl.text),
      'deposit_required_percent': double.tryParse(depositCtrl.text),
      'weekend_surcharge_percent': double.tryParse(weekendSurchargeCtrl.text),
    };
    final updatedProfile = Map<String, dynamic>.from(widget.profile)..addAll(updates);
    
    await widget.provider.saveProfessionalOnboardingData(updatedProfile);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pricing updated'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pricing & Policies', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTextField('Starting Price (RM)', startingPriceCtrl, keyboardType: TextInputType.number),
          _buildTextField('Deposit Required (%)', depositCtrl, keyboardType: TextInputType.number),
          _buildTextField('Weekend Surcharge (%)', weekendSurchargeCtrl, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VendorInstallmentSettingsScreen(vendorId: widget.profile['id']),
                ),
              );
            },
            icon: const Icon(Icons.payment),
            label: const Text('Configure Installment Settings'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              side: const BorderSide(color: AppTheme.primaryColor),
              foregroundColor: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class OwnerTab extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VendorProfileProvider provider;

  const OwnerTab({super.key, required this.profile, required this.provider});

  @override
  State<OwnerTab> createState() => _OwnerTabState();
}

class _OwnerTabState extends State<OwnerTab> {
  late TextEditingController fullNameCtrl;
  late TextEditingController roleCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController emailCtrl;

  @override
  void initState() {
    super.initState();
    final ownerData = widget.profile['vendor_owners'] != null && (widget.profile['vendor_owners'] as List).isNotEmpty
        ? (widget.profile['vendor_owners'] as List).first
        : <String, dynamic>{};
    fullNameCtrl = TextEditingController(text: ownerData['full_name']?.toString() ?? '');
    roleCtrl = TextEditingController(text: ownerData['role']?.toString() ?? '');
    phoneCtrl = TextEditingController(text: ownerData['phone_number']?.toString() ?? '');
    emailCtrl = TextEditingController(text: ownerData['email']?.toString() ?? '');
  }

  @override
  void dispose() {
    fullNameCtrl.dispose();
    roleCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final ownerData = widget.profile['vendor_owners'] != null && (widget.profile['vendor_owners'] as List).isNotEmpty
        ? Map<String, dynamic>.from((widget.profile['vendor_owners'] as List).first)
        : <String, dynamic>{};
    
    ownerData['full_name'] = fullNameCtrl.text;
    ownerData['role'] = roleCtrl.text;
    ownerData['phone_number'] = phoneCtrl.text;
    ownerData['email'] = emailCtrl.text;

    final updatedProfile = Map<String, dynamic>.from(widget.profile);
    updatedProfile['vendor_owners'] = [ownerData];
    
    await widget.provider.saveProfessionalOnboardingData(updatedProfile);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Owner information updated'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: Colors.amber),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Ensure owner information is accurate for contract purposes.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoCard('Owner / Person In Charge', [
            {'label': 'Full Name', 'controller': fullNameCtrl},
            {'label': 'Role', 'controller': roleCtrl},
            {'label': 'Phone', 'controller': phoneCtrl, 'type': TextInputType.phone},
            {'label': 'Email', 'controller': emailCtrl, 'type': TextInputType.emailAddress},
          ]),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Map<String, dynamic>> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        item['label']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: item['controller'],
                        keyboardType: item['type'],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: InputBorder.none,
                          hintText: 'Enter value',
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class BankingTab extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VendorProfileProvider provider;

  const BankingTab({super.key, required this.profile, required this.provider});

  @override
  State<BankingTab> createState() => _BankingTabState();
}

class _BankingTabState extends State<BankingTab> {
  late TextEditingController bankNameCtrl;
  late TextEditingController accountHolderCtrl;
  late TextEditingController accountNumberCtrl;

  @override
  void initState() {
    super.initState();
    final bankingData = widget.profile['vendor_banking'] != null && (widget.profile['vendor_banking'] as List).isNotEmpty
        ? (widget.profile['vendor_banking'] as List).first
        : <String, dynamic>{};
    bankNameCtrl = TextEditingController(text: bankingData['bank_name']?.toString() ?? '');
    accountHolderCtrl = TextEditingController(text: bankingData['account_holder_name']?.toString() ?? '');
    accountNumberCtrl = TextEditingController(text: bankingData['account_number']?.toString() ?? '');
  }

  @override
  void dispose() {
    bankNameCtrl.dispose();
    accountHolderCtrl.dispose();
    accountNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final bankingData = widget.profile['vendor_banking'] != null && (widget.profile['vendor_banking'] as List).isNotEmpty
        ? Map<String, dynamic>.from((widget.profile['vendor_banking'] as List).first)
        : <String, dynamic>{};
    
    bankingData['bank_name'] = bankNameCtrl.text;
    bankingData['account_holder_name'] = accountHolderCtrl.text;
    bankingData['account_number'] = accountNumberCtrl.text;

    final updatedProfile = Map<String, dynamic>.from(widget.profile);
    updatedProfile['vendor_banking'] = [bankingData];
    
    await widget.provider.saveProfessionalOnboardingData(updatedProfile);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banking information updated'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: const [
                Icon(Icons.security, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Banking information is used for automated payouts.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoCard('Banking Details', [
            {'label': 'Bank Name', 'controller': bankNameCtrl},
            {'label': 'Account Holder', 'controller': accountHolderCtrl},
            {'label': 'Account Number', 'controller': accountNumberCtrl, 'type': TextInputType.number},
          ]),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Map<String, dynamic>> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        item['label']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: item['controller'],
                        keyboardType: item['type'],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: InputBorder.none,
                          hintText: 'Enter value',
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

class OperationsTab extends StatefulWidget {
  final Map<String, dynamic> profile;
  final VendorProfileProvider provider;

  const OperationsTab({super.key, required this.profile, required this.provider});

  @override
  State<OperationsTab> createState() => _OperationsTabState();
}

class _OperationsTabState extends State<OperationsTab> {
  late TextEditingController leadTimeCtrl;
  late TextEditingController maxBookingsCtrl;
  late TextEditingController operatingDaysCtrl;

  @override
  void initState() {
    super.initState();
    leadTimeCtrl = TextEditingController(text: widget.profile['lead_time_days']?.toString() ?? '3');
    maxBookingsCtrl = TextEditingController(text: widget.profile['max_bookings_per_day']?.toString() ?? '1');
    operatingDaysCtrl = TextEditingController(text: (widget.profile['operating_days'] as List?)?.map((e) => e.toString()).join(', ') ?? '');
  }

  @override
  void dispose() {
    leadTimeCtrl.dispose();
    maxBookingsCtrl.dispose();
    operatingDaysCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final days = operatingDaysCtrl.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    
    final updates = {
      'lead_time_days': int.tryParse(leadTimeCtrl.text),
      'max_bookings_per_day': int.tryParse(maxBookingsCtrl.text),
      'operating_days': days,
    };

    final updatedProfile = Map<String, dynamic>.from(widget.profile)..addAll(updates);
    
    await widget.provider.saveProfessionalOnboardingData(updatedProfile);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operations updated'), backgroundColor: AppTheme.successColor),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Operations', [
            {'label': 'Lead Time (Days)', 'controller': leadTimeCtrl, 'type': TextInputType.number},
            {'label': 'Max Bookings/Day', 'controller': maxBookingsCtrl, 'type': TextInputType.number},
            {'label': 'Operating Days', 'controller': operatingDaysCtrl},
          ]),
          const SizedBox(height: 16),
          const Text('Note: Separate operating days with commas (e.g., Monday, Tuesday).', 
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontStyle: FontStyle.italic)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              minimumSize: const Size(double.infinity, 50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Map<String, dynamic>> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        item['label']!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: item['controller'],
                        keyboardType: item['type'],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: InputBorder.none,
                          hintText: 'Enter value',
                        ),
                      ),
                    ),
                  ],
                ),
              )).toList(),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
