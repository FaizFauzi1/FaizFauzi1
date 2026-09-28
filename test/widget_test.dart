import 'package:flutter_test/flutter_test.dart';
import 'package:eventease/main.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eventease/core/services/supabase_service.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: '''
      SUPABASE_URL=https://mock.supabase.co
      SUPABASE_ANON_KEY=mock-key
    ''');
    await SupabaseService.initialize();
  });

  testWidgets('App renders successfully smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const EventEaseApp());

    // Verify the app widget structure is successfully created
    expect(find.byType(EventEaseApp), findsOneWidget);
  });
}
