import 'package:eventease/core/database/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';

class SimpleDatabaseService {
  static final SimpleDatabaseService _instance =
      SimpleDatabaseService._internal();
  factory SimpleDatabaseService() => _instance;
  SimpleDatabaseService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Initialize database
  Future<void> initializeDatabase() async {
    try {
      // Initialize database factory for desktop platforms
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
      }

      await _dbHelper.database;
      print('✅ Database initialized successfully!');
    } catch (e) {
      print('❌ Database initialization failed: $e');
      rethrow;
    }
  }

  // Get database path
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return path.join(dbPath, 'eventease.db');
  }

  // Check if database exists
  Future<bool> databaseExists() async {
    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);
    return await dbFile.exists();
  }

  // Get database info
  Future<Map<String, dynamic>> getDatabaseInfo() async {
    final dbPath = await getDatabasePath();
    final exists = await databaseExists();
    final size = await getDatabaseSize();

    return {
      'path': dbPath,
      'exists': exists,
      'size': size,
      'sizeKB': (size / 1024).toStringAsFixed(2),
    };
  }

  // Get database size
  Future<int> getDatabaseSize() async {
    final dbPath = await getDatabasePath();
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      return await dbFile.length();
    }
    return 0;
  }

  // Test basic operations
  Future<Map<String, dynamic>> testDatabase() async {
    try {
      final users = await _dbHelper.getAllUsers();
      final vendors = await _dbHelper.getAllVendors();
      final customers = await _dbHelper.getAllCustomers();

      return {
        'status': 'healthy',
        'users': users.length,
        'vendors': vendors.length,
        'customers': customers.length,
        'message': 'Database is working correctly!',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'message': 'Database test failed',
      };
    }
  }

  // Close database
  Future<void> closeDatabase() async {
    await _dbHelper.close();
  }
}
