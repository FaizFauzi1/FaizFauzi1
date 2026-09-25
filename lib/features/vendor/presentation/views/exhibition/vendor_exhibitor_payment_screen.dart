import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/models/exhibitor_vendor.dart';
import 'package:eventease/features/organizer/data/repositories/organizer_repository.dart';

class VendorExhibitorPaymentScreen extends StatefulWidget {
  final ExhibitorVendor application;

  const VendorExhibitorPaymentScreen({
    super.key,
    required this.application,
  });

  static const routeName = '/vendor-exhibitor-payment';

  @override
  State<VendorExhibitorPaymentScreen> createState() => _VendorExhibitorPaymentScreenState();
}

class _VendorExhibitorPaymentScreenState extends State<VendorExhibitorPaymentScreen> {
  late ExhibitorVendor _app;
  String _selectedMethod = 'fpx'; // 'fpx', 'card', 'ewallet'
  String _selectedBank = 'Maybank2u';
  String _selectedWallet = "Touch 'n Go eWallet";
  bool _isProcessing = false;
  bool _agreedToTerms = true;
  bool _payDepositOnly = false;

  final List<Map<String, String>> _banks = [
    {'id': 'maybank', 'name': 'Maybank2u', 'logo': '🏦'},
    {'id': 'cimb', 'name': 'CIMB Clicks', 'logo': '🏛️'},
    {'id': 'public', 'name': 'Public Bank', 'logo': '🏢'},
    {'id': 'rhb', 'name': 'RHB Now', 'logo': '🏧'},
    {'id': 'hongleong', 'name': 'Hong Leong Connect', 'logo': '💳'},
    {'id': 'ambank', 'name': 'AmOnline', 'logo': '💰'},
  ];

  final List<Map<String, String>> _wallets = [
    {'id': 'tng', 'name': "Touch 'n Go eWallet", 'logo': '📱'},
    {'id': 'grab', 'name': 'GrabPay', 'logo': '🟢'},
    {'id': 'boost', 'name': 'Boost', 'logo': '⚡'},
  ];

  @override
  void initState() {
    super.initState();
    _app = widget.application;
  }

  double get _totalDue {
    final remaining = _app.boothFeeRm - _app.paidRm;
    return remaining > 0 ? remaining : _app.boothFeeRm;
  }

  double get _payableAmount {
    if (_payDepositOnly) {
      return (_totalDue * 0.5); // 50% deposit
    }
    return _totalDue;
  }

  Future<void> _processPayment() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the exhibitor payment terms')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Simulate banking network roundtrip
      await Future.delayed(const Duration(milliseconds: 1400));

      final amountPaid = _payableAmount;
      final paymentMethodStr = switch (_selectedMethod) {
        'fpx' => 'FPX - $_selectedBank',
        'card' => 'Credit/Debit Card (Online)',
        'ewallet' => 'E-Wallet - $_selectedWallet',
        _ => 'Online Transfer',
      };

      await OrganizerRepository.instance.payExhibitorFee(
        _app.id,
        amount: amountPaid,
        paymentMethod: paymentMethodStr,
      );

      final updated = _app.copyWith(
        paidRm: (_app.paidRm + amountPaid).clamp(0.0, _app.boothFeeRm),
        paymentStatus: (_app.paidRm + amountPaid) >= _app.boothFeeRm ? PaymentStatus.paid : PaymentStatus.partial,
        status: (_app.paidRm + amountPaid) >= _app.boothFeeRm ? ExhibitorStatus.confirmed : ExhibitorStatus.paymentPending,
      );

      if (!mounted) return;
      setState(() {
        _app = updated;
        _isProcessing = false;
      });

      _showSuccessDialog(updated, paymentMethodStr, amountPaid);
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showSuccessDialog(ExhibitorVendor confirmedApp, String method, double amount) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 44),
            ),
            const SizedBox(height: 16),
            const Text(
              'Payment Successful!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'Your exhibitor booth is now confirmed',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),

            // Receipt summary box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _receiptRow('Event', _app.expoName ?? 'Exhibition'),
                  _receiptRow('Booth Assigned', _app.boothNumber ?? 'Booth Confirmed'),
                  _receiptRow('Package', _app.packageName ?? 'Exhibitor'),
                  _receiptRow('Amount Paid', currency.format(amount), isBold: true),
                  _receiptRow('Payment Method', method),
                  _receiptRow('Transaction ID', 'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'),
                  _receiptRow('Date', DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Receipt downloaded to device')),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Receipt'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF334155),
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pushReplacementNamed(
                        context,
                        '/vendor-exhibition-dashboard',
                        arguments: confirmedApp,
                      );
                    },
                    icon: const Icon(Icons.dashboard_rounded, size: 18),
                    label: const Text('Go to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String title, String val, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Flexible(
            child: Text(
              val,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: isBold ? const Color(0xFF059669) : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Exhibitor Fee Payment', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, _app),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Header
            _buildInvoiceSummary(currency),
            const SizedBox(height: 24),

            // Payment Split / Option (Full vs 50% Deposit)
            _buildPaymentOption(),
            const SizedBox(height: 24),

            // Payment Methods
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),
            _buildMethodTabs(),
            const SizedBox(height: 16),

            // Method-specific configuration
            if (_selectedMethod == 'fpx') _buildFpxSelector(),
            if (_selectedMethod == 'card') _buildCardForm(),
            if (_selectedMethod == 'ewallet') _buildEwalletSelector(),

            const SizedBox(height: 24),

            // Terms Checkbox
            _buildTermsCheckbox(),
            const SizedBox(height: 28),

            // Pay Action Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                child: _isProcessing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text('Securing Payment...', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline_rounded, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pay ${currency.format(_payableAmount)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, size: 15, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text(
                    '256-bit Bank Grade Encrypted · Instant Confirmation',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceSummary(NumberFormat currency) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.receipt_long_rounded, color: AppTheme.primaryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _app.expoName ?? 'Exhibition',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Booth ${_app.boothNumber ?? "Pending"} · ${_app.packageName ?? "Exhibitor Package"}',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),
          _summaryRow('Booth Package Fee', currency.format(_app.boothFeeRm)),
          if (_app.paidRm > 0)
            _summaryRow('Previously Paid', '- ${currency.format(_app.paidRm)}', color: const Color(0xFF059669)),
          _summaryRow('SST / Tax (8%)', 'Included', isFaded: true),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Outstanding',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                ),
                Text(
                  currency.format(_totalDue),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF059669)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {Color? color, bool isFaded = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isFaded ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color ?? (isFaded ? const Color(0xFF94A3B8) : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Radio<bool>(
            value: false,
            groupValue: _payDepositOnly,
            onChanged: (v) => setState(() => _payDepositOnly = v ?? false),
            activeColor: AppTheme.primaryColor,
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Full Payment (Recommended)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Instant confirmation and booth lock', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Radio<bool>(
            value: true,
            groupValue: _payDepositOnly,
            onChanged: (v) => setState(() => _payDepositOnly = v ?? false),
            activeColor: AppTheme.primaryColor,
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('50% Deposit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Balance before move-in', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTabs() {
    final methods = [
      {'id': 'fpx', 'title': 'FPX Banking', 'icon': Icons.account_balance_rounded},
      {'id': 'card', 'title': 'Card', 'icon': Icons.credit_card_rounded},
      {'id': 'ewallet', 'title': 'E-Wallet', 'icon': Icons.account_balance_wallet_rounded},
    ];

    return Row(
      children: methods.map((m) {
        final isSelected = _selectedMethod == m['id'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedMethod = m['id'] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.08) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    m['icon'] as IconData,
                    color: isSelected ? AppTheme.primaryColor : const Color(0xFF64748B),
                    size: 24,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    m['title'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? AppTheme.primaryColor : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFpxSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Your Bank', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _banks.length,
            itemBuilder: (ctx, i) {
              final bank = _banks[i];
              final isSelected = _selectedBank == bank['name'];
              return InkWell(
                onTap: () => setState(() => _selectedBank = bank['name']!),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(bank['logo']!, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bank['name']!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? AppTheme.primaryColor : const Color(0xFF1E293B),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          TextFormField(
            initialValue: '4532 •••• •••• 8821',
            decoration: InputDecoration(
              labelText: 'Card Number',
              prefixIcon: const Icon(Icons.credit_card),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: '12/28',
                  decoration: InputDecoration(
                    labelText: 'MM / YY',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: '•••',
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: _app.companyName,
            decoration: InputDecoration(
              labelText: 'Cardholder Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEwalletSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: _wallets.map((w) {
          final isSelected = _selectedWallet == w['name'];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
              ),
            ),
            child: RadioListTile<String>(
              value: w['name']!,
              groupValue: _selectedWallet,
              onChanged: (v) => setState(() => _selectedWallet = v!),
              title: Row(
                children: [
                  Text(w['logo']!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Text(w['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                ],
              ),
              activeColor: AppTheme.primaryColor,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
            activeColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'I agree to the Expo Exhibitor Rules & Regulations, Booth Terms, and Cancellation & Refund Policy.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
          ),
        ),
      ],
    );
  }
}
