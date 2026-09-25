import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/customer/data/providers/customer_provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/customer/data/models/customer.dart';
import 'package:eventease/features/support/data/models/customer_interaction.dart';
import 'package:eventease/shared/widgets/common_navbar.dart';

class CrmDashboardScreen extends StatefulWidget {
  const CrmDashboardScreen({super.key});

  @override
  State<CrmDashboardScreen> createState() => _CrmDashboardScreenState();
}

class _CrmDashboardScreenState extends State<CrmDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final customerProvider = Provider.of<CustomerProvider>(context);
    final vendorId = authProvider.userEmail; // Using email as vendor ID

    final analytics = customerProvider.getCustomerAnalytics(vendorId);
    final customers = customerProvider.getCustomersForVendor(vendorId);
    final recentInteractions = customerProvider.getRecentInteractions(vendorId, limit: 10);
    final customerSegments = customerProvider.getCustomerSegments(vendorId);
    final topCustomers = customerProvider.getTopCustomersBySpending(vendorId, limit: 5);
    final recommendations = customerProvider.getCustomerRecommendations(vendorId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: const CommonNavbar(currentIndex: 4), // Profile/Account tab
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Key Metrics Cards
            _buildMetricsGrid(analytics),

            const SizedBox(height: 24),

            // Customer Segments Chart
            _buildCustomerSegmentsCard(customerSegments),

            const SizedBox(height: 24),

            // Top Customers
            _buildTopCustomersCard(topCustomers),

            const SizedBox(height: 24),

            // Recent Interactions
            _buildRecentInteractionsCard(recentInteractions),

            const SizedBox(height: 24),

            // Recommendations
            if (recommendations.isNotEmpty) _buildRecommendationsCard(recommendations),

            const SizedBox(height: 24),

            // Customer List
            _buildCustomerListCard(customers),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(Map<String, dynamic> analytics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildMetricCard(
          'Total Customers',
          analytics['totalCustomers'].toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildMetricCard(
          'New Customers',
          analytics['newCustomers'].toString(),
          Icons.person_add,
          Colors.green,
        ),
        _buildMetricCard(
          'Total Revenue',
          'RM ${analytics['totalRevenue'].toStringAsFixed(0)}',
          Icons.attach_money,
          Colors.purple,
        ),
        _buildMetricCard(
          'Avg Order Value',
          'RM ${analytics['averageOrderValue'].toStringAsFixed(0)}',
          Icons.shopping_cart,
          Colors.orange,
        ),
        _buildMetricCard(
          'Retention Rate',
          '${analytics['customerRetentionRate'].toStringAsFixed(1)}%',
          Icons.refresh,
          Colors.teal,
        ),
        _buildMetricCard(
          'Recent Interactions',
          analytics['recentInteractions'].toString(),
          Icons.message,
          Colors.indigo,
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

  Widget _buildCustomerSegmentsCard(Map<CustomerSegment, int> segments) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customer Segments',
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

  Widget _buildTopCustomersCard(List<Customer> topCustomers) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Customers by Spending',
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

  Widget _buildRecentInteractionsCard(List<CustomerInteraction> interactions) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Customer Interactions',
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
              ...interactions.map((interaction) {
                return ListTile(
                  leading: Icon(
                    _getInteractionIcon(interaction.type),
                    color: _getInteractionColor(interaction.type),
                  ),
                  title: Text(interaction.description),
                  subtitle: Text(
                    '${interaction.customerId} • ${_formatTimestamp(interaction.timestamp)}',
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

  Widget _buildRecommendationsCard(List<String> recommendations) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Recommendations',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recommendations.map((recommendation) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb, color: Colors.amber),
                    const SizedBox(width: 8),
                    Expanded(child: Text(recommendation)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerListCard(List<Customer> customers) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Customers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showAllCustomers(customers),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (customers.isEmpty)
              const Center(
                child: Text('No customers yet'),
              )
            else
              ...customers.take(5).map((customer) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text(customer.name[0].toUpperCase()),
                  ),
                  title: Text(customer.name),
                  subtitle: Text('${customer.totalBookings} bookings • RM ${customer.totalSpent.toStringAsFixed(0)} spent'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getSegmentColor(customer.segment).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getSegmentDisplayName(customer.segment),
                      style: TextStyle(
                        color: _getSegmentColor(customer.segment),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
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

  void _showAllCustomers(List<Customer> customers) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final customer = customers[index];
            return ListTile(
              leading: CircleAvatar(
                child: Text(customer.name[0].toUpperCase()),
              ),
              title: Text(customer.name),
              subtitle: Text(customer.email),
              onTap: () {
                Navigator.of(context).pop();
                _showCustomerDetails(customer);
              },
            );
          },
        ),
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
}
