
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/presentation/widgets/vendor_drawer.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_document_management_screen_fixed.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_portfolio_screen.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/shared/models/other/venue.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/shared/models/seed_data.dart';
import 'package:eventease/shared/data/vendor_services_data.dart';
import 'package:eventease/core/utils/string_extensions.dart';
import 'package:eventease/features/location/data/providers/location_provider.dart';
import 'package:eventease/features/location/data/models/region.dart';
import 'package:eventease/features/location/data/models/city.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_profile_tabs.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';
import 'package:eventease/features/vendor/presentation/widgets/vendor_setup_checklist.dart';
import 'package:seo/seo.dart';
class VendorProfileEnhancedScreen extends StatefulWidget {
  const VendorProfileEnhancedScreen({super.key});

  @override
  State<VendorProfileEnhancedScreen> createState() => _VendorProfileEnhancedScreenState();
}

class _VendorProfileEnhancedScreenState extends State<VendorProfileEnhancedScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  Region? _selectedRegion;
  City? _selectedCity;
  bool _locationsLoaded = false;

  bool _isEditing = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    // Load vendor profile when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileProvider = Provider.of<VendorProfileProvider>(context, listen: false);
      profileProvider.loadVendorProfile();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VendorProfileProvider, LocationProvider>(
      builder: (context, profileProvider, locationProvider, child) {
        final profile = profileProvider.vendorProfile;

        // Load profile data into controllers when profile changes
        if (profile != null && !_locationsLoaded) {
          _nameController.text = profile['business_name'] ?? '';
          _descriptionController.text = profile['description'] ?? '';
          _locationController.text = profile['address'] ?? '';
          _phoneController.text = profile['phone'] ?? '';
          _emailController.text = profile['email'] ?? '';
          _websiteController.text = profile['website'] ?? '';
          
          _locationsLoaded = true;
        }

        return DefaultTabController(
          length: 8,
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              backgroundColor: AppTheme.primaryColor,
              elevation: 0,
              title: Seo.text(
                text: profile != null
                    ? '${profile['business_name']} — EventEase Vendor'
                    : 'Vendor Profile — EventEase',
                child: Text(
                'Vendor Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ),

              leading: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
              bottom: const TabBar(
                isScrollable: true,
                indicatorColor: Colors.white,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                tabs: [
                  Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
                  Tab(icon: Icon(Icons.business), text: 'Business'),
                  Tab(icon: Icon(Icons.person), text: 'Owner'),
                  Tab(icon: Icon(Icons.account_balance), text: 'Banking'),
                  Tab(icon: Icon(Icons.settings), text: 'Capability'),
                  Tab(icon: Icon(Icons.attach_money), text: 'Pricing'),
                  Tab(icon: Icon(Icons.schedule), text: 'Operations'),
                  Tab(icon: Icon(Icons.verified), text: 'Compliance'),
                ],
              ),
            ),
            drawer: VendorDrawer.build(context),
            body: profileProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : profile == null
                    ? const Center(child: Text('No vendor profile found'))
                    : TabBarView(
                        children: [
                          _buildOverviewTab(profile),
                          BusinessInfoTab(profile: profile, provider: profileProvider),
                          OwnerTab(profile: profile, provider: profileProvider),
                          BankingTab(profile: profile, provider: profileProvider),
                          CapabilityTab(profile: profile, provider: profileProvider),
                          PricingTab(profile: profile, provider: profileProvider),
                          OperationsTab(profile: profile, provider: profileProvider),
                          _buildComplianceTab(profile, profileProvider),
                        ].map((child) => ResponsiveWrapper(child: child)).toList(),
                      ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(Map<String, dynamic> profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isUploadingImage ? null : () => _updateProfilePicture(profile),
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(40),
                    image: profile['profile_picture_url'] != null && profile['profile_picture_url'] != ''
                        ? DecorationImage(
                            image: NetworkImage(profile['profile_picture_url']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: profile['profile_picture_url'] == null || profile['profile_picture_url'] == ''
                      ? const Icon(
                          Icons.business,
                          color: Colors.white,
                          size: 40,
                        )
                      : null,
                ),
                if (_isUploadingImage)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        profile['business_name'] ?? 'Business Name',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (profile['subscription_tier'] != null && profile['subscription_tier'] != 'free')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade400,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          profile['subscription_tier'].toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _getFirstCategory(profile['categories']),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '4.5 (12 reviews)', // Default rating for now
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(profile['profile_completion_status'] ?? 'incomplete'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (profile['profile_completion_percentage'] != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (profile['profile_completion_percentage'] as num) / 100,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${profile['profile_completion_percentage']}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateProfilePicture(Map<String, dynamic> profile) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      setState(() {
        _isUploadingImage = true;
      });

      final profileProvider = Provider.of<VendorProfileProvider>(context, listen: false);
      
      final Map<String, dynamic> payload = {
        'fileName': pickedFile.name,
      };

      try {
        final bytes = await pickedFile.readAsBytes();
        payload['fileBytes'] = bytes;
      } catch (e) {
        payload['filePath'] = pickedFile.path;
      }

      final success = await profileProvider.uploadProfilePicture(payload);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
        // Reload to show new picture
        await profileProvider.loadVendorProfile();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(profileProvider.error ?? 'Failed to upload image')),
        );
      }
    } catch (e) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildEditableField('Name', _nameController, Icons.business),
          const SizedBox(height: 16),
          _buildEditableField('Description', _descriptionController, Icons.description),
          const SizedBox(height: 16),
          
          // Location Selector
          Consumer<LocationProvider>(
            builder: (context, lp, _) {
              if (!_isEditing) {
                return _buildEditableField('Location', _locationController, Icons.location_on);
              }
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor)),
                  const SizedBox(height: 8),
                  // Region Dropdown
                  DropdownButtonFormField<Region>(
                    decoration: InputDecoration(
                      labelText: 'State / Region',
                      prefixIcon: const Icon(Icons.map, color: AppTheme.primaryColor),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    value: _selectedRegion,
                    items: (() {
                      final items = lp.regions.toList();
                      if (_selectedRegion != null && !items.contains(_selectedRegion)) {
                        items.add(_selectedRegion!);
                      }
                      return items.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList();
                    })(),
                    onChanged: (val) {
                      setState(() {
                        _selectedRegion = val;
                        _selectedCity = null;
                      });
                    },
                    validator: (val) => val == null ? 'Please select a state' : null,
                  ),
                  const SizedBox(height: 12),
                  
                  // City Dropdown
                  if (_selectedRegion != null)
                    FutureBuilder<List<City>>(
                      future: lp.fetchCities(_selectedRegion!.id),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                           return const Padding(padding: EdgeInsets.all(8.0), child: LinearProgressIndicator());
                        }
                        final cities = snapshot.data!;
                        return DropdownButtonFormField<City>(
                          decoration: InputDecoration(
                            labelText: 'City',
                            prefixIcon: const Icon(Icons.location_city, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          value: _selectedCity,
                          // Ensure selected city is actually in the list (checks by reference/equality)
                          // Since we reload cities, references might change if not cached correctly.
                          // Ideally adapt equals or use ID search. 
                          // For now, simpler to rely on ID match or check.
                          items: (() {
                            final items = cities.toList();
                            if (_selectedCity != null && !items.contains(_selectedCity)) {
                              items.add(_selectedCity!);
                            }
                            return items.map((c) => DropdownMenuItem(
                              value: c, 
                              child: Text(c.name)
                            )).toList();
                          })(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCity = val;
                              // Update legacy controller for display when not editing
                              _locationController.text = "${val!.name}, ${_selectedRegion!.name}"; 
                            });
                          },
                           validator: (val) => val == null ? 'Please select a city' : null,
                        );
                      }
                    ),
                ],
              );
            }
          ),

          const SizedBox(height: 16),
          _buildEditableField('Phone', _phoneController, Icons.phone),
          const SizedBox(height: 16),
          _buildEditableField('Email', _emailController, Icons.email),
          const SizedBox(height: 16),
          _buildEditableField('Website', _websiteController, Icons.web),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: _isEditing,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isEditing ? AppTheme.primaryColor : Colors.grey.shade300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: _isEditing ? AppTheme.primaryColor : Colors.grey.shade300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
            filled: !_isEditing,
            fillColor: _isEditing ? Colors.transparent : Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildPortfolioSection(Map<String, dynamic> profile) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Portfolio Gallery',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VendorPortfolioScreen(vendorId: profile['id'] ?? 'v1'),
                    ),
                  );
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('Manage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Showcase your best work to attract more customers.',
             style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(Map<String, dynamic> profile, VendorProfileProvider profileProvider) {
    // Get document types that should be displayed (matching onboarding document types)
    final documentTypes = [
      'business_license',
      'tax_registration',
      'insurance_certificate',
      'halal_certificate',
      'professional_certifications',
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Documents & Certifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VendorDocumentManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Manage'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...documentTypes.map((docType) {
            final isUploaded = profileProvider.isDocumentUploaded(docType);
            // Documents from Supabase are pending review until approved by admin
            final status = isUploaded ? 'Pending Review' : 'Not Uploaded';
            final statusColor = isUploaded ? Colors.orange : Colors.grey;
            final statusIcon = isUploaded ? Icons.pending : Icons.upload;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUploaded ? Colors.orange.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isUploaded ? Colors.orange.shade200 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    statusIcon,
                    color: statusColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDocumentName(docType),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isUploaded)
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const VendorDocumentManagementScreen(),
                          ),
                        );
                      },
                      child: const Text('Upload'),
                    ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildLogisticsSection(Map<String, dynamic> profile) {
    final logistics = profile['logistics'] != null
        ? Map<String, dynamic>.from(profile['logistics'] as Map)
        : <String, dynamic>{};
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Logistics & Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildLogisticsItem('Delivery Radius', logistics['deliveryRadius'] ?? 'N/A'),
          _buildLogisticsItem('Setup Included', logistics['setupIncluded'] == true ? 'Yes' : 'No'),
          _buildLogisticsItem('Staffing', logistics['staffing'] == true ? 'Yes' : 'No'),
        ],
      ),
    );
  }

  Widget _buildBusinessHoursSection(Map<String, dynamic> profile) {
    final businessHours = profile['business_hours'] != null 
        ? Map<String, dynamic>.from(profile['business_hours'] as Map)
        : <String, dynamic>{};
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          const Text(
            'Business Hours',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          ...days.map((day) {
            final rawData = businessHours[day];
            final data = rawData != null && rawData is Map
                ? Map<String, dynamic>.from(rawData)
                : {'open': '09:00', 'close': '18:00', 'closed': true};
            final isClosed = data['closed'] == true;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      day[0].toUpperCase() + day.substring(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (_isEditing)
                    Switch(
                      value: !isClosed,
                      onChanged: (value) {
                        setState(() {
                          if (profile['business_hours'] == null) {
                            profile['business_hours'] = {};
                          }
                          profile['business_hours'][day] = {
                            ...data,
                            'closed': !value,
                          };
                        });
                      },
                      activeColor: AppTheme.primaryColor,
                    )
                  else
                    Text(
                      isClosed ? 'Closed' : '${data['open']} - ${data['close']}',
                      style: TextStyle(
                        color: isClosed ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (_isEditing && !isClosed) ...[
                    const SizedBox(width: 8),
                    _buildTimeEditor(day, data, profile),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTimeEditor(String day, Map<String, dynamic> data, Map<String, dynamic> profile) {
    return Row(
      children: [
        GestureDetector(
          onTap: () async {
            final time = await _selectTime(data['open']);
            if (time != null) {
              setState(() {
                profile['business_hours'][day]['open'] = time;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(data['open']),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('-'),
        ),
        GestureDetector(
          onTap: () async {
            final time = await _selectTime(data['close']);
            if (time != null) {
              setState(() {
                profile['business_hours'][day]['close'] = time;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(data['close']),
          ),
        ),
      ],
    );
  }

  Future<String?> _selectTime(String currentTime) async {
    final t = currentTime.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(t[0]), minute: int.parse(t[1])),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (picked != null) {
      return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }
  Widget _buildLogisticsItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionSection(Map<String, dynamic> profile) {
    final subscriptionTier = profile['subscription_tier'] ?? 'free';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subscription',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  subscriptionTier.toString(),
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Current Plan Benefits:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildBenefitItem('Priority listing in search results'),
          _buildBenefitItem('Advanced analytics dashboard'),
          _buildBenefitItem('Premium customer support'),
          _buildBenefitItem('Marketing tools and promotions'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Upgrade functionality - Coming Soon')),
                );
              },
              child: const Text('Upgrade Plan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String benefit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Text(
            benefit,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getDocumentName(String key) {
    switch (key) {
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
      default:
        return key;
    }
  }

  String _getFirstCategory(dynamic categories) {
    if (categories == null) return 'Category';
    if (categories is List && categories.isNotEmpty) {
      return categories.first.toString();
    }
    if (categories is String && categories.isNotEmpty) {
      // If it's a string like '["Cat1", "Cat2"]', it's already failed parsing in provider
      // but let's try to be super safe or just return the string if it's not JSON
      if (categories.startsWith('[') && categories.endsWith(']')) {
        return 'Category';
      }
      return categories;
    }
    return 'Category';
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'incomplete':
        return 'Profile Incomplete';
      case 'complete':
        return 'Profile Complete';
      case 'pending_review':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'suspended':
        return 'Suspended';
      default:
        return 'Unknown Status';
    }
  }

  Widget _buildFeaturesSection() {
    final features = [
      {'title': 'Installment Plans', 'desc': 'Offer flexible payment options', 'icon': Icons.payments, 'color': Colors.green},
      {'title': 'Instant Booking', 'desc': 'Receive bookings instantly', 'icon': Icons.electric_bolt, 'color': Colors.orange},
      {'title': 'Direct Messaging', 'desc': 'Chat with clients real-time', 'icon': Icons.chat, 'color': Colors.blue},
      {'title': 'Analytics', 'desc': 'Track your business growth', 'icon': Icons.insights, 'color': Colors.purple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Platform Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: (feature['color'] as Color).withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: (feature['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(feature['icon'] as IconData, color: feature['color'] as Color, size: 18),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      feature['title'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      feature['desc'] as String,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppTheme.textSecondaryColor,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _saveProfile(Map<String, dynamic> profile, VendorProfileProvider profileProvider) {
    // Create updated profile map
    final updatedProfile = Map<String, dynamic>.from(profile);
    updatedProfile['business_name'] = _nameController.text;
    updatedProfile['description'] = _descriptionController.text;
    
    // Construct address from region/city if selected, else use text controller (fallback)
    if (_selectedRegion != null && _selectedCity != null) {
      updatedProfile['address'] = '${_selectedCity!.name}, ${_selectedRegion!.name}';
    } else {
      updatedProfile['address'] = _locationController.text;
    }

    updatedProfile['phone'] = _phoneController.text;
    updatedProfile['email'] = _emailController.text;
    updatedProfile['website'] = _websiteController.text;
    updatedProfile['updated_at'] = DateTime.now().toIso8601String();

    print('-------------------------------------------');
    print('UI: Save Profile Button Clicked');
    print('Collecting data from controllers:');
    print('Name: ${_nameController.text}');
    print('Desc: ${_descriptionController.text}');
    print('Address: ${updatedProfile['address']}');
    print('Phone: ${_phoneController.text}');
    print('Email: ${_emailController.text}');
    print('Sending to provider: $updatedProfile');
    print('-------------------------------------------');

    // Update through provider
    profileProvider.saveVendorProfile(updatedProfile);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  // ============ TAB BUILDERS ============

  Widget _buildOverviewTab(Map<String, dynamic> profile) {
    return SingleChildScrollView(
      child: ResponsiveWrapper(
        padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(profile),
          const SizedBox(height: 16),
          const VendorSetupChecklist(),
          const SizedBox(height: 16),
          _buildSubscriptionSection(profile),
          const SizedBox(height: 20),
          _buildInfoCard('Quick Stats', [
            {'label': 'Status', 'value': _getStatusText(profile['status'] ?? 'pending')},
            {'label': 'Vendor Tier', 'value': (profile['subscription_tier'] ?? 'free').toString().capitalize()},
            {'label': 'Member Since', 'value': profile['created_at'] != null ? DateFormat('MMM yyyy').format(DateTime.parse(profile['created_at'])) : '-'},
            {'label': 'Verification', 'value': (profile['verification_level'] ?? 'basic').toString().capitalize()},
            {'label': 'Rating', 'value': '${profile['rating'] ?? 0.0} ⭐'},
            {'label': 'Total Bookings', 'value': '${profile['total_bookings'] ?? 0}'},
          ]),
          const SizedBox(height: 16),
          _buildFeaturesSection(),
          const SizedBox(height: 16),
          _buildQRCodeCard(profile),
          const SizedBox(height: 16),
          _buildInfoCard('Business Summary', [
            {'label': 'Legal Name', 'value': profile['legal_business_name'] ?? '-'},
            {'label': 'Business Type', 'value': profile['business_type'] ?? '-'},
            {'label': 'SSM Number', 'value': profile['ssm_number'] ?? '-'},
            {'label': 'Coverage Area', 'value': '${profile['coverage_area_city'] ?? ''}, ${profile['coverage_area_state'] ?? ''}'},
          ]),
        ],
      ),
    ),
  );
}

  Widget _buildQRCodeCard(Map<String, dynamic> profile) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/vendor-qr-codes');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_2,
                  color: AppTheme.primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Share Your QR Code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Let customers scan to view your profile',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildComplianceTab(Map<String, dynamic> profile, VendorProfileProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDocumentsSection(profile, provider),
          const SizedBox(height: 20),
          _buildInfoCard('Agreements', [
            {'label': 'Terms & Conditions', 'value': profile['agreed_to_terms'] == true ? '✅ Agreed' : '❌ Not Agreed'},
            {'label': 'Service Level Agreement', 'value': profile['agreed_to_sla'] == true ? '✅ Agreed' : '❌ Not Agreed'},
          ]),
        ],
      ),
    );
  }

  // ============ HELPER WIDGETS ============

  Widget _buildInfoCard(String title, List<Map<String, String>> items) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const Divider(),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(item['label']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(item['value']!, style: const TextStyle(color: AppTheme.textSecondaryColor)),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableTextField(String label, TextEditingController controller, {String? prefix, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixText: prefix,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildDocumentCard(String title, String? url) {
    final hasDocument = url != null && url.isNotEmpty;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(hasDocument ? Icons.check_circle : Icons.upload_file, 
          color: hasDocument ? AppTheme.successColor : AppTheme.textSecondaryColor),
        title: Text(title),
        subtitle: Text(hasDocument ? 'Uploaded' : 'Not uploaded'),
        trailing: hasDocument ? const Icon(Icons.visibility, color: AppTheme.primaryColor) : null,
        onTap: hasDocument ? () {
          // TODO: Open document viewer
        } : null,
      ),
    );
  }

  // ============ SAVE HANDLERS ============


  // ============ UTILITY METHODS ============

  String _maskIC(String? ic) {
    if (ic == null || ic.isEmpty) return '-';
    if (ic.length <= 4) return ic;
    return '******${ic.substring(ic.length - 4)}';
  }

  String _maskAccountNumber(String? accountNumber) {
    if (accountNumber == null || accountNumber.isEmpty) return '-';
    if (accountNumber.length <= 4) return accountNumber;
    return '****${accountNumber.substring(accountNumber.length - 4)}';
  }
}
