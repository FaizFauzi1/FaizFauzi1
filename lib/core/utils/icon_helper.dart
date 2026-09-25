import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'platform_helper.dart';

/// Icon helper utility for consistent icon handling across platforms
class IconHelper {
  /// Get a Material Design icon with platform-specific sizing
  static Widget getMaterialIcon({
    required IconData iconData,
    required String semanticLabel,
    double? size,
    Color? color,
    bool platformSize = true,
  }) {
    final iconSize = platformSize
        ? PlatformHelper.getIconSize(
            size ?? 24.0,
          )
        : (size ?? 24.0);

    return PlatformHelper.getIconWithFallback(
      iconData: iconData,
      semanticLabel: semanticLabel,
      size: iconSize,
      color: color,
    );
  }

  /// Get an SVG icon with error handling
  static Widget getSvgIcon({
    required String assetPath,
    required String semanticLabel,
    double? size,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    try {
      return SvgPicture.asset(
        PlatformHelper.getAssetPath(assetPath),
        width: size,
        height: size,
        color: color,
        fit: fit,
        semanticsLabel: semanticLabel,
        placeholderBuilder: (context) => getMaterialIcon(
          iconData: Icons.image,
          semanticLabel: 'Loading $semanticLabel',
          size: size,
          color: color,
        ),
      );
    } catch (e) {
      // Fallback to Material Design icon if SVG fails to load
      return getMaterialIcon(
        iconData: Icons.broken_image,
        semanticLabel: semanticLabel,
        size: size,
        color: color,
      );
    }
  }

  /// Get an image icon with error handling
  static Widget getImageIcon({
    required String assetPath,
    required String semanticLabel,
    double? size,
    Color? color,
    BoxFit fit = BoxFit.contain,
  }) {
    try {
      return Image.asset(
        PlatformHelper.getAssetPath(assetPath),
        width: size,
        height: size,
        color: color,
        fit: fit,
        semanticLabel: semanticLabel,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to Material Design icon if image fails to load
          return getMaterialIcon(
            iconData: Icons.broken_image,
            semanticLabel: semanticLabel,
            size: size,
            color: color,
          );
        },
      );
    } catch (e) {
      // Fallback to Material Design icon if image fails to load
      return getMaterialIcon(
        iconData: Icons.broken_image,
        semanticLabel: semanticLabel,
        size: size,
        color: color,
      );
    }
  }

  /// Common icon mappings for consistent usage across the app
  static IconData getIconForAction(String action) {
    switch (action.toLowerCase()) {
      case 'dashboard':
      case 'home':
        return Icons.dashboard;
      case 'bookings':
      case 'booking':
        return Icons.book_online;
      case 'services':
      case 'service':
        return Icons.business_center;
      case 'analytics':
      case 'chart':
      case 'stats':
        return Icons.analytics;
      case 'profile':
      case 'user':
        return Icons.person;
      case 'settings':
      case 'setting':
        return Icons.settings;
      case 'notifications':
      case 'notification':
        return Icons.notifications;
      case 'messages':
      case 'message':
      case 'chat':
        return Icons.message;
      case 'add':
      case 'create':
      case 'plus':
        return Icons.add;
      case 'edit':
      case 'update':
        return Icons.edit;
      case 'delete':
      case 'remove':
      case 'trash':
        return Icons.delete;
      case 'search':
        return Icons.search;
      case 'filter':
        return Icons.filter_alt;
      case 'calendar':
      case 'date':
        return Icons.calendar_today;
      case 'time':
      case 'clock':
        return Icons.access_time;
      case 'location':
      case 'place':
        return Icons.location_on;
      case 'phone':
        return Icons.phone;
      case 'email':
      case 'mail':
        return Icons.email;
      case 'website':
      case 'web':
        return Icons.web;
      case 'payment':
      case 'money':
      case 'revenue':
        return Icons.payment;
      case 'star':
      case 'rating':
        return Icons.star;
      case 'heart':
      case 'favorite':
        return Icons.favorite;
      case 'share':
        return Icons.share;
      case 'download':
        return Icons.download;
      case 'upload':
        return Icons.upload;
      case 'camera':
        return Icons.camera;
      case 'gallery':
      case 'photo':
      case 'image':
        return Icons.photo;
      case 'video':
        return Icons.video_call;
      case 'audio':
      case 'music':
        return Icons.music_note;
      case 'document':
      case 'file':
        return Icons.description;
      case 'menu':
        return Icons.menu;
      case 'close':
      case 'cancel':
        return Icons.close;
      case 'check':
      case 'done':
      case 'success':
        return Icons.check;
      case 'error':
      case 'warning':
        return Icons.warning;
      case 'info':
      case 'information':
        return Icons.info;
      case 'help':
        return Icons.help;
      case 'logout':
      case 'signout':
        return Icons.logout;
      case 'login':
      case 'signin':
        return Icons.login;
      case 'refresh':
      case 'reload':
        return Icons.refresh;
      case 'save':
        return Icons.save;
      case 'send':
        return Icons.send;
      case 'back':
      case 'arrow_back':
        return Icons.arrow_back;
      case 'forward':
      case 'arrow_forward':
        return Icons.arrow_forward;
      case 'up':
      case 'arrow_up':
        return Icons.arrow_upward;
      case 'down':
      case 'arrow_down':
        return Icons.arrow_downward;
      case 'left':
      case 'arrow_left':
        return Icons.arrow_left;
      case 'right':
      case 'arrow_right':
        return Icons.arrow_right;
      default:
        return Icons.help_outline; // Default fallback icon
    }
  }

  /// Get themed icon based on current theme
  static IconData getThemedIcon(String iconName, {bool isDark = false}) {
    // This could be extended to return different icons based on theme
    return getIconForAction(iconName);
  }
}
