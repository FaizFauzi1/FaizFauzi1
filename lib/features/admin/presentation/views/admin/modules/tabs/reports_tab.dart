part of vendor_management;

class ReportsTab extends StatelessWidget {
  final List<AdminVendor> vendors;
  final AdminProvider admin;
  final _VendorManagementScreenState state;

  const ReportsTab({
    super.key,
    required this.vendors,
    required this.admin,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final totalVendors = vendors.length;
    final activeVendors = vendors.where((v) => !v.suspended && v.verified).length;
    final suspendedVendors = vendors.where((v) => v.suspended).length;
    final pendingVendors = admin.pendingApprovalVendors.length;
    final totalBookings = vendors.fold<int>(0, (sum, v) => sum + v.bookings);
    final averageRating = vendors.isEmpty ? 0.0 : vendors.map((v) => v.rating).reduce((a, b) => a + b) / vendors.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Vendor Reports & Analytics',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Summary Statistics
          const Text(
            'Overall Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              state._buildReportStatCard(
                'Total Vendors',
                totalVendors.toString(),
                Icons.business,
                Colors.blue,
              ),
              state._buildReportStatCard(
                'Active Vendors',
                activeVendors.toString(),
                Icons.check_circle,
                Colors.green,
              ),
              state._buildReportStatCard(
                'Suspended Vendors',
                suspendedVendors.toString(),
                Icons.block,
                Colors.red,
              ),
              state._buildReportStatCard(
                'Pending Approval',
                pendingVendors.toString(),
                Icons.pending,
                Colors.orange,
              ),
              state._buildReportStatCard(
                'Total Bookings',
                totalBookings.toString(),
                Icons.event,
                Colors.purple,
              ),
              state._buildReportStatCard(
                'Average Rating',
                averageRating.toStringAsFixed(1),
                Icons.star,
                Colors.amber,
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Report Actions
          const Text(
            'Generate Reports',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.download, color: AppTheme.primaryColor),
                    title: const Text('Export Vendors to CSV'),
                    subtitle: const Text('Download complete vendor list with all details'),
                    trailing: ElevatedButton(
                      onPressed: () => state._exportVendorsToCSV(context),
                      child: const Text('Export'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.analytics, color: AppTheme.primaryColor),
                    title: const Text('Performance Report'),
                    subtitle: const Text('Generate detailed performance analytics'),
                    trailing: ElevatedButton(
                      onPressed: () => state._generatePerformanceReport(vendors),
                      child: const Text('Generate'),
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.assessment, color: AppTheme.primaryColor),
                    title: const Text('Revenue Report'),
                    subtitle: const Text('Export revenue and booking statistics'),
                    trailing: ElevatedButton(
                      onPressed: () => state._generateRevenueReport(vendors),
                      child: const Text('Generate'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Category Breakdown
          const Text(
            'Vendors by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: state._buildCategoryBreakdown(vendors),
              ),
            ),
          ),
        ],
      ),
    );
  }
}