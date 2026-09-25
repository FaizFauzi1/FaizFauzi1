import 'package:flutter/material.dart';
import 'package:eventease/core/utils/app_theme.dart';
import 'package:eventease/features/organizer/presentation/organizer_screen_catalog.dart';
import 'package:eventease/features/organizer/presentation/widgets/organizer_screen_body.dart';

/// Scaffold for organizer screens not yet fully implemented.
class OrganizerPlaceholderScreen extends StatelessWidget {
  final OrganizerScreenDef def;

  const OrganizerPlaceholderScreen({super.key, required this.def});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(def.title),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: OrganizerScreenBody(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ModuleChip(label: OrganizerScreenCatalog.moduleLabel(def.module)),
            const SizedBox(height: 12),
            Text(
              def.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Wedding Event Organizer · Expo / Bridal Fair',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryColor,
                  ),
            ),
            if (def.isHub) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Hub screen',
                  style: TextStyle(
                    color: AppTheme.accentColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            if (def.features.isNotEmpty) ...[
              Text(
                'Planned capabilities',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              ...def.features.map(
                (f) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline, color: AppTheme.primaryColor),
                    title: Text(f),
                    dense: true,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Go back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  final String label;
  const _ModuleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(label),
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
        labelStyle: const TextStyle(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
