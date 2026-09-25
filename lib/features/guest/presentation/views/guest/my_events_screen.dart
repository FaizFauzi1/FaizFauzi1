import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/event/data/providers/invitation_provider.dart';
import 'package:eventease/core/utils/guest_routes.dart';

class MyEventsScreen extends StatelessWidget {
  const MyEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final invitationProvider = Provider.of<InvitationProvider>(context);
    final eventProvider = Provider.of<EventProvider>(context);
    final joinedCodes = invitationProvider.joinedInvitationCodes;

    return Scaffold(
      appBar: AppBar(title: const Text('My Events')),
      body: joinedCodes.isEmpty
          ? const Center(child: Text('No joined events found.'))
          : ListView.builder(
              itemCount: joinedCodes.length,
              itemBuilder: (context, index) {
                final code = joinedCodes[index];
                return FutureBuilder(
                  future: Future.wait([
                    invitationProvider.getInvitationByCode(code),
                    eventProvider.getEventByShortId(code),
                  ]),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const ListTile(title: Text('Loading...'));
                    }
                    
                    // Logic to retrieve the event from the combined results
                    final results = snapshot.data as List?;
                    final invitation = results?[0];
                    final event = results?[1] ?? (invitation != null ? eventProvider.getEventById(invitation.eventId) : null);

                    if (event == null) {
                      return ListTile(title: Text('Event $code not found'));
                    }

                    return ListTile(
                      title: Text(event.title),
                      subtitle: Text('Event Code: ${event.id.substring(0, 8).toUpperCase()}'),
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          GuestRoutes.guestDashboard,
                          arguments: {'event': event, 'invitation': invitation},
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
