part of vendor_management;

class VendorUsersTab extends StatelessWidget {
  final List<AdminVendor> vendors;
  final AdminProvider admin;
  final _VendorManagementScreenState state;

  const VendorUsersTab({
    super.key,
    required this.vendors,
    required this.admin,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final vendorUsers = admin.users.where((user) => user.role == 'vendor').toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vendorUsers.length,
      itemBuilder: (context, index) {
        final vendorUser = vendorUsers[index];
        return state._buildVendorUserCardFromAppUser(vendorUser, admin);
      },
    );
  }
}