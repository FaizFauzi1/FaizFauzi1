import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Standard Breakpoints
  static const double mobileLimit = 600.0;
  static const double tabletLimit = 1024.0;
  
  // Layout Constants
  static const double maxContentWidth = 1200.0;
  static const double maxFormWidth = 600.0;
  
  // Helper functions
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileLimit;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileLimit &&
      MediaQuery.of(context).size.width < tabletLimit;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletLimit;

  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileLimit;

  // Responsive padding — tighter on desktop vendor tools
  static EdgeInsets getScreenPadding(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < mobileLimit) {
      return const EdgeInsets.all(16.0);
    } else if (width < tabletLimit) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0);
    }
  }

  // Dynamic grid column count
  static int getGridColumnCount(BuildContext context, {int mobile = 2, int tablet = 3, int desktop = 4}) {
    double width = MediaQuery.of(context).size.width;
    if (width < mobileLimit) return mobile;
    if (width < tabletLimit) return tablet;
    return desktop;
  }
  
  // Get width for centered content
  static double getContentWidth(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return width > maxContentWidth ? maxContentWidth : width;
  }
}

/// Extension to easily add hover effects (pointer cursor and slight scale/elevation)
extension HoverExtension on Widget {
  Widget get showCursorOnHover {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: this,
    );
  }
}
