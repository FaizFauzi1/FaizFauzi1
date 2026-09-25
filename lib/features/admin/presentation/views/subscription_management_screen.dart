import 'package:flutter/material.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/models/subscription_model.dart';
import 'package:eventease/shared/widgets/responsive_wrapper.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> {
  bool _isLoading = true;
  List<SubscriptionTierModel> _vendorTiers = [];
  List<SubscriptionTierModel> _customerTiers = [];

  @override
  void initState() {
    super.initState();
    _loadTiers();
  }

  Future<void> _loadTiers() async {
    setState(() => _isLoading = true);
    try {
      final response = await SupabaseService.select(
        table: 'subscription_tiers',
        orderBy: 'sort_order',
        ascending: true,
      );

      final List<SubscriptionTierModel> vendors = [];
      final List<SubscriptionTierModel> customers = [];

      for (final item in response) {
        final tier = SubscriptionTierModel.fromJson(item);
        if (item['target_audience'] == 'customer') {
          customers.add(tier);
        } else {
          vendors.add(tier);
        }
      }

      setState(() {
        _vendorTiers = vendors;
        _customerTiers = customers;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading subscription tiers: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(SubscriptionTierModel tier) {
    final TextEditingController nameController = TextEditingController(text: tier.displayName);
    final TextEditingController priceController = TextEditingController(text: tier.price.toString());
    final TextEditingController featuresController = TextEditingController(text: tier.features.join('\n'));

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${tier.displayName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Display Name'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(labelText: 'Price (RM)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                const Text('Features (One per line)'),
                TextField(
                  controller: featuresController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Feature 1\nFeature 2',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final double? newPrice = double.tryParse(priceController.text);
                if (newPrice == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid price')));
                  return;
                }
                
                final List<String> newFeatures = featuresController.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

                Navigator.pop(context); // close dialog
                
                setState(() => _isLoading = true);
                try {
                  await SupabaseService.update(
                    table: 'subscription_tiers',
                    data: {
                      'display_name': nameController.text.trim(),
                      'price': newPrice,
                      'features': newFeatures,
                    },
                    column: 'id',
                    value: tier.id,
                  );
                  _loadTiers();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Plan updated successfully!')));
                } catch (e) {
                  debugPrint('Error updating tier: $e');
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating plan: $e')));
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTierCard(SubscriptionTierModel tier) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tier.displayName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showEditDialog(tier),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'RM ${tier.price.toStringAsFixed(2)} / ${tier.billingCycle}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            const Text('Features:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...tier.features.map((feature) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature, style: const TextStyle(fontSize: 14))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWrapper(
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: const Text('Subscription Management', style: TextStyle(color: Colors.white)),
            backgroundColor: AppTheme.primaryColor,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: const TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: [
                Tab(text: 'Customer Plans'),
                Tab(text: 'Vendor Plans'),
              ],
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    // Customer Tab
                    RefreshIndicator(
                      onRefresh: _loadTiers,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _customerTiers.length,
                        itemBuilder: (context, index) => _buildTierCard(_customerTiers[index]),
                      ),
                    ),
                    // Vendor Tab
                    RefreshIndicator(
                      onRefresh: _loadTiers,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: _vendorTiers.length,
                        itemBuilder: (context, index) => _buildTierCard(_vendorTiers[index]),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
