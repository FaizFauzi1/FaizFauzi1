import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/gift_registry/data/providers/gift_registry_provider.dart';
import 'package:eventease/shared/models/gift_registry.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class GiftManagementScreen extends StatefulWidget {
  final String eventId;
  const GiftManagementScreen({super.key, required this.eventId});

  @override
  State<GiftManagementScreen> createState() => _GiftManagementScreenState();
}

class _GiftManagementScreenState extends State<GiftManagementScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GiftRegistryProvider>().loadRegistryForEvent(widget.eventId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Gift Registry Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showItemDialog(context),
          ),
        ],
      ),
      body: Consumer<GiftRegistryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          final registries = provider.registries;
          if (registries.isEmpty) {
            return _buildEmptyState();
          }

          final registry = registries.first; // Assume one registry per event
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: registry.items.length,
            itemBuilder: (context, index) {
              final item = registry.items[index];
              return _buildItemCard(context, registry.id, item);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.card_giftcard, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No items in your registry yet.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => _showCreateRegistryDialog(context),
            child: const Text('Create Registry'),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(BuildContext context, String registryId, GiftRegistryItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(item.imageUrl!,
                    width: 60, height: 60, fit: BoxFit.cover),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image_not_supported),
              ),
        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Price: RM ${item.price.toStringAsFixed(2)}'),
            Text('Qty: ${item.quantity} (Remaining: ${item.remainingQuantity})'),
            if (item.isPurchased)
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text('Purchased by: ${item.purchasedBy ?? "Unknown"}',
                      style: const TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showItemDialog(context, registryId: registryId, item: item);
            } else if (value == 'delete') {
              context.read<GiftRegistryProvider>().deleteItem(registryId, item.id);
            }
          },
        ),
      ),
    );
  }

  void _showCreateRegistryDialog(BuildContext context) {
    final titleController = TextEditingController(text: 'My Gift Registry');
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Registry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final registry = GiftRegistry(
                id: const Uuid().v4(),
                eventId: widget.eventId,
                title: titleController.text,
                description: descController.text,
                items: [],
                isActive: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              context.read<GiftRegistryProvider>().createRegistry(registry);
              Navigator.pop(context);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showItemDialog(BuildContext context, {String? registryId, GiftRegistryItem? item}) {
    final isEditing = item != null;
    final nameController = TextEditingController(text: item?.name ?? '');
    final priceController = TextEditingController(text: item?.price.toString() ?? '');
    final qtyController = TextEditingController(text: item?.quantity.toString() ?? '1');
    final descController = TextEditingController(text: item?.description ?? '');
    final categoryController = TextEditingController(text: item?.category ?? 'General');
    final imageController = TextEditingController(text: item?.imageUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Edit Item' : 'Add Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Item Name')),
              TextField(controller: priceController, decoration: const InputDecoration(labelText: 'Price (RM)'), keyboardType: TextInputType.number),
              TextField(controller: qtyController, decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number),
              TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
              TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Image URL')),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 2),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final provider = context.read<GiftRegistryProvider>();
              final targetRegistryId = registryId ?? provider.registries.firstOrNull?.id;
              
              if (targetRegistryId == null) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please create a registry first')));
                return;
              }

              final newItem = GiftRegistryItem(
                id: item?.id ?? 'item_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text,
                description: descController.text,
                price: double.tryParse(priceController.text) ?? 0.0,
                quantity: int.tryParse(qtyController.text) ?? 1,
                remainingQuantity: int.tryParse(qtyController.text) ?? 1,
                category: categoryController.text,
                imageUrl: imageController.text.isNotEmpty ? imageController.text : null,
                isPurchased: item?.isPurchased ?? false,
                purchasedBy: item?.purchasedBy,
                purchasedAt: item?.purchasedAt,
              );

              if (isEditing) {
                provider.updateItem(targetRegistryId, newItem);
              } else {
                provider.addItem(targetRegistryId, newItem);
              }
              Navigator.pop(context);
            },
            child: Text(isEditing ? 'Update' : 'Add'),
          ),
        ],
      ),
    );
  }
}
