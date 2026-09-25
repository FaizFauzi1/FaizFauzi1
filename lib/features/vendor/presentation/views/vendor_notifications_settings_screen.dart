import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class VendorNotificationsSettingsScreen extends StatefulWidget {
  const VendorNotificationsSettingsScreen({super.key});

  @override
  State<VendorNotificationsSettingsScreen> createState() => _VendorNotificationsSettingsScreenState();
}

class _VendorNotificationsSettingsScreenState extends State<VendorNotificationsSettingsScreen> {
  // Notification preferences
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;

  // Notification types
  bool _bookingNotifications = true;
  bool _paymentNotifications = true;
  bool _reviewNotifications = true;
  bool _messageNotifications = true;
  bool _promotionNotifications = false;
  bool _systemNotifications = true;

  // Schedule settings
  bool _doNotDisturb = false;
  TimeOfDay? _dndStartTime;
  TimeOfDay? _dndEndTime;
  List<String> _workingDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notification Settings',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Notification channels
            _buildSectionHeader('Notification Channels'),
            _buildNotificationChannels(),

            const SizedBox(height: 24),

            // Notification types
            _buildSectionHeader('Notification Types'),
            _buildNotificationTypes(),

            const SizedBox(height: 24),

            // Do Not Disturb
            _buildSectionHeader('Do Not Disturb'),
            _buildDoNotDisturb(),

            const SizedBox(height: 24),

            // Working hours
            _buildSectionHeader('Working Hours'),
            _buildWorkingHours(),

            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                child: const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textPrimaryColor,
      ),
    );
  }

  Widget _buildNotificationChannels() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildChannelSwitch(
            'Email Notifications',
            'Receive notifications via email',
            _emailNotifications,
            (value) => setState(() => _emailNotifications = value),
            Icons.email,
          ),
          const Divider(),
          _buildChannelSwitch(
            'Push Notifications',
            'Receive push notifications on your device',
            _pushNotifications,
            (value) => setState(() => _pushNotifications = value),
            Icons.notifications,
          ),
          const Divider(),
          _buildChannelSwitch(
            'SMS Notifications',
            'Receive important notifications via SMS',
            _smsNotifications,
            (value) => setState(() => _smsNotifications = value),
            Icons.sms,
          ),
        ],
      ),
    );
  }

  Widget _buildChannelSwitch(String title, String subtitle, bool value, Function(bool) onChanged, IconData icon) {
    return SwitchListTile(
      title: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }

  Widget _buildNotificationTypes() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTypeSwitch(
            'New Bookings',
            'Get notified when customers make new bookings',
            _bookingNotifications,
            (value) => setState(() => _bookingNotifications = value),
            Icons.book_online,
          ),
          const Divider(),
          _buildTypeSwitch(
            'Payments',
            'Receive notifications for payment confirmations and issues',
            _paymentNotifications,
            (value) => setState(() => _paymentNotifications = value),
            Icons.payment,
          ),
          const Divider(),
          _buildTypeSwitch(
            'Reviews & Ratings',
            'Get notified when customers leave reviews',
            _reviewNotifications,
            (value) => setState(() => _reviewNotifications = value),
            Icons.star,
          ),
          const Divider(),
          _buildTypeSwitch(
            'Messages',
            'Receive notifications for new customer messages',
            _messageNotifications,
            (value) => setState(() => _messageNotifications = value),
            Icons.message,
          ),
          const Divider(),
          _buildTypeSwitch(
            'Promotions',
            'Marketing and promotional notifications',
            _promotionNotifications,
            (value) => setState(() => _promotionNotifications = value),
            Icons.campaign,
          ),
          const Divider(),
          _buildTypeSwitch(
            'System Updates',
            'Important system updates and maintenance notifications',
            _systemNotifications,
            (value) => setState(() => _systemNotifications = value),
            Icons.system_update,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSwitch(String title, String subtitle, bool value, Function(bool) onChanged, IconData icon) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: AppTheme.textSecondaryColor,
          fontSize: 12,
        ),
      ),
      secondary: Icon(icon, color: AppTheme.primaryColor),
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }

  Widget _buildDoNotDisturb() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'Do Not Disturb',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            subtitle: const Text(
              'Pause notifications during specified hours',
              style: TextStyle(
                color: AppTheme.textSecondaryColor,
                fontSize: 12,
              ),
            ),
            value: _doNotDisturb,
            onChanged: (value) => setState(() => _doNotDisturb = value),
            activeColor: AppTheme.primaryColor,
          ),
          if (_doNotDisturb) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _dndStartTime ?? const TimeOfDay(hour: 22, minute: 0),
                      );
                      if (time != null) {
                        setState(() => _dndStartTime = time);
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(_dndStartTime?.format(context) ?? 'Start Time'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _dndEndTime ?? const TimeOfDay(hour: 8, minute: 0),
                      );
                      if (time != null) {
                        setState(() => _dndEndTime = time);
                      }
                    },
                    icon: const Icon(Icons.access_time),
                    label: Text(_dndEndTime?.format(context) ?? 'End Time'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWorkingHours() {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
            'Select working days for notifications',
            style: TextStyle(
              color: AppTheme.textSecondaryColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: days.map((day) {
              final isSelected = _workingDays.contains(day);
              return FilterChip(
                label: Text(day.substring(0, 3)),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _workingDays.add(day);
                    } else {
                      _workingDays.remove(day);
                    }
                  });
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                checkmarkColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _saveSettings() {
    // In real app, save to backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification settings saved successfully'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }
}
