part of vendor_management;

class AllVendorsTab extends StatefulWidget {
  final List<AdminVendor> vendors;
  final AdminProvider admin;
  final _VendorManagementScreenState state;

  const AllVendorsTab({super.key, required this.vendors, required this.admin, required this.state});

  @override
  State<AllVendorsTab> createState() => _AllVendorsTabState();
}

class _AllVendorsTabState extends State<AllVendorsTab> {
  final Map<String, List<VendorDocument>> _documents = {};

  @override
  void initState() {
    super.initState();
    _loadVendorUserDocuments();
  }

  void _loadVendorUserDocuments() {
    final vendorUsers = widget.admin.users.where((user) => user.role == 'vendor').toList();
    for (final user in vendorUsers) {
      if (!_documents.containsKey(user.id)) {
        widget.admin.getVendorDocuments(user.id).then((docs) {
          if (mounted) {
            setState(() {
              _documents[user.id] = docs;
            });
          }
        }).catchError((error) {
          print('Error loading documents for user ${user.id}: $error');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendorUsers = widget.admin.users.where((user) => user.role == 'vendor').toList();

    // Combine vendors and vendor users to ensure vendor users are counted as vendors
    final allVendors = [...widget.vendors];
    for (final user in vendorUsers) {
      if (!allVendors.any((v) => v.id == user.id)) {
        // Get loaded documents for vendor users
        final docs = _documents[user.id] ?? [];
        allVendors.add(AdminVendor(
          user.id,
          user.name,
          'Vendor', // Default category for vendor users
          false, // verified
          false, // suspended
          0.0, // rating
          0, // reviews
          0, // bookings
          [], // serviceAreas
          false, // pendingApproval
          documents: docs,
          documentsVerified: docs.isNotEmpty && docs.every((d) => d.isVerified),
        ));
      }
    }

    final filteredVendors = widget.state._filterVendors(allVendors);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredVendors.length,
      itemBuilder: (context, index) {
        final vendor = filteredVendors[index];
        return widget.state._buildVendorCard(
          context, 
          vendor, 
          widget.admin, 
          showActions: true,
          isPending: vendor.pendingApproval,
          isSuspended: vendor.suspended,
        );
      },
    );
  }
}
