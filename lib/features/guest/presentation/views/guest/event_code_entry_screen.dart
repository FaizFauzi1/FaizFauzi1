import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/event/data/models/invitation.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/event/data/providers/invitation_provider.dart';
import 'package:eventease/core/utils/guest_routes.dart';
import 'package:eventease/features/guest/presentation/views/guest/guest_dashboard_screen.dart';

class EventCodeEntryScreen extends StatefulWidget {
  const EventCodeEntryScreen({super.key});

  @override
  State<EventCodeEntryScreen> createState() => _EventCodeEntryScreenState();
}

class _EventCodeEntryScreenState extends State<EventCodeEntryScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _joinEvent({String? providedCode}) async {
    final code = (providedCode ?? _codeController.text.trim()).toUpperCase();

    if (code.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an event code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
      final eventProvider = Provider.of<EventProvider>(context, listen: false);

      // 1. Check if it's a valid invitation code first
      var invitation = await invitationProvider.getInvitationByCode(code, forceRefresh: true);
      Event? event;

      if (invitation != null) {
        // Valid specific invitation
        event = await eventProvider.fetchEventById(invitation.eventId);
      } else {
        // 2. Otherwise, check for a Master Code (Event Short ID)
        event = await eventProvider.getEventByShortId(code);
        if (event != null) {
          // Get or create a shared general invitation for this event
          invitation = await invitationProvider.getOrCreateGeneralInvitation(event.id, event.hostEmail ?? '');
        }
      }
      
      if (event == null || invitation == null) {
        setState(() {
          _errorMessage = 'Invalid event code. Please check and try again.';
          _isLoading = false;
        });
        return;
      }

      // Mark as viewed
      await invitationProvider.markInvitationViewed(invitation.id);

      // Determine the shared master code (Event short ID)
      final masterCode = event.id.substring(0, 8).toUpperCase();

      // Cache the master code
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_joined_invitation_code', masterCode);
      await invitationProvider.addJoinedInvitationCode(masterCode);

      setState(() {
        _isLoading = false;
      });

      // Navigate with full context
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          GuestRoutes.invitation,
          arguments: {
            'invitationCode': masterCode, // Use master code for navigation
            'invitation': invitation, 
            'event': event
          },
        );
      }

    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to join event. Please try again.';
        _isLoading = false;
      });
    }
  }

  Widget _buildRecentEvents() {
    final invitationProvider = Provider.of<InvitationProvider>(context);
    final recentCodes = invitationProvider.joinedInvitationCodes;

    if (recentCodes.isEmpty) return const SizedBox.shrink();

    // Deduplicate and filter: Only show codes that look like Master Codes (8 chars)
    final uniqueCodes = recentCodes.toSet().where((code) => code.length == 8).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        Row(
          children: [
            const Icon(Icons.history, size: 20, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Recently Joined Events',
              style: TextStyle(
                fontSize: 16, 
                fontWeight: FontWeight.bold, 
                color: Colors.grey[700],
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...uniqueCodes.map((code) => Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: InkWell(
            onTap: () {
              _joinEvent(providedCode: code);
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[200]!),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.event_available, size: 18, color: Colors.blue[700]),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    code.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
                ],
              ),
            ),
          ),
        )),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Event')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(labelText: 'Enter Event Code'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _joinEvent(),
              child: _isLoading ? const CircularProgressIndicator() : const Text('Join Event'),
            ),
            if (_errorMessage != null) Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            _buildRecentEvents(),
          ],
        ),
      ),
    );
  }
}
