import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/finance/data/providers/finance_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';
import 'package:eventease/features/finance/data/models/finance_transaction.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';
import 'package:intl/intl.dart';

class VendorFinanceScreen extends StatefulWidget {
  const VendorFinanceScreen({Key? key}) : super(key: key);

  @override
  State<VendorFinanceScreen> createState() => _VendorFinanceScreenState();
}

class _VendorFinanceScreenState extends State<VendorFinanceScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'ms_MY', symbol: 'RM ');
  String _vendorId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFinance());
  }

  Future<void> _loadFinance() async {
    final vendor = context.read<VendorProvider>().currentVendor;
    final auth = context.read<AuthProvider>();
    final id = vendor?.id ??
        AdminImpersonationService.instance.effectiveUserId ??
        auth.userId ??
        '';
    if (!mounted) return;
    setState(() => _vendorId = id);
    if (id.isNotEmpty) {
      await context.read<FinanceProvider>().loadVendorFinancialData(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Management'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddTransactionDialog,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportFinancialReport,
          ),
        ],
      ),
      body: Consumer<FinanceProvider>(
        builder: (context, financeProvider, child) {
          final analytics = financeProvider.getFinancialAnalytics(_vendorId);
          final summary = analytics['summary'];


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Financial Overview Cards
                _buildFinancialOverview(summary),

                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(),

                const SizedBox(height: 24),

                // Recent Transactions
                _buildRecentTransactions(financeProvider),

                const SizedBox(height: 24),

                // Category Breakdown
                _buildCategoryBreakdown(analytics),

                const SizedBox(height: 24),

                // Monthly Trends
                _buildMonthlyTrends(analytics),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinancialOverview(dynamic summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Total Income',
                  currencyFormat.format(summary['totalIncome'] ?? 0),
                  Icons.trending_up,
                  Colors.green.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Total Expenses',
                  currencyFormat.format(summary['totalExpenses'] ?? 0),
                  Icons.trending_down,
                  Colors.red.shade100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildOverviewCard(
                  'Net Profit',
                  currencyFormat.format(summary['netProfit'] ?? 0),
                  Icons.account_balance_wallet,
                  Colors.blue.shade100,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildOverviewCard(
                  'Monthly Profit',
                  currencyFormat.format(summary['monthlyProfit'] ?? 0),
                  Icons.calendar_month,
                  Colors.orange.shade100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'Add Income',
                Icons.add_circle,
                Colors.green,
                () => _showAddTransactionDialog(type: TransactionType.income),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Add Expense',
                Icons.remove_circle,
                Colors.red,
                () => _showAddTransactionDialog(type: TransactionType.expense),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'View Reports',
                Icons.analytics,
                AppTheme.primaryColor,
                () => Navigator.pushNamed(context, '/vendor-reports'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(FinanceProvider provider) {
    final transactions = provider.transactions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/vendor-transactions'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (transactions.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No transactions yet'),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return _buildTransactionItem(transaction);
            },
          ),
      ],
    );
  }

  Widget _buildTransactionItem(FinanceTransaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.textSecondaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: transaction.type == TransactionType.income
                  ? Colors.green.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              transaction.type == TransactionType.income
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: transaction.type == TransactionType.income
                  ? Colors.green
                  : Colors.red,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.description,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMM dd, yyyy').format(transaction.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.type == TransactionType.income ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: transaction.type == TransactionType.income
                  ? Colors.green
                  : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(dynamic analytics) {
    final categoryBreakdown = analytics['categoryBreakdown'] as Map<String, double>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Income by Category',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        if (categoryBreakdown.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No category data available'),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: categoryBreakdown.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: const TextStyle(color: AppTheme.textPrimaryColor),
                        ),
                      ),
                      Text(
                        currencyFormat.format(entry.value),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildMonthlyTrends(dynamic analytics) {
    final monthlyTrends = analytics['monthlyTrends'] as Map<String, Map<String, double>>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Trends',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        if (monthlyTrends.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No trend data available'),
            ),
          )
        else
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: monthlyTrends.entries.take(6).map((entry) {
                final data = entry.value;
                final income = data['income'] ?? 0.0;
                final expenses = data['expenses'] ?? 0.0;
                final maxValue = [income, expenses].reduce((a, b) => a > b ? a : b);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                width: double.infinity,
                                height: maxValue > 0 ? (income / maxValue) * 150 : 0,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(4),
                                    topRight: Radius.circular(4),
                                  ),
                                ),
                              ),
                              Container(
                                width: double.infinity,
                                height: maxValue > 0 ? (expenses / maxValue) * 150 : 0,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(4),
                                    bottomRight: Radius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          entry.key.split('-')[1],
                          style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  void _showAddTransactionDialog({TransactionType? type}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${type == TransactionType.income ? 'Income' : 'Expense'}'),
        content: const Text('Transaction form would be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _exportFinancialReport() {
    final analytics = context.read<FinanceProvider>().getFinancialAnalytics(_vendorId);
    final summary = analytics['summary'];
    final buffer = StringBuffer()
      ..writeln('EventEase Vendor Finance Report')
      ..writeln('Vendor ID,$_vendorId')
      ..writeln('Generated,${DateTime.now().toIso8601String()}')
      ..writeln('Summary,$summary');
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Finance report copied to clipboard (CSV text)')),
    );
  }
}
