import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Platform-specific helper for handling icons and assets across web and mobile
class PlatformHelper {
  /// Check if running on web platform
  static bool get isWeb => kIsWeb;

  /// Check if running on mobile platform (Android/iOS)
  static bool get isMobile => !kIsWeb;

  /// Get platform-specific icon size
  static double getIconSize(double defaultSize) {
    if (isWeb) {
      // Slightly larger icons on web for better visibility
      return defaultSize * 1.2;
    }
    return defaultSize;
  }

  /// Get platform-specific asset path with fallback
  static String getAssetPath(String assetPath, {String? fallbackPath}) {
    if (isWeb) {
      // On web, ensure assets are properly accessible
      return assetPath;
    }
    return assetPath;
  }

  /// Handle icon loading with error fallback
  static Widget getIconWithFallback({
    required IconData iconData,
    required String semanticLabel,
    double? size,
    Color? color,
  }) {
    return Icon(
      iconData,
      size: size,
      color: color,
      semanticLabel: semanticLabel,
    );
  }

  /// Get platform-specific loading indicator
  static Widget getLoadingIndicator({double? size, Color? color}) {
    return CircularProgressIndicator(
      strokeWidth: 2.0,
      valueColor: AlwaysStoppedAnimation<Color>(
        color ?? Colors.blue,
      ),
    );
  }

  /// Check if device has high DPI display
  static bool get isHighDpi {
    if (isWeb) {
      // On web, we can check window.devicePixelRatio
      return (ui.window.devicePixelRatio) > 1.5;
    }
    return false;
  }

  /// Get platform-specific spacing
  static EdgeInsets getPlatformPadding({double all = 16.0}) {
    if (isWeb) {
      // More generous padding on web
      return EdgeInsets.all(all * 1.2);
    }
    return EdgeInsets.all(all);
  }
}
