import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';

class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  String _selectedLanguage = 'English';
  String _selectedTheme = 'Light';
  String _selectedUnits = 'Metric';
  bool _autoSave = true;
  bool _showTips = true;
  bool _soundEffects = false;
  String _dateFormat = 'DD/MM/YYYY';
  String _timeFormat = '12-hour';
  String _currency = 'MYR';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Preferences"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'Display & Language',
            [
              _buildPreferenceItem(
                'Language',
                _selectedLanguage,
                Icons.language,
                () => _showLanguageDialog(context),
              ),
              _buildPreferenceItem(
                'Theme',
                _selectedTheme,
                Icons.dark_mode,
                () => _showThemeDialog(context),
              ),
              _buildPreferenceItem(
                'Units',
                _selectedUnits,
                Icons.straighten,
                () => _showUnitsDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Date & Time',
            [
              _buildPreferenceItem(
                'Date Format',
                _dateFormat,
                Icons.date_range,
                () => _showDateFormatDialog(context),
              ),
              _buildPreferenceItem(
                'Time Format',
                _timeFormat,
                Icons.access_time,
                () => _showTimeFormatDialog(context),
              ),
              _buildPreferenceItem(
                'Currency',
                _currency,
                Icons.attach_money,
                () => _showCurrencyDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'App Behavior',
            [
              SwitchListTile(
                title: const Text('Auto-save'),
                subtitle: const Text('Automatically save changes'),
                value: _autoSave,
                onChanged: (value) {
                  setState(() {
                    _autoSave = value;
                  });
                },
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.save, color: AppTheme.primaryColor, size: 20),
                ),
              ),
              SwitchListTile(
                title: const Text('Show Tips'),
                subtitle: const Text('Display helpful tips and hints'),
                value: _showTips,
                onChanged: (value) {
                  setState(() {
                    _showTips = value;
                  });
                },
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.lightbulb, color: AppTheme.primaryColor, size: 20),
                ),
              ),
              SwitchListTile(
                title: const Text('Sound Effects'),
                subtitle: const Text('Play sounds for interactions'),
                value: _soundEffects,
                onChanged: (value) {
                  setState(() {
                    _soundEffects = value;
                  });
                },
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.volume_up, color: AppTheme.primaryColor, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Accessibility',
            [
              _buildPreferenceItem(
                'Font Size',
                'Medium',
                Icons.text_fields,
                () => _showFontSizeDialog(context),
              ),
              _buildPreferenceItem(
                'High Contrast',
                'Standard',
                Icons.contrast,
                () => _showContrastDialog(context),
              ),
              _buildPreferenceItem(
                'Animation Speed',
                'Normal',
                Icons.speed,
                () => _showAnimationSpeedDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Data & Storage',
            [
              _buildPreferenceItem(
                'Cache Size',
                'Clear cache',
                Icons.cleaning_services,
                () => _clearCache(context),
              ),
              _buildPreferenceItem(
                'Offline Data',
                'Manage downloaded content',
                Icons.offline_share,
                () => _manageOfflineData(context),
              ),
              _buildPreferenceItem(
                'Storage Location',
                'Internal Storage',
                Icons.storage,
                () => _showStorageLocationDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.info, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      'Tip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your preferences are automatically saved and synced across all your devices.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceItem(String title, String value, IconData icon, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 14,
          color: AppTheme.textSecondaryColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
      onTap: onTap,
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              leading: Radio(
                value: 'English',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Bahasa Malaysia'),
              leading: Radio(
                value: 'Bahasa Malaysia',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('中文'),
              leading: Radio(
                value: '中文',
                groupValue: _selectedLanguage,
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Light'),
              leading: Radio(
                value: 'Light',
                groupValue: _selectedTheme,
                onChanged: (value) {
                  setState(() {
                    _selectedTheme = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Dark'),
              leading: Radio(
                value: 'Dark',
                groupValue: _selectedTheme,
                onChanged: (value) {
                  setState(() {
                    _selectedTheme = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('System'),
              leading: Radio(
                value: 'System',
                groupValue: _selectedTheme,
                onChanged: (value) {
                  setState(() {
                    _selectedTheme = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnitsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Units'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Metric'),
              leading: Radio(
                value: 'Metric',
                groupValue: _selectedUnits,
                onChanged: (value) {
                  setState(() {
                    _selectedUnits = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('Imperial'),
              leading: Radio(
                value: 'Imperial',
                groupValue: _selectedUnits,
                onChanged: (value) {
                  setState(() {
                    _selectedUnits = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDateFormatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Date Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('DD/MM/YYYY'),
              leading: Radio(
                value: 'DD/MM/YYYY',
                groupValue: _dateFormat,
                onChanged: (value) {
                  setState(() {
                    _dateFormat = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('MM/DD/YYYY'),
              leading: Radio(
                value: 'MM/DD/YYYY',
                groupValue: _dateFormat,
                onChanged: (value) {
                  setState(() {
                    _dateFormat = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('YYYY-MM-DD'),
              leading: Radio(
                value: 'YYYY-MM-DD',
                groupValue: _dateFormat,
                onChanged: (value) {
                  setState(() {
                    _dateFormat = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeFormatDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('12-hour'),
              leading: Radio(
                value: '12-hour',
                groupValue: _timeFormat,
                onChanged: (value) {
                  setState(() {
                    _timeFormat = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('24-hour'),
              leading: Radio(
                value: '24-hour',
                groupValue: _timeFormat,
                onChanged: (value) {
                  setState(() {
                    _timeFormat = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('MYR (Ringgit Malaysia)'),
              leading: Radio(
                value: 'MYR',
                groupValue: _currency,
                onChanged: (value) {
                  setState(() {
                    _currency = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('USD (US Dollar)'),
              leading: Radio(
                value: 'USD',
                groupValue: _currency,
                onChanged: (value) {
                  setState(() {
                    _currency = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: const Text('SGD (Singapore Dollar)'),
              leading: Radio(
                value: 'SGD',
                groupValue: _currency,
                onChanged: (value) {
                  setState(() {
                    _currency = value.toString();
                  });
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFontSizeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Font Size'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Small'),
              leading: Radio(
                value: 'Small',
                groupValue: 'Medium',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('Medium'),
              leading: Radio(
                value: 'Medium',
                groupValue: 'Medium',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('Large'),
              leading: Radio(
                value: 'Large',
                groupValue: 'Medium',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showContrastDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('High Contrast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Standard'),
              leading: Radio(
                value: 'Standard',
                groupValue: 'Standard',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('High Contrast'),
              leading: Radio(
                value: 'High Contrast',
                groupValue: 'Standard',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAnimationSpeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Animation Speed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Slow'),
              leading: Radio(
                value: 'Slow',
                groupValue: 'Normal',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('Normal'),
              leading: Radio(
                value: 'Normal',
                groupValue: 'Normal',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('Fast'),
              leading: Radio(
                value: 'Fast',
                groupValue: 'Normal',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('This will remove temporary files and free up storage space.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _manageOfflineData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offline Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Downloaded content:'),
            const SizedBox(height: 16),
            const Text('• 5 venues\n• 12 vendor profiles\n• 3 event templates'),
            const SizedBox(height: 16),
            const Text('Total size: 45 MB'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offline data updated')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showStorageLocationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Internal Storage'),
              subtitle: const Text('Store data on device'),
              leading: Radio(
                value: 'Internal',
                groupValue: 'Internal',
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('External Storage'),
              subtitle: const Text('Store data on SD card'),
              leading: Radio(
                value: 'External',
                groupValue: 'Internal',
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
