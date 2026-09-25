import 'package:flutter/material.dart';
import 'package:eventease/core/utils/responsive_utils.dart';

/// A wrapper that centers content and limits its width on larger screens.
class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool usePadding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
    this.usePadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double effectiveMaxWidth = maxWidth ?? ResponsiveUtils.maxContentWidth;
    final EdgeInsetsGeometry effectivePadding = padding ?? ResponsiveUtils.getScreenPadding(context);

    // If screen is wider than max content width, center the constrained content.
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: effectiveMaxWidth,
        ),
        child: Padding(
          padding: usePadding ? effectivePadding : EdgeInsets.zero,
          child: child,
        ),
      ),
    );
  }
}

/// A responsive sliver wrapper for centering content in CustomScrollViews.
class ResponsiveSliverWrapper extends StatelessWidget {
  final Widget sliver;
  final double? maxWidth;

  const ResponsiveSliverWrapper({
    super.key,
    required this.sliver,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double effectiveMaxWidth = maxWidth ?? ResponsiveUtils.maxContentWidth;
    final double horizontalPadding = screenWidth > effectiveMaxWidth
        ? (screenWidth - effectiveMaxWidth) / 2
        : 0.0;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      sliver: sliver,
    );
  }
}
