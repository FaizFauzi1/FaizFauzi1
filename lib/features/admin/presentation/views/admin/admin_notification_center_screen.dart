import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/admin/data/providers/admin_notification_provider.dart';
import 'package:eventease/shared/models/admin_notification.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class AdminNotificationCenterScreen extends StatefulWidget {
  const AdminNotificationCenterScreen({super.key});

  @override
  State<AdminNotificationCenterScreen> createState() => _AdminNotificationCenterScreenState();
}

class _AdminNotificationCenterScreenState extends State<AdminNotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminNotificationProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Admin Control Tower', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.blueGrey.shade900,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => context.read<AdminNotificationProvider>().loadNotifications(),
            ),
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              onPressed: () => context.read<AdminNotificationProvider>().markAllAsRead(),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.cyanAccent,
            tabs: [
              Tab(text: 'All'),
              Tab(text: '🔴 Critical'),
              Tab(text: '🟠 Operations'),
              Tab(text: '🔵 Onboarding'),
              Tab(text: '🟢 System'),
              Tab(text: '🟣 Business'),
            ],
          ),
        ),
        body: Consumer<AdminNotificationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) return const Center(child: CircularProgressIndicator());
            
            return TabBarView(
              children: [
                _buildNotificationList(provider.notifications),
                _buildNotificationList(provider.criticalNotifications),
                _buildNotificationList(provider.operationNotifications),
                _buildNotificationList(provider.onboardingNotifications),
                _buildNotificationList(provider.systemNotifications),
                _buildNotificationList(provider.businessNotifications),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationList(List<AdminNotificationModel> notifications) {
    if (notifications.isEmpty) {
      return const Center(child: Text("No alerts in this category", style: TextStyle(color: Colors.grey)));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: notifications.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final n = notifications[index];
        return _buildAdminNotificationCard(context, n);
      },
    );
  }

  Widget _buildAdminNotificationCard(BuildContext context, AdminNotificationModel n) {
    final severityColor = _getSeverityColor(n.severity);
    final isUnread = n.status == AdminNotificationStatus.unread;

    return Card(
      elevation: isUnread ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUnread ? BorderSide(color: severityColor, width: 1.5) : BorderSide.none,
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: severityColor.withOpacity(0.1),
          child: Icon(_getTypeIcon(n.type), color: severityColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                n.title,
                style: TextStyle(
                  fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                  color: isUnread ? Colors.black87 : Colors.black54,
                ),
              ),
            ),
            _getSeverityBadge(n.severity),
          ],
        ),
        subtitle: Text(
          DateFormat('dd MMM, hh:mm a').format(n.createdAt),
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.message, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (n.status != AdminNotificationStatus.resolved)
                      TextButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Resolve"),
                        onPressed: () => context.read<AdminNotificationProvider>().updateNotificationStatus(n.id, AdminNotificationStatus.resolved),
                      ),
                    if (n.status == AdminNotificationStatus.unread)
                      TextButton.icon(
                        icon: const Icon(Icons.mark_email_read_outlined),
                        label: const Text("Mark Read"),
                        onPressed: () => context.read<AdminNotificationProvider>().updateNotificationStatus(n.id, AdminNotificationStatus.read),
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                      onPressed: () {
                        // Action logic
                      },
                      child: const Text("Take Action"),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Color _getSeverityColor(AdminNotificationSeverity severity) {
    switch (severity) {
      case AdminNotificationSeverity.low: return Colors.blue;
      case AdminNotificationSeverity.medium: return Colors.orange;
      case AdminNotificationSeverity.high: return Colors.deepOrange;
      case AdminNotificationSeverity.critical: return Colors.red;
    }
  }

  Widget _getSeverityBadge(AdminNotificationSeverity severity) {
    final color = _getSeverityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        severity.toString().split('.').last.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  IconData _getTypeIcon(AdminNotificationType type) {
    switch (type) {
      case AdminNotificationType.booking: return Icons.calendar_today;
      case AdminNotificationType.payment: return Icons.payments;
      case AdminNotificationType.vendor: return Icons.storefront;
      case AdminNotificationType.system: return Icons.settings_applications;
      case AdminNotificationType.support: return Icons.support_agent;
      case AdminNotificationType.onboarding: return Icons.person_add_alt_1;
      case AdminNotificationType.risk: return Icons.security;
      case AdminNotificationType.health: return Icons.monitor_heart;
      case AdminNotificationType.business: return Icons.trending_up;
    }
  }
}
