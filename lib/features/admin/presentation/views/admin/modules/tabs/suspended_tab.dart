part of vendor_management;

class SuspendedTab extends StatelessWidget {
  final List<AdminVendor> vendors;
  final AdminProvider admin;
  final _VendorManagementScreenState state;

  const SuspendedTab({
    super.key,
    required this.vendors,
    required this.admin,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vendors.length,
      itemBuilder: (context, index) {
        final vendor = vendors[index];
        return state._buildVendorCard(context, vendor, admin,
            showActions: true, isSuspended: true);
      },
    );
  }
}