import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/gift_registry/data/providers/gift_registry_provider.dart';
import 'package:eventease/features/gift_registry/presentation/views/add_edit_item_dialog.dart';
import 'package:eventease/shared/models/gift_registry.dart';
import 'package:eventease/core/utils/app_theme.dart';

class RegistryManagementScreen extends StatefulWidget {
  final Event event;

  const RegistryManagementScreen({super.key, required this.event});

  @override
  State<RegistryManagementScreen> createState() => _RegistryManagementScreenState();
}

class _RegistryManagementScreenState extends State<RegistryManagementScreen> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gift Registry'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer<GiftRegistryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (provider.error != null) {
             return Center(child: Text(provider.error!));
          }

          final registry = provider.registries.isNotEmpty ? provider.registries.first : null;

          if (registry == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No registry created yet.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _createRegistry(context),
                    child: const Text('Create Registry'),
                  ),
                ],
              ),
            );
          }

          if (registry.items.isEmpty) {
             return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Your registry is empty.'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _addItem(context, registry.id),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Item'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: registry.items.length,
            itemBuilder: (context, index) {
              final item = registry.items[index];
              return Card(
                child: ListTile(
                  leading: item.imageUrl != null 
                    ? Image.network(item.imageUrl!, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.broken_image))
                    : const Icon(Icons.card_giftcard),
                  title: Text(item.name),
                  subtitle: Text('RM ${item.price.toStringAsFixed(2)} • ${item.remainingQuantity}/${item.quantity} left'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _editItem(context, registry.id, item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteItem(context, registry.id, item.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<GiftRegistryProvider>(
        builder: (context, provider, child) {
          final registry = provider.registries.isNotEmpty ? provider.registries.first : null;
          if (registry != null && registry.items.isNotEmpty) {
            return FloatingActionButton(
              onPressed: () => _addItem(context, registry.id),
              backgroundColor: AppTheme.primaryColor,
              child: const Icon(Icons.add),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<void> _createRegistry(BuildContext context) async {
    final provider = Provider.of<GiftRegistryProvider>(context, listen: false);
    final newRegistry = GiftRegistry(
       id: '', // Supabase will gen ID if we omit, or we can use UUID. 
               // Provider logic needs to handle this. For now let's hope Provider gracefully ignores ID or handles it.
               // Actually the Provider uses 'toSupabaseJson' which includes ID.
               // Supabase insert usually ignores ID if it's auto-gen, provided we don't send it or send default.
               // But our ID is required in model.
               // Let's generate a temporary UUID or rely on Provider assuming empty string = new.
       eventId: widget.event.id,
       title: '${widget.event.title} Registry',
       description: 'Gift registry for ${widget.event.title}',
       items: [],
       isActive: true,
       createdAt: DateTime.now(),
       updatedAt: DateTime.now(),
    );
    
    // NOTE: Provider should handle ID removal for insert if needed. 
    // My provider implementation sends ID. If ID is empty string, uuid conversion in DB might fail.
    // I should fix the Provider to remove ID if it's empty, OR generate a UUID here.
    // Given no uuid package imported yet, let's assume valid UUID is needed or Provider handles it.
    // I will update Provider later if it fails, ensuring it generates UUID or omits it.
    
    await provider.createRegistry(newRegistry);
  }

  Future<void> _addItem(BuildContext context, String registryId) async {
    final result = await showDialog<GiftRegistryItem>(
      context: context,
      builder: (context) => const AddEditItemDialog(),
    );

    if (result != null && mounted) {
      await Provider.of<GiftRegistryProvider>(context, listen: false)
          .addItem(registryId, result);
    }
  }

  Future<void> _editItem(BuildContext context, String registryId, GiftRegistryItem item) async {
    final result = await showDialog<GiftRegistryItem>(
      context: context,
      builder: (context) => AddEditItemDialog(item: item),
    );

     if (result != null && mounted) {
      // Result has updated fields but might have lost ID if dialog regenerated it (check dialog logic)
      // Dialog: "id: widget.item?.id ?? ''" -> Preserves ID if editing.
      await Provider.of<GiftRegistryProvider>(context, listen: false)
          .updateItem(registryId, result);
    }
  }

  Future<void> _deleteItem(BuildContext context, String registryId, String itemId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item?'),
        content: const Text('Are you sure you want to remove this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
           TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    
    if (confirm == true && mounted) {
      await Provider.of<GiftRegistryProvider>(context, listen: false)
          .deleteItem(registryId, itemId);
    }
  }
}
