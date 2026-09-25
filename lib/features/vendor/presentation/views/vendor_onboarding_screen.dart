import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_dashboard_screen.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/features/vendor/models/vendor_service_enhanced.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/models/services/service_enums.dart'; 
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/features/vendor/presentation/views/onboarding/step_business_info.dart';
import 'package:eventease/features/vendor/presentation/views/onboarding/step_owner_details.dart';
import 'package:eventease/features/vendor/presentation/views/onboarding/step_banking_payment.dart';
import 'package:eventease/features/vendor/presentation/views/onboarding/step_service_capability.dart';
import 'package:eventease/features/vendor/presentation/views/onboarding/step_pricing_packages.dart';
import 'package:eventease/features/vendor/presentation/views/onboarding/step_operations.dart';
import 'package:eventease/features/vendor/presentation/views/onboarding/step_compliance.dart';


import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:eventease/core/utils/location_helper.dart';

final SupabaseClient supabase = Supabase.instance.client;

class AddServiceDialog extends StatefulWidget {
   final Map<String, dynamic>? service;
   final Set<String> selectedCategories;
   final void Function(VendorService) onServiceAdded;

   const AddServiceDialog({
     super.key,
     this.service,
     required this.selectedCategories,
     required this.onServiceAdded,
   });

   @override
   State<AddServiceDialog> createState() => _AddServiceDialogState();
 }

 class _AddServiceDialogState extends State<AddServiceDialog> {
   final _formKey = GlobalKey<FormState>();
   String _name = '';
   String _description = '';
   String _category = '';
   String? _subcategory;
   String _priceType = 'fixed'; // 'fixed', 'hourly', 'per_person', etc.
   double _basePrice = 0.0;
   double? _hourlyRate;
   int? _durationHours;
   int? _maxGuests;
   List<String> _features = [];
   ServiceType _serviceType = ServiceType.service;
   bool _isFeatured = false;
   int? _minAdvanceBookingDays;
   bool _active = true;


   @override
   void initState() {
     super.initState();
     // Set initial category from selected categories
     if (widget.selectedCategories.isNotEmpty) {
       _category = widget.selectedCategories.first;
     } else {
       _category = 'Other'; // Fallback category
     }

     // Populate fields if editing existing service
     if (widget.service != null) {
       _name = widget.service!['name'] ?? '';
       _description = widget.service!['description'] ?? '';
       _category = widget.service!['category'] ?? _category;
       _priceType = widget.service!['priceType'] ?? 'fixed';
       _basePrice = widget.service!['price'] ?? 0.0;
       _hourlyRate = widget.service!['hourlyRate'];
       _durationHours = widget.service!['durationHours'];
       _maxGuests = widget.service!['maxGuests'];
       _features = List<String>.from(widget.service!['features'] ?? []);
       _serviceType = ServiceType.values.firstWhere(
         (e) => e.toString().split('.').last == widget.service!['type'],
         orElse: () => ServiceType.service,
       );
       _isFeatured = widget.service!['isFeatured'] ?? false;
       _active = widget.service!['active'] ?? true;
       _minAdvanceBookingDays = widget.service!['minAdvanceBookingDays'];
     }
   }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.service != null ? 'Edit Service' : 'Add New Service',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),

              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Service Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                        onSaved: (value) => _name = value!,
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                        onSaved: (value) => _description = value!,
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        value: _category,
                        items: widget.selectedCategories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Row(
                              children: [
                                Icon(_getCategoryIcon(category), size: 18),
                                const SizedBox(width: 8),
                                Text(category),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _category = value!;
                            _subcategory = null;
                          });
                        },
                        validator: (value) => null, // Remove validation for now to test
                      ),

                      const SizedBox(height: 16),

                      if (_getSubcategories(_category).isNotEmpty) ...[
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Subcategory',
                            border: OutlineInputBorder(),
                          ),
                          value: _subcategory,
                          items: _getSubcategories(_category).map((subcategory) {
                            return DropdownMenuItem(
                              value: subcategory,
                              child: Text(subcategory),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _subcategory = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                      ],

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Price Type',
                          border: OutlineInputBorder(),
                        ),
                        value: _priceType,
                        items: const [
                          DropdownMenuItem(value: 'fixed', child: Text('Fixed Price')),
                          DropdownMenuItem(value: 'hourly', child: Text('Hourly Rate')),
                          DropdownMenuItem(value: 'per_person', child: Text('Per Person')),
                          DropdownMenuItem(value: 'per_day', child: Text('Per Day')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _priceType = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      DropdownButtonFormField<ServiceType>(
                        decoration: const InputDecoration(
                          labelText: 'Service Type',
                          border: OutlineInputBorder(),
                        ),
                        value: _serviceType,
                        items: ServiceType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toString().split('.').last),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _serviceType = value!;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Base Price (RM)',
                          border: OutlineInputBorder(),
                          prefixText: 'RM ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a base price';
                          }
                          final price = double.tryParse(value!);
                          if (price == null || price < 0) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                        onSaved: (value) => _basePrice = double.parse(value!),
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Hourly Rate (RM) - Optional',
                          border: OutlineInputBorder(),
                          prefixText: 'RM ',
                        ),
                        keyboardType: TextInputType.number,
                        onSaved: (value) => _hourlyRate = value?.isEmpty ?? true ? null : double.parse(value!),
                      ),

                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Duration Hours',
                                border: OutlineInputBorder(),
                                suffixText: 'hours',
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) => _durationHours = value?.isEmpty ?? true ? null : int.parse(value!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Max Guests',
                                border: OutlineInputBorder(),
                                suffixText: 'people',
                              ),
                              keyboardType: TextInputType.number,
                              onSaved: (value) => _maxGuests = value?.isEmpty ?? true ? null : int.parse(value!),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Simplified features input to prevent Android crashes
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Service Features (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Brief description of key features',
                        ),
                        maxLines: 2,
                        onSaved: (value) {
                          if (value?.isNotEmpty ?? false) {
                            // Store as single feature to avoid complex processing
                            _features = [value!.trim()];
                          } else {
                            _features = [];
                          }
                        },
                      ),

                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Featured Service'),
                        subtitle: const Text('Highlight this service on your profile'),
                        value: _isFeatured,
                        onChanged: (value) {
                          setState(() {
                            _isFeatured = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      SwitchListTile(
                        title: const Text('Active'),
                        value: _active,
                        onChanged: (value) {
                          setState(() {
                            _active = value;
                          });
                        },
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: AppTheme.textSecondaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveService,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(widget.service != null ? 'Update Service' : 'Submit for Review'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveService() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      print('📝 SERVICE ADDED DURING ONBOARDING: "${_name}" added to services list (will be submitted for review later)');

      final newService = VendorService(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        vendorId: '', // Will be set by the provider
        name: _name,
        description: _description,
        category: EventCategory.values.firstWhere(
          (e) => e.name.toLowerCase() == _category.toLowerCase(),
          orElse: () => EventCategory.package,
        ),
        basePrice: _basePrice,
        types: [_serviceType],
        status: _active ? ServiceStatus.active : ServiceStatus.inactive,
        options: {
          'priceType': _priceType,
          'durationHours': _durationHours,
          'maxGuests': _maxGuests,
          'features': _features,
          'isFeatured': _isFeatured,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      widget.onServiceAdded(newService);
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  List<String> _getSubcategories(String category) {
    switch (category) {
      case 'Catering':
        return [
          'Wedding Catering',
          'Corporate Events',
          'Private Parties',
          'Buffet Service'
        ];
      case 'Photography':
        return [
          'Wedding Photography',
          'Event Coverage',
          'Portrait Sessions',
          'Video Services'
        ];
      case 'Venues':
        return [
          'Wedding Venues',
          'Corporate Events',
          'Private Functions',
          'Outdoor Venues'
        ];
      case 'Fashion':
        return [
          'Wedding Dresses',
          'Suits & Tuxedos',
          'Traditional Attire',
          'Accessories'
        ];
      case 'Decoration':
        return [
          'Wedding Decor',
          'Event Styling',
          'Floral Arrangements',
          'Lighting'
        ];
      default:
        return ['General Services'];
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Catering':
        return Icons.restaurant;
      case 'Photography':
        return Icons.camera_alt;
      case 'Venues':
        return Icons.location_city;
      case 'Fashion':
        return Icons.checkroom;
      case 'Decoration':
        return Icons.celebration;
      case 'Entertainment':
        return Icons.music_note;
      case 'Transportation':
        return Icons.directions_car;
      case 'Beauty & Makeup':
        return Icons.face;
      case 'Music & DJ':
        return Icons.headphones;
      default:
        return Icons.business;
    }
  }
}

class VendorOnboardingScreen extends StatefulWidget {
  final String? initialEmail;
  final String? initialPhone;
  final String? initialBusinessName;

  const VendorOnboardingScreen({super.key, this.initialEmail, this.initialPhone, this.initialBusinessName});

  @override
  State<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState extends State<VendorOnboardingScreen> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  // Form controllers
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  // Address step controllers
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _addressLine2Controller = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  // Phone number with country code
  PhoneNumber? _phoneNumber;
  PhoneNumber? _initialPhoneNumber;
  String _initialCountryCode = 'MY'; // Default, will update via location

  // Form data
  final Set<String> _selectedCategories = <String>{};
  List<String> _selectedSubcategories = [];
  List<Map<String, dynamic>> _services = [];
  Map<String, dynamic> _businessInfo = {};
  Map<String, dynamic> _documents = {};
  Map<String, dynamic>? _profilePicture;
  
  // centralized onboarding data
  Map<String, dynamic> _onboardingData = {};

  final List<String> _categories = [
    'Catering',
    'Photography',
    'Venues',
    'Fashion',
    'Decoration',
    'Entertainment',
    'Transportation',
    'Beauty & Makeup',
    'Music & DJ',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    final currentUser = supabase.auth.currentUser;

    // Prefill business name: use widget arg or fallback to user metadata
    if (widget.initialBusinessName != null && widget.initialBusinessName!.isNotEmpty) {
      _businessNameController.text = widget.initialBusinessName!;
    } else if (currentUser != null && currentUser.userMetadata != null) {
      final fullName = currentUser.userMetadata!['full_name'];
      if (fullName != null && fullName is String && fullName.isNotEmpty) {
        _businessNameController.text = fullName;
      }
    }

    // Prefill email: use widget arg or fallback to user email
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
    } else if (currentUser != null && currentUser.email != null) {
       _emailController.text = currentUser.email!;
    }
    // Prefill phone if provided
    if (widget.initialPhone != null && widget.initialPhone!.isNotEmpty) {
      final phoneText = widget.initialPhone!;
      try {
        if (phoneText.startsWith('+')) {
          // If it has a country code, let the parser handle it automatically
          _phoneNumber = PhoneNumber.fromCompleteNumber(completeNumber: phoneText);
        } else {
          // Fallback
          _phoneNumber = PhoneNumber(
            countryISOCode: _initialCountryCode,
            countryCode: '',
            number: phoneText.replaceAll(RegExp(r'[^\d]'), ''),
          );
        }
      } catch (e) {
        // Fallback on error
        _phoneNumber = PhoneNumber(
          countryISOCode: _initialCountryCode,
          countryCode: '',
          number: phoneText.replaceAll(RegExp(r'[^\d]'), ''),
        );
      }
    }
    // Add listeners to trigger rebuild when text changes
    _businessNameController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
    _phoneController.addListener(_onFormChanged);
    _emailController.addListener(_onFormChanged);
    _addressController.addListener(_onFormChanged);
    _websiteController.addListener(_onFormChanged);

    // Load existing profile data after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // _detectLocationForPhone(); // Removed to prevent forcing location permission on startup
        _loadExistingProfile();
      }
    });
  }

  Future<void> _detectLocationForPhone() async {
    final countryCode = await LocationHelper.detectCountryCode();
    if (countryCode != null && mounted) {
      setState(() {
        _initialCountryCode = countryCode;
      });
    }
  }

  bool _isLoadingProfile = true;

  Future<void> _loadExistingProfile() async {
    if (!mounted) return;
    setState(() => _isLoadingProfile = true);
    
    try {
      final profileProvider =
          Provider.of<VendorProfileProvider>(context, listen: false);
      await profileProvider.loadVendorProfile();

      if (!mounted) return;

      if (profileProvider.vendorProfile != null) {
        final profile = profileProvider.vendorProfile!;
        
        setState(() {
          _onboardingData = Map<String, dynamic>.from(profile);
          
          // Populate legacy controllers for backup (optional, can be removed if fully migrated)
          if (profile['business_name'] != null) _businessNameController.text = profile['business_name'];
          if (profile['email'] != null) _emailController.text = profile['email'];
          if (profile['phone'] != null) _phoneController.text = profile['phone'];
          
          // Map flattened fields to structure if needed? 
          // Our save logic flattens them, so load logic gets them flat. 
          // The Nested mappings (owners, banking) come from joins.
          if (profile['vendor_owners'] != null && (profile['vendor_owners'] as List).isNotEmpty) {
             _onboardingData['owner_details'] = (profile['vendor_owners'] as List).first;
             // Remove list wraper for the step widget which expects Map
          }
          if (profile['vendor_banking'] != null && (profile['vendor_banking'] as List).isNotEmpty) {
             _onboardingData['banking_details'] = (profile['vendor_banking'] as List).first;
          }
        });
      } else {
        // Init with pre-fills
         _onboardingData['business_name'] = _businessNameController.text;
         _onboardingData['email'] = _emailController.text;
         _onboardingData['phone'] = _phoneController.text; // Note: this might be raw text
      }
    } catch (e) {
      print('Error loading existing profile: $e');
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }
  Future<void> _loadExistingDocuments() async {
    if (!mounted) return;
    final profileProvider =
        Provider.of<VendorProfileProvider>(context, listen: false);
    final documents = profileProvider.documents;

    setState(() {
      for (final doc in documents) {
        final displayName = _getDocumentDisplayName(doc['document_type']);
        if (displayName != null) {
          _documents[displayName] = {
            'fileName': doc['file_name'],
            'fileUrl': doc['file_url'],
            'uploaded': true,
          };
        }
      }
    });
  }

  String? _getDocumentDisplayName(String documentType) {
    switch (documentType) {
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
        return null;
    }
  }

  void _determineCurrentStep(Map<String, dynamic> profile) {
    final completionPercentage = profile['profile_completion_percentage'] ?? 0;
    final status = profile['profile_completion_status'] ?? 'incomplete';

    if (status == 'complete' ||
        status == 'pending_review' ||
        status == 'approved') {
      // Profile is complete, go to review step
      setState(() {
        _currentStep = 7;
      });
      _pageController.jumpToPage(7);
    } else if (completionPercentage >= 75) {
      // Compliance step
      setState(() {
        _currentStep = 6;
      });
      _pageController.jumpToPage(6);
    } else if (completionPercentage >= 50) {
      // Service step
      setState(() {
        _currentStep = 3;
      });
      _pageController.jumpToPage(3);
    } else if (completionPercentage >= 25) {
      // Owner step
      setState(() {
        _currentStep = 1;
      });
      _pageController.jumpToPage(1);
    } else {
      // Basic info step
      setState(() {
        _currentStep = 0;
      });
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    // Remove listeners
    _businessNameController.removeListener(_onFormChanged);
    _descriptionController.removeListener(_onFormChanged);
    _phoneController.removeListener(_onFormChanged);
    _emailController.removeListener(_onFormChanged);
    _addressController.removeListener(_onFormChanged);
    _websiteController.removeListener(_onFormChanged);

    // Dispose controllers
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    
    // Dispose address controllers
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    
    _pageController.dispose();
    super.dispose();
  }

  Future<String?> _handleUploadFile(String fieldName) async {
    String folder = 'documents';
    if (fieldName.contains('ic')) folder = 'identification';
    else if (fieldName.contains('ssm')) folder = 'business_registration';
    else if (fieldName.contains('bank')) folder = 'banking';
    
    try {
        final result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        );
        
        if (result != null) {
            final file = result.files.first;
            final provider = Provider.of<VendorProfileProvider>(context, listen: false);
            return await provider.uploadFileForOnboarding(
                filePath: file.path, 
                fileBytes: file.bytes, 
                fileName: file.name, 
                folder: folder
            );
        }
    } catch (e) {
        print("Picker Error: $e");
    }
    return null;
  }

  void _onFormChanged() {
    if (mounted) {
      setState(() {}); // Trigger rebuild to update button state
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Vendor Onboarding',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        // Removed back button to prevent navigation errors - onboarding is mandatory
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          _isLoadingProfile 
              ? const Center(child: CircularProgressIndicator()) 
              : Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                BusinessInfoStep(
                    data: _onboardingData, 
                    onChanged: (d) => setState(() => _onboardingData.addAll(d))
                ),
                OwnerDetailsStep(
                    data: Map<String, dynamic>.from(_onboardingData['owner_details'] ?? {}), 
                    onChanged: (d) => setState(() => _onboardingData['owner_details'] = d)
                ),
                BankingPaymentStep(
                    data: Map<String, dynamic>.from(_onboardingData['banking_details'] ?? {}), 
                    onChanged: (d) => setState(() => _onboardingData['banking_details'] = d)
                ),
                ServiceCapabilityStep(
                    data: _onboardingData, 
                    onChanged: (d) => setState(() => _onboardingData.addAll(d))
                ),
                PricingPackagesStep(
                    data: _onboardingData, 
                    onChanged: (d) => setState(() => _onboardingData.addAll(d))
                ),
                OperationsStep(
                    data: _onboardingData, 
                    onChanged: (d) => setState(() => _onboardingData.addAll(d))
                ),
                ComplianceStep(
                    data: _onboardingData, 
                    onChanged: (d) => setState(() => _onboardingData.addAll(d)), 
                    onUploadFile: _handleUploadFile
                ),
                _buildReviewStep(),
              ],
            ),
          ),
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(8, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.primaryColor
                    : isActive
                        ? AppTheme.primaryColor.withOpacity(0.3)
                        : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Business Information',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about your business to get started',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          _buildProfilePictureUpload(),
          const SizedBox(height: 20),
          _buildTextField(
              'Business Name', _businessNameController, Icons.business),
          const SizedBox(height: 20),
          _buildTextField(
              'Description', _descriptionController, Icons.description,
              maxLines: 3),
          const SizedBox(height: 20),
          _buildPhoneNumberField(),
          const SizedBox(height: 20),
          _buildTextField('Email Address', _emailController, Icons.email),
          const SizedBox(height: 20),
          _buildTextField(
              'Business Address', _addressController, Icons.location_on,
              maxLines: 2),
          const SizedBox(height: 20),
          _buildTextField('Website (Optional)', _websiteController, Icons.web),
          const SizedBox(height: 32),
          _buildRequirementsChecklist(),
        ],
      ),
    );
  }

  Widget _buildCategorySelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Categories',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose all that apply to your business',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategories.contains(category);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCategories.remove(category);
                    } else {
                      _selectedCategories.add(category);
                    }
                    _selectedSubcategories = _selectedCategories
                        .expand((c) => _getSubcategories(c))
                        .toSet()
                        .toList();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.primaryColor
                          : Colors.grey.shade300,
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        size: 32,
                        color:
                            isSelected ? Colors.white : AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textPrimaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (_selectedCategories.isNotEmpty) ...[
            const SizedBox(height: 32),
            const Text(
              'Subcategories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _selectedSubcategories.map((subcategory) {
                return FilterChip(
                  label: Text(subcategory),
                  selected: true,
                  onSelected: (selected) {
                    // Subcategories are auto-selected for now
                  },
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  labelStyle: const TextStyle(color: AppTheme.primaryColor),
                );
              }).toList(),
            ),
          ],
        ],
        ),
      );
    }




  Widget _buildDocumentsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Documents',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please upload required documents for verification',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          _buildDocumentUpload('Business License', 'Required for all vendors',
              Icons.description),
          const SizedBox(height: 16),
          _buildDocumentUpload('Tax Registration',
              'Required for business operations', Icons.receipt),
          const SizedBox(height: 16),
          _buildDocumentUpload('Insurance Certificate',
              'Required for liability coverage', Icons.security),
          const SizedBox(height: 16),
          _buildDocumentUpload('Halal Certificate', 'Required for food vendors',
              Icons.restaurant),
          const SizedBox(height: 16),
          _buildDocumentUpload('Professional Certifications',
              'Optional but recommended', Icons.verified),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload(String title, String description, IconData icon) {
    final isUploaded = _documents[title] != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUploaded ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUploaded ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isUploaded ? Colors.green : AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          if (isUploaded)
            const Icon(Icons.check_circle, color: Colors.green)
          else
            OutlinedButton(
              onPressed: () => _uploadDocument(title),
              child: const Text('Upload'),
            ),
          const SizedBox(height: 32),
          const Text(
            'Services',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add the services you offer (optional - can be added later)',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (_services.isEmpty) ...[
            Center(
              child: Column(
                children: [
                  const Text(
                    'No services added yet',
                    style: TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _showAddServiceDialog(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Your First Service'),
                  ),
                ],
              ),
            ),
          ] else ...[
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _services.length,
              itemBuilder: (context, index) {
                final service = _services[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text(service['name']),
                    subtitle: Text('RM ${service['price']} • ${service['category']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showAddServiceDialog(service: service, index: index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setState(() {
                              _services.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () => _showAddServiceDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Add Another Service'),
              ),
            ),
          ],
          ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final List<String> missingItems = _getMissingRequirements();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & Submit',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please review your information before submitting',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (missingItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Missing Required Information',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('Please complete the following to activate your profile:'),
                  const SizedBox(height: 8),
                  ...missingItems.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(item, style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
                ],
              ),
            ),
          const SizedBox(height: 16),
          _buildReviewSection('Business Information', [
            'Name: ${_onboardingData['business_name'] ?? '-'}',
            'Business Type: ${_onboardingData['business_type'] ?? '-'}',
            'Phone: ${_onboardingData['phone'] ?? '-'}',
            'Email: ${_onboardingData['email'] ?? '-'}',
          ]),
          const SizedBox(height: 20),
          _buildReviewSection('Owner Details', [
             'Name: ${_onboardingData['owner_details']?['full_name'] ?? '-'}',
             'Role: ${_onboardingData['owner_details']?['role'] ?? '-'}',
          ]),
          const SizedBox(height: 20),
          _buildReviewSection('Banking', [
             'Bank: ${_onboardingData['banking_details']?['bank_name'] ?? '-'}',
             'Account: ${_onboardingData['banking_details']?['account_number'] ?? '-'}',
          ]),
          const SizedBox(height: 20),
          _buildReviewSection('Operations', [
             'Days: ${(_onboardingData['operating_days'] as List?)?.join(', ') ?? '-'}',
             'Hours: ${_onboardingData['operating_hours_start']} - ${_onboardingData['operating_hours_end']}',
          ]),
          const SizedBox(height: 20),
          _buildReviewSection('Documents Uploaded', [
             if (_onboardingData['ic_upload_url'] != null) '• IC / MyKad',
             if (_onboardingData['ssm_cert_url'] != null) '• SSM Certificate',
             if (_onboardingData['bank_statement_url'] != null) '• Bank Statement',
          ]),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your profile will be activated immediately after submission. You can start using the platform right away.',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewSection(String title, List<String> items) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...items
              .map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• $item',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _previousStep,
                child: const Text('Previous'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoadingProfile ? null : () {
                _nextStep();
              },
              child: _isLoadingProfile 
                  ? const SizedBox(
                      height: 20, 
                      width: 20, 
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                    ) 
                  : Text(_currentStep == 7 ? 'Submit Application' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getMissingRequirements() {
    List<String> missing = [];
    if ((_onboardingData['business_name'] ?? '').isEmpty) missing.add('Business Name (Step 1)');
    if ((_onboardingData['description'] ?? '').isEmpty) missing.add('Business Description (Step 1)');
    if ((_onboardingData['phone'] ?? '').isEmpty) missing.add('Phone Number (Step 1)');
    if ((_onboardingData['email'] ?? '').isEmpty) missing.add('Email Address (Step 1)');
    
    if ((_onboardingData['categories'] ?? []).isEmpty) missing.add('Categories Selection (Step 4)');
    
    bool hasDoc = _onboardingData['ssm_cert_url'] != null || 
                  _onboardingData['ic_upload_url'] != null || 
                  _onboardingData['bank_statement_url'] != null;
    if (!hasDoc) missing.add('At least 1 Document (Step 7)');
    
    return missing;
  }

  Widget _buildRequirementsChecklist() {
    final requirements = [
      {
        'label': 'Business Name',
        'completed': _businessNameController.text.isNotEmpty
      },
      {
        'label': 'Description',
        'completed': _descriptionController.text.isNotEmpty
      },
      {
        'label': 'Phone Number',
        'completed': _phoneNumber != null && _phoneNumber!.number.isNotEmpty
      },
      {'label': 'Email Address', 'completed': _emailController.text.isNotEmpty},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Requirements to proceed:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...requirements.map((req) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      req['completed'] as bool
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color:
                          req['completed'] as bool ? Colors.green : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      req['label'] as String,
                      style: TextStyle(
                        color: req['completed'] as bool
                            ? Colors.green
                            : AppTheme.textSecondaryColor,
                        fontWeight: req['completed'] as bool
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberFieldSimple() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            prefixText: '+60 ',
            prefixIcon: const Icon(Icons.phone, color: AppTheme.primaryColor),
            hintText: '123456789',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          onChanged: (value) {
            // Create phone number object for consistency
            final cleanNumber = value.replaceAll(RegExp(r'[^\d]'), '');
            setState(() {
              _phoneNumber = PhoneNumber(
                countryISOCode: _initialCountryCode,
                countryCode: '',
                number: cleanNumber,
              );
            });
            _onFormChanged();
          },
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        IntlPhoneField(
          controller: _phoneController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
          initialCountryCode: _initialCountryCode,
          autovalidateMode: AutovalidateMode.disabled,
          onChanged: (phone) {
            if (mounted) {
              setState(() {
                _phoneNumber = phone;
              });
              _onFormChanged();
            }
          },
          validator: (phone) => null, // Disable built-in validation
        ),
      ],
    );
  }

  bool _isValidPhoneNumber(PhoneNumber phone) {
    // Make validation extremely lenient - accept any non-empty phone number
    return phone.number.isNotEmpty && phone.number.trim().isNotEmpty;
  }

  Widget _buildTextField(
      String label, TextEditingController controller, IconData icon,
      {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfilePictureUpload() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Profile Picture',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                _profilePicture != null ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _profilePicture != null
                  ? Colors.green.shade200
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: _profilePicture != null
                    ? (_profilePicture!['fileBytes'] != null
                        ? MemoryImage(
                                _profilePicture!['fileBytes'] as Uint8List)
                            as ImageProvider<Object>
                        : (_profilePicture!['filePath'] != null
                            ? FileImage(File(
                                    _profilePicture!['filePath'] as String))
                                as ImageProvider<Object>
                            : null))
                    : null,
                child: _profilePicture == null
                    ? Icon(Icons.camera_alt,
                        color: AppTheme.primaryColor, size: 30)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _profilePicture != null
                          ? 'Profile picture selected'
                          : 'Upload Profile Picture',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      _profilePicture != null
                          ? _profilePicture!['fileName']
                          : 'Optional: Add a profile picture to personalize your business',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (_profilePicture != null)
                const Icon(Icons.check_circle, color: Colors.green)
              else
                OutlinedButton(
                  onPressed: _uploadProfilePicture,
                  child: const Text('Upload'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  List<String> _getSubcategories(String category) {
    switch (category) {
      case 'Catering':
        return [
          'Wedding Catering',
          'Corporate Events',
          'Private Parties',
          'Buffet Service'
        ];
      case 'Photography':
        return [
          'Wedding Photography',
          'Event Coverage',
          'Portrait Sessions',
          'Video Services'
        ];
      case 'Venues':
        return [
          'Wedding Venues',
          'Corporate Events',
          'Private Functions',
          'Outdoor Venues'
        ];
      case 'Fashion':
        return [
          'Wedding Dresses',
          'Suits & Tuxedos',
          'Traditional Attire',
          'Accessories'
        ];
      case 'Decoration':
        return [
          'Wedding Decor',
          'Event Styling',
          'Floral Arrangements',
          'Lighting'
        ];
      default:
        return ['General Services'];
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Catering':
        return Icons.restaurant;
      case 'Photography':
        return Icons.camera_alt;
      case 'Venues':
        return Icons.location_city;
      case 'Fashion':
        return Icons.checkroom;
      case 'Decoration':
        return Icons.celebration;
      case 'Entertainment':
        return Icons.music_note;
      case 'Transportation':
        return Icons.directions_car;
      case 'Beauty & Makeup':
        return Icons.face;
      case 'Music & DJ':
        return Icons.headphones;
      default:
        return Icons.business;
    }
  }

  void _showAddServiceDialog({Map<String, dynamic>? service, int? index}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismissal
      builder: (BuildContext dialogContext) => AddServiceDialog(
        selectedCategories: _selectedCategories,
        onServiceAdded: (newService) {
          // Convert VendorService to the simple map format used in onboarding
          final serviceMap = {
            'name': newService.name,
            'price': newService.basePrice,
            'description': newService.description,
            'category': newService.category.name,
            'type': newService.type.name,
            'priceType': newService.options['priceType'],
            'durationHours': newService.options['durationHours'],
            'maxGuests': newService.options['maxGuests'],
            'features': newService.options['features'],
            'isFeatured': newService.options['isFeatured'],
            'active': newService.status == ServiceStatus.active,
          };

          if (mounted) { // Check if widget is still mounted
            setState(() {
              if (index != null) {
                _services[index] = serviceMap;
              } else {
                _services.add(serviceMap);
              }
            });
          }

          Navigator.of(dialogContext).pop(); // Use dialog context
        },
      ),
    );
  }

  void _uploadDocument(String documentType) async {
    try {
      // Pick a file using file_picker
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.single;

        // Handle both web and mobile platforms
        String? filePath;
        Uint8List? fileBytes;
        int fileSize;

        if (file.bytes != null) {
          // Web: bytes are available instead of path
          fileBytes = file.bytes!;
          fileSize = fileBytes.length;
        } else if (file.path != null) {
          // Mobile/Desktop: path is available
          filePath = file.path!;
          final fileObj = File(filePath);
          if (!await fileObj.exists()) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content:
                    Text('Selected file no longer exists. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
          fileSize = await fileObj.length();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to access file data. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Validate file size (max 10MB)
        if (fileSize > 10 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('File size must be less than 10MB'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Store file data locally for now (will be uploaded during submission)
        setState(() {
          _documents[documentType] = {
            'filePath': filePath,
            'fileBytes': fileBytes,
            'fileName': file.name,
            'fileSize': fileSize,
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$documentType selected successfully')),
        );
      } else {
        // User cancelled file picker
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No file selected. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting $documentType: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _uploadProfilePicture() async {
    try {
      // Pick image
      final XFile? picked = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return; // user cancelled

      final File file = File(picked.path);
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      final userId = user.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = p.basename(picked.path);
      final storagePath = '$userId/$timestamp\_$filename';

      // Upload to storage
      final bucket = 'profile-picture';
      final bytes = await file.readAsBytes();
      await supabase.storage.from(bucket).uploadBinary(storagePath, bytes,
          fileOptions: FileOptions(upsert: true));

      // Get public URL (since bucket is public)
      final publicUrl = supabase.storage.from(bucket).getPublicUrl(storagePath);

      // Store locally for submission
      setState(() {
        _profilePicture = {
          'filePath': picked.path,
          'fileBytes': bytes,
          'fileName': filename,
          'publicUrl': publicUrl,
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture selected successfully')),
      );
    } catch (e, st) {
      debugPrint('Upload error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    }
  }

  String _getDocumentTypeKey(String displayName) {
    switch (displayName) {
      case 'Business License':
        return 'business_license';
      case 'Tax Registration':
        return 'tax_registration';
      case 'Insurance Certificate':
        return 'insurance_certificate';
      case 'Halal Certificate':
        return 'halal_certificate';
      case 'Professional Certifications':
        return 'professional_certifications';
      default:
        return displayName.toLowerCase().replaceAll(' ', '_');
    }
  }

  Future<void> _nextStep() async {
    await _saveProgress();

    if (_currentStep < 7) {
      if (mounted) {
        setState(() {
          _currentStep++;
        });
        _pageController.animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      await _submitApplicationSafe();
    }
  }

  Future<void> _saveProgress() async {
    final profileProvider =
        Provider.of<VendorProfileProvider>(context, listen: false);

    try {
      // Save current state of onboarding data
      final success = await profileProvider.saveProfessionalOnboardingData(_onboardingData);
      
      if (!success) {
         if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to save progress: ${profileProvider.error}'), backgroundColor: Colors.red),
            );
         }
      }
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skipOnboarding() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skip Onboarding?'),
        content: const Text(
            'You can complete your profile later from your dashboard. '
            'Some features may be limited until your profile is complete.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (context) => const VendorDashboardScreen()),
              );
            },
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveServicesToDatabase(String vendorProfileId) async {
    print('DEBUG: ===== STARTING SERVICE SUBMISSION FOR REVIEW =====');
    print('DEBUG: Vendor Profile ID: $vendorProfileId');
    print('DEBUG: Number of services to submit: ${_services.length}');

    try {
      for (int i = 0; i < _services.length; i++) {
        final service = _services[i];
        print('DEBUG: Submitting service ${i + 1}/${_services.length}: ${service['name']}');

        final serviceData = {
          'vendor_id': vendorProfileId,
          'name': service['name'],
          'description': service['description'],
          'category': service['category'],
          'base_price': service['price'],
          'price_type': service['priceType'],
          'duration_hours': service['durationHours'],
          'max_guests': service['maxGuests'],
          'features': service['features'],
          'service_type': service['type'],
          'is_featured': service['isFeatured'],
          'active': false, // Pending services are inactive until approved by admin
          'approval_status': 'pending', // Services need admin approval - SUBMITTED FOR REVIEW
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        print('DEBUG: Service data for ${service['name']}: $serviceData');
        print('DEBUG: Inserting service into vendor_services table...');

        final result = await supabase.from('vendor_services').insert(serviceData);
        print('DEBUG: Service ${service['name']} submitted for review successfully');
        print('DEBUG: Service approval_status set to: pending (awaiting admin review)');
      }

      print('DEBUG: ===== ALL SERVICES SUBMITTED FOR REVIEW =====');
      print('DEBUG: Services are now pending admin approval');

    } catch (e) {
      print('DEBUG: ===== SERVICE SUBMISSION FAILED =====');
      print('DEBUG: Error saving services to database: $e');
      print('DEBUG: Services will need to be submitted again later');
      // Don't fail the entire submission if services save fails
      // Services can be added later from the dashboard
    }
  }

  Future<void> _submitApplicationSafe() async {
    print('🔒 SUBMIT APPLICATION: Starting professional submission process');
    FocusManager.instance.primaryFocus?.unfocus();

    if (!mounted) return;

    try {
      final profileProvider = Provider.of<VendorProfileProvider>(context, listen: false);

      // Save all data
      final saveSuccess = await profileProvider.saveProfessionalOnboardingData(_onboardingData);
      
      if (!saveSuccess) {
        throw Exception(profileProvider.error ?? 'Failed to save profile');
      }

      // Submit for review
      final submitSuccess = await profileProvider.submitForReview();
      if (!submitSuccess) {
         throw Exception(profileProvider.error ?? 'Failed to submit for review');
      }

      // Success
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Application Submitted!'),
            content: const Text(
              'Your vendor profile has been submitted for review. '
              'You will be notified once your application is approved.\n\n'
              'In the meantime, you can access your dashboard to update your profile.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                        builder: (context) => const VendorDashboardScreen()),
                  );
                },
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('Submission Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
