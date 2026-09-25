import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdminCommsScreen extends StatefulWidget {
  const AdminCommsScreen({super.key});

  @override
  State<AdminCommsScreen> createState() => _AdminCommsScreenState();
}

class _AdminCommsScreenState extends State<AdminCommsScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  String _audience = "All"; // Default
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    // Filter announcements by search
    final announcements = admin.announcements.where((a) {
      return _searchQuery.isEmpty ||
          a.message.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Admin Communication Hub',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Send Announcement Section ----
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Send Announcement",
                      style: TextStyle(
                          color: AppTheme.textPrimaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _msgCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type your announcement...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _audience,
                    items: const [
                      DropdownMenuItem(value: "All", child: Text("All Users")),
                      DropdownMenuItem(
                          value: "Vendors", child: Text("Vendors Only")),
                      DropdownMenuItem(
                          value: "Users", child: Text("Event Organizers Only")),
                    ],
                    onChanged: (v) => setState(() => _audience = v ?? "All"),
                    decoration: const InputDecoration(
                      labelText: "Audience",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (_msgCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Message is empty!')));
                        return;
                      }
                      // Send announcement and push notification
                      admin.addAnnouncement(_msgCtrl.text, _audience);
                      _sendPushNotification(_msgCtrl.text, _audience);
                      _msgCtrl.clear();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'Announcement sent to $_audience (placeholder).')));
                    },
                    icon: const Icon(Icons.send),
                    label: const Text("Send"),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ---- Search Past Announcements ----
          TextField(
            decoration: const InputDecoration(
              hintText: "Search announcements...",
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),

          const SizedBox(height: 16),

          // ---- Announcements Log ----
          const Text("Announcements Log",
              style: TextStyle(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),

          const SizedBox(height: 8),

          if (announcements.isEmpty)
            const Center(
                child: Text("No announcements found",
                    style: TextStyle(color: AppTheme.textSecondaryColor)))
          else
            ...announcements.map((a) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Icon(
                      a.pinned ? Icons.push_pin : Icons.campaign,
                      color: a.pinned
                          ? AppTheme.secondaryColor
                          : AppTheme.primaryColor,
                    ),
                    title: Text(a.message,
                        style: const TextStyle(
                            color: AppTheme.textPrimaryColor,
                            fontWeight: FontWeight.w500)),
                    subtitle: Text(
                      "${a.date} • Sent to ${a.audience}",
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textSecondaryColor),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == "Pin") {
                          admin.pinAnnouncement(a);
                        } else if (value == "Delete") {
                          admin.removeAnnouncement(a);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: "Pin", child: Text("Pin / Unpin")),
                        const PopupMenuItem(
                            value: "Delete", child: Text("Delete")),
                      ],
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // Send Push Notification
  void _sendPushNotification(String message, String audience) {
    // In a real implementation, this would integrate with FCM
    // For now, we'll simulate the notification sending
    print('Sending push notification to $audience: $message');

    // Simulate notification sending with different channels based on audience
    switch (audience) {
      case 'All':
        print('Broadcasting to all users via FCM');
        break;
      case 'Vendors':
        print('Sending to vendor channel via FCM');
        break;
      case 'Users':
        print('Sending to event organizer channel via FCM');
        break;
    }

    // In a real app, you would:
    // 1. Get FCM tokens for the target audience
    // 2. Send notification via Firebase Cloud Messaging
    // 3. Handle success/error responses
    // 4. Update notification delivery status
  }
}
