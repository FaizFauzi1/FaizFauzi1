import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';

class VendorListScreen extends StatelessWidget {
  const VendorListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vendorProvider = Provider.of<VendorProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendors'),
      ),
      body: vendorProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : vendorProvider.error != null
              ? Center(child: Text(vendorProvider.error!))
              : ListView.builder(
                  itemCount: vendorProvider.vendors.length,
                  itemBuilder: (context, index) {
                    final vendor = vendorProvider.vendors[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(vendor.name.isNotEmpty
                              ? vendor.name[0].toUpperCase()
                              : '?'),
                        ),
                        title: Text(vendor.name),
                        subtitle: Text('${vendor.category} • ${vendor.serviceAreas.join(", ")}'),
                        trailing: vendor.verified
                            ? const Icon(Icons.verified, color: Colors.green)
                            : null,
                        onTap: () {
                          _showVendorDetailsDialog(context, vendor);
                        },
                      ),
                    );
                  },
                ),
    );
  }

  void _showVendorDetailsDialog(BuildContext context, AdminVendor vendor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(vendor.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Category: ${vendor.category}'),
            Text('Rating: ${vendor.rating.toStringAsFixed(1)}'),
            Text('Reviews: ${vendor.reviews}'),
            Text('Bookings: ${vendor.bookings}'),
            Text('Service Areas: ${vendor.serviceAreas.join(", ")}'),
            Text('Status: ${vendor.suspended ? 'Suspended' : 'Active'}'),
            Text('Verified: ${vendor.verified ? 'Yes' : 'No'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
