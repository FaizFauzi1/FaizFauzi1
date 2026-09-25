import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class CalendarIntegrationScreen extends StatefulWidget {
  const CalendarIntegrationScreen({super.key});

  @override
  State<CalendarIntegrationScreen> createState() => _CalendarIntegrationScreenState();
}

class _CalendarIntegrationScreenState extends State<CalendarIntegrationScreen> {
  bool _googleCalendarEnabled = false;
  bool _appleCalendarEnabled = false;
  bool _outlookCalendarEnabled = false;
  
  List<Map<String, dynamic>> _reminders = [
    {
      'id': '1',
      'title': 'Wedding Catering Meeting',
      'date': DateTime.now().add(const Duration(days: 2)),
      'time': '10:00 AM',
      'type': 'appointment',
      'reminderTime': '1 hour before',
      'enabled': true,
    },
    {
      'id': '2',
      'title': 'Photography Session',
      'date': DateTime.now().add(const Duration(days: 5)),
      'time': '2:00 PM',
      'type': 'appointment',
      'reminderTime': '30 minutes before',
      'enabled': true,
    },
    {
      'id': '3',
      'title': 'Venue Site Visit',
      'date': DateTime.now().add(const Duration(days: 7)),
      'time': '11:00 AM',
      'type': 'appointment',
      'reminderTime': '1 day before',
      'enabled': true,
    },
    {
      'id': '4',
      'title': 'Return Rental Items',
      'date': DateTime.now().add(const Duration(days: 10)),
      'time': '5:00 PM',
      'type': 'rental',
      'reminderTime': '2 hours before',
      'enabled': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Calendar Integration',
          style: TextStyle(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCalendarServices(),
            const SizedBox(height: 24),
            _buildReminderSettings(),
            const SizedBox(height: 24),
            _buildUpcomingReminders(),
            const SizedBox(height: 24),
            _buildSyncOptions(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarServices() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Calendar Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildCalendarService(
            'Google Calendar',
            'Sync with your Google Calendar',
            Icons.calendar_today,
            _googleCalendarEnabled,
            (value) => setState(() => _googleCalendarEnabled = value),
          ),
          const SizedBox(height: 16),
          _buildCalendarService(
            'Apple Calendar',
            'Sync with your Apple Calendar',
            Icons.apple,
            _appleCalendarEnabled,
            (value) => setState(() => _appleCalendarEnabled = value),
          ),
          const SizedBox(height: 16),
          _buildCalendarService(
            'Outlook Calendar',
            'Sync with your Outlook Calendar',
            Icons.email,
            _outlookCalendarEnabled,
            (value) => setState(() => _outlookCalendarEnabled = value),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarService(String title, String subtitle, IconData icon, bool enabled, Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: enabled ? AppTheme.primaryColor.withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: enabled ? AppTheme.primaryColor : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: enabled ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: enabled ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: enabled ? AppTheme.primaryColor.withOpacity(0.7) : AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reminder Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildReminderOption('Appointments', '15 minutes before'),
          const SizedBox(height: 12),
          _buildReminderOption('Site Visits', '1 hour before'),
          const SizedBox(height: 12),
          _buildReminderOption('Rental Returns', '2 hours before'),
          const SizedBox(height: 12),
          _buildReminderOption('Payment Due', '1 day before'),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _customizeReminders,
              icon: const Icon(Icons.settings),
              label: const Text('Customize Reminders'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderOption(String title, String time) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimaryColor,
            ),
          ),
        ),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right,
          color: AppTheme.textSecondaryColor,
          size: 20,
        ),
      ],
    );
  }

  Widget _buildUpcomingReminders() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Upcoming Reminders',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _viewAllReminders,
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._reminders.take(3).map((reminder) => _buildReminderItem(reminder)).toList(),
        ],
      ),
    );
  }

  Widget _buildReminderItem(Map<String, dynamic> reminder) {
    final date = reminder['date'] as DateTime;
    final isToday = date.difference(DateTime.now()).inDays == 0;
    final isTomorrow = date.difference(DateTime.now()).inDays == 1;
    
    String dateText;
    if (isToday) {
      dateText = 'Today';
    } else if (isTomorrow) {
      dateText = 'Tomorrow';
    } else {
      dateText = '${date.difference(DateTime.now()).inDays} days';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: reminder['type'] == 'appointment' 
            ? AppTheme.primaryColor.withOpacity(0.1)
            : AppTheme.secondaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: reminder['type'] == 'appointment' 
              ? AppTheme.primaryColor
              : AppTheme.secondaryColor,
        ),
      ),
      child: Row(
        children: [
          Icon(
            reminder['type'] == 'appointment' ? Icons.event : Icons.inventory,
            color: reminder['type'] == 'appointment' 
                ? AppTheme.primaryColor
                : AppTheme.secondaryColor,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      dateText,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'at ${reminder['time']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Reminder: ${reminder['reminderTime']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: reminder['enabled'],
            onChanged: (value) => _toggleReminder(reminder['id'], value),
            activeColor: reminder['type'] == 'appointment' 
                ? AppTheme.primaryColor
                : AppTheme.secondaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncOptions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sync Options',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildSyncOption(
            'Auto-sync every 15 minutes',
            'Keep your calendar up to date automatically',
            true,
          ),
          const SizedBox(height: 12),
          _buildSyncOption(
            'Sync on app open',
            'Update calendar when you open the app',
            true,
          ),
          const SizedBox(height: 12),
          _buildSyncOption(
            'Manual sync only',
            'Sync only when you manually refresh',
            false,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _syncNow,
                  icon: const Icon(Icons.sync),
                  label: const Text('Sync Now'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _exportCalendar,
                  icon: const Icon(Icons.download),
                  label: const Text('Export'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSyncOption(String title, String subtitle, bool enabled) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
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
        Radio<bool>(
          value: enabled,
          groupValue: true, // For demo, always show first option as selected
          onChanged: (value) {},
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  void _customizeReminders() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Customize Reminders'),
        content: const Text('This would open a detailed reminder customization screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewAllReminders() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Reminders'),
        content: const Text('This would show all upcoming reminders in a list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _toggleReminder(String id, bool enabled) {
    setState(() {
      final reminder = _reminders.firstWhere((r) => r['id'] == id);
      reminder['enabled'] = enabled;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reminder ${enabled ? 'enabled' : 'disabled'}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _syncNow() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing calendar...'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _exportCalendar() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Calendar'),
        content: const Text('Choose export format and date range.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Calendar exported successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}













