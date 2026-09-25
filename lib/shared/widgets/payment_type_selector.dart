import 'package:eventease/features/booking/data/models/installment_plan.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/data/models/vendor_installment_settings.dart';
import 'package:eventease/features/vendor/models/vendor_service.dart';
import 'package:eventease/core/services/installment_service.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/utils/currency_formatter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

/// Widget for selecting payment type (Full or Installment) during booking
class PaymentTypeSelector extends StatefulWidget {
  final double totalAmount;
  final String vendorId;
  final VendorService? service;
  final Function(bool useInstallment, InstallmentPlan? plan) onPaymentTypeChanged;

  const PaymentTypeSelector({
    Key? key,
    required this.totalAmount,
    required this.vendorId,
    this.service,
    required this.onPaymentTypeChanged,
  }) : super(key: key);

  @override
  State<PaymentTypeSelector> createState() => _PaymentTypeSelectorState();
}

class _PaymentTypeSelectorState extends State<PaymentTypeSelector> {
  bool _useInstallment = false;
  InstallmentPlan? _selectedPlan;
  VendorInstallmentSettings? _vendorSettings;
  bool _isLoading = true;
  final _installmentService = InstallmentService();

  @override
  void initState() {
    super.initState();
    _loadVendorSettings();
  }

  Future<void> _loadVendorSettings() async {
    setState(() => _isLoading = true);
    try {
      if (widget.service?.installmentEnabled == true) {
        // Use service-specific settings
        _vendorSettings = VendorInstallmentSettings(
          id: 'service-${widget.service!.id}',
          vendorId: widget.vendorId,
          isEnabled: true,
          depositPercentage: widget.service!.depositPercentage ?? 30.0,
          maxInstallments: widget.service!.maxInstallments ?? 5,
          minOrderAmount: 0,
          paymentDeadlineDays: widget.service!.paymentDeadlineDays ?? 14,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        // Fallback to global vendor settings
        final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
        _vendorSettings = await vendorProvider.getInstallmentSettings(widget.vendorId);
      }
      
      // Calculate plan based on settings
      _selectedPlan = _installmentService.calculateMVPPlan(
        totalAmount: widget.totalAmount,
        bookingId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        settings: _vendorSettings,
      );
    } catch (e) {
      print('Error loading vendor installment settings: $e');
      // Fallback to default plan
      _selectedPlan = _installmentService.calculateMVPPlan(
        totalAmount: widget.totalAmount,
        bookingId: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If installments are disabled by vendor, only show full payment option
    final installmentsVisible = _vendorSettings?.isEnabled ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Full Payment Option
        _buildPaymentTypeCard(
          isSelected: !_useInstallment,
          icon: Icons.payment,
          title: 'Pay in Full',
          subtitle: 'Pay the total amount now',
          amount: widget.totalAmount,
          onTap: () {
            setState(() {
              _useInstallment = false;
            });
            widget.onPaymentTypeChanged(false, null);
          },
        ),
        
        if (installmentsVisible) ...[
          const SizedBox(height: 12),
          
          // Installment Payment Option
          _buildPaymentTypeCard(
            isSelected: _useInstallment,
            icon: Icons.calendar_month,
            title: 'Pay in Installments',
            subtitle: 'Split payment into ${_selectedPlan?.numberOfInstallments ?? 5} months',
            amount: _selectedPlan?.depositAmount ?? 0,
            badge: 'Popular',
            onTap: () {
              setState(() {
                _useInstallment = true;
              });
              widget.onPaymentTypeChanged(true, _selectedPlan);
            },
          ),
        ],
        
        // Installment Details (shown when installment is selected)
        if (_useInstallment && _selectedPlan != null) ...[
          const SizedBox(height: 16),
          _buildInstallmentDetails(),
        ],
      ],
    );
  }

  Widget _buildPaymentTypeCard({
    required bool isSelected,
    required IconData icon,
    required String title,
    required String subtitle,
    required double amount,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Stack(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? AppTheme.primaryColor.withOpacity(0.2)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Pay now: ${CurrencyFormatter.symbol} ${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<bool>(
                  value: true,
                  groupValue: isSelected,
                  onChanged: (_) => onTap(),
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
            if (badge != null)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallmentDetails() {
    if (_selectedPlan == null) return const SizedBox.shrink();

    final schedule = _installmentService.generatePaymentSchedule(_selectedPlan!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Installment Plan Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Summary
          _buildDetailRow('Total Amount', '${CurrencyFormatter.symbol} ${_selectedPlan!.totalAmount.toStringAsFixed(2)}'),
          _buildDetailRow(
            'Deposit (${(_selectedPlan!.depositAmount / _selectedPlan!.totalAmount * 100).toInt()}%)', 
            '${CurrencyFormatter.symbol} ${_selectedPlan!.depositAmount.toStringAsFixed(2)}', 
            highlight: true
          ),
          _buildDetailRow('Remaining Balance', '${CurrencyFormatter.symbol} ${_selectedPlan!.remainingBalance.toStringAsFixed(2)}'),
          _buildDetailRow('Number of Installments', '${_selectedPlan!.numberOfInstallments} months'),
          _buildDetailRow(
            'Monthly Payment',
            '${CurrencyFormatter.symbol} ${(_selectedPlan!.remainingBalance / _selectedPlan!.numberOfInstallments).toStringAsFixed(2)}',
          ),
          
          const Divider(height: 24),
          
          // Payment Schedule Preview
          const Text(
            'Payment Schedule',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          
          ...schedule.take(3).map((payment) {
            final dueDate = payment['dueDate'] as DateTime;
            final amount = payment['amount'] as double;
            final installmentNumber = payment['installmentNumber'] as int;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$installmentNumber',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      DateFormat('MMM dd, yyyy').format(dueDate),
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ),
                  Text(
                    '${CurrencyFormatter.symbol} ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          if (schedule.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+ ${schedule.length - 3} more payments',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: highlight ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
              fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: highlight ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
