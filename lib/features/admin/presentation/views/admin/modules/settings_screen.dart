import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _darkMode = false;
  bool _pushNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Admin Settings',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Section: Security
          const Text(
            "Security",
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.security, color: AppTheme.accentColor),
              title: const Text("Access Control",
                  style: TextStyle(color: AppTheme.textPrimaryColor)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 16, color: AppTheme.textSecondaryColor),
              onTap: () {
                // Navigate to Access Control page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AccessControlScreen()),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Section: Appearance
          const Text(
            "Appearance",
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              activeColor: AppTheme.accentColor,
              value: _darkMode,
              onChanged: (val) {
                setState(() => _darkMode = val);
                // You can link this with AppTheme / Provider / Riverpod for global theme change
              },
              title: const Text(
                "Dark Mode",
                style: TextStyle(color: AppTheme.textPrimaryColor),
              ),
              secondary: const Icon(Icons.palette, color: AppTheme.accentColor),
            ),
          ),
          const SizedBox(height: 16),

          // Section: Notifications
          const Text(
            "Notifications",
            style: TextStyle(
              color: AppTheme.textPrimaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: SwitchListTile(
              activeColor: AppTheme.accentColor,
              value: _pushNotifications,
              onChanged: (val) {
                setState(() => _pushNotifications = val);
              },
              title: const Text(
                "Push Notifications",
                style: TextStyle(color: AppTheme.textPrimaryColor),
              ),
              secondary: const Icon(Icons.notifications,
                  color: AppTheme.accentColor),
            ),
          ),
        ],
      ),
    );
  }
}

class AccessControlScreen extends StatelessWidget {
  const AccessControlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Access Control",
          style: TextStyle(
              color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimaryColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: AppTheme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const ListTile(
              leading: Icon(Icons.admin_panel_settings,
                  color: AppTheme.accentColor),
              title: Text("Manage Admin Roles",
                  style: TextStyle(color: AppTheme.textPrimaryColor)),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: AppTheme.cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const ListTile(
              leading: Icon(Icons.group, color: AppTheme.accentColor),
              title: Text("Manage User Permissions",
                  style: TextStyle(color: AppTheme.textPrimaryColor)),
            ),
          ),
        ],
      ),
    );
  }
}
