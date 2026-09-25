import 'package:eventease/core/database/platform_database_service.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  try {
    final dbService = PlatformDatabaseService();
    await dbService.initializeDatabase();
    print('✅ Database initialized successfully!');

    // Test database
    final testResult = await dbService.testDatabase();
    print('📊 Database test: ${testResult['message']}');
    if (testResult['platform'] == 'mobile') {
      print(
          '   Users: ${testResult['users']}, Vendors: ${testResult['vendors']}, Customers: ${testResult['customers']}');
    }

    // Show database info
    final dbInfo = await dbService.getDatabaseInfo();
    print('📁 Database location: ${dbInfo['path']}');
    print('   Platform: ${dbInfo['platform']}');
    print('   Size: ${dbInfo['sizeKB']} KB');
  } catch (e) {
    print('❌ Database initialization failed: $e');
  }

  runApp(const MinimalApp());
}

class MinimalApp extends StatelessWidget {
  const MinimalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EventEase Database Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Database Test'),
        ),
        body: const Center(
          child: Text('Database initialized successfully!'),
        ),
      ),
    );
  }
}
