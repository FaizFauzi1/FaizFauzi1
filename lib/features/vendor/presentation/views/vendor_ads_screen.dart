import 'dart:convert';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VendorAdsScreen extends StatefulWidget {
  const VendorAdsScreen({super.key});

  @override
  State<VendorAdsScreen> createState() => _VendorAdsScreenState();
}

class _VendorAdsScreenState extends State<VendorAdsScreen> {
  static const _storageKey = 'vendor_ads_campaigns_v1';
  List<Map<String, dynamic>> _ads = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  String _selectedType = 'Banner Ad';
  List<String> _selectedPlatforms = [];
  DateTime? _startDate;
  DateTime? _endDate;

  static List<Map<String, dynamic>> get _seedAds => [
        {
          'name': 'Wedding Package Promotion',
          'type': 'Banner Ad',
          'status': 'Active',
          'budget': 500,
          'spent': 125,
          'impressions': 2500,
          'clicks': 45,
          'conversions': 3,
          'startDate': '2024-03-01',
          'endDate': '2024-03-31',
          'targetAudience': 'Couples aged 25-35',
          'platforms': ['Facebook', 'Instagram'],
        },
        {
          'name': 'Corporate Event Special',
          'type': 'Sponsored Post',
          'status': 'Active',
          'budget': 300,
          'spent': 89,
          'impressions': 1800,
          'clicks': 32,
          'conversions': 2,
          'startDate': '2024-03-10',
          'endDate': '2024-03-25',
          'targetAudience': 'Business professionals',
          'platforms': ['LinkedIn'],
        },
        {
          'name': 'Birthday Party Deal',
          'type': 'Carousel Ad',
          'status': 'Paused',
          'budget': 200,
          'spent': 45,
          'impressions': 1200,
          'clicks': 18,
          'conversions': 1,
          'startDate': '2024-02-15',
          'endDate': '2024-02-28',
          'targetAudience': 'Families with children',
          'platforms': ['Facebook', 'Instagram'],
        },
      ];

  @override
  void initState() {
    super.initState();
    _loadAds();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _loadAds() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _ads = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } else {
      _ads = _seedAds.map((e) => Map<String, dynamic>.from(e)).toList();
      await _persistAds();
    }
    if (mounted) setState(() {});
  }

  Future<void> _persistAds() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(_ads));
  }

  @override
  Widget build(BuildContext context) {
    final activeAds = _ads.where((ad) => ad['status'] == 'Active').toList();
    final totalBudget = _ads.fold<double>(0, (sum, ad) => sum + (ad['budget'] as num).toDouble());
    final totalSpent = _ads.fold<double>(0, (sum, ad) => sum + (ad['spent'] as num).toDouble());
    final totalImpressions = _ads.fold<int>(0, (sum, ad) => sum + (ad['impressions'] as int));
    final totalClicks = _ads.fold<int>(0, (sum, ad) => sum + (ad['clicks'] as int));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Ads Management',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _showCreateAdDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAds,
        child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview cards
            Row(
              children: [
                _buildOverviewCard('Active Ads', activeAds.length.toString(), Icons.campaign, AppTheme.primaryColor),
                const SizedBox(width: 12),
                _buildOverviewCard('Total Budget', 'RM ${totalBudget.toStringAsFixed(0)}', Icons.account_balance_wallet, AppTheme.successColor),
                const SizedBox(width: 12),
                _buildOverviewCard('Total Spent', 'RM ${totalSpent.toStringAsFixed(0)}', Icons.payments, AppTheme.warningColor),
              ],
            ),
            const SizedBox(height: 24),

            // Performance metrics
            Row(
              children: [
                _buildOverviewCard('Impressions', totalImpressions.toString(), Icons.visibility, Colors.blue),
                const SizedBox(width: 12),
                _buildOverviewCard('Clicks', totalClicks.toString(), Icons.touch_app, Colors.purple),
                const SizedBox(width: 12),
                _buildOverviewCard('CTR', '${((totalClicks / totalImpressions) * 100).toStringAsFixed(1)}%', Icons.trending_up, Colors.green),
              ],
            ),
            const SizedBox(height: 24),

            // Ads list
            const Text(
              'Your Ads',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            ..._ads.map((ad) => _buildAdCard(ad)).toList(),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildOverviewCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    Color statusColor = ad['status'] == 'Active' ? AppTheme.successColor : AppTheme.textSecondaryColor;
    double progress = ad['spent'] / ad['budget'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  ad['name'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  ad['status'],
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${ad['type']} • ${ad['platforms'].join(', ')}',
            style: const TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),

          // Budget progress
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget: RM ${ad['budget']} • Spent: RM ${ad['spent']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress > 0.8 ? AppTheme.errorColor : AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Performance metrics
          Row(
            children: [
              _buildMetricChip('Impressions', ad['impressions'].toString()),
              const SizedBox(width: 8),
              _buildMetricChip('Clicks', ad['clicks'].toString()),
              const SizedBox(width: 8),
              _buildMetricChip('Conversions', ad['conversions'].toString()),
            ],
          ),
          const SizedBox(height: 12),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _editAd(ad),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _toggleAdStatus(ad),
                icon: Icon(
                  ad['status'] == 'Active' ? Icons.pause : Icons.play_arrow,
                  size: 16,
                ),
                label: Text(ad['status'] == 'Active' ? 'Pause' : 'Resume'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => _deleteAd(ad),
                icon: const Icon(Icons.delete, size: 16),
                label: const Text('Delete'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showCreateAdDialog() {
    _nameController.clear();
    _budgetController.clear();
    _targetController.clear();
    _selectedType = 'Banner Ad';
    _selectedPlatforms = [];
    _startDate = null;
    _endDate = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Ad'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Ad Name'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  items: const [
                    DropdownMenuItem(value: 'Banner Ad', child: Text('Banner Ad')),
                    DropdownMenuItem(value: 'Sponsored Post', child: Text('Sponsored Post')),
                    DropdownMenuItem(value: 'Carousel Ad', child: Text('Carousel Ad')),
                    DropdownMenuItem(value: 'Video Ad', child: Text('Video Ad')),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedType = value!);
                  },
                  decoration: const InputDecoration(labelText: 'Ad Type'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _budgetController,
                  decoration: const InputDecoration(labelText: 'Budget (RM)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _targetController,
                  decoration: const InputDecoration(labelText: 'Target Audience'),
                ),
                const SizedBox(height: 16),
                const Text('Platforms'),
                Wrap(
                  spacing: 8,
                  children: ['Facebook', 'Instagram', 'LinkedIn', 'TikTok'].map((platform) {
                    return FilterChip(
                      label: Text(platform),
                      selected: _selectedPlatforms.contains(platform),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedPlatforms.add(platform);
                          } else {
                            _selectedPlatforms.remove(platform);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_startDate == null ? 'Start Date' : _startDate!.toString().split(' ')[0]),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: _startDate ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_endDate == null ? 'End Date' : _endDate!.toString().split(' ')[0]),
                      ),
                    ),
                  ],
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
              onPressed: () {
                if (_nameController.text.isNotEmpty &&
                    _budgetController.text.isNotEmpty &&
                    _selectedPlatforms.isNotEmpty) {
                  setState(() {
                    _ads.add({
                      'name': _nameController.text,
                      'type': _selectedType,
                      'status': 'Active',
                      'budget': double.tryParse(_budgetController.text) ?? 0,
                      'spent': 0,
                      'impressions': 0,
                      'clicks': 0,
                      'conversions': 0,
                      'startDate': _startDate?.toString().split(' ')[0] ?? '',
                      'endDate': _endDate?.toString().split(' ')[0] ?? '',
                      'targetAudience': _targetController.text,
                      'platforms': List<String>.from(_selectedPlatforms),
                    });
                  });
                  _persistAds();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ad created successfully')),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _editAd(Map<String, dynamic> ad) {
    // Implement edit functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _toggleAdStatus(Map<String, dynamic> ad) {
    setState(() {
      ad['status'] = ad['status'] == 'Active' ? 'Paused' : 'Active';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ad ${ad['status'].toLowerCase()}')),
    );
  }

  void _deleteAd(Map<String, dynamic> ad) {
    setState(() {
      _ads.remove(ad);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ad deleted successfully')),
    );
  }
}
