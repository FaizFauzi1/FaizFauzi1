import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_profile_provider.dart';
import 'package:eventease/features/vendor/data/providers/vendor_networking_provider.dart';
import 'package:eventease/shared/models/vendor_collaboration_request_fixed.dart';

class VendorNetworkingScreen extends StatefulWidget {
  const VendorNetworkingScreen({super.key});

  @override
  State<VendorNetworkingScreen> createState() => _VendorNetworkingScreenState();
}

class _VendorNetworkingScreenState extends State<VendorNetworkingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<VendorProfileProvider>(context, listen: false);
      final networkingProvider = Provider.of<VendorNetworkingProvider>(context, listen: false);

      final currentId = profileProvider.vendorProfile?['id'] ?? auth.userId ?? '';
      if (currentId.isNotEmpty) {
        networkingProvider.setCurrentVendor(currentId);
      }
      networkingProvider.loadDiscoveryVendors();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Collaboration Hub'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          isScrollable: true,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Partnerships & History', icon: Icon(Icons.handshake)),
            Tab(text: 'Requests', icon: Icon(Icons.send)),
            Tab(text: 'Portfolio Tags', icon: Icon(Icons.style)),
            Tab(text: 'Vendor Referrals', icon: Icon(Icons.share)),
            Tab(text: 'Co-Branding Groups', icon: Icon(Icons.group)),
          ],
        ),
      ),
      body: Consumer<VendorNetworkingProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildPartnershipsTab(provider),
              _buildRequestsTab(provider),
              _buildPortfolioTagsTab(),
              _buildReferralsTab(provider),
              _buildGroupsTab(provider),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNetworkingOptions(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRequestsTab(VendorNetworkingProvider provider) {
    final sentRequests = provider.sentRequests;
    final receivedRequests = provider.receivedRequests;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Sent Requests (${sentRequests.length})'),
        ...sentRequests.map((request) => _buildRequestCard(request, true)),
        const SizedBox(height: 20),
        _buildSectionHeader('Received Requests (${receivedRequests.length})'),
        ...receivedRequests.map((request) => _buildRequestCard(request, false)),
      ],
    );
  }

  Widget _buildPartnershipsTab(VendorNetworkingProvider provider) {
    final partnerships = provider.myPartnerships;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Active Partnerships & Joint History (${partnerships.length})'),
        ...partnerships.map(_buildPartnershipCard),
        if (partnerships.isEmpty)
          _buildEmptyState(
            icon: Icons.handshake_outlined,
            title: 'No Partnerships Yet',
            subtitle: 'Connect with other vendors to share leads, co-brand events, and grow together.',
            actionLabel: 'Find Partners',
            onAction: () => Navigator.pushNamed(context, '/find-partners'),
          ),
      ],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPortfolioTagsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Cross-Tagged Event Portfolios'),
        const Text(
          'Tag collaborating vendors in your photo galleries to receive cross-discovery & co-promotion traffic.',
          style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
        ),
        const SizedBox(height: 8),
        _buildEmptyState(
          icon: Icons.style_outlined,
          title: 'No Tagged Albums Yet',
          subtitle: 'Upload event albums and tag the vendors you collaborated with to boost cross-discovery traffic.',
          actionLabel: 'Upload Album',
          onAction: () => Navigator.pushNamed(context, '/vendor-portfolio'),
        ),
      ],
    );
  }



  Widget _buildGroupsTab(VendorNetworkingProvider provider) {
    final groups = provider.myGroups;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('My Groups (${groups.length})'),
        ...groups.map(_buildGroupCard),
        if (groups.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('Not a member of any groups yet'),
            ),
          ),
      ],
    );
  }

  Widget _buildReferralsTab(VendorNetworkingProvider provider) {
    final sentReferrals = provider.sentReferrals;
    final receivedReferrals = provider.receivedReferrals;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Sent Referrals (${sentReferrals.length})'),
        ...sentReferrals.map((referral) => _buildReferralCard(referral, true)),
        const SizedBox(height: 20),
        _buildSectionHeader('Received Referrals (${receivedReferrals.length})'),
        ...receivedReferrals.map((referral) => _buildReferralCard(referral, false)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
        ),
      ),
    );
  }

  Widget _buildRequestCard(dynamic request, bool isSent) {
    final isPending = (request is VendorCollaborationRequest)
        ? request.isPending
        : request.status.toString().toLowerCase().contains('pending');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: _getStatusColor(request.status),
                child: Icon(
                  isSent ? Icons.send : Icons.inbox,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text(
                isSent ? request.receiverVendorName : request.senderVendorName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  Text(
                    'Type: ${request.type is CollaborationType ? (request as VendorCollaborationRequest).typeDisplayName : request.type}',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Status: ${_getStatusText(request.status)}',
                    style: TextStyle(
                      color: _getStatusColor(request.status),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: Text(
                _formatDate(request.createdAt),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            if (request.message.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  request.message,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                ),
              ),
            ],
            if (!isSent && isPending) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      final provider = context.read<VendorNetworkingProvider>();
                      provider.respondToCollaborationRequest(
                        request.id,
                        CollaborationRequestStatus.rejected,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Request declined')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final provider = context.read<VendorNetworkingProvider>();
                      provider.respondToCollaborationRequest(
                        request.id,
                        CollaborationRequestStatus.accepted,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Collaboration accepted! Partnership created.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    child: const Text('Accept & Partner'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPartnershipCard(dynamic partnership) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.handshake, color: Colors.white),
        ),
        title: Text(partnership.partnershipName),
        subtitle: Text('${partnership.vendorNames.join(', ')}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: partnership.isActive ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            partnership.isActive ? 'Active' : 'Inactive',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(dynamic group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.group, color: Colors.white),
        ),
        title: Text(group.name),
        subtitle: Text('${group.memberIds.length} members'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: group.visibility == 'public' ? Colors.green : Colors.orange,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            group.visibility,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildReferralCard(dynamic referral, bool isSent) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getReferralStatusColor(referral.status),
          child: Icon(
            isSent ? Icons.share : Icons.call_received,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(referral.customerName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Value: RM ${referral.estimatedValue.toStringAsFixed(0)}'),
            Text(
              'Status: ${_getReferralStatusText(referral.status)}',
              style: TextStyle(
                color: _getReferralStatusColor(referral.status),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: referral.commissionEarned != null
            ? Text(
                '+RM ${referral.commissionEarned!.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final statusStr = (status is CollaborationRequestStatus)
        ? status.toString().split('.').last
        : status.toString();
    switch (statusStr.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(dynamic status) {
    final statusStr = (status is CollaborationRequestStatus)
        ? status.toString().split('.').last
        : status.toString();
    if (statusStr.isEmpty) return '';
    return statusStr[0].toUpperCase() + statusStr.substring(1);
  }

  Color _getReferralStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getReferralStatusText(String status) {
    return status[0].toUpperCase() + status.substring(1);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showNetworkingOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Networking Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Find Partners'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/find-partners');
              },
            ),
            ListTile(
              leading: const Icon(Icons.send),
              title: const Text('Collaboration Requests'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/collaboration-requests');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_work),
              title: const Text('Package Builder'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/package-builder');
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Groups'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/vendor-groups');
              },
            ),
            ListTile(
              leading: const Icon(Icons.store),
              title: const Text('Marketplace'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/marketplace');
              },
            ),
          ],
        ),
      ),
    );
  }
}
