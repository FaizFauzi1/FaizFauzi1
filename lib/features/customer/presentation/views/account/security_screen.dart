import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/core/services/security_service.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:intl/intl.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _activeSessions = [];
  List<Map<String, dynamic>> _securityLogs = [];
  
  // Settings (fetched from preferences)
  bool _twoFactorEnabled = false;
  bool _biometricEnabled = false;
  bool _loginNotifications = true;
  bool _isProfilePublic = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      // Proactively record the current session to ensure the list is never empty
      await SecurityService.recordCurrentSession();
      
      final sessions = await SecurityService.getActiveSessions();
      final logs = await SecurityService.getRecentLogs();
      
      // Load user preferences for privacy
      final user = SupabaseService.client.auth.currentUser;
      if (user != null) {
        final response = await SupabaseService.client
            .from('users')
            .select('preferences')
            .eq('id', user.id)
            .single();
        
        final prefs = response['preferences'] as Map<String, dynamic>? ?? {};
        setState(() {
          _isProfilePublic = prefs['is_profile_public'] ?? true;
          _loginNotifications = prefs['login_notifications'] ?? true;
          _biometricEnabled = prefs['biometric_enabled'] ?? false;
          _twoFactorEnabled = prefs['two_factor_enabled'] ?? false;
        });
      }

      setState(() {
        _activeSessions = sessions;
        _securityLogs = logs;
      });
    } catch (e) {
      debugPrint('Error loading security data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text("Security & Privacy"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppTheme.textPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAllData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                   _buildSection(
                    'Password & Authentication',
                    [
                      _buildSecurityItem(
                        'Change Password',
                        'Maintain a strong password',
                        Icons.lock,
                        () => _showChangePasswordDialog(context),
                      ),
                      _buildSecurityItem(
                        'Two-Factor Authentication',
                        _twoFactorEnabled ? 'Securely Enabled' : 'Disabled (Recommended)',
                        Icons.security,
                        () => _toggleSetting('two_factor_enabled', !_twoFactorEnabled),
                        trailing: Switch(
                          value: _twoFactorEnabled,
                          onChanged: (val) => _toggleSetting('two_factor_enabled', val),
                        ),
                      ),
                      _buildSecurityItem(
                        'Biometric Login',
                        'Use Fingerprint/Face ID',
                        Icons.fingerprint,
                        () => _toggleSetting('biometric_enabled', !_biometricEnabled),
                        trailing: Switch(
                          value: _biometricEnabled,
                          onChanged: (val) => _toggleSetting('biometric_enabled', val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  _buildSection(
                    'Device Management',
                    [
                      if (_activeSessions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No active sessions found.'),
                        )
                      else
                        ..._activeSessions.map((session) => ListTile(
                          leading: Icon(
                            _getPlatformIcon(session['platform']),
                            color: AppTheme.primaryColor,
                          ),
                          title: Text(session['device_name'] ?? 'Unknown Device'),
                          subtitle: Text(
                            'Last active: ${_formatDate(session['last_active_at'])}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.logout),
                          label: const Text('Sign out from all other devices'),
                          onPressed: _handleLogoutOthers,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    'Privacy Controls',
                    [
                      _buildSecurityItem(
                        'Public Profile',
                        'Control who sees your profile',
                        Icons.visibility,
                        () => _toggleSetting('is_profile_public', !_isProfilePublic),
                        trailing: Switch(
                          value: _isProfilePublic,
                          onChanged: (val) => _toggleSetting('is_profile_public', val),
                        ),
                      ),
                      _buildSecurityItem(
                        'Security Notifications',
                        'Alerts for new logins',
                        Icons.notifications_active,
                        () => _toggleSetting('login_notifications', !_loginNotifications),
                        trailing: Switch(
                          value: _loginNotifications,
                          onChanged: (val) => _toggleSetting('login_notifications', val),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildSection(
                    'Audit Log',
                    [
                      if (_securityLogs.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No security events logged yet.'),
                        )
                      else
                        ..._securityLogs.map((log) => ListTile(
                          dense: true,
                          title: Text(log['event_type'].toString().toUpperCase()),
                          subtitle: Text(log['description'] ?? ''),
                          trailing: Text(
                            _formatDateShort(log['created_at']),
                            style: const TextStyle(fontSize: 10),
                          ),
                        )),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  _buildDangerZone(),
                ],
              ),
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

  Widget _buildSecurityItem(String title, String value, IconData icon, VoidCallback onTap, {Widget? trailing}) {
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
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
      onTap: onTap,
    );
  }

  Widget _buildDangerZone() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Deleting your account will hide your profile. You can reactivate it within 30 days.',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showDeleteAccountDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Deactivate Account (Soft Delete)'),
            ),
          ),
        ],
      ),
    );
  }

  // --- Handlers ---

  Future<void> _toggleSetting(String key, bool value) async {
    setState(() => _isLoading = true);
    try {
      await SecurityService.updatePrivacySetting(key, value);
      await _loadAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${key.replaceAll('_', ' ')} updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update setting: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogoutOthers() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out others?'),
        content: const Text('This will log you out from all other active sessions and browsers.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out Others', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await SecurityService.logoutOtherDevices();
        await _loadAllData();
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _showChangePasswordDialog(BuildContext context) {
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your new password below. It must be at least 6 characters.'),
            const SizedBox(height: 16),
            TextField(
              controller: newPassController,
              decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPassController,
              decoration: const InputDecoration(labelText: 'Confirm Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (newPassController.text.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password too short')));
                return;
              }
              if (newPassController.text != confirmPassController.text) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
                return;
              }
              
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await SecurityService.updatePassword(newPassController.text);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated successfully!')));
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('Update Password'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final confirmController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Soft Delete Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This will deactivate your account and log you out immediately. You have 30 days to recover it.'),
            const SizedBox(height: 16),
            TextField(
              controller: confirmController,
              decoration: const InputDecoration(labelText: 'Type "DELETE" to confirm', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (confirmController.text != 'DELETE') return;
              Navigator.pop(context);
              setState(() => _isLoading = true);
              try {
                await SecurityService.softDeleteAccount();
                // Logout happens automatically inside service
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  // --- Utils ---

  IconData _getPlatformIcon(String? platform) {
    switch (platform?.toLowerCase()) {
      case 'android': return Icons.android;
      case 'ios': return Icons.apple;
      case 'web': return Icons.public;
      case 'windows': return Icons.desktop_windows;
      default: return Icons.device_unknown;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Never';
    final dt = DateTime.parse(date.toString());
    return DateFormat('MMM dd, yyyy HH:mm').format(dt);
  }

  String _formatDateShort(dynamic date) {
    if (date == null) return '';
    final dt = DateTime.parse(date.toString());
    return DateFormat('dd/MM HH:mm').format(dt);
  }
}
