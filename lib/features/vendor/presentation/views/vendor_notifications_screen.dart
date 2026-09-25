import 'package:eventease/core/services/notification_service.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/shared/models/notification.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';

class VendorNotificationsScreen extends StatefulWidget {
  const VendorNotificationsScreen({super.key});

  @override
  State<VendorNotificationsScreen> createState() =>
      _VendorNotificationsScreenState();
}

class _VendorNotificationsScreenState extends State<VendorNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  final Set<String> _selectedIds = {}; // Using IDs for selection

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final userId = AdminImpersonationService.instance.effectiveUserId;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final notifications = await _notificationService.getNotifications(userId);
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading notifications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Group notifications by date
  Map<String, List<NotificationModel>> _groupByDate() {
    Map<String, List<NotificationModel>> grouped = {};
    for (var n in _notifications) {
      String key;
      final now = DateTime.now();
      final date = n.createdAt;

      if (date.day == now.day &&
          date.month == now.month &&
          date.year == now.year) {
        key = "Today";
      } else if (now.difference(date).inDays == 1 && date.day != now.day) {
        key = "Yesterday";
      } else {
        key = DateFormat('dd/MM/yyyy').format(date);
      }

      grouped.putIfAbsent(key, () => []);
      grouped[key]!.add(n);
    }
    return grouped;
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.newBookingRequest:
      case NotificationType.bookingSubmitted:
      case NotificationType.vendorConfirmed:
        return Colors.blueAccent;
      case NotificationType.paymentReceived:
        return Colors.green;
      case NotificationType.systemUpdate:
      case NotificationType.vendorServiceApproval:
        return Colors.orange;
      case NotificationType.bookingCancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByDate();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: _selectedIds.isEmpty
            ? const Text(
                'Notifications',
                style: TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold),
              )
            : Text(
                '${_selectedIds.length} selected',
                style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold),
              ),
        actions: [
           IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadNotifications();
            },
          ),
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all, color: AppTheme.primaryColor),
              onPressed: () async {
                 // Mark selected as read
                 for (var id in _selectedIds) {
                   await _notificationService.markAsRead(id);
                 }
                 await _loadNotifications();
                 setState(() {
                   _selectedIds.clear();
                 });
              },
            ),
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: AppTheme.errorColor),
              onPressed: () async {
                // Delete selected
                 for (var id in _selectedIds) {
                   await _notificationService.deleteNotification(id);
                 }
                 await _loadNotifications();
                 setState(() {
                   _selectedIds.clear();
                 });
              },
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _notifications.isEmpty
          ? const Center(
              child: Text("No notifications yet",
                  style: TextStyle(color: AppTheme.textSecondaryColor)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Priority/Pinned (High Priority)
                if (_notifications.any((n) => n.priority == NotificationPriority.high || n.priority == NotificationPriority.urgent))
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Priority",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimaryColor)),
                      ..._notifications
                          .where((n) => n.priority == NotificationPriority.high || n.priority == NotificationPriority.urgent)
                          .map((n) => _buildNotificationCard(n)),
                      const SizedBox(height: 10),
                    ],
                  ),
                // Grouped Notifications
                ...grouped.entries.map((entry) {
                   // Filter out priority ones if we want to show them separately, or just show all grouped
                   // For now showing all in groups as well or just standard
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.key,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textSecondaryColor)),
                      const SizedBox(height: 6),
                      ...entry.value.map((n) {
                        return Dismissible(
                          key: Key(n.id),
                          background: Container(
                            color: Colors.green,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            child: const Icon(Icons.done, color: Colors.white),
                          ),
                          secondaryBackground: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) async {
                             if (direction == DismissDirection.startToEnd) {
                                await _notificationService.markAsRead(n.id);
                                setState(() {
                                  final index = _notifications.indexWhere((notif) => notif.id == n.id);
                                  if (index != -1) {
                                    _notifications[index] = _notifications[index].copyWith(isRead: true);
                                  }
                                });
                             } else {
                                await _notificationService.deleteNotification(n.id);
                                setState(() {
                                  _notifications.remove(n);
                                });
                             }
                          },
                          child: _buildNotificationCard(n),
                        );
                      }).toList(),
                      const SizedBox(height: 12),
                    ],
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildNotificationCard(NotificationModel n) {
    final isSelected = _selectedIds.contains(n.id);

    return GestureDetector(
      onLongPress: () {
        setState(() {
          if (isSelected) {
            _selectedIds.remove(n.id);
          } else {
            _selectedIds.add(n.id);
          }
        });
      },
      onTap: () {
        if (_selectedIds.isNotEmpty) {
          setState(() {
            if (isSelected) {
              _selectedIds.remove(n.id);
            } else {
              _selectedIds.add(n.id);
            }
          });
        } else {
          // Navigation logic based on type
           if (!n.isRead) {
             _notificationService.markAsRead(n.id);
             setState(() {
               final index = _notifications.indexWhere((notif) => notif.id == n.id);
               if (index != -1) {
                 _notifications[index] = _notifications[index].copyWith(isRead: true);
               }
             });
           }
           // TODO: Add specific navigation logic here
        }
      },
      child: Card(
        color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: _getTypeColor(n.type).withOpacity(0.2),
                child: Icon(
                  _getIconForType(n.type),
                  color: _getTypeColor(n.type),
                ),
              ),
              if (!n.isRead)
                const Positioned(
                  right: 0,
                  top: 0,
                  child: CircleAvatar(radius: 6, backgroundColor: Colors.red),
                ),
            ],
          ),
          title: Text(n.title,
              style: TextStyle(
                  fontWeight: !n.isRead ? FontWeight.bold : FontWeight.normal)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.message),
              // Optional action buttons could go here
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.newBookingRequest:
      case NotificationType.bookingSubmitted:
        return Icons.event;
      case NotificationType.paymentReceived:
        return Icons.attach_money;
      case NotificationType.systemUpdate:
        return Icons.system_update;
      default:
        return Icons.notifications;
    }
  }
}
