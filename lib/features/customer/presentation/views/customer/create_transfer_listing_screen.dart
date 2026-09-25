import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/customer/data/models/transfer_listing.dart';
import 'package:eventease/features/customer/data/providers/marketplace_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateTransferListingScreen extends StatefulWidget {
  const CreateTransferListingScreen({super.key});

  @override
  State<CreateTransferListingScreen> createState() => _CreateTransferListingScreenState();
}

class _CreateTransferListingScreenState extends State<CreateTransferListingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // ⚡ TESTING: set to true to bypass Supabase and use local-only mode
  static const bool _testMode = true;

  bool _isExternal = true; // Default to external so no booking is required
  Booking? _selectedBooking;
  
  String _category = 'Wedding venue';
  final _vendorNameController = TextEditingController();
  DateTime _eventDate = DateTime.now().add(const Duration(days: 90));
  final _originalPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reasonController = TextEditingController();
  final _proofUrlController = TextEditingController(); // Simulated/URL upload proof

  final List<String> _categories = [
    'Wedding venue',
    'Bridal package',
    'Catering package',
    'Photography/videography',
    'Makeup artist',
    'Decoration package',
    'Entertainment services',
    'Wedding planner services'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        Provider.of<BookingProvider>(context, listen: false).loadCustomerBookings(user.id);
      }
    });
  }

  @override
  void dispose() {
    _vendorNameController.dispose();
    _originalPriceController.dispose();
    _sellingPriceController.dispose();
    _descriptionController.dispose();
    _reasonController.dispose();
    _proofUrlController.dispose();
    super.dispose();
  }

  void _onBookingSelected(Booking? booking) {
    if (booking == null) return;
    setState(() {
      _selectedBooking = booking;
      _category = _mapBookingToCategory(booking.packageName);
      _vendorNameController.text = booking.vendorName.isNotEmpty ? booking.vendorName : 'EventEase Vendor';
      _eventDate = booking.bookingDate;
      _originalPriceController.text = booking.amount.toString();
      _descriptionController.text = booking.notes;
    });
  }

  String _mapBookingToCategory(String packageName) {
    packageName = packageName.toLowerCase();
    if (packageName.contains('venue') || packageName.contains('hall')) return 'Wedding venue';
    if (packageName.contains('cater') || packageName.contains('food')) return 'Catering package';
    if (packageName.contains('photo') || packageName.contains('video')) return 'Photography/videography';
    if (packageName.contains('makeup') || packageName.contains('artist')) return 'Makeup artist';
    if (packageName.contains('decor') || packageName.contains('arch')) return 'Decoration package';
    if (packageName.contains('music') || packageName.contains('band') || packageName.contains('sing')) return 'Entertainment services';
    if (packageName.contains('plan') || packageName.contains('coordin')) return 'Wedding planner services';
    return 'Bridal package';
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // ⚡ TESTING bypass: require vendor name for external
    if (_isExternal && _vendorNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the vendor / service name')),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    final userId = user?.id ?? 'test-user-${DateTime.now().millisecondsSinceEpoch}';

    final listing = TransferListing(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      customerId: userId,
      vendorId: _isExternal ? null : _selectedBooking?.vendorId,
      bookingId: _isExternal ? null : _selectedBooking?.id,
      category: _category,
      vendorName: _isExternal
          ? _vendorNameController.text
          : (_selectedBooking?.vendorName ?? _vendorNameController.text),
      eventDate: _eventDate,
      originalBookingPrice: double.tryParse(_originalPriceController.text) ?? 0,
      sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0,
      packageDescription: _descriptionController.text,
      images: ['https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=800&q=80'],
      reason: _reasonController.text,
      proofUrl: _isExternal ? _proofUrlController.text : null,
      transferApprovalStatus: _isExternal ? TransferApprovalStatus.pending : TransferApprovalStatus.approved,
      listingStatus: _isExternal ? TransferListingStatus.active : TransferListingStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final provider = Provider.of<MarketplaceProvider>(context, listen: false);

    if (_testMode) {
      // ⚡ TEST MODE: skip Supabase, add locally immediately
      provider.addLocalTransferListing(listing);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ [Test Mode] Listing added locally!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
      return;
    }

    final success = await provider.createTransferListing(listing);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isExternal
              ? 'Listing submitted! Awaiting external vendor verification.'
              : 'Listing posted successfully!'),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookings = Provider.of<BookingProvider>(context).customerBookings
        .where((b) => b.status == BookingStatus.confirmed)
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Transfer Listing'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle internal vs external
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('My EventEase Booking')),
                      selected: !_isExternal,
                      onSelected: (val) {
                        setState(() {
                          _isExternal = false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('External Vendor Booking')),
                      selected: _isExternal,
                      onSelected: (val) {
                        setState(() {
                          _isExternal = true;
                          _selectedBooking = null;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              if (!_isExternal) ...[
                const Text('Select Confirmed Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<Booking>(
                  value: _selectedBooking,
                  hint: const Text('Choose booking to transfer'),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: bookings.map((b) {
                    return DropdownMenuItem(
                      value: b,
                      child: Text('${b.packageName} (${DateFormat('dd MMM').format(b.bookingDate)})'),
                    );
                  }).toList(),
                  onChanged: _onBookingSelected,
                  validator: (val) => _isExternal ? null : (val == null ? 'Please select a booking' : null),
                ),
                const SizedBox(height: 16),
              ],

              // Service Category
              const Text('Service Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) => setState(() => _category = val!),
              ),
              const SizedBox(height: 16),

              // Vendor Name (Only editable for external or if custom input needed)
              const Text('Vendor Name', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _vendorNameController,
                enabled: _isExternal,
                decoration: InputDecoration(
                  hintText: 'e.g. Grand Plaza Ballroom',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter vendor name' : null,
              ),
              const SizedBox(height: 16),

              // Date Picker
              const Text('Event Date', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _isExternal ? () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _eventDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (picked != null) {
                    setState(() => _eventDate = picked);
                  }
                } : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd MMMM yyyy').format(_eventDate)),
                      const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Original Price & Selling Price
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Original Price (RM)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _originalPriceController,
                          enabled: _isExternal,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'RM 12,000',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Selling Price (RM)', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _sellingPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'RM 9,500',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Package Details / Description
              const Text('Package Description', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'What is included in this package? Event schedule, pax amount, decor styles...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter package description' : null,
              ),
              const SizedBox(height: 16),

              // Reason (Optional)
              const Text('Reason for Transfer (Optional)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  hintText: 'Why are you letting this package go?',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),

              // Proof of Booking (For External Vendor Resale)
              if (_isExternal) ...[
                const Text('Proof of Booking Receipt (Verification Required)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _proofUrlController,
                  decoration: InputDecoration(
                    hintText: 'Paste link to booking receipt/invoice doc',
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (val) => _isExternal && (val == null || val.isEmpty) ? 'Please provide proof link' : null,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload receipt/invoice stating dates and deposit paid to verify the listing.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
                const SizedBox(height: 24),
              ],

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Post Transfer Listing', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
