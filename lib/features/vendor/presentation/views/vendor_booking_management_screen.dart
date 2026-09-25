import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/services/pdf_generator_service.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_event_checkin_screen.dart';
import 'package:eventease/shared/models/event/event_category.dart';
import 'package:eventease/shared/models/services/service_enums.dart';

class VendorBookingManagementScreen extends StatefulWidget {
  final Vendor vendor;

  const VendorBookingManagementScreen({
    super.key,
    required this.vendor,
  });

  @override
  State<VendorBookingManagementScreen> createState() => _VendorBookingManagementScreenState();
}

class _VendorBookingManagementScreenState extends State<VendorBookingManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  DateTimeRange? _selectedDateRange;

  final List<String> _statusFilters = [
    'All',
    'Pending',
    'Accepted',
    'In Progress',
    'Completed',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
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
                  Tab(text: 'Pending'),
                  Tab(text: 'Accepted'),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_getFilteredBookings().length} bookings',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingsList('all'),
          _buildBookingsList('pending'),
          _buildBookingsList('accepted'),
          _buildBookingsList('completed'),
        ],
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

  Widget _buildBookingsList(String filter) {
    final bookings = _getFilteredBookings(filter: filter);

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
    // For now, construct a lightweight service model from the booking data.
    // This avoids depending on an internal `services` list on VendorProvider
    // that no longer exists in the updated provider implementation.
    final service = VendorService(
      id: booking.serviceId,
      vendorId: booking.vendorId,
      name: booking.serviceName,
      description: '',
      category: EventCategory.other,
      types: [ServiceType.service],
      basePrice: booking.amount,
      active: true,
      availability: const {},
      images: const [],
      advanceBookingDays: 0,
      maxBookingsPerDay: 1,
      status: ServiceStatus.active,
      approvalStatus: ApprovalStatus.approved,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

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
              // Header with status and actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
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
                    booking.bookingTime.format(context),
                    style: const TextStyle(
                      color: AppTheme.textPrimaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Amount and package
              Row(
                children: [
                  Expanded(
                    child: Text(
                      booking.packageName,
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _contactCustomer(booking),
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
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
                  if (booking.status == BookingStatus.confirmed || booking.status == BookingStatus.inProgress)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VendorEventCheckinScreen(booking: booking),
                          ),
                        );
                      },
                      icon: const Icon(Icons.location_on, size: 16),
                      label: const Text('Event Check-In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
    late Color color;
    late String text;

    switch (status) {
      case BookingStatus.pendingVendor:
      case BookingStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case BookingStatus.awaitingPayment:
        color = Colors.blue;
        text = 'Awaiting Payment';
        break;
      case BookingStatus.confirmed:
        color = Colors.green;
        text = 'Confirmed';
        break;
      case BookingStatus.inProgress:
        color = Colors.purple;
        text = 'In Progress';
        break;
      case BookingStatus.completed:
        color = Colors.teal;
        text = 'Completed';
        break;
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByVendor:
      case BookingStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
      case BookingStatus.rejected:
        color = Colors.grey;
        text = 'Rejected';
        break;
      case BookingStatus.expired:
        color = Colors.blueGrey;
        text = 'Expired';
        break;
      case BookingStatus.changeRequested:
        color = Colors.indigo;
        text = 'Change Requested';
        break;
      case BookingStatus.changeApproved:
        color = Colors.cyan;
        text = 'Change Approved';
        break;
      case BookingStatus.changeRejected:
        color = Colors.brown;
        text = 'Change Rejected';
        break;
      case BookingStatus.awaitingAdjustmentPayment:
        color = Colors.amber;
        text = 'Awaiting Adjustment';
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

  List<Booking> _getFilteredBookings({String filter = 'all'}) {
    // Get bookings from provider
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    final allBookings = bookingProvider.vendorBookings
        .where((booking) => booking.vendorId == widget.vendor.id)
        .toList();

    // Apply status filter
    List<Booking> filteredBookings = allBookings;
    if (filter != 'all') {
      filteredBookings = allBookings.where((booking) {
        switch (filter) {
          case 'pending':
            return booking.status == BookingStatus.pendingVendor || booking.status == BookingStatus.pending;
          case 'accepted':
            return booking.status == BookingStatus.awaitingPayment || booking.status == BookingStatus.confirmed;
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
                  'Time: ${booking.bookingTime.format(context)}',
                  'Duration: ${booking.duration}',
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
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.message),
                  label: const Text('Message'),
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
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => PdfGeneratorService().generateAndShareInvoice(
                booking,
                widget.vendor,
                booking.packageName,
                booking.amount,
              ),
              icon: const Icon(Icons.description),
              label: const Text('Generate Invoice'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening chat with ${booking.customerName}...'),
        backgroundColor: AppTheme.primaryColor,
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
              return ListTile(
                title: Text(status.toString().split('.').last),
                leading: Icon(_getStatusIcon(status)),
                onTap: () {
                  // Update booking status logic here
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Booking status updated to ${status.toString().split('.').last}'),
                      backgroundColor: AppTheme.primaryColor,
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingVendor:
      case BookingStatus.pending:
        return Icons.schedule;
      case BookingStatus.awaitingPayment:
        return Icons.payment;
      case BookingStatus.confirmed:
        return Icons.check_circle;
      case BookingStatus.inProgress:
        return Icons.play_circle;
      case BookingStatus.completed:
        return Icons.done_all;
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByVendor:
      case BookingStatus.cancelled:
        return Icons.cancel;
      case BookingStatus.rejected:
        return Icons.close;
      case BookingStatus.expired:
        return Icons.timer_off;
      case BookingStatus.changeRequested:
        return Icons.edit_note;
      case BookingStatus.changeApproved:
        return Icons.assignment_turned_in;
      case BookingStatus.changeRejected:
        return Icons.assignment_late;
      case BookingStatus.awaitingAdjustmentPayment:
        return Icons.price_change;
    }
  }
}
