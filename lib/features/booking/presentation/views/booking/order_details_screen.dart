import 'package:eventease/core/services/pdf_generator_service.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/presentation/views/booking/booking_amendment_screen.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/booking/data/models/installment_plan.dart';
import 'package:eventease/features/customer/presentation/views/customer_vendor_tracking_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final Vendor vendor;
  final String serviceId;
  final String? eventId;
  final double amount;
  final Map<String, dynamic> bookingDetails;
  final String paymentMethod;
  
  const OrderDetailsScreen({
    super.key,
    required this.vendor,
    required this.serviceId,
    this.eventId,
    required this.amount,
    required this.bookingDetails,
    required this.paymentMethod,
  });

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  String _orderId = '';
  
  @override
  void initState() {
    super.initState();
    _generateOrderId();
  }

  void _generateOrderId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = (timestamp % 10000).toString().padLeft(4, '0');
    setState(() {
      _orderId = 'ORD$timestamp$random';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Order Details',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.primaryColor),
            onPressed: _shareOrder,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSuccessHeader(),
            const SizedBox(height: 24),
            _buildOrderStatus(),
            const SizedBox(height: 24),
            _buildOrderSummary(),
            const SizedBox(height: 24),
            _buildInstallmentPlanSection(),
            const SizedBox(height: 24),
            _buildVendorInfo(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    final isPendingVend = widget.paymentMethod == 'Pending Approval';
    final isOnlinePayment = widget.paymentMethod == 'online_banking' || widget.paymentMethod == 'credit_card' || widget.paymentMethod == 'e_wallet';
    
    String getTitle() {
      if (isPendingVend) return 'Booking Requested!';
      if (isOnlinePayment) return 'Payment Pending!';
      return 'Booking Confirmed!';
    }
    
    String getSubtitle() {
      if (isPendingVend) return 'Wait for vendor to confirm availability';
      if (isOnlinePayment) return 'Please complete your payment in the browser gateway';
      return 'Your booking has been successfully paid';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              isPendingVend ? Icons.hourglass_empty : (isOnlinePayment ? Icons.payment : Icons.check),
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            getTitle(),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            getSubtitle(),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatus() {
    final isPendingVend = widget.paymentMethod == 'Pending Approval';
    final isOnlinePayment = widget.paymentMethod == 'online_banking' || widget.paymentMethod == 'credit_card' || widget.paymentMethod == 'e_wallet';

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
            'Order Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          const SizedBox(height: 20),
          _buildStatusStep('Request Sent', 'Your request has been sent', true, Icons.send),
          _buildStatusStep(
            'Vendor Confirmation', 
            widget.paymentMethod == 'Pending Approval' ? 'Waiting for vendor confirmation' : 'Vendor has confirmed availability', 
            widget.paymentMethod != 'Pending Approval', 
            Icons.schedule
          ),
          _buildStatusStep(
            'Payment', 
            isOnlinePayment ? 'Awaiting payment completion' : (isPendingVend ? 'Awaiting confirmation' : 'Payment received successfully'), 
            !isPendingVend && !isOnlinePayment, 
            Icons.payment
          ),
          _buildStatusStep(
            'Service Delivery', 
            'Scheduled for ${widget.bookingDetails['bookingDate'] ?? 'Date TBD'}', 
            false, 
            Icons.event
          ),
          _buildStatusStep('Completed', 'Service has been completed', false, Icons.done_all),
        ],
      ),
    );
  }

  Widget _buildStatusStep(String title, String description, bool isCompleted, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted ? AppTheme.successColor : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: isCompleted ? AppTheme.textSecondaryColor : AppTheme.textSecondaryColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
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
            'Order Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow('Order ID', _orderId),
          _buildSummaryRow('Service', widget.bookingDetails['service']?.toString() ?? 'N/A'),
          _buildSummaryRow('Date', widget.bookingDetails['date'] != null ? '${(widget.bookingDetails['date'] as DateTime).day}/${(widget.bookingDetails['date'] as DateTime).month}/${(widget.bookingDetails['date'] as DateTime).year}' : 'N/A'),
          _buildSummaryRow('Time', widget.bookingDetails['time'] != null ? (widget.bookingDetails['time'] as TimeOfDay).format(context) : 'N/A'),
          _buildSummaryRow('Duration', widget.bookingDetails['duration']?.toString() ?? 'N/A'),
          if (widget.bookingDetails['location'] != null && widget.bookingDetails['location'].toString().isNotEmpty)
            _buildSummaryRow('Location', widget.bookingDetails['location']),
          if (widget.bookingDetails['notes'] != null && widget.bookingDetails['notes'].toString().isNotEmpty)
            _buildSummaryRow('Notes', widget.bookingDetails['notes']),
          const Divider(height: 32),
          _buildSummaryRow('Subtotal', 'RM ${widget.amount.toStringAsFixed(2)}'),
          _buildSummaryRow('Service Fee', 'RM ${(widget.amount * 0.05).toStringAsFixed(2)}'),
          _buildSummaryRow('Tax', 'RM ${(widget.amount * 0.06).toStringAsFixed(2)}'),
          const Divider(height: 32),
          _buildSummaryRow(
            'Total Paid',
            'RM ${(widget.amount * 1.11).toStringAsFixed(2)}',
            isTotal: true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.payment, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Paid via ${_getPaymentMethodName(widget.paymentMethod)}',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentPlanSection() {
    final bookingId = widget.bookingDetails['bookingId'] ?? widget.bookingDetails['id'];
    if (bookingId == null) return const SizedBox.shrink();

    return Consumer<BookingProvider>(
      builder: (context, provider, child) {
        final booking = provider.getBookingById(bookingId);
        final plan = booking?.installmentPlan;

        if (plan == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Payment Schedule',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${plan.totalInstallments} Installments',
                      style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Total Amount: RM ${plan.totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
              ),
              const Divider(height: 24),
              ...plan.payments.map((payment) => _buildInstallmentItem(payment)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstallmentItem(InstallmentPayment payment) {
    final isPaid = payment.status == InstallmentPaymentStatus.paid;
    final isPending = payment.status == InstallmentPaymentStatus.pending;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isPaid ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isPaid ? Icons.check_circle : Icons.schedule,
              color: isPaid ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RM ${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Due: ${DateFormat('MMM dd, yyyy').format(payment.dueDate)}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
          ),
          if (isPending)
            ElevatedButton(
              onPressed: () => _payInstallment(payment),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Pay', style: TextStyle(fontSize: 12)),
            )
          else
            Text(
              payment.status.name.toUpperCase(),
              style: TextStyle(
                color: isPaid ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  void _payInstallment(InstallmentPayment payment) {
    // Navigate to payment screen or initiate Billplz
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Processing payment for RM ${payment.amount.toStringAsFixed(2)}...')),
    );
    // TODO: Implement actual payment flow for installments
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorInfo() {
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
            'Vendor Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(
                  Icons.business,
                  color: AppTheme.primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vendor.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      widget.vendor.category,
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.vendor.rating} (${widget.vendor.reviewCount} reviews)',
                          style: const TextStyle(
                            color: AppTheme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildContactRow(Icons.location_on, widget.vendor.location),
          _buildContactRow(Icons.phone, widget.vendor.contactInfo['phone'] ?? 'N/A'),
          _buildContactRow(Icons.email, widget.vendor.contactInfo['email'] ?? 'N/A'),
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _contactVendor,
            icon: const Icon(Icons.chat),
            label: const Text('Contact Vendor'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: AppTheme.secondaryColor,
            ),
          ),
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerVendorTrackingScreen(
                    bookingId: _orderId,
                    vendorName: widget.vendor.name,
                    serviceName: widget.bookingDetails['service']?.toString() ?? 'Service',
                    eventDate: widget.bookingDetails['date'] ?? DateTime.now(),
                    eventLocation: widget.vendor.location, // or the actual event location if available
                    vendorUserId: widget.vendor.id, // optional chat link
                  ),
                ),
              );
            },
            icon: const Icon(Icons.location_on, color: Colors.white),
            label: const Text('Live Vendor Tracking', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _requestChange,
            icon: const Icon(Icons.edit_calendar, color: AppTheme.primaryColor),
            label: const Text('Request Change (Date/Package)', style: TextStyle(color: AppTheme.primaryColor)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _viewInCalendar,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Add to Calendar'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _downloadContract,
             icon: const Icon(Icons.description),
            label: const Text('Download Contract'),
             style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
         const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _downloadReceipt,
            icon: const Icon(Icons.download),
            label: const Text('Download Receipt'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: _goToHome,
          child: const Text('Back to Home'),
        ),
      ],
    );
  }

  String _getPaymentMethodName(String methodId) {
    switch (methodId) {
      case 'credit_card':
        return 'Credit/Debit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      case 'e_wallet':
        return 'E-Wallet';
      case 'online_banking':
        return 'Online Banking';
      default:
        return 'Unknown';
    }
  }

  void _shareOrder() {
    final shareText = '''
Booking Confirmed!

Order ID: $_orderId
Service: ${widget.bookingDetails['service']}
Date: ${widget.bookingDetails['date'].day}/${widget.bookingDetails['date'].month}/${widget.bookingDetails['date'].year}
Time: ${widget.bookingDetails['time'].format(context)}
Vendor: ${widget.vendor.name}

Total: RM ${(widget.amount * 1.11).toStringAsFixed(2)}
    ''';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Share: $shareText')),
    );
  }

  void _contactVendor() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening chat with vendor...')),
    );
    // Navigate to chat screen
  }

  void _viewInCalendar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Adding to calendar...')),
    );
    // Add to device calendar
  }

  void _downloadContract() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating contract...')),
    );
    
    // Create a temporary booking object if real one isn't fully available or just use passed data
    final booking = Booking(
      id: _orderId,
      serviceId: widget.serviceId,
      customerId: 'CUST001', // Should be real user ID
      vendorId: widget.vendor.id,
      bookingDate: widget.bookingDetails['date'] ?? DateTime.now(),
      status: BookingStatus.confirmed,
      amount: widget.amount,
      serviceName: widget.bookingDetails['service']?.toString() ?? 'Service Name',
      customerName: widget.bookingDetails['customerName']?.toString() ?? 'Customer Name',
      customerPhone: widget.bookingDetails['customerPhone']?.toString() ?? 'N/A',
      customerEmail: widget.bookingDetails['customerEmail']?.toString() ?? 'N/A',
      bookingTime: TimeOfDay.now(), // Placeholder
      duration: '1 hour', // Placeholder
      packageName: 'Standard Package', // Placeholder
      location: widget.vendor.location,
      notes: 'Notes',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await PdfGeneratorService().generateAndShareContract(
        booking,
        widget.vendor,
        widget.bookingDetails['service']?.toString() ?? 'Service',
        widget.amount,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating contract: $e')),
      );
    }
  }

  void _downloadReceipt() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Generating receipt...')),
    );

    final booking = Booking(
      id: _orderId,
      serviceId: widget.serviceId,
      customerId: 'CUST001', // Should be real user ID
      vendorId: widget.vendor.id,
      bookingDate: widget.bookingDetails['date'] ?? DateTime.now(),
      status: BookingStatus.confirmed,
      amount: widget.amount,
      serviceName: widget.bookingDetails['service']?.toString() ?? 'Service Name',
      customerName: widget.bookingDetails['customerName']?.toString() ?? 'Customer Name',
      customerPhone: widget.bookingDetails['customerPhone']?.toString() ?? 'N/A',
      customerEmail: widget.bookingDetails['customerEmail']?.toString() ?? 'N/A',
      bookingTime: TimeOfDay.now(), // Placeholder
      duration: '1 hour', // Placeholder
      packageName: 'Standard Package', // Placeholder
      location: widget.vendor.location,
      notes: 'Notes',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await PdfGeneratorService().generateAndShareInvoice(
        booking,
        widget.vendor,
        widget.bookingDetails['service']?.toString() ?? 'Service',
        widget.amount,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating receipt: $e')),
      );
    }
  }

  void _goToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _requestChange() {
    final bookingId = widget.bookingDetails['bookingId'] ?? widget.bookingDetails['id'];
    
    if (bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot find booking ID. Please try from Bookings history.')),
      );
      return;
    }

    _navigateToAmendment(context, bookingId);
  }

  void _navigateToAmendment(BuildContext context, String bookingId) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final bookingProvider = context.read<BookingProvider>();
      Booking? booking = bookingProvider.getBookingById(bookingId);
      
      if (booking == null) {
        // Fallback: try to fetch from Supabase if not in provider cache
        final response = await Supabase.instance.client
            .from('bookings')
            .select('*, customer_user(*), vendor_services(name)')
            .eq('id', bookingId)
            .single();
        
        booking = Booking.fromSupabase(response);
      }

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookingAmendmentScreen(
              booking: booking!,
              vendor: widget.vendor,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading booking: $e')),
        );
      }
    }
  }
}
