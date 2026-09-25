import 'package:flutter/material.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_data_mode_banner.dart';
import 'package:eventease/core/utils/responsive_utils.dart';

/// Standard organizer screen body with optional demo/live data banner.
/// Centers content and limits width on large screens (Web/Desktop).
class OrganizerScreenBody extends StatelessWidget {
  const OrganizerScreenBody({
    super.key,
    required this.child,
    this.showDataModeBanner = true,
  });

  final Widget child;
  final bool showDataModeBanner;

  @override
  Widget build(BuildContext context) {
    Widget current = child;

    if (showDataModeBanner) {
      current = Column(
        children: [
          const OrganizerDataModeBanner(),
          Expanded(child: child),
        ],
      );
    }

    // Apply responsive centering and max-width for web/desktop
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: ResponsiveUtils.maxContentWidth,
        ),
        child: current,
      ),
    );
  }
}
