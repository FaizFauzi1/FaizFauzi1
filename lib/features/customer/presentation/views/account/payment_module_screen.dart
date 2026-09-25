import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:intl/intl.dart';

class PaymentModuleScreen extends StatefulWidget {
  const PaymentModuleScreen({super.key});

  @override
  State<PaymentModuleScreen> createState() => _PaymentModuleScreenState();
}

class _PaymentModuleScreenState extends State<PaymentModuleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock Data for Wallet (No backend yet)
  double walletBalance = 0.00;
  final List<Map<String, String>> cards = [
    {"type": "Visa", "number": "**** 1234", "holder": "John Doe"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Fetch bookings on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.userId != null) {
        final customerId = authProvider.userId!;
        Provider.of<BookingProvider>(context, listen: false).loadCustomerBookings(customerId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text("My Payments"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.credit_card), text: "Methods"),
            Tab(icon: Icon(Icons.account_balance_wallet), text: "Wallet"),
            Tab(icon: Icon(Icons.receipt_long), text: "Transactions"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPaymentMethods(),
          _buildWallet(),
          _buildTransactions(),
        ],
      ),
    );
  }

  // ---------------- PAYMENT METHODS ----------------
  Widget _buildPaymentMethods() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Placeholder for now as we focus on Transactions
        for (var card in cards) _buildCreditCardUI(card),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            _showAddMethodSheet();
          },
          icon: const Icon(Icons.add),
          label: const Text("Add New Method"),
        ),
        const SizedBox(height: 12),
        const Center(
            child: Text(
          "Payment Methods logic pending backend integration.",
          style: TextStyle(color: Colors.grey, fontSize: 12),
        )),
      ],
    );
  }

  Widget _buildCreditCardUI(Map<String, String> card) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(20),
      height: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card["type"]!,
              style: const TextStyle(color: Colors.white, fontSize: 18)),
          const Spacer(),
          Text(card["number"]!,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  letterSpacing: 2,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(card["holder"]!,
              style: const TextStyle(color: Colors.white70, fontSize: 16)),
        ],
      ),
    );
  }

  void _showAddMethodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Add Payment Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: "Card Number")),
            const TextField(decoration: InputDecoration(labelText: "Card Holder")),
            const TextField(decoration: InputDecoration(labelText: "Expiry Date")),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Save"),
            )
          ],
        ),
      ),
    );
  }

  // ---------------- WALLET ----------------
  Widget _buildWallet() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(24),
          height: 180,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Wallet Balance",
                  style: TextStyle(color: Colors.white70, fontSize: 16)),
              const Spacer(),
              Text("RM ${walletBalance.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton.icon(
              onPressed: () => _showActionSheet("Top Up"),
              icon: const Icon(Icons.add_circle),
              label: const Text("Top Up"),
            ),
            ElevatedButton.icon(
              onPressed: () => _showActionSheet("Withdraw"),
              icon: const Icon(Icons.arrow_circle_down),
              label: const Text("Withdraw"),
            ),
            ElevatedButton.icon(
              onPressed: () => _showActionSheet("Send"),
              icon: const Icon(Icons.send),
              label: const Text("Send"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Center(
            child: Text(
          "Wallet features are coming soon.",
          style: TextStyle(color: Colors.grey),
        )),
      ],
    );
  }

  void _showActionSheet(String action) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("$action Funds",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const TextField(
                decoration: InputDecoration(labelText: "Enter Amount (RM)")),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text("$action Now"),
            )
          ],
        ),
      ),
    );
  }

  // ---------------- TRANSACTIONS (Refactored to use BookingProvider) ----------------
  Widget _buildTransactions() {
    return Consumer<BookingProvider>(
      builder: (context, bookingProvider, child) {
        if (bookingProvider.isLoading && bookingProvider.customerBookings.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = bookingProvider.customerBookings;

        if (bookings.isEmpty) {
           return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  "No transactions yet",
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                if (bookingProvider.error != null)
                   Padding(
                     padding: const EdgeInsets.all(8.0),
                     child: Text("Error: ${bookingProvider.error}", style: const TextStyle(color: Colors.red)),
                   )
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
             final authProvider = Provider.of<AuthProvider>(context, listen: false);
             if (authProvider.isAuthenticated && authProvider.userId != null) {
                await bookingProvider.loadCustomerBookings(authProvider.userId!);
             }
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              
              // Determine display logic based on booking status
              // Paid/Completed -> Green
              // Pending -> Orange
              // Cancelled -> Grey
              // Rejected -> Red
              
              Color statusColor;
              IconData statusIcon;
              String statusText = booking.status.toString().split('.').last.toUpperCase();
              
              switch (booking.status) {
                case BookingStatus.completed:
                case BookingStatus.confirmed:
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                  break;
                case BookingStatus.pending:
                case BookingStatus.pendingVendor:
                case BookingStatus.awaitingPayment:
                case BookingStatus.inProgress:
                  statusColor = Colors.orange;
                  statusIcon = Icons.pending;
                  break;
                case BookingStatus.cancelled:
                case BookingStatus.cancelledByUser:
                case BookingStatus.cancelledByVendor:
                case BookingStatus.rejected:
                case BookingStatus.expired:
                  statusColor = Colors.red;
                  statusIcon = Icons.cancel;
                  break;
                default:
                  statusColor = Colors.grey;
                  statusIcon = Icons.help;
              }

              return AnimatedContainer(
                duration: Duration(milliseconds: 300 + (index * 50)),
                curve: Curves.easeOut,
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: statusColor.withOpacity(0.1),
                      child: Icon(statusIcon, color: statusColor),
                    ),
                    title: Text(booking.packageName.isNotEmpty ? booking.packageName : booking.serviceName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('dd MMM yyyy, hh:mm a').format(booking.bookingDate)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                    trailing: Text(
                      "RM ${booking.amount.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: statusColor,
                      ),
                    ),
                    onTap: () {
                         // Optional: Navigate to booking details
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
