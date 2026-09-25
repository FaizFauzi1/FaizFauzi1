import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/data/organizer_data_mode.dart';
import 'package:eventease/features/organizer/presentation/views/dashboard/expo_command_dashboard_screen.dart';

/// Banner + toggle for demo (in-app sample) vs live (Supabase) data.
class OrganizerDataModeBanner extends StatefulWidget {
  const OrganizerDataModeBanner({super.key});

  @override
  State<OrganizerDataModeBanner> createState() => _OrganizerDataModeBannerState();
}

class _OrganizerDataModeBannerState extends State<OrganizerDataModeBanner> {
  @override
  void initState() {
    super.initState();
    OrganizerDataModeController.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    OrganizerDataModeController.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    OrganizerDataModeController.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _setMode(OrganizerDataSource source) async {
    await OrganizerDataModeController.instance.setSource(source);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          source == OrganizerDataSource.demo
              ? 'Demo data — sample bridal fair preview'
              : 'Live data — reading from Supabase',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!OrganizerDataModeController.instance.isLoaded) {
      return const SizedBox.shrink();
    }

    final isDemo = OrganizerDataModeController.instance.isDemo;

    return Material(
      color: isDemo ? AppTheme.warningColor.withValues(alpha: 0.12) : AppTheme.successColor.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(
              isDemo ? Icons.science_outlined : Icons.cloud_done_outlined,
              size: 20,
              color: isDemo ? AppTheme.warningColor : AppTheme.successColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDemo ? 'Demo data' : 'Live Supabase data',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(
                    isDemo
                        ? 'Sample bridal fair — no database required'
                        : 'Your organizer company & expos from Supabase',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ),
            SegmentedButton<OrganizerDataSource>(
              segments: const [
                ButtonSegment(
                  value: OrganizerDataSource.demo,
                  label: Text('Demo'),
                  icon: Icon(Icons.preview, size: 16),
                ),
                ButtonSegment(
                  value: OrganizerDataSource.live,
                  label: Text('Live'),
                  icon: Icon(Icons.storage, size: 16),
                ),
              ],
              selected: {isDemo ? OrganizerDataSource.demo : OrganizerDataSource.live},
              onSelectionChanged: (set) => _setMode(set.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Settings card with data source toggle and seed instructions.
class OrganizerDataSourceSettingsCard extends StatefulWidget {
  const OrganizerDataSourceSettingsCard({super.key});

  @override
  State<OrganizerDataSourceSettingsCard> createState() => _OrganizerDataSourceSettingsCardState();
}

class _OrganizerDataSourceSettingsCardState extends State<OrganizerDataSourceSettingsCard> {
  @override
  void initState() {
    super.initState();
    OrganizerDataModeController.instance.load().then((_) {
      if (mounted) setState(() {});
    });
    OrganizerDataModeController.instance.addListener(_refresh);
  }

  @override
  void dispose() {
    OrganizerDataModeController.instance.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Future<void> _applyMode(OrganizerDataSource source) async {
    await OrganizerDataModeController.instance.setSource(source);
    if (!mounted) return;
    Navigator.of(context).popUntil(
      (route) => route.settings.name == ExpoCommandDashboardScreen.routeName || route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mode = OrganizerDataModeController.instance.source;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data source', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
              'Demo uses built-in sample data for UI previews. Live reads your Supabase organizer tables (run the seed SQL once for sample live data).',
              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
            ),
            const SizedBox(height: 16),
            RadioListTile<OrganizerDataSource>(
              title: const Text('Demo (sample data)'),
              subtitle: const Text('Offline preview — KL Bridal Fair mock dataset'),
              value: OrganizerDataSource.demo,
              groupValue: mode,
              onChanged: (v) => v != null ? _applyMode(v) : null,
            ),
            RadioListTile<OrganizerDataSource>(
              title: const Text('Live (Supabase)'),
              subtitle: const Text('Real tables, RLS, and dashboard stats view'),
              value: OrganizerDataSource.live,
              groupValue: mode,
              onChanged: (v) => v != null ? _applyMode(v) : null,
            ),
            const Divider(height: 24),
            const Text('Seed live database', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            const Text(
              'In Supabase SQL editor, run:\nselect public.seed_organizer_module();',
              style: TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
