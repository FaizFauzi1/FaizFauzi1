import 'package:eventease/core/database/database_helper.dart';
import 'package:eventease/core/database/repositories/vendor_repository.dart';
import 'package:eventease/core/database/repositories/vendor_service_repository.dart';
import 'package:eventease/core/database/repositories/customer_repository.dart';
import 'package:eventease/core/database/repositories/order_repository.dart';
import 'package:eventease/core/database/repositories/cart_repository.dart';
import 'package:eventease/core/database/repositories/favorites_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  // Repository instances
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final VendorRepository _vendorRepository = VendorRepository();
  final VendorServiceRepository _vendorServiceRepository =
      VendorServiceRepository();
  final CustomerRepository _customerRepository = CustomerRepository();
  final OrderRepository _orderRepository = OrderRepository();
  final CartRepository _cartRepository = CartRepository();
  final FavoritesRepository _favoritesRepository = FavoritesRepository();

  // Repository getters
  VendorRepository get vendors => _vendorRepository;
  VendorServiceRepository get vendorServices => _vendorServiceRepository;
  CustomerRepository get customers => _customerRepository;
  OrderRepository get orders => _orderRepository;
  CartRepository get cart => _cartRepository;
  FavoritesRepository get favorites => _favoritesRepository;

  // Database information and utilities
  Future<String> getDatabasePath() async {
    final dbPath = await _dbHelper.getDatabasePath();
    return path.join(dbPath, 'eventease.db');
  }

  Future<File> getDatabaseFile() async {
    final dbPath = await getDatabasePath();
    return File(dbPath);
  }

  Future<bool> databaseExists() async {
    final dbFile = await getDatabaseFile();
    return await dbFile.exists();
  }

  Future<int> getDatabaseSize() async {
    final dbFile = await getDatabaseFile();
    if (await dbFile.exists()) {
      return await dbFile.length();
    }
    return 0;
  }

  Future<String> getDatabaseInfo() async {
    final dbPath = await getDatabasePath();
    final exists = await databaseExists();
    final size = await getDatabaseSize();

    return '''
Database Information:
- Path: $dbPath
- Exists: $exists
- Size: ${(size / 1024).toStringAsFixed(2)} KB
- Tables: 12+ tables with relationships
- Version: 2
''';
  }

  // Database management methods
  Future<void> initializeDatabase() async {
    try {
      // This will create the database if it doesn't exist
      await _dbHelper.database;
      print('Database initialized successfully');
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> closeDatabase() async {
    await _dbHelper.close();
  }

  // Data migration and seeding
  Future<void> seedInitialData() async {
    try {
      // Add some sample vendors
      await _seedVendors();
      print('Database seeded with initial data');
    } catch (e) {
      print('Error seeding database: $e');
    }
  }

  Future<void> _seedVendors() async {
    // This is just an example - you can add your own seed data
    final sampleVendors = [
      {
        'id': 'vendor_001',
        'name': 'Elegant Catering Co.',
        'categories': '["catering"]',
        'description': 'Premium catering services for all occasions',
        'location': 'Kuala Lumpur',
        'rating': 4.8,
        'reviewCount': 150,
        'status': 'approved',
        'subscriptionTier': 'premium',
        'email': 'info@elegantcatering.com',
        'phone': '+60123456789',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': 1,
        'verified': 1,
        'featured': 1,
      },
      {
        'id': 'vendor_002',
        'name': 'Dream Photography',
        'categories': '["photography"]',
        'description': 'Professional photography for weddings and events',
        'location': 'Petaling Jaya',
        'rating': 4.9,
        'reviewCount': 200,
        'status': 'approved',
        'subscriptionTier': 'basic',
        'email': 'hello@dreamphotography.com',
        'phone': '+60198765432',
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
        'isActive': 1,
        'verified': 1,
        'featured': 0,
      },
    ];

    for (final vendorData in sampleVendors) {
      await _dbHelper.insertVendor(vendorData);
    }
  }

  // Database health check
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final dbExists = await databaseExists();
      final dbSize = await getDatabaseSize();

      // Test basic operations
      final vendorCount =
          await _vendorRepository.getAllVendors().then((v) => v.length);
      final customerCount =
          await _customerRepository.getAllCustomers().then((c) => c.length);

      return {
        'status': 'healthy',
        'databaseExists': dbExists,
        'databaseSize': dbSize,
        'vendorCount': vendorCount,
        'customerCount': customerCount,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Backup and restore functionality
  Future<String> createBackup() async {
    try {
      final dbFile = await getDatabaseFile();
      final backupPath =
          '${dbFile.path}.backup.${DateTime.now().millisecondsSinceEpoch}';
      await dbFile.copy(backupPath);
      return backupPath;
    } catch (e) {
      throw Exception('Failed to create backup: $e');
    }
  }

  Future<void> restoreFromBackup(String backupPath) async {
    try {
      final dbFile = await getDatabaseFile();
      final backupFile = File(backupPath);

      if (!await backupFile.exists()) {
        throw Exception('Backup file does not exist');
      }

      await backupFile.copy(dbFile.path);
    } catch (e) {
      throw Exception('Failed to restore from backup: $e');
    }
  }

  // Clear all data (use with caution!)
  Future<void> clearAllData() async {
    await _dbHelper.clearAllData();
  }

  // Get database statistics
  Future<Map<String, dynamic>> getDatabaseStatistics() async {
    try {
      final vendors = await _vendorRepository.getAllVendors();
      final customers = await _customerRepository.getAllCustomers();
      final orders = await _orderRepository.getAllOrders();

      final vendorStats = await _vendorRepository.getVendorStatistics();
      final orderStats = await _orderRepository.getOrderStatistics();

      return {
        'vendors': vendorStats,
        'orders': orderStats,
        'customers': {
          'total': customers.length,
          'active': customers.where((c) => c.status.name == 'active').length,
        },
        'database': {
          'size': await getDatabaseSize(),
          'path': await getDatabasePath(),
          'exists': await databaseExists(),
        },
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  // Search across all entities
  Future<Map<String, dynamic>> globalSearch(String query) async {
    try {
      final vendors = await _vendorRepository.searchVendors(query: query);
      final customers = await _customerRepository.searchCustomers(query);
      final orders = await _orderRepository.searchOrders(query);

      return {
        'vendors': vendors
            .map((v) => {
                  'id': v.id,
                  'name': v.name,
                  'type': 'vendor',
                })
            .toList(),
        'customers': customers
            .map((c) => {
                  'id': c.id,
                  'name': c.name,
                  'type': 'customer',
                })
            .toList(),
        'orders': orders
            .map((o) => {
                  'id': o.id,
                  'customerName': o.customerName,
                  'type': 'order',
                })
            .toList(),
        'totalResults': vendors.length + customers.length + orders.length,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'results': [],
      };
    }
  }

  // Export data to JSON (for debugging/backup)
  Future<Map<String, dynamic>> exportData() async {
    try {
      final vendors = await _vendorRepository.getAllVendors();
      final customers = await _customerRepository.getAllCustomers();
      final orders = await _orderRepository.getAllOrders();

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0',
        'data': {
          'vendors': vendors
              .map((v) => {
                    'id': v.id,
                    'name': v.name,
                    'email': v.email,
                    'rating': v.rating,
                  })
              .toList(),
          'customers': customers.map((c) => c.toJson()).toList(),
          'orders': orders.map((o) => o.toJson()).toList(),
        },
      };
    } catch (e) {
      throw Exception('Failed to export data: $e');
    }
  }
}
