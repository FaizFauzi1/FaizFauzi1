import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_networking_provider.dart';
import 'package:eventease/shared/widgets/package_builder_widget.dart';
import 'package:eventease/shared/models/vendor_marketplace_item.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';


class VendorPackageBuilderScreen extends StatefulWidget {
  const VendorPackageBuilderScreen({super.key});

  @override
  State<VendorPackageBuilderScreen> createState() => _VendorPackageBuilderScreenState();
}

class _VendorPackageBuilderScreenState extends State<VendorPackageBuilderScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vendorProvider = Provider.of<VendorProvider>(context, listen: false);
      final networkingProvider = Provider.of<VendorNetworkingProvider>(context, listen: false);
      final vendorId = vendorProvider.currentVendor?.id ?? '';
      if (vendorId.isNotEmpty) {
        networkingProvider.setCurrentVendor(vendorId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Package Builder',
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
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Joint Packages',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Build collaborative packages with other vendors to offer comprehensive solutions to customers.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Benefits Section
                Text(
                  'Benefits of Joint Packages',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildBenefitCard(
                  icon: Icons.group,
                  title: 'Expanded Services',
                  description: 'Offer complete event solutions by combining services from multiple vendors.',
                ),
                _buildBenefitCard(
                  icon: Icons.attach_money,
                  title: 'Competitive Pricing',
                  description: 'Create attractive package deals that provide value to customers.',
                ),
                _buildBenefitCard(
                  icon: Icons.handshake,
                  title: 'Stronger Partnerships',
                  description: 'Build lasting relationships with other vendors in your network.',
                ),
                _buildBenefitCard(
                  icon: Icons.trending_up,
                  title: 'Increased Revenue',
                  description: 'Access new customer segments and increase your overall business.',
                ),
                const SizedBox(height: 24),

                // Package Builder Widget
                const Text(
                  'Build Your Package',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                PackageBuilderWidget(
                  availableVendors: provider.allVendors,
                  onCreatePackage: (vendorIds, packageName, description) async {
                    // In a real app, this would create the package
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Joint package "$packageName" created successfully!'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Recent Packages Section
                const Text(
                  'Recent Joint Packages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                _buildRecentPackages(provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPackages(VendorNetworkingProvider provider) {
    // Combine real data with sample data if real data is empty for demo purposes
    // But since we want to enable actions, we should prefer real data structure
    
    final packages = provider.myMarketplaceItems
        .where((item) => item.type == MarketplaceItemType.package)
        .toList();

    if (packages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Text(
            "No packages created yet.",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return Column(
      children: packages.map((package) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        package.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: package.isActive 
                            ? AppTheme.successColor.withOpacity(0.1) 
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        package.isActive ? "Active" : "Inactive",
                        style: TextStyle(
                          fontSize: 12,
                          color: package.isActive ? AppTheme.successColor : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "RM ${package.currentPrice.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    if (package.discountedPrice != null) ...[
                      const SizedBox(width: 8),
                       Text(
                        "RM ${package.discountedPrice}",
                        style: const TextStyle(
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  package.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                if (package.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.details,
                        size: 16,
                        color: AppTheme.textSecondaryColor,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Tags: ${package.tags.take(3).join(', ')}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Management Actions
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: Icon(
                        package.isActive ? Icons.visibility_off : Icons.visibility,
                        size: 18,
                        color: Colors.orange,
                      ),
                      label: Text(
                        package.isActive ? "Deactivate" : "Activate",
                        style: const TextStyle(color: Colors.orange),
                      ),
                      onPressed: () {
                        if (package.isActive) {
                          provider.rejectMarketplaceItem(package.id); // Reusing reject as deactivate for now or implement toggle
                        } else {
                          provider.approveMarketplaceItem(package.id); // Reusing approve as activate
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Package status updated"))
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                      label: const Text("Delete", style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Delete Package"),
                            content: const Text("Are you sure you want to delete this package?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("Cancel"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                onPressed: () {
                                  provider.deleteMarketplaceItem(package.id);
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("Package deleted"))
                                  );
                                },
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
