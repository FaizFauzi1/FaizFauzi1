import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/notifications/data/providers/notification_provider.dart';
import 'package:eventease/shared/models/notification.dart';
import 'package:eventease/shared/widgets/notification_item.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    final authProvider = context.read<AuthProvider>();
    _userId = authProvider.isAuthenticated ? authProvider.userId : null;

    if (_userId != null) {
      // Trigger a load for the correct user ID
      context.read<NotificationProvider>().loadNotifications(_userId!);
    }
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
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Archived'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
          IconButton(
            icon: const Icon(Icons.add_alert, color: Colors.orange),
            tooltip: 'DEBUG: Add Test Notification',
            onPressed: () async {
              if (_userId != null) {
                await context.read<NotificationProvider>().createNotification(
                  userId: _userId!,
                  title: 'Test Notification',
                  message: 'This is a manual test notification at ${DateTime.now()}',
                  type: NotificationType.system,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification created')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.done_all),
            onPressed: _markAllAsRead,
          ),
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, child) {
          if (notificationProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildNotificationList(notificationProvider.notifications),
              _buildNotificationList(notificationProvider.getUnreadNotifications()),
              _buildNotificationList(notificationProvider.notifications
                  .where((n) => n.isArchived)
                  .toList()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNotificationList(List<NotificationModel> notifications) {
    debugPrint('FCM UI: Building list with ${notifications.length} items');
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_userId != null) {
          await context.read<NotificationProvider>().loadNotifications(_userId!);
        }
      },
      child: ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationItem(
            notification: notification,
            onTap: () => _onNotificationTap(notification),
            onDismiss: () => _onNotificationDismiss(notification),
          );
        },
      ),
    );
  }

  void _onNotificationTap(NotificationModel notification) async {
    // Mark as read if not already read
    if (!notification.isRead && _userId != null) {
      await context.read<NotificationProvider>().markAsRead(_userId!, notification.id);
    }

    // Handle action URL or navigate based on notification type
    if (notification.actionUrl != null) {
      // Navigate to the action URL or specific screen
      _handleNotificationAction(notification);
    } else {
      // Show notification details dialog
      _showNotificationDetails(notification);
    }
  }

  void _onNotificationDismiss(NotificationModel notification) async {
    if (_userId != null) {
      await context.read<NotificationProvider>().deleteNotification(_userId!, notification.id);
    }
  }

  void _handleNotificationAction(NotificationModel notification) {
    // Handle different notification types
    switch (notification.type) {
      case NotificationType.booking:
        // Navigate to booking details
        Navigator.of(context).pushNamed('/booking-details', arguments: notification.data);
        break;
      case NotificationType.message:
        // Navigate to chat
        Navigator.of(context).pushNamed('/chat', arguments: notification.data);
        break;
      case NotificationType.chat:
        // Navigate to chat with conversation details
        Navigator.of(context).pushNamed('/chat', arguments: notification.data);
        break;
      case NotificationType.payment:
        // Navigate to payment details
        Navigator.of(context).pushNamed('/payment-details', arguments: notification.data);
        break;
      default:
        // Show details dialog for other types
        _showNotificationDetails(notification);
    }
  }

  void _showNotificationDetails(NotificationModel notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(notification.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.message),
            const SizedBox(height: 16),
            Text(
              'Type: ${_getTypeLabel(notification.type)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            Text(
              'Priority: ${_getPriorityLabel(notification.priority)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            Text(
              'Time: ${_formatDateTime(notification.createdAt)}',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _markAllAsRead() async {
    if (_userId != null) {
      await context.read<NotificationProvider>().markAllAsRead(_userId!);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    }
  }

  void _showSettingsDialog() {
    final notificationProvider = context.read<NotificationProvider>();
    final currentSettings = notificationProvider.settings;

    if (currentSettings == null) return;

    // Create mutable copies of settings
    bool pushEnabled = currentSettings.pushEnabled;
    bool emailEnabled = currentSettings.emailEnabled;
    bool smsEnabled = currentSettings.smsEnabled;
    Set<NotificationType> enabledTypes = Set.from(currentSettings.enabledTypes);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Notification Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Push Notifications'),
                  value: pushEnabled,
                  onChanged: (value) {
                    setState(() => pushEnabled = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Email Notifications'),
                  value: emailEnabled,
                  onChanged: (value) {
                    setState(() => emailEnabled = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('SMS Notifications'),
                  value: smsEnabled,
                  onChanged: (value) {
                    setState(() => smsEnabled = value);
                  },
                ),
                const Divider(),
                const Text('Notification Types:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...NotificationType.values.map((type) => CheckboxListTile(
                  title: Text(_getTypeLabel(type)),
                  value: enabledTypes.contains(type),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        enabledTypes.add(type);
                      } else {
                        enabledTypes.remove(type);
                      }
                    });
                  },
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_userId != null) {
                  final newSettings = NotificationSettings(
                    pushEnabled: pushEnabled,
                    emailEnabled: emailEnabled,
                    smsEnabled: smsEnabled,
                    enabledTypes: enabledTypes,
                    typePriorities: currentSettings.typePriorities,
                    quietHoursEnabled: currentSettings.quietHoursEnabled,
                    quietStartTime: currentSettings.quietStartTime,
                    quietEndTime: currentSettings.quietEndTime,
                    workingDays: currentSettings.workingDays,
                  );
                  await notificationProvider.updateSettings(_userId!, newSettings);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Settings saved')),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeLabel(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return 'Booking';
      case NotificationType.reminder:
        return 'Reminder';
      case NotificationType.promotion:
        return 'Promotion';
      case NotificationType.system:
        return 'System';
      case NotificationType.message:
        return 'Message';
      case NotificationType.payment:
        return 'Payment';
      case NotificationType.review:
        return 'Review';
      case NotificationType.update:
        return 'Update';
      case NotificationType.eventUpdate:
        return 'Event Update';
      case NotificationType.vendorApproval:
        return 'Vendor Approval';
      case NotificationType.vendorRejection:
        return 'Vendor Rejection';
      case NotificationType.vendorSuspension:
        return 'Vendor Suspension';
      case NotificationType.vendorActivation:
        return 'Vendor Activation';
      case NotificationType.vendorMessage:
        return 'Vendor Message';
      case NotificationType.vendorDocumentVerification:
        return 'Document Verification';
      case NotificationType.vendorServiceApproval:
        return 'Service Approval';
      case NotificationType.vendorPayout:
        return 'Vendor Payout';
      case NotificationType.chat:
        return 'Chat';
      default:
        return 'Notification';
    }
  }

  String _getPriorityLabel(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.urgent:
        return 'Urgent';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
