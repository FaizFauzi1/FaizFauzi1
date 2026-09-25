import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:eventease/features/organizer/presentation/organizer_screen_catalog.dart';

/// Debug navigator for all Wedding Event Organizer (expo) screens.
class OrganizerScreensGalleryScreen extends StatelessWidget {
  const OrganizerScreensGalleryScreen({super.key});

  static const routeName = '/__debug/organizer-screens';

  @override
  Widget build(BuildContext context) {
    final modules = OrganizerModule.values;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizer Screens (Expo)'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                kDebugMode
                    ? '${OrganizerScreenCatalog.all.length} screens · Wedding Event Organizer'
                    : 'Debug-only screen.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: modules.length,
        itemBuilder: (context, moduleIndex) {
          final module = modules[moduleIndex];
          final screens = OrganizerScreenCatalog.byModule(module);
          return ExpansionTile(
            initiallyExpanded: moduleIndex < 3,
            title: Text(
              OrganizerScreenCatalog.moduleLabel(module),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text('${screens.length} screens'),
            children: screens
                .map(
                  (def) => ListTile(
                    dense: true,
                    title: Row(
                      children: [
                        Expanded(child: Text(def.title)),
                        if (def.isHub)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('HUB', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    subtitle: Text(def.route, style: const TextStyle(fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => Navigator.of(context).pushNamed(def.route),
                  ),
                )
                .toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/organizer/expo-command-dashboard'),
        icon: const Icon(Icons.dashboard),
        label: const Text('Open command dashboard'),
      ),
    );
  }
}
