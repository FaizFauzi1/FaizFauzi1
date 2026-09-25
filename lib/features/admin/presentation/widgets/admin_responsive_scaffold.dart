import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/admin/presentation/views/admin/widgets/admin_drawer.dart';

/// A wrapper Scaffold that provides a responsive layout for Admin screens.
/// On wide screens (>=1024px), it shows a persistent sidebar and centers the content.
/// On mobile screens, it falls back to an optional bottom navigation bar and hamburger Drawer.
class AdminResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;
  final bool restrictMaxWidth;

  const AdminResponsiveScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.appBar,
    this.restrictMaxWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;

        // The main content area
        Widget content = body;
        if (isDesktop && restrictMaxWidth) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: body,
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundColor,
          appBar: appBar,
          drawer: isDesktop ? null : adminDrawer(context),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: 300,
                  child: Material(
                    elevation: 2,
                    color: Colors.white,
                    child: adminDrawerContent(context),
                  ),
                ),
              Expanded(child: content),
            ],
          ),
          bottomNavigationBar: isDesktop ? null : bottomNavigationBar,
        );
      },
    );
  }
}
