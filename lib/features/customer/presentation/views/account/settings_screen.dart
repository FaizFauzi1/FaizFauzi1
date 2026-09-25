import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/providers/country_provider.dart';
import 'package:eventease/core/providers/theme_provider.dart';
import 'package:eventease/shared/views/privacy_policy_screen.dart';
import 'package:eventease/shared/views/terms_of_service_screen.dart';
import 'package:eventease/shared/views/help_center_screen.dart';
import 'package:eventease/shared/widgets/design_system/shimmer_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final countryProvider = context.watch<CountryProvider>();
    final country = countryProvider.selectedCountry;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimaryColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            'General',
            [
              CountrySelector(
                value: countryProvider.selectedCountryCode,
                onChanged: (code) async {
                  await countryProvider.setCountry(code);
                  setState(() {});
                },
              ),
              const Divider(height: 1),
              _buildSettingItem(
                'Currency',
                country.currencyCode,
                Icons.attach_money,
                () => _showCurrencyInfo(context, country.currencyCode),
              ),
              _buildSettingItem(
                'Language',
                'English',
                Icons.language,
                () => _showLanguageDialog(context),
              ),
              _buildSettingItem(
                'Theme',
                context.watch<ThemeProvider>().themeMode.name,
                Icons.dark_mode,
                () => _showThemeDialog(context),
              ),
              _buildSettingItem(
                'Help Center',
                'FAQs & support',
                Icons.help_outline,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                ),
              ),
              _buildSettingItem(
                'Units',
                'Metric',
                Icons.straighten,
                () => _showUnitsDialog(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Notifications',
            [
              _buildSettingItem(
                'Push Notifications',
                'Enabled',
                Icons.notifications,
                () => _togglePushNotifications(context),
              ),
              _buildSettingItem(
                'Email Notifications',
                'Enabled',
                Icons.email,
                () => _toggleEmailNotifications(context),
              ),
              _buildSettingItem(
                'SMS Notifications',
                'Disabled',
                Icons.sms,
                () => _toggleSMSNotifications(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Privacy',
            [
              _buildSettingItem(
                'Profile Visibility',
                'Public',
                Icons.visibility,
                () => _showPrivacyDialog(context),
              ),
              _buildSettingItem(
                'Data Sharing',
                'Disabled',
                Icons.share,
                () => _toggleDataSharing(context),
              ),
              _buildSettingItem(
                'Analytics',
                'Enabled',
                Icons.analytics,
                () => _toggleAnalytics(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Account',
            [
              _buildSettingItem(
                'Account Type',
                'Premium',
                Icons.account_circle,
                () => _showAccountTypeDialog(context),
              ),
              _buildSettingItem(
                'Storage Used',
                '2.4 GB / 10 GB',
                Icons.storage,
                () => _showStorageDialog(context),
              ),
              _buildSettingItem(
                'Export Data',
                'Available',
                Icons.download,
                () => _exportData(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSection(
            'Legal',
            [
              _buildSettingItem(
                'Privacy Policy',
                'How we handle your data',
                Icons.privacy_tip,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),
              _buildSettingItem(
                'Terms of Service',
                'Your rights and obligations',
                Icons.gavel,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TermsOfServiceScreen(initialTab: 2),
                  ),
                ),
              ),
              _buildSettingItem(
                'Cookie Policy',
                'How we use cookies',
                Icons.cookie,
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PrivacyPolicyScreen(),
                  ),
                ),
              ),
            ],
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

  Widget _buildSettingItem(String title, String value, IconData icon, VoidCallback onTap) {
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

  void _showCurrencyInfo(BuildContext context, String currency) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Currency'),
        content: Text(
          'Currency is set automatically based on your country ($currency). '
          'Change your country above to update pricing display.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
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
              leading: Radio(value: 'en', groupValue: 'en', onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('Bahasa Malaysia'),
              leading: Radio(value: 'ms', groupValue: 'en', onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('中文'),
              leading: Radio(value: 'zh', groupValue: 'en', onChanged: (value) {}),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Light'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (v) {
                themeProvider.setThemeMode(v!);
                Navigator.pop(ctx);
                setState(() {});
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (v) {
                themeProvider.setThemeMode(v!);
                Navigator.pop(ctx);
                setState(() {});
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('System'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (v) {
                themeProvider.setThemeMode(v!);
                Navigator.pop(ctx);
                setState(() {});
              },
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
              leading: Radio(value: 'metric', groupValue: 'metric', onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('Imperial'),
              leading: Radio(value: 'imperial', groupValue: 'metric', onChanged: (value) {}),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _togglePushNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Push notifications toggled')),
    );
  }

  void _toggleEmailNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email notifications toggled')),
    );
  }

  void _toggleSMSNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('SMS notifications toggled')),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Visibility'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Public'),
              leading: Radio(value: 'public', groupValue: 'public', onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('Private'),
              leading: Radio(value: 'private', groupValue: 'public', onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('Friends Only'),
              leading: Radio(value: 'friends', groupValue: 'public', onChanged: (value) {}),
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
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _toggleDataSharing(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data sharing toggled')),
    );
  }

  void _toggleAnalytics(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics toggled')),
    );
  }

  void _showAccountTypeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Type'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Free'),
              subtitle: const Text('Basic features'),
              leading: Radio(value: 'free', groupValue: 'premium', onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('Premium'),
              subtitle: const Text('Advanced features'),
              leading: Radio(value: 'premium', groupValue: 'premium', onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('Business'),
              subtitle: const Text('All features + support'),
              leading: Radio(value: 'business', groupValue: 'premium', onChanged: (value) {}),
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
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _showStorageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Storage Usage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LinearProgressIndicator(
              value: 0.24,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
            ),
            const SizedBox(height: 16),
            const Text('2.4 GB used of 10 GB'),
            const SizedBox(height: 16),
            const Text('Upgrade for more storage space.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data export started. You will receive an email when ready.')),
    );
  }
}
