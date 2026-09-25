import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class VendorSocialMediaIntegrationScreen extends StatefulWidget {
  const VendorSocialMediaIntegrationScreen({super.key});

  @override
  State<VendorSocialMediaIntegrationScreen> createState() => _VendorSocialMediaIntegrationScreenState();
}

class _VendorSocialMediaIntegrationScreenState extends State<VendorSocialMediaIntegrationScreen> {
  final List<Map<String, dynamic>> _socialAccounts = [
    {
      'platform': 'Instagram',
      'account': 'Not connected',
      'status': 'Disconnected',
      'followers': 0,
      'posts': 0,
      'engagement': 0.0,
      'lastPost': null,
      'color': Colors.pink,
      'icon': Icons.camera_alt,
    },
    {
      'platform': 'TikTok',
      'account': 'Not connected',
      'status': 'Disconnected',
      'followers': 0,
      'posts': 0,
      'engagement': 0.0,
      'lastPost': null,
      'color': Colors.black,
      'icon': Icons.music_note,
    },
    {
      'platform': 'Facebook',
      'account': 'Not connected',
      'status': 'Disconnected',
      'followers': 0,
      'posts': 0,
      'engagement': 0.0,
      'lastPost': null,
      'color': Colors.blue.shade800,
      'icon': Icons.facebook,
    },
    {
      'platform': 'Twitter / X',
      'account': 'Not connected',
      'status': 'Disconnected',
      'followers': 0,
      'posts': 0,
      'engagement': 0.0,
      'lastPost': null,
      'color': Colors.black87,
      'icon': Icons.tag,
    },
  ];

  final List<Map<String, dynamic>> _scheduledPosts = [];

  final List<Map<String, dynamic>> _reviews = [];

  String _selectedTab = 'Accounts';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Social Media Integration',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.primaryColor),
            onPressed: _addNewAccount,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab selector
          _buildTabSelector(),

          // Content based on selected tab
          Expanded(
            child: _selectedTab == 'Accounts'
                ? _buildAccountsView()
                : _selectedTab == 'Posts'
                    ? _buildPostsView()
                    : _buildReviewsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton('Accounts', _selectedTab == 'Accounts'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTabButton('Posts', _selectedTab == 'Posts'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTabButton('Reviews', _selectedTab == 'Reviews'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return ElevatedButton(
      onPressed: () => setState(() => _selectedTab = title),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.white,
        foregroundColor: isSelected ? Colors.white : AppTheme.textPrimaryColor,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
      ),
      child: Text(title),
    );
  }

  Widget _buildAccountsView() {
    final connectedAccounts = _socialAccounts.where((a) => a['status'] == 'Connected').length;
    final totalFollowers = _socialAccounts.fold<int>(0, (sum, a) => sum + (a['followers'] as int));

    return Column(
      children: [
        // Stats overview
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Connected',
                  connectedAccounts.toString(),
                  Icons.link,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Followers',
                  _formatNumber(totalFollowers),
                  Icons.people,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Engagement',
                  '${_calculateAvgEngagement().toStringAsFixed(1)}%',
                  Icons.trending_up,
                  AppTheme.accentColor,
                ),
              ),
            ],
          ),
        ),

        // Accounts list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _socialAccounts.length,
            itemBuilder: (context, index) =>
                _buildAccountCard(_socialAccounts[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
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
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account) {
    final isConnected = account['status'] == 'Connected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          // Platform icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (account['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              account['icon'] as IconData,
              color: account['color'] as Color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Account details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      account['platform'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isConnected ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        account['status'],
                        style: TextStyle(
                          color: isConnected ? Colors.green : Colors.grey,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  account['account'],
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
                if (isConnected) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildAccountMetric('Followers', account['followers']),
                      const SizedBox(width: 16),
                      _buildAccountMetric('Posts', account['posts']),
                      const SizedBox(width: 16),
                      _buildAccountMetric('Engagement', '${account['engagement']}%'),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Action button
          ElevatedButton(
            onPressed: isConnected ? () => _manageAccount(account) : () => _connectAccount(account),
            style: ElevatedButton.styleFrom(
              backgroundColor: isConnected ? AppTheme.primaryColor : AppTheme.successColor,
              minimumSize: const Size(80, 32),
            ),
            child: Text(isConnected ? 'Manage' : 'Connect'),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountMetric(String label, dynamic value) {
    String displayValue;
    if (label == 'Engagement') {
      // Always show engagement as string with % sign, but keep value as double
      displayValue = value is String ? value : '${value.toString()}%';
    } else {
      // Followers and Posts should be int
      int intValue;
      if (value is int) {
        intValue = value;
      } else if (value is String && value.endsWith('%')) {
        // Defensive: engagement as string, not for followers/posts
        intValue = 0;
      } else {
        intValue = int.tryParse(value.toString()) ?? 0;
      }
      displayValue = _formatNumber(intValue);
    }

    return Row(
      children: [
        Text(
          displayValue,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPostsView() {
    return Column(
      children: [
        // Quick actions
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _createNewPost,
                  icon: const Icon(Icons.add),
                  label: const Text('New Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _scheduleBulkPosts,
                  icon: const Icon(Icons.schedule),
                  label: const Text('Bulk Schedule'),
                ),
              ),
            ],
          ),
        ),

        // Posts list
        Expanded(
          child: _scheduledPosts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'No Scheduled Posts',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap "New Post" to create and schedule your posts.',
                        style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _scheduledPosts.length,
                  itemBuilder: (context, index) =>
                      _buildPostCard(_scheduledPosts[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> post) {
    final isScheduled = post['status'] == 'Scheduled';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPlatformColor(post['platform']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post['platform'],
                  style: TextStyle(
                    color: _getPlatformColor(post['platform']),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isScheduled ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  post['status'],
                  style: TextStyle(
                    color: isScheduled ? Colors.green : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                post['scheduledTime'],
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post['content'],
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.image, size: 16, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 4),
              Text(
                '${post['images']} image${post['images'] != 1 ? 's' : ''}',
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _editPost(post),
                    icon: const Icon(Icons.edit, size: 18),
                    color: AppTheme.primaryColor,
                  ),
                  IconButton(
                    onPressed: () => _deletePost(post),
                    icon: const Icon(Icons.delete, size: 18),
                    color: AppTheme.errorColor,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsView() {
    final pendingReviews = _reviews.where((r) => !r['responded']).length;

    return Column(
      children: [
        // Reviews stats
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Total Reviews',
                  _reviews.length.toString(),
                  Icons.star,
                  AppTheme.accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Avg Rating',
                  '${_calculateAvgRating().toStringAsFixed(1)}/5',
                  Icons.grade,
                  AppTheme.warningColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Pending Response',
                  pendingReviews.toString(),
                  Icons.reply,
                  AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ),

        // Reviews list
        Expanded(
          child: _reviews.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text(
                        'No Reviews Yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Reviews from social accounts will sync here once connected.',
                        style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) =>
                      _buildReviewCard(_reviews[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPlatformColor(review['platform']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  review['platform'],
                  style: TextStyle(
                    color: _getPlatformColor(review['platform']),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    size: 16,
                    color: index < review['rating'] ? Colors.amber : Colors.grey.shade300,
                  ),
                ),
              ),
              const Spacer(),
              if (!review['responded'])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: AppTheme.errorColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 4),
              Text(
                review['customer'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.calendar_today, size: 16, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 4),
              Text(
                review['date'],
                style: const TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            review['review'],
            style: const TextStyle(
              color: AppTheme.textPrimaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          if (!review['responded'])
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _respondToReview(review),
                    icon: const Icon(Icons.reply, size: 16),
                    label: const Text('Respond'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _markAsResponded(review),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Mark Done'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  double _calculateAvgEngagement() {
    final connectedAccounts = _socialAccounts.where((a) => a['status'] == 'Connected');
    if (connectedAccounts.isEmpty) return 0.0;

    final totalEngagement = connectedAccounts.fold<double>(
      0,
      (sum, account) => sum + (account['engagement'] as double),
    );

    return totalEngagement / connectedAccounts.length;
  }

  double _calculateAvgRating() {
    if (_reviews.isEmpty) return 0.0;

    final totalRating = _reviews.fold<int>(
      0,
      (sum, review) => sum + (review['rating'] as int),
    );

    return totalRating / _reviews.length;
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'Facebook':
        return Colors.blue.shade800;
      case 'Instagram':
        return Colors.pink;
      case 'Twitter':
        return Colors.blue;
      case 'Google':
        return Colors.green;
      default:
        return AppTheme.primaryColor;
    }
  }

  void _addNewAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add new social media account (placeholder)')),
    );
  }

  void _manageAccount(Map<String, dynamic> account) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Manage ${account['platform']} account (placeholder)')),
    );
  }

  void _connectAccount(Map<String, dynamic> account) {
    setState(() {
      account['status'] = 'Connected';
      account['account'] = 'Connected account';
      account['followers'] = 0;
      account['posts'] = 0;
      account['engagement'] = 0.0;
      account['lastPost'] = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${account['platform']} connected successfully')),
    );
  }

  void _createNewPost() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create new post (placeholder)')),
    );
  }

  void _scheduleBulkPosts() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bulk schedule posts (placeholder)')),
    );
  }

  void _editPost(Map<String, dynamic> post) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit post ${post['id']} (placeholder)')),
    );
  }

  void _deletePost(Map<String, dynamic> post) {
    setState(() {
      _scheduledPosts.remove(post);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post deleted')),
    );
  }

  void _respondToReview(Map<String, dynamic> review) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Respond to review from ${review['customer']} (placeholder)')),
    );
  }

  void _markAsResponded(Map<String, dynamic> review) {
    setState(() {
      review['responded'] = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review marked as responded')),
    );
  }
}
