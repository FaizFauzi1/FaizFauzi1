import 'package:eventease/core/database/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

/// Simple database initialization and testing
class SimpleDatabaseInit {
  static Future<void> initializeAndTest() async {
    print('🚀 Initializing EventEase Database...\n');

    try {
      // 1. Initialize database helper
      final dbHelper = DatabaseHelper();
      print('✅ Database helper created');

      // 2. Get database path via helper
      final fullPath = await dbHelper.getDatabasePath();
      print('📁 Database will be created at: $fullPath');

      // 3. Initialize database (this creates the file)
      final database = await dbHelper.database;
      print('✅ Database initialized successfully!');

      // 4. Check if file exists
      final dbFile = File(fullPath);
      if (await dbFile.exists()) {
        final stat = await dbFile.stat();
        print('✅ Database file exists!');
        print('   Size: ${(stat.size / 1024).toStringAsFixed(2)} KB');
        print('   Created: ${stat.changed}');
        print('   Location: $fullPath');
      } else {
        print('❌ Database file not found at expected location');
      }

      // 5. Test basic operations
      print('\n🧪 Testing basic operations...');

      // Test user operations
      final users = await dbHelper.getAllUsers();
      print('   Users in database: ${users.length}');

      // Test vendor operations
      final vendors = await dbHelper.getAllVendors();
      print('   Vendors in database: ${vendors.length}');

      // Test customer operations
      final customers = await dbHelper.getAllCustomers();
      print('   Customers in database: ${customers.length}');

      print('\n🎉 Database initialization completed successfully!');
      print('\n📍 Your database is located at:');
      print('   $fullPath');
      print('\n💡 You can now:');
      print('   1. Use SQLite Browser to view your database');
      print('   2. Download from: https://sqlitebrowser.org/');
      print('   3. Open the .db file with SQLite Browser');
    } catch (e) {
      print('❌ Error initializing database: $e');
      print('\n🔧 Troubleshooting:');
      print('1. Make sure you have proper file permissions');
      print('2. Try running the app first');
      print('3. Check if the path exists');
    }
  }

  static Future<void> showDatabaseLocation() async {
    try {
      final dbHelper = DatabaseHelper();
      final fullPath = await dbHelper.getDatabasePath();
      final dbFile = File(fullPath);

      print('🔍 Database Location Information:');
      print('   Expected path: $fullPath');
      print('   File exists: ${await dbFile.exists()}');

      if (await dbFile.exists()) {
        final stat = await dbFile.stat();
        print('   File size: ${(stat.size / 1024).toStringAsFixed(2)} KB');
        print('   Last modified: ${stat.modified}');
      }

      print('\n💡 To find your database:');
      print('   Windows: Check %APPDATA%\\eventease\\databases\\');
      print(
          '   macOS: Check ~/Library/Application Support/eventease/databases/');
      print('   Linux: Check ~/.local/share/eventease/databases/');
    } catch (e) {
      print('❌ Error getting database location: $e');
    }
  }
}



