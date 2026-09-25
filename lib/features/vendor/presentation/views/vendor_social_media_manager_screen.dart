import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class VendorSocialMediaManagerScreen extends StatefulWidget {
  const VendorSocialMediaManagerScreen({super.key});

  @override
  State<VendorSocialMediaManagerScreen> createState() => _VendorSocialMediaManagerScreenState();
}

class _VendorSocialMediaManagerScreenState extends State<VendorSocialMediaManagerScreen> {
  String _selectedTab = 'Accounts';
  final List<String> _platforms = ['Facebook', 'Instagram', 'Twitter', 'LinkedIn', 'TikTok'];
  
  List<Map<String, dynamic>> _featuredPosts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFeaturedPosts();
    });
  }

  Future<void> _loadFeaturedPosts() async {
    final provider = Provider.of<VendorProfileProvider>(context, listen: false);
    final posts = await provider.getFeaturedPosts();
    if (!mounted) return;
    setState(() {
      _featuredPosts = posts;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Social Media Manager',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
      ),
      body: Consumer<VendorProfileProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.vendorProfile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildTabSelector(),
              Expanded(
                child: _selectedTab == 'Accounts'
                    ? _buildAccountsView(provider)
                    : _buildFeaturedPostsView(provider),
              ),
            ],
          );
        },
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
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton('Featured Posts', _selectedTab == 'Featured Posts'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected) {
    return ElevatedButton(
      onPressed: () {
        setState(() => _selectedTab = title);
        if (title == 'Featured Posts') {
          _loadFeaturedPosts();
        }
      },
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

  Widget _buildAccountsView(VendorProfileProvider provider) {
    final profile = provider.vendorProfile ?? {};
    
    // Build accounts list dynamically
    final accounts = _platforms.map((platform) {
      final dbKey = 'social_${platform.toLowerCase()}';
      final url = profile[dbKey] as String?;
      final isConnected = url != null && url.isNotEmpty;

      return {
        'platform': platform,
        'url': url,
        'status': isConnected ? 'Connected' : 'Not Connected',
        'color': _getPlatformColor(platform),
        'dbKey': dbKey,
        'isConnected': isConnected,
      };
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                const Text(
                  'Social Accounts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                ...accounts.map((account) => _buildAccountCard(account, provider)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(Map<String, dynamic> account, VendorProfileProvider provider) {
    final isConnected = account['isConnected'] as bool;
    final platform = account['platform'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isConnected ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (account['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getPlatformIcon(platform),
              color: account['color'] as Color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                if (isConnected)
                  GestureDetector(
                    onTap: () => _launchURL(account['url']),
                    child: Text(
                      account['url'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isConnected) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Connected',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 18),
              onPressed: () => _editAccountUrl(account, provider),
            ),
          ] else ...[
            ElevatedButton(
              onPressed: () => _editAccountUrl(account, provider),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('Connect'),
            ),
          ],
        ],
      ),
    );
  }

  void _editAccountUrl(Map<String, dynamic> account, VendorProfileProvider provider) {
    final TextEditingController controller = TextEditingController(text: account['url'] ?? '');
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${account['isConnected'] ? 'Edit' : 'Connect'} ${account['platform']}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Profile URL',
            hintText: 'https://...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              String url = controller.text.trim();
              Navigator.pop(context);
              if (url.isNotEmpty && !url.startsWith('http')) {
                url = 'https://$url';
              }
              final currentProfile = provider.vendorProfile ?? {};
              final updatedData = Map<String, dynamic>.from(currentProfile);
              updatedData[account['dbKey']] = url;

              final success = await provider.saveProfessionalOnboardingData(updatedData);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedPostsView(VendorProfileProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Featured Recent Posts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Show up to 3 of your best recent posts to customers.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _featuredPosts.length >= 3 
                      ? null 
                      : () => _addFeaturedPostDialog(provider),
                  icon: const Icon(Icons.add),
                  label: Text('${_featuredPosts.length}/3 Posts'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _featuredPosts.isEmpty
                ? const Center(child: Text('No featured posts. Add some!'))
                : ListView.builder(
                    itemCount: _featuredPosts.length,
                    itemBuilder: (context, index) {
                      final post = _featuredPosts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
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
                            Icon(
                              _getPlatformIcon(post['platform']),
                              color: _getPlatformColor(post['platform']),
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post['platform'],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  GestureDetector(
                                    onTap: () => _launchURL(post['post_url']),
                                    child: Text(
                                      post['post_url'],
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final success = await provider.removeFeaturedPost(post['id']);
                                if (success) {
                                  _loadFeaturedPosts();
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  void _addFeaturedPostDialog(VendorProfileProvider provider) {
    String selectedPlatform = _platforms.first;
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Featured Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedPlatform,
                items: _platforms.map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
                onChanged: (val) => setState(() => selectedPlatform = val!),
                decoration: const InputDecoration(labelText: 'Platform'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Post URL',
                  hintText: 'https://...',
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
                String url = urlController.text.trim();
                if (url.isEmpty) return;
                if (!url.startsWith('http')) url = 'https://$url';
                
                Navigator.pop(context);
                final success = await provider.addFeaturedPost(selectedPlatform, url);
                if (success && mounted) {
                  _loadFeaturedPosts();
                } else if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(provider.error ?? 'Error adding post')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Could not launch \$url');
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'Facebook':
        return Icons.facebook;
      case 'Instagram':
        return Icons.camera_alt;
      case 'Twitter':
        return Icons.chat_bubble;
      case 'LinkedIn':
        return Icons.business;
      case 'TikTok':
        return Icons.music_note;
      default:
        return Icons.public;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform) {
      case 'Facebook':
        return const Color(0xFF1877F2);
      case 'Instagram':
        return const Color(0xFFE4405F);
      case 'Twitter':
        return const Color(0xFF1DA1F2);
      case 'LinkedIn':
        return const Color(0xFF0077B5);
      case 'TikTok':
        return const Color(0xFF000000);
      default:
        return AppTheme.primaryColor;
    }
  }
}
