import 'package:flutter/material.dart';
import 'package:eventease/shared/models/ad_models.dart';
import 'package:eventease/core/providers/ad_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:provider/provider.dart';

class AdManagementScreen extends StatefulWidget {
  const AdManagementScreen({super.key});

  @override
  State<AdManagementScreen> createState() => _AdManagementScreenState();
}

class _AdManagementScreenState extends State<AdManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        titleSpacing: 0,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text(
                'Ad Management',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const Spacer(),
              _buildSearchBar(),
            ],
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: 'Ads'),
            Tab(text: 'Placements'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: Consumer<AdProvider>(
        builder: (context, adProvider, child) {
          if (adProvider.isLoading && adProvider.ads.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Fetching campaigns...', style: TextStyle(color: AppTheme.textSecondaryColor)),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildAdsTab(),
              _buildPlacementsTab(),
              _buildAnalyticsTab(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAdDialog(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Ad', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 250,
      height: 40,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search...',
          hintStyle: TextStyle(color: AppTheme.textSecondaryColor.withOpacity(0.5)),
          prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondaryColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  Widget _buildAdsTab() {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        final ads = adProvider.ads;
        final filteredAds = ads.where((ad) {
          return ad.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              ad.description.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        return RefreshIndicator(
          onRefresh: () => adProvider.refreshData(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _buildSummaryDashboard(adProvider),
              ),
              if (filteredAds.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState('No ads found', Icons.campaign_outlined, onAction: () => adProvider.refreshData()),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildAdCard(filteredAds[index]),
                      childCount: filteredAds.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryDashboard(AdProvider adProvider) {
    final ads = adProvider.ads;
    final activeCount = adProvider.activeAdsCount;
    final totalImpressions = adProvider.totalImpressions;
    final totalClicks = adProvider.totalClicks;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performance Overview',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildSummaryCard('Ads', ads.length.toString(), Icons.layers, Colors.blue),
              const SizedBox(width: 12),
              _buildSummaryCard('Active', activeCount.toString(), Icons.check_circle, Colors.green),
              const SizedBox(width: 12),
              _buildSummaryCard('Traffic', '${(totalImpressions / 1000).toStringAsFixed(1)}k', Icons.trending_up, Colors.orange),
              const SizedBox(width: 12),
              _buildSummaryCard('Clicks', totalClicks.toString(), Icons.touch_app, Colors.purple),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildAdCard(AdConfiguration ad) {
    final impressionProg = ad.maxImpressions > 0 ? ad.currentImpressions / ad.maxImpressions : 0.0;
    final clickProg = ad.maxClicks > 0 ? ad.currentClicks / ad.maxClicks : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showEditAdDialog(ad),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ad.imageUrl != null)
                    Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(ad.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.image_outlined, color: AppTheme.textSecondaryColor),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ad.name,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            _buildStatusBadge(ad.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ad.description,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  _buildTag(ad.type.name.toUpperCase(), AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  _buildTag(ad.platform.name.toUpperCase(), Colors.orange),
                  const Spacer(),
                  const Icon(Icons.star, size: 14, color: AppTheme.accentColor),
                  const SizedBox(width: 4),
                  Text('Priority: ${ad.priority}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              _buildProgressSection('Impressions', ad.currentImpressions, ad.maxImpressions, impressionProg, Colors.blue),
              const SizedBox(height: 12),
              _buildProgressSection('Clicks', ad.currentClicks, ad.maxClicks, clickProg, Colors.purple),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _toggleAdStatus(ad),
                    icon: Icon(ad.status == AdStatus.active ? Icons.pause : Icons.play_arrow, size: 18),
                    label: Text(ad.status == AdStatus.active ? 'Pause' : 'Activate'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _deleteAd(ad),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(String label, int current, int max, double progress, Color color) {
    final maxLabel = max == -1 ? '∞' : max.toString();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
            Text('$current / $maxLabel', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: max == -1 ? null : progress.clamp(0.0, 1.0),
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(AdStatus status) {
    Color color = Colors.grey;
    if (status == AdStatus.active) color = Colors.green;
    if (status == AdStatus.inactive) color = Colors.red;
    if (status == AdStatus.draft) color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildPlacementsTab() {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        final filteredPlacements = adProvider.placements.where((p) {
          return p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              p.screen.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredPlacements.isEmpty) {
          return _buildEmptyState('No placements matching search', Icons.place_outlined, onAction: () => adProvider.refreshData());
        }

        return RefreshIndicator(
          onRefresh: () => adProvider.refreshData(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: filteredPlacements.length,
            itemBuilder: (context, index) {
              final placement = filteredPlacements[index];
              final assignedAds = adProvider.ads.where((a) => placement.adIds.contains(a.id)).toList();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(placement.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(placement.description, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.monitor, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(placement.screen, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              const SizedBox(width: 12),
                              Icon(Icons.align_vertical_bottom, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(placement.position, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                            ],
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: placement.isEnabled,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (v) => _togglePlacement(placement, v),
                      ),
                    ),
                    if (assignedAds.isNotEmpty) ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Text('Assigned:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                children: assignedAds.map((ad) => _buildTag(ad.name, Colors.blue)).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon, {VoidCallback? onAction}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600)),
          if (onAction != null) ...[
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Fetch'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<AdProvider>(
      builder: (context, adProvider, child) {
        final ads = adProvider.ads;

        if (ads.isEmpty) {
          return _buildEmptyState('No campaign data for analytics', Icons.analytics_outlined, onAction: () => adProvider.refreshData());
        }

        return RefreshIndicator(
          onRefresh: () => adProvider.refreshData(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            itemBuilder: (context, index) {
              final ad = ads[index];
              final analytics = adProvider.getAdAnalytics(ad.id);
              final ctr = analytics['ctr'] as double;

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(ad.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          Text(
                            '${ctr.toStringAsFixed(2)}% CTR',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ctr > 2.0 ? Colors.green : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildMetric('Impressions', analytics['impressions'].toString(), Colors.blue),
                          _buildMetric('Clicks', analytics['clicks'].toString(), Colors.purple),
                          _buildMetric('Unique Users', (analytics['impressions'] * 0.8).toInt().toString(), Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text('Conversion Rate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: (ctr / 10.0).clamp(0.0, 1.0),
                          minHeight: 10,
                          backgroundColor: AppTheme.backgroundColor,
                          valueColor: AlwaysStoppedAnimation<Color>(ctr > 2.0 ? Colors.green : Colors.orange),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ctr > 2.0 ? 'High performing campaign' : 'Performance optimization recommended',
                        style: TextStyle(fontSize: 10, color: ctr > 2.0 ? Colors.green : Colors.orange[700]),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
        ],
      ),
    );
  }

  void _showAddAdDialog() {
    showDialog(
      context: context,
      builder: (context) => const AdFormDialog(),
    );
  }

  void _showEditAdDialog(AdConfiguration ad) {
    showDialog(
      context: context,
      builder: (context) => AdFormDialog(ad: ad),
    );
  }

  void _toggleAdStatus(AdConfiguration ad) async {
    final adProvider = context.read<AdProvider>();
    final newStatus = ad.status == AdStatus.active ? AdStatus.inactive : AdStatus.active;
    final updatedAd = ad.copyWith(status: newStatus, updatedAt: DateTime.now());
    
    try {
      await adProvider.updateAd(updatedAd);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Campaign ${newStatus == AdStatus.active ? 'activated' : 'paused'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update campaign status'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _deleteAd(AdConfiguration ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Ad'),
        content: Text('Are you sure you want to delete "${ad.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final adProvider = context.read<AdProvider>();
              try {
                await adProvider.deleteAd(ad.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Campaign deleted')));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Delete failed'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _togglePlacement(AdPlacement placement, bool isEnabled) async {
    final adProvider = context.read<AdProvider>();
    final updatedPlacement = AdPlacement(
      id: placement.id,
      name: placement.name,
      description: placement.description,
      adType: placement.adType,
      screen: placement.screen,
      position: placement.position,
      adIds: placement.adIds,
      isEnabled: isEnabled,
      refreshInterval: placement.refreshInterval,
      targeting: placement.targeting,
    );
    
    try {
      await adProvider.updatePlacement(updatedPlacement);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Placement ${isEnabled ? 'enabled' : 'disabled'}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update failed'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

class AdFormDialog extends StatefulWidget {
  final AdConfiguration? ad;

  const AdFormDialog({super.key, this.ad});

  @override
  State<AdFormDialog> createState() => _AdFormDialogState();
}

class _AdFormDialogState extends State<AdFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _adUnitIdController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _callToActionController = TextEditingController();
  final _targetUrlController = TextEditingController();
  final _maxImpressionsController = TextEditingController(text: '-1');
  final _maxClicksController = TextEditingController(text: '-1');

  AdType _selectedType = AdType.banner;
  AdStatus _selectedStatus = AdStatus.draft;
  AdPlatform _selectedPlatform = AdPlatform.android;
  int _priority = 1;

  @override
  void initState() {
    super.initState();
    if (widget.ad != null) {
      _nameController.text = widget.ad!.name;
      _descriptionController.text = widget.ad!.description;
      _adUnitIdController.text = widget.ad!.adUnitId;
      _imageUrlController.text = widget.ad!.imageUrl ?? '';
      _titleController.text = widget.ad!.title ?? '';
      _subtitleController.text = widget.ad!.subtitle ?? '';
      _callToActionController.text = widget.ad!.callToAction ?? '';
      _targetUrlController.text = widget.ad!.targetUrl ?? '';
      _maxImpressionsController.text = widget.ad!.maxImpressions.toString();
      _maxClicksController.text = widget.ad!.maxClicks.toString();
      _selectedType = widget.ad!.type;
      _selectedStatus = widget.ad!.status;
      _selectedPlatform = widget.ad!.platform;
      _priority = widget.ad!.priority;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.ad == null ? 'Create New Ad Campaign' : 'Edit Ad Configuration',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Campaign Name',
                    prefixIcon: Icon(Icons.badge_outlined),
                    hintText: 'e.g. Summer Sale Banner',
                  ),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Internal Description',
                    prefixIcon: Icon(Icons.description_outlined),
                  ),
                  maxLines: 2,
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<AdType>(
                        value: _selectedType,
                        decoration: const InputDecoration(labelText: 'Ad Type'),
                        items: AdType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()))).toList(),
                        onChanged: (v) => setState(() => _selectedType = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<AdPlatform>(
                        value: _selectedPlatform,
                        decoration: const InputDecoration(labelText: 'Target Platform'),
                        items: AdPlatform.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name.toUpperCase()))).toList(),
                        onChanged: (v) => setState(() => _selectedPlatform = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _adUnitIdController,
                  decoration: const InputDecoration(labelText: 'Ad Unit ID / Tag', prefixIcon: Icon(Icons.code)),
                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Ad Creative (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondaryColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(labelText: 'Creative Image URL', prefixIcon: Icon(Icons.image_outlined)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Display Title', prefixIcon: Icon(Icons.title)),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetUrlController,
                  decoration: const InputDecoration(labelText: 'Landing Page URL', prefixIcon: Icon(Icons.link)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxImpressionsController,
                        decoration: const InputDecoration(labelText: 'Max Impressions', helperText: '-1 for unlimited'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _maxClicksController,
                        decoration: const InputDecoration(labelText: 'Max Clicks', helperText: '-1 for unlimited'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Delivery Priority', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Slider(
                  value: _priority.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  label: _priority.toString(),
                  onChanged: (v) => setState(() => _priority = v.round()),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveAd,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(widget.ad == null ? 'Create Campaign' : 'Save Changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _saveAd() async {
    if (_formKey.currentState?.validate() ?? false) {
      final adProvider = context.read<AdProvider>();

      final ad = AdConfiguration(
        id: widget.ad?.id ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        type: _selectedType,
        status: _selectedStatus,
        platform: _selectedPlatform,
        adUnitId: _adUnitIdController.text,
        imageUrl: _imageUrlController.text.isEmpty ? null : _imageUrlController.text,
        title: _titleController.text.isEmpty ? null : _titleController.text,
        subtitle: _subtitleController.text.isEmpty ? null : _subtitleController.text,
        callToAction: _callToActionController.text.isEmpty ? null : _callToActionController.text,
        targetUrl: _targetUrlController.text.isEmpty ? null : _targetUrlController.text,
        priority: _priority,
        maxImpressions: int.tryParse(_maxImpressionsController.text) ?? -1,
        maxClicks: int.tryParse(_maxClicksController.text) ?? -1,
        currentImpressions: widget.ad?.currentImpressions ?? 0,
        currentClicks: widget.ad?.currentClicks ?? 0,
        createdAt: widget.ad?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (widget.ad == null) {
          await adProvider.addAd(ad);
        } else {
          await adProvider.updateAd(ad);
        }
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(widget.ad == null ? 'Campaign created successfully' : 'Configuration updated')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save campaign. Please check your connection.'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}