import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/shared/models/gift_registry.dart';
import 'package:eventease/features/gift_registry/data/providers/gift_registry_provider.dart';

class GiftRegistryScreen extends StatefulWidget {
  final Event event;

  const GiftRegistryScreen({
    super.key,
    required this.event,
  });

  @override
  State<GiftRegistryScreen> createState() => _GiftRegistryScreenState();
}

class _GiftRegistryScreenState extends State<GiftRegistryScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => 
      Provider.of<GiftRegistryProvider>(context, listen: false)
          .loadRegistryForEvent(widget.event.id)
    );
  }

  @override
  Widget build(BuildContext context) {
    // Check if gift registry feature is enabled
    final guestFeatures = widget.event.additionalInfo['guestFeatures'] as Map<String, dynamic>? ?? {};
    final isGiftRegistryEnabled = guestFeatures['Gift Registry'] ?? true;

    if (!isGiftRegistryEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Gift Registry'),
          elevation: 0,
        ),
        body: _buildFeatureDisabledState('Gift Registry'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Registry'),
        elevation: 0,
      ),
      body: Consumer<GiftRegistryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
             return const Center(child: CircularProgressIndicator());
          }
           
           // Assuming one registry per event for now
          final registry = provider.registries.isEmpty ? null : provider.registries.first;

          if (registry == null || registry.items.isEmpty) {
            return _buildEmptyState();
          }

          return _buildGiftRegistryList(registry);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.card_giftcard_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Gift Registry',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The host hasn\'t set up a gift registry yet.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureDisabledState(String featureName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.block,
            size: 80,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '$featureName Disabled',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature has been disabled by the event host.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGiftRegistryList(GiftRegistry giftRegistry) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: giftRegistry.items.length,
      itemBuilder: (context, index) {
        final item = giftRegistry.items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Image and Basic Info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item Image
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.surfaceVariant,
                      ),
                      child: item.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_,__,___) => const Icon(Icons.broken_image),
                              ),
                            )
                          : Icon(
                              Icons.card_giftcard,
                              size: 40,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Item Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.description,
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          // Price
                          Text(
                            'RM ${item.price.toStringAsFixed(2)}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Purchase Status
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: item.quantity > 0 ? (item.quantity - item.remainingQuantity) / item.quantity : 0,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          item.remainingQuantity == 0
                              ? Theme.of(context).colorScheme.error
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item.quantity - item.remainingQuantity}/${item.quantity} purchased',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: item.remainingQuantity > 0
                            ? () => _purchaseGift(giftRegistry.id, item)
                            : null,
                        icon: const Icon(Icons.shopping_cart),
                        label: Text(
                          item.remainingQuantity > 0
                              ? 'Purchase'
                              : 'Sold Out',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _shareGift(item),
                      icon: const Icon(Icons.share),
                      tooltip: 'Share',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _purchaseGift(String registryId, GiftRegistryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to purchase "${item.name}"?'),
            const SizedBox(height: 8),
            Text(
              'Price: RM ${item.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await context.read<GiftRegistryProvider>().purchaseItem(
                registryId,
                item.id,
                1,
                'Anonymous', // TODO: Get actual user name if logged in
              );
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully purchased "${item.name}"!'),
                  ),
                );
              }
            },
            child: const Text('Purchase'),
          ),
        ],
      ),
    );
  }

  void _shareGift(GiftRegistryItem item) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Share functionality for "${item.name}" coming soon!'),
      ),
    );
  }
}
