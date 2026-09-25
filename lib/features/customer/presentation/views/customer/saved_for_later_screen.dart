import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/customer/data/providers/save_for_later_provider.dart';
import 'package:eventease/shared/widgets/common_navbar.dart';

class SavedForLaterScreen extends StatelessWidget {
  const SavedForLaterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Saved for Later',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Consumer<SaveForLaterProvider>(
            builder: (context, saveProvider, child) {
              if (saveProvider.savedCount > 0) {
                return TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear All'),
                        content: const Text('Remove all saved items?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              saveProvider.clearAll();
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('All items removed')),
                              );
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: AppTheme.primaryColor),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<SaveForLaterProvider>(
        builder: (context, saveProvider, child) {
          if (saveProvider.savedCount == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved items yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Items you save will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: saveProvider.savedCount,
            itemBuilder: (context, index) {
              final serviceId = saveProvider.savedServiceIds[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  title: Text(
                    'Service $serviceId',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  subtitle: const Text('Saved for later viewing'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      saveProvider.removeService(serviceId);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Removed from saved items')),
                      );
                    },
                  ),
                  onTap: () {
                    // Navigate to product detail screen
                    // This would need to be implemented based on your navigation setup
                  },
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: const CommonNavbar(currentIndex: 3),
    );
  }
}
