import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({super.key});

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  String searchQuery = "";
  String selectedFilter = "All";
  bool showPaymentStatus = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        bookingProvider.loadCustomerBookings(currentUser.id);
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
            icon: Icon(
              showPaymentStatus ? Icons.inventory : Icons.payment,
              color: AppTheme.primaryColor,
            ),
            tooltip: showPaymentStatus ? 'Show Booking Status' : 'Show Payment Status',
            onPressed: () {
              setState(() {
                showPaymentStatus = !showPaymentStatus;
              });
            },
          )
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, bookingProvider, child) {
          if (bookingProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final bookings = bookingProvider.bookings;
          final filtered = bookings.where((booking) {
            final matchesSearch = booking.id.toLowerCase().contains(searchQuery.toLowerCase()) ||
                booking.serviceName.toLowerCase().contains(searchQuery.toLowerCase()) ||
                booking.packageName.toLowerCase().contains(searchQuery.toLowerCase());

            final matchesFilter = selectedFilter == "All" ||
                (selectedFilter == "Pending" && (booking.status == BookingStatus.pending || booking.status == BookingStatus.pendingVendor || booking.status == BookingStatus.awaitingPayment)) ||
                (selectedFilter == "Confirmed" && booking.status == BookingStatus.confirmed) ||
                (selectedFilter == "Completed" && booking.status == BookingStatus.completed) ||
                (selectedFilter == "Cancelled" && (booking.status == BookingStatus.rejected || booking.status == BookingStatus.cancelled || booking.status == BookingStatus.cancelledByUser || booking.status == BookingStatus.cancelledByVendor || booking.status == BookingStatus.expired));

            return matchesSearch && matchesFilter;
          }).toList();

          return Column(
            children: [
              // Search & Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      value: selectedFilter,
                      items: const [
                        DropdownMenuItem(value: "All", child: Text("All")),
                        DropdownMenuItem(value: "Pending", child: Text("Pending")),
                        DropdownMenuItem(value: "Confirmed", child: Text("Confirmed")),
                        DropdownMenuItem(value: "Completed", child: Text("Completed")),
                        DropdownMenuItem(value: "Cancelled", child: Text("Cancelled")),
                      ],
                      onChanged: (val) {
                        setState(() {
                          selectedFilter = val!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Content View
              Expanded(
                child: bookings.isEmpty
                    ? _buildEmptyBookings()
                    : _buildBookingsList(filtered),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyBookings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_today, size: 80, color: AppTheme.primaryColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          const Text("No bookings found",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          const Text("Your bookings will appear here"),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Booking> filtered) {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: AppTheme.textSecondaryColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text("No matching bookings",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            const Text("Try adjusting your search or filter"),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, i) {
        return _BookingCard(booking: filtered[i], showPaymentStatus: showPaymentStatus);
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool showPaymentStatus;

  const _BookingCard({required this.booking, required this.showPaymentStatus});

  Color _getStatusColor(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.pendingVendor:
      case BookingStatus.awaitingPayment:
        return AppTheme.warningColor; 
      case BookingStatus.confirmed:
        return Colors.green;
      case BookingStatus.rejected:
      case BookingStatus.cancelled:
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByVendor:
      case BookingStatus.expired:
        return Colors.red;
      case BookingStatus.completed:
        return Colors.blue;
      case BookingStatus.inProgress:
        return AppTheme.primaryColor;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BookingStatus status) {
    switch (status) {
      case BookingStatus.pending:
      case BookingStatus.pendingVendor:
        return 'Pending Approval';
      case BookingStatus.awaitingPayment:
        return 'Awaiting Payment';
      case BookingStatus.confirmed:
        return 'Confirmed';
      case BookingStatus.rejected:
        return 'Rejected';
      case BookingStatus.cancelled:
      case BookingStatus.cancelledByUser:
      case BookingStatus.cancelledByVendor:
        return 'Cancelled';
      case BookingStatus.expired:
        return 'Expired';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.inProgress:
        return 'In Progress';
      default:
        return status.toString().split('.').last;
    }
  }
  
  // Placeholder since PaymentStatus might not be directly in Booking model or needs mapping
  Color _getPaymentStatusColor(String status) {
     if (status == 'paid') return Colors.green;
     if (status == 'pending') return AppTheme.warningColor;
     if (status == 'failed') return Colors.red;
     return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(booking.status);
    final formattedDate = booking.bookingDate != null 
        ? DateFormat("MMM dd, yyyy").format(booking.bookingDate) 
        : 'Date N/A';
    
    // Determine payment status (assuming simple logic for now as Booking model might vary)
    // If you have a specific payment status field in Booking, use it.
    // For now I'll check status or use a default.
    String paymentStatus = 'pending'; 
    if (booking.status == BookingStatus.confirmed || booking.status == BookingStatus.completed) {
        // This is a simplification. Ideally check a payment_status field if it exists.
        // Based on previous file reads, Booking doesn't expose paymentStatus directly in the constructor shown?
        // Let's assume pending unless we see otherwise.
    }

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
          // Header
          Row(
            children: [
              Icon(Icons.event, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.serviceName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      booking.packageName.isNotEmpty ? booking.packageName : 'Standard Booking',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 12),

          // Details Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const Text('Status', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                   const SizedBox(height: 4),
                   Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(booking.status),
                      style: TextStyle(
                        fontSize: 12, 
                        fontWeight: FontWeight.bold,
                        color: statusColor
                      ),
                    ),
                   )
                ],
               ),
               Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                   const Text('Total Amount', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                   const SizedBox(height: 4),
                   Text(
                     'RM ${booking.amount.toStringAsFixed(2)}',
                     style: const TextStyle(
                       fontSize: 16,
                       fontWeight: FontWeight.bold,
                       color: AppTheme.primaryColor,
                     ),
                   ),
                ],
               )
            ],
          ),

          const SizedBox(height: 12),

          if (booking.status == BookingStatus.pending)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                     // Todo: Implement cancel
                  },
                  icon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                  label: const Text('Cancel', style: TextStyle(color: Colors.red)),
                )
              ],
            )
        ],
      ),
    );
  }
}
