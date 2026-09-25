import 'package:flutter/material.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/shared/widgets/custom_text_field.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:provider/provider.dart';

class AdminCreateVendorScreen extends StatefulWidget {
  const AdminCreateVendorScreen({super.key});

  @override
  State<AdminCreateVendorScreen> createState() => _AdminCreateVendorScreenState();
}

class _AdminCreateVendorScreenState extends State<AdminCreateVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  String? _generatedCode;

  final List<String> _availableCategories = [
    'Venue', 'Catering', 'Photography', 'Videography', 'Entertainment', 
    'Decoration', 'Makeup', 'Transportation', 'Gift', 'Attire', 'Planning', 'Other'
  ];
  final List<String> _selectedCategories = [];

  final List<String> _malaysiaStates = [
    'Johor', 'Kedah', 'Kelantan', 'Melaka', 'Negeri Sembilan', 
    'Pahang', 'Penang', 'Perak', 'Perlis', 'Sabah', 
    'Sarawak', 'Selangor', 'Terengganu', 'Kuala Lumpur', 
    'Labuan', 'Putrajaya'
  ];
  final List<String> _selectedServiceAreas = [];
  final List<String> _selectedCities = [];

  final Map<String, List<String>> _stateCities = {
    'Selangor': ['Petaling Jaya', 'Shah Alam', 'Subang Jaya', 'Klang', 'Ampang', 'Cheras', 'Selayang', 'Rawang', 'Gombak', 'Kajang', 'Sepang', 'Cyberjaya', 'Puchong'],
    'Kuala Lumpur': ['Bukit Bintang', 'Wangsa Maju', 'Cheras', 'Setiawangsa', 'Titiwangsa', 'Bangsar', 'Seputeh', 'Lembah Pantai', 'Segambut', 'Batu', 'Mont Kiara', 'Kepong'],
    'Penang': ['George Town', 'Bayan Lepas', 'Butterworth', 'Bukit Mertajam', 'Nibong Tebal', 'Gelugor', 'Ayer Itam'],
    'Johor': ['Johor Bahru', 'Batu Pahat', 'Muar', 'Kluang', 'Skudai', 'Kulai', 'Pasir Gudang'],
    'Perak': ['Ipoh', 'Taiping', 'Sitiawan', 'Teluk Intan', 'Batu Gajah'],
    'Kedah': ['Alor Setar', 'Sungei Petani', 'Kulim', 'Langkawi'],
    'Melaka': ['Melaka City', 'Ayer Keroh', 'Alor Gajah', 'Jasin'],
    'Negeri Sembilan': ['Seremban', 'Port Dickson', 'Nilai'],
    'Pahang': ['Kuantan', 'Temerloh', 'Bentong', 'Raub'],
    'Kelantan': ['Kota Bharu', 'Tanah Merah', 'Pasir Mas'],
    'Terengganu': ['Kuala Terengganu', 'Dungun', 'Kemaman'],
    'Sabah': ['Kota Kinabalu', 'Sandakan', 'Tawau'],
    'Sarawak': ['Kuching', 'Miri', 'Bintulu', 'Sibu'],
    'Perlis': ['Kangar'],
    'Labuan': ['Labuan'],
    'Putrajaya': ['Putrajaya'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one category')),
      );
      return;
    }
    if (_selectedServiceAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service area')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final code = await context.read<AdminProvider>().createUnclaimedVendor(
        name: _nameController.text,
        categories: _selectedCategories,
        description: _descriptionController.text,
        address: _locationController.text,
        serviceAreas: _selectedServiceAreas,
        serviceCities: _selectedCities,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        phone: _phoneController.text,
      );

      setState(() {
        _generatedCode = code;
        _isLoading = false;
      });

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Vendor Profile Created'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Share this claim code with the vendor:'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.primaryColor),
                  ),
                  child: Text(
                    code,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('ERROR CREATING VENDOR: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Vendor Profile'),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Enter vendor details to create an unclaimed profile.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  CustomTextField(
                    controller: _nameController,
                    label: 'Business Name',
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Business Categories',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 0,
                    children: _availableCategories.map((cat) {
                      final isSelected = _selectedCategories.contains(cat);
                      return FilterChip(
                        label: Text(cat, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(cat);
                            } else {
                              _selectedCategories.remove(cat);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _descriptionController,
                    label: 'Business Description',
                    maxLines: 3,
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _locationController,
                    label: 'Main Business Address',
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Service Coverage Areas (States)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 0,
                    children: _malaysiaStates.map((state) {
                      final isSelected = _selectedServiceAreas.contains(state);
                      return FilterChip(
                        label: Text(state, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.black)),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: Colors.white,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedServiceAreas.add(state);
                            } else {
                              _selectedServiceAreas.remove(state);
                              // Remove all cities belonging to this state
                              final citiesToRemove = _stateCities[state] ?? [];
                              _selectedCities.removeWhere((city) => citiesToRemove.contains(city));
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  if (_selectedServiceAreas.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Select Cities (Granular Coverage)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ..._selectedServiceAreas.map((state) {
                      final cities = _stateCities[state] ?? [];
                      if (cities.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(state, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 0,
                            children: [
                              // Add "All Cities" option
                              FilterChip(
                                label: const Text('All Cities', style: TextStyle(fontSize: 11)),
                                selected: cities.every((c) => _selectedCities.contains(c)),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      for (var c in cities) {
                                        if (!_selectedCities.contains(c)) _selectedCities.add(c);
                                      }
                                    } else {
                                      for (var c in cities) {
                                        _selectedCities.remove(c);
                                      }
                                    }
                                  });
                                },
                              ),
                              ...cities.map((city) {
                                final isCitySelected = _selectedCities.contains(city);
                                return FilterChip(
                                  label: Text(city, style: TextStyle(fontSize: 11, color: isCitySelected ? Colors.white : Colors.black)),
                                  selected: isCitySelected,
                                  selectedColor: AppTheme.primaryColor.withOpacity(0.8),
                                  checkmarkColor: Colors.white,
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedCities.add(city);
                                      } else {
                                        _selectedCities.remove(city);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                          const Divider(),
                        ],
                      );
                    }).toList(),
                  ],
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Contact Email (Optional)',
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    label: 'Contact Phone',
                    keyboardType: TextInputType.phone,
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Create Profile & Generate Code',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
