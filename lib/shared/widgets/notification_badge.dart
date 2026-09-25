import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/notifications/data/providers/notification_provider.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final double badgeSize;
  final Color badgeColor;
  final Color textColor;
  final double fontSize;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.badgeSize = 18.0,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
    this.fontSize = 10.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final unreadCount = notificationProvider.unreadCount;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            child!,
            if (unreadCount > 0)
              Positioned(
                right: -8,
                top: -8,
                child: Container(
                  width: badgeSize,
                  height: badgeSize,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      child: child,
    );
  }
}
