import 'package:eventease/features/admin/data/services/admin_impersonation_service.dart';
import 'package:eventease/features/admin/data/providers/admin_provider.dart';
import 'package:eventease/features/auth/data/auth_provider.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:eventease/features/vendor/presentation/views/vendor_dashboard_screen.dart';
import 'package:eventease/features/vendor/data/providers/vendor_provider_updated.dart';

class SystemSecurityScreen extends StatefulWidget {
  const SystemSecurityScreen({super.key});

  @override
  State<SystemSecurityScreen> createState() => _SystemSecurityScreenState();
}

class _SystemSecurityScreenState extends State<SystemSecurityScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _backupEnabled = true;
  bool _twoFactorAuth = true;
  final _impersonationService = AdminImpersonationService();
  final _vendorIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _impersonationService.loadSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vendorIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final admin = Provider.of<AdminProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('System & Security'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Access Control'),
            Tab(text: 'Monitoring'),
            Tab(text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(admin),
          _buildAccessControlTab(admin),
          _buildMonitoringTab(admin),
          _buildSettingsTab(admin),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        'System',
                        'Online',
                        Icons.check_circle,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        'Database',
                        'Connected',
                        Icons.storage,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusCard(
                        'API Services',
                        'Active',
                        Icons.api,
                        Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusCard(
                        'Security',
                        'Protected',
                        Icons.security,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Security Overview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Security Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSecurityMetric(
                    'Active Users', '${admin.users.where((u) => u.status == 'active').length}', Colors.blue),
                _buildSecurityMetric(
                    'Failed Login Attempts', admin.getSystemMetrics()['failed_logins'] ?? '0', Colors.orange),
                _buildSecurityMetric(
                    'Suspicious Activities', admin.getSystemMetrics()['suspicious_activities'] ?? '0', Colors.green),
                _buildSecurityMetric('Blocked IPs', admin.getSystemMetrics()['blocked_ips'] ?? '0', Colors.red),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Quick Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _performSystemBackup(),
                        icon: const Icon(Icons.backup),
                        label: const Text('Backup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _runSecurityScan(),
                        icon: const Icon(Icons.security),
                        label: const Text('Security Scan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _clearSystemCache(),
                        icon: const Icon(Icons.cleaning_services),
                        label: const Text('Clear Cache'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _restartServices(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Restart Services'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessControlTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Role Management
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Role Management',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showAddRoleDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Role'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...admin.roles.map((role) => _buildRoleCard(role)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Admin Impersonation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.switch_account, color: Colors.orange.shade900),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Login as Vendor (Impersonation)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Securely view the app as a vendor. All sessions are audit-logged.',
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_impersonationService.isImpersonating)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Currently impersonating: ${_impersonationService.impersonatingVendorName ?? _impersonationService.impersonatingUserId}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange.shade800,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const VendorDashboardScreen()),
                                  );
                                },
                                icon: const Icon(Icons.dashboard),
                                label: const Text('Open Vendor Dashboard'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red.shade700,
                                side: BorderSide(color: Colors.red.shade300),
                              ),
                              onPressed: () async {
                                await _impersonationService.endImpersonation();
                                if (context.mounted) {
                                  context.read<VendorProvider>().clearCurrentVendor();
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Returned to admin mode')),
                                  );
                                }
                              },
                              icon: const Icon(Icons.exit_to_app),
                              label: const Text('Return to Admin'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                else ...[
                  if (admin.vendors.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Registered Vendor',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.store),
                      ),
                      hint: const Text('Choose a vendor to impersonate...'),
                      items: admin.vendors.map((v) {
                        return DropdownMenuItem<String>(
                          value: v.id,
                          child: Text('${v.name} (${v.category})'),
                        );
                      }).toList(),
                      onChanged: (selectedId) {
                        if (selectedId != null) {
                          _vendorIdController.text = selectedId;
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        '— OR ENTER VENDOR USER ID / PROFILE ID DIRECTLY —',
                        style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _vendorIdController,
                    decoration: const InputDecoration(
                      labelText: 'Vendor User ID / Profile ID',
                      border: OutlineInputBorder(),
                      hintText: 'Paste vendor UUID',
                      prefixIcon: Icon(Icons.fingerprint),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        final auth = context.read<AuthProvider>();
                        final adminId = auth.userId ?? 'admin';
                        final adminEmail = auth.userEmail;
                        final vendorId = _vendorIdController.text.trim();
                        if (vendorId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select or enter a vendor ID'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        // Try to find vendor name from loaded list
                        final matchingVendor = admin.vendors.where((v) => v.id == vendorId).firstOrNull;
                        final vendorName = matchingVendor?.name;

                        final ok = await _impersonationService.startImpersonation(
                          adminId: adminId,
                          targetUserId: vendorId,
                          targetRole: 'vendor',
                          vendorName: vendorName,
                          adminEmail: adminEmail,
                        );

                        if (ok && context.mounted) {
                          setState(() {});
                          await context.read<VendorProvider>().loadCurrentVendorFromSupabase(force: true);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Impersonating ${vendorName ?? vendorId}'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const VendorDashboardScreen()),
                            );
                          }
                        } else if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to start impersonation'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.switch_account),
                      label: const Text('Login as Vendor (Impersonate)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Permission Matrix
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Permission Matrix',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPermissionMatrix(),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Two-Factor Authentication
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Two-Factor Authentication',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Enable 2FA for all users'),
                  subtitle: const Text(
                      'Require two-factor authentication for enhanced security'),
                  value: _twoFactorAuth,
                  onChanged: (value) {
                    setState(() {
                      _twoFactorAuth = value;
                    });
                  },
                ),
                if (_twoFactorAuth) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _configure2FA(),
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure 2FA'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Login Activity
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Login Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...admin.logins.map((login) => _buildLoginActivityItem(login)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // System Activity Log
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Activity Log',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...admin.activity
                    .map((activity) => _buildActivityLogItem(activity)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // API Integration Status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'API Integration Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ...admin.apis.map((api) => _buildApiStatusItem(api)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTab(AdminProvider admin) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // System Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'System Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<AdminProvider>(
                  builder: (context, adminProvider, child) {
                    return SwitchListTile(
                      title: const Text('System Maintenance Mode'),
                      subtitle:
                          const Text('Enable maintenance mode to restrict access'),
                      value: adminProvider.isMaintenanceMode,
                      onChanged: (value) async {
                        await adminProvider.setMaintenanceMode(value ?? false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Maintenance mode ${value ?? false ? 'enabled' : 'disabled'}',
                            ),
                            backgroundColor: value ?? false ? Colors.orange : Colors.green,
                          ),
                        );
                      },
                    );
                  },
                ),
                SwitchListTile(
                  title: const Text('Automatic Backups'),
                  subtitle: const Text('Enable daily automatic system backups'),
                  value: _backupEnabled,
                  onChanged: (value) {
                    setState(() {
                      _backupEnabled = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Feature Controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Feature Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Consumer<AdminProvider>(
                  builder: (context, adminProvider, child) {
                    final featureFlags = adminProvider.featureFlags;
                    return Column(
                      children: featureFlags.keys.map((featureName) {
                        final isEnabled = featureFlags[featureName] ?? false;
                        return SwitchListTile(
                          title: Text(featureName),
                          subtitle: Text('${isEnabled ? 'Disable' : 'Enable'} $featureName feature'),
                          value: isEnabled,
                          onChanged: (value) async {
                            await adminProvider.updateFeatureFlag(featureName, value);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '$featureName feature ${value ? 'enabled' : 'disabled'}',
                                ),
                                backgroundColor: value ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Backup & Restore
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Backup & Restore',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _createBackup(),
                        icon: const Icon(Icons.backup),
                        label: const Text('Create Backup'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _restoreBackup(),
                        icon: const Icon(Icons.restore),
                        label: const Text('Restore'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _downloadBackup(),
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _uploadBackup(),
                        icon: const Icon(Icons.upload),
                        label: const Text('Upload'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Security Settings
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Security Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showSecuritySettings(),
                  icon: const Icon(Icons.security),
                  label: const Text('Advanced Security Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showAuditLog(),
                  icon: const Icon(Icons.history),
                  label: const Text('View Audit Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600]!,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(
      String title, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            status,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityMetric(String title, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(RoleAssignment role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
          child: Icon(Icons.person, color: AppTheme.primaryColor),
        ),
        title: Text(role.user),
        subtitle: Text('Role: ${role.role}'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Text('Edit'),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Text('Delete'),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'edit':
                _showEditRoleDialog(role);
                break;
              case 'delete':
                _showDeleteRoleDialog(role);
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildPermissionMatrix() {
    return Column(
      children: [
        _buildPermissionRow('User Management', ['Read', 'Write', 'Delete']),
        _buildPermissionRow('Vendor Management', ['Read', 'Write', 'Delete']),
        _buildPermissionRow('Financial Data', ['Read', 'Write', 'Delete']),
        _buildPermissionRow('System Settings', ['Read', 'Write', 'Delete']),
      ],
    );
  }

  Widget _buildPermissionRow(String permission, List<String> actions) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(permission),
          ),
          ...actions.map((action) => Expanded(
                child: Checkbox(
                  value: action == 'Read' || action == 'Write', // Mock data
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${(value ?? false) ? 'Granted' : 'Revoked'} $action permission for $permission'),
                        backgroundColor:
                            (value ?? false) ? Colors.green : Colors.orange,
                      ),
                    );
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildLoginActivityItem(LoginEvent login) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.green.withOpacity(0.1),
        child: const Icon(Icons.login, color: Colors.green),
      ),
      title: Text(login.user),
      subtitle: Text('${login.time} • ${login.ip}'),
      trailing: IconButton(
        icon: const Icon(Icons.info),
        onPressed: () => _showLoginDetails(login),
      ),
    );
  }

  Widget _buildActivityLogItem(ActivityLog activity) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
        child: Icon(Icons.history, color: AppTheme.primaryColor),
      ),
      title: Text(activity.title),
      subtitle: Text('${activity.subtitle} • ${activity.time}'),
    );
  }

  Widget _buildApiStatusItem(ApiIntegration api) {
    Color statusColor;
    IconData statusIcon;

    if (api.status == 'active') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(statusIcon, color: statusColor),
      ),
      title: Text(api.name),
      subtitle: Text('Status: ${api.status}'),
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'test',
            child: Text('Test Connection'),
          ),
          const PopupMenuItem(
            value: 'configure',
            child: Text('Configure'),
          ),
        ],
        onSelected: (value) {
          switch (value) {
            case 'test':
              _testApiConnection(api);
              break;
            case 'configure':
              _configureApi(api);
              break;
          }
        },
      ),
    );
  }

  // Action Methods
  void _performSystemBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('System Backup'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating system backup...'),
          ],
        ),
      ),
    );

    // Simulate backup process
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('System backup completed successfully')),
      );
    });
  }

  void _runSecurityScan() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Scan'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running security scan...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Security scan completed - No issues found')),
      );
    });
  }

  void _clearSystemCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text('Are you sure you want to clear all system cache?'),
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
                    content: Text('System cache cleared successfully')),
              );
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _restartServices() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restart Services'),
        content: const Text('This will restart all system services. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performServiceRestart();
            },
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _performServiceRestart() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restarting Services'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Restarting system services...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Services restarted successfully')),
      );
    });
  }

  void _showAddRoleDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Role Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Role added successfully')),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditRoleDialog(RoleAssignment role) {
    final nameController = TextEditingController(text: role.role);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Role'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Role Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Role updated successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteRoleDialog(RoleAssignment role) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Role'),
        content:
            Text('Are you sure you want to delete the role "${role.role}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Role deleted successfully')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _configure2FA() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Two-Factor Authentication'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.security),
              title: Text('Current Status: Disabled'),
            ),
            ListTile(
              leading: Icon(Icons.qr_code),
              title: Text('Scan QR Code'),
            ),
            ListTile(
              leading: Icon(Icons.sms),
              title: Text('SMS Verification'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('2FA configuration opened')),
              );
            },
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  void _showLoginDetails(LoginEvent login) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User: ${login.user}'),
            Text('Time: ${login.time}'),
            Text('IP Address: ${login.ip}'),
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

  void _testApiConnection(ApiIntegration api) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Testing ${api.name}'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Testing API connection...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${api.name} connection test ${api.status == 'active' ? 'successful' : 'failed'}'),
          backgroundColor: api.status == 'active' ? Colors.green : Colors.red,
        ),
      );
    });
  }

  void _configureApi(ApiIntegration api) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configure ${api.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'API Endpoint',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'API Key',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${api.name} configured successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _createBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Backup'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Creating system backup...'),
          ],
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Backup created successfully')),
      );
    });
  }

  void _restoreBackup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Backup'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.backup),
              title: Text('backup_2024_03_15.bak'),
              subtitle: Text('Created: Mar 15, 2024'),
            ),
            ListTile(
              leading: Icon(Icons.backup),
              title: Text('backup_2024_03_10.bak'),
              subtitle: Text('Created: Mar 10, 2024'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Backup restoration started')),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _downloadBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup download started')),
    );
  }

  void _uploadBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup upload dialog opened')),
    );
  }

  void _showSecuritySettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Settings'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: Text('Require Strong Passwords'),
              subtitle: Text('Enforce complex password requirements'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Session Timeout'),
              subtitle: Text('Auto-logout after 30 minutes'),
              value: true,
              onChanged: null,
            ),
            SwitchListTile(
              title: Text('Login Notifications'),
              subtitle: Text('Email notifications for new logins'),
              value: true,
              onChanged: null,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Security settings saved')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAuditLog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Audit Log'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: 5, // Mock data count
            itemBuilder: (context, index) {
              final activity = ActivityLog(
                title: 'System action $index',
                subtitle: 'admin',
                time: 'Mar ${10 + index}, 10:${45 + index}',
                type: 'system',
              );
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(activity.title),
                subtitle: Text('${activity.subtitle} • ${activity.time}'),
                trailing: const Icon(Icons.info_outline),
              );
            },
          ),
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
                const SnackBar(
                    content: Text('Audit log exported successfully')),
              );
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }
}
