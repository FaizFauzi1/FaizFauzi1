import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/customer/data/providers/customer_provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/customer/data/models/customer.dart';
import 'package:eventease/features/support/data/models/customer_interaction.dart';

class AdminCrmDashboardScreen extends StatefulWidget {
  const AdminCrmDashboardScreen({super.key});

  @override
  State<AdminCrmDashboardScreen> createState() => _AdminCrmDashboardScreenState();
}

class _AdminCrmDashboardScreenState extends State<AdminCrmDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final customerProvider = Provider.of<CustomerProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    // Get global analytics across all vendors
    final allCustomers = customerProvider.customers;
    final allInteractions = customerProvider.interactions;

    // Calculate global metrics
    final totalCustomers = allCustomers.length;
    final totalRevenue = allCustomers.fold<double>(0.0, (sum, customer) => sum + customer.totalSpent);
    final averageOrderValue = totalCustomers > 0 ? totalRevenue / totalCustomers : 0.0;
    final totalInteractions = allInteractions.length;

    // Customer segments distribution
    final customerSegments = <CustomerSegment, int>{};
    for (final segment in CustomerSegment.values) {
      customerSegments[segment] = allCustomers.where((customer) => customer.segment == segment).length;
    }

    // Recent interactions (last 30 days)
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final recentInteractions = allInteractions
        .where((interaction) => interaction.timestamp.isAfter(thirtyDaysAgo))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Top customers globally
    final topCustomers = allCustomers
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent))
      ..take(10)
      .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin CRM Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Global Metrics Cards
            _buildGlobalMetricsGrid(
              totalCustomers: totalCustomers,
              totalRevenue: totalRevenue,
              averageOrderValue: averageOrderValue,
              totalInteractions: totalInteractions,
            ),

            const SizedBox(height: 24),

            // Customer Segments Chart
            _buildGlobalCustomerSegmentsCard(customerSegments),

            const SizedBox(height: 24),

            // Top Customers Globally
            _buildGlobalTopCustomersCard(topCustomers),

            const SizedBox(height: 24),

            // Recent Global Interactions
            _buildGlobalRecentInteractionsCard(recentInteractions),

            const SizedBox(height: 24),

            // Customer Insights
            _buildCustomerInsightsCard(allCustomers),

            const SizedBox(height: 24),

            // Vendor Performance Comparison
            _buildVendorPerformanceCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalMetricsGrid({
    required int totalCustomers,
    required double totalRevenue,
    required double averageOrderValue,
    required int totalInteractions,
  }) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Total Customers',
          totalCustomers.toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildMetricCard(
          'Total Revenue',
          'RM ${totalRevenue.toStringAsFixed(0)}',
          Icons.attach_money,
          Colors.green,
        ),
        _buildMetricCard(
          'Avg Order Value',
          'RM ${averageOrderValue.toStringAsFixed(0)}',
          Icons.shopping_cart,
          Colors.orange,
        ),
        _buildMetricCard(
          'Total Interactions',
          totalInteractions.toString(),
          Icons.message,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalCustomerSegmentsCard(Map<CustomerSegment, int> segments) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Global Customer Segments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...segments.entries.map((entry) {
              final percentage = segments.values.fold<int>(0, (sum, count) => sum + count) > 0
                  ? (entry.value / segments.values.fold<int>(0, (sum, count) => sum + count)) * 100
                  : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(_getSegmentDisplayName(entry.key)),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text('${entry.value}'),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(_getSegmentColor(entry.key)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${percentage.toStringAsFixed(1)}%'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalTopCustomersCard(List<Customer> topCustomers) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Customers Globally',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (topCustomers.isEmpty)
              const Center(
                child: Text('No customer data available'),
              )
            else
              ...topCustomers.map((customer) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(customer.name[0].toUpperCase()),
                  ),
                  title: Text(customer.name),
                  subtitle: Text(customer.email),
                  trailing: Text(
                    'RM ${customer.totalSpent.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  onTap: () => _showCustomerDetails(customer),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalRecentInteractionsCard(List<CustomerInteraction> interactions) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Global Interactions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (interactions.isEmpty)
              const Center(
                child: Text('No recent interactions'),
              )
            else
              ...interactions.take(10).map((interaction) {
                return ListTile(
                  leading: Icon(
                    _getInteractionIcon(interaction.type),
                    color: _getInteractionColor(interaction.type),
                  ),
                  title: Text(interaction.description),
                  subtitle: Text(
                    '${interaction.customerId} • ${interaction.vendorId} • ${_formatTimestamp(interaction.timestamp)}',
                  ),
                  trailing: interaction.isRead
                      ? null
                      : Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInsightsCard(List<Customer> customers) {
    // Calculate insights
    final activeCustomers = customers.where((c) => c.status == CustomerStatus.active).length;
    final vipCustomers = customers.where((c) => c.segment == CustomerSegment.vipCustomer).length;
    final avgBookingsPerCustomer = customers.isNotEmpty
        ? customers.fold<int>(0, (sum, c) => sum + c.totalBookings) / customers.length
        : 0.0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Insights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInsightRow('Active Customers', '$activeCustomers / ${customers.length}'),
            _buildInsightRow('VIP Customers', vipCustomers.toString()),
            _buildInsightRow('Avg Bookings per Customer', avgBookingsPerCustomer.toStringAsFixed(1)),
            _buildInsightRow('Customer Retention Rate', _calculateRetentionRate(customers)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorPerformanceCard() {
    // This would show performance comparison between vendors
    // For now, showing a placeholder
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vendor Performance Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Vendor performance metrics will be displayed here',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerDetails(Customer customer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${customer.email}'),
            Text('Total Spent: RM ${customer.totalSpent.toStringAsFixed(2)}'),
            Text('Total Bookings: ${customer.totalBookings}'),
            Text('Average Rating: ${customer.averageRating.toStringAsFixed(1)}'),
            Text('Segment: ${_getSegmentDisplayName(customer.segment)}'),
            Text('Status: ${customer.status.toString().split('.').last}'),
            Text('Last Active: ${_formatTimestamp(customer.lastActive)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _getSegmentDisplayName(CustomerSegment segment) {
    switch (segment) {
      case CustomerSegment.newCustomer:
        return 'New Customer';
      case CustomerSegment.regularCustomer:
        return 'Regular Customer';
      case CustomerSegment.vipCustomer:
        return 'VIP Customer';
      case CustomerSegment.inactiveCustomer:
        return 'Inactive Customer';
    }
  }

  Color _getSegmentColor(CustomerSegment segment) {
    switch (segment) {
      case CustomerSegment.newCustomer:
        return Colors.blue;
      case CustomerSegment.regularCustomer:
        return Colors.green;
      case CustomerSegment.vipCustomer:
        return Colors.purple;
      case CustomerSegment.inactiveCustomer:
        return Colors.grey;
    }
  }

  IconData _getInteractionIcon(InteractionType type) {
    switch (type) {
      case InteractionType.bookingCreated:
      case InteractionType.bookingAccepted:
      case InteractionType.bookingRejected:
      case InteractionType.bookingCompleted:
      case InteractionType.bookingCancelled:
        return Icons.event;
      case InteractionType.messageSent:
      case InteractionType.messageReceived:
        return Icons.message;
      case InteractionType.reviewSubmitted:
        return Icons.star;
      case InteractionType.favoriteAdded:
      case InteractionType.favoriteRemoved:
        return Icons.favorite;
      case InteractionType.profileViewed:
      case InteractionType.serviceViewed:
        return Icons.visibility;
      case InteractionType.paymentMade:
        return Icons.payment;
      case InteractionType.refundRequested:
        return Icons.undo;
      case InteractionType.complaintFiled:
        return Icons.report;
      case InteractionType.inquirySubmitted:
        return Icons.help;
      default:
        return Icons.info;
    }
  }

  Color _getInteractionColor(InteractionType type) {
    switch (type) {
      case InteractionType.bookingCreated:
        return Colors.blue;
      case InteractionType.bookingAccepted:
        return Colors.green;
      case InteractionType.bookingRejected:
      case InteractionType.bookingCancelled:
        return Colors.red;
      case InteractionType.bookingCompleted:
        return Colors.purple;
      case InteractionType.messageSent:
      case InteractionType.messageReceived:
        return Colors.orange;
      case InteractionType.reviewSubmitted:
        return Colors.amber;
      case InteractionType.favoriteAdded:
        return Colors.pink;
      case InteractionType.favoriteRemoved:
        return Colors.grey;
      case InteractionType.profileViewed:
      case InteractionType.serviceViewed:
        return Colors.teal;
      case InteractionType.paymentMade:
        return Colors.green;
      case InteractionType.refundRequested:
        return Colors.orange;
      case InteractionType.complaintFiled:
        return Colors.red;
      case InteractionType.inquirySubmitted:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _calculateRetentionRate(List<Customer> customers) {
    if (customers.isEmpty) return '0%';

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final activeCustomers = customers.where((c) => c.lastActive.isAfter(thirtyDaysAgo)).length;
    final rate = (activeCustomers / customers.length) * 100;

    return '${rate.toStringAsFixed(1)}%';
  }
}
