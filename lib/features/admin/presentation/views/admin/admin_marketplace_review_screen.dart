import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_networking_provider.dart';
import 'package:eventease/shared/widgets/marketplace_item_card.dart';
import 'package:eventease/shared/models/vendor_marketplace_item.dart';

class AdminMarketplaceReviewScreen extends StatefulWidget {
  const AdminMarketplaceReviewScreen({super.key});

  @override
  State<AdminMarketplaceReviewScreen> createState() => _AdminMarketplaceReviewScreenState();
}

class _AdminMarketplaceReviewScreenState extends State<AdminMarketplaceReviewScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Marketplace Review',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<VendorNetworkingProvider>(
        builder: (context, provider, child) {
          final pendingItems = provider.pendingMarketplaceItems;

          if (provider.isLoadingMarketplace) {
            return const Center(child: CircularProgressIndicator());
          }

          if (pendingItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: AppTheme.textSecondaryColor.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No pending items',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'All marketplace items have been reviewed.',
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pendingItems.length,
            itemBuilder: (context, index) {
              final item = pendingItems[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Card
                    MarketplaceItemCard(
                      item: item,
                      onTap: () => _showItemDetails(context, item),
                      onContactPressed: null, // Disable contact for admin
                      showContactButton: false,
                    ),
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _rejectItem(context, item),
                              icon: const Icon(Icons.close, color: Colors.white),
                              label: const Text('Reject'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approveItem(context, item),
                              icon: const Icon(Icons.check, color: Colors.white),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.successColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showItemDetails(BuildContext context, VendorMarketplaceItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Vendor: ${item.vendorName}'),
              const SizedBox(height: 8),
              Text('Type: ${item.typeDisplayName}'),
              const SizedBox(height: 8),
              Text('Price: RM ${item.currentPrice.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              if (item.location != null) ...[
                Text('Location: ${item.location}'),
                const SizedBox(height: 8),
              ],
              Text('Description: ${item.description}'),
              const SizedBox(height: 8),
              if (item.specifications.isNotEmpty) ...[
                const Text('Specifications:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...item.specifications.entries.map((e) => Text('${e.key}: ${e.value}')).toList(),
                const SizedBox(height: 8),
              ],
              if (item.tags.isNotEmpty) ...[
                const Text('Tags:', style: TextStyle(fontWeight: FontWeight.bold)),
                Wrap(
                  children: item.tags.map((tag) => Chip(label: Text('#$tag'))).toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _approveItem(BuildContext context, VendorMarketplaceItem item) async {
    final provider = Provider.of<VendorNetworkingProvider>(context, listen: false);
    await provider.approveMarketplaceItem(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item approved successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _rejectItem(BuildContext context, VendorMarketplaceItem item) async {
    final provider = Provider.of<VendorNetworkingProvider>(context, listen: false);
    await provider.rejectMarketplaceItem(item.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item rejected.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
