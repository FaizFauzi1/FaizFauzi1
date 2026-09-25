import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/support/data/models/customer_request.dart';
import 'package:eventease/features/support/data/providers/request_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';

class VendorRequestManagementScreen extends StatefulWidget {
  final String vendorId;
  final String vendorName;

  const VendorRequestManagementScreen({
    super.key,
    required this.vendorId,
    required this.vendorName,
  });

  @override
  State<VendorRequestManagementScreen> createState() => _VendorRequestManagementScreenState();
}

class _VendorRequestManagementScreenState extends State<VendorRequestManagementScreen> {
  @override
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RequestProvider>(context, listen: false).loadVendorRequests(widget.vendorId, widget.vendorName);
    });
  }

  void _showOfferDialog(CustomerRequest request) {
    final _priceController = TextEditingController();
    final _messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Offer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (RM)'),
            ),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(_priceController.text);
              final message = _messageController.text.trim();
              if (price == null || message.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid price and message')),
                );
                return;
              }
              final offer = RequestOffer(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                vendorId: widget.vendorId,
                vendorName: widget.vendorName,
                price: price,
                message: message,
                createdAt: DateTime.now(),
              );
              Provider.of<RequestProvider>(context, listen: false).addOffer(request.id, offer);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offer submitted')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, requestProvider, child) {
        final requests = requestProvider.vendorRequests;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Customer Requests'),
            backgroundColor: AppTheme.primaryColor,
          ),
          body: requests.isEmpty
              ? const Center(child: Text('No customer requests available'))
              : RefreshIndicator(
                  onRefresh: () async {
                    // Reload vendor requests
                    requestProvider.loadVendorRequests(widget.vendorId, widget.vendorName);
                  },
                  child: ListView.builder(
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text('${request.eventCategory.displayName} - ${request.eventType}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Date: ${request.eventDate.toLocal().toString().split(' ')[0]}'),
                              Text('Budget: RM ${request.budget.toStringAsFixed(2)}'),
                              Text('Description: ${request.description}'),
                              Text('Status: ${request.status.displayName}'),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: request.status == RequestStatus.pending
                              ? ElevatedButton(
                                  onPressed: () => _showOfferDialog(request),
                                  child: const Text('Make Offer'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                  ),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
        );
      },
    );
  }
}
