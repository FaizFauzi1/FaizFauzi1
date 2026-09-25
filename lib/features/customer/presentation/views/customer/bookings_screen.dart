import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/chat/presentation/views/messages/messages_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/chat/data/models/chat_message.dart';
import 'package:eventease/features/customer/presentation/views/customer/customer_incident_report_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/chat_screen.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/features/booking/presentation/views/booking/payment_screen.dart';
import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/features/booking/presentation/views/booking/booking_amendment_screen.dart';
import 'package:eventease/features/customer/presentation/views/customer/create_transfer_listing_screen.dart';
import 'package:eventease/core/services/pdf_generator_service.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/responsive_utils.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';
import 'package:eventease/shared/widgets/app_footer.dart';

class CustomerBookingsScreen extends StatefulWidget {
  const CustomerBookingsScreen({super.key});

  @override
  State<CustomerBookingsScreen> createState() =>
      _CustomerBookingsScreenState();
}

class _CustomerBookingsScreenState extends State<CustomerBookingsScreen> {
  String searchQuery = "";
  String selectedSort = "Upcoming First";
  bool calendarView = false;

  @override
  void initState() {
    super.initState();
    // Load customer bookings when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        bookingProvider.loadCustomerBookings(user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'My Bookings',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
            onPressed: () {
              setState(() {
                calendarView = !calendarView;
              });
            },
          )
        ],
      ),
      body: ResponsiveWrapper(
        padding: EdgeInsets.zero,
        child: Consumer<BookingProvider>(
          builder: (context, bookingProvider, child) {
            final bookings = bookingProvider.customerBookings;
            final filtered = bookings
                .where((booking) =>
                    booking.packageName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                    booking.customerName.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Column(
              children: [
                // Search & Sort
                Padding(
                  padding: ResponsiveUtils.getScreenPadding(context),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: "Search bookings...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onChanged: (val) {
                            setState(() {
                              searchQuery = val;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: selectedSort,
                        items: const [
                          DropdownMenuItem(
                              value: "Upcoming First", child: Text("Upcoming First")),
                          DropdownMenuItem(
                              value: "Price High-Low", child: Text("Price High-Low")),
                          DropdownMenuItem(
                              value: "Price Low-High", child: Text("Price Low-High")),
                        ],
                        onChanged: (val) {
                          setState(() {
                            selectedSort = val!;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                // Content View
                Expanded(
                  child: calendarView
                      ? _buildCalendarView(filtered)
                      : _buildListView(filtered),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildListView(List<Booking> filtered) {
    if (filtered.isEmpty) {
      return SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 150,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_today, size: 80, color: AppTheme.primaryColor.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text("No bookings found",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 8),
                        const Text("Your upcoming bookings will appear here"),
                      ],
                    ),
                  ),
                ),
                if (kIsWeb) const AppFooter(),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
      itemCount: filtered.length + (kIsWeb ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == filtered.length) {
          return const AppFooter();
        }
        return _BookingTile(booking: filtered[i]);
      },
    );
  }

  Widget _buildCalendarView(List<Booking> filtered) {
    // Placeholder calendar (could integrate TableCalendar package later)
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 150,
        ),
        child: IntrinsicHeight(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.calendar_month, size: 80, color: AppTheme.primaryColor),
                      const SizedBox(height: 16),
                      const Text("Calendar View Coming Soon",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text("${filtered.length} upcoming bookings found"),
                    ],
                  ),
                ),
              ),
              if (kIsWeb) const AppFooter(),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingTile extends StatelessWidget {
  final Booking booking;
  const _BookingTile({required this.booking});

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingVendor:
        return AppTheme.warningColor; // Orange
      case BookingStatus.awaitingPayment:
        return Colors.blue;
      case BookingStatus.confirmed:
        return AppTheme.successColor;
      case BookingStatus.rejected:
        return Colors.red;
      case BookingStatus.inProgress:
        return AppTheme.primaryColor;
      case BookingStatus.completed:
        return Colors.green;
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByVendor:
      case BookingStatus.cancelled:
        return Colors.grey;
      case BookingStatus.expired:
        return Colors.grey;
      default:
        return AppTheme.warningColor;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pendingVendor:
        return 'Awaiting Vendor';
      case BookingStatus.awaitingPayment:
        return 'Ready to Pay';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByVendor:
      case BookingStatus.cancelled:
        return 'Cancelled';
      case BookingStatus.expired:
        return 'Expired';
      default:
        return 'Pending';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final formattedDate = DateFormat("MMM dd, yyyy").format(booking.bookingDate);
    final formattedTime = DateFormat.jm().format(
      DateTime(
        booking.bookingDate.year,
        booking.bookingDate.month,
        booking.bookingDate.day,
        booking.bookingTime.hour,
        booking.bookingTime.minute,
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: statusColor, width: 5),
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service & Title
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                child: Icon(Icons.business_center, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.serviceName,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimaryColor)),
                    if (booking.packageName.isNotEmpty && booking.packageName != 'Base Package')
                      Text(booking.packageName,
                          style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ),
              IconButton(
                  onPressed: () => _generateInvoice(context, booking),
                  icon: const Icon(Icons.share, color: AppTheme.primaryColor))
            ],
          ),

          const SizedBox(height: 8),

          // Date + Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$formattedDate at $formattedTime',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondaryColor)),
              Text('ID: ${booking.id}',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ],
          ),

          const SizedBox(height: 12),

          // Amount + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("RM ${booking.amount.toStringAsFixed(2)}",
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor)),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(_getStatusText(booking.status),
                    style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Location
          if (booking.location.isNotEmpty)
            Row(
              children: [
                Icon(Icons.location_on, color: AppTheme.textSecondaryColor, size: 16),
                const SizedBox(width: 6),
                Text(booking.location,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor)),
              ],
            ),

          const Divider(height: 20),

          // Actions
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (booking.status == BookingStatus.pendingVendor || booking.status == BookingStatus.awaitingPayment)
                TextButton.icon(
                    onPressed: () => _cancelBooking(context, booking),
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    label: const Text("Cancel")),
              
              TextButton.icon(
                  onPressed: () => _chatWithVendor(context, booking),
                  icon: const Icon(Icons.chat, color: AppTheme.primaryColor),
                  label: const Text("Chat")),
              
              if (booking.status == BookingStatus.awaitingPayment)
                 ElevatedButton.icon(
                  onPressed: () => _payForBooking(context, booking),
                  icon: const Icon(Icons.payment, color: Colors.white, size: 18),
                  label: const Text("Pay Deposit", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                 ),
              
              if (booking.status != BookingStatus.cancelled && booking.status != BookingStatus.rejected) ...[
                 TextButton.icon(
                  onPressed: () => _rescheduleBooking(context, booking),
                  icon: const Icon(Icons.edit_calendar, color: AppTheme.primaryColor),
                  label: const Text("Reschedule"),
                ),
                
                // EMERGENCY SOS BUTTON
                if (booking.status == BookingStatus.confirmed || booking.status == BookingStatus.inProgress)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CustomerIncidentReportScreen(booking: booking),
                        ),
                      );
                    },
                    icon: const Icon(Icons.emergency, color: Colors.white, size: 16),
                    label: const Text("Emergency SOS", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),

                if (booking.status == BookingStatus.confirmed)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateTransferListingScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 16),
                    label: const Text("List for Transfer", style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
              ],
            ],
          ),

          if (booking.status == BookingStatus.completed)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor),
                  onPressed: () {
                    // TODO review
                  },
                  icon: const Icon(Icons.star, color: Colors.white),
                  label: const Text("Leave Review"),
                ),
                           ),
             )
        ],
      ),
    );
  }

  void _cancelBooking(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
              bookingProvider.cancelBooking(booking.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking cancelled successfully')),
              );
            },
            child: const Text('Yes', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _chatWithVendor(BuildContext context, Booking booking) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final currentUser = Supabase.instance.client.auth.currentUser;
    
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to chat')),
      );
      return;
    }
    
    // Create or get conversation with the specific vendor
    final conversation = chatProvider.createConversation(
      vendorId: booking.vendorId,
      vendorName: 'Vendor', // Use booking.vendorName if available in future
      vendorEmail: 'vendor@example.com', // Placeholder
      vendorPhone: '',
    );
    
    // Navigate to the chat screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerChatScreen(conversation: conversation),
      ),
    );
  }

  void _payForBooking(BuildContext context, Booking booking) {
    // Construct a temporary Vendor object required by PaymentScreen
    final vendor = Vendor(
      id: booking.vendorId,
      name: 'Vendor', 
      categories: ['General'],
      subcategories: [],
      description: '',
      location: '',
      images: [],
      rating: 5.0,
      reviewCount: 0,
      status: VendorStatus.approved,
      documents: {},
      subscriptionTier: SubscriptionTier.free,
      logistics: {},
      contactInfo: {},
      sampleServiceIds: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          vendor: vendor,
          serviceId: booking.serviceId,
          amount: booking.amount,
          bookingDetails: {
            'bookingId': booking.id,
            'service': booking.packageName,
            'date': booking.bookingDate,
            'time': booking.bookingTime,
            'duration': '1 hour', // Placeholder as Booking model might not have duration or handle it differently
            'location': booking.location,
            'description': booking.notes,
          },
        ),
      ),
    );
  }

  void _rescheduleBooking(BuildContext context, Booking booking) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Fetch vendor profile
      final vendorData = await Supabase.instance.client
          .from('vendor_profiles')
          .select()
          .eq('id', booking.vendorId)
          .single();
      
      final vendor = Vendor.fromSupabase(vendorData);

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingAmendmentScreen(
              booking: booking,
              vendor: vendor,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vendor: $e')),
        );
      }
    }
  }

  Future<void> _generateInvoice(BuildContext context, Booking booking) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // 1. Fetch vendor profile (needed for invoice generation info)
      final vendorData = await Supabase.instance.client
          .from('vendor_profiles')
          .select()
          .eq('id', booking.vendorId)
          .single();

      final vendor = Vendor.fromSupabase(vendorData);

      if (context.mounted) {
        Navigator.pop(context); // Close loading

        // 2. Generate and Share Invoice
        await PdfGeneratorService().generateAndShareInvoice(
            booking, vendor, booking.packageName, booking.amount);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating invoice: $e')),
        );
      }
    }
  }
}
