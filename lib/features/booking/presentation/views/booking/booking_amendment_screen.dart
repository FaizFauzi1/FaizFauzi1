import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/models/booking_change.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/shared/models/sample_service_packages.dart';
import 'package:eventease/shared/models/services/service_package.dart';

class BookingAmendmentScreen extends StatefulWidget {
  final Booking booking;
  final Vendor vendor;

  const BookingAmendmentScreen({
    super.key,
    required this.booking,
    required this.vendor,
  });

  @override
  State<BookingAmendmentScreen> createState() => _BookingAmendmentScreenState();
}

class _BookingAmendmentScreenState extends State<BookingAmendmentScreen> {
  BookingChangeType _selectedType = BookingChangeType.date;
  DateTime? _newDate;
  String? _newPackageName;
  double? _newPackagePrice;
  final _customerNotesController = TextEditingController();
  bool _isSubmitting = false;
  List<ServicePackage> _availablePackages = [];
  bool _isLoadingPackages = false;

  @override
  void initState() {
    super.initState();
    _newDate = widget.booking.bookingDate;
    _newPackageName = widget.booking.packageName;
    _newPackagePrice = widget.booking.amount;
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoadingPackages = true);
    try {
      final response = await Supabase.instance.client
          .from('vendor_service_packages')
          .select()
          .eq('service_id', widget.booking.serviceId)
          .eq('is_active', true);
      
      setState(() {
        _availablePackages = (response as List)
            .map((p) => ServicePackage.fromMap(p))
            .toList();
      });
    } catch (e) {
      print('Error loading packages: $e');
    } finally {
      setState(() => _isLoadingPackages = false);
    }
  }

  @override
  void dispose() {
    _customerNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Request Change'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCurrentBookingInfo(),
            const SizedBox(height: 24),
            const Text(
              'What would you like to change?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildChangeTypeSelector(),
            const SizedBox(height: 24),
            if (_selectedType == BookingChangeType.date) _buildDateSelection(),
            if (_selectedType == BookingChangeType.package) _buildPackageSelection(),
            const SizedBox(height: 24),
            const Text(
              'Notes for Vendor',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _customerNotesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Explain why you are requesting this change...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
            _buildPriceComparison(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Change Request',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Your current booking remains active until the vendor approves this request.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBookingInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Booking', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
          const SizedBox(height: 8),
          Text(
            widget.booking.packageName,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
              Text(DateFormat('dd MMM yyyy').format(widget.booking.bookingDate)),
              const SizedBox(width: 12),
              const Icon(Icons.payments, size: 14, color: AppTheme.primaryColor),
              const SizedBox(width: 4),
              Text('RM ${widget.booking.amount.toStringAsFixed(2)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChangeTypeSelector() {
    return Row(
      children: [
        _buildTypeChip('Change Date', BookingChangeType.date),
        const SizedBox(width: 12),
        _buildTypeChip('Upgrade Package', BookingChangeType.package),
      ],
    );
  }

  Widget _buildTypeChip(String label, BookingChangeType type) {
    final isSelected = _selectedType == type;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select New Date', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.textSecondaryColor.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(_newDate!),
                  style: const TextStyle(fontSize: 16),
                ),
                const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPackageSelection() {
    if (_isLoadingPackages) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_availablePackages.isEmpty) {
      return const Text('No other packages available for this service.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select New Package', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _availablePackages.length,
          itemBuilder: (context, index) {
            final pkg = _availablePackages[index];
            final isSelected = _newPackageName == pkg.name;
            final price = pkg.getPriceForPax(widget.booking.guestCount); 

            return GestureDetector(
              onTap: () {
                setState(() {
                  _newPackageName = pkg.name;
                  _newPackagePrice = price;
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected ? AppTheme.primaryColor.withOpacity(0.05) : Colors.transparent,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pkg.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(pkg.description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    Text(
                      'RM ${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceComparison() {
    final diff = (_newPackagePrice ?? 0) - widget.booking.amount;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Estimated Price Difference:'),
          Text(
            diff == 0 ? 'No Change' : (diff > 0 ? '+ RM ${diff.toStringAsFixed(2)}' : '- RM ${diff.abs().toStringAsFixed(2)}'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: diff > 0 ? Colors.red : (diff < 0 ? Colors.green : AppTheme.textPrimaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _newDate!,
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _newDate = date);
    }
  }

  Future<void> _submitRequest() async {
    setState(() => _isSubmitting = true);
    
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) throw Exception('Not logged in');

      final change = BookingChange(
        id: '', // Generated by Supabase
        bookingId: widget.booking.id,
        requestedBy: currentUser.id,
        type: _selectedType,
        oldValue: {
          'date': widget.booking.bookingDate.toIso8601String(),
          'packageName': widget.booking.packageName,
          'amount': widget.booking.amount,
        },
        newValue: {
          'date': _newDate!.toIso8601String(),
          'packageName': _newPackageName,
          'amount': _newPackagePrice,
        },
        priceDiff: (_newPackagePrice ?? 0) - widget.booking.amount,
        customerNotes: _customerNotesController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await context.read<BookingProvider>().requestBookingChange(change);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Request Submitted'),
            content: const Text('Your change request has been sent to the vendor. You will be notified once they review it.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Dialog
                  Navigator.of(context).pop(); // Amendment Screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
