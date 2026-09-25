import 'package:flutter/material.dart';
import 'package:eventease/features/event/data/models/event.dart';
import 'package:eventease/features/event/data/models/event_schedule_item.dart';

class EventScheduleScreen extends StatelessWidget {
  final Event event;
  final List<EventScheduleItem> scheduleItems;

  const EventScheduleScreen({
    super.key,
    required this.event,
    required this.scheduleItems,
  });

  @override
  Widget build(BuildContext context) {
    // Check if event schedule feature is enabled
    final guestFeatures = event.additionalInfo['guestFeatures'] as Map<String, dynamic>? ?? {};
    final isEventScheduleEnabled = guestFeatures['Event Schedule'] ?? true;

    if (!isEventScheduleEnabled) {
      return Scaffold(
        appBar: AppBar(
          title: Text('${event.title} Schedule'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
        body: _buildFeatureDisabledState('Event Schedule'),
      );
    }

    final sortedItems = List<EventScheduleItem>.from(scheduleItems)
      ..sort((a, b) => a.order.compareTo(b.order));

    return Scaffold(
      appBar: AppBar(
        title: Text('${event.title} Schedule'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedItems.length,
        itemBuilder: (context, index) {
          final item = sortedItems[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: item.color,
                child: Icon(
                  item.icon,
                  color: Colors.white,
                ),
              ),
              title: Text(
                item.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.description != null) ...[
                    Text(item.description!),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    '${_formatTime(item.startTime)} - ${_formatTime(item.endTime)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (item.location != null) ...[
                    const SizedBox(height: 4),
                    Text('Location: ${item.location!}'),
                  ],
                  if (item.speaker != null) ...[
                    const SizedBox(height: 4),
                    Text('Speaker: ${item.speaker!}'),
                  ],
                ],
              ),
              trailing: item.isRequired
                  ? const Icon(Icons.star, color: Colors.amber)
                  : null,
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = time.minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $amPm';
  }

  Widget _buildFeatureDisabledState(String featureName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '$featureName Disabled',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This feature has been disabled by the event host.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
