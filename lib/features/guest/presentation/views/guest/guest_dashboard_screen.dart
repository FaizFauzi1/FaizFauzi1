import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/event/data/models/invitation.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/features/event/data/providers/invitation_provider.dart';
import 'package:eventease/core/utils/guest_routes.dart';

class GuestDashboardScreen extends StatefulWidget {
  final Event event;
  final Invitation invitation;

  const GuestDashboardScreen({
    super.key,
    required this.event,
    required this.invitation,
  });

  @override
  State<GuestDashboardScreen> createState() => _GuestDashboardScreenState();
}

class _GuestDashboardScreenState extends State<GuestDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.event.title} - Guest Portal'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettingsDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Header
            _buildEventHeader(),

            const SizedBox(height: 24),

            // Quick Actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActions(),

            const SizedBox(height: 24),

            // Event Features
            Text(
              'Event Features',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildEventFeatures(),

            const SizedBox(height: 24),

            // Guest Setup
            Text(
              'Guest Setup',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildGuestSetup(),

            const SizedBox(height: 24),

            // Important Information
            _buildImportantInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventHeader() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.event.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  _formatDate(widget.event.date),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${_formatTime(widget.event.startTime)} - ${_formatTime(widget.event.endTime ?? widget.event.startTime.add(const Duration(hours: 4)))}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.event.venue.name,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: widget.invitation.rsvpResponse == 'accepted'
                    ? Colors.green[100]
                    : Colors.orange[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.invitation.rsvpResponse == 'accepted'
                    ? '✓ RSVP Confirmed'
                    : '⏳ RSVP Pending',
                style: TextStyle(
                  color: widget.invitation.rsvpResponse == 'accepted'
                      ? Colors.green[800]
                      : Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildActionCard(
          icon: Icons.confirmation_number,
          title: 'E-Ticket',
          subtitle: 'Digital entry pass',
          onTap: () => _navigateToScreen(GuestRoutes.eTicket),
        ),
        _buildActionCard(
          icon: Icons.mail,
          title: 'View Invitation',
          subtitle: 'See original invite',
          onTap: _navigateToInvitation,
        ),
        _buildActionCard(
          icon: Icons.chat,
          title: 'Guest Chat',
          subtitle: 'Connect with others',
          onTap: () => _navigateToScreen(GuestRoutes.guestChat),
        ),
        _buildActionCard(
          icon: Icons.photo_camera,
          title: 'Photo Sharing',
          subtitle: 'Share memories',
          onTap: () => _navigateToScreen(GuestRoutes.photoSharing),
        ),
      ],
    );
  }

  Widget _buildEventFeatures() {
    return Column(
      children: [
        _buildFeatureCard(
          icon: Icons.schedule,
          title: 'Event Schedule',
          subtitle: 'View the complete agenda and timeline',
          onTap: () => _navigateToScreen(GuestRoutes.eventSchedule),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.event_seat,
          title: 'Seating Assignment',
          subtitle: 'Find your table and seat',
          onTap: () => _navigateToScreen(GuestRoutes.seatingAssignment),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.restaurant,
          title: 'Meal Preferences',
          subtitle: 'Update your dining choices',
          onTap: () => _navigateToScreen(GuestRoutes.mealPreferences),
        ),
        const SizedBox(height: 12),
        _buildFeatureCard(
          icon: Icons.card_giftcard,
          title: 'Gift Registry',
          subtitle: 'Browse host\'s wish list',
          onTap: () => _navigateToScreen(GuestRoutes.giftRegistry),
        ),
      ],
    );
  }

  Widget _buildGuestSetup() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Complete Your Guest Setup',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSetupStep(
              number: 1,
              title: 'RSVP Response',
              description: 'Confirm your attendance and bring additional guests',
              isCompleted: widget.invitation.respondedAt != null,
              onTap: () => _navigateToScreen(GuestRoutes.rsvp),
            ),
            const SizedBox(height: 12),
            _buildSetupStep(
              number: 2,
              title: 'Meal Preferences',
              description: 'Select your meal choice and dietary restrictions',
              isCompleted: false, // TODO: Check if meal preferences are set
              onTap: () => _navigateToScreen(GuestRoutes.mealPreferences),
            ),
            const SizedBox(height: 12),
            _buildSetupStep(
              number: 3,
              title: 'Seating Assignment',
              description: 'View your assigned table and seat',
              isCompleted: false, // TODO: Check if seating is assigned
              onTap: () => _navigateToScreen(GuestRoutes.seatingAssignment),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantInfo() {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  'Important Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '• Please arrive 15 minutes before the event starts\n'
              '• Bring your E-Ticket for easy entry\n'
              '• Parking information is available in the Event Map\n'
              '• Dietary preferences must be submitted 48 hours in advance\n'
              '• Contact the host for any special accommodations',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSetupStep({
    required int number,
    required String title,
    required String description,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? Colors.green
                  : Theme.of(context).colorScheme.primary.withOpacity(0.2),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      number.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                    color: isCompleted ? Colors.grey : null,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isCompleted ? Colors.grey[600] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }

  void _navigateToScreen(String route) {
    Navigator.pushNamed(
      context,
      route,
      arguments: {
        'event': widget.event,
        'invitation': widget.invitation,
      },
    );
  }

  void _navigateToInvitation() {
    Navigator.pushNamed(
      context,
      GuestRoutes.invitation,
      arguments: {'invitationCode': widget.invitation.invitationCode},
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guest Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Update Profile'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to profile update
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notification Settings'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to notification settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to help
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';
  }
}
