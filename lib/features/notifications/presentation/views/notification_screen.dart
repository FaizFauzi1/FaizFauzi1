import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/notifications/data/providers/notification_provider.dart';
import 'package:eventease/shared/models/notification.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Notifications', style: TextStyle(color: AppTheme.textPrimaryColor)),
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
          bottom: const TabBar(
            isScrollable: true,
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryColor,
            tabs: [
              Tab(text: 'All'),
              Tab(text: 'Bookings'),
              Tab(text: 'Payments'),
              Tab(text: 'Messages'),
              Tab(text: 'System'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all),
              tooltip: 'Mark all as read',
              onPressed: () {
                context.read<NotificationProvider>().markAllAsRead();
              },
            ),
          ],
        ),
        body: Consumer<NotificationProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                _buildNotificationList(context, provider.notifications),
                _buildNotificationList(context, _filterByType(provider.notifications, 'booking')),
                _buildNotificationList(context, _filterByType(provider.notifications, 'payment')),
                _buildNotificationList(context, _filterByType(provider.notifications, 'messages')),
                _buildNotificationList(context, _filterByType(provider.notifications, 'system')),
              ],
            );
          },
        ),
      ),
    );
  }

  List<NotificationModel> _filterByType(List<NotificationModel> notifications, String category) {
    switch (category) {
      case 'booking':
        return notifications.where((n) => 
          n.type == NotificationType.booking ||
          n.type == NotificationType.bookingSubmitted ||
          n.type == NotificationType.vendorConfirmed ||
          n.type == NotificationType.vendorConfirmed ||
          n.type == NotificationType.vendorRejected ||
          n.type == NotificationType.depositReminder ||
          n.type == NotificationType.balanceReminder ||
          n.type == NotificationType.bookingRescheduled ||
          n.type == NotificationType.bookingCancelled ||
          n.type == NotificationType.refundProcessed ||
          n.type == NotificationType.newBookingRequest ||
          n.type == NotificationType.dateChangeRequest ||
          n.type == NotificationType.packageChangeRequest
        ).toList();
      case 'payment':
        return notifications.where((n) => 
          n.type == NotificationType.payment ||
          n.type == NotificationType.paymentReceived ||
          n.type == NotificationType.depositSuccessful ||
          n.type == NotificationType.paymentFailed ||
          n.type == NotificationType.installmentDue ||
          n.type == NotificationType.installmentOverdue ||
          n.type == NotificationType.refundInitiated ||
          n.type == NotificationType.refundCompleted ||
          n.type == NotificationType.invoiceGenerated ||
          n.type == NotificationType.receiptAvailable ||
          n.type == NotificationType.paymentSettlement
        ).toList();
      case 'messages':
        return notifications.where((n) => 
          n.type == NotificationType.message ||
          n.type == NotificationType.chat ||
          n.type == NotificationType.vendorMessage ||
          n.type == NotificationType.newMessage ||
          n.type == NotificationType.missedMessage ||
          n.type == NotificationType.adminSupportReply
        ).toList();
      case 'system':
        return notifications.where((n) => 
          n.type == NotificationType.system ||
          n.type == NotificationType.update ||
          n.type == NotificationType.eventUpdate ||
          n.type == NotificationType.vendorApproval ||
          n.type == NotificationType.vendorRejection ||
          n.type == NotificationType.vendorSuspension ||
          n.type == NotificationType.vendorActivation ||
          n.type == NotificationType.vendorDocumentVerification ||
          n.type == NotificationType.vendorServiceApproval ||
          n.type == NotificationType.vendorPayout ||
          n.type == NotificationType.accountVerified ||
          n.type == NotificationType.documentApproved ||
          n.type == NotificationType.serviceApproved ||
          n.type == NotificationType.subscriptionExpiring ||
          n.type == NotificationType.policyUpdate ||
          n.type == NotificationType.maintenanceDowntime
        ).toList();
      default:
        return notifications;
    }
  }

  Widget _buildNotificationList(BuildContext context, List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return _buildEmptyState();
    }

    final pinned = notifications.where((n) => n.isPinned).toList();
    final others = notifications.where((n) => !n.isPinned).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      children: [
        if (pinned.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.push_pin, size: 16, color: Colors.grey),
                SizedBox(width: 8),
                Text(
                  'PINNED',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          ...pinned.map((n) => _buildNotificationItem(context, n)),
          const Divider(height: 24),
        ],
        ...others.asMap().entries.map((entry) {
          final index = entry.key;
          final n = entry.value;
          return Column(
            children: [
              _buildNotificationItem(context, n),
              if (index < others.length - 1) const Divider(height: 1),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No notifications here',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel notification) {
    final isRead = notification.isRead;
    
    return Container(
      color: isRead ? Colors.transparent : AppTheme.primaryColor.withOpacity(0.05),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getIconColor(notification.type).withOpacity(0.1),
          child: Icon(_getIcon(notification.type), color: _getIconColor(notification.type)),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  _formatTime(notification.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                if (notification.priority != NotificationPriority.normal) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(notification.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      notification.priority.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getPriorityColor(notification.priority),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        onTap: () {
          if (!isRead) {
            context.read<NotificationProvider>().markAsRead(notification.id);
          }
        },
      ),
    );
  }

  IconData _getIcon(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
      case NotificationType.bookingSubmitted:
      case NotificationType.vendorConfirmed:
      case NotificationType.vendorRejected:
      case NotificationType.newBookingRequest:
        return Icons.calendar_today;
      case NotificationType.payment:
      case NotificationType.paymentReceived:
      case NotificationType.depositSuccessful:
      case NotificationType.invoiceGenerated:
        return Icons.payment;
      case NotificationType.chat:
      case NotificationType.message:
      case NotificationType.newMessage:
      case NotificationType.vendorMessage:
        return Icons.chat_bubble_outline;
      case NotificationType.system:
      case NotificationType.update:
      case NotificationType.policyUpdate:
      case NotificationType.serviceApproved:
      case NotificationType.serviceRejected:
        return Icons.info_outline;
      case NotificationType.review:
      case NotificationType.reviewReceived:
      case NotificationType.vendorRatingRequest:
        return Icons.star_border;
      case NotificationType.reminder:
      case NotificationType.depositReminder:
      case NotificationType.balanceReminder:
      case NotificationType.eventReminder1d:
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconColor(NotificationType type) {
    if (type.toString().contains('booking')) return Colors.orange;
    if (type.toString().contains('payment')) return Colors.green;
    if (type.toString().contains('chat') || type.toString().contains('message')) return Colors.blue;
    if (type.toString().contains('review')) return Colors.amber;
    if (type.toString().contains('reminder')) return Colors.deepOrange;
    return AppTheme.primaryColor;
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low: return Colors.grey;
      case NotificationPriority.normal: return Colors.blue;
      case NotificationPriority.high: return Colors.orange;
      case NotificationPriority.urgent: return Colors.red;
    }
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
