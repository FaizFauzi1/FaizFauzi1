import 'package:eventease/features/booking/data/models/installment_plan.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/chat/presentation/views/messages/messages_screen.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class VendorBookingManagementScreenFixed extends StatefulWidget {
  final Vendor vendor;
  final bool embeddedInDashboard;

  const VendorBookingManagementScreenFixed({
    super.key,
    required this.vendor,
    this.embeddedInDashboard = false,
  });

  @override
  State<VendorBookingManagementScreenFixed> createState() => _VendorBookingManagementScreenFixedState();
}

class _VendorBookingManagementScreenFixedState extends State<VendorBookingManagementScreenFixed>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;

  final List<String> _statusFilters = [
    'All',
    'Pending Vendor',
    'Awaiting Payment',
    'Confirmed',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Load vendor bookings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      bookingProvider.loadVendorBookings(widget.vendor.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          'Booking Management',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: widget.embeddedInDashboard
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: !widget.embeddedInDashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list, color: AppTheme.textPrimaryColor),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today, color: AppTheme.textPrimaryColor),
            onPressed: _showDateRangePicker,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryColor,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textSecondaryColor,
                tabs: const [
                  Tab(text: 'All Bookings'),
                  Tab(text: 'New Requests'),
                  Tab(text: 'Confirmed'),
                  Tab(text: 'Completed'),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '$_selectedFilter Status',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Consumer<BookingProvider>(
                      builder: (context, bookingProvider, child) {
                        final filteredCount = _getFilteredBookings(bookingProvider.vendorBookings).length;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '$filteredCount bookings',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
                _buildBookingsList(bookingProvider.vendorBookings, 'all'),
                _buildBookingsList(bookingProvider.vendorBookings, 'pending_vendor'),
                _buildBookingsList(bookingProvider.vendorBookings, 'confirmed'),
                _buildBookingsList(bookingProvider.vendorBookings, 'completed'),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewBookingDialog,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Booking'),
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> allBookings, String filter) {
    final bookings = _getFilteredBookings(allBookings, filter: filter);

    if (bookings.isEmpty) {
      return _buildEmptyState(filter);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: InkWell(
        onTap: () => _showBookingDetails(booking),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Past Date Warning
              if (booking.bookingDate.isBefore(DateTime.now().subtract(const Duration(days: 1))) &&
                  (booking.status == BookingStatus.pendingVendor || booking.status == BookingStatus.awaitingPayment))
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This event date has passed.',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Header with status and actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.serviceName.isNotEmpty ? booking.serviceName : 'Service',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        if (booking.serviceName != booking.packageName)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              booking.packageName,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Booking #${booking.id.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(booking.status),
                ],
              ),

              const SizedBox(height: 12),

              // Customer info
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text(
                    booking.customerName,
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.phone, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text(
                    booking.customerPhone,
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Date and time
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(booking.bookingDate),
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.jm().format(
                      DateTime(
                        booking.bookingDate.year,
                        booking.bookingDate.month,
                        booking.bookingDate.day,
                        booking.bookingTime.hour,
                        booking.bookingTime.minute,
                      ),
                    ),
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Amount and location
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.location.isNotEmpty ? booking.location : 'Location not specified',
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    'RM ${booking.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _contactCustomer(booking),
                      icon: const Icon(Icons.message, size: 16),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: const BorderSide(color: AppTheme.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (booking.status == BookingStatus.pendingVendor)
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _acceptBooking(booking),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Confirm'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _rejectBooking(booking),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (booking.status == BookingStatus.awaitingPayment)
                     Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'Awaiting User Payment',
                            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _updateBookingStatus(booking),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Update'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
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

  Widget _buildStatusBadge(BookingStatus status) {
    Color color;
    String text;

    switch (status) {
      case BookingStatus.pendingVendor:
        color = Colors.orange;
        text = 'New Request';
        break;
      case BookingStatus.awaitingPayment:
        color = Colors.blue;
        text = 'Awaiting Pay';
        break;
      case BookingStatus.confirmed:
        color = Colors.green;
        text = 'Confirmed';
        break;
      case BookingStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
      case BookingStatus.inProgress:
        color = Colors.purple;
        text = 'In Progress';
        break;
      case BookingStatus.completed:
        color = Colors.blue;
        text = 'Completed';
        break;
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByVendor:
      case BookingStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelled';
        break;
      case BookingStatus.expired:
        color = Colors.grey;
        text = 'Expired';
        break;
      case BookingStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case BookingStatus.changeRequested:
        color = Colors.orange;
        text = 'Change Req';
        break;
      case BookingStatus.changeApproved:
        color = Colors.green;
        text = 'Change Appr';
        break;
      case BookingStatus.changeRejected:
        color = Colors.red;
        text = 'Change Rej';
        break;
      case BookingStatus.awaitingAdjustmentPayment:
        color = Colors.blue;
        text = 'Awaiting Adj';
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
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    String title;
    String message;

    switch (filter) {
      case 'pending':
        title = 'No Pending Bookings';
        message = 'All booking requests have been processed.';
        break;
      case 'accepted':
        title = 'No Accepted Bookings';
        message = 'No bookings have been accepted yet.';
        break;
      case 'completed':
        title = 'No Completed Bookings';
        message = 'No bookings have been completed yet.';
        break;
      default:
        title = 'No Bookings Found';
        message = 'You don\'t have any bookings matching the current filter.';
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _selectedFilter = 'All';
              _selectedDateRange = null;
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Clear Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Booking> _getFilteredBookings(List<Booking> allBookings, {String filter = 'all'}) {
    // Apply status filter
    List<Booking> filteredBookings = allBookings;
    if (filter != 'all') {
      filteredBookings = allBookings.where((booking) {
        switch (filter) {
          case 'pending_vendor':
            return booking.status == BookingStatus.pendingVendor;
          case 'awaiting_payment':
            return booking.status == BookingStatus.awaitingPayment;
          case 'confirmed':
            return booking.status == BookingStatus.confirmed;
          case 'completed':
            return booking.status == BookingStatus.completed;
          default:
            return true;
        }
      }).toList();
    }

    // Apply date range filter
    if (_selectedDateRange != null) {
      filteredBookings = filteredBookings.where((booking) {
        return booking.bookingDate.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
               booking.bookingDate.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filteredBookings;
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _statusFilters.map((filter) {
            return RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _showNewBookingDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Booking'),
        content: const Text('This feature allows you to manually create bookings for walk-in customers or special arrangements.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to manual booking creation screen
              _showManualBookingForm();
            },
            child: const Text('Create Booking'),
          ),
        ],
      ),
    );
  }

  void _showManualBookingForm() {
    // This would navigate to a manual booking creation form
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Manual booking creation feature coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return _buildBookingDetailsSheet(booking, scrollController);
        },
      ),
    );
  }

  Widget _buildBookingDetailsSheet(Booking booking, ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Booking Details',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Scrollable content
          Expanded(
            child: ListView(
              controller: scrollController,
              children: [
                _buildDetailSection('Customer Information', [
                  'Name: ${booking.customerName}',
                  'Phone: ${booking.customerPhone}',
                  'Email: ${booking.customerEmail}',
                ]),

                _buildDetailSection('Service Details', [
                  'Service: ${booking.serviceName}',
                  'Package: ${booking.packageName}',
                  'Amount: RM ${booking.amount.toStringAsFixed(2)}',
                ]),

                _buildDetailSection('Booking Schedule', [
                  'Date: ${DateFormat('MMMM dd, yyyy').format(booking.bookingDate)}',
                  'Time: ${DateFormat.jm().format(DateTime(booking.bookingDate.year, booking.bookingDate.month, booking.bookingDate.day, booking.bookingTime.hour, booking.bookingTime.minute))}',
                  'Duration: ${booking.duration}',
                ]),

                if (booking.installmentPlan != null)
                  _buildInstallmentPlanSection(booking.installmentPlan!),

                if (booking.location.isNotEmpty)
                  _buildDetailSection('Location', [
                    booking.location,
                  ]),

                if (booking.notes.isNotEmpty)
                  _buildDetailSection('Notes', [
                    booking.notes,
                  ]),

                _buildDetailSection('Booking Information', [
                  'Booking ID: ${booking.id}',
                  'Status: ${booking.status.toString().split('.').last}',
                  'Created: ${DateFormat('MMM dd, yyyy HH:mm').format(booking.createdAt)}',
                  'Last Updated: ${DateFormat('MMM dd, yyyy HH:mm').format(booking.updatedAt)}',
                ]),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _contactCustomer(booking),
                  icon: const Icon(Icons.message),
                  label: const Text('Chat'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              if (booking.status == BookingStatus.pending)
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _acceptBooking(booking),
                          icon: const Icon(Icons.check),
                          label: const Text('Accept'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _rejectBooking(booking),
                          icon: const Icon(Icons.close),
                          label: const Text('Reject'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _updateBookingStatus(booking),
                    icon: const Icon(Icons.edit),
                    label: const Text('Update Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
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
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text(
              '• $item',
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 14,
              ),
            ),
          )),
        ],
      ),
    );
  }

  void _contactCustomer(Booking booking) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MessagesScreen(),
      ),
    );
  }

  void _acceptBooking(Booking booking) {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.acceptBooking(booking.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking accepted successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _rejectBooking(Booking booking) {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    bookingProvider.rejectBooking(booking.id);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Booking rejected'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _updateBookingStatus(Booking booking) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Update Booking Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 20),
              ...BookingStatus.values.map((status) {
                if (status == booking.status) return const SizedBox.shrink();
                return ListTile(
                  title: Text(_getStatusText(status)),
                  leading: Icon(_getStatusIcon(status)),
                  onTap: () {
                    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
                    bookingProvider.updateBookingStatus(booking.id, status);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Booking status updated to ${_getStatusText(status)}'),
                        backgroundColor: AppTheme.primaryColor,
                      ),
                    );
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.pendingVendor:
        return 'New Request';
      case BookingStatus.awaitingPayment:
        return 'Awaiting Payment';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByVendor:
        return 'Cancelled';
      case BookingStatus.expired:
        return 'Expired';
      case BookingStatus.changeRequested:
        return 'Change Requested';
      case BookingStatus.changeApproved:
        return 'Change Approved';
      case BookingStatus.changeRejected:
        return 'Change Rejected';
      case BookingStatus.awaitingAdjustmentPayment:
        return 'Awaiting Adjustment Payment';
    }
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

  Widget _buildInstallmentPlanSection(InstallmentPlan plan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Payment Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${plan.numberOfInstallments} Installments',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total Amount: RM ${plan.totalAmount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 13,
            ),
          ),
          const Divider(height: 24),
          ...plan.payments.map((payment) => _buildInstallmentItem(payment)).toList(),
        ],
      ),
    );
  }

  Widget _buildInstallmentItem(InstallmentPayment payment) {
    final isPaid = payment.status == InstallmentPaymentStatus.paid;
    final isLate = payment.status == InstallmentPaymentStatus.late;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isPaid ? Icons.check_circle : (isLate ? Icons.error_outline : Icons.schedule),
            color: isPaid ? Colors.green : (isLate ? Colors.red : Colors.orange),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RM ${payment.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  'Due: ${DateFormat('MMM dd, yyyy').format(payment.dueDate)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (isPaid ? Colors.green : (isLate ? Colors.red : Colors.orange)).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              payment.status.name.toUpperCase(),
              style: TextStyle(
                color: isPaid ? Colors.green : (isLate ? Colors.red : Colors.orange),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
