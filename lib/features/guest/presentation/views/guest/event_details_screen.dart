import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/event/data/providers/event_provider.dart';
import 'package:eventease/core/utils/guest_routes.dart';

class EventDetailsScreen extends StatefulWidget {
  final Event event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final event = widget.event;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Header with Event Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: event.coverImage != null
                  ? Image.network(
                      event.coverImage!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.celebration,
                        size: 80,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
            ),
            title: Text(event.title),
            actions: [
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () => _shareEvent(context),
              ),
            ],
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Event Title and Basic Info
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),

                  const SizedBox(height: 24),

                  // Date & Time Section
                  _buildDateTimeSection(),

                  const SizedBox(height: 16),

                  // Venue Section
                  _buildVenueSection(),

                  const SizedBox(height: 16),

                  // Event Details Section
                  _buildEventDetailsSection(),

                  const SizedBox(height: 16),

                  // Host Information
                  _buildHostInfoSection(),

                  const SizedBox(height: 24),

                  // Action Buttons
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Date & Time',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatDate(widget.event.date),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(widget.event.startTime),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (widget.event.endTime != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Ends at ${_formatTime(widget.event.endTime!)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.event_available),
                  onPressed: () => _addToCalendar(context),
                  tooltip: 'Add to Calendar',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Venue',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.event.venue.name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              widget.event.venue.location,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (widget.event.venue.contactInfo['phone'] != null) ...[
              const SizedBox(height: 4),
              Text(
                widget.event.venue.contactInfo['phone'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openMap(context),
                    icon: const Icon(Icons.map),
                    label: const Text('View on Map'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _getDirections(context),
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Details',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Event Type & Theme
            Row(
              children: [
                Icon(
                  widget.event.type.icon,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.event.type.displayName,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                if (widget.event.theme != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.palette,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.event.theme!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 12),

            // Dress Code
            if (widget.event.dressCode != null) ...[
              Row(
                children: [
                  Icon(
                    Icons.checkroom,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dress Code: ${widget.event.dressCode!}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Max Guests
            Row(
              children: [
                Icon(
                  Icons.people,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Max Guests: ${widget.event.maxGuests}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Additional Information
            if (widget.event.additionalInfo != null && widget.event.additionalInfo!.isNotEmpty) ...[
              Text(
                'Additional Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.event.additionalInfo.toString(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHostInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Host Information',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: widget.event.hostProfileImage != null
                      ? ClipOval(
                          child: Image.network(
                            widget.event.hostProfileImage!,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.event.hostName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (widget.event.hostEmail != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.event.hostEmail!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      if (widget.event.hostPhone != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          widget.event.hostPhone!,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: () => _navigateToGiftRegistry(context),
          icon: const Icon(Icons.card_giftcard),
          label: const Text('View Gift Registry'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _navigateToSchedule(context),
          icon: const Icon(Icons.schedule),
          label: const Text('View Event Schedule'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _navigateToPhotoSharing(context),
          icon: const Icon(Icons.photo_camera),
          label: const Text('Photo Sharing'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 0 && difference <= 7) {
      return 'In $difference days';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : time.hour;
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $amPm';
  }

  void _shareEvent(BuildContext context) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _addToCalendar(BuildContext context) {
    // TODO: Implement add to calendar functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add to calendar functionality coming soon!')),
    );
  }

  void _openMap(BuildContext context) {
    // TODO: Implement map functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map functionality coming soon!')),
    );
  }

  void _getDirections(BuildContext context) {
    // TODO: Implement directions functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Directions functionality coming soon!')),
    );
  }

  void _navigateToGiftRegistry(BuildContext context) {
    Navigator.of(context).pushNamed(
      GuestRoutes.giftRegistry,
      arguments: {'event': widget.event},
    );
  }

  void _navigateToSchedule(BuildContext context) {
    Navigator.of(context).pushNamed(
      GuestRoutes.eventSchedule,
      arguments: {'event': widget.event},
    );
  }

  void _navigateToPhotoSharing(BuildContext context) {
    Navigator.of(context).pushNamed(
      GuestRoutes.photoSharing,
      arguments: {'event': widget.event},
    );
  }
}
