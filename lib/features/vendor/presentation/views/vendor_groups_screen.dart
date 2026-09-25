import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/data/providers/vendor_networking_provider.dart';
import 'package:eventease/features/vendor/presentation/widgets/group_card.dart';

class VendorGroupsScreen extends StatefulWidget {
  const VendorGroupsScreen({super.key});

  @override
  State<VendorGroupsScreen> createState() => _VendorGroupsScreenState();
}

class _VendorGroupsScreenState extends State<VendorGroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Vendor Groups',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondaryColor,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Discover'),
            Tab(text: 'My Groups'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search groups...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: AppTheme.backgroundColor,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Content
          Expanded(
            child: Consumer<VendorNetworkingProvider>(
              builder: (context, provider, child) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Discover Groups
                    _buildGroupsList(
                      provider.groups.where((group) => !group.memberIds.contains('1')).toList(),
                      isMemberView: false,
                      isLoading: provider.isLoadingGroups,
                    ),

                    // My Groups
                    _buildGroupsList(
                      provider.groups.where((group) => group.memberIds.contains('1')).toList(),
                      isMemberView: true,
                      isLoading: provider.isLoadingGroups,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateGroupDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGroupsList(List groups, {required bool isMemberView, required bool isLoading}) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Filter by search
    final filteredGroups = _searchController.text.isEmpty
        ? groups
        : groups.where((group) {
            final query = _searchController.text.toLowerCase();
            return group.name.toLowerCase().contains(query) ||
                   group.description.toLowerCase().contains(query) ||
                   group.tags.any((tag) => tag.toLowerCase().contains(query));
          }).toList();

    if (filteredGroups.isEmpty) {
      return _buildEmptyState(isMemberView);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredGroups.length,
      itemBuilder: (context, index) {
        final group = filteredGroups[index];
        return GroupCard(
          group: group,
          isMember: isMemberView,
          onTap: () => _showGroupDetails(group, isMemberView),
          onJoinPressed: isMemberView ? null : () => _joinGroup(group),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isMemberView) {
    final title = isMemberView ? 'No groups joined yet' : 'No groups found';
    final subtitle = isMemberView
        ? 'Join groups to connect with other vendors in your area.'
        : 'Be the first to create a group or try adjusting your search.';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isMemberView ? Icons.group_off : Icons.search_off,
            size: 64,
            color: AppTheme.textSecondaryColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (!isMemberView)
            ElevatedButton.icon(
              onPressed: () => _showCreateGroupDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Create Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
        ],
      ),
    );
  }

  void _showGroupDetails(group, bool isMember) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              // Group Header
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _getGroupColor(group.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      _getGroupIcon(group.type),
                      color: _getGroupColor(group.type),
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created by ${group.creatorName}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              const Text(
                'About this Group',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                group.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 20),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.group,
                      label: 'Members',
                      value: group.memberIds.length.toString(),
                    ),
                  ),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.event,
                      label: 'Type',
                      value: group.typeDisplayName,
                    ),
                  ),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.visibility,
                      label: 'Visibility',
                      value: group.visibilityDisplayName,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Tags
              if (group.tags.isNotEmpty) ...[
                const Text(
                  'Tags',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: group.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (isMember) {
                          // Leave group
                          _leaveGroup(group);
                        } else {
                          // Join group
                          _joinGroup(group);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isMember ? AppTheme.errorColor : AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(isMember ? 'Leave Group' : 'Join Group'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({required IconData icon, required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  void _joinGroup(group) async {
    try {
      await context.read<VendorNetworkingProvider>().joinGroup(group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined ${group.name} successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join ${group.name}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _leaveGroup(group) async {
    try {
      await context.read<VendorNetworkingProvider>().leaveGroup(group.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Left ${group.name}'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to leave ${group.name}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showCreateGroupDialog(BuildContext context) {
    // In a real app, this would show a dialog to create a new group
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create group feature coming soon!'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Color _getGroupColor(String type) {
    switch (type) {
      case 'regional':
        return Colors.blue;
      case 'service':
        return Colors.green;
      case 'business':
        return Colors.purple;
      case 'event':
        return Colors.orange;
      case 'custom':
        return AppTheme.primaryColor;
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getGroupIcon(String type) {
    switch (type) {
      case 'regional':
        return Icons.location_on;
      case 'service':
        return Icons.business;
      case 'business':
        return Icons.factory;
      case 'event':
        return Icons.event;
      case 'custom':
        return Icons.group;
      default:
        return Icons.group;
    }
  }
}
