import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});
  static const routeName = '/organizer/company-profile';

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  final _legalName = TextEditingController(text: 'Bridal Events Malaysia Sdn Bhd');
  final _tradeName = TextEditingController(text: 'BEM Expo');
  final _registration = TextEditingController(text: '201801012345');
  final _email = TextEditingController(text: 'ops@bemexpo.com.my');
  final _phone = TextEditingController(text: '+60 3-1234 5678');
  final _address = TextEditingController(text: 'Level 12, Menara KL, 50250 Kuala Lumpur');

  @override
  void dispose() {
    _legalName.dispose();
    _tradeName.dispose();
    _registration.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Company profile saved'), backgroundColor: AppTheme.successColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Company Profile'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Legal & contact information for your organizer company.',
                style: TextStyle(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 20),
            TextField(controller: _legalName, decoration: const InputDecoration(labelText: 'Legal name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _tradeName, decoration: const InputDecoration(labelText: 'Trade / brand name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _registration, decoration: const InputDecoration(labelText: 'Business registration no.', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _email, decoration: const InputDecoration(labelText: 'Contact email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _phone, decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: _address, maxLines: 2, decoration: const InputDecoration(labelText: 'Registered address', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)), child: const Text('Save profile')),
          ],
        ),
      ),
    );
  }
}

class OrganizerBrandingScreen extends StatefulWidget {
  const OrganizerBrandingScreen({super.key});
  static const routeName = '/organizer/branding';

  @override
  State<OrganizerBrandingScreen> createState() => _OrganizerBrandingScreenState();
}

class _OrganizerBrandingScreenState extends State<OrganizerBrandingScreen> {
  Color _primary = AppTheme.primaryColor;
  Color _accent = AppTheme.accentColor;
  String _template = 'Classic bridal';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Organizer Branding'),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: _primary, child: const Icon(Icons.image, color: Colors.white)),
                title: const Text('Company logo'),
                subtitle: const Text('PNG or SVG, min 512×512'),
                trailing: OutlinedButton(onPressed: () {}, child: const Text('Upload')),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Brand colours', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                _ColorSwatch(label: 'Primary', color: _primary, onTap: () => setState(() => _primary = const Color(0xFF6B21A8))),
                const SizedBox(width: 16),
                _ColorSwatch(label: 'Accent', color: _accent, onTap: () => setState(() => _accent = const Color(0xFFD97706))),
              ],
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              value: _template,
              decoration: const InputDecoration(labelText: 'Expo branding template', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'Classic bridal', child: Text('Classic bridal')),
                DropdownMenuItem(value: 'Modern minimal', child: Text('Modern minimal')),
                DropdownMenuItem(value: 'Luxury gold', child: Text('Luxury gold')),
                DropdownMenuItem(value: 'AP Event', child: Text('AP Event')),
              ],
              onChanged: (v) => setState(() => _template = v!),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branding updated'))),
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Apply branding'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ColorSwatch({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderColor))),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class EventTypesSetupScreen extends StatefulWidget {
  const EventTypesSetupScreen({super.key});
  static const routeName = '/organizer/event-types-setup';

  @override
  State<EventTypesSetupScreen> createState() => _EventTypesSetupScreenState();
}

class _EventTypesSetupScreenState extends State<EventTypesSetupScreen> {
  final _types = [
    _EventType('Bridal fair', true, 'Multi-vendor wedding showcase'),
    _EventType('Wedding expo', true, 'Large-scale consumer expo'),
    _EventType('AP Event', false, 'Asian Pacific wedding events'),
    _EventType('Vendor showcase', true, 'Category-focused mini expo'),
    _EventType('Corporate bridal', false, 'B2B vendor networking'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Event Types Setup'),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: AppTheme.primaryColor, child: const Icon(Icons.add)),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _types.length,
          itemBuilder: (context, i) {
            final t = _types[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: SwitchListTile(
                title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(t.description),
                value: t.enabled,
                activeColor: AppTheme.primaryColor,
                onChanged: (v) => setState(() => _types[i] = _EventType(t.name, v, t.description)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EventType {
  final String name;
  final bool enabled;
  final String description;
  const _EventType(this.name, this.enabled, this.description);
}

class StaffRolesSetupScreen extends StatefulWidget {
  const StaffRolesSetupScreen({super.key});
  static const routeName = '/organizer/staff-roles-setup';

  @override
  State<StaffRolesSetupScreen> createState() => _StaffRolesSetupScreenState();
}

class _StaffRolesSetupScreenState extends State<StaffRolesSetupScreen> {
  final _roles = [
    _StaffRole('Registration team', ['Check-in', 'Ticket scan', 'Visitor reg'], 12),
    _StaffRole('Booth support', ['Vendor assist', 'Layout changes'], 8),
    _StaffRole('Crowd control', ['Zone patrol', 'Incident report'], 6),
    _StaffRole('Lead capture', ['Lead scan', 'Lead assign'], 10),
    _StaffRole('Finance desk', ['Payment collect', 'Invoice issue'], 4),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Staff & Role Setup'),
      floatingActionButton: FloatingActionButton(onPressed: () {}, backgroundColor: AppTheme.primaryColor, child: const Icon(Icons.add)),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _roles.length,
          itemBuilder: (context, i) {
            final r = _roles[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                title: Text(r.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${r.memberCount} staff assigned'),
                children: r.permissions
                    .map((p) => CheckboxListTile(
                          title: Text(p),
                          value: true,
                          activeColor: AppTheme.primaryColor,
                          onChanged: (_) {},
                        ))
                    .toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StaffRole {
  final String name;
  final List<String> permissions;
  final int memberCount;
  const _StaffRole(this.name, this.permissions, this.memberCount);
}

class ServiceRegionsScreen extends StatefulWidget {
  const ServiceRegionsScreen({super.key});
  static const routeName = '/organizer/service-regions';

  @override
  State<ServiceRegionsScreen> createState() => _ServiceRegionsScreenState();
}

class _ServiceRegionsScreenState extends State<ServiceRegionsScreen> {
  final _states = {
    'Selangor': true,
    'Kuala Lumpur': true,
    'Penang': true,
    'Johor': true,
    'Perak': false,
    'Sabah': false,
    'Sarawak': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Service Regions'),
      body: OrganizerScreenBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Select states and cities where you operate expos.',
                  style: TextStyle(color: AppTheme.textSecondaryColor)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _states.keys.map((state) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      title: Text(state, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(_states[state]! ? 'Active coverage' : 'Not covered'),
                      value: _states[state],
                      activeColor: AppTheme.primaryColor,
                      onChanged: (v) => setState(() => _states[state] = v ?? false),
                    ),
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Regions updated'))),
                style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Save regions'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
