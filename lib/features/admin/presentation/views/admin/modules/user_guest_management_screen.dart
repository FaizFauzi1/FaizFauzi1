import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class UserGuestManagementScreen extends StatefulWidget {
  const UserGuestManagementScreen({super.key});

  @override
  State<UserGuestManagementScreen> createState() => _UserGuestManagementScreenState();
}

class _UserGuestManagementScreenState extends State<UserGuestManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _filterRole = 'All';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('User & Guest Management'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Builder(
            builder: (context) {
              final admin = Provider.of<AdminProvider>(context);
              return IconButton(
                icon: admin.isLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: admin.isLoading
                    ? null
                    : () async {
                        await admin.refreshAllData();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('User data refreshed')),
                        );
                      },
                tooltip: 'Refresh Users',
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'All Users'),
            Tab(text: 'Guests'),
            Tab(text: 'Reported'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search users by name, email, or role...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Filter Row
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                            value: _filterRole,
                            items: ['All', 'admin', 'vendor', 'bride', 'groom', 'planner', 'guest', 'customer']
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role.toUpperCase()),
                                    ))
                                .toList(),
                        onChanged: (value) {
                          setState(() {
                            _filterRole = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: _filterStatus,
                        items: ['All', 'active', 'banned', 'suspended']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status.toUpperCase()),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _filterStatus = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAllUsersTab(admin.users, admin),
                _buildGuestsTab(admin.guestInvitations, admin),
                _buildReportedTab(admin.reportedUsers, admin),
                _buildAnalyticsTab(admin),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllUsersTab(List<AppUser> users, AdminProvider admin) {
    final filteredUsers = _filterUsers(users);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user, admin);
      },
    );
  }

  Widget _buildGuestsTab(List<Invitation> invitations, AdminProvider admin) {
    return Column(
      children: [
        // Guest Management Actions
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showAddGuestDialog(admin),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Add Guest'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _importGuestList(),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Import List'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Guest Invitations List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: invitations.length,
            itemBuilder: (context, index) {
              final invitation = invitations[index];
              return _buildGuestCard(invitation, admin);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReportedTab(List<ReportedUser> reportedUsers, AdminProvider admin) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: reportedUsers.length,
      itemBuilder: (context, index) {
        final reportedUser = reportedUsers[index];
        return _buildReportedUserCard(reportedUser, admin);
      },
    );
  }

  Widget _buildAnalyticsTab(AdminProvider admin) {
    final users = admin.users;
    final roleCounts = <String, int>{};
    final statusCounts = <String, int>{};

    for (final user in users) {
      roleCounts[user.role] = (roleCounts[user.role] ?? 0) + 1;
      statusCounts[user.status] = (statusCounts[user.status] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Statistics
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Total Users',
                  '${users.length}',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Active Users',
                  '${statusCounts['active'] ?? 0}',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  'Banned Users',
                  '${statusCounts['banned'] ?? 0}',
                  Icons.block,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAnalyticsCard(
                  'Guest Invitations',
                  '${admin.guestInvitations.length}',
                  Icons.mail,
                  Colors.orange,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Role Distribution Chart
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Users by Role',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...roleCounts.entries.map((entry) => _buildRoleBar(entry.key, entry.value, users.length)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Recent Activity
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent User Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...users.take(5).map((user) => _buildActivityItem(user)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppUser user, AdminProvider admin) {
    Color statusColor;
    IconData statusIcon;
    
    switch (user.status) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'banned':
        statusColor = Colors.red;
        statusIcon = Icons.block;
        break;
      case 'suspended':
        statusColor = Colors.orange;
        statusIcon = Icons.pause_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(
            _getRoleIcon(user.role),
            color: AppTheme.primaryColor,
          ),
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Text('Role: ${user.role.toUpperCase()} • Status: ${user.status.toUpperCase()}'),
          ],
        ),
        isThreeLine: true,
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Text('View Profile'),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit User'),
            ),
            if (user.status == 'active')
              const PopupMenuItem(
                value: 'ban',
                child: Text('Ban User'),
              )
            else
              const PopupMenuItem(
                value: 'activate',
                child: Text('Activate User'),
              ),
            const PopupMenuItem(
              value: 'reset',
              child: Text('Reset Password'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showUserProfile(user);
                break;
              case 'edit':
                _showEditUserDialog(user, admin);
                break;
              case 'ban':
                _showBanUserDialog(user.id, user.name, admin);
                break;
              case 'activate':
                admin.activateUser(user.id);
                break;
              case 'reset':
                _showResetPasswordDialog(user);
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildGuestCard(Invitation invitation, AdminProvider admin) {
    Color statusColor;
    IconData statusIcon;
    
    switch (invitation.status) {
      case 'in-progress':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'imported':
        statusColor = Colors.blue;
        statusIcon = Icons.file_upload;
        break;
      case 'confirmed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor),
        ),
        title: Text(invitation.name),
        subtitle: Text('Status: ${invitation.status}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Text('View Details'),
            ),
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'view':
                _showGuestDetails(invitation);
                break;
              case 'edit':
                _showEditGuestDialog(invitation);
                break;
              case 'delete':
                _showDeleteGuestDialog(invitation);
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildReportedUserCard(ReportedUser reportedUser, AdminProvider admin) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.red[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.1),
          child: const Icon(Icons.report, color: Colors.red),
        ),
        title: Text(reportedUser.user),
        subtitle: Text('Reason: ${reportedUser.reason}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => _showReportDetails(reportedUser),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Review'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _banReportedUser(reportedUser.user, admin),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ban'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleBar(String role, int count, int total) {
    final percentage = (count / total * 100).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                role.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('$count ($percentage%)'),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: count / total,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(AppUser user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Icon(
          _getRoleIcon(user.role),
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(user.name),
      subtitle: Text('${user.role.toUpperCase()} • Last active: Today'),
      trailing: Icon(
        user.status == 'active' ? Icons.check_circle : Icons.block,
        color: user.status == 'active' ? Colors.green : Colors.red,
      ),
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'vendor':
        return Icons.storefront;
      case 'bride':
        return Icons.favorite;
      case 'groom':
        return Icons.person;
      case 'planner':
        return Icons.event_note;
      case 'guest':
        return Icons.people;
      default:
        return Icons.person;
    }
  }

  List<AppUser> _filterUsers(List<AppUser> users) {
    return users.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          user.email.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesRole = _filterRole == 'All' || user.role == _filterRole;
      
      final matchesStatus = _filterStatus == 'All' || user.status == _filterStatus;
      
      return matchesSearch && matchesRole && matchesStatus;
    }).toList();
  }

  void _showUserProfile(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${user.name} Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${user.email}'),
            Text('Role: ${user.role.toUpperCase()}'),
            Text('Status: ${user.status.toUpperCase()}'),
            Text('ID: ${user.id}'),
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

  void _showEditUserDialog(AppUser user, AdminProvider admin) {
    // TODO: Implement edit user dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit user functionality coming soon...')),
    );
  }

  void _showResetPasswordDialog(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Password'),
        content: Text('Send password reset email to ${user.email}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement password reset
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password reset email sent!')),
              );
            },
            child: const Text('Send Reset'),
          ),
        ],
      ),
    );
  }

  void _showAddGuestDialog(AdminProvider admin) {
    // TODO: Implement add guest dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add guest functionality coming soon...')),
    );
  }

  void _importGuestList() {
    // TODO: Implement guest list import
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Import functionality coming soon...')),
    );
  }

  void _showGuestDetails(Invitation invitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Guest: ${invitation.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status: ${invitation.status}'),
            // Add more guest details here
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

  void _showEditGuestDialog(Invitation invitation) {
    // TODO: Implement edit guest dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit guest functionality coming soon...')),
    );
  }

  void _showDeleteGuestDialog(Invitation invitation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Guest'),
        content: Text('Are you sure you want to delete ${invitation.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Implement delete guest
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guest deleted!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showReportDetails(ReportedUser reportedUser) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${reportedUser.user}'),
            Text('Reason: ${reportedUser.reason}'),
            const SizedBox(height: 16),
            const Text('Additional actions:'),
            const SizedBox(height: 8),
            const Text('• Review user activity'),
            const Text('• Check for similar reports'),
            const Text('• Contact user for clarification'),
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

  void _banReportedUser(String username, AdminProvider admin) {
    // Find user by username and ban them
    try {
      final user = admin.users.firstWhere((u) => u.name == username);
      _showBanUserDialog(user.id, user.name, admin);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User $username not found')),
      );
    }
  }

  void _showBanUserDialog(String userId, String userName, AdminProvider admin) {
    final reasonController = TextEditingController();
    String banType = 'permanent';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Ban User: $userName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for ban',
                  hintText: 'e.g. Inappropriate behavior',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: banType,
                decoration: const InputDecoration(labelText: 'Ban Type'),
                items: const [
                  DropdownMenuItem(value: 'permanent', child: Text('Permanent')),
                  DropdownMenuItem(value: 'temporary', child: Text('Temporary')),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => banType = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final reason = reasonController.text.trim();
                admin.banUser(
                  userId,
                  reason: reason.isNotEmpty ? reason : 'Violated platform policies',
                  banType: banType,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$userName has been banned')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Ban User'),
            ),
          ],
        ),
      ),
    );
  }
}



