import 'package:eventease/core/services/admin_notification_service.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/models/admin_notification.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final AdminNotificationService _adminNotificationService = AdminNotificationService();
  List<AdminNotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications = await _adminNotificationService.getAdminNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading admin notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsRead(AdminNotificationModel notification) async {
    if (notification.status == AdminNotificationStatus.read) return;

    try {
      await _adminNotificationService.markAsRead(notification.id);
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(status: AdminNotificationStatus.read);
        }
      });
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Admin Notifications',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.textPrimaryColor),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadNotifications();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AdminNotificationModel>>(
        stream: _adminNotificationService.adminNotificationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off_outlined, size: 64, color: AppTheme.textSecondaryColor),
                  const SizedBox(height: 16),
                  Text(
                    'No admin alerts',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _buildNotificationCard(notification);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(AdminNotificationModel notification) {
    IconData icon;
    Color iconColor;
    final bool isRead = notification.status == AdminNotificationStatus.read;

    switch (notification.type) {
      case AdminNotificationType.support:
        icon = Icons.support_agent;
        iconColor = Colors.red;
        break;
      case AdminNotificationType.booking:
        icon = Icons.event_available_rounded;
        iconColor = Colors.blue;
        break;
      case AdminNotificationType.payment:
        icon = Icons.payments_outlined;
        iconColor = Colors.green;
        break;
      case AdminNotificationType.vendor:
        icon = Icons.storefront;
        iconColor = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AppTheme.primaryColor;
    }

    if (isRead) {
      iconColor = AppTheme.textSecondaryColor;
    }

    return Card(
      elevation: isRead ? 1 : 4,
      color: isRead ? AppTheme.cardColor : AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: !isRead && notification.severity == AdminNotificationSeverity.critical
            ? const BorderSide(color: Colors.red, width: 2)
            : BorderSide.none,
      ),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: isRead ? AppTheme.textSecondaryColor : AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
              ),
            ),
             const SizedBox(height: 6),
            Text(
              DateFormat('MMM d, h:mm a').format(notification.createdAt),
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondaryColor.withOpacity(0.7),
              ),
            ),
          ],
        ),
        trailing: isRead
            ? null
            : const Icon(Icons.circle, color: AppTheme.primaryColor, size: 10),
        onTap: () => _markAsRead(notification),
      ),
    );
  }
}
