import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/customer/data/providers/customer_provider.dart';
import 'package:intl/intl.dart';
import 'package:eventease/features/booking/data/providers/payment_provider.dart';
import 'package:eventease/shared/models/payment.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerInstallmentScreen extends StatefulWidget {
  final String customerId;

  const CustomerInstallmentScreen({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  State<CustomerInstallmentScreen> createState() => _CustomerInstallmentScreenState();
}

class _CustomerInstallmentScreenState extends State<CustomerInstallmentScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _summary;
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _upcomingPayments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final customerProvider = Provider.of<CustomerProvider>(context, listen: false);
      final summary = await customerProvider.getInstallmentPaymentSummary(widget.customerId);
      final bookings = await customerProvider.getCustomerBookingsWithInstallments(widget.customerId);
      final upcoming = await customerProvider.getUpcomingInstallmentPayments(widget.customerId);
      setState(() {
        _summary = summary;
        _bookings = bookings;
        _upcomingPayments = upcoming;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading installment data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Installment Payments'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const SizedBox(height: 24),
                    _buildUpcomingPaymentsSection(),
                    const SizedBox(height: 24),
                    _buildAllBookingsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    if (_summary == null) return const SizedBox.shrink();

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Theme.of(context).primaryColor, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Payment Summary',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildSummaryRow('Active Plans', '${_summary!['active_installment_plans']}', Icons.receipt_long),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Outstanding Balance',
              'RM ${_summary!['total_outstanding_balance'].toStringAsFixed(2)}',
              Icons.pending_actions,
              valueColor: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              'Total Paid',
              'RM ${_summary!['total_paid'].toStringAsFixed(2)}',
              Icons.check_circle,
              valueColor: Colors.green,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('Pending Payments', '${_summary!['total_pending_payments']}', Icons.schedule),
            if (_summary!['has_late_payments']) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                'Late Payments',
                '${_summary!['total_late_payments']}',
                Icons.warning,
                valueColor: Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingPaymentsSection() {
    if (_upcomingPayments.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: Colors.green[300]),
                const SizedBox(height: 12),
                const Text(
                  'No upcoming payments',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upcoming Payments',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._upcomingPayments.map((payment) => _buildUpcomingPaymentCard(payment)),
      ],
    );
  }

  Widget _buildUpcomingPaymentCard(Map<String, dynamic> payment) {
    final dueDate = payment['due_date'] as DateTime;
    final isOverdue = payment['is_overdue'] as bool;
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    final status = payment['status'] as String;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (status == 'late' || isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
      statusText = 'OVERDUE';
    } else if (daysUntilDue <= 7) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = 'DUE SOON';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.schedule;
      statusText = 'UPCOMING';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Navigate to payment details or initiate payment
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'RM ${payment['amount'].toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                payment['service_name'],
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    'Due: ${DateFormat('MMM dd, yyyy').format(dueDate)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    isOverdue
                        ? '${daysUntilDue.abs()} days overdue'
                        : '$daysUntilDue days remaining',
                    style: TextStyle(
                      fontSize: 14,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Generating payment link for ${payment['service_name']}...')),
                  );
                  try {
                    final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
                    final currentUser = Supabase.instance.client.auth.currentUser;
                    final email = currentUser?.email ?? 'customer@example.com';
                    final phone = currentUser?.userMetadata?['phone'] as String? ?? '0123456789';
                    final name = currentUser?.userMetadata?['full_name'] as String? ?? 'Valued Customer';
                    
                    final paymentUrl = await paymentProvider.processPayment(
                      bookingId: payment['booking_id'],
                      customerId: currentUser?.id ?? '',
                      vendorId: 'vendor-id-placeholder',
                      amount: payment['amount'],
                      method: PaymentMethod.onlineBanking,
                      email: email,
                      mobile: phone,
                      name: name,
                      description: 'Installment for ${payment['service_name']}',
                    );

                    if (paymentUrl != null) {
                      final Uri url = Uri.parse(paymentUrl);
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url, mode: LaunchMode.externalApplication);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Payment page opened. Please complete payment in browser.')),
                          );
                        }
                      }
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.payment),
                label: const Text('Pay Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: statusColor,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllBookingsSection() {
    if (_bookings.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Bookings with Installments',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ..._bookings.map((booking) => _buildBookingCard(booking)),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final allPayments = booking['all_payments'] as List<Map<String, dynamic>>;
    final eventDate = booking['event_date'] as DateTime;
    final nextPayment = booking['next_payment'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: Icon(
          Icons.event,
          color: Theme.of(context).primaryColor,
        ),
        title: Text(
          booking['service_name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Event: ${DateFormat('MMM dd, yyyy').format(eventDate)}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBookingInfoRow('Total Amount', 'RM ${booking['total_amount'].toStringAsFixed(2)}'),
                _buildBookingInfoRow('Deposit Paid', 'RM ${booking['deposit_amount'].toStringAsFixed(2)}'),
                _buildBookingInfoRow('Total Paid', 'RM ${booking['total_paid'].toStringAsFixed(2)}'),
                _buildBookingInfoRow('Remaining Balance', 'RM ${booking['remaining_balance'].toStringAsFixed(2)}'),
                _buildBookingInfoRow('Installments', '${booking['number_of_installments']} payments'),
                const Divider(height: 24),
                const Text(
                  'Payment Schedule',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ...allPayments.map((payment) => _buildPaymentItem(payment)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildPaymentItem(Map<String, dynamic> payment) {
    final dueDate = payment['due_date'] as DateTime;
    final status = payment['status'] as String;
    final isOverdue = payment['is_overdue'] as bool;

    IconData icon;
    Color color;

    switch (status) {
      case 'paid':
        icon = Icons.check_circle;
        color = Colors.green;
        break;
      case 'late':
        icon = Icons.warning;
        color = Colors.red;
        break;
      case 'pending':
        icon = isOverdue ? Icons.warning : Icons.schedule;
        color = isOverdue ? Colors.red : Colors.orange;
        break;
      default:
        icon = Icons.cancel;
        color = Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(dueDate),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  status.toUpperCase(),
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ],
            ),
          ),
          Text(
            'RM ${payment['amount'].toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
