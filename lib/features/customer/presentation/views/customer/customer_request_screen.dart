import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/support/data/models/customer_request.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/features/support/data/providers/request_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:uuid/uuid.dart';
import 'package:eventease/features/customer/presentation/views/customer/customer_request_management_screen.dart';

class CustomerRequestScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  final CustomerRequest? existingRequest; // Optional for editing

  const CustomerRequestScreen({
    super.key,
    required this.customerId,
    required this.customerName,
    this.existingRequest,
  });

  @override
  State<CustomerRequestScreen> createState() => _CustomerRequestScreenState();
}

class _CustomerRequestScreenState extends State<CustomerRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  EventCategory? _selectedCategory;
  String _eventType = '';
  DateTime? _eventDate;
  double? _budget;
  String _description = '';
  String _location = '';
  int? _guestCount;
  String _contactPhone = '';
  String _contactEmail = '';
  bool _isNegotiable = true;

  @override
  void initState() {
    super.initState();
    if (widget.existingRequest != null) {
      _selectedCategory = widget.existingRequest!.eventCategory;
      _eventType = widget.existingRequest!.eventType;
      _eventDate = widget.existingRequest!.eventDate;
      _budget = widget.existingRequest!.budget;
      _description = widget.existingRequest!.description;
      _location = widget.existingRequest!.location;
      _guestCount = widget.existingRequest!.guestCount;
      _contactPhone = widget.existingRequest!.contactPhone ?? '';
      _contactEmail = widget.existingRequest!.contactEmail ?? '';
    }
  }

  Future<void> _selectEventDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              onSurface: AppTheme.textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _eventDate) {
      setState(() {
        _eventDate = picked;
      });
    }
  }

  void _submitRequest() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedCategory == null || _eventDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select event category and date'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        return;
      }
      _formKey.currentState?.save();

      final requestProvider = Provider.of<RequestProvider>(context, listen: false);

      if (widget.existingRequest != null) {
        final updatedRequest = widget.existingRequest!.copyWith(
          eventCategory: _selectedCategory!,
          eventType: _eventType,
          eventDate: _eventDate!,
          budget: _budget ?? 0,
          description: _description,
          location: _location,
          guestCount: _guestCount ?? 0,
          contactPhone: _contactPhone,
          contactEmail: _contactEmail,
        );

        requestProvider.updateRequest(widget.existingRequest!.id, updatedRequest);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request updated successfully')),
        );

        Navigator.of(context).pop();
      } else {
        final newRequest = CustomerRequest(
          id: const Uuid().v4(),
          customerId: widget.customerId,
          customerName: widget.customerName,
          eventCategory: _selectedCategory!,
          eventType: _eventType,
          eventDate: _eventDate!,
          budget: _budget ?? 0,
          description: _description,
          location: _location,
          guestCount: _guestCount ?? 0,
          contactPhone: _contactPhone,
          contactEmail: _contactEmail,
          status: RequestStatus.pending,
          createdAt: DateTime.now(),
          offers: [],
        );

        requestProvider.addRequest(newRequest);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request submitted successfully! Vendors will notify you soon.'),
            backgroundColor: AppTheme.successColor,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => CustomerRequestManagementScreen(
              customerId: widget.customerId,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.existingRequest != null ? 'Edit Quote Request' : 'Get Custom Quotes',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('Event Details', Icons.event_note),
                    _buildCard([
                      _buildDropdownField(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Specific Event Type',
                        hint: 'e.g., Garden Wedding, Corporate Gala',
                        icon: Icons.celebration,
                        onSaved: (v) => _eventType = v!,
                        initialValue: _eventType,
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Requirements', Icons.list_alt),
                    _buildCard([
                      _buildTextField(
                        label: 'Estimated Guest Count',
                        hint: 'Number of people',
                        icon: Icons.people,
                        keyboardType: TextInputType.number,
                        onSaved: (v) => _guestCount = int.tryParse(v!),
                        initialValue: _guestCount?.toString(),
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Event Location',
                        hint: 'City or specific venue',
                        icon: Icons.location_on,
                        onSaved: (v) => _location = v!,
                        initialValue: _location,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'What are you looking for?',
                        hint: 'Describe your requirements in detail...',
                        icon: Icons.description,
                        maxLines: 4,
                        onSaved: (v) => _description = v!,
                        initialValue: _description,
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSectionTitle('Budget & Contact', Icons.payments),
                    _buildCard([
                      _buildTextField(
                        label: 'Your Budget (RM)',
                        hint: 'Enter your total budget',
                        icon: Icons.account_balance_wallet,
                        keyboardType: TextInputType.number,
                        onSaved: (v) => _budget = double.tryParse(v!),
                        initialValue: _budget?.toString(),
                      ),
                      CheckboxListTile(
                        title: const Text('Budget is negotiable', style: TextStyle(fontSize: 14)),
                        value: _isNegotiable,
                        onChanged: (v) => setState(() => _isNegotiable = v!),
                        activeColor: AppTheme.primaryColor,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const Divider(),
                      _buildTextField(
                        label: 'Contact Phone',
                        hint: '+60 12-345 6789',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        onSaved: (v) => _contactPhone = v!,
                        initialValue: _contactPhone,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Contact Email',
                        hint: 'yourname@example.com',
                        icon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        onSaved: (v) => _contactEmail = v!,
                        initialValue: _contactEmail,
                      ),
                    ]),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(widget.existingRequest != null ? Icons.save : Icons.send),
                          const SizedBox(width: 8),
                          Text(
                            widget.existingRequest != null ? 'Update Request' : 'Get Custom Quotes',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required void Function(String?) onSaved,
    String? initialValue,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      initialValue: initialValue,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.textSecondaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      onSaved: onSaved,
      validator: (value) => (value == null || value.isEmpty) ? 'Required field' : null,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<EventCategory>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Event Category',
        prefixIcon: const Icon(Icons.category, color: AppTheme.textSecondaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: EventCategory.values
          .map((category) => DropdownMenuItem(
                value: category,
                child: Text(category.displayName),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategory = value;
        });
      },
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: () => _selectEventDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: AppTheme.textSecondaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Event Date',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _eventDate == null
                        ? 'Select Date'
                        : _eventDate!.toLocal().toString().split(' ')[0],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: _eventDate == null ? FontWeight.normal : FontWeight.bold,
                      color: _eventDate == null ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textSecondaryColor),
          ],
        ),
      ),
    );
  }
}
