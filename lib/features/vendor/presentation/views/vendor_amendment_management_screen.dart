import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/models/booking_change.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:intl/intl.dart';

class VendorAmendmentManagementScreen extends StatefulWidget {
  final String vendorId;

  const VendorAmendmentManagementScreen({
    super.key,
    required this.vendorId,
  });

  @override
  State<VendorAmendmentManagementScreen> createState() => _VendorAmendmentManagementScreenState();
}

class _VendorAmendmentManagementScreenState extends State<VendorAmendmentManagementScreen> {
  bool _isLoading = true;
  List<BookingChange> _pendingChanges = [];

  @override
  void initState() {
    super.initState();
    _loadChanges();
  }

  Future<void> _loadChanges() async {
    setState(() => _isLoading = true);
    try {
      final provider = context.read<BookingProvider>();
      // Fetch all vendor bookings first (if not loaded)
      await provider.loadVendorBookings(widget.vendorId);
      
      final allPending = await provider.getPendingVendorChanges(widget.vendorId);
      
      setState(() {
        _pendingChanges = allPending;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading changes: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Amendment Requests'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadChanges,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _pendingChanges.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pendingChanges.length,
                  itemBuilder: (context, index) => _buildChangeCard(_pendingChanges[index]),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note, size: 80, color: AppTheme.textSecondaryColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No pending amendment requests',
            style: TextStyle(fontSize: 18, color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildChangeCard(BookingChange change) {
    final booking = context.read<BookingProvider>().getBookingById(change.bookingId);
    if (booking == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(change.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change.type.name.toUpperCase(),
                  style: TextStyle(
                    color: _getTypeColor(change.type),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                DateFormat('dd MMM HH:mm').format(change.createdAt),
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Booking: ${booking.packageName}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildComparisonRow(change),
          if (change.customerNotes != null && change.customerNotes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Text(
                '"${change.customerNotes}"',
                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleRejection(change),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleApproval(change),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(BookingChange change) {
    if (change.type == BookingChangeType.date) {
      final oldDate = DateTime.parse(change.oldValue['date']);
      final newDate = DateTime.parse(change.newValue['date']);
      return Row(
        children: [
          _buildValueColumn('Old Date', DateFormat('dd MMM yyyy').format(oldDate)),
          const Icon(Icons.arrow_forward, size: 16, color: AppTheme.textSecondaryColor),
          _buildValueColumn('New Date', DateFormat('dd MMM yyyy').format(newDate), isHighlighted: true),
        ],
      );
    } else if (change.type == BookingChangeType.package) {
      return Row(
        children: [
          _buildValueColumn('Old Pkg', change.oldValue['packageName']),
          const Icon(Icons.arrow_forward, size: 16, color: AppTheme.textSecondaryColor),
          _buildValueColumn('New Pkg', change.newValue['packageName'], isHighlighted: true),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildValueColumn(String label, String value, {bool isHighlighted = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isHighlighted ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
              color: isHighlighted ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(BookingChangeType type) {
    switch (type) {
      case BookingChangeType.date: return Colors.blue;
      case BookingChangeType.package: return Colors.purple;
      case BookingChangeType.pax: return Colors.orange;
      default: return Colors.grey;
    }
  }

  Future<void> _handleApproval(BookingChange change) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Change'),
        content: Text('Are you sure you want to approve this ${change.type.name} change?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Approve', style: TextStyle(color: Colors.green))),
        ],
      ),
    );

    if (confirmed == true) {
      await context.read<BookingProvider>().approveBookingChange(
        change.id,
        change.bookingId,
        priceDiff: change.priceDiff,
      );
      _loadChanges();
    }
  }

  Future<void> _handleRejection(BookingChange change) async {
    String? reason;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Change'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => reason = v,
              decoration: const InputDecoration(hintText: 'e.g. Fully booked on this date'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true && reason != null) {
      await context.read<BookingProvider>().rejectBookingChange(
        change.id,
        change.bookingId,
        reason!,
      );
      _loadChanges();
    }
  }
}
