import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:eventease/features/admin/data/providers/admin_provider.dart'; // <-- use TransactionEntry from here
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/commission_management_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:flutter/services.dart';
import 'package:eventease/shared/models/bank_account.dart';


import 'package:eventease/features/admin/data/services/admin_marketplace_service.dart';
import 'package:eventease/features/admin/presentation/widgets/admin_entity_detail_dialog.dart';

class FinancialManagementScreen extends StatefulWidget {
  const FinancialManagementScreen({super.key});

  @override
  State<FinancialManagementScreen> createState() =>
      _FinancialManagementScreenState();
}

class _FinancialManagementScreenState extends State<FinancialManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = 'This Month';
  double? _commissionPercent;

  final List<Map<String, dynamic>> _disputes = [
    {
      'id': 'DSP-2026-081',
      'bookingId': 'BK-98214',
      'customer': 'Elena Rostova',
      'customerId': 'CUST-002',
      'vendor': 'SoundWave Pro Audio',
      'vendorId': 'VEND-001',
      'event': 'Kuala Lumpur Tech Gala 2026',
      'package': 'Corporate Audio Visual Pro',
      'disputedAmount': 1850.0,
      'status': 'Under Review',
      'reason': 'Vendor arrived 2.5 hours late and failed to provide 2 wireless lapel mics, disrupting keynote speakers.',
      'customerStatement': 'Keynote started without audio. We had to use hotel backup system.',
      'vendorResponse': 'Traffic obstruction on MEX Highway. Incurred parking fee and provided wired mics as substitute.',
      'createdAt': '2026-09-22 14:30',
      'payoutHeld': true,
    },
    {
      'id': 'DSP-2026-079',
      'bookingId': 'BK-77412',
      'customer': 'Marcus Vance',
      'customerId': 'CUST-003',
      'vendor': 'Epic Moments Photography',
      'vendorId': 'VEND-003',
      'event': 'Sarah & David Wedding',
      'package': 'Full-Day Signature Coverage',
      'disputedAmount': 3200.0,
      'status': 'Payout Held',
      'reason': 'Only 1 photographer showed up instead of agreed 2 shooters. 40% of cocktail reception coverage missing.',
      'customerStatement': 'Second shooter fell ill without replacement provided.',
      'vendorResponse': 'Willing to offer 20% discount or additional photobook album.',
      'createdAt': '2026-09-20 18:15',
      'payoutHeld': true,
    },
    {
      'id': 'DSP-2026-074',
      'bookingId': 'BK-61209',
      'customer': 'Aisha Rahman',
      'customerId': 'CUST-001',
      'vendor': 'Royal Floral & Decors',
      'vendorId': 'VEND-002',
      'event': 'Petronas Annual Dinner',
      'package': 'Grand Ballroom Decor Suite',
      'disputedAmount': 2800.0,
      'status': 'Resolved',
      'reason': 'Cancellation made 7 days prior; disputed non-refundable deposit terms.',
      'customerStatement': 'Policy permitted 50% refund for cancellation >5 days.',
      'vendorResponse': 'Fresh flowers already imported from Cameron Highlands.',
      'createdAt': '2026-09-18 10:00',
      'payoutHeld': false,
    },
  ];

  final List<Map<String, dynamic>> _failedPayments = [
    {
      'id': 'PAY-FAIL-8821',
      'bookingId': 'BK-10394',
      'customer': 'David Tan',
      'customerId': 'CUST-004',
      'vendor': 'Grand Hyatt Kuala Lumpur',
      'vendorId': 'VEND-004',
      'event': 'Tan Family 50th Anniversary',
      'package': 'Grand Banquet Hall Experience',
      'amount': 5400.0,
      'errorCode': 'ERR_INSUFFICIENT_FUNDS',
      'gateway': 'Stripe Credit Card',
      'gatewayMessage': 'Card declined: Insufficient funds in cardholder account.',
      'attemptCount': 2,
      'lastAttempt': '2026-09-24 16:42',
      'resolved': false,
    },
    {
      'id': 'PAY-FAIL-8819',
      'bookingId': 'BK-99823',
      'customer': 'Nurul Huda',
      'customerId': 'CUST-005',
      'vendor': 'SoundWave Pro Audio',
      'vendorId': 'VEND-001',
      'event': 'Cyberjaya Indie Fest 2026',
      'package': 'Festival Stage Line Array',
      'amount': 3800.0,
      'errorCode': 'ERR_3DS_TIMEOUT',
      'gateway': 'FPX Online Banking (Maybank)',
      'gatewayMessage': 'Bank authorization timed out: Customer did not approve OTP within 180s.',
      'attemptCount': 1,
      'lastAttempt': '2026-09-24 11:20',
      'resolved': false,
    },
    {
      'id': 'PAY-FAIL-8804',
      'bookingId': 'BK-87114',
      'customer': 'Rachel Green',
      'customerId': 'CUST-006',
      'vendor': 'Epic Moments Photography',
      'vendorId': 'VEND-003',
      'event': 'Green Corporate Product Launch',
      'package': 'Commercial Video & Photo Combo',
      'amount': 2250.0,
      'errorCode': 'ERR_CARD_EXPIRED',
      'gateway': 'Visa Corporate Card',
      'gatewayMessage': 'Expired card: Expiration date 08/26 precedes transaction date.',
      'attemptCount': 3,
      'lastAttempt': '2026-09-23 09:14',
      'resolved': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);
    _commissionPercent ??= admin.commissionPercent;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Financial Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions & Payments'),
            Tab(text: 'Refunds & Disputes'),
            Tab(text: 'Payouts'),
            Tab(text: 'Failed Payments'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(admin),
          _buildTransactionsTab(admin),
          _buildRefundsDisputesTab(admin),
          _buildPayoutsTab(admin),
          _buildFailedPaymentsTab(admin),
          _buildReportsTab(admin),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AdminProvider admin) {
    final totalGross = admin.totalGrossRevenue;
    final platformFees = admin.totalPlatformFees;
    final vendorPayouts = admin.totalVendorPayouts;
    final pendingPayoutAmount = admin.payouts.where((p) => p.status == 'pending').fold(0.0, (sum, p) => sum + p.amount);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text(
                  'Period: ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  value: _selectedPeriod,
                  items: ['This Month', 'Last Month', 'This Quarter', 'This Year']
                      .map((period) => DropdownMenuItem(
                            value: period,
                            child: Text(period),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedPeriod = value!;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Revenue Overview Cards
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.0,
            children: [
              _buildRevenueCard(
                'Gross Revenue',
                'RM ${totalGross.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                Colors.green,
                '+12.5%',
                [5, 7, 6, 8, 9, 11],
              ),
              _buildRevenueCard(
                'Platform Fees',
                'RM ${platformFees.toStringAsFixed(2)}',
                Icons.analytics,
                Colors.orange,
                '11% Rate',
                [2, 3, 2, 4, 3, 5],
              ),
              _buildRevenueCard(
                'Vendor Net',
                'RM ${vendorPayouts.toStringAsFixed(2)}',
                Icons.payments,
                Colors.blue,
                '89% Share',
                [4, 6, 5, 7, 8, 10],
              ),
              _buildRevenueCard(
                'Pending',
                'RM ${pendingPayoutAmount.toStringAsFixed(2)}',
                Icons.pending,
                Colors.red,
                '${admin.payouts.where((p) => p.status == 'pending').length} items',
                [1, 2, 1, 3, 2, 4],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Main Revenue Chart
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revenue Performance',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Total growth and earnings trend',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.trending_up, size: 16, color: AppTheme.primaryColor),
                          SizedBox(width: 4),
                          Text(
                            '+24.3%',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 250,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.05),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 45,
                            getTitlesWidget: (value, meta) => Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: Text(
                                '${(value / 1000).toInt()}k',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[400],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                              if (value.toInt() < months.length) {
                                return Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: Text(
                                    months[value.toInt()],
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 5000),
                            FlSpot(1, 7500),
                            FlSpot(2, 6000),
                            FlSpot(3, 9000),
                            FlSpot(4, 8500),
                            FlSpot(5, 11000),
                          ],
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: AppTheme.primaryColor,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                              radius: index == barData.spots.length - 1 ? 6 : 0,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor: AppTheme.primaryColor,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.primaryColor.withOpacity(0.15),
                                AppTheme.primaryColor.withOpacity(0.0),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Commission Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Platform Commission: ${admin.commissionPercent}%',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _showCommissionDialog(admin),
                      child: const Text('Adjust'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Commission Rate Management',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _navigateToCommissionManagement(),
                      icon: const Icon(Icons.edit),
                      label: const Text('Manage Rates'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Configure commission rates for different vendor types and services',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab(AdminProvider admin) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Status Filter',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  value: 'All',
                  items: ['All', 'Paid', 'Pending', 'Refunded', 'Cancelled']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: () => _exportTransactions(admin.transactions),
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Colors.grey[50],
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Tip: Click on Customer, Vendor, Event, Booking or Package chips to traverse full marketplace records.',
                style: TextStyle(fontSize: 11, color: Colors.grey[700]),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: admin.transactions.length,
            itemBuilder: (context, index) {
              final transaction = admin.transactions[index];
              return _buildTransactionCard(transaction, admin);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRefundsDisputesTab(AdminProvider admin) {
    final activeDisputes = _disputes.where((d) => d['status'] != 'Resolved').toList();
    final totalDisputed = _disputes.fold<double>(0, (s, d) => s + (d['disputedAmount'] as double));
    final heldPayoutsCount = _disputes.where((d) => d['payoutHeld'] == true).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metrics Cards Row
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Active Disputes',
                  '${activeDisputes.length}',
                  Icons.gavel_rounded,
                  Colors.amber[800]!,
                  'Action needed',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Disputed Value',
                  'RM ${totalDisputed.toStringAsFixed(0)}',
                  Icons.account_balance_wallet_outlined,
                  Colors.red[700]!,
                  'In escrow review',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Payouts on Hold',
                  '$heldPayoutsCount',
                  Icons.pause_circle_filled_rounded,
                  Colors.purple[700]!,
                  'Safe protection',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Avg Resolution SLA',
                  '4.2 hrs',
                  Icons.timer_outlined,
                  Colors.teal[700]!,
                  'Target: < 24 hrs',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Disputes & Refund Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'Mediate marketplace issues, review evidence, hold payouts, and enforce refund policies',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dispute settlement policies updated.')),
                  );
                },
                icon: const Icon(Icons.policy_outlined, size: 16),
                label: const Text('Dispute Policy Rules'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Dispute Cards List
          ..._disputes.map((dispute) => _buildDisputeCard(dispute, admin)),
        ],
      ),
    );
  }

  Widget _buildDisputeCard(Map<String, dynamic> dispute, AdminProvider admin) {
    final status = dispute['status'] as String;
    Color statusColor;
    switch (status) {
      case 'Under Review':
        statusColor = Colors.orange;
        break;
      case 'Payout Held':
        statusColor = Colors.purple;
        break;
      case 'Resolved':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.blue;
    }

    final isHeld = dispute['payoutHeld'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHeld ? Colors.purple.withOpacity(0.3) : Colors.black.withOpacity(0.06),
          width: isHeld ? 1.5 : 1.0,
        ),
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
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      status == 'Payout Held' ? Icons.lock : Icons.shield_outlined,
                      size: 14,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                dispute['id'],
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              const Spacer(),
              Text(
                'Disputed: RM ${(dispute['disputedAmount'] as double).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppTheme.primaryColor,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Connected Relationship Chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildConnectedEntityChip(
                label: 'Customer',
                name: dispute['customer'],
                type: MarketplaceEntityType.customer,
                id: dispute['customerId'],
                color: Colors.blue,
              ),
              _buildConnectedEntityChip(
                label: 'Vendor',
                name: dispute['vendor'],
                type: MarketplaceEntityType.vendor,
                id: dispute['vendorId'],
                color: Colors.purple,
              ),
              _buildConnectedEntityChip(
                label: 'Booking',
                name: dispute['bookingId'],
                type: MarketplaceEntityType.booking,
                id: dispute['bookingId'],
                color: Colors.teal,
              ),
              _buildConnectedEntityChip(
                label: 'Event',
                name: dispute['event'],
                type: MarketplaceEntityType.event,
                id: 'EVT-${dispute['bookingId']}',
                color: Colors.orange,
              ),
              _buildConnectedEntityChip(
                label: 'Package',
                name: dispute['package'],
                type: MarketplaceEntityType.package,
                id: 'PKG-DEMO',
                color: Colors.indigo,
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Issue Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reason: ${dispute['reason']}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Customer Statement: "${dispute['customerStatement']}"',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700], fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vendor Defense: "${dispute['vendorResponse']}"',
                  style: TextStyle(fontSize: 11, color: Colors.grey[700], fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Buttons: Review, Hold Payout, Refund Customer, Release to Vendor
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showDisputeReviewModal(dispute),
                icon: const Icon(Icons.remove_red_eye_outlined, size: 15),
                label: const Text('Review Evidence', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    dispute['payoutHeld'] = !isHeld;
                    if (dispute['payoutHeld']) {
                      dispute['status'] = 'Payout Held';
                    } else if (dispute['status'] == 'Payout Held') {
                      dispute['status'] = 'Under Review';
                    }
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isHeld ? 'Payout released to queue.' : 'Vendor payout locked and held in escrow.'),
                      backgroundColor: isHeld ? Colors.green : Colors.purple,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isHeld ? Colors.grey[700] : Colors.purple[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: Icon(isHeld ? Icons.lock_open : Icons.pause_circle_outline, size: 15),
                label: Text(isHeld ? 'Unlock Payout' : 'Hold Payout', style: const TextStyle(fontSize: 12)),
              ),
              ElevatedButton.icon(
                onPressed: () => _showRefundDialog(dispute: dispute),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.replay, size: 15),
                label: const Text('Refund Customer', style: TextStyle(fontSize: 12)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    dispute['status'] = 'Resolved';
                    dispute['payoutHeld'] = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dispute resolved in vendor favor. Funds released for next payout cycle.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.check_circle_outline, size: 15),
                label: const Text('Release to Vendor', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFailedPaymentsTab(AdminProvider admin) {
    final uncollectedTotal = _failedPayments.where((p) => !p['resolved']).fold<double>(0, (s, p) => s + (p['amount'] as double));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  'Failed Transactions',
                  '${_failedPayments.where((p) => !p['resolved']).length}',
                  Icons.error_outline_rounded,
                  Colors.red[700]!,
                  'Past 7 days',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Uncollected Amount',
                  'RM ${uncollectedTotal.toStringAsFixed(0)}',
                  Icons.money_off_csred_rounded,
                  Colors.orange[800]!,
                  'Pending retry',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricTile(
                  'Auto-Recovery Rate',
                  '68.4%',
                  Icons.autorenew_rounded,
                  Colors.green[700]!,
                  'Recovered RM 14.2k',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Failed Payment Gateway Attempts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          Text(
            'Track card declines, FPX timeouts, and expired authorization sessions with direct retry tools',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          ..._failedPayments.map((payment) => _buildFailedPaymentCard(payment)),
        ],
      ),
    );
  }

  Widget _buildFailedPaymentCard(Map<String, dynamic> payment) {
    final isResolved = payment['resolved'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isResolved ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isResolved ? Colors.green[50] : Colors.red[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isResolved ? Colors.green[300]! : Colors.red[300]!,
                  ),
                ),
                child: Text(
                  payment['errorCode'],
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isResolved ? Colors.green[800] : Colors.red[800],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Attempt #${payment['attemptCount']} • ${payment['lastAttempt']}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                'RM ${(payment['amount'] as double).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildConnectedEntityChip(
                label: 'Customer',
                name: payment['customer'],
                type: MarketplaceEntityType.customer,
                id: payment['customerId'],
                color: Colors.blue,
              ),
              _buildConnectedEntityChip(
                label: 'Vendor',
                name: payment['vendor'],
                type: MarketplaceEntityType.vendor,
                id: payment['vendorId'],
                color: Colors.purple,
              ),
              _buildConnectedEntityChip(
                label: 'Booking',
                name: payment['bookingId'],
                type: MarketplaceEntityType.booking,
                id: payment['bookingId'],
                color: Colors.teal,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Gateway: ${payment['gateway']} — ${payment['gatewayMessage']}',
            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    payment['resolved'] = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment re-attempt authorized and captured successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.refresh, size: 15),
                label: const Text('Re-attempt Charge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Smart SMS payment link sent to ${payment['customer']}.'),
                    ),
                  );
                },
                icon: const Icon(Icons.send_outlined, size: 15),
                label: const Text('Send Payment Link'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600]),
              ),
              Icon(icon, size: 16, color: color),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedEntityChip({
    required String label,
    required String name,
    required MarketplaceEntityType type,
    required String id,
    required Color color,
  }) {
    return InkWell(
      onTap: () => AdminEntityDetailDialog.show(
        context,
        entityType: type,
        entityId: id,
        entityName: name,
      ),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.3), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[850]),
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.open_in_new, size: 10, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildPayoutsTab(AdminProvider admin) {
    final pendingPayouts =
        admin.payouts.where((p) => p.status == 'pending').toList();
    final completedPayouts =
        admin.payouts.where((p) => p.status == 'completed').toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingPayouts.isNotEmpty) ...[
            const Text(
              'Pending Payouts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...pendingPayouts
                .map((payout) => _buildPayoutCard(payout, admin, isPending: true)),
            const SizedBox(height: 20),
          ],
          const Text(
            'Completed Payouts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...completedPayouts
              .map((payout) => _buildPayoutCard(payout, admin, isPending: false)),
        ],
      ),
    );
  }

  Widget _buildReportsTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Reports',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Generate and export detailed financial data for analysis',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.5,
            children: [
              _buildReportCard(
                'Monthly Revenue',
                'Detailed breakdown of earnings by month',
                Icons.calendar_month,
                AppTheme.primaryColor,
                () => _generateReport('monthly', admin.transactions),
              ),
              _buildReportCard(
                'Vendor Performance',
                'Top performing vendors and commission stats',
                Icons.analytics,
                Colors.orange,
                () => _generateReport('vendor', admin.transactions),
              ),
              _buildReportCard(
                'Transaction Log',
                'Complete history of all platform payments',
                Icons.receipt_long,
                Colors.blue,
                () => _generateReport('transactions', admin.transactions),
              ),
              _buildReportCard(
                'Commission Audit',
                'Verify platform fees and net distributions',
                Icons.percent,
                Colors.teal,
                () => _generateReport('commission', admin.transactions),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String title, String amount, IconData icon,
      Color color, String change, List<double> sparkData) {
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
              const Spacer(),
              Text(
                change,
                style: TextStyle(
                  color: change.startsWith('+') ? Colors.green : Colors.grey[600],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
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
            height: 30,
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

  Widget _buildTransactionCard(
      TransactionEntry transaction, AdminProvider admin) {
    Color statusColor;
    String statusText = transaction.status.toUpperCase();

    switch (transaction.status) {
      case 'completed':
      case 'paid':
        statusColor = AppTheme.successColor;
        break;
      case 'pending':
        statusColor = AppTheme.warningColor;
        break;
      case 'refunded':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = Colors.grey;
    }

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
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  (transaction.status == 'completed' || transaction.status == 'paid') ? Icons.check_rounded : 
                  transaction.status == 'pending' ? Icons.schedule_rounded : Icons.close_rounded,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.party,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${transaction.date} • ID: ${transaction.id.substring(0, 8)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${transaction.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              PopupMenuButton(
                icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                padding: EdgeInsets.zero,
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View Details')),
                  if (transaction.status == 'pending')
                    const PopupMenuItem(value: 'approve', child: Text('Approve')),
                  if (transaction.status == 'paid')
                    const PopupMenuItem(
                        value: 'refund', child: Text('Process Refund')),
                ],
                onSelected: (value) {
                  switch (value) {
                    case 'view':
                      _showTransactionDetails(transaction);
                      break;
                    case 'approve':
                      admin.updateTransactionStatus(transaction.id, 'paid');
                      break;
                    case 'refund':
                      admin.updateTransactionStatus(transaction.id, 'refunded');
                      break;
                  }
                },
              ),
            ],
          ),
          // Clickable Entity Relationship Chips
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildConnectedEntityChip(
                label: 'Customer',
                name: transaction.party,
                type: MarketplaceEntityType.customer,
                id: 'CUST-${transaction.id.substring(0, 4)}',
                color: Colors.blue,
              ),
              if (transaction.vendorId != null)
                _buildConnectedEntityChip(
                  label: 'Vendor',
                  name: 'Vendor',
                  type: MarketplaceEntityType.vendor,
                  id: transaction.vendorId!,
                  color: Colors.purple,
                ),
              _buildConnectedEntityChip(
                label: 'Booking',
                name: 'BK-${transaction.id.substring(0, 6)}',
                type: MarketplaceEntityType.booking,
                id: 'BK-${transaction.id.substring(0, 6)}',
                color: Colors.teal,
              ),
              if (transaction.serviceId != null)
                _buildConnectedEntityChip(
                  label: 'Service',
                  name: 'Service',
                  type: MarketplaceEntityType.service,
                  id: transaction.serviceId!,
                  color: Colors.orange,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayoutCard(Payout payout, AdminProvider admin,
      {required bool isPending}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPending ? AppTheme.warningColor.withOpacity(0.2) : Colors.black.withOpacity(0.03),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: (isPending ? AppTheme.warningColor : AppTheme.successColor).withOpacity(0.1),
                child: Icon(
                  isPending ? Icons.pending_actions_rounded : Icons.verified_user_rounded,
                  color: isPending ? AppTheme.warningColor : AppTheme.successColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      payout.vendor,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Requested on ${payout.date}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'RM ${payout.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BANK DETAILS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.grey,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder(
                          future: admin.getBankAccount(payout),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const Text('Loading...');
                            final bank = snapshot.data;
                            return Text(
                              '${bank?.bankName} • ${bank?.accountNumber}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _processPayout(payout, admin),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('PROCESS'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildReportCard(
      String title, String description, IconData icon, Color color, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withOpacity(0.03)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor.withOpacity(0.7),
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommissionDialog(AdminProvider admin) {
    final controller =
        TextEditingController(text: admin.commissionPercent.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Commission'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter new commission percentage:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Commission %',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newCommission = double.tryParse(controller.text);
              if (newCommission != null &&
                  newCommission >= 0 &&
                  newCommission <= 100) {
                admin.setCommissionPercent(newCommission);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(TransactionEntry transaction) {
    Color statusColor;
    switch (transaction.status) {
      case 'completed':
      case 'paid':
        statusColor = AppTheme.successColor;
        break;
      case 'pending':
        statusColor = AppTheme.warningColor;
        break;
      case 'refunded':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = Colors.grey;
    }

    final platformFee = transaction.amount * 0.08;
    final vendorNet = transaction.amount - platformFee;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction Details',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Status + Amount Hero
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor.withOpacity(0.08), statusColor.withOpacity(0.02)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: statusColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            transaction.status == 'paid' || transaction.status == 'completed'
                                ? Icons.check_circle_rounded
                                : transaction.status == 'pending'
                                    ? Icons.hourglass_top_rounded
                                    : Icons.cancel_rounded,
                            color: statusColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'RM ${transaction.amount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'monospace',
                              ),
                            ),
                            Text(
                              transaction.status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Linked Entities
                  const Text(
                    'LINKED ENTITIES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildConnectedEntityChip(
                        label: 'Customer',
                        name: transaction.party,
                        type: MarketplaceEntityType.customer,
                        id: 'CUST-${transaction.id.substring(0, 4)}',
                        color: Colors.blue,
                      ),
                      if (transaction.vendorId != null)
                        _buildConnectedEntityChip(
                          label: 'Vendor',
                          name: 'Vendor',
                          type: MarketplaceEntityType.vendor,
                          id: transaction.vendorId!,
                          color: Colors.purple,
                        ),
                      _buildConnectedEntityChip(
                        label: 'Booking',
                        name: 'BK-${transaction.id.substring(0, 6)}',
                        type: MarketplaceEntityType.booking,
                        id: 'BK-${transaction.id.substring(0, 6)}',
                        color: Colors.teal,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Details Grid
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _buildTxDetailRow('Transaction ID', transaction.id),
                        const Divider(height: 16),
                        _buildTxDetailRow('Party', transaction.party),
                        const Divider(height: 16),
                        _buildTxDetailRow('Date', transaction.date),
                        const Divider(height: 16),
                        _buildTxDetailRow('Gross Amount', 'RM ${transaction.amount.toStringAsFixed(2)}'),
                        const Divider(height: 16),
                        _buildTxDetailRow('Platform Fee (8%)', 'RM ${platformFee.toStringAsFixed(2)}', valueColor: Colors.orange),
                        const Divider(height: 16),
                        _buildTxDetailRow('Vendor Net', 'RM ${vendorNet.toStringAsFixed(2)}', valueColor: Colors.green),
                        const Divider(height: 16),
                        _buildTxDetailRow('Payment Method', 'Credit Card (Visa •••4291)'),
                        const Divider(height: 16),
                        _buildTxDetailRow('Gateway Ref', 'ch_3N4kJL2eZvKYlo2C0${transaction.id.substring(0, 3)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Timeline
                  const Text(
                    'PAYMENT TIMELINE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  _buildTimelineItem('Payment initiated', transaction.date, Icons.play_arrow_rounded, Colors.blue),
                  _buildTimelineItem('Gateway authorized', '${transaction.date} +2s', Icons.verified_outlined, Colors.green),
                  if (transaction.status == 'paid' || transaction.status == 'completed')
                    _buildTimelineItem('Payment captured', '${transaction.date} +5s', Icons.check_circle_outline, Colors.green),
                  if (transaction.status == 'refunded')
                    _buildTimelineItem('Refund processed', '${transaction.date} +24h', Icons.replay, Colors.red),
                  const SizedBox(height: 20),

                  // Admin Notes
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note_alt_outlined, size: 16, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Admin Note: No issues flagged. Standard auto-settlement within T+2 business days.',
                            style: TextStyle(fontSize: 12, color: Colors.blue[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTxDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600])),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: valueColor ?? Colors.black87)),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          Text(time, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
        ],
      ),
    );
  }

  void _showDisputeReviewModal(Map<String, dynamic> dispute) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dispute Review: ${dispute['id']}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Customer Side
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person, size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 6),
                            Text(
                              'CUSTOMER EVIDENCE — ${dispute['customer']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.blue[700],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Statement: "${dispute['customerStatement']}"',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.photo_library_outlined, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('3 photo attachments uploaded', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            const SizedBox(width: 10),
                            Icon(Icons.videocam_outlined, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('1 video clip (02:14)', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Vendor Side
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.purple[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.store, size: 16, color: Colors.purple[700]),
                            const SizedBox(width: 6),
                            Text(
                              'VENDOR DEFENSE — ${dispute['vendor']}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.purple[700],
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Response: "${dispute['vendorResponse']}"',
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.receipt_long, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('Invoice and delivery receipt attached', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Booking Contract Summary
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CONTRACT TERMS',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1),
                        ),
                        const SizedBox(height: 8),
                        _buildTxDetailRow('Booking Amount', 'RM ${(dispute['disputedAmount'] as double).toStringAsFixed(2)}'),
                        const Divider(height: 12),
                        _buildTxDetailRow('Event', dispute['event'] ?? 'N/A'),
                        const Divider(height: 12),
                        _buildTxDetailRow('Package', dispute['package'] ?? 'N/A'),
                        const Divider(height: 12),
                        _buildTxDetailRow('Cancellation Policy', 'Flexible (>5 days = 50% refund)'),
                        const Divider(height: 12),
                        _buildTxDetailRow('Dispute Filed', dispute['createdAt'] ?? 'N/A'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Admin Resolution Notes
                  const Text(
                    'ADMIN RESOLUTION NOTES',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Record internal resolution notes here...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Resolution Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              dispute['status'] = 'Resolved';
                              dispute['payoutHeld'] = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Full refund of RM ${(dispute['disputedAmount'] as double).toStringAsFixed(2)} issued to ${dispute['customer']}.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.replay, size: 16),
                          label: const Text('Full Refund', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Partial refund (50%) processed successfully.')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.pie_chart_outline, size: 16),
                          label: const Text('Partial (50%)', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              dispute['status'] = 'Resolved';
                              dispute['payoutHeld'] = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dispute dismissed. Vendor payout released.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Dismiss', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showRefundDialog({required Map<String, dynamic> dispute}) {
    final refundAmountController = TextEditingController(
      text: (dispute['disputedAmount'] as double).toStringAsFixed(2),
    );
    String selectedReason = 'Service not delivered as agreed';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: SizedBox(
            width: 460,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Process Refund',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Refund Summary
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Refund to: ${dispute['customer']}', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('Booking: ${dispute['bookingId']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        Text('Vendor: ${dispute['vendor']}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Refund Amount
                  TextField(
                    controller: refundAmountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Refund Amount (RM)',
                      prefixText: 'RM ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Reason Dropdown
                  DropdownButtonFormField<String>(
                    value: selectedReason,
                    decoration: InputDecoration(
                      labelText: 'Refund Reason',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    items: [
                      'Service not delivered as agreed',
                      'Vendor no-show',
                      'Quality below expectations',
                      'Vendor cancellation',
                      'Customer cancellation (policy eligible)',
                      'Double charge / billing error',
                      'Goodwill refund',
                    ].map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => dialogSetState(() => selectedReason = v!),
                  ),
                  const SizedBox(height: 16),

                  // Refund Source
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('REFUND SOURCE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1)),
                        const SizedBox(height: 6),
                        _buildTxDetailRow('Vendor Balance Deduction', 'RM ${((dispute['disputedAmount'] as double) * 0.92).toStringAsFixed(2)}'),
                        const SizedBox(height: 4),
                        _buildTxDetailRow('Platform Fee Reversal', 'RM ${((dispute['disputedAmount'] as double) * 0.08).toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              dispute['status'] = 'Resolved';
                              dispute['payoutHeld'] = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Refund of RM ${refundAmountController.text} processed to ${dispute['customer']}. Vendor balance adjusted.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.replay, size: 16),
                          label: const Text('Confirm Refund'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _processPayout(Payout payout, AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Process Payout'),
        content: FutureBuilder<BankAccount?>(
          future: admin.getBankAccount(payout),
          builder: (context, snapshot) {
            final bank = snapshot.data;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vendor: ${payout.vendor}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Amount: RM ${payout.amount.toStringAsFixed(2)}'),
                const Divider(height: 24),
                
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: CircularProgressIndicator())
                else if (bank == null)
                  const Text('No bank details found for this vendor.',
                      style: TextStyle(color: Colors.red, fontSize: 12))
                else ...[
                  const Text('Bank Account Details:', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                  const SizedBox(height: 8),
                  Text('Bank: ${bank.bankName}'),
                  Text('Holder: ${bank.accountHolderName}'),
                  Row(
                    children: [
                      Text('Acc No: ${bank.accountNumber}'),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 16),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: bank.accountNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Account number copied')),
                          );
                        },
                        tooltip: 'Copy Account Number',
                      ),
                    ],
                  ),
                ],
                
                const Divider(height: 24),
                const Text(
                  'Choose payout method:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Manual: You transfer the money using your own bank portal, then mark this as paid.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            );
          }
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              admin.updatePayoutStatus(payout.id, 'completed');
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payout marked as manually paid')),
              );
            },
            child: const Text('Manual (Mark Paid)'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            onPressed: () async {
              final success = await admin.processAutomatedPayout(payout);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Automated Payout successful!'
                        : 'Automated Payout failed. Check logs.'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: const Text('Instant (Billplz Pay)'),
          ),
        ],
      ),
    );
  }

  void _exportTransactions(List<TransactionEntry> transactions) async {
  // Generate CSV from your model
  final csvBuffer = StringBuffer();
  csvBuffer.writeln("ID,Party,Amount,Status,Date");

  for (var t in transactions) {
    csvBuffer.writeln(
        "${t.id},${t.party},${t.amount},${t.status},${t.date}");
  }

  final csvData = csvBuffer.toString();

  if (kIsWeb) {
    // WEB DOWNLOAD
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "transactions.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
  } else {
    // MOBILE / DESKTOP
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/transactions.csv';
    final file = File(filePath);
    await file.writeAsString(csvData);
    await Share.shareXFiles([XFile(file.path)], text: "Transaction Report");
  }
}

  void _navigateToCommissionManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CommissionManagementScreen(),
      ),
    );
  }

void _generateReport(String type, List<TransactionEntry> transactions) async {
  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text("$type Report",
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: ["ID", "Party", "Amount (RM)", "Status", "Date"],
            data: transactions.map((t) {
              return [t.id, t.party, t.amount.toString(), t.status, t.date];
            }).toList(),
          ),
        ],
      ),
    ),
  );

  final pdfBytes = await pdf.save();

  if (kIsWeb) {
    final blob = html.Blob([pdfBytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "${type}_report.pdf")
      ..click();
    html.Url.revokeObjectUrl(url);
  } else {
    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/${type}_report.pdf';
    final file = File(filePath);
    await file.writeAsBytes(pdfBytes);
    await Share.shareXFiles([XFile(file.path)], text: "$type Report PDF");
  }
}
    }
