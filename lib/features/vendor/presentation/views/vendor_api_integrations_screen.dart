import 'package:eventease/core/utils/app_theme.dart';
import 'package:flutter/material.dart';

class VendorApiIntegrationsScreen extends StatefulWidget {
  const VendorApiIntegrationsScreen({super.key});

  @override
  State<VendorApiIntegrationsScreen> createState() => _VendorApiIntegrationsScreenState();
}

class _VendorApiIntegrationsScreenState extends State<VendorApiIntegrationsScreen> {
  final List<Map<String, dynamic>> _integrations = [
    {
      'name': 'Google Calendar',
      'description': 'Sync your bookings with Google Calendar',
      'icon': Icons.calendar_today,
      'color': Colors.blue,
      'status': 'connected',
      'lastSync': '2024-03-15 10:30',
      'features': ['Auto-sync bookings', 'Availability updates', 'Reminder notifications'],
    },
    {
      'name': 'Facebook',
      'description': 'Connect your Facebook business page',
      'icon': Icons.facebook,
      'color': Colors.blue.shade800,
      'status': 'connected',
      'lastSync': '2024-03-15 09:15',
      'features': ['Post updates', 'Event promotion', 'Customer reviews sync'],
    },
    {
      'name': 'Instagram',
      'description': 'Link your Instagram business account',
      'icon': Icons.camera_alt,
      'color': Colors.pink,
      'status': 'disconnected',
      'lastSync': null,
      'features': ['Story highlights', 'Photo gallery sync', 'Hashtag tracking'],
    },
    {
      'name': 'Stripe',
      'description': 'Payment processing integration',
      'icon': Icons.payment,
      'color': Colors.purple,
      'status': 'connected',
      'lastSync': '2024-03-15 08:00',
      'features': ['Secure payments', 'Payout management', 'Transaction tracking'],
    },
    {
      'name': 'Mailchimp',
      'description': 'Email marketing automation',
      'icon': Icons.email,
      'color': Colors.orange,
      'status': 'disconnected',
      'lastSync': null,
      'features': ['Customer newsletters', 'Marketing campaigns', 'Email automation'],
    },
    {
      'name': 'Zapier',
      'description': 'Connect with 2000+ apps',
      'icon': Icons.link,
      'color': Colors.teal,
      'status': 'disconnected',
      'lastSync': null,
      'features': ['Workflow automation', 'Data sync', 'Custom integrations'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final connectedCount = _integrations.where((i) => i['status'] == 'connected').length;
    final totalCount = _integrations.length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('API Integrations',
            style: TextStyle(
                color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Integration stats
          _buildIntegrationStats(connectedCount, totalCount),

          // Integration list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _integrations.length,
              itemBuilder: (context, index) =>
                  _buildIntegrationCard(_integrations[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationStats(int connected, int total) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Connected',
              connected.toString(),
              Icons.link,
              AppTheme.successColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Available',
              total.toString(),
              Icons.apps,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Success Rate',
              '98%',
              Icons.trending_up,
              AppTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildIntegrationCard(Map<String, dynamic> integration) {
    final isConnected = integration['status'] == 'connected';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: integration['color'].withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  integration['icon'],
                  color: integration['color'],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          integration['name'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isConnected
                                ? Colors.green.shade100
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isConnected ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              color: isConnected ? Colors.green : Colors.grey,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      integration['description'],
                      style: const TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                    if (integration['lastSync'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Last sync: ${integration['lastSync']}',
                        style: const TextStyle(
                          color: AppTheme.textSecondaryColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _handleIntegrationAction(integration),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConnected
                      ? AppTheme.errorColor
                      : AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text(isConnected ? 'Disconnect' : 'Connect'),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Features
          const Text(
            'Features:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: integration['features'].map<Widget>((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  feature,
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showIntegrationDetails(integration),
                  icon: const Icon(Icons.info, size: 16),
                  label: const Text('Details'),
                ),
              ),
              const SizedBox(width: 8),
              if (isConnected) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _configureIntegration(integration),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Configure'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _syncIntegration(integration),
                    icon: const Icon(Icons.sync, size: 16),
                    label: const Text('Sync'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _handleIntegrationAction(Map<String, dynamic> integration) {
    final isConnected = integration['status'] == 'connected';

    if (isConnected) {
      // Disconnect
      setState(() {
        integration['status'] = 'disconnected';
        integration['lastSync'] = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${integration['name']} disconnected')),
      );
    } else {
      // Connect - show connection dialog
      _showConnectionDialog(integration);
    }
  }

  void _showConnectionDialog(Map<String, dynamic> integration) {
    final TextEditingController apiKeyController = TextEditingController();
    final TextEditingController secretController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Connect ${integration['name']}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Enter your ${integration['name']} credentials to connect.',
                style: const TextStyle(color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: secretController,
                decoration: const InputDecoration(
                  labelText: 'Secret Key (if required)',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your credentials are encrypted and stored securely.',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (apiKeyController.text.isNotEmpty) {
                setState(() {
                  integration['status'] = 'connected';
                  integration['lastSync'] = DateTime.now().toString().substring(0, 16);
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${integration['name']} connected successfully')),
                );
              }
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  void _showIntegrationDetails(Map<String, dynamic> integration) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${integration['name']} Integration'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                integration['description'],
                style: const TextStyle(color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 16),
              const Text(
                'Features:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              ...integration['features'].map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Text(feature, style: const TextStyle(fontSize: 14)),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              if (integration['lastSync'] != null) ...[
                const Text(
                  'Last Sync:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(integration['lastSync']),
              ],
            ],
          ),
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

  void _configureIntegration(Map<String, dynamic> integration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Configure ${integration['name']} (placeholder)')),
    );
  }

  void _syncIntegration(Map<String, dynamic> integration) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Syncing ${integration['name']}...')),
    );
    // Simulate sync
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        integration['lastSync'] = DateTime.now().toString().substring(0, 16);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${integration['name']} synced successfully')),
      );
    });
  }
}
