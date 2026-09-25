import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:eventease/features/admin/presentation/views/admin/modules/emergency_partner_matcher_screen.dart';

class RescueRoomScreen extends StatefulWidget {
  final String incidentId;
  final String bookingTitle;

  const RescueRoomScreen({
    Key? key,
    required this.incidentId,
    required this.bookingTitle,
  }) : super(key: key);

  @override
  State<RescueRoomScreen> createState() => _RescueRoomScreenState();
}

class _RescueRoomScreenState extends State<RescueRoomScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {
      'sender': 'System',
      'type': 'alert',
      'text': 'Emergency SOS Triggered. Priority: CRITICAL.',
      'time': DateTime.now().subtract(const Duration(minutes: 12)),
    },
    {
      'sender': 'AI Assistant',
      'type': 'system',
      'text': 'I have notified the EventEase Operations Team. Attempting to contact the original vendor now.',
      'time': DateTime.now().subtract(const Duration(minutes: 11)),
    },
    {
      'sender': 'EventEase Ops',
      'type': 'admin',
      'text': 'Hi, I am Mike from Ops. I see the photographer hasn\'t arrived. I am calling them immediately. Please stay calm, we have backups on standby.',
      'time': DateTime.now().subtract(const Duration(minutes: 8)),
    },
    {
      'sender': 'You',
      'type': 'user',
      'text': 'Thank you! The event starts in 45 minutes.',
      'time': DateTime.now().subtract(const Duration(minutes: 7)),
    },
    {
      'sender': 'AI Assistant',
      'type': 'system',
      'text': 'Original vendor unreachable. Activating Emergency Partner Protocol. Searching for available Photographers within 15km...',
      'time': DateTime.now().subtract(const Duration(minutes: 2)),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Rescue Room', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
            Text('Case ${widget.incidentId} • ${widget.bookingTitle}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: Colors.black87,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
            alignment: Alignment.center,
            child: const Text('LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),
      body: Column(
        children: [
          _buildStatusBanner(),
          // Action button for Admin to trigger backup vendor search
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            width: double.infinity,
            color: Colors.white,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EmergencyPartnerMatcherScreen(
                      incidentId: widget.incidentId,
                      categoryRequired: 'Photographer', // Simulated category
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.person_search, color: Colors.white),
              label: const Text('Find Backup Vendor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ),
          Expanded(child: _buildChatTimeline()),
          _buildChatInput(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Resolution Status:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              Text('Searching Backup', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: 0.6,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Reported', style: TextStyle(fontSize: 10)),
              Text('Investigating', style: TextStyle(fontSize: 10)),
              Text('Finding Backup', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
              Text('Resolved', style: TextStyle(fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildChatTimeline() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final bool isMe = msg['sender'] == 'You';
        final bool isSystem = msg['type'] == 'system' || msg['type'] == 'alert';

        if (isSystem) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: msg['type'] == 'alert' ? Colors.red.shade50 : Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: msg['type'] == 'alert' ? Colors.red.shade200 : Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(msg['type'] == 'alert' ? Icons.warning : Icons.smart_toy, 
                     color: msg['type'] == 'alert' ? Colors.red : Colors.blue, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(msg['text'], style: TextStyle(
                    color: msg['type'] == 'alert' ? Colors.red.shade900 : Colors.blue.shade900,
                    fontWeight: FontWeight.w500,
                  )),
                )
              ],
            ),
          );
        }

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(msg['sender'], style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isMe ? AppTheme.primaryColor : (msg['type'] == 'admin' ? Colors.black87 : Colors.white),
                    borderRadius: BorderRadius.circular(16).copyWith(
                      bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                      bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                  ),
                  child: Text(
                    msg['text'],
                    style: TextStyle(color: isMe || msg['type'] == 'admin' ? Colors.white : Colors.black87),
                  ),
                ),
                const SizedBox(height: 4),
                Text(DateFormat('h:mm a').format(msg['time']), style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _chatController,
                decoration: InputDecoration(
                  hintText: 'Type your message...',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primaryColor,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: () {
                  if (_chatController.text.trim().isNotEmpty) {
                    setState(() {
                      _messages.add({
                        'sender': 'You',
                        'type': 'user',
                        'text': _chatController.text.trim(),
                        'time': DateTime.now(),
                      });
                      _chatController.clear();
                    });
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
