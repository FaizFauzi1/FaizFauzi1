import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VendorBookingStatusUpdateScreen extends StatefulWidget {
  final Booking booking;

  const VendorBookingStatusUpdateScreen({
    super.key,
    required this.booking,
  });

  @override
  State<VendorBookingStatusUpdateScreen> createState() => _VendorBookingStatusUpdateScreenState();
}

class _VendorBookingStatusUpdateScreenState extends State<VendorBookingStatusUpdateScreen> {
  late BookingStatus _selectedStatus;
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.booking.status;
    _notesController.text = widget.booking.notes;
  }

  @override
  void dispose() {
    _notesController.dispose();
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
          'Update Booking Status',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking Summary
            _buildBookingSummary(),

            const SizedBox(height: 32),

            // Status Selection
            _buildStatusSelection(),

            const SizedBox(height: 32),

            // Notes Section
            _buildNotesSection(),

            const SizedBox(height: 32),

            // Status-specific Actions
            _buildStatusActions(),

            const SizedBox(height: 32),

            // Update History
            _buildUpdateHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Customer', widget.booking.customerName),
          _buildSummaryRow('Service', 'Wedding Catering Package'), // Would come from service lookup
          _buildSummaryRow('Date', DateFormat('MMMM dd, yyyy').format(widget.booking.bookingDate)),
          _buildSummaryRow('Time', widget.booking.bookingTime.format(context)),
          _buildSummaryRow('Amount', 'RM ${widget.booking.amount.toStringAsFixed(2)}'),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Current Status:',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
              _buildStatusBadge(widget.booking.status),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select New Status',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ...BookingStatus.values.map((status) {
          return _buildStatusOption(status);
        }),
      ],
    );
  }

  Widget _buildStatusOption(BookingStatus status) {
    final isSelected = _selectedStatus == status;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: RadioListTile<BookingStatus>(
        value: status,
        groupValue: _selectedStatus,
        onChanged: (value) {
          setState(() {
            _selectedStatus = value!;
          });
        },
        title: Text(
          status.toString().split('.').last,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: _buildStatusDescription(status),
        secondary: Icon(
          _getStatusIcon(status),
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
        ),
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildStatusDescription(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.pendingVendor:
        return const Text('Booking request received, awaiting confirmation');
      case BookingStatus.awaitingPayment:
        return const Text('Vendor confirmed, awaiting user payment');
      case BookingStatus.confirmed:
        return const Text('Booking confirmed, payment received');
      case BookingStatus.rejected:
        return const Text('Booking rejected, customer notified');
      case BookingStatus.inProgress:
        return const Text('Service is currently being provided');
      case BookingStatus.completed:
        return const Text('Service completed successfully');
      case BookingStatus.cancelled:
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByVendor:
        return const Text('Booking cancelled');
      case BookingStatus.expired:
        return const Text('Booking expired due to non-payment');
      case BookingStatus.changeRequested:
        return const Text('Customer requested a change to the booking');
      case BookingStatus.changeApproved:
        return const Text('Change approved, waiting for finalization');
      case BookingStatus.changeRejected:
        return const Text('Change request rejected');
      case BookingStatus.awaitingAdjustmentPayment:
        return const Text('Awaiting payment for price difference');
    }
  }

  Widget _buildStatusBadge(BookingStatus status) {
    Color color;
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.pendingVendor:
      case BookingStatus.awaitingPayment:
        color = Colors.orange;
        break;
      case BookingStatus.confirmed:
        color = Colors.green;
        break;
      case BookingStatus.rejected:
        color = Colors.red;
        break;
      case BookingStatus.inProgress:
        color = Colors.purple;
        break;
      case BookingStatus.completed:
        color = Colors.green;
        break;
      case BookingStatus.cancelled:
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByVendor:
      case BookingStatus.expired:
        color = Colors.red;
        break;
      case BookingStatus.changeRequested:
        color = Colors.orange;
        break;
      case BookingStatus.changeApproved:
      case BookingStatus.awaitingAdjustmentPayment:
        color = Colors.green;
        break;
      case BookingStatus.changeRejected:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status.toString().split('.').last,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Update Notes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Add any notes about this status change or special instructions',
          style: TextStyle(
            color: AppTheme.textSecondaryColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Enter your notes here...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildActionButton(
              'Send Confirmation',
              Icons.check_circle,
              Colors.green,
              _selectedStatus == BookingStatus.confirmed,
              () => _sendConfirmation(),
            ),
            _buildActionButton(
              'Contact Customer',
              Icons.message,
              Colors.blue,
              true,
              () => _contactCustomer(),
            ),
            _buildActionButton(
              'Reschedule',
              Icons.calendar_today,
              Colors.orange,
              true,
              () => _rescheduleBooking(),
            ),
            _buildActionButton(
              'Cancel Booking',
              Icons.cancel,
              Colors.red,
              _selectedStatus != BookingStatus.completed,
              () => _cancelBooking(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, bool enabled, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: enabled ? color : Colors.grey.shade300,
        foregroundColor: enabled ? Colors.white : Colors.grey.shade500,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildUpdateHistory() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Update History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildHistoryItem(
            'Status changed to ${widget.booking.status.toString().split('.').last}',
            '2 hours ago',
            Icons.update,
          ),
          _buildHistoryItem(
            'Booking confirmed by customer',
            '1 day ago',
            Icons.check_circle,
          ),
          _buildHistoryItem(
            'Initial booking request received',
            '3 days ago',
            Icons.add,
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String action, String time, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.textSecondaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 14,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.pendingVendor:
        return Icons.schedule;
      case BookingStatus.awaitingPayment:
        return Icons.payment;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.rejected:
        return Icons.cancel;
      case BookingStatus.inProgress:
        return Icons.play_circle;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelled:
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByVendor:
      case BookingStatus.expired:
        return Icons.cancel;
      case BookingStatus.changeRequested:
        return Icons.edit_calendar;
      case BookingStatus.changeApproved:
        return Icons.check_circle_outline;
      case BookingStatus.changeRejected:
        return Icons.highlight_off;
      case BookingStatus.awaitingAdjustmentPayment:
        return Icons.payment_outlined;
    }
  }

  void _saveChanges() {
    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking status updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, _selectedStatus);
    });
  }

  void _sendConfirmation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Confirmation message sent to customer!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _contactCustomer() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with ${widget.booking.customerName}...'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _rescheduleBooking() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reschedule feature coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _cancelBooking() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No, Keep It'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedStatus = BookingStatus.cancelledByVendor;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Booking cancelled successfully'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }
}
