import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:intl/intl.dart';

class ChatInboxScreen extends StatefulWidget {
  const ChatInboxScreen({super.key});
  static const routeName = '/organizer/chat-inbox';

  @override
  State<ChatInboxScreen> createState() => _ChatInboxScreenState();
}

class _ChatInboxScreenState extends State<ChatInboxScreen> {
  int _filter = 0;
  final _threads = [
    _Thread('Glam Bridal Studio', 'Vendor', 'Can we get an extra power outlet?', '10 min ago', 2),
    _Thread('Ahmad Rizal', 'Staff', 'Zone A queue is building up', '25 min ago', 1),
    _Thread('Maybank', 'Sponsor', 'Confirming logo placement on stage', '1 hr ago', 0),
    _Thread('Royal Catering Co', 'Vendor', 'Payment receipt attached', '2 hr ago', 0),
    _Thread('Registration team', 'Staff', 'VIP list updated', 'Yesterday', 0),
  ];

  List<_Thread> get _filtered {
    if (_filter == 0) return _threads;
    const types = ['All', 'Vendor', 'Staff', 'Sponsor'];
    return _threads.where((t) => t.type == types[_filter]).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Chat Inbox'),
      body: OrganizerScreenBody(
        child: Column(
          children: [
            OrganizerFilterChips(labels: const ['All', 'Vendors', 'Staff', 'Sponsors'], selectedIndex: _filter, onSelected: (i) => setState(() => _filter = i)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final t = _filtered[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                        child: Icon(switch (t.type) {
                          'Vendor' => Icons.storefront,
                          'Staff' => Icons.badge,
                          _ => Icons.business,
                        }, color: AppTheme.primaryColor, size: 20),
                      ),
                      title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${t.type} · ${t.preview}', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(t.time, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
                          if (t.unread > 0)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(color: AppTheme.errorColor, shape: BoxShape.circle),
                              child: Text('${t.unread}', style: const TextStyle(color: Colors.white, fontSize: 10)),
                            ),
                        ],
                      ),
                      onTap: () => _openChat(context, t),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChat(BuildContext context, _Thread t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            ListTile(title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(t.type)),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.all(16),
                children: [
                  _Bubble(t.preview, false),
                  _Bubble('Thanks, we will look into this shortly.', true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Expanded(child: TextField(decoration: InputDecoration(hintText: 'Type a message...', border: OutlineInputBorder()))),
                  IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.send, color: AppTheme.primaryColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool isMe;
  const _Bubble(this.text, this.isMe);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : AppTheme.borderColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(text, style: TextStyle(color: isMe ? Colors.white : AppTheme.textPrimaryColor)),
      ),
    );
  }
}

class _Thread {
  final String name;
  final String type;
  final String preview;
  final String time;
  final int unread;
  const _Thread(this.name, this.type, this.preview, this.time, this.unread);
}

class VendorCommunicationScreen extends StatefulWidget {
  const VendorCommunicationScreen({super.key});
  static const routeName = '/organizer/vendor-communication';

  @override
  State<VendorCommunicationScreen> createState() => _VendorCommunicationScreenState();
}

class _VendorCommunicationScreenState extends State<VendorCommunicationScreen> {
  final _subject = TextEditingController(text: 'Expo day schedule update');
  final _body = TextEditingController(text: 'Dear exhibitors,\n\nDoors open at 10:00 AM. Please ensure your booth setup is complete by 9:30 AM.\n\nRegards,\nExpo Operations');

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Vendor Communication'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Send expo updates to all registered vendors.', style: TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 16),
            TextField(controller: _subject, decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _body, maxLines: 8, decoration: const InputDecoration(labelText: 'Message', border: OutlineInputBorder(), alignLabelWithHint: true)),
            const SizedBox(height: 16),
            const Text('Recipients: 94 approved vendors', style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update sent to all vendors'))),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              icon: const Icon(Icons.send),
              label: const Text('Send update'),
            ),
          ],
        ),
      ),
    );
  }
}

class BroadcastMessagingScreen extends StatefulWidget {
  const BroadcastMessagingScreen({super.key});
  static const routeName = '/organizer/broadcast-messaging';

  @override
  State<BroadcastMessagingScreen> createState() => _BroadcastMessagingScreenState();
}

class _BroadcastMessagingScreenState extends State<BroadcastMessagingScreen> {
  final _message = TextEditingController();
  final _channels = {'Push notification': true, 'Email': true, 'SMS': false};
  String _audience = 'All vendors';

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Broadcast Messaging'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              value: _audience,
              decoration: const InputDecoration(labelText: 'Audience', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'All vendors', child: Text('All vendors')),
                DropdownMenuItem(value: 'All staff', child: Text('All staff')),
                DropdownMenuItem(value: 'All sponsors', child: Text('All sponsors')),
                DropdownMenuItem(value: 'Everyone', child: Text('Everyone at expo')),
              ],
              onChanged: (v) => setState(() => _audience = v!),
            ),
            const SizedBox(height: 16),
            TextField(controller: _message, maxLines: 4, decoration: const InputDecoration(labelText: 'Broadcast message', hintText: 'e.g. Main hall will close in 30 minutes', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const Text('Channels', style: TextStyle(fontWeight: FontWeight.w600)),
            ..._channels.keys.map((ch) => SwitchListTile(
                  title: Text(ch),
                  value: _channels[ch]!,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (v) => setState(() => _channels[ch] = v),
                )),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Broadcast sent to $_audience'))),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Send broadcast'),
            ),
            const SizedBox(height: 24),
            const Text('Recent broadcasts', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...[
              ('VIP lounge now open', DateTime.now().subtract(const Duration(hours: 2))),
              ('Lucky draw at 4 PM – Main stage', DateTime.now().subtract(const Duration(hours: 5))),
            ].map((b) => Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: const Icon(Icons.campaign, color: AppTheme.primaryColor),
                    title: Text(b.$1),
                    subtitle: Text(DateFormat('d MMM, HH:mm').format(b.$2)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
