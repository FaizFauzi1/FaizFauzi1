import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class VendorAddressManagementScreen extends StatefulWidget {
  const VendorAddressManagementScreen({super.key});

  @override
  State<VendorAddressManagementScreen> createState() =>
      _VendorAddressManagementScreenState();
}

class _VendorAddressManagementScreenState
    extends State<VendorAddressManagementScreen> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  bool _isLoadingLocation = false;

  final _formKey = GlobalKey<FormState>();
  final _businessAddressController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();
  final _fullAddressController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadSavedAddress();
  }

  Future<void> _loadSavedAddress() async {
    final profile = Provider.of<VendorProfileProvider>(context, listen: false).vendorProfile;
    if (profile != null) {
      _businessAddressController.text = (profile['business_address'] ?? '').toString();
      _addressLine1Controller.text = (profile['address_line1'] ?? '').toString();
      _addressLine2Controller.text = (profile['address_line2'] ?? '').toString();
      _cityController.text = (profile['city'] ?? '').toString();
      _stateController.text = (profile['state'] ?? '').toString();
      _postalCodeController.text = (profile['postal_code'] ?? '').toString();
      _countryController.text = (profile['country'] ?? 'Malaysia').toString();
      _fullAddressController.text = (profile['full_address'] ?? profile['address'] ?? '').toString();
      final lat = (profile['latitude'] as num?)?.toDouble();
      final lng = (profile['longitude'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        _updateMarker(LatLng(lat, lng));
        return;
      }
    }
    _selectedLocation = const LatLng(3.1390, 101.6869); // Kuala Lumpur default
    _updateMarker(_selectedLocation!);
  }

  void _updateMarker(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId('vendor_location'),
          position: location,
          infoWindow: const InfoWindow(
            title: 'Vendor Location',
            snippet: 'Tap to update',
          ),
        ),
      };
      _latitudeController.text = location.latitude.toStringAsFixed(7);
      _longitudeController.text = location.longitude.toStringAsFixed(7);
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final location = LatLng(position.latitude, position.longitude);
      _updateMarker(location);
      await _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to get location: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill all required fields');
      return;
    }

    if (_selectedLocation == null) {
      _showErrorSnackBar('Please select a location on the map');
      return;
    }

    try {
      _constructFullAddress();
      final saved = await Provider.of<VendorProfileProvider>(context, listen: false).updateVendorAddress(
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _countryController.text.trim(),
        fullAddress: _fullAddressController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        businessAddress: _businessAddressController.text.trim(),
      );
      if (!mounted) return;
      if (saved) {
        _showSuccessSnackBar('Address saved successfully!');
      } else {
        final error = Provider.of<VendorProfileProvider>(context, listen: false).error;
        _showErrorSnackBar(error ?? 'Failed to save address');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save address: $e');
    }
  }

  void _constructFullAddress() {
    final parts = [
      _addressLine1Controller.text,
      _addressLine2Controller.text,
      _cityController.text,
      _stateController.text,
      _postalCodeController.text,
      _countryController.text,
    ].where((part) => part.isNotEmpty).toList();

    _fullAddressController.text = parts.join(', ');
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _businessAddressController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _fullAddressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Business Address',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Map Section
              _buildMapSection(),
              const SizedBox(height: 24),

              // Location Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                  icon: _isLoadingLocation
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.my_location),
                  label: const Text('Use Current Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Business Address (Legacy field - kept for compatibility)
              _buildTextField(
                controller: _businessAddressController,
                label: 'Business Address (Legacy)',
                hint: 'Full address (optional)',
                icon: Icons.location_on,
              ),
              const SizedBox(height: 16),

              // Address Form Section
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Structured Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),

              // Address Line 1
              _buildTextField(
                controller: _addressLine1Controller,
                label: 'Street Address *',
                hint: 'House number and street name',
                icon: Icons.home,
                isRequired: true,
                onChanged: (_) => _constructFullAddress(),
              ),
              const SizedBox(height: 16),

              // Address Line 2
              _buildTextField(
                controller: _addressLine2Controller,
                label: 'Apartment/Unit (Optional)',
                hint: 'Apt, suite, unit, building, floor, etc.',
                icon: Icons.apartment,
                onChanged: (_) => _constructFullAddress(),
              ),
              const SizedBox(height: 16),

              // City and State Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City *',
                      hint: 'Kuala Lumpur',
                      icon: Icons.location_city,
                      isRequired: true,
                      onChanged: (_) => _constructFullAddress(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State *',
                      hint: 'Selangor',
                      icon: Icons.public,
                      isRequired: true,
                      onChanged: (_) => _constructFullAddress(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Postal Code and Country Row
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _postalCodeController,
                      label: 'Postal Code *',
                      hint: '50000',
                      icon: Icons.mail,
                      isRequired: true,
                      onChanged: (_) => _constructFullAddress(),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _countryController,
                      label: 'Country *',
                      hint: 'Malaysia',
                      icon: Icons.flag,
                      isRequired: true,
                      onChanged: (_) => _constructFullAddress(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Full Address (Auto-generated)
              _buildTextField(
                controller: _fullAddressController,
                label: 'Full Address (Auto-generated)',
                hint: 'Full address will appear here',
                icon: Icons.description,
                readOnly: true,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Coordinates Section
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Map Coordinates',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _latitudeController,
                      label: 'Latitude',
                      hint: '3.1390',
                      icon: Icons.my_location,
                      readOnly: true,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _longitudeController,
                      label: 'Longitude',
                      hint: '101.6869',
                      icon: Icons.location_on,
                      readOnly: true,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Address',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapSection() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _selectedLocation == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : GoogleMap(
                onMapCreated: (controller) => _mapController = controller,
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation ?? const LatLng(3.1390, 101.6869),
                  zoom: 15,
                ),
                markers: _markers,
                onTap: (LatLng location) {
                  _updateMarker(location);
                },
                myLocationButtonEnabled: false,
                myLocationEnabled: false,
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isRequired = false,
    bool readOnly = false,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return '$label is required';
              }
              return null;
            }
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: AppTheme.primaryColor.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(
            color: AppTheme.primaryColor,
            width: 2,
          ),
        ),
        filled: readOnly,
        fillColor: readOnly ? AppTheme.backgroundColor : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
