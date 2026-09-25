import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/widgets/payment_type_selector.dart';
import 'package:eventease/features/booking/data/models/installment_plan.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/core/services/installment_service.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

class PaymentScreenWithInstallment extends StatefulWidget {
  final Vendor vendor;
  final String serviceId;
  final VendorService? service;
  final String? eventId;
  final double amount;
  final Map<String, dynamic> bookingDetails;

  const PaymentScreenWithInstallment({
    super.key,
    required this.vendor,
    required this.serviceId,
    this.service,
    this.eventId,
    required this.amount,
    required this.bookingDetails,
  });

  @override
  State<PaymentScreenWithInstallment> createState() => _PaymentScreenWithInstallmentState();
}

class _PaymentScreenWithInstallmentState extends State<PaymentScreenWithInstallment> {
  String _selectedPaymentMethod = 'credit_card';
  bool _isProcessing = false;
  bool _useInstallment = false;
  InstallmentPlan? _installmentPlan;

  final Map<String, String> _paymentMethods = {
    'credit_card': 'Credit/Debit Card',
    'online_banking': 'Online Banking',
    'ewallet': 'E-Wallet',
  };

  double get _amountToPay {
    if (_useInstallment && _installmentPlan != null) {
      return _installmentPlan!.depositAmount;
    }
    return widget.amount;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Payment',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
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
            const Text(
              'Payment Details',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete your booking by selecting payment options',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 32),

            // Booking Summary
            _buildBookingSummary(),
            const SizedBox(height: 32),

            // Payment Type Selector (Full or Installment)
            PaymentTypeSelector(
              totalAmount: widget.amount,
              vendorId: widget.vendor.id,
              service: widget.service,
              onPaymentTypeChanged: (useInstallment, plan) {
                setState(() {
                  _useInstallment = useInstallment;
                  _installmentPlan = plan;
                });
              },
            ),
            const SizedBox(height: 32),

            // Payment Methods
            _buildPaymentMethods(),
            const SizedBox(height: 32),

            // Terms and Conditions
            _buildTermsAndConditions(),
            const SizedBox(height: 32),

            // Payment Button
            _buildPaymentButton(),
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
          _buildSummaryRow('Service', widget.bookingDetails['service'] ?? 'Unknown'),
          _buildSummaryRow('Package', widget.bookingDetails['package'] ?? 'Base Package'),
          _buildSummaryRow('Date', _formatDate(widget.bookingDetails['date'])),
          _buildSummaryRow('Time', _formatTime(widget.bookingDetails['time'])),
          _buildSummaryRow('Duration', widget.bookingDetails['duration'] ?? '1 hour'),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              Text(
                'RM ${widget.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
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

  Widget _buildPaymentMethods() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        ..._paymentMethods.entries.map((method) => _buildPaymentMethodCard(
              method.key,
              method.value,
              _getPaymentMethodIcon(method.key),
            )),
      ],
    );
  }

  Widget _buildPaymentMethodCard(String method, String title, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;

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
      child: RadioListTile<String>(
        value: method,
        groupValue: _selectedPaymentMethod,
        onChanged: (value) {
          setState(() {
            _selectedPaymentMethod = value!;
          });
        },
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: _buildPaymentMethodSubtitle(method),
        secondary: Icon(
          icon,
          color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
        ),
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildPaymentMethodSubtitle(String method) {
    switch (method) {
      case 'credit_card':
        return const Text('Visa, MasterCard, American Express');
      case 'online_banking':
        return const Text('Maybank2u, CIMB Clicks, Public Bank');
      case 'ewallet':
        return const Text('Touch n Go, GrabPay, Boost');
      default:
        return const SizedBox.shrink();
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'credit_card':
        return Icons.credit_card;
      case 'online_banking':
        return Icons.account_balance;
      case 'ewallet':
        return Icons.smartphone;
      default:
        return Icons.payment;
    }
  }

  Widget _buildTermsAndConditions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 8),
              const Text(
                'Terms and Conditions',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _useInstallment
                ? 'By proceeding with installment payment, you agree to pay the remaining balance in ${_installmentPlan?.numberOfInstallments ?? 5} monthly installments. Late payments may incur additional fees.'
                : 'By proceeding with this payment, you agree to our terms of service and cancellation policy. Please note that bookings are subject to vendor confirmation.',
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _processPayment,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                _useInstallment
                    ? 'Pay Deposit: RM ${_amountToPay.toStringAsFixed(2)}'
                    : 'Pay RM ${_amountToPay.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    }
    return 'Not specified';
  }

  String _formatTime(dynamic time) {
    if (time is TimeOfDay) {
      return time.format(context);
    }
    return 'Not specified';
  }

  Future<void> _processPayment() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // If using installment, create the installment plan
      if (_useInstallment && _installmentPlan != null) {
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        final installmentService = InstallmentService();
        
        // Generate payment schedule
        final schedule = installmentService.generatePaymentSchedule(_installmentPlan!);
        
        // Create installment plan in database
        await bookingProvider.createInstallmentPlan(_installmentPlan!, schedule);
      }

      // Simulate payment processing
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Show success dialog
      _showPaymentSuccessDialog();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  void _showPaymentSuccessDialog() {
    final bookingRef = 'BK${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Payment Successful!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _useInstallment
                  ? 'Your deposit has been paid successfully. You will receive reminders for upcoming installment payments.'
                  : 'Your booking has been confirmed successfully. You will receive a confirmation email shortly.',
              style: const TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    'Booking Reference: $bookingRef',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (_useInstallment) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Payment Plan: ${_installmentPlan?.numberOfInstallments ?? 5} months',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
              Navigator.of(context).pop(); // Go back to services screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}
