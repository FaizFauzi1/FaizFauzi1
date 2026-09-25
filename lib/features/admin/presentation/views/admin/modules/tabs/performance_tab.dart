part of vendor_management;

class PerformanceTab extends StatelessWidget {
  final List<AdminVendor> vendors;
  final AdminProvider admin;
  final _VendorManagementScreenState state;

  const PerformanceTab({
    super.key,
    required this.vendors,
    required this.admin,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    // Sort vendors by performance (rating * bookings)
    final sortedVendors = List<AdminVendor>.from(vendors)
      ..sort(
          (a, b) => (b.rating * b.bookings).compareTo(a.rating * a.bookings));

    if (sortedVendors.isEmpty) {
      return const Center(
        child: Text(
          'No vendors available for performance analysis',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        // Performance Summary Cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: state._buildPerformanceStatCard(
                  'Top Performer',
                  sortedVendors.first.name,
                  '${sortedVendors.first.rating}★',
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: state._buildPerformanceStatCard(
                  'Most Bookings',
                  sortedVendors
                      .reduce((a, b) => a.bookings > b.bookings ? a : b)
                      .name,
                  '${sortedVendors.reduce((a, b) => a.bookings > b.bookings ? a : b).bookings}',
                  Colors.blue,
                ),
              ),
            ],
          ),
        ),

        // Performance List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedVendors.length,
            itemBuilder: (context, index) {
              final vendor = sortedVendors[index];
              final performanceScore = vendor.rating * vendor.bookings;
              return state._buildPerformanceCard(vendor, performanceScore, index + 1);
            },
          ),
        ),
      ],
    );
  }
}