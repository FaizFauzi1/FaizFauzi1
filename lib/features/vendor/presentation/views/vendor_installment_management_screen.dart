import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/booking/data/models/installment_plan.dart';

/// Vendor screen for managing customer installment payments
/// Shows all customers with active payment plans and their status
class VendorInstallmentManagementScreen extends StatefulWidget {
  final String vendorId;

  const VendorInstallmentManagementScreen({
    Key? key,
    required this.vendorId,
  }) : super(key: key);

  @override
  State<VendorInstallmentManagementScreen> createState() =>
      _VendorInstallmentManagementScreenState();
}

class _VendorInstallmentManagementScreenState
    extends State<VendorInstallmentManagementScreen> {
  String _filter = 'all'; // all, pending, late, paid
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).loadVendorBookings(widget.vendorId);
    });
  }

  List<Map<String, dynamic>> get _realCustomers {
    final bookings = context.watch<BookingProvider>().vendorBookings;
    final installmentBookings = bookings.where((b) => b.installmentPlan != null).toList();
    
    return installmentBookings.map((b) {
      final plan = b.installmentPlan!;
      final payments = plan.payments;
      payments.sort((x, y) => x.dueDate.compareTo(y.dueDate));
      
      final paidPayments = payments.where((p) => p.status == InstallmentPaymentStatus.paid).toList();
      final pendingPayments = payments.where((p) => p.status == InstallmentPaymentStatus.pending || p.status == InstallmentPaymentStatus.late).toList();
      final latePayments = payments.where((p) => p.status == InstallmentPaymentStatus.late).toList();
      
      InstallmentPayment? nextPayment = pendingPayments.isNotEmpty ? pendingPayments.first : null;
      
      return {
        'customer_name': b.customerName,
        'customer_email': b.customerEmail,
        'customer_phone': b.customerPhone,
        'service_name': b.serviceName,
        'booking_id': b.id,
        'total_amount': plan.totalAmount,
        'deposit_paid': plan.depositAmount,
        'remaining_balance': plan.remainingBalance,
        'number_of_installments': plan.numberOfInstallments,
        'next_payment_date': nextPayment?.dueDate ?? DateTime.now(),
        'next_payment_amount': nextPayment?.amount ?? 0.0,
        'status': plan.status == InstallmentPlanStatus.completed ? 'paid' : (latePayments.isNotEmpty ? 'late' : 'active'),
        'payments_made': paidPayments.length,
        'payments_remaining': pendingPayments.length,
        'late_payments': latePayments.length,
      };
    }).toList();
  }

  Map<String, dynamic> get _summary {
    final customers = _getFilteredCustomers();
    final totalExpectedRevenue = customers.fold<double>(
      0,
      (sum, customer) => sum + (customer['remaining_balance'] as double),
    );
    final activePlans = customers.where((c) => c['status'] == 'active').length;
    final latePlans = customers.where((c) => c['status'] == 'late').length;

    return {
      'total_expected_revenue': totalExpectedRevenue,
      'active_plans': activePlans,
      'late_payments': latePlans,
      'total_customers': customers.length,
    };
  }

  List<Map<String, dynamic>> _getFilteredCustomers() {
    final data = _realCustomers;
    if (_filter == 'all') return data;
    if (_filter == 'late') {
      return data.where((c) => c['status'] == 'late').toList();
    }
    if (_filter == 'pending') {
      return data.where((c) => c['status'] == 'active').toList();
    }
    if (_filter == 'paid') {
      return data.where((c) => c['status'] == 'paid' || c['payments_remaining'] == 0).toList();
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final customers = _getFilteredCustomers();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Payment Management',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Dashboard
            _buildSummaryDashboard(summary),
            const SizedBox(height: 24),

            // Filters
            _buildFilters(),
            const SizedBox(height: 24),

            // Customer List
            const Text(
              'Customer Payment Plans',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),

            if (customers.isEmpty)
              _buildEmptyState()
            else
              ...customers.map((customer) => _buildCustomerCard(customer)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryDashboard(Map<String, dynamic> summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Summary',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Expected Revenue',
                  'RM ${summary['total_expected_revenue'].toStringAsFixed(2)}',
                  Icons.trending_up,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Active Plans',
                  '${summary['active_plans']}',
                  Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Late Payments',
                  '${summary['late_payments']}',
                  Icons.warning,
                  isWarning: true,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  'Total Customers',
                  '${summary['total_customers']}',
                  Icons.people,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon,
      {bool isWarning = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: isWarning ? Colors.orange : Colors.white, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', 'all'),
          const SizedBox(width: 8),
          _buildFilterChip('Active', 'pending'),
          const SizedBox(width: 8),
          _buildFilterChip('Late', 'late'),
          const SizedBox(width: 8),
          _buildFilterChip('Paid', 'paid'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryColor.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
      ),
    );
  }

  Widget _buildCustomerCard(Map<String, dynamic> customer) {
    final isLate = customer['status'] == 'late';
    final nextPaymentDate = customer['next_payment_date'] as DateTime;
    final daysUntilPayment = nextPaymentDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLate ? Colors.red.shade200 : Colors.grey.shade200,
          width: isLate ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.all(16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isLate
                  ? Colors.red.shade50
                  : AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isLate ? Icons.warning : Icons.person,
              color: isLate ? Colors.red : AppTheme.primaryColor,
            ),
          ),
          title: Text(
            customer['customer_name'],
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                customer['service_name'],
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (isLate)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${daysUntilPayment.abs()} DAYS LATE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: daysUntilPayment <= 7
                            ? Colors.orange.shade100
                            : Colors.green.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        daysUntilPayment <= 7 ? 'DUE SOON' : 'ON TRACK',
                        style: TextStyle(
                          color: daysUntilPayment <= 7
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${customer['payments_made']}/${customer['number_of_installments']} paid',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${customer['remaining_balance'].toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const Text(
                'remaining',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ],
          ),
          children: [
            _buildCustomerDetails(customer),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerDetails(Map<String, dynamic> customer) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Customer Information',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.email, customer['customer_email']),
          _buildDetailRow(Icons.phone, customer['customer_phone']),
          _buildDetailRow(Icons.receipt, 'Booking: ${customer['booking_id']}'),
          const Divider(height: 24),
          const Text(
            'Payment Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildPaymentDetailRow(
            'Total Amount',
            'RM ${customer['total_amount'].toStringAsFixed(2)}',
          ),
          _buildPaymentDetailRow(
            'Deposit Paid',
            'RM ${customer['deposit_paid'].toStringAsFixed(2)}',
          ),
          _buildPaymentDetailRow(
            'Remaining Balance',
            'RM ${customer['remaining_balance'].toStringAsFixed(2)}',
            highlight: true,
          ),
          _buildPaymentDetailRow(
            'Next Payment',
            'RM ${customer['next_payment_amount'].toStringAsFixed(2)} on ${DateFormat('MMM dd, yyyy').format(customer['next_payment_date'])}',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Contacting ${customer['customer_name']}...'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.message),
                  label: const Text('Contact'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment reminder sent!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.notifications),
                  label: const Text('Remind'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: highlight ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: highlight ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No payment plans found',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Customer payment plans will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
