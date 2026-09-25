part of vendor_management;

class ServicesPackagesTab extends StatelessWidget {
  final List<AdminVendor> vendors;
  final AdminProvider admin;
  final _VendorManagementScreenState state;

  const ServicesPackagesTab({
    super.key,
    required this.vendors,
    required this.admin,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final allServices = VendorServicesData.getAllServices();

    // Group services by vendor
    final Map<String, List<VendorService>> servicesByVendor = {};
    for (final service in allServices) {
      if (!servicesByVendor.containsKey(service.vendorId)) {
        servicesByVendor[service.vendorId] = [];
      }
      servicesByVendor[service.vendorId]!.add(service);
    }

    // Filter vendors that have services
    final vendorsWithServices = vendors.where((vendor) =>
        servicesByVendor.containsKey(vendor.id) &&
        servicesByVendor[vendor.id]!.isNotEmpty).toList();

    return Column(
      children: [
        // Summary Cards
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: state._buildServiceStatCard(
                  'Total Services',
                  allServices.length.toString(),
                  Icons.design_services,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: state._buildServiceStatCard(
                  'Active Services',
                  allServices.whereType<VendorService>().where((s) => s.active).length.toString(),
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: state._buildServiceStatCard(
                  'Pending Approval',
                  allServices.whereType<VendorService>().where((s) => s.approvalStatus.toString() == 'pending').length.toString(),
                  Icons.pending,
                  Colors.orange,
                ),
              ),
            ],
          ),
        ),

        // Services List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: vendorsWithServices.length,
            itemBuilder: (context, index) {
              final vendor = vendorsWithServices[index];
              final vendorServices = servicesByVendor[vendor.id]!;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                child: ExpansionTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      Icons.business,
                      color: AppTheme.primaryColor,
                      size: 25,
                    ),
                  ),
                  title: Text(
                    vendor.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${vendor.category} • ${vendorServices.length} services'),
                      Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          Text(' ${vendor.rating.toStringAsFixed(1)}'),
                          const SizedBox(width: 16),
                          Text('${vendor.bookings} bookings'),
                        ],
                      ),
                    ],
                  ),
                  trailing: ElevatedButton.icon(
                    onPressed: () => state._showVendorServicesAndDocuments(vendor, vendorServices, admin),
                    icon: const Icon(Icons.more_vert, size: 16),
                    label: const Text('Actions'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                  children: vendorServices.map((service) => state._buildServiceItem(service, vendor, admin)).toList(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}