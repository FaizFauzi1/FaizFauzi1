import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:intl/intl.dart';

class OwnerDetailsStep extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onChanged;

  const OwnerDetailsStep({
    super.key,
    required this.data,
    required this.onChanged,
  });

  @override
  State<OwnerDetailsStep> createState() => _OwnerDetailsStepState();
}

class _OwnerDetailsStepState extends State<OwnerDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _icNumberController;
  late TextEditingController _phoneController;
  late TextEditingController _whatsappController;
  late TextEditingController _emailController;
  late TextEditingController _emergencyContactController;
  
  String? _nationality;
  String? _role;
  DateTime? _dob;

  final List<String> _roles = ['Owner', 'Manager', 'Administrator', 'Director'];

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.data['full_name']);
    _icNumberController = TextEditingController(text: widget.data['ic_number']);
    _phoneController = TextEditingController(text: widget.data['phone_number']);
    _whatsappController = TextEditingController(text: widget.data['whatsapp_number']);
    _emailController = TextEditingController(text: widget.data['email']);
    _emergencyContactController = TextEditingController(text: widget.data['emergency_contact']);
    
    _nationality = widget.data['nationality'];
    _role = widget.data['role'];
    if (widget.data['date_of_birth'] != null) {
      _dob = DateTime.tryParse(widget.data['date_of_birth']);
    }

    _setupListeners();
  }

  void _setupListeners() {
    void listener() {
      _updateParent();
    }
    _fullNameController.addListener(listener);
    _icNumberController.addListener(listener);
    _phoneController.addListener(listener);
    _whatsappController.addListener(listener);
    _emailController.addListener(listener);
    _emergencyContactController.addListener(listener);
  }

  void _updateParent() {
    widget.onChanged({
      'full_name': _fullNameController.text,
      'ic_number': _icNumberController.text,
      'date_of_birth': _dob?.toIso8601String(),
      'nationality': _nationality,
      'phone_number': _phoneController.text,
      'whatsapp_number': _whatsappController.text,
      'email': _emailController.text,
      'emergency_contact': _emergencyContactController.text,
      'role': _role,
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _icNumberController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Owner / Person In Charge',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: const [
                  Icon(Icons.lock_outline, size: 20, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This information is private and used for verification only.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader('Personal Details'),
            _buildDropdownField('Role', _role, _roles, (val) {
              setState(() => _role = val);
              _updateParent();
            }),
            _buildTextField('Full Name (as per IC)', _fullNameController, required: true),
            _buildTextField('IC / Passport Number', _icNumberController, required: true),
            Row(
              children: [
                Expanded(child: _buildDatePicker('Date of Birth', _dob)),
                const SizedBox(width: 16),
                Expanded(child: _buildTextField('Nationality', TextEditingController(text: _nationality)..addListener(() {
                  // Hacky but works for stateless controller
                }), onChanged: (val) {
                   _nationality = val;
                   _updateParent();
                })),
              ],
            ),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Contact Information'),
            _buildTextField('Mobile Phone', _phoneController, required: true, isPhone: true),
            _buildTextField('WhatsApp Number', _whatsappController, isPhone: true),
            _buildTextField('Direct Email', _emailController, required: true, isEmail: true),
            _buildTextField('Emergency Contact (Name & Phone)', _emergencyContactController),
          ],
        ),
      ),
    );
  }
  
  // Helper methods reused (could be refactored to shared widget)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, 
    {bool required = false, bool isPhone = false, bool isEmail = false, Function(String)? onChanged}
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label + (required ? ' *' : ''),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: required ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildDatePicker(String label, DateTime? date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime(1990),
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            setState(() => _dob = picked);
            _updateParent();
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          child: Text(
            date != null ? DateFormat('dd/MM/yyyy').format(date) : 'Select Date',
            style: TextStyle(color: date != null ? AppTheme.textPrimaryColor : Colors.grey),
          ),
        ),
      ),
    );
  }
}
