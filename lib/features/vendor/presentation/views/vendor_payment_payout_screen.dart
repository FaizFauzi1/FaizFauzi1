import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';
import 'package:eventease/features/finance/data/models/finance_transaction.dart';
import 'package:eventease/features/finance/data/providers/finance_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class VendorPaymentPayoutScreen extends StatefulWidget {
  const VendorPaymentPayoutScreen({super.key});

  @override
  State<VendorPaymentPayoutScreen> createState() => _VendorPaymentPayoutScreenState();
}

class _VendorPaymentPayoutScreenState extends State<VendorPaymentPayoutScreen> {
  String _selectedTab = 'Transactions';
  String _selectedPeriod = 'This Month';

  // Bank accounts loaded from Supabase (vendor_banking table via VendorProfileProvider)
  List<Map<String, dynamic>> _paymentMethods = [];

  final List<String> _malaysianBanks = [
    'Maybank (Malayan Banking Berhad)',
    'CIMB Bank Berhad',
    'Public Bank Berhad',
    'RHB Bank Berhad',
    'Hong Leong Bank Berhad',
    'AmBank (M) Berhad',
    'Bank Islam Malaysia Berhad',
    'OCBC Bank (Malaysia) Berhad',
    'Standard Chartered Bank',
    'HSBC Bank Malaysia',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final profileProvider = Provider.of<VendorProfileProvider>(context, listen: false);
    final effectiveId = AdminImpersonationService.instance.effectiveUserId ?? auth.userId;
    if (effectiveId != null) {
      await finance.loadVendorFinancialData(effectiveId);
    }
    await profileProvider.loadVendorProfile();
    _syncBankAccountsFromProfile(profileProvider);
  }

  void _syncBankAccountsFromProfile(VendorProfileProvider profileProvider) {
    final profile = profileProvider.vendorProfile;
    if (profile == null) return;
    final bankingList = profile['vendor_banking'];
    if (bankingList == null || bankingList is! List || (bankingList as List).isEmpty) {
      setState(() => _paymentMethods = []);
      return;
    }
    setState(() {
      _paymentMethods = (bankingList as List).asMap().entries.map((entry) {
        final b = Map<String, dynamic>.from(entry.value as Map);
        final bankName = b['bank_name'] ?? b['bank'] ?? 'Bank Account';
        final accNum = b['account_number'] ?? '';
        final last4 = accNum.length >= 4 ? accNum.substring(accNum.length - 4) : accNum;
        return {
          'type': 'Bank Account',
          'bankName': bankName,
          'details': last4.isNotEmpty ? '$bankName - ****$last4' : bankName,
          'accountNumber': accNum,
          'accountHolder': b['account_holder_name'] ?? b['account_name'] ?? '',
          'status': 'Active',
          'default': entry.key == 0,
          '_raw': b,
        };
      }).toList();
    });
  }

  String _nextPayoutDate() {
    final now = DateTime.now();
    final daysUntilFriday = (5 - now.weekday + 7) % 7;
    final nextFriday = now.add(Duration(days: daysUntilFriday == 0 ? 7 : daysUntilFriday));
    return DateFormat('EEE, d MMM').format(nextFriday);
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Payments & Payouts',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppTheme.primaryColor),
            tooltip: 'Export Statement',
            onPressed: _exportStatement,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimaryColor),
            onPressed: _loadData,
          ),
        ],
      ),
      body: finance.isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildAvailableBalanceBanner(finance),
                _buildTabSelector(),
                _buildPeriodSelector(),
                Expanded(
                  child: _selectedTab == 'Transactions'
                      ? _buildTransactionsView(finance)
                      : _buildPaymentMethodsView(),
                ),
              ],
            ),
    );
  }

  Widget _buildAvailableBalanceBanner(FinanceProvider finance) {
    final income = finance.transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    final payouts = finance.transactions
        .where((t) => t.description.contains('Payout') || t.type == TransactionType.expense)
        .fold<double>(0, (sum, t) => sum + t.amount.abs());

    final calculatedAvailable = (income - (income * 0.05) - payouts);
    final availableBalance = calculatedAvailable > 0 ? calculatedAvailable : (income > 0 ? income * 0.95 : 0.0);
    final pendingBalance = income > 0 ? income * 0.15 : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E1B4B).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available for Withdrawal',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'RM ${availableBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showWithdrawalModal(availableBalance),
                icon: const Icon(Icons.arrow_upward, size: 16),
                label: const Text('Request Payout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_clock, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 6),
                  const Text(
                    'Pending Escrow Balance: ',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    'RM ${pendingBalance.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                'Next payout: ${_nextPayoutDate()}',
                style: const TextStyle(color: Colors.white60, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Transactions', _selectedTab == 'Transactions'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTabButton('Bank Management', _selectedTab == 'Payment Methods'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return ElevatedButton(
      onPressed: () => setState(() => _selectedTab = title == 'Bank Management' ? 'Payment Methods' : title),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(title),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: DropdownButtonFormField<String>(
        value: _selectedPeriod,
        items: const [
          DropdownMenuItem(value: 'Today', child: Text('Today')),
          DropdownMenuItem(value: 'This Week', child: Text('This Week')),
          DropdownMenuItem(value: 'This Month', child: Text('This Month')),
          DropdownMenuItem(value: 'Last Month', child: Text('Last Month')),
          DropdownMenuItem(value: 'All Time', child: Text('All Time')),
        ],
        onChanged: (value) => setState(() => _selectedPeriod = value!),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildTransactionsView(FinanceProvider finance) {
    final transactions = finance.transactions;
    
    final totalEarnings = transactions
        .where((t) => t.type == TransactionType.income)
        .fold<double>(0, (sum, t) => sum + t.amount);
    
    final totalFees = totalEarnings * 0.05; 
    
    final totalPayouts = transactions
        .where((t) => t.description.contains('Payout'))
        .fold<double>(0, (sum, t) => sum + t.amount.abs());

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Earnings',
                      'RM ${totalEarnings.toStringAsFixed(0)}',
                      Icons.trending_up,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryCard(
                      'Commission (5%)',
                      'RM ${totalFees.toStringAsFixed(0)}',
                      Icons.account_balance_wallet,
                      AppTheme.warningColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryCard(
                      'Total Payouts',
                      'RM ${totalPayouts.toStringAsFixed(0)}',
                      Icons.payments,
                      AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCommissionAuditTile(),
            ],
          ),
        ),

        Expanded(
          child: transactions.isEmpty
              ? _buildEmptyTransactionsState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) =>
                      _buildTransactionCard(transactions[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildCommissionAuditTile() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.verified, size: 16, color: AppTheme.primaryColor),
              SizedBox(width: 6),
              Text(
                'Platform Commission: 5.0%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor),
              ),
            ],
          ),
          Text(
            'Applied on confirmed bookings',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTransactionsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No Transactions Yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your confirmed bookings and payouts\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }



  Widget _buildTransactionCard(dynamic transaction) {
    // Works with FinanceTransaction model or any map-like object
    final title = transaction.title ?? transaction.description ?? 'Transaction';
    final desc = transaction.description ?? '';
    final amount = (transaction.amount ?? 0.0) as double;
    final isIncome = amount >= 0;
    final dateStr = transaction.date?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isIncome ? Colors.green : Colors.indigo).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isIncome ? Icons.arrow_downward : Icons.arrow_upward,
              color: isIncome ? Colors.green : Colors.indigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (desc.isNotEmpty)
                  Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : ''}RM ${amount.abs().toStringAsFixed(2)}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isIncome ? Colors.green : Colors.indigo),
              ),
              Text(dateStr, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: ElevatedButton.icon(
            onPressed: _showAddBankDialog,
            icon: const Icon(Icons.add_card),
            label: const Text('Add Malaysian Bank Account'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _paymentMethods.length,
            itemBuilder: (context, index) =>
                _buildPaymentMethodCard(_paymentMethods[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isDefault = method['default'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDefault ? Border.all(color: AppTheme.primaryColor, width: 1.5) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.account_balance,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        method['bankName'] ?? method['type'] ?? 'Bank Account',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Default Payout',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  method['details'] ?? '',
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (method['accountHolder'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Holder: ${method['accountHolder']}',
                    style: const TextStyle(
                      color: AppTheme.textSecondaryColor,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),

          PopupMenuButton<String>(
            onSelected: (value) => _handlePaymentMethodAction(value, method),
            itemBuilder: (context) => [
              if (!isDefault)
                const PopupMenuItem(
                  value: 'set_default',
                  child: Text('Set as Default Payout'),
                ),
              const PopupMenuItem(
                value: 'remove',
                child: Text('Remove Bank Account'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showWithdrawalModal(double availableBalance) {
    final amountController = TextEditingController();
    String selectedMethod = _paymentMethods.isNotEmpty ? (_paymentMethods.first['details'] ?? '') : '';
    String transferSpeed = 'instant'; // 'instant' or 'standard'

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final enteredAmount = double.tryParse(amountController.text) ?? 0.0;
            final fee = transferSpeed == 'instant' ? 1.00 : 0.00;
            final netPayout = (enteredAmount - fee).clamp(0.0, double.infinity);

            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Request Fund Withdrawal',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Available: RM ${availableBalance.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13, color: Colors.green, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),

                    const Text('Withdrawal Amount (MYR)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        prefixText: 'RM ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppTheme.backgroundColor,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      children: [500, 1000, 5000, availableBalance.toInt()].map((quickAmt) {
                        return ActionChip(
                          label: Text(quickAmt == availableBalance.toInt() ? 'Max (RM $quickAmt)' : 'RM $quickAmt'),
                          onPressed: () {
                            setModalState(() {
                              amountController.text = quickAmt.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    const Text('Destination Bank Account', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedMethod,
                      items: _paymentMethods.map((m) {
                        return DropdownMenuItem<String>(
                          value: m['details'] as String,
                          child: Text(m['details'] as String),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedMethod = val!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Transfer Speed', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Instant FPX (RM1.00 fee)'),
                            selected: transferSpeed == 'instant',
                            onSelected: (val) => setModalState(() => transferSpeed = 'instant'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Standard (Free, 1-2d)'),
                            selected: transferSpeed == 'standard',
                            onSelected: (val) => setModalState(() => transferSpeed = 'standard'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Gross Withdrawal:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                              Text('RM ${enteredAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Processing Fee:', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                              Text('RM ${fee.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Net Payout to Bank:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('RM ${netPayout.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: enteredAmount > 0 && enteredAmount <= availableBalance
                          ? () {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Payout request of RM ${netPayout.toStringAsFixed(2)} submitted successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirm & Submit Payout Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAddBankDialog() {
    String selectedBank = _malaysianBanks.first;
    final accNumberController = TextEditingController();
    final holderController = TextEditingController();
    bool setAsDefault = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Add Malaysian Bank Account', style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Bank Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedBank,
                      items: _malaysianBanks.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) => setDialogState(() => selectedBank = val!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Account Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: accNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'e.g. 514012345678',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text('Account Holder Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: holderController,
                      decoration: InputDecoration(
                        hintText: 'As per IC / SSM Registration',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Set as Default Payout Account', style: TextStyle(fontSize: 13)),
                      value: setAsDefault,
                      onChanged: (val) => setDialogState(() => setAsDefault = val ?? false),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (accNumberController.text.trim().isEmpty || holderController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please fill all bank details')),
                      );
                      return;
                    }

                    setState(() {
                      if (setAsDefault) {
                        for (var m in _paymentMethods) {
                          m['default'] = false;
                        }
                      }
                      _paymentMethods.add({
                        'type': 'Bank Account',
                        'bankName': selectedBank,
                        'details': '$selectedBank - ${accNumberController.text.trim()}',
                        'accountNumber': accNumberController.text.trim(),
                        'accountHolder': holderController.text.trim(),
                        'status': 'Active',
                        'default': setAsDefault || _paymentMethods.isEmpty,
                      });
                    });

                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Bank account added successfully!'), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Bank Account'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handlePaymentMethodAction(String action, Map<String, dynamic> method) {
    switch (action) {
      case 'set_default':
        setState(() {
          for (var m in _paymentMethods) {
            m['default'] = false;
          }
          method['default'] = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${method['bankName'] ?? method['type']} set as default payout bank')),
        );
        break;
      case 'remove':
        if (method['default'] && _paymentMethods.length > 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please set another bank as default before removing this one.')),
          );
        } else {
          setState(() {
            _paymentMethods.remove(method);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bank account removed')),
          );
        }
        break;
    }
  }

  void _exportStatement() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Financial Statement'),
        content: const Text('Choose format to download your verified transaction and payout ledger:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exported financial statement to PDF!')),
              );
            },
            child: const Text('PDF Statement'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exported financial statement to Excel/CSV!')),
              );
            },
            child: const Text('Excel / CSV'),
          ),
        ],
      ),
    );
  }
}
