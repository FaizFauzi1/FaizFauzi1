import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/presentation/widgets/vendor_drawer.dart';

/// Responsive layout for Vendor screens.
/// Wide (>800px): persistent sidebar, content fills remaining width.
/// Mobile: AppBar + hamburger drawer (+ optional bottom nav).
class VendorResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  /// When true, centers content with maxWidth 1200 (forms). Default false fills width.
  final bool restrictMaxWidth;
  final PreferredSizeWidget? bottom;
  final Widget? bottomNavigationBar;
  /// Hide the top AppBar title row on desktop (e.g. dashboard with its own header).
  final bool hideDesktopAppBar;
  final Widget? leading;
  /// When true (e.g. inside dashboard IndexedStack), skip sidebar/drawer shell.
  final bool embedded;

  const VendorResponsiveScaffold({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor = AppTheme.backgroundColor,
    this.restrictMaxWidth = false,
    this.bottom,
    this.bottomNavigationBar,
    this.hideDesktopAppBar = false,
    this.leading,
    this.embedded = false,
  });

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width > 800;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: hideDesktopAppBar
            ? null
            : AppBar(
                title: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                actions: actions,
                automaticallyImplyLeading: false,
                bottom: bottom,
              ),
        body: body,
        floatingActionButton: floatingActionButton,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;

        Widget content = body;
        if (isWideScreen && restrictMaxWidth) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: body,
            ),
          );
        }

        if (isWideScreen) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Row(
              children: [
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: const VendorSidebarContent(),
                ),
                Expanded(
                  child: Column(
                    children: [
                      if (!hideDesktopAppBar)
                        AppBar(
                          title: Text(
                            title,
                            style: const TextStyle(
                              color: AppTheme.textPrimaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                          actions: actions,
                          automaticallyImplyLeading: false,
                          bottom: bottom,
                        ),
                      if (hideDesktopAppBar && bottom != null)
                        Material(
                          color: Colors.transparent,
                          child: bottom!,
                        ),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: floatingActionButton,
          );
        }

        return Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            title: Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: leading,
            iconTheme: const IconThemeData(color: AppTheme.primaryColor),
            actions: actions,
            bottom: bottom,
          ),
          drawer: VendorDrawer.build(context),
          body: content,
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: bottomNavigationBar,
        );
      },
    );
  }
}
