import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/constants/app_config.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/features/customer/data/providers/customer_subscription_provider.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/event/data/providers/invitation_provider.dart';
import 'package:eventease/shared/models/photo_album.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/countdown_widget_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eventease/features/event/presentation/widgets/digital_invite_card_dialog.dart';

class EventManagementScreen extends StatefulWidget {
  const EventManagementScreen({super.key});

  @override
  State<EventManagementScreen> createState() => _EventManagementScreenState();
}

class _EventManagementScreenState extends State<EventManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize sample data if no events exist
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eventProvider = Provider.of<EventProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.isAuthenticated && authProvider.userId != null) {
        eventProvider.loadEvents(authProvider.userId!).then((_) {
          // Sync the nearest upcoming event to the home-screen widget
          CountdownWidgetService.saveNearestEvent(eventProvider.events);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Events'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Consumer3<AuthProvider, EventProvider, CustomerSubscriptionProvider>(
        builder: (context, authProvider, eventProvider, subscriptionProvider, child) {
          if (!authProvider.isAuthenticated) {
            return const Center(child: Text('Please log in to view your events.'));
          }

          final hostId = authProvider.userId ?? '';
          // Use subscription provider to check premium status
          final isPremium = subscriptionProvider.isPremium;

          if (!isPremium) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock,
                    size: 80,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Premium Feature',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Event planning tools are available only for premium customers. Upgrade to premium to create and manage your events.',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/customer-subscription');
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('Upgrade to Premium'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          final events = eventProvider.getEventsByHost(hostId);

          if (events.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.event_note,
                    size: 80,
                    color: AppTheme.textSecondaryColor,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Events Yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first event to get started!',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textSecondaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildActionCard(
                    context,
                    'Create New Event',
                    'Plan a new event and invite guests',
                    Icons.add,
                    () {
                      Navigator.pushNamed(context, '/event-create');
                    },
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Your Events',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Here you can create new events, manage existing ones, and handle guest lists.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return _buildEventCard(context, event);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionCard(
                  context,
                  'Create New Event',
                  'Plan a new event and invite guests',
                  Icons.add,
                  () {
                    Navigator.pushNamed(context, '/event-create');
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.date.day}/${event.date.month}/${event.date.year} at ${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: ${event.status.toString().split('.').last}',
                        style: TextStyle(
                          fontSize: 12,
                          color: event.status == EventStatus.published
                              ? Colors.green
                              : AppTheme.textSecondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    event.type.displayName,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/event-edit',
                        arguments: {'event': event},
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _shareEventCode(context, event),
                    icon: const Icon(Icons.share),
                    label: const Text('Share Code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/event-details',
                    arguments: {'event': event},
                  );
                },
                icon: const Icon(Icons.visibility),
                label: const Text('Preview as Guest'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/planning-hub',
                    arguments: {'eventId': event.id},
                  );
                },
                icon: const Icon(Icons.hub_rounded),
                label: const Text('Open Planning Hub'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            // ── Countdown button (only for future events) ──
            if (event.startTime.isAfter(DateTime.now())) ...
              [
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/event-countdown',
                        arguments: {'event': event},
                      );
                    },
                    icon: const Icon(Icons.timer_rounded),
                    label: const Text('View Countdown'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6B3FA0),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondaryColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareEventCode(BuildContext context, Event event) async {
    final invitationProvider = Provider.of<InvitationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get or create a general invitation for this event
      final invitation = await invitationProvider.getOrCreateGeneralInvitation(
        event.id, 
        authProvider.userEmail ?? 'host@eventease.com'
      );
      
      if (!mounted) return;
      Navigator.pop(context); // Remove loading dialog

      // Use the first 8 characters of Event ID as the Master Code
      final masterCode = event.id.substring(0, 8).toUpperCase();
      final appSchemeLink = '${AppConfig.appInviteLinkBase}$masterCode';
      final webLink = '${AppConfig.inviteLinkBase}$masterCode';
      
      final shareText = '🌟 You are invited to ${event.title}!\n\n'
          '📅 Date: ${event.date.day}/${event.date.month}/${event.date.year}\n'
          '📍 Venue: ${event.venue.name}\n\n'
          '📲 Open in App:\n$appSchemeLink\n\n'
          '🌐 Open in Browser:\n$webLink\n\n'
          '🔑 Event Join Code: $masterCode';

      // Show sharing options
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Share Invitation',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 20,
                runSpacing: 20,
                children: [
                  _shareOption(
                    context,
                    icon: Icons.style,
                    label: 'Digital Card',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      DigitalInviteCardDialog.show(context, event: event);
                    },
                  ),
                  _shareOption(
                    context,
                    icon: Icons.chat,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () {
                      Navigator.pop(context);
                      DigitalInviteCardDialog.show(context, event: event);
                    },
                  ),
                  _shareOption(
                    context,
                    icon: Icons.share,
                    label: 'Text Share',
                    color: AppTheme.primaryColor,
                    onTap: () {
                      Share.share(shareText, subject: 'Invitation to ${event.title}');
                      Navigator.pop(context);
                    },
                  ),
                  _shareOption(
                    context,
                    icon: Icons.copy,
                    label: 'Copy Code',
                    color: Colors.grey,
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: masterCode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Code $masterCode copied!')),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Remove loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating invitation: $e')),
        );
      }
    }
  }

  Widget _shareOption(BuildContext context, {
    required IconData icon, 
    required String label, 
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
