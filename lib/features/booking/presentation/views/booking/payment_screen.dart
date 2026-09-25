import 'package:eventease/features/vendor/data/models/vendor.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/booking/presentation/views/booking/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:eventease/features/booking/data/providers/payment_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eventease/shared/models/payment.dart';
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  final Vendor vendor;
  final String serviceId;
  final String? eventId;
  final double amount;
  final Map<String, dynamic> bookingDetails;
  
  const PaymentScreen({
    super.key,
    required this.vendor,
    required this.serviceId,
    this.eventId,
    required this.amount,
    required this.bookingDetails,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedPaymentMethod = 'credit_card';
  String _selectedPaymentPlan = 'full'; // 'full', 'deposit', 'installment'
  bool _isProcessing = false;

  
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _cardholderNameController = TextEditingController();
  
  // Installment Rules from Vendor
  bool _installmentEnabled = false;
  double _depositPercentage = 30.0;
  int _maxInstallments = 3;
  int _selectedInstallments = 2;
  int _paymentDeadlineDays = 14;
  double _lateFeePercentage = 0.0;
  bool _isLoadingRules = true;
  List<Map<String, dynamic>> _installmentSchedule = [];
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'credit_card',
      'name': 'Credit/Debit Card',
      'icon': Icons.credit_card,
      'description': 'Visa, Mastercard, American Express',
    },
    {
      'id': 'bank_transfer',
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'description': 'Direct bank transfer',
    },
    {
      'id': 'e_wallet',
      'name': 'E-Wallet',
      'icon': Icons.account_balance_wallet,
      'description': 'Touch n Go, GrabPay, Boost',
    },
    {
      'id': 'online_banking',
      'name': 'Online Banking',
      'icon': Icons.computer,
      'description': 'FPX, Maybank2u, CIMB Clicks',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fetchServiceInstallmentRules();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardholderNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchServiceInstallmentRules() async {
    try {
      final response = await Supabase.instance.client
          .from('vendor_services')
          .select('installment_enabled, deposit_percentage, max_installments, payment_deadline_days, late_fee_percentage')
          .eq('id', widget.serviceId)
          .single();
      
      if (mounted) {
        setState(() {
          _installmentEnabled = response['installment_enabled'] ?? false;
          _depositPercentage = (response['deposit_percentage'] as num?)?.toDouble() ?? 30.0;
          _maxInstallments = (response['max_installments'] as num?)?.toInt() ?? 3;
          _selectedInstallments = _maxInstallments > 1 ? _maxInstallments : 2;
          _paymentDeadlineDays = (response['payment_deadline_days'] as num?)?.toInt() ?? 14;
          _lateFeePercentage = (response['late_fee_percentage'] as num?)?.toDouble() ?? 0.0;
          _isLoadingRules = false;
          _calculateInstallmentSchedule();
          _enforcePaymentPlanRules();
        });
      }
    } catch (e) {
      print("Error fetching service installment rules: $e");
      if (mounted) {
        setState(() {
          _isLoadingRules = false;
          _enforcePaymentPlanRules();
        });
      }
    }
  }

  void _calculateInstallmentSchedule() {
    final total = widget.amount * 1.11;
    final eventDate = widget.bookingDetails['date'] as DateTime?;
    if (eventDate == null) return;

    final today = DateTime.now();
    final finalDeadline = eventDate.subtract(Duration(days: _paymentDeadlineDays));
    
    _installmentSchedule = [];

    // Part 1: Deposit (Today)
    final depositAmount = total * (_depositPercentage / 100);
    _installmentSchedule.add({
      'name': 'Initial Deposit',
      'amount': depositAmount,
      'due_date': today,
      'status': 'pending',
    });

    if (_selectedInstallments > 1) {
      final remainingAmount = total - depositAmount;
      final remainingParts = _selectedInstallments - 1;
      final partAmount = remainingAmount / remainingParts;

      final totalInterval = finalDeadline.difference(today).inDays;
      // Ensure we don't have negative intervals
      final safeInterval = totalInterval > 0 ? totalInterval : 1;
      final intervalPerPart = remainingParts > 1 ? safeInterval / remainingParts : safeInterval;

      for (int i = 1; i <= remainingParts; i++) {
        final dueDate = today.add(Duration(days: (intervalPerPart * i).toInt()));
        
        String stepName;
        if (i == remainingParts) {
          stepName = 'Final Payment';
        } else {
          stepName = 'Installment $i';
        }

        _installmentSchedule.add({
          'name': stepName,
          'amount': partAmount,
          'due_date': dueDate.isAfter(finalDeadline) ? finalDeadline : dueDate,
          'status': 'pending',
        });
      }
    }
  }

  void _enforcePaymentPlanRules() {
    final total = widget.amount * 1.11;
    
    // Platform Strategy: For high-value bookings (> RM 5,000), 
    // we enable installments even if vendor settings are disabled.
    // This serves as a safety net for misconfigured services.
    if (total > 5000 && !_installmentEnabled) {
      _installmentEnabled = true;
      // Use standard platform defaults if vendor hasn't set them
      if (_maxInstallments < 2) _maxInstallments = 3;
      _selectedInstallments = _maxInstallments;
      _calculateInstallmentSchedule(); // Re-calculate with new rules
    }

    if (!_installmentEnabled) {
      _selectedPaymentPlan = 'full';
      return;
    }

    if (total > 5000) {
      _selectedPaymentPlan = 'installment';
    } else if (total < 1000) {
      // For < 1000, we generally force full payment unless vendor specifically enabled installments
      // In this case, we'll keep the vendor's choice if total is small but they want installments
      if (!_installmentEnabled) {
        _selectedPaymentPlan = 'full';
      }
    } else {
      _selectedPaymentPlan = 'deposit'; // Default for 1000-5000
    }
  }

  double get _amountToPayNow {
    final total = widget.amount * 1.11;
    if (_selectedPaymentPlan == 'full') {
      return total;
    } else if (_selectedPaymentPlan == 'deposit' || _selectedPaymentPlan == 'installment') {
      if (_installmentSchedule.isNotEmpty) {
        return _installmentSchedule.first['amount'];
      }
      return total * (_depositPercentage / 100);
    }
    return total;
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: 24),
            _buildPaymentPlanSelector(),
            const SizedBox(height: 24),
            _buildPaymentMethods(),
            const SizedBox(height: 24),
            if (_selectedPaymentMethod == 'credit_card') _buildCreditCardForm(),
            const SizedBox(height: 24),
            _buildPaymentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    print("DEBUG: PaymentScreen bookingDetails: ${widget.bookingDetails}");
    try {
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildSummaryRow('Service', widget.bookingDetails['service']?.toString() ?? 'N/A'),
            _buildSummaryRow('Date', widget.bookingDetails['date'] != null ? '${(widget.bookingDetails['date'] as DateTime).day}/${(widget.bookingDetails['date'] as DateTime).month}/${(widget.bookingDetails['date'] as DateTime).year}' : 'N/A'),
            _buildSummaryRow('Time', widget.bookingDetails['time'] != null ? (widget.bookingDetails['time'] as TimeOfDay).format(context) : 'N/A'),
            _buildSummaryRow('Duration', widget.bookingDetails['duration']?.toString() ?? 'N/A'),
            if (widget.bookingDetails['location'] != null && widget.bookingDetails['location'].toString().isNotEmpty)
              _buildSummaryRow('Location', widget.bookingDetails['location']),
            const Divider(height: 32),
            _buildSummaryRow('Subtotal', 'RM ${widget.amount.toStringAsFixed(2)}'),
            _buildSummaryRow('Service Fee', 'RM ${(widget.amount * 0.05).toStringAsFixed(2)}'),
            _buildSummaryRow('Tax', 'RM ${(widget.amount * 0.06).toStringAsFixed(2)}'),
            const Divider(height: 32),
            _buildSummaryRow(
              'Total',
              'RM ${(widget.amount * 1.11).toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      );
    } catch (e, stack) {
      print("ERROR in _buildOrderSummary: $e");
      print(stack);
      return Center(child: Text("Error loading summary: $e"));
    }
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

  Widget _buildPaymentPlanSelector() {
    if (_isLoadingRules) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Text("Fetching payment options..."),
            ],
          ),
        ),
      );
    }

    final total = widget.amount * 1.11;
    final isSmall = total < 1000;
    final isMedium = total >= 1000 && total <= 5000;
    
    // We only force installments for high value services if the vendor enabled it
    final isLarge = total > 5000 && _installmentEnabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Payment Plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            if (isLarge)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Recommended for > RM 5K',
                  style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              // Show Full Payment always as an option unless forced
              _buildPlanRadio(
                'full',
                'Pay in Full',
                'RM ${total.toStringAsFixed(2)} today',
              ),
              
              if (_installmentEnabled && !isSmall) ...[
                const Divider(height: 1),
                _buildPlanRadio(
                  isLarge ? 'installment' : 'deposit',
                  isLarge ? '$_maxInstallments-Part Installment Plan' : 'Pay $_depositPercentage% Deposit',
                  isLarge 
                    ? 'Spread payments over time' 
                    : 'RM ${(total * (_depositPercentage / 100)).toStringAsFixed(2)} today, remainder later',
                ),
                
                // Detailed Schedule for installments
                if ((_selectedPaymentPlan == 'installment' || _selectedPaymentPlan == 'deposit') && _installmentSchedule.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Duration Selector (only if > 2 max installments)
                        if (_maxInstallments > 2) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Number of installments:", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                              Text("$_selectedInstallments", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                            ],
                          ),
                          Slider(
                            value: _selectedInstallments.toDouble(),
                            min: 2,
                            max: _maxInstallments.toDouble(),
                            divisions: _maxInstallments - 2,
                            activeColor: AppTheme.primaryColor,
                            onChanged: (val) {
                              setState(() {
                                _selectedInstallments = val.toInt();
                                _calculateInstallmentSchedule();
                              });
                            },
                          ),
                        ],
                        
                        // Policy Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: const [
                                  Icon(Icons.info_outline, size: 16, color: Colors.amber),
                                  SizedBox(width: 8),
                                  Text("Installment Policy", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _buildPolicyRow("Deposit Required", "$_depositPercentage%"),
                              _buildPolicyRow("Payment Deadline", "$_paymentDeadlineDays days before event"),
                              if (_lateFeePercentage > 0)
                                _buildPolicyRow("Late Fee", "$_lateFeePercentage%"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Detailed Schedule
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Payment Schedule",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(height: 12),
                              ..._installmentSchedule.asMap().entries.map((entry) {
                                final idx = entry.key;
                                final step = entry.value;
                                final date = step['due_date'] as DateTime;
                                final amount = step['amount'] as double;
                                final name = step['name'] as String;
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          Text(
                                            idx == 0 ? "Due Today" : "Due ${date.day}/${date.month}/${date.year}",
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "RM ${amount.toStringAsFixed(2)}",
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPolicyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildPlanRadio(String value, String title, String subtitle) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedPaymentPlan,
      activeColor: AppTheme.primaryColor,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedPaymentPlan = newValue;
          });
        }
      },
      controlAffinity: ListTileControlAffinity.trailing,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)).toList(),
      ],
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method['id'];
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  method['icon'],
                  color: isSelected ? Colors.white : AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      method['description'],
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCardForm() {
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
            'Card Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildCardField('Card Number', _cardNumberController, Icons.credit_card, '1234 5678 9012 3456'),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildCardField('Expiry', _expiryController, Icons.calendar_today, 'MM/YY'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildCardField('CVV', _cvvController, Icons.security, '123'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCardField('Cardholder Name', _cardholderNameController, Icons.person, 'John Doe'),
        ],
      ),
    );
  }

  Widget _buildCardField(String label, TextEditingController controller, IconData icon, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppTheme.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
      ],
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
                'Pay RM ${_amountToPayNow.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }


  void _processPayment() async {
    print("DEBUG: _processPayment started");
    setState(() {
      _isProcessing = true;
    });

    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      print("DEBUG: User logged in: ${currentUser.id}");
      print("DEBUG: bookingDetails keys: ${widget.bookingDetails.keys}");

      // Calculate start and end times
      // Add '?' check for date and time to avoid crashes if they are somehow null here too
      if (widget.bookingDetails['date'] == null || widget.bookingDetails['time'] == null) {
        throw Exception("Missing booking date or time");
      }

      final date = widget.bookingDetails['date'] as DateTime;
      final time = widget.bookingDetails['time'] as TimeOfDay;
      final startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);

      int durationMinutes = 60;
      final durationStr = widget.bookingDetails['duration']?.toString() ?? '1 hour';
      if (durationStr.contains('minutes')) {
        durationMinutes = int.tryParse(durationStr.split(' ')[0]) ?? 30;
      } else if (durationStr.contains('hour')) {
         final val = double.tryParse(durationStr.split(' ')[0]) ?? 1.0;
         durationMinutes = (val * 60).toInt();
      } else if (durationStr == 'Full day') {
        durationMinutes = 8 * 60;
      }
      
      final endTime = startTime.add(Duration(minutes: durationMinutes));
      
      final totalAmount = widget.amount * 1.11;
      
      // Determine if this is paying for an EXISTING booking or creating a NEW one.
      // If 'bookingId' exists in bookingDetails, we are paying for an existing one.
      String bookingId;
      
      if (widget.bookingDetails.containsKey('bookingId')) {
         bookingId = widget.bookingDetails['bookingId'];
         print("DEBUG: Paying for existing booking ID: $bookingId. Updating total_amount to $totalAmount");
         
         // Update existing booking with gross amount and correct status
         await Supabase.instance.client.from('bookings').update({
           'total_amount': totalAmount,
           'deposit_amount': _amountToPayNow,
           'status': 'awaiting_payment',
           'booking_details': {
             ...widget.bookingDetails.map((key, value) {
               if (value is DateTime || value is TimeOfDay) return MapEntry(key, value.toString());
               return MapEntry(key, value);
             }),
             'payment_plan': _selectedPaymentPlan,
             'installment_schedule': _installmentSchedule.map((s) => {
               ...s,
               'due_date': (s['due_date'] as DateTime).toIso8601String(),
             }).toList(),
           },
           'updated_at': DateTime.now().toIso8601String(),
         }).eq('id', bookingId);
         
      } else {
         print("DEBUG: Creating NEW booking record...");
         // Insert into Supabase and get ID
         final bookingResponse = await Supabase.instance.client.from('bookings').insert({
          'customer_id': currentUser.id,
          'vendor_id': widget.vendor.id,
          'service_id': widget.serviceId,
          'event_date': date.toIso8601String(),
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'guest_count': widget.bookingDetails['guestCount'] ?? 0,
          'total_amount': totalAmount,
          'deposit_amount': _amountToPayNow, // Use dynamic selected downpayment
          'status': 'pending_payment', 
          'special_requests': widget.bookingDetails['notes'],
          'booking_details': {
              ...widget.bookingDetails.map((key, value) {
                if (value is DateTime || value is TimeOfDay) return MapEntry(key, value.toString());
                return MapEntry(key, value);
              }),
              'payment_plan': _selectedPaymentPlan,
              'installment_schedule': _installmentSchedule.map((s) => {
                ...s,
                'due_date': (s['due_date'] as DateTime).toIso8601String(),
              }).toList(),
           },
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
         }).select().single();
         
         bookingId = bookingResponse['id'];
         print("DEBUG: New booking created with ID: $bookingId");
      }

      // Initiate Payment
      if (!mounted) return;
      
      final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
      
      // Get user details for Billplz
      final email = currentUser.email ?? 'customer@example.com';
      final phone = currentUser.userMetadata?['phone'] as String? ?? '0123456789'; // Fallback
      final name = currentUser.userMetadata?['full_name'] as String? ?? 'Valued Customer';

      print("DEBUG: Initiating payment process for RM $_amountToPayNow");

      final paymentUrl = await paymentProvider.processPayment(
        bookingId: bookingId,
        customerId: currentUser.id,
        vendorId: widget.vendor.id,
        amount: _amountToPayNow, 
        method: PaymentMethod.onlineBanking, // Default to online banking for Billplz or map from _selectedPaymentMethod
        email: email,
        mobile: phone,
        name: name,
        description: 'Payment for booking #$bookingId',
      );
      
      print("DEBUG: Payment URL generated: $paymentUrl");

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      if (paymentUrl != null) {
        // Launch Billplz URL
        final Uri url = Uri.parse(paymentUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(
                vendor: widget.vendor,
                serviceId: widget.serviceId,
                eventId: widget.eventId,
                amount: widget.amount,
                bookingDetails: {
                  ...widget.bookingDetails,
                  'bookingId': bookingId,
                },
                paymentMethod: _selectedPaymentMethod,
              ),
            ),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment page opened. Please complete payment.')),
          );
        } else {
          throw Exception('Could not launch payment URL: $paymentUrl');
        }
      } else {
        throw Exception('Failed to generate payment URL (returned null)');
      }

    } catch (e, stack) {
      print("ERROR in _processPayment: $e");
      print("STACK TRACE: $stack");
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to process payment: $e')),
      );
    }
  }
}













