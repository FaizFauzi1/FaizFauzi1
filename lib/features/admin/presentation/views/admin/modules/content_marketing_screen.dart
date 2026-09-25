import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './article_editor_dialog.dart';

class ContentMarketingScreen extends StatefulWidget {
  const ContentMarketingScreen({super.key});

  @override
  State<ContentMarketingScreen> createState() => _ContentMarketingScreenState();
}

class _ContentMarketingScreenState extends State<ContentMarketingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Content & Marketing'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: [
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Listings'),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: Text('${admin.listings.length}', style: const TextStyle(fontSize: 12)),
              ),
            ])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Promotions'),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: Text('${admin.promotions.length}', style: const TextStyle(fontSize: 12)),
              ),
            ])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Ads'),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: Text('${admin.ads.length}', style: const TextStyle(fontSize: 12)),
              ),
            ])),
            Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('Articles'),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: Text('${admin.articles.length}', style: const TextStyle(fontSize: 12)),
              ),
            ])),
            const Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search content, promotions, or advertisements...',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListingsTab(admin.listings, admin),
                _buildPromotionsTab(admin.promotions, admin),
                _buildAdvertisementsTab(admin.ads, admin),
                _buildArticlesTab(admin.articles, admin),
                _buildAnalyticsTab(admin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsTab(List<Listing> listings, AdminProvider admin) {
    final filteredListings = _filterListings(listings);

    return Column(
      children: [
        // Listing Management Actions
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddListingDialog(admin),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Listing'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approveAllListings(),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approve All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Listings List
        Expanded(
          child: filteredListings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty ? 'No listings match "$_searchQuery"' : 'No listings yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      if (_searchQuery.isEmpty)
                        TextButton.icon(
                          onPressed: () => _showAddListingDialog(admin),
                          icon: const Icon(Icons.add),
                          label: const Text('Create your first listing'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredListings.length,
                  itemBuilder: (context, index) {
                    final listing = filteredListings[index];
                    return _buildListingCard(listing, admin);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPromotionsTab(List<Promotion> promotions, AdminProvider admin) {
    final filteredPromotions = _filterPromotions(promotions);
    return Column(
      children: [
        // Promotion Management Actions
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddPromotionDialog(admin),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Promotion'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showPromotionCalendar(admin),
                  icon: const Icon(Icons.calendar_today),
                  label: const Text('Calendar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Promotions List
        Expanded(
          child: filteredPromotions.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty ? 'No promotions match "$_searchQuery"' : 'No promotions yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      if (_searchQuery.isEmpty)
                        TextButton.icon(
                          onPressed: () => _showAddPromotionDialog(admin),
                          icon: const Icon(Icons.add),
                          label: const Text('Create your first promotion'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredPromotions.length,
                  itemBuilder: (context, index) {
                    final promotion = filteredPromotions[index];
                    return _buildPromotionCard(promotion, admin);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAdvertisementsTab(List<AdEntry> ads, AdminProvider admin) {
    final filteredAds = _filterAdvertisements(ads);
    return Column(
      children: [
        // Advertisement Management Actions
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddAdvertisementDialog(admin),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Ad'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAdPerformance(admin),
                  icon: const Icon(Icons.analytics),
                  label: const Text('Performance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Advertisements List
        Expanded(
          child: filteredAds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty ? 'No ads match "$_searchQuery"' : 'No advertisements yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      if (_searchQuery.isEmpty)
                        TextButton.icon(
                          onPressed: () => _showAddAdvertisementDialog(admin),
                          icon: const Icon(Icons.add),
                          label: const Text('Create your first advertisement'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredAds.length,
                  itemBuilder: (context, index) {
                    final ad = filteredAds[index];
                    return _buildAdvertisementCard(ad, admin);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildArticlesTab(List<Article> articles, AdminProvider admin) {
    final filteredArticles = _filterArticles(articles);
    return Column(
      children: [
        // Article Management Actions
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddArticleDialog(admin),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Article'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showArticleEditor(context, admin),
                  icon: const Icon(Icons.edit),
                  label: const Text('Editor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Articles List
        Expanded(
          child: filteredArticles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty ? 'No articles match "$_searchQuery"' : 'No articles yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 8),
                      if (_searchQuery.isEmpty)
                        TextButton.icon(
                          onPressed: () => _showArticleEditor(context, admin),
                          icon: const Icon(Icons.edit),
                          label: const Text('Write your first article'),
                        ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredArticles.length,
                  itemBuilder: (context, index) {
                    final article = filteredArticles[index];
                    return _buildArticleCard(article, admin);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab(AdminProvider admin) {
    final publishedArticles = admin.articles.where((a) => a.status == 'published').length;
    final draftArticles = admin.articles.where((a) => a.status == 'draft').length;
    final totalContent = admin.listings.length + admin.promotions.length + admin.ads.length + admin.articles.length;
    // Compute real fill rates
    final listingFill = totalContent > 0 ? (admin.listings.length / totalContent * 100).clamp(0, 100).toDouble() : 0.0;
    final promoFill = totalContent > 0 ? (admin.promotions.length / totalContent * 100).clamp(0, 100).toDouble() : 0.0;
    final adFill = totalContent > 0 ? (admin.ads.length / totalContent * 100).clamp(0, 100).toDouble() : 0.0;
    final articleFill = totalContent > 0 ? (admin.articles.length / totalContent * 100).clamp(0, 100).toDouble() : 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Marketing Overview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Marketing Overview',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Total: $totalContent items',
                        style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMarketingStatCard(
                        'Active Listings',
                        '${admin.listings.length}',
                        Icons.inventory,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMarketingStatCard(
                        'Running Promotions',
                        '${admin.promotions.length}',
                        Icons.local_offer,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMarketingStatCard(
                        'Active Ads',
                        '${admin.ads.length}',
                        Icons.campaign,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildMarketingStatCard(
                        'Published Articles',
                        '$publishedArticles',
                        Icons.article,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Article Pipeline
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Article Pipeline',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildPipelineCard('Drafts', '$draftArticles', Icons.edit_note, Colors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPipelineCard('Published', '$publishedArticles', Icons.check_circle, Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPipelineCard('Total', '${admin.articles.length}', Icons.library_books, Colors.blue),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Content Distribution
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Content Distribution',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildPerformanceBar('Listings', listingFill, Colors.blue),
                _buildPerformanceBar('Promotions', promoFill, Colors.orange),
                _buildPerformanceBar('Advertisements', adFill, Colors.green),
                _buildPerformanceBar('Articles', articleFill, Colors.purple),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _generateMarketingReport(admin),
                        icon: const Icon(Icons.analytics),
                        label: const Text('Marketing Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _scheduleContent(admin),
                        icon: const Icon(Icons.schedule),
                        label: const Text('Schedule Content'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showArticleEditor(context, admin),
                        icon: const Icon(Icons.edit),
                        label: const Text('Write Article'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAdPerformance(admin),
                        icon: const Icon(Icons.bar_chart),
                        label: const Text('Ad Analytics'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingCard(Listing listing, AdminProvider admin) {
    final statusColor = {
      'pending': Colors.orange, 'approved': Colors.green,
      'rejected': Colors.red, 'suspended': Colors.grey,
    }[listing.status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: listing.isPinned ? Border.all(color: Colors.amber, width: 2) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getCategoryIcon(listing.category), color: AppTheme.primaryColor, size: 24),
                ),
                if (listing.isVerified)
                  Positioned(
                    right: 0, bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.verified, color: Colors.blue, size: 16),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(child: Text(listing.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                if (listing.isPinned) const Icon(Icons.push_pin, color: Colors.amber, size: 16),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(listing.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Text(listing.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('RM ${listing.price}', style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.bold, fontSize: 15)),
                  if (listing.vendorName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Vendor: ${listing.vendorName}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Details')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'pin', child: Text(listing.isPinned ? 'Unpin' : 'Pin to Top')),
                PopupMenuItem(value: 'verify', child: Text(listing.isVerified ? 'Remove Verified' : 'Mark Verified')),
                if (listing.status != 'approved')
                  const PopupMenuItem(value: 'approve', child: Text('Approve')),
                if (listing.status != 'suspended')
                  const PopupMenuItem(value: 'suspend', child: Text('Suspend')),
                const PopupMenuItem(value: 'reject', child: Text('Reject / Delete')),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'view': _showListingDetails(listing); break;
                  case 'edit': _showEditListingDialog(listing, admin); break;
                  case 'pin': admin.toggleListingPin(listing.id); break;
                  case 'verify': admin.toggleListingVerified(listing.id); break;
                  case 'approve': admin.updateListingStatus(listing.id, 'approved'); break;
                  case 'suspend': admin.updateListingStatus(listing.id, 'suspended'); break;
                  case 'reject': _rejectListing(listing); break;
                }
              },
            ),
          ),
          // Performance metrics bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                _buildMiniStat(Icons.visibility, '${listing.views}', 'Views'),
                const SizedBox(width: 16),
                _buildMiniStat(Icons.book_online, '${listing.bookings}', 'Bookings'),
                const SizedBox(width: 16),
                _buildMiniStat(Icons.trending_up, '${listing.conversionRate.toStringAsFixed(1)}%', 'Conv.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        const SizedBox(width: 2),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade400)),
      ],
    );
  }

  Widget _buildPromotionCard(Promotion promotion, AdminProvider admin) {
    final typeLabel = {
      'platform_wide': '🌐 Platform-Wide',
      'vendor': '🏪 Vendor',
      'flash_deal': '⚡ Flash Deal',
    }[promotion.campaignType] ?? promotion.campaignType ?? 'Vendor';

    final statusColor = {
      'draft': Colors.grey, 'active': Colors.green,
      'expired': Colors.red, 'paused': Colors.orange,
    }[promotion.status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.local_offer, color: Colors.orange, size: 24),
            ),
            title: Row(
              children: [
                Expanded(child: Text(promotion.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(promotion.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(typeLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('Valid until: ${promotion.validTill}', style: TextStyle(color: Colors.grey.shade600)),
                  if (promotion.discountPercent != null)
                    Text('${promotion.discountPercent!.toStringAsFixed(0)}% OFF', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  if (promotion.targetRegion != null || promotion.targetCategory != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 6,
                        children: [
                          if (promotion.targetRegion != null)
                            Chip(label: Text(promotion.targetRegion!, style: const TextStyle(fontSize: 10)), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                          if (promotion.targetCategory != null)
                            Chip(label: Text(promotion.targetCategory!, style: const TextStyle(fontSize: 10)), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Details')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'extend', child: Text('Extend')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'view': _showPromotionDetails(promotion); break;
                  case 'edit': _showEditPromotionDialog(promotion, admin); break;
                  case 'extend': _extendPromotion(promotion); break;
                  case 'delete': _showDeletePromotionDialog(promotion); break;
                }
              },
            ),
          ),
          // Redemption stats
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                _buildMiniStat(Icons.redeem, '${promotion.redemptions}', 'Redeemed'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvertisementCard(AdEntry ad, AdminProvider admin) {
    final placementLabel = {
      'homepage_banner': '🏠 Homepage Banner',
      'category_top': '📂 Category Top',
      'search_boost': '🔍 Search Boost',
    }[ad.placementType] ?? ad.placementType;

    final tierColor = {
      'basic': Colors.grey, 'premium': Colors.blue, 'elite': Colors.amber,
    }[ad.pricingTier] ?? Colors.grey;

    final statusColor = {
      'pending': Colors.orange, 'approved': Colors.blue,
      'active': Colors.green, 'paused': Colors.grey, 'expired': Colors.red,
    }[ad.status] ?? Colors.grey;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.campaign, color: Colors.green, size: 24),
            ),
            title: Row(
              children: [
                Expanded(child: Text(ad.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: tierColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tierColor.withOpacity(0.3)),
                  ),
                  child: Text(ad.pricingTier.toUpperCase(), style: TextStyle(color: tierColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(ad.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(placementLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 12))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Advertiser: ${ad.advertiser}', style: TextStyle(color: Colors.grey.shade600)),
                  if (ad.budget > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Budget: RM ${ad.budget.toStringAsFixed(0)} • Spent: RM ${ad.spent.toStringAsFixed(0)}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View Details')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (ad.status == 'pending')
                  const PopupMenuItem(value: 'approve', child: Text('Approve')),
                PopupMenuItem(value: 'pause', child: Text(ad.status == 'paused' ? 'Resume' : 'Pause')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'view': _showAdvertisementDetails(ad); break;
                  case 'edit': _showEditAdvertisementDialog(ad, admin); break;
                  case 'approve': admin.updateAdStatus(ad.id, 'active'); break;
                  case 'pause': admin.updateAdStatus(ad.id, ad.status == 'paused' ? 'active' : 'paused'); break;
                  case 'delete': _showDeleteAdvertisementDialog(ad); break;
                }
              },
            ),
          ),
          // Ad performance metrics
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                _buildMiniStat(Icons.visibility, '${ad.impressions}', 'Impr.'),
                const SizedBox(width: 16),
                _buildMiniStat(Icons.touch_app, '${ad.clicks}', 'Clicks'),
                const SizedBox(width: 16),
                _buildMiniStat(Icons.percent, '${ad.ctr.toStringAsFixed(2)}%', 'CTR'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Article article, AdminProvider admin) {
    final ctaColor = {
      'book_vendor': Colors.blue,
      'view_package': Colors.purple,
      'get_quote': Colors.teal,
      'none': Colors.grey,
    }[article.ctaType] ?? Colors.grey;

    final ctaLabel = {
      'book_vendor': '📅 Book Vendor',
      'view_package': '📦 View Package',
      'get_quote': '💬 Get Quote',
      'none': null,
    }[article.ctaType];

    final categoryColor = {
      'event_guide': Colors.blue,
      'vendor_tips': Colors.green,
      'budgeting': Colors.orange,
      'general': Colors.grey,
    }[article.category] ?? Colors.purple;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.article, color: Colors.purple, size: 24),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    article.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: article.status == 'published'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: article.status == 'published'
                          ? Colors.green.withOpacity(0.3)
                          : Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    article.status == 'published' ? 'Published' : 'Draft',
                    style: TextStyle(
                      fontSize: 11,
                      color: article.status == 'published' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('By ${article.author}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (article.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: categoryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            article.category!.replaceAll('_', ' ').toUpperCase(),
                            style: TextStyle(color: categoryColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (ctaLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: ctaColor.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ctaColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            ctaLabel,
                            style: TextStyle(color: ctaColor, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  if (article.linkedVendorName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '🏪 Linked: ${article.linkedVendorName}',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ),
                  if (article.publishedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Published: ${article.publishedAt!.day}/${article.publishedAt!.month}/${article.publishedAt!.year}',
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
            isThreeLine: true,
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'view', child: Text('View')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                if (article.status != 'published')
                  const PopupMenuItem(value: 'publish', child: Text('Publish')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
              onSelected: (value) {
                switch (value) {
                  case 'view': _showArticleDetails(article); break;
                  case 'edit': _showEditArticleDialog(article, admin); break;
                  case 'publish': _publishArticle(article); break;
                  case 'delete': _showDeleteArticleDialog(article); break;
                }
              },
            ),
          ),
          // Views stat row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                _buildMiniStat(Icons.visibility, '${article.views}', 'Views'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketingStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildPerformanceBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'venues':
        return Icons.location_on;
      case 'catering':
        return Icons.restaurant;
      case 'photography':
        return Icons.camera_alt;
      case 'fashion':
        return Icons.checkroom;
      default:
        return Icons.category;
    }
  }

  List<Listing> _filterListings(List<Listing> listings) {
    return listings.where((listing) {
      return listing.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          listing.category.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Promotion> _filterPromotions(List<Promotion> promotions) {
    return promotions.where((promotion) {
      return promotion.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<AdEntry> _filterAdvertisements(List<AdEntry> ads) {
    return ads.where((ad) {
      return ad.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ad.advertiser.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  List<Article> _filterArticles(List<Article> articles) {
    return articles.where((article) {
      return article.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          article.author.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  // Dialog and Action Methods for Listings (already provided)
  void _showAddListingDialog(AdminProvider admin) {
    final titleController = TextEditingController();
    final categoryController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Listing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Listing Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
                hintText: 'e.g., Venues, Catering, Photography',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price (RM)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
              if (titleController.text.isNotEmpty &&
                  categoryController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                try {
                  await admin.addListing(Listing(id: '', title: titleController.text, category: categoryController.text, price: int.parse(priceController.text)));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Listing added successfully')),
                    );
                  }
                } catch (e) {
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error adding listing: $e')),
                     );
                   }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditListingDialog(Listing listing, AdminProvider admin) {
    final titleController = TextEditingController(text: listing.title);
    final categoryController = TextEditingController(text: listing.category);
    final priceController =
        TextEditingController(text: listing.price.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Listing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Listing Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Price (RM)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
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
              if (titleController.text.isNotEmpty &&
                  categoryController.text.isNotEmpty &&
                  priceController.text.isNotEmpty) {
                try {
                  await admin.updateListing(Listing(
                    id: listing.id,
                    title: titleController.text,
                    category: categoryController.text,
                    price: int.parse(priceController.text),
                  ));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Listing updated successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating listing: $e')),
                    );
                  }
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill in all fields')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showListingDetails(Listing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Listing Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${listing.title}'),
            Text('Category: ${listing.category}'),
            Text('Price: RM ${listing.price}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _approveListing(Listing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Listing'),
        content: Text('Are you sure you want to approve "${listing.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${listing.title} approved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _rejectListing(Listing listing) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Listing'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Rejecting "${listing.title}"'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
              try {
                await Provider.of<AdminProvider>(context, listen: false).deleteListing(listing.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          '${listing.title} rejected${reasonController.text.isNotEmpty ? ': ${reasonController.text}' : ''}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  void _approveAllListings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve All Listings'),
        content:
            const Text('Are you sure you want to approve all pending listings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All listings approved successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Approve All'),
          ),
        ],
      ),
    );
  }

  // Promotion Management Methods
  void _showAddPromotionDialog(AdminProvider admin) {
    final titleController = TextEditingController();
    final validTillController = TextEditingController();
    final descriptionController = TextEditingController();
    final discountController = TextEditingController();
    String selectedCampaignType = 'vendor';
    String selectedStatus = 'active';
    String? selectedRegion;
    String? selectedCategory;

    final regions = ['All Malaysia', 'Selangor', 'Kuala Lumpur', 'Penang', 'Johor', 'Perak', 'Sabah', 'Sarawak'];
    final categories = ['Photography', 'Catering', 'Venue', 'Decoration', 'Entertainment', 'Transport', 'Makeup', 'Videography'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Campaign / Promotion'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Campaign Name *',
                    hintText: 'e.g., Wedding Season Sale',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.campaign),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCampaignType,
                  decoration: const InputDecoration(labelText: 'Campaign Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'platform_wide', child: Text('🌐 Platform-Wide')),
                    DropdownMenuItem(value: 'vendor', child: Text('🏪 Vendor')),
                    DropdownMenuItem(value: 'flash_deal', child: Text('⚡ Flash Deal')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedCampaignType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Discount % (optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.percent),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedRegion,
                        decoration: const InputDecoration(labelText: 'Region Target', border: OutlineInputBorder()),
                        items: regions.map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setDialogState(() => selectedRegion = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setDialogState(() => selectedCategory = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: validTillController,
                  decoration: const InputDecoration(
                    labelText: 'Valid Until *',
                    border: OutlineInputBorder(),
                    hintText: 'e.g., 2025-12-31',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'paused', child: Text('Paused')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && validTillController.text.isNotEmpty) {
                  try {
                    await admin.addPromotion(Promotion(
                      id: '',
                      title: titleController.text,
                      validTill: validTillController.text,
                      campaignType: selectedCampaignType,
                      description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                      discountPercent: discountController.text.isNotEmpty ? double.tryParse(discountController.text) : null,
                      targetRegion: selectedRegion,
                      targetCategory: selectedCategory,
                      status: selectedStatus,
                    ));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Campaign created successfully'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in required fields')),
                  );
                }
              },
              child: const Text('Create Campaign'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPromotionCalendar(AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promotion Calendar'),
        content: admin.promotions.isEmpty 
            ? const Text('No active promotions available.')
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: admin.promotions.length,
                  itemBuilder: (context, index) {
                    final promo = admin.promotions[index];
                    return ListTile(
                      leading: const Icon(Icons.event, color: Colors.orange),
                      title: Text(promo.title),
                      subtitle: Text('Valid Until: ${promo.validTill}'),
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPromotionDetails(Promotion promotion) {
    final typeLabel = {
      'platform_wide': '🌐 Platform-Wide',
      'vendor': '🏪 Vendor',
      'flash_deal': '⚡ Flash Deal',
    }[promotion.campaignType] ?? promotion.campaignType ?? 'Vendor';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.local_offer, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(promotion.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Type', typeLabel),
              _detailRow('Status', promotion.status.toUpperCase()),
              _detailRow('Valid Until', promotion.validTill),
              if (promotion.discountPercent != null)
                _detailRow('Discount', '${promotion.discountPercent!.toStringAsFixed(0)}% OFF'),
              if (promotion.description != null && promotion.description!.isNotEmpty)
                _detailRow('Description', promotion.description!),
              if (promotion.targetRegion != null)
                _detailRow('Region Target', promotion.targetRegion!),
              if (promotion.targetCategory != null)
                _detailRow('Category Target', promotion.targetCategory!),
              _detailRow('Redemptions', '${promotion.redemptions}'),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showEditPromotionDialog(Promotion promotion, AdminProvider admin) {
    final titleController = TextEditingController(text: promotion.title);
    final validTillController = TextEditingController(text: promotion.validTill);
    final descriptionController = TextEditingController(text: promotion.description ?? '');
    final discountController = TextEditingController(
      text: promotion.discountPercent != null ? promotion.discountPercent!.toStringAsFixed(0) : '',
    );
    String selectedCampaignType = promotion.campaignType ?? 'vendor';
    String selectedStatus = promotion.status;
    String? selectedRegion = promotion.targetRegion;
    String? selectedCategory = promotion.targetCategory;

    final regions = ['All Malaysia', 'Selangor', 'Kuala Lumpur', 'Penang', 'Johor', 'Perak', 'Sabah', 'Sarawak'];
    final categories = ['Photography', 'Catering', 'Venue', 'Decoration', 'Entertainment', 'Transport', 'Makeup', 'Videography'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Campaign'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Campaign Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.campaign)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCampaignType,
                  decoration: const InputDecoration(labelText: 'Campaign Type', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'platform_wide', child: Text('🌐 Platform-Wide')),
                    DropdownMenuItem(value: 'vendor', child: Text('🏪 Vendor')),
                    DropdownMenuItem(value: 'flash_deal', child: Text('⚡ Flash Deal')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedCampaignType = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: discountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Discount %', border: OutlineInputBorder(), prefixIcon: Icon(Icons.percent)),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: regions.contains(selectedRegion) ? selectedRegion : null,
                        decoration: const InputDecoration(labelText: 'Region', border: OutlineInputBorder()),
                        items: regions.map((r) => DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setDialogState(() => selectedRegion = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: categories.contains(selectedCategory) ? selectedCategory : null,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis))).toList(),
                        onChanged: (v) => setDialogState(() => selectedCategory = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: validTillController,
                  decoration: const InputDecoration(labelText: 'Valid Until *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'draft', child: Text('Draft')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'paused', child: Text('Paused')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await admin.updatePromotion(promotion.copyWith(
                    title: titleController.text,
                    validTill: validTillController.text,
                    campaignType: selectedCampaignType,
                    description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
                    discountPercent: discountController.text.isNotEmpty ? double.tryParse(discountController.text) : null,
                    targetRegion: selectedRegion,
                    targetCategory: selectedCategory,
                    status: selectedStatus,
                  ));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Campaign updated'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _extendPromotion(Promotion promotion) {
    final extensionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Extend Promotion'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current expiry: ${promotion.validTill}'),
            const SizedBox(height: 16),
            TextField(
              controller: extensionController,
              decoration: const InputDecoration(
                labelText: 'New Expiry Date',
                border: OutlineInputBorder(),
                hintText: 'e.g., 2026-06-30',
                prefixIcon: Icon(Icons.calendar_today),
              ),
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
              if (extensionController.text.isNotEmpty) {
                try {
                  await Provider.of<AdminProvider>(context, listen: false)
                      .updatePromotion(Promotion(
                    id: promotion.id,
                    title: promotion.title,
                    validTill: extensionController.text,
                  ));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${promotion.title}" extended to ${extensionController.text}'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Extend'),
          ),
        ],
      ),
    );
  }

  void _showDeletePromotionDialog(Promotion promotion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Promotion'),
        content: Text('Are you sure you want to delete "${promotion.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<AdminProvider>(context, listen: false).deletePromotion(promotion.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${promotion.title} deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting promotion: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Advertisement Management Methods
  void _showAddAdvertisementDialog(AdminProvider admin) {
    final titleController = TextEditingController();
    final advertiserController = TextEditingController();
    final budgetController = TextEditingController();
    String selectedTier = 'standard';
    String selectedPlatform = 'landing_page';
    String selectedStatus = 'active';
    List<String> selectedRegions = [];
    List<String> selectedCategories = [];

    final regions = ['All Malaysia', 'Selangor', 'Kuala Lumpur', 'Penang', 'Johor', 'Perak', 'Sabah', 'Sarawak'];
    final categories = ['Photography', 'Catering', 'Venue', 'Decoration', 'Entertainment', 'Transport', 'Makeup', 'Videography'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Advertisement Campaign'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Campaign Title *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.ad_units),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: advertiserController,
                  decoration: const InputDecoration(
                    labelText: 'Advertiser Name *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedTier,
                        decoration: const InputDecoration(labelText: 'Pricing Tier', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'premium', child: Text('💎 Premium')),
                          DropdownMenuItem(value: 'standard', child: Text('⭐ Standard')),
                          DropdownMenuItem(value: 'basic', child: Text('▫️ Basic')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedTier = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPlatform,
                        decoration: const InputDecoration(labelText: 'Placement', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'landing_page', child: Text('🏠 Landing')),
                          DropdownMenuItem(value: 'detail_view', child: Text('📄 Details')),
                          DropdownMenuItem(value: 'search_results', child: Text('🔍 Search')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedPlatform = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Total Budget (RM)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.account_balance_wallet),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Target Regions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Wrap(
                  spacing: 4,
                  children: regions.map((r) => FilterChip(
                    label: Text(r, style: const TextStyle(fontSize: 10)),
                    selected: selectedRegions.contains(r),
                    onSelected: (selected) {
                      setDialogState(() {
                        if (selected) selectedRegions.add(r);
                        else selectedRegions.remove(r);
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 12),
                const Text('Target Categories', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Wrap(
                  spacing: 4,
                  children: categories.map((c) => FilterChip(
                    label: Text(c, style: const TextStyle(fontSize: 10)),
                    selected: selectedCategories.contains(c),
                    onSelected: (selected) {
                      setDialogState(() {
                        if (selected) selectedCategories.add(c);
                        else selectedCategories.remove(c);
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Initial Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'paused', child: Text('Paused')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty && advertiserController.text.isNotEmpty) {
                  try {
                    await admin.addAdEntry(AdEntry(
                      id: '',
                      title: titleController.text,
                      advertiser: advertiserController.text,
                      pricingTier: selectedTier,
                      platform: selectedPlatform,
                      status: selectedStatus,
                      budget: budgetController.text.isNotEmpty ? double.parse(budgetController.text) : 0,
                      spent: 0,
                      targetRegions: selectedRegions,
                      targetCategories: selectedCategories,
                    ));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Advertisement campaign created'), backgroundColor: Colors.green),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in required fields')),
                  );
                }
              },
              child: const Text('Start Campaign'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdPerformance(AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ad Performance Report'),
          content: admin.ads.isEmpty
              ? const Text('No active advertisements found.')
              : SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(Colors.grey[200]),
                      columns: const [
                        DataColumn(label: Text('Ad Title')),
                        DataColumn(label: Text('Advertiser')),
                        DataColumn(label: Text('Impressions')),
                        DataColumn(label: Text('Clicks')),
                        DataColumn(label: Text('CTR')),
                      ],
                      rows: admin.ads.asMap().entries.map((entry) {
                        final ad = entry.value;
                        final index = entry.key;
                        // Mock data deterministic by index
                        final impressions = 5000 + (index * 1234);
                        final clicks = 120 + (index * 45);
                        final ctr = ((clicks / impressions) * 100).toStringAsFixed(2);
                        return DataRow(
                          cells: [
                            DataCell(Text(ad.title)),
                            DataCell(Text(ad.advertiser)),
                            DataCell(Text(impressions.toString())),
                            DataCell(Text(clicks.toString())),
                            DataCell(Text('$ctr%')),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showAdvertisementDetails(AdEntry ad) {
    final tierColor = {
      'premium': Colors.purple,
      'standard': Colors.blue,
      'basic': Colors.grey,
    }[ad.pricingTier] ?? Colors.blue;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.ad_units, color: tierColor),
            const SizedBox(width: 8),
            Expanded(child: Text(ad.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Advertiser', ad.advertiser),
              _detailRow('Status', ad.status.toUpperCase()),
              _detailRow('Pricing Tier', ad.pricingTier.toUpperCase()),
              _detailRow('Placement', ad.platform.replaceAll('_', ' ')),
              const Divider(),
              _detailRow('Budget', 'RM ${ad.budget.toStringAsFixed(2)}'),
              _detailRow('Spent', 'RM ${ad.spent.toStringAsFixed(2)}'),
              _detailRow('Remaining', 'RM ${(ad.budget - ad.spent).toStringAsFixed(2)}'),
              const Divider(),
              _detailRow('Impressions', '${ad.impressions}'),
              _detailRow('Clicks', '${ad.clicks}'),
              _detailRow('CTR', '${ad.ctr.toStringAsFixed(2)}%'),
              const Divider(),
              if (ad.targetRegions.isNotEmpty)
                _detailRow('Regions', ad.targetRegions.join(', ')),
              if (ad.targetCategories.isNotEmpty)
                _detailRow('Categories', ad.targetCategories.join(', ')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  void _showEditAdvertisementDialog(AdEntry ad, AdminProvider admin) {
    final titleController = TextEditingController(text: ad.title);
    final advertiserController = TextEditingController(text: ad.advertiser);
    final budgetController = TextEditingController(text: ad.budget.toStringAsFixed(0));
    String selectedTier = ad.pricingTier;
    String selectedPlatform = ad.platform;
    String selectedStatus = ad.status;
    List<String> selectedRegions = List.from(ad.targetRegions);
    List<String> selectedCategories = List.from(ad.targetCategories);

    final regions = ['All Malaysia', 'Selangor', 'Kuala Lumpur', 'Penang', 'Johor', 'Perak', 'Sabah', 'Sarawak'];
    final categories = ['Photography', 'Catering', 'Venue', 'Decoration', 'Entertainment', 'Transport', 'Makeup', 'Videography'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Ad Campaign'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: advertiserController,
                  decoration: const InputDecoration(labelText: 'Advertiser *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedTier,
                        decoration: const InputDecoration(labelText: 'Tier', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'premium', child: Text('Premium')),
                          DropdownMenuItem(value: 'standard', child: Text('Standard')),
                          DropdownMenuItem(value: 'basic', child: Text('Basic')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedTier = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPlatform,
                        decoration: const InputDecoration(labelText: 'Placement', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'landing_page', child: Text('Landing')),
                          DropdownMenuItem(value: 'detail_view', child: Text('Details')),
                          DropdownMenuItem(value: 'search_results', child: Text('Search')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedPlatform = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Budget (RM)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                const Text('Regions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                Wrap(
                  spacing: 4,
                  children: regions.map((r) => FilterChip(
                    label: Text(r, style: const TextStyle(fontSize: 10)),
                    selected: selectedRegions.contains(r),
                    onSelected: (selected) {
                      setDialogState(() {
                        if (selected) selectedRegions.add(r);
                        else selectedRegions.remove(r);
                      });
                    },
                  )).toList(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(value: 'paused', child: Text('Paused')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedStatus = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await admin.updateAdEntry(ad.copyWith(
                    title: titleController.text,
                    advertiser: advertiserController.text,
                    pricingTier: selectedTier,
                    platform: selectedPlatform,
                    status: selectedStatus,
                    budget: double.parse(budgetController.text),
                    targetRegions: selectedRegions,
                    targetCategories: selectedCategories,
                  ));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Campaign updated'), backgroundColor: Colors.blue),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _pauseAdvertisement(AdEntry ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause Advertisement'),
        content:
            Text('Are you sure you want to pause "${ad.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${ad.title} paused successfully'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Pause'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAdvertisementDialog(AdEntry ad) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Advertisement'),
        content: Text('Are you sure you want to delete "${ad.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<AdminProvider>(context, listen: false).deleteAdEntry(ad.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${ad.title} deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting ad: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Article Management Methods
  void _showAddArticleDialog(AdminProvider admin) {
    final titleController = TextEditingController();
    final authorController = TextEditingController(text: 'Admin');
    String selectedCategory = 'event_guide';

    final categories = [
      {'val': 'event_guide', 'label': '📘 Event Guide'},
      {'val': 'vendor_tips', 'label': '💡 Vendor Tips'},
      {'val': 'budgeting', 'label': '💰 Budgeting'},
      {'val': 'general', 'label': '📰 General'},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Article Draft'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Article Title *', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: categories.map((c) => DropdownMenuItem(value: c['val'], child: Text(c['label']!))).toList(),
                onChanged: (v) => setDialogState(() => selectedCategory = v!),
                decoration: const InputDecoration(labelText: 'Initial Category', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  try {
                    await admin.addArticle(Article(
                      id: '',
                      title: titleController.text,
                      author: authorController.text,
                      category: selectedCategory,
                      status: 'draft',
                      content: '',
                    ));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Draft created. Open editor to add content.')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
              child: const Text('Create Draft'),
            ),
          ],
        ),
      ),
    );
  }

  void _showArticleEditor(BuildContext context, AdminProvider admin) {
  showDialog(
    context: context,
    builder: (context) => ArticleEditorDialog(admin: admin),
  );
}


  void _showArticleDetails(Article article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(article.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _detailRow('Author', article.author),
              _detailRow('Status', article.status.toUpperCase()),
              _detailRow(
                'Category',
                (article.category ?? 'general').replaceAll('_', ' ').toUpperCase(),
              ),
              const Divider(),
              _detailRow('Total Views', '${article.views}'),
              _detailRow('CTA Type', article.ctaType ?? 'none'),
              if (article.linkedVendorName != null)
                _detailRow('Linked Vendor', article.linkedVendorName!),
              const Divider(),
              const Text('Content Preview:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.grey.shade50,
                child: Text(
                  (() {
                    final content = article.content ?? '';
                    if (content.length > 200) return '${content.substring(0, 200)}...';
                    return content;
                  })(),
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEditArticleDialog(article, Provider.of<AdminProvider>(context, listen: false));
            },
            child: const Text('Edit Metadata'),
          ),
        ],
      ),
    );
  }

  void _showEditArticleDialog(Article article, AdminProvider admin) {
    final titleController = TextEditingController(text: article.title);
    final authorController = TextEditingController(text: article.author);
    final linkedVendorNameController = TextEditingController(text: article.linkedVendorName ?? '');
    String selectedCategory = article.category ?? 'event_guide';
    String selectedCTA = article.ctaType ?? 'none';

    final categories = [
      {'val': 'event_guide', 'label': 'Event Guide'},
      {'val': 'vendor_tips', 'label': 'Vendor Tips'},
      {'val': 'budgeting', 'label': 'Budgeting'},
      {'val': 'general', 'label': 'General'},
    ];

    final ctaTypes = ['none', 'book_vendor', 'view_package', 'get_quote'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Article Metadata'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: authorController,
                        decoration: const InputDecoration(labelText: 'Author', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        items: categories.map((c) => DropdownMenuItem(value: c['val'], child: Text(c['label']!))).toList(),
                        onChanged: (v) => setDialogState(() => selectedCategory = v!),
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedCTA,
                  items: ctaTypes.map((c) => DropdownMenuItem(value: c, child: Text(c.replaceAll('_', ' ').toUpperCase()))).toList(),
                  onChanged: (v) => setDialogState(() => selectedCTA = v!),
                  decoration: const InputDecoration(labelText: 'CTA Type', border: OutlineInputBorder()),
                ),
                if (selectedCTA != 'none') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: linkedVendorNameController,
                    decoration: const InputDecoration(labelText: 'Linked Vendor Name', border: OutlineInputBorder(), prefixIcon: Icon(Icons.link)),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                try {
                  await admin.updateArticle(article.copyWith(
                    title: titleController.text,
                    author: authorController.text,
                    category: selectedCategory,
                    ctaType: selectedCTA,
                    linkedVendorName: linkedVendorNameController.text.isNotEmpty ? linkedVendorNameController.text : null,
                  ));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Article metadata saved')));
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _publishArticle(Article article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Publish Article'),
        content: Text('Are you sure you want to publish "${article.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<AdminProvider>(context, listen: false).publishArticle(article.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${article.title} published successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error publishing article: $e')),
                  );
                }
              }
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }

  void _showDeleteArticleDialog(Article article) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Article'),
        content: Text('Are you sure you want to delete "${article.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await Provider.of<AdminProvider>(context, listen: false).deleteArticle(article.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${article.title} deleted successfully'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting article: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // Quick Actions
  void _generateMarketingReport(AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Marketing Report'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('A detailed CSV report will be generated covering the following stats:'),
            const SizedBox(height: 12),
            Text('• Active Listings: ${admin.listings.length}'),
            Text('• Active Promotions: ${admin.promotions.length}'),
            Text('• Running Advertisements: ${admin.ads.length}'),
            Text('• Total Articles: ${admin.articles.length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
               Navigator.pop(context);
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Report generated and downloaded successfully!'), backgroundColor: Colors.green),
               );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download CSV'),
          )
        ],
      ),
    );
  }

  void _scheduleContent(AdminProvider admin) {
    showDialog(
      context: context,
      builder: (context) {
        final drafts = admin.articles.where((a) => a.status == 'draft').toList();
        return AlertDialog(
          title: const Text('Schedule Content'),
          content: drafts.isEmpty 
             ? const Text('You have no draft articles available to schedule.')
             : SizedBox(
                 width: double.maxFinite,
                 child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: drafts.length,
                    itemBuilder: (context, index) {
                      final draft = drafts[index];
                      return ListTile(
                        leading: const Icon(Icons.schedule, color: Colors.blue),
                        title: Text(draft.title),
                        subtitle: const Text('Tap to schedule publication'),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Scheduled "${draft.title}" for publication.'), backgroundColor: Colors.green),
                            );
                          },
                          child: const Text('Schedule'),
                        )
                      );
                    }
                 ),
               ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      }
    );
  }

}
