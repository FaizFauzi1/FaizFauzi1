import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/organizer/presentation/organizer_screen_catalog.dart';

/// A wrapper Scaffold that provides a responsive layout for Organizer screens.
/// On wide screens (>800px), it shows a persistent sidebar and centers the content.
/// On mobile screens, it falls back to a standard AppBar with a hamburger Drawer.
class OrganizerResponsiveScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Color? backgroundColor;
  final bool restrictMaxWidth;
  final PreferredSizeWidget? bottom;

  const OrganizerResponsiveScaffold({
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
  State<OrganizerResponsiveScaffold> createState() => _OrganizerResponsiveScaffoldState();
}

class _OrganizerResponsiveScaffoldState extends State<OrganizerResponsiveScaffold> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Route guard: if authenticated as a non-organizer (e.g. customer/vendor), block access
    if (auth.isAuthenticated && !auth.isOrganizer) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: const Color(0xFF1E1B4B),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_person_outlined, size: 64, color: Colors.red),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Organizer Portal Restricted',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'You are currently logged in as a non-organizer account. Only approved event organizers can access the Organizer Command Portal.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), height: 1.5),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed: () {
                      final route = auth.getRouteForUser();
                      Navigator.pushNamedAndRemoveUntil(context, route, (r) => false);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go to My Dashboard'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () async {
                      await auth.signOut();
                      if (!context.mounted) return;
                      Navigator.pushNamedAndRemoveUntil(context, '/organizer/login', (r) => false);
                    },
                    child: const Text('Sign in with Organizer Account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;

        // The main content area
        Widget content = widget.body;
        if (isWideScreen && widget.restrictMaxWidth) {
          content = Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: widget.body,
            ),
          );
        }

        if (isWideScreen) {
          // Desktop / Tablet Landscape Layout
          return Scaffold(
            backgroundColor: widget.backgroundColor,
            body: Row(
              children: [
                // Persistent Sidebar
                Container(
                  width: 280,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B), // Organizer dark blue
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(2, 0),
                      ),
                    ],
                  ),
                  child: const _OrganizerSidebar(),
                ),
                // Main Content Area with AppBar
                Expanded(
                  child: Column(
                    children: [
                      AppBar(
                        title: Text(
                          widget.title,
                          style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        actions: widget.actions,
                        automaticallyImplyLeading: false, // No hamburger needed
                        bottom: widget.bottom,
                      ),
                      Expanded(child: content),
                    ],
                  ),
                ),
              ],
            ),
            floatingActionButton: widget.floatingActionButton,
          );
        }

        // Mobile Layout
        return Scaffold(
          backgroundColor: widget.backgroundColor,
          appBar: AppBar(
            title: Text(
              widget.title,
            ),
            backgroundColor: const Color(0xFF1E1B4B),
            foregroundColor: Colors.white,
            elevation: 0,
            actions: widget.actions,
            bottom: widget.bottom,
          ),
          drawer: Drawer(
            child: Container(
              color: const Color(0xFF1E1B4B),
              child: const _OrganizerSidebar(),
            ),
          ),
          body: content,
          floatingActionButton: widget.floatingActionButton,
        );
      },
    );
  }
}

class _OrganizerSidebar extends StatelessWidget {
  const _OrganizerSidebar();

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Organizer Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out from the Organizer Portal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final auth = context.read<AuthProvider>();
      await auth.signOut();
      if (!context.mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/organizer/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Organizer Command',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _SidebarItem(
          icon: Icons.dashboard_outlined,
          title: 'Dashboard',
          onTap: () => Navigator.pushReplacementNamed(context, OrganizerScreenCatalog.byId('expo_command_dashboard')!.route),
        ),
        _SidebarItem(
          icon: Icons.event_note_outlined,
          title: 'Expos',
          onTap: () => Navigator.pushNamed(context, OrganizerScreenCatalog.byId('expo_list')!.route),
        ),
        _SidebarItem(
          icon: Icons.people_outline,
          title: 'Vendors',
          onTap: () => Navigator.pushNamed(context, OrganizerScreenCatalog.byId('vendor_directory')!.route),
        ),
        _SidebarItem(
          icon: Icons.groups_outlined,
          title: 'Visitors',
          onTap: () => Navigator.pushNamed(context, OrganizerScreenCatalog.byId('visitor_registration')!.route),
        ),
        _SidebarItem(
          icon: Icons.campaign_outlined,
          title: 'Marketing',
          onTap: () => Navigator.pushNamed(context, OrganizerScreenCatalog.byId('campaign_dashboard')!.route),
        ),
        _SidebarItem(
          icon: Icons.analytics_outlined,
          title: 'Analytics',
          onTap: () => Navigator.pushNamed(context, OrganizerScreenCatalog.byId('expo_analytics_dashboard')!.route),
        ),
        const Divider(color: Colors.white24),
        _SidebarItem(
          icon: Icons.settings_outlined,
          title: 'Settings',
          onTap: () => Navigator.pushNamed(context, OrganizerScreenCatalog.byId('company_settings')!.route),
        ),
        _SidebarItem(
          icon: Icons.logout_rounded,
          title: 'Sign Out',
          iconColor: Colors.redAccent.shade100,
          textColor: Colors.redAccent.shade100,
          onTap: () => _confirmSignOut(context),
        ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;

  const _SidebarItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Colors.white70),
      title: Text(
        title,
        style: TextStyle(color: textColor ?? Colors.white70),
      ),
      hoverColor: Colors.white10,
      onTap: () {
        Scaffold.maybeOf(context)?.closeDrawer();
        onTap();
      },
    );
  }
}
