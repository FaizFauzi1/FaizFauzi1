import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/vendor/presentation/widgets/vendor_drawer.dart';

/// A wrapper Scaffold that provides a responsive layout for Vendor screens.
/// On wide screens (>800px), it shows a persistent sidebar and centers the content.
/// On mobile screens, it falls back to a standard AppBar with a hamburger Drawer.
class VendorResponsiveScaffold extends StatelessWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool restrictMaxWidth;
  final PreferredSizeWidget? bottom;

  const VendorResponsiveScaffold({
    super.key,
    required this.body,
    required this.title,
    this.actions,
    this.floatingActionButton,
    this.backgroundColor = AppTheme.backgroundColor,
    this.restrictMaxWidth = true,
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;

        // The main content area
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
          // Desktop / Tablet Landscape Layout
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Row(
              children: [
                // Persistent Sidebar
                Container(
                  width: 280,
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
                // Main Content Area with AppBar
                Expanded(
                  child: Column(
                    children: [
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
                        automaticallyImplyLeading: false, // No hamburger needed
                        bottom: bottom,
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

        // Mobile Layout
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
            iconTheme: const IconThemeData(color: AppTheme.primaryColor),
            actions: actions,
            bottom: bottom,
          ),
          drawer: VendorDrawer.build(context),
          body: content,
          floatingActionButton: floatingActionButton,
        );
      },
    );
  }
}
