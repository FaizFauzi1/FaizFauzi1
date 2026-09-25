part of vendor_management;

class AnalyticsTab extends StatelessWidget {
  final List<AdminVendor> vendors;
  final AdminProvider admin;
  final _VendorManagementScreenState state;

  const AnalyticsTab({
    super.key,
    required this.vendors,
    required this.admin,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final totalVendors = vendors.length;
    final activeVendors = vendors.where((v) => !v.suspended && v.verified).length;
    final totalBookings = vendors.fold<int>(0, (sum, v) => sum + v.bookings);
    final averageRating = vendors.isEmpty ? 0.0 : vendors.map((v) => v.rating).reduce((a, b) => a + b) / vendors.length;
    final totalRevenue = vendors.fold<double>(0, (sum, vendor) => sum + (vendor.bookings * 100));

    // Category analytics
    final categoryStats = <String, Map<String, dynamic>>{};
    for (final vendor in vendors) {
      if (!categoryStats.containsKey(vendor.category)) {
        categoryStats[vendor.category] = {
          'count': 0,
          'totalBookings': 0,
          'totalRating': 0.0,
          'totalRevenue': 0.0,
        };
      }
      categoryStats[vendor.category]!['count']++;
      categoryStats[vendor.category]!['totalBookings'] += vendor.bookings;
      categoryStats[vendor.category]!['totalRating'] += vendor.rating;
      categoryStats[vendor.category]!['totalRevenue'] += vendor.bookings * 100;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Vendor Analytics Dashboard',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Key Metrics Cards
          Row(
            children: [
              Expanded(
                child: state._buildAnalyticsMetricCard(
                  'Total Revenue',
                  'RM ${totalRevenue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: state._buildAnalyticsMetricCard(
                  'Avg Rating',
                  averageRating.toStringAsFixed(1),
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: state._buildAnalyticsMetricCard(
                  'Total Bookings',
                  totalBookings.toString(),
                  Icons.event,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: state._buildAnalyticsMetricCard(
                  'Active Vendors',
                  '$activeVendors/$totalVendors',
                  Icons.business,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Category Performance
          const Text(
            'Category Performance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...categoryStats.entries.map((entry) {
            final category = entry.key;
            final stats = entry.value;
            final avgRating = stats['totalRating'] / stats['count'];
            final revenue = stats['totalRevenue'];

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          category,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${stats['count']} vendors',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Revenue',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'RM ${revenue.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Avg Rating',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 16),
                                  Text(
                                    avgRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Bookings',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${stats['totalBookings']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 32),

          // Performance Insights
          const Text(
            'Performance Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  state._buildInsightItem(
                    'Top Performing Category',
                    categoryStats.entries.isEmpty
                        ? 'N/A'
                        : categoryStats.entries
                            .reduce((a, b) => a.value['totalRevenue'] > b.value['totalRevenue'] ? a : b)
                            .key,
                    Icons.trending_up,
                    Colors.green,
                  ),
                  const Divider(),
                  state._buildInsightItem(
                    'Highest Rated Category',
                    categoryStats.entries.isEmpty
                        ? 'N/A'
                        : categoryStats.entries
                            .reduce((a, b) => (a.value['totalRating'] / a.value['count']) > (b.value['totalRating'] / b.value['count']) ? a : b)
                            .key,
                    Icons.star,
                    Colors.amber,
                  ),
                  const Divider(),
                  state._buildInsightItem(
                    'Most Active Category',
                    categoryStats.entries.isEmpty
                        ? 'N/A'
                        : categoryStats.entries
                            .reduce((a, b) => a.value['totalBookings'] > b.value['totalBookings'] ? a : b)
                            .key,
                    Icons.event,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}