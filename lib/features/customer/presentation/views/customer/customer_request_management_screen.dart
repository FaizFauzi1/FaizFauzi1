import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/support/data/models/customer_request.dart';
import 'package:eventease/features/support/data/providers/request_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'customer_request_screen.dart';

class CustomerRequestManagementScreen extends StatefulWidget {
  final String customerId;

  const CustomerRequestManagementScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<CustomerRequestManagementScreen> createState() => _CustomerRequestManagementScreenState();
}

class _CustomerRequestManagementScreenState extends State<CustomerRequestManagementScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<RequestProvider>(
      builder: (context, requestProvider, child) {
        final customerRequests = requestProvider.getCustomerRequests(widget.customerId);

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: AppBar(
            title: const Text('My Quote Requests', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: AppTheme.textPrimaryColor,
          ),
          body: customerRequests.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => requestProvider.loadRequests(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: customerRequests.length,
                    itemBuilder: (context, index) {
                      final request = customerRequests[index];
                      return _buildRequestCard(request, requestProvider);
                    },
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerRequestScreen(
                    customerId: widget.customerId,
                    customerName: 'Customer User',
                  ),
                ),
              );
            },
            backgroundColor: AppTheme.primaryColor,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.request_quote_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            'No requests yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 8),
          const Text(
            'Submit a request to get custom quotes from vendors.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
               Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CustomerRequestScreen(
                    customerId: widget.customerId,
                    customerName: 'Customer User',
                  ),
                ),
              );
            },
            child: const Text('Create Your First Request'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(CustomerRequest request, RequestProvider provider) {
    final statusColor = _getStatusColor(request.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          title: Text(
            '${request.eventCategory.displayName} - ${request.eventType}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                _buildChip(request.status.displayName, statusColor),
                const SizedBox(width: 8),
                _buildChip('${request.offers.length} Offers', Colors.blue),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(Icons.calendar_today, 'Date', request.eventDate.toLocal().toString().split(' ')[0]),
                  _buildDetailRow(Icons.location_on, 'Location', request.location),
                  _buildDetailRow(Icons.payments, 'Budget', 'RM ${request.budget.toStringAsFixed(2)}'),
                  _buildDetailRow(Icons.description, 'Needs', request.description),
                  const Divider(height: 32),
                  const Text('Offers from Vendors', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (request.offers.isEmpty)
                    const Text('Waiting for vendors to respond...', style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textSecondaryColor))
                  else
                    ...request.offers.map((offer) => _buildOfferItem(offer, request, provider)).toList(),
                  
                  const SizedBox(height: 24),
                  // Delete Action
                   Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => _confirmDelete(context, request, provider),
                      icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      label: const Text('Delete Request', style: TextStyle(color: Colors.red)),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),

                  if (request.status == RequestStatus.pending)
                    const SizedBox.shrink() // Placeholder
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondaryColor),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor))),
        ],
      ),
    );
  }

  Widget _buildOfferItem(RequestOffer offer, CustomerRequest request, RequestProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(offer.vendorName, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('RM ${offer.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text(offer.message, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor)),
          if (request.status == RequestStatus.offered) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => provider.acceptOffer(request.id, offer.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text('Accept Offer', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // Navigate to chat
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 32),
                      padding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                    child: const Text('Chat', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, CustomerRequest request, RequestProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Request?'),
        content: const Text('Are you sure you want to delete this request? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop(); // Close dialog
              await provider.deleteRequest(request.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request deleted successfully')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.pending: return Colors.orange;
      case RequestStatus.offered: return Colors.blue;
      case RequestStatus.accepted: return AppTheme.successColor;
      case RequestStatus.rejected: return AppTheme.errorColor;
      case RequestStatus.completed: return Colors.purple;
    }
  }
}
