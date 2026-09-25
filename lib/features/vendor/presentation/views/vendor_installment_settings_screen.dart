import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:eventease/features/vendor/data/models/vendor_installment_settings.dart';

/// Vendor screen for configuring installment payment options
/// Allows vendors to set deposit %, installments, minimum amount, and payment deadline
class VendorInstallmentSettingsScreen extends StatefulWidget {
  final String vendorId;

  const VendorInstallmentSettingsScreen({
    Key? key,
    required this.vendorId,
  }) : super(key: key);

  @override
  State<VendorInstallmentSettingsScreen> createState() =>
      _VendorInstallmentSettingsScreenState();
}

class _VendorInstallmentSettingsScreenState
    extends State<VendorInstallmentSettingsScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  VendorInstallmentSettings? _settings;

  bool _installmentsEnabled = false;
  double _depositPercentage = 30.0;
  int _numberOfInstallments = 5;
  double _minimumOrderAmount = 1000.0;
  int _paymentDeadlineDays = 30;
  bool _allowCustomPlans = false;
  bool _lateFeeEnabled = false;
  double _lateFeePercentage = 5.0;

  final _minimumAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // TODO: Load vendor's existing settings from database
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      final settings = await vendorProvider.getInstallmentSettings(widget.vendorId);
      
      if (settings != null) {
        setState(() {
          _settings = settings;
          _installmentsEnabled = settings.isEnabled;
          _depositPercentage = settings.depositPercentage;
          _numberOfInstallments = settings.maxInstallments;
          _minimumOrderAmount = settings.minOrderAmount;
          _paymentDeadlineDays = settings.paymentDeadlineDays;
          _allowCustomPlans = settings.allowCustomPlans;
          _lateFeePercentage = settings.lateFeePercentage;
          _lateFeeEnabled = settings.lateFeePercentage > 0;
          _minimumAmountController.text = settings.minOrderAmount.toStringAsFixed(0);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      
      final updatedSettings = (_settings ?? VendorInstallmentSettings.defaultSettings(widget.vendorId)).copyWith(
        isEnabled: _installmentsEnabled,
        depositPercentage: _depositPercentage,
        maxInstallments: _numberOfInstallments,
        minOrderAmount: double.tryParse(_minimumAmountController.text) ?? _minimumOrderAmount,
        paymentDeadlineDays: _paymentDeadlineDays,
        allowCustomPlans: _allowCustomPlans,
        lateFeePercentage: _lateFeeEnabled ? _lateFeePercentage : 0.0,
      );

      final success = await vendorProvider.saveInstallmentSettings(updatedSettings);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to save settings'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Installment Settings',
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Configure Payment Plans',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Set your installment payment options for customers',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 32),

            // Enable/Disable Toggle
            _buildEnableToggle(),
            const SizedBox(height: 24),

            if (_installmentsEnabled) ...[
              // Global Settings
              _buildGlobalSettings(),
              const SizedBox(height: 24),

              // Payment Deadline
              _buildPaymentDeadline(),
              const SizedBox(height: 24),

              // Preview
              _buildPreview(),
              const SizedBox(height: 24),

              // Advanced Options
              _buildAdvancedOptions(),
              const SizedBox(height: 32),
            ],

            // Save Button
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnableToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _installmentsEnabled
                  ? AppTheme.primaryColor.withOpacity(0.1)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.payment,
              color: _installmentsEnabled ? AppTheme.primaryColor : Colors.grey,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enable Installment Payments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _installmentsEnabled
                      ? 'Customers can pay in installments'
                      : 'Only full payment accepted',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _installmentsEnabled,
            onChanged: (value) {
              setState(() {
                _installmentsEnabled = value;
              });
            },
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            'Payment Plan Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 20),

          // Deposit Percentage
          const Text(
            'Deposit Percentage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _depositPercentage,
                  min: 10,
                  max: 50,
                  divisions: 8,
                  label: '${_depositPercentage.toInt()}%',
                  onChanged: (value) {
                    setState(() {
                      _depositPercentage = value;
                    });
                  },
                  activeColor: AppTheme.primaryColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${_depositPercentage.toInt()}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Number of Installments
          const Text(
            'Number of Installments',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [3, 4, 5, 6].map((months) {
              final isSelected = _numberOfInstallments == months;
              return ChoiceChip(
                label: Text('$months months'),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _numberOfInstallments = months;
                  });
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                labelStyle: TextStyle(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Minimum Order Amount
          const Text(
            'Minimum Order Amount',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _minimumAmountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              prefixText: 'RM ',
              hintText: '1000',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _minimumOrderAmount = double.tryParse(value) ?? 1000;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDeadline() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Payment Completion Deadline',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Require customers to complete all payments before the event date',
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange.shade900,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Full payment required',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              {'days': 7, 'label': '1 Week Before'},
              {'days': 14, 'label': '2 Weeks Before'},
              {'days': 30, 'label': '1 Month Before'},
            ].map((option) {
              final days = option['days'] as int;
              final label = option['label'] as String;
              final isSelected = _paymentDeadlineDays == days;
              return ChoiceChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _paymentDeadlineDays = days;
                  });
                },
                selectedColor: Colors.orange.shade200,
                backgroundColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.orange.shade900 : AppTheme.textSecondaryColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Customers must complete final payment $_paymentDeadlineDays days before their event',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final exampleAmount = 5000.0;
    final deposit = exampleAmount * (_depositPercentage / 100);
    final remaining = exampleAmount - deposit;
    final monthlyPayment = remaining / _numberOfInstallments;

    return Container(
      padding: const EdgeInsets.all(20),
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
              Icon(Icons.preview, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Example Payment Plan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'For a booking of RM ${exampleAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 16),
          _buildPreviewRow('Deposit (${_depositPercentage.toInt()}%)', 'RM ${deposit.toStringAsFixed(2)}', true),
          _buildPreviewRow('Remaining Balance', 'RM ${remaining.toStringAsFixed(2)}'),
          _buildPreviewRow('Monthly Payment', 'RM ${monthlyPayment.toStringAsFixed(2)}'),
          _buildPreviewRow('Number of Payments', '$_numberOfInstallments months'),
          const Divider(height: 24),
          Row(
            children: [
              Icon(Icons.event, size: 14, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Final payment due $_paymentDeadlineDays days before event',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value, [bool highlight = false]) {
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

  Widget _buildAdvancedOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            'Advanced Options',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Allow Custom Payment Plans'),
            subtitle: const Text('Let customers request custom schedules'),
            value: _allowCustomPlans,
            onChanged: (value) {
              setState(() {
                _allowCustomPlans = value;
              });
            },
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Enable Late Fees'),
            subtitle: Text('Charge ${_lateFeePercentage.toInt()}% for late payments'),
            value: _lateFeeEnabled,
            onChanged: (value) {
              setState(() {
                _lateFeeEnabled = value;
              });
            },
            activeColor: AppTheme.primaryColor,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Save Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _minimumAmountController.dispose();
    super.dispose();
  }
}
