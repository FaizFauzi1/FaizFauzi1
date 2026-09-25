import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Admin screen for overseeing all installment payments across the platform.
/// All data is fetched live from Supabase installment_plans / installment_payments tables.
class AdminInstallmentManagementScreen extends StatefulWidget {
  const AdminInstallmentManagementScreen({Key? key}) : super(key: key);

  @override
  State<AdminInstallmentManagementScreen> createState() =>
      _AdminInstallmentManagementScreenState();
}

class _AdminInstallmentManagementScreenState
    extends State<AdminInstallmentManagementScreen> {
  String _selectedView = 'overview'; // overview, vendors, overdue

  bool _isLoading = true;
  String? _error;

  Map<String, dynamic> _systemSummary = {};
  List<Map<String, dynamic>> _vendors = [];
  List<Map<String, dynamic>> _overduePayments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;

      // Load overview stats
      final plansResponse = await client
          .from('installment_plans')
          .select('id, total_amount, amount_paid, status, vendor_id')
          .timeout(const Duration(seconds: 15));

      final plans = List<Map<String, dynamic>>.from(plansResponse);
      double totalRevenue = 0;
      double totalOutstanding = 0;
      double totalCollected = 0;
      int activePlans = 0;
      final Set<String> vendorIds = {};

      for (final plan in plans) {
        final total = (plan['total_amount'] as num?)?.toDouble() ?? 0;
        final paid = (plan['amount_paid'] as num?)?.toDouble() ?? 0;
        totalRevenue += total;
        totalCollected += paid;
        totalOutstanding += (total - paid).clamp(0, double.infinity);
        if (plan['status'] == 'active') activePlans++;
        if (plan['vendor_id'] != null) vendorIds.add(plan['vendor_id'] as String);
      }

      // Overdue payments
      final overdueResponse = await client
          .from('installment_payments')
          .select(
              'id, amount, due_date, status, installment_plan_id, installment_plans(vendor_id, vendor_profiles(business_name), bookings(customer_id, users(full_name, email, phone_number), services(name)))')
          .eq('status', 'overdue')
          .order('due_date', ascending: true)
          .timeout(const Duration(seconds: 15));

      final overdueRaw = List<Map<String, dynamic>>.from(overdueResponse);
      final List<Map<String, dynamic>> overdue = overdueRaw.map((row) {
        final plan = row['installment_plans'] as Map<String, dynamic>?;
        final booking = (plan?['bookings']) as Map<String, dynamic>?;
        final user = (booking?['users']) as Map<String, dynamic>?;
        final service = (booking?['services']) as Map<String, dynamic>?;
        final vendor = (plan?['vendor_profiles']) as Map<String, dynamic>?;
        final dueDate = DateTime.tryParse(row['due_date'] as String? ?? '');
        final daysOverdue =
            dueDate != null ? DateTime.now().difference(dueDate).inDays : 0;
        return {
          'customer_name': user?['full_name'] ?? 'Unknown',
          'customer_email': user?['email'] ?? '',
          'customer_phone': user?['phone_number'] ?? '',
          'vendor_name': vendor?['business_name'] ?? 'Unknown Vendor',
          'service_name': service?['name'] ?? 'Unknown Service',
          'amount_due': (row['amount'] as num?)?.toDouble() ?? 0,
          'due_date': dueDate ?? DateTime.now(),
          'days_overdue': daysOverdue.clamp(0, 9999),
        };
      }).toList();

      // Vendor breakdown
      final vendorBreakdown = <Map<String, dynamic>>[];
      if (vendorIds.isNotEmpty) {
        for (final vId in vendorIds) {
          final vendorPlans =
              plans.where((p) => p['vendor_id'] == vId).toList();
          double vTotal = 0;
          double vOutstanding = 0;
          int vActive = 0;
          int vLate = overdue.where((o) {
            // approximate: match by vendor name since we don't carry vendor_id in overdue list
            return vendorPlans.isNotEmpty;
          }).length;

          for (final vp in vendorPlans) {
            final t = (vp['total_amount'] as num?)?.toDouble() ?? 0;
            final p = (vp['amount_paid'] as num?)?.toDouble() ?? 0;
            vTotal += t;
            vOutstanding += (t - p).clamp(0, double.infinity);
            if (vp['status'] == 'active') vActive++;
          }

          // Fetch vendor name
          String vendorName = vId;
          try {
            final vpRes = await client
                .from('vendor_profiles')
                .select('business_name')
                .eq('id', vId)
                .maybeSingle();
            vendorName = (vpRes?['business_name'] as String?) ?? vId;
          } catch (_) {}

          vendorBreakdown.add({
            'vendor_id': vId,
            'vendor_name': vendorName,
            'total_revenue': vTotal,
            'outstanding': vOutstanding,
            'active_plans': vActive,
            'late_payments': vLate,
            'collection_rate': vTotal > 0 ? (vTotal - vOutstanding) / vTotal : 0.0,
          });
        }
      }

      final lateCount = overdue.length;
      final collectionRate = totalRevenue > 0
          ? totalCollected / totalRevenue
          : 0.0;

      setState(() {
        _systemSummary = {
          'total_platform_revenue': totalRevenue,
          'total_outstanding': totalOutstanding,
          'total_collected': totalCollected,
          'active_plans': activePlans,
          'late_payments': lateCount,
          'collection_rate': collectionRate,
          'vendors_with_plans': vendorIds.length,
        };
        _vendors = vendorBreakdown;
        _overduePayments = overdue;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('AdminInstallmentManagementScreen error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
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
          'Installment Management',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            tooltip: 'Refresh',
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load installment data.\n$_error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppTheme.textSecondaryColor),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildViewSelector(),
                      const SizedBox(height: 24),
                      if (_selectedView == 'overview') ...[
                        _buildSystemSummary(),
                        const SizedBox(height: 24),
                        _buildQuickStats(),
                      ] else if (_selectedView == 'vendors') ...[
                        _buildVendorBreakdown(),
                      ] else if (_selectedView == 'overdue') ...[
                        _buildOverduePayments(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildViewSelector() {
    return Row(
      children: [
        Expanded(child: _buildViewButton('Overview', 'overview', Icons.dashboard)),
        const SizedBox(width: 12),
        Expanded(child: _buildViewButton('Vendors', 'vendors', Icons.store)),
        const SizedBox(width: 12),
        Expanded(child: _buildViewButton('Overdue', 'overdue', Icons.warning)),
      ],
    );
  }

  Widget _buildViewButton(String label, String value, IconData icon) {
    final isSelected = _selectedView == value;
    return ElevatedButton.icon(
      onPressed: () => setState(() => _selectedView = value),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.white,
        foregroundColor:
            isSelected ? Colors.white : AppTheme.textSecondaryColor,
        elevation: isSelected ? 4 : 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color:
                isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  Widget _buildSystemSummary() {
    final summary = _systemSummary;
    if (summary.isEmpty) {
      return const Center(child: Text('No data available.'));
    }
    return Container(
      padding: const EdgeInsets.all(24),
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
            'Platform Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Revenue',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${(summary['total_platform_revenue'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white, size: 32),
                    const SizedBox(height: 4),
                    Text(
                      '${((summary['collection_rate'] as double) * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text('Collection Rate',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildSummaryMetric(
                  'Outstanding',
                  'RM ${(summary['total_outstanding'] as double).toStringAsFixed(2)}',
                  Icons.hourglass_empty,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryMetric(
                  'Collected',
                  'RM ${(summary['total_collected'] as double).toStringAsFixed(2)}',
                  Icons.check_circle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final summary = _systemSummary;
    final activePlans = summary['active_plans'] as int? ?? 0;
    final latePayments = summary['late_payments'] as int? ?? 0;
    final vendorCount = summary['vendors_with_plans'] as int? ?? 0;
    final avgPlanValue =
        activePlans > 0 ? (summary['total_platform_revenue'] as double) / activePlans : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick Statistics',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Active Plans', '$activePlans',
                  Icons.calendar_month, Colors.blue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Late Payments', '$latePayments',
                  Icons.warning, Colors.red),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                  'Vendors', '$vendorCount', Icons.store, Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                  'Avg. Plan Value',
                  'RM ${avgPlanValue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.purple),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _buildVendorBreakdown() {
    if (_vendors.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No vendor installment data found.',
              style: TextStyle(color: AppTheme.textSecondaryColor)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Vendor Breakdown',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor)),
        const SizedBox(height: 16),
        ..._vendors.map((vendor) => _buildVendorCard(vendor)),
      ],
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    final collectionRate = (vendor['collection_rate'] as double?) ?? 0.0;
    final hasLatePayments = ((vendor['late_payments'] as int?) ?? 0) > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasLatePayments ? Colors.orange.shade200 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.store, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor['vendor_name'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('${vendor['active_plans']} active plans',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ),
              if (hasLatePayments)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${vendor['late_payments']} LATE',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildVendorMetric('Total Revenue',
                    'RM ${(vendor['total_revenue'] as double).toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildVendorMetric('Outstanding',
                    'RM ${(vendor['outstanding'] as double).toStringAsFixed(2)}'),
              ),
              Expanded(
                child: _buildVendorMetric('Collection',
                    '${(collectionRate * 100).toStringAsFixed(0)}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVendorMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppTheme.textSecondaryColor)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor)),
      ],
    );
  }

  Widget _buildOverduePayments() {
    if (_overduePayments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 12),
              Text('No overdue payments! Great job.',
                  style: TextStyle(color: AppTheme.textSecondaryColor)),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            const Text('Overdue Payments',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor)),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_overduePayments.length} payments require attention',
          style: const TextStyle(
              fontSize: 14, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 16),
        ..._overduePayments.map((payment) => _buildOverdueCard(payment)),
      ],
    );
  }

  Widget _buildOverdueCard(Map<String, dynamic> payment) {
    final daysOverdue = (payment['days_overdue'] as int?) ?? 0;
    final severity =
        daysOverdue > 10 ? 'critical' : daysOverdue > 5 ? 'high' : 'medium';
    final severityColor = severity == 'critical'
        ? Colors.red
        : severity == 'high'
            ? Colors.orange
            : Colors.yellow.shade700;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor, width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(payment['customer_name'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(payment['vendor_name'] as String? ?? '',
                        style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$daysOverdue DAYS LATE',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(payment['service_name'] as String? ?? '',
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textPrimaryColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Amount Due',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor)),
                    Text(
                      'RM ${(payment['amount_due'] as double).toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Due Date',
                        style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor)),
                    Text(
                      DateFormat('MMM dd, yyyy')
                          .format(payment['due_date'] as DateTime),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              const Icon(Icons.email, size: 14, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 6),
              Text(payment['customer_email'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondaryColor)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone, size: 14, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 6),
              Text(payment['customer_phone'] as String? ?? '',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondaryColor)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Notification sent to customer')),
                    );
                  },
                  icon: const Icon(Icons.notifications, size: 16),
                  label: const Text('Notify Customer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Notification sent to vendor')),
                    );
                  },
                  icon: const Icon(Icons.store, size: 16),
                  label: const Text('Notify Vendor'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
