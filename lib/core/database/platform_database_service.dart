import 'package:eventease/core/database/database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class PlatformDatabaseService {
  static final PlatformDatabaseService _instance = PlatformDatabaseService._internal();
  factory PlatformDatabaseService() => _instance;
  PlatformDatabaseService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Initialize database factory for desktop platforms only (web uses IndexedDB natively)
  static void initializeDatabaseFactory() {
    try {
      // Only initialize for desktop platforms, not web
      if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
        sqfliteFfiInit();
        databaseFactory = databaseFactoryFfi;
        print('✅ Database factory initialized for desktop platforms');
      } else if (kIsWeb) {
        print('✅ Web platform detected - using native IndexedDB');
      }
    } catch (e) {
      print('❌ Database factory initialization failed: $e');
    }
  }

  // Initialize database
  Future<void> initializeDatabase() async {
    try {
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
      'platform': Platform.isAndroid ? 'mobile' : 'desktop',
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
      final services = await _dbHelper.getAllVendorServices();
      // Note: getAllServicePackages method doesn't exist in DatabaseHelper
      // final packages = await _dbHelper.getAllServicePackages();

      return {
        'status': 'healthy',
        'users': users.length,
        'vendors': vendors.length,
        'customers': customers.length,
        'services': services.length,
        // 'packages': packages.length,
        'platform': Platform.isAndroid ? 'mobile' : 'desktop',
        'message': 'Database is working correctly!',
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
        'platform': Platform.isAndroid ? 'mobile' : 'desktop',
        'message': 'Database test failed',
      };
    }
  }

  // Close database
  Future<void> closeDatabase() async {
    await _dbHelper.close();
  }
}
