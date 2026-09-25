import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_ui_helpers.dart';

class StaffAssignmentScreen extends StatefulWidget {
  const StaffAssignmentScreen({super.key});
  static const routeName = '/organizer/staff-assignment';

  @override
  State<StaffAssignmentScreen> createState() => _StaffAssignmentScreenState();
}

class _StaffAssignmentScreenState extends State<StaffAssignmentScreen> {
  final _assignments = [
    _Assignment('Ahmad Rizal', 'Registration team', 'Zone A – Main entrance', Icons.login),
    _Assignment('Siti Nurhaliza', 'Lead capture', 'Zone B – Bridal row', Icons.people_alt),
    _Assignment('Raj Kumar', 'Booth support', 'Zone VIP', Icons.storefront),
    _Assignment('Lim Wei Jie', 'Crowd control', 'Hall 2 corridor', Icons.groups),
    _Assignment('Fatimah Ali', 'Registration team', 'Zone C – Side entry', Icons.login),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Staff Assignment'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAssignDialog(context),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.person_add),
      ),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _assignments.length,
          itemBuilder: (context, i) {
            final a = _assignments[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15), child: Icon(a.icon, color: AppTheme.primaryColor)),
                title: Text(a.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${a.role}\n${a.zone}'),
                isThreeLine: true,
                trailing: IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () {}),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAssignDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Assign staff', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Staff name', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Role', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Zone', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Staff assigned')));
              },
              style: FilledButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Assignment {
  final String name;
  final String role;
  final String zone;
  final IconData icon;
  const _Assignment(this.name, this.role, this.zone, this.icon);
}

class StaffRolesScreen extends StatelessWidget {
  const StaffRolesScreen({super.key});
  static const routeName = '/organizer/staff-roles';

  @override
  Widget build(BuildContext context) {
    const roles = [
      ('Registration team', 'Check-in visitors, scan tickets, issue badges', Icons.how_to_reg, 12),
      ('Booth support', 'Assist vendors, manage booth changes', Icons.support_agent, 8),
      ('Crowd control', 'Monitor flow, report incidents', Icons.security, 6),
      ('Lead capture', 'Collect and assign visitor leads', Icons.contact_page, 10),
    ];

    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Staff Roles'),
      body: OrganizerScreenBody(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: roles.length,
          itemBuilder: (context, i) {
            final (name, desc, icon, count) = roles[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: Icon(icon, color: AppTheme.primaryColor),
                title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(desc),
                trailing: Chip(label: Text('$count'), backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1)),
              ),
            );
          },
        ),
      ),
    );
  }
}

class LiveStaffTrackingScreen extends StatefulWidget {
  const LiveStaffTrackingScreen({super.key});
  static const routeName = '/organizer/live-staff-tracking';

  @override
  State<LiveStaffTrackingScreen> createState() => _LiveStaffTrackingScreenState();
}

class _LiveStaffTrackingScreenState extends State<LiveStaffTrackingScreen> {
  int _filter = 0;

  final _staff = [
    _LiveStaff('Ahmad Rizal', 'Registration', 'Active', 'Zone A', '2 min ago'),
    _LiveStaff('Siti Nurhaliza', 'Lead capture', 'Active', 'Zone B', 'Just now'),
    _LiveStaff('Raj Kumar', 'Booth support', 'On break', 'Rest area', '8 min ago'),
    _LiveStaff('Lim Wei Jie', 'Crowd control', 'Active', 'Hall 2', '1 min ago'),
    _LiveStaff('Fatimah Ali', 'Registration', 'Offline', '—', '25 min ago'),
  ];

  List<_LiveStaff> get _filtered {
    if (_filter == 0) return _staff;
    if (_filter == 1) return _staff.where((s) => s.status == 'Active').toList();
    return _staff.where((s) => s.status != 'Active').toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const OrganizerAppBar(title: 'Live Staff Tracking'),
      body: OrganizerScreenBody(
        child: Column(
          children: [
            OrganizerFilterChips(
              labels: const ['All', 'Active', 'Away / Offline'],
              selectedIndex: _filter,
              onSelected: (i) => setState(() => _filter = i),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filtered.length,
                itemBuilder: (context, i) {
                  final s = _filtered[i];
                  final color = switch (s.status) {
                    'Active' => AppTheme.successColor,
                    'On break' => AppTheme.warningColor,
                    _ => AppTheme.textSecondaryColor,
                  };
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.15),
                        child: Icon(Icons.person, color: color, size: 20),
                      ),
                      title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${s.role} · ${s.zone}\nLast seen: ${s.lastSeen}'),
                      isThreeLine: true,
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                        child: Text(s.status, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveStaff {
  final String name;
  final String role;
  final String status;
  final String zone;
  final String lastSeen;
  const _LiveStaff(this.name, this.role, this.status, this.zone, this.lastSeen);
}
