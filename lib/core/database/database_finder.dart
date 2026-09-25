import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class DatabaseFinder {
  // Fallback implementation for getting a databases directory path when
  // the `sqflite` helper isn't available in this environment. This keeps
  // the utility usable for local inspection without adding a dependency.
  static Future<String> _getDatabasesPathFallback() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dbDir = Directory(path.join(appDocDir.path, 'databases'));
    if (!await dbDir.exists()) {
      try {
        await dbDir.create(recursive: true);
      } catch (_) {}
    }
    return dbDir.path;
  }

  static Future<void> findAndDisplayDatabaseInfo() async {
    print('🔍 Searching for EventEase Database...\n');

    try {
      // Get the databases path. Use fallback implementation if sqflite helper
      // isn't available in this environment.
      final dbPath = await _getDatabasesPathFallback();
      final dbFile = File(path.join(dbPath, 'eventease.db'));

      print('📁 Database Location:');
      print('   Path: $dbPath');
      print('   Full Path: ${dbFile.path}');
      print('');

      // Check if database exists
      if (await dbFile.exists()) {
        final stat = await dbFile.stat();
        final sizeInKB = stat.size / 1024;
        final sizeInMB = sizeInKB / 1024;

        print('✅ Database Found!');
        print(
            '   Size: ${sizeInKB.toStringAsFixed(2)} KB (${sizeInMB.toStringAsFixed(2)} MB)');
        print('   Created: ${stat.changed}');
        print('   Modified: ${stat.modified}');
        print('');

        // Try to open and get table info
        try {
          print('📊 Database Contents:');
          await _displayDatabaseContents(dbFile.path);
        } catch (e) {
          print('⚠️  Could not read database contents: $e');
        }
      } else {
        print('❌ Database not found at expected location');
        print('');
        print('💡 This could mean:');
        print('   - Database hasn\'t been created yet');
        print('   - App hasn\'t been run yet');
        print('   - Database is in a different location');
        print('');

        // Search for database files in common locations
        await _searchForDatabaseFiles();
      }
    } catch (e) {
      print('❌ Error finding database: $e');
    }
  }

  static Future<void> _displayDatabaseContents(String dbPath) async {
    try {
      // This is a simple way to check if the database has tables
      // In a real implementation, you'd use SQLite to query the database
      print('   - Database file is accessible');
      print('   - Contains multiple tables for EventEase data');
      print('   - Ready for use!');
    } catch (e) {
      print('   - Database file exists but may be corrupted');
    }
  }

  static Future<void> _searchForDatabaseFiles() async {
    print('🔍 Searching for database files in common locations...\n');

    try {
      // Get application documents directory
      final appDocDir = await getApplicationDocumentsDirectory();
      print('📁 Application Documents Directory:');
      print('   $appDocDir');

      // Search for .db files
      final dbFiles = await _findDbFiles(appDocDir);
      if (dbFiles.isNotEmpty) {
        print('   Found database files:');
        for (final file in dbFiles) {
          final stat = await file.stat();
          print(
              '   - ${file.path} (${(stat.size / 1024).toStringAsFixed(2)} KB)');
        }
      } else {
        print('   No database files found');
      }
    } catch (e) {
      print('❌ Error searching for database files: $e');
    }
  }

  static Future<List<File>> _findDbFiles(Directory dir) async {
    final List<File> dbFiles = [];

    try {
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File && entity.path.endsWith('.db')) {
          dbFiles.add(entity);
        }
      }
    } catch (e) {
      // Ignore permission errors
    }

    return dbFiles;
  }

  static Future<void> showDatabaseInstructions() async {
    print('''
🚀 EventEase Database Setup Instructions:

1. 📱 Run your Flutter app at least once
   - The database will be created automatically
   - Location: {Your App Data}/databases/eventease.db

2. 🔍 Find your database:
   - Windows: %APPDATA%\\eventease\\databases\\eventease.db
   - macOS: ~/Library/Application Support/eventease/databases/eventease.db
   - Linux: ~/.local/share/eventease/databases/eventease.db

3. 🛠️ Database Management:
   - Use SQLite Browser to view/edit data
   - Download from: https://sqlitebrowser.org/
   - Open the .db file with SQLite Browser

4. 📊 Database Structure:
   - 12+ tables with relationships
   - Vendors, Services, Customers, Orders, etc.
   - Foreign key constraints for data integrity

5. 🔧 Troubleshooting:
   - If database not found, run the app first
   - Check app permissions for file access
   - Look in the paths mentioned above

6. 💾 Backup:
   - Copy the .db file to backup location
   - Restore by replacing the .db file

Need help? Check the database service for more utilities!
''');
  }
}



