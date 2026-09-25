import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:eventease/shared/models/notification.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationItem({
    Key? key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        onDismiss?.call();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: notification.isRead ? Colors.grey.shade200 : Colors.blue.shade200,
            width: 1.0,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16.0),
          leading: CircleAvatar(
            backgroundColor: _getTypeColor(notification.type),
            child: Icon(
              _getTypeIcon(notification.type),
              color: Colors.white,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  notification.title,
                  style: TextStyle(
                    fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                    fontSize: 16.0,
                  ),
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4.0),
              Text(
                notification.message,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14.0,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8.0),
              Row(
                children: [
                  Icon(
                    _getPriorityIcon(notification.priority),
                    size: 14.0,
                    color: _getPriorityColor(notification.priority),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12.0,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                    decoration: BoxDecoration(
                      color: _getTypeColor(notification.type).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      _getTypeLabel(notification.type),
                      style: TextStyle(
                        color: _getTypeColor(notification.type),
                        fontSize: 10.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          onTap: onTap,
          trailing: notification.actionUrl != null
              ? IconButton(
                  icon: const Icon(Icons.arrow_forward_ios, size: 16.0),
                  onPressed: onTap,
                )
              : null,
        ),
      ),
    );
  }

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Colors.green;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.promotion:
        return Colors.purple;
      case NotificationType.system:
        return Colors.blue;
      case NotificationType.message:
        return Colors.teal;
      case NotificationType.payment:
        return Colors.red;
      case NotificationType.review:
        return Colors.amber;
      case NotificationType.update:
        return Colors.indigo;
      case NotificationType.eventUpdate:
        return Colors.cyan;
      case NotificationType.vendorApproval:
        return Colors.green;
      case NotificationType.vendorRejection:
        return Colors.red;
      case NotificationType.vendorSuspension:
        return Colors.orange;
      case NotificationType.vendorActivation:
        return Colors.blue;
      case NotificationType.vendorMessage:
        return Colors.teal;
      case NotificationType.vendorDocumentVerification:
        return Colors.purple;
      case NotificationType.vendorServiceApproval:
        return Colors.green;
      case NotificationType.vendorPayout:
        return Colors.amber;
      case NotificationType.chat:
        return Colors.blueAccent;
      case NotificationType.bookingSubmitted:
      case NotificationType.vendorConfirmed:
      case NotificationType.depositReminder:
      case NotificationType.balanceReminder:
      case NotificationType.bookingRescheduled:
      case NotificationType.newBookingRequest:
        return Colors.blue;
      case NotificationType.vendorRejected:
      case NotificationType.bookingCancelled:
      case NotificationType.paymentFailed:
        return Colors.red;
      case NotificationType.paymentReceived:
      case NotificationType.depositSuccessful:
      case NotificationType.refundProcessed:
      case NotificationType.refundCompleted:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.booking:
        return Icons.calendar_today;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.promotion:
        return Icons.local_offer;
      case NotificationType.system:
        return Icons.info;
      case NotificationType.message:
        return Icons.message;
      case NotificationType.payment:
        return Icons.payment;
      case NotificationType.review:
        return Icons.star;
      case NotificationType.update:
        return Icons.update;
      case NotificationType.eventUpdate:
        return Icons.event;
      case NotificationType.vendorApproval:
        return Icons.check_circle;
      case NotificationType.vendorRejection:
        return Icons.cancel;
      case NotificationType.vendorSuspension:
        return Icons.block;
      case NotificationType.vendorActivation:
        return Icons.play_circle;
      case NotificationType.vendorMessage:
        return Icons.business;
      case NotificationType.vendorDocumentVerification:
        return Icons.verified;
      case NotificationType.vendorServiceApproval:
        return Icons.check_circle;
      case NotificationType.vendorPayout:
        return Icons.account_balance_wallet;
      case NotificationType.chat:
        return Icons.chat;
      case NotificationType.bookingSubmitted:
      case NotificationType.newBookingRequest:
        return Icons.calendar_month;
      case NotificationType.vendorConfirmed:
        return Icons.check_circle_outline;
      case NotificationType.paymentReceived:
      case NotificationType.depositSuccessful:
        return Icons.payments;
      case NotificationType.paymentFailed:
        return Icons.error_outline;
      default:
        return Icons.notifications;
    }
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
      case NotificationType.bookingSubmitted:
        return 'Booking Submitted';
      case NotificationType.vendorConfirmed:
        return 'Vendor Confirmed';
      case NotificationType.vendorRejected:
        return 'Vendor Rejected';
      case NotificationType.paymentReceived:
        return 'Payment Received';
      case NotificationType.newBookingRequest:
        return 'New Booking Request';
      default:
        return 'Notification';
    }
  }

  Color _getPriorityColor(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Colors.grey;
      case NotificationPriority.normal:
        return Colors.blue;
      case NotificationPriority.high:
        return Colors.orange;
      case NotificationPriority.urgent:
        return Colors.red;
    }
  }

  IconData _getPriorityIcon(NotificationPriority priority) {
    switch (priority) {
      case NotificationPriority.low:
        return Icons.arrow_downward;
      case NotificationPriority.normal:
        return Icons.remove;
      case NotificationPriority.high:
        return Icons.arrow_upward;
      case NotificationPriority.urgent:
        return Icons.priority_high;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return DateFormat('MMM d').format(dateTime);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
