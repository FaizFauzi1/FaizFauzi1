import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:eventease/features/finance/data/providers/commission_provider.dart';
import 'package:eventease/features/finance/data/models/commission.dart';

class CommissionManagementScreen extends StatefulWidget {
  const CommissionManagementScreen({super.key});

  @override
  State<CommissionManagementScreen> createState() => _CommissionManagementScreenState();
}

class _CommissionManagementScreenState extends State<CommissionManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Commission Management',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Rates', icon: Icon(Icons.percent)),
            Tab(text: 'Transactions', icon: Icon(Icons.receipt)),
            Tab(text: 'Payments', icon: Icon(Icons.payment)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildRatesTab(),
          _buildTransactionsTab(),
          _buildPaymentsTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<CommissionProvider>(
      builder: (context, commissionProvider, child) {
        final pendingPayments = commissionProvider.getTotalPendingPayments();
        final totalTransactions = commissionProvider.commissionTransactions.length;
        final pendingTransactions = commissionProvider.getPendingPayments().length;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Commission Overview',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 20),

              // Summary Cards
              GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.1,
                children: [
                  _buildSummaryCard(
                    'Total Txns',
                    totalTransactions.toString(),
                    Icons.receipt,
                    AppTheme.primaryColor,
                    [2, 4, 3, 5, 4, 6],
                  ),
                  _buildSummaryCard(
                    'Pending Pay',
                    'RM ${pendingPayments.toStringAsFixed(2)}',
                    Icons.pending,
                    Colors.orange,
                    [5, 3, 4, 2, 3, 1],
                  ),
                  _buildSummaryCard(
                    'In Process',
                    pendingTransactions.toString(),
                    Icons.schedule,
                    Colors.blue,
                    [1, 2, 3, 2, 4, 3],
                  ),
                  _buildSummaryCard(
                    'Active Rates',
                    commissionProvider.commissionRates.length.toString(),
                    Icons.percent,
                    Colors.green,
                    [4, 4, 4, 4, 4, 4],
                  ),
                ],
              ),

              const SizedBox(height: 32),
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 16),

              // Recent Transactions
              ...commissionProvider.commissionTransactions
                  .take(5)
                  .cast<CommissionTransaction>()
                  .map((transaction) => _buildTransactionCard(transaction))
                  .toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatesTab() {
    return Consumer<CommissionProvider>(
      builder: (context, commissionProvider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Commission Rates',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAddRateDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Rate'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: commissionProvider.commissionRates.length,
                itemBuilder: (context, index) {
                  final rate = commissionProvider.commissionRates[index];
                  return _buildRateCard(rate);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionsTab() {
    return Consumer<CommissionProvider>(
      builder: (context, commissionProvider, child) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Commission Transactions',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: commissionProvider.commissionTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = commissionProvider.commissionTransactions[index];
                  return _buildTransactionCard(transaction);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPaymentsTab() {
    return Consumer<CommissionProvider>(
      builder: (context, commissionProvider, child) {
        final pendingPayments = commissionProvider.getPendingPayments();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pending Payments',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  if (pendingPayments.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: () => _processBulkPayment(context, pendingPayments),
                      icon: const Icon(Icons.payment),
                      label: const Text('Process All'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: pendingPayments.isEmpty
                  ? const Center(
                      child: Text(
                        'No pending payments',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: pendingPayments.length,
                      itemBuilder: (context, index) {
                        final transaction = pendingPayments[index];
                        return _buildPaymentCard(transaction);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, List<double> sparkData) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 25,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: sparkData.length.toDouble() - 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: sparkData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.05),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateCard(CommissionRate rate) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.percent, color: AppTheme.primaryColor),
        title: Text('${rate.type.toString().split('.').last} - ${rate.vendorId == 'all' ? 'Default' : 'Vendor Specific'}'),
        subtitle: Text('${rate.percentage}% ${rate.fixedAmount != null ? '+ RM ${rate.fixedAmount}' : ''}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.secondaryColor),
              onPressed: () => _showEditRateDialog(context, rate),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              onPressed: () => _deleteRate(context, rate.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(CommissionTransaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.03)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking #${transaction.bookingId.substring(0, 8)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.3,
                ),
              ),
              _buildStatusChip(transaction.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.storefront, size: 14, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 4),
              Text(
                'Vendor: ${transaction.vendorId}',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor.withOpacity(0.8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL AMOUNT',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
                  ),
                  Text(
                    'RM ${transaction.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'VENDOR EARNINGS',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
                  ),
                  Text(
                    'RM ${transaction.vendorEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Processed on ${transaction.createdAt.toString().split(' ')[0]}',
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor.withOpacity(0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(CommissionTransaction transaction) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Booking #${transaction.bookingId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    'Vendor: ${transaction.vendorId}',
                    style: const TextStyle(color: AppTheme.textSecondaryColor),
                  ),
                  Text(
                    'Amount: RM ${transaction.vendorEarnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => _processPayment(context, transaction),
              child: const Text('Pay Now'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(CommissionStatus status) {
    Color color;
    String label;

    switch (status) {
      case CommissionStatus.pending:
        color = AppTheme.warningColor;
        label = 'PENDING';
        break;
      case CommissionStatus.paid:
        color = AppTheme.successColor;
        label = 'PAID';
        break;
      case CommissionStatus.cancelled:
        color = AppTheme.errorColor;
        label = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  void _showAddRateDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    CommissionType selectedType = CommissionType.booking;
    String vendorId = 'all';
    double percentage = 10.0;
    double? fixedAmount;
    bool isVendorSpecific = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Commission Rate'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vendor Specific Toggle
                  SwitchListTile(
                    title: const Text('Vendor Specific Rate'),
                    subtitle: const Text('Apply to specific vendor or use as default'),
                    value: isVendorSpecific,
                    onChanged: (value) {
                      setState(() {
                        isVendorSpecific = value;
                        vendorId = value ? '' : 'all';
                      });
                    },
                  ),

                  // Vendor ID Field (if vendor specific)
                  if (isVendorSpecific)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Vendor ID',
                        hintText: 'Enter vendor ID',
                      ),
                      validator: (value) {
                        if (isVendorSpecific && (value == null || value.isEmpty)) {
                          return 'Vendor ID is required';
                        }
                        return null;
                      },
                      onSaved: (value) => vendorId = value ?? '',
                    ),

                  const SizedBox(height: 16),

                  // Commission Type Dropdown
                  DropdownButtonFormField<CommissionType>(
                    decoration: const InputDecoration(
                      labelText: 'Commission Type',
                    ),
                    value: selectedType,
                    items: CommissionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Percentage Field
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Percentage (%)',
                      hintText: 'Enter percentage (e.g., 10.0)',
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: percentage.toString(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Percentage is required';
                      }
                      final percent = double.tryParse(value);
                      if (percent == null || percent < 0 || percent > 100) {
                        return 'Enter valid percentage (0-100)';
                      }
                      return null;
                    },
                    onSaved: (value) => percentage = double.parse(value!),
                  ),

                  const SizedBox(height: 16),

                  // Fixed Amount Field (Optional)
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Fixed Amount (RM) - Optional',
                      hintText: 'Additional fixed amount',
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (value) {
                      if (value != null && value.isNotEmpty) {
                        fixedAmount = double.tryParse(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  final rate = CommissionRate(
                    id: '${selectedType}_${vendorId}_${DateTime.now().millisecondsSinceEpoch}',
                    vendorId: vendorId,
                    type: selectedType,
                    percentage: percentage,
                    fixedAmount: fixedAmount,
                    effectiveFrom: DateTime.now(),
                  );

                  context.read<CommissionProvider>().addCommissionRate(rate);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Commission rate added successfully')),
                  );
                }
              },
              child: const Text('Add Rate'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRateDialog(BuildContext context, CommissionRate rate) {
    final formKey = GlobalKey<FormState>();
    CommissionType selectedType = rate.type;
    String vendorId = rate.vendorId;
    double percentage = rate.percentage;
    double? fixedAmount = rate.fixedAmount;
    bool isVendorSpecific = rate.vendorId != 'all';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Commission Rate'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vendor Specific Toggle
                  SwitchListTile(
                    title: const Text('Vendor Specific Rate'),
                    subtitle: const Text('Apply to specific vendor or use as default'),
                    value: isVendorSpecific,
                    onChanged: (value) {
                      setState(() {
                        isVendorSpecific = value;
                        vendorId = value ? (rate.vendorId != 'all' ? rate.vendorId : '') : 'all';
                      });
                    },
                  ),

                  // Vendor ID Field (if vendor specific)
                  if (isVendorSpecific)
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Vendor ID',
                        hintText: 'Enter vendor ID',
                      ),
                      initialValue: rate.vendorId != 'all' ? rate.vendorId : '',
                      validator: (value) {
                        if (isVendorSpecific && (value == null || value.isEmpty)) {
                          return 'Vendor ID is required';
                        }
                        return null;
                      },
                      onSaved: (value) => vendorId = value ?? '',
                    ),

                  const SizedBox(height: 16),

                  // Commission Type Dropdown
                  DropdownButtonFormField<CommissionType>(
                    decoration: const InputDecoration(
                      labelText: 'Commission Type',
                    ),
                    value: selectedType,
                    items: CommissionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.toString().split('.').last.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Percentage Field
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Percentage (%)',
                      hintText: 'Enter percentage (e.g., 10.0)',
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: percentage.toString(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Percentage is required';
                      }
                      final percent = double.tryParse(value);
                      if (percent == null || percent < 0 || percent > 100) {
                        return 'Enter valid percentage (0-100)';
                      }
                      return null;
                    },
                    onSaved: (value) => percentage = double.parse(value!),
                  ),

                  const SizedBox(height: 16),

                  // Fixed Amount Field (Optional)
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Fixed Amount (RM) - Optional',
                      hintText: 'Additional fixed amount',
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: fixedAmount?.toString(),
                    onSaved: (value) {
                      if (value != null && value.isNotEmpty) {
                        fixedAmount = double.tryParse(value);
                      } else {
                        fixedAmount = null;
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  formKey.currentState!.save();

                  final updatedRate = CommissionRate(
                    id: rate.id,
                    vendorId: vendorId,
                    type: selectedType,
                    percentage: percentage,
                    fixedAmount: fixedAmount,
                    effectiveFrom: rate.effectiveFrom,
                    effectiveTo: rate.effectiveTo,
                    isActive: rate.isActive,
                  );

                  context.read<CommissionProvider>().updateCommissionRate(rate.id, updatedRate);
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Commission rate updated successfully')),
                  );
                }
              },
              child: const Text('Update Rate'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteRate(BuildContext context, String rateId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Commission Rate'),
        content: const Text('Are you sure you want to delete this commission rate?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<CommissionProvider>().removeCommissionRate(rateId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Commission rate deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _processPayment(BuildContext context, CommissionTransaction transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payment'),
        content: Text('Process payment of RM ${transaction.vendorEarnings.toStringAsFixed(2)} to vendor ${transaction.vendorId}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<CommissionProvider>().updateTransactionStatus(
                transaction.id,
                CommissionStatus.paid,
                paymentReference: 'PAY_${DateTime.now().millisecondsSinceEpoch}',
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment processed successfully')),
              );
            },
            child: const Text('Process Payment'),
          ),
        ],
      ),
    );
  }

  void _processBulkPayment(BuildContext context, List<CommissionTransaction> transactions) {
    final totalAmount = transactions.fold(0.0, (sum, t) => sum + t.vendorEarnings);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Bulk Payment'),
        content: Text('Process payment of RM ${totalAmount.toStringAsFixed(2)} for ${transactions.length} transactions?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final transactionIds = transactions.map((t) => t.id).toList();
              context.read<CommissionProvider>().markTransactionsAsPaid(
                transactionIds,
                'BULK_PAY_${DateTime.now().millisecondsSinceEpoch}',
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bulk payment processed successfully')),
              );
            },
            child: const Text('Process All'),
          ),
        ],
      ),
    );
  }
}
