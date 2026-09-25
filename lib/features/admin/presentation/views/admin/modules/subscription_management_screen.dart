import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionManagementScreen extends StatefulWidget {
  const SubscriptionManagementScreen({super.key});

  @override
  State<SubscriptionManagementScreen> createState() => _SubscriptionManagementScreenState();
}

class _SubscriptionManagementScreenState extends State<SubscriptionManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // For Plan Config tab
  List<Map<String, dynamic>> _allTiers = [];
  bool _isLoadingTiers = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadTiersFromDb();
  }

  Future<void> _loadTiersFromDb() async {
    setState(() => _isLoadingTiers = true);
    try {
      final response = await Supabase.instance.client
          .from('subscription_tiers')
          .select()
          .order('sort_order');
      setState(() {
        _allTiers = List<Map<String, dynamic>>.from(response as List);
        _isLoadingTiers = false;
      });
    } catch (e) {
      setState(() => _isLoadingTiers = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Subscription Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Customers'),
            Tab(text: 'Vendors'),
            Tab(text: 'Payments'),
            Tab(text: 'Plan Config'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildCustomerList(),
                _buildVendorList(),
                _buildTransactionHistoryTab(),
                _buildPlanConfigTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList() {
    return Consumer<AdminProvider>(
      builder: (context, admin, child) {
        final customers = admin.users.where((user) {
          final isCustomer = user.role == 'customer';
          final matchesSearch = user.name.toLowerCase().contains(_searchQuery) || 
                               user.email.toLowerCase().contains(_searchQuery);
          return isCustomer && matchesSearch;
        }).toList();

        if (customers.isEmpty) {
          return const Center(child: Text('No customers found.'));
        }

        return ListView.builder(
          itemCount: customers.length,
          itemBuilder: (context, index) {
            final user = customers[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.email),
                    const SizedBox(height: 4),
                    _buildSubscriptionBadge(user.subscriptionTier),
                    if (user.subscriptionExpiry != null)
                      Text(
                        'Expires: ${DateFormat('dd MMM yyyy').format(user.subscriptionExpiry!)}',
                        style: TextStyle(
                          color: user.subscriptionExpiry!.isBefore(DateTime.now()) 
                              ? Colors.red 
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                  onPressed: () => _showEditSubscriptionDialog(context, user: user),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVendorList() {
    return Consumer<AdminProvider>(
      builder: (context, admin, child) {
        final vendors = admin.vendors.where((vendor) {
          final matchesSearch = vendor.name.toLowerCase().contains(_searchQuery) || 
                               (vendor.category.toLowerCase().contains(_searchQuery));
          return matchesSearch;
        }).toList();

        if (vendors.isEmpty) {
          return const Center(child: Text('No vendors found.'));
        }

        return ListView.builder(
          itemCount: vendors.length,
          itemBuilder: (context, index) {
            final vendor = vendors[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(vendor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor.category),
                    const SizedBox(height: 4),
                    _buildSubscriptionBadge(vendor.subscriptionTier),
                    if (vendor.subscriptionExpiry != null)
                      Text(
                        'Expires: ${DateFormat('dd MMM yyyy').format(vendor.subscriptionExpiry!)}',
                        style: TextStyle(
                          color: vendor.subscriptionExpiry!.isBefore(DateTime.now()) 
                              ? Colors.red 
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: AppTheme.primaryColor),
                  onPressed: () => _showEditSubscriptionDialog(context, vendor: vendor),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, child) {
        final stats = admin.getSubscriptionAnalytics();
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Performance Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildStatCard('Total Active', stats['totalActive'].toString(), Icons.people, Colors.blue),
                  _buildStatCard('MRR', 'RM ${stats['mrr'].toStringAsFixed(0)}', Icons.payments, Colors.green),
                  _buildStatCard('Expiring Soon', stats['upcomingExpirations'].toString(), Icons.timer, Colors.orange),
                  _buildStatCard('Growth', '+12%', Icons.trending_up, Colors.purple),
                ],
              ),
              const SizedBox(height: 32),
              const Text(
                'Tier Distribution',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ... (stats['distribution'] as Map<String, int>).entries.map((e) => _buildDistributionItem(e.key, e.value, admin.vendors.length)).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionItem(String tier, int count, int total) {
    final percent = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tier.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('$count vendors (${(percent * 100).toStringAsFixed(1)}%)'),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percent,
            backgroundColor: Colors.grey[200],
            color: tier.toLowerCase() == 'business' ? Colors.purple : (tier.toLowerCase() == 'pro' ? Colors.orange : Colors.blue),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistoryTab() {
    return Consumer<AdminProvider>(
      builder: (context, admin, child) {
        final payments = admin.allSubscriptionPayments;
        
        if (payments.isEmpty) {
          return const Center(child: Text('No subscription payments recorded yet.'));
        }

        return ListView.builder(
          itemCount: payments.length,
          itemBuilder: (context, index) {
            final p = payments[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: p.status == 'completed' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                child: Icon(
                  p.status == 'completed' ? Icons.check : Icons.close,
                  color: p.status == 'completed' ? Colors.green : Colors.red,
                ),
              ),
              title: Text('Payment ID: ${p.id.substring(0, 8)}...'),
              subtitle: Text(DateFormat('dd MMM yyyy, HH:mm').format(p.createdAt)),
              trailing: Text(
                'RM ${p.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlanConfigTab() {
    if (_isLoadingTiers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allTiers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No plans found in database.', style: TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              onPressed: _loadTiersFromDb,
            ),
          ],
        ),
      );
    }

    final vendorTiers = _allTiers.where((t) => (t['target_audience'] ?? 'vendor') == 'vendor').toList();
    final customerTiers = _allTiers.where((t) => t['target_audience'] == 'customer').toList();

    return RefreshIndicator(
      onRefresh: _loadTiersFromDb,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (vendorTiers.isNotEmpty) ...
            [
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Vendor Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...vendorTiers.map((tier) => _buildTierConfigCard(tier)),
              const SizedBox(height: 8),
            ],
          if (customerTiers.isNotEmpty) ...
            [
              const Divider(height: 24),
              const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Customer Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ...customerTiers.map((tier) => _buildTierConfigCard(tier)),
            ],
        ],
      ),
    );
  }

  Widget _buildTierConfigCard(Map<String, dynamic> tier) {
    final features = (tier['features'] as List? ?? []).cast<String>();
    final price = (tier['price'] as num?)?.toDouble() ?? 0.0;
    final billingCycle = tier['billing_cycle'] ?? 'Monthly';
    final audience = tier['target_audience'] ?? 'vendor';

    Color accentColor = Colors.blue;
    if (tier['name'] == 'pro') accentColor = Colors.orange;
    if (tier['name'] == 'business') accentColor = Colors.purple;
    if (audience == 'customer') accentColor = Colors.pink;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: accentColor.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier['display_name'] ?? tier['name'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accentColor),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          audience.toUpperCase(),
                          style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  color: AppTheme.primaryColor,
                  tooltip: 'Edit Plan',
                  onPressed: () => _showPlanEditDialog(tier),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.attach_money, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'RM ${price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                ),
                const SizedBox(width: 8),
                Text('/ $billingCycle', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            ...features.take(3).map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, size: 14, color: accentColor),
                  const SizedBox(width: 6),
                  Expanded(child: Text(f, style: const TextStyle(fontSize: 13))),
                ],
              ),
            )),
            if (features.length > 3)
              Text(
                '+ ${features.length - 3} more features',
                style: TextStyle(color: Colors.grey[500], fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  void _showPlanEditDialog(Map<String, dynamic> tier) {
    final nameCtrl = TextEditingController(text: tier['display_name'] ?? tier['name']);
    final priceCtrl = TextEditingController(text: (tier['price'] as num?)?.toString() ?? '0');
    final featuresCtrl = TextEditingController(
      text: (tier['features'] as List? ?? []).join('\n'),
    );
    final billingCtrl = TextEditingController(text: tier['billing_cycle'] ?? 'Monthly');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Plan: ${tier['display_name'] ?? tier['name']}'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Display Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceCtrl,
                  decoration: const InputDecoration(labelText: 'Price (RM)', border: OutlineInputBorder(), prefixText: 'RM '),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: billingCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Billing Cycle',
                    border: OutlineInputBorder(),
                    hintText: 'Monthly / Yearly / Lifetime',
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Features (one per line)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextField(
                  controller: featuresCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Up to 5 vendors\nPriority support\nAnalytics dashboard',
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save Changes'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
            onPressed: () async {
              final newPrice = double.tryParse(priceCtrl.text.trim());
              if (newPrice == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid price — please enter a number.')),
                );
                return;
              }
              final newFeatures = featuresCtrl.text
                  .split('\n')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();
              Navigator.pop(context);
              try {
                await Supabase.instance.client
                    .from('subscription_tiers')
                    .update({
                      'display_name': nameCtrl.text.trim(),
                      'price': newPrice,
                      'billing_cycle': billingCtrl.text.trim(),
                      'features': newFeatures,
                    })
                    .eq('id', tier['id']);
                _loadTiersFromDb();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Plan updated! Changes are live.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionBadge(String tier) {
    Color color = Colors.grey;
    String label = tier.toUpperCase();

    if (tier == 'wedding_pass' || tier == 'pro') {
      color = Colors.orange;
    } else if (tier == 'business' || tier == 'premium') {
      color = Colors.purple;
    } else if (tier == 'wedding_pass_trial') {
      color = Colors.blue;
      label = 'TRIAL';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showEditSubscriptionDialog(BuildContext context, {AppUser? user, AdminVendor? vendor}) {
    final String initialTier = user?.subscriptionTier ?? vendor?.subscriptionTier ?? 'free';
    DateTime? selectedDate = user?.subscriptionExpiry ?? vendor?.subscriptionExpiry;
    String selectedTier = initialTier.toLowerCase();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit ${user != null ? 'User' : 'Vendor'} Subscription'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  user != null 
                    ? _buildUserTierDropdown(selectedTier, initialTier, (val) => setDialogState(() => selectedTier = val!))
                    : _buildVendorTierDropdown(selectedTier, initialTier, (val) => setDialogState(() => selectedTier = val!)),
                  const SizedBox(height: 16),
                  ListTile(
                    title: const Text('Expiry Date'),
                    subtitle: Text(selectedDate != null 
                        ? DateFormat('dd MMM yyyy').format(selectedDate!) 
                        : 'No expiry (Lifetime)'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) {
                        setDialogState(() => selectedDate = date);
                      }
                    },
                  ),
                  if (selectedDate != null)
                    TextButton(
                      onPressed: () => setDialogState(() => selectedDate = null),
                      child: const Text('Remove Expiry', style: TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final admin = Provider.of<AdminProvider>(context, listen: false);
                    try {
                      if (user != null) {
                        await admin.updateUserSubscription(user.id, selectedTier, selectedDate);
                      } else if (vendor != null) {
                        await admin.updateVendorSubscription(vendor.id, selectedTier, selectedDate);
                      }
                      if (context.mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Subscription updated successfully')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildUserTierDropdown(String selectedTier, String initialTier, ValueChanged<String?> onChanged) {
    final List<String> tiers = ['free', 'wedding_pass', 'wedding_pass_trial', 'pro', 'premium'];
    if (!tiers.contains(initialTier.toLowerCase())) {
      tiers.add(initialTier.toLowerCase());
    }

    return DropdownButtonFormField<String>(
      value: selectedTier,
      decoration: const InputDecoration(labelText: 'Subscription Tier (User)'),
      items: tiers.map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildVendorTierDropdown(String selectedTier, String initialTier, ValueChanged<String?> onChanged) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: Supabase.instance.client.from('subscription_tiers').select('id, name').order('sort_order'),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        
        final data = snapshot.data!;
        final List<String> dbTiers = data.map((e) => e['id'].toString()).toList();
        final Map<String, String> nameMap = { for (var e in data) e['id'].toString() : e['name'].toString() };
        
        // Fallbacks if DB is empty
        if (dbTiers.isEmpty) {
          dbTiers.addAll(['starter', 'pro', 'business']);
        }
        
        if (!dbTiers.contains(initialTier.toLowerCase())) {
          dbTiers.add(initialTier.toLowerCase());
          nameMap[initialTier.toLowerCase()] = initialTier.toUpperCase();
        }
        
        // If the selectedTier is not in dbTiers (can happen during first render if mismatch), default it
        final validSelectedTier = dbTiers.contains(selectedTier) ? selectedTier : dbTiers.first;
        if (validSelectedTier != selectedTier) {
          // Fire callback asynchronously to prevent build phase issues
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onChanged(validSelectedTier);
          });
        }

        return DropdownButtonFormField<String>(
          value: validSelectedTier,
          decoration: const InputDecoration(labelText: 'Subscription Tier (Vendor)'),
          items: dbTiers.map((t) => DropdownMenuItem(
            value: t, 
            child: Text(nameMap[t] ?? t.toUpperCase())
          )).toList(),
          onChanged: onChanged,
        );
      },
    );
  }
}
