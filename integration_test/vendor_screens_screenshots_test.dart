import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:eventease/main.dart' as app;
import 'package:eventease/debug/vendor_screens_gallery_screen.dart';

/// Drives the Windows desktop app through vendor routes and captures screenshots.
///
/// Run:
///   flutter drive -d windows --driver test_driver/integration_test.dart --target integration_test/vendor_screens_screenshots_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('capture vendor screen screenshots', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // Open the debug vendor gallery.
    app.mainNavigatorKey.currentState!.pushNamed(VendorScreensGalleryScreen.routeName);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Collect route tiles.
    Finder tiles = find.byType(ListTile);
    expect(tiles, findsWidgets);

    // We re-query tiles each loop because the list re-builds after navigation.
    int safety = 0;
    while (true) {
      safety++;
      if (safety > 200) {
        fail('Safety break: too many iterations while capturing screenshots.');
      }

      await tester.pumpAndSettle(const Duration(milliseconds: 200));
      tiles = find.byType(ListTile);
      final tileCount = tester.widgetList(tiles).length;
      if (tileCount == 0) {
        fail('No vendor routes found in gallery.');
      }

      // Capture by index to keep deterministic ordering.
      for (int i = 0; i < tileCount; i++) {
        // Scroll tile into view (ListView virtualizes).
        final tileFinder = tiles.at(i);
        await tester.ensureVisible(tileFinder);
        await tester.pumpAndSettle(const Duration(milliseconds: 250));

        final tile = tester.widget<ListTile>(tileFinder);
        final title = (tile.title is Text) ? (tile.title as Text).data ?? '' : '';
        final route = (tile.subtitle is Text) ? (tile.subtitle as Text).data ?? '' : '';
        final fileSafe = _fileSafeName('${i.toString().padLeft(2, '0')}_${title.isNotEmpty ? title : route}');

        // Navigate into the screen.
        await tester.tap(tileFinder);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Screenshot.
        // On web, the driver saves screenshots on the host machine.
        // On non-web, takeScreenshot returns bytes (depending on platform), but we
        // still rely on the driver to persist results consistently.
        await binding.takeScreenshot(fileSafe);

        // Navigate back.
        if (app.mainNavigatorKey.currentState!.canPop()) {
          app.mainNavigatorKey.currentState!.pop();
        } else {
          // Fallback: use system back if needed
          await tester.pageBack();
        }
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Ensure we are back on the gallery for the next screenshot.
        expect(find.text('Vendor Screens (Debug)'), findsOneWidget);
      }

      // Done after one full pass.
      break;
    }
  }, timeout: const Timeout(Duration(minutes: 20)));
}

String _fileSafeName(String input) {
  final trimmed = input.trim().isEmpty ? 'screen' : input.trim();
  final safe = trimmed
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(RegExp(r'__+'), '_');
  return safe.toLowerCase();
}

