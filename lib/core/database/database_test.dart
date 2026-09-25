import 'package:eventease/core/database/database_service.dart';
import 'package:eventease/core/database/database_finder.dart';

class DatabaseTest {
  static Future<void> runDatabaseTest() async {
    print('🧪 Running EventEase Database Test...\n');

    try {
      // Initialize database service
      final dbService = DatabaseService();

      // Show database info
      print('📊 Database Information:');
      print(await dbService.getDatabaseInfo());

      // Initialize database
      print('🔧 Initializing database...');
      await dbService.initializeDatabase();
      print('✅ Database initialized successfully!\n');

      // Run health check
      print('🏥 Running health check...');
      final health = await dbService.healthCheck();
      print('Health Status: ${health['status']}');
      if (health['status'] == 'healthy') {
        print('✅ Database is healthy!');
        print('   - Vendors: ${health['vendorCount']}');
        print('   - Customers: ${health['customerCount']}');
      } else {
        print('❌ Database health check failed: ${health['error']}');
      }
      print('');

      // Test basic operations
      print('🔍 Testing basic operations...');

      // Test vendor operations
      final vendors = await dbService.vendors.getAllVendors();
      print('   - Vendors loaded: ${vendors.length}');

      // Test customer operations
      final customers = await dbService.customers.getAllCustomers();
      print('   - Customers loaded: ${customers.length}');

      // Test order operations
      final orders = await dbService.orders.getAllOrders();
      print('   - Orders loaded: ${orders.length}');

      print('✅ All basic operations working!\n');

      // Show database statistics
      print('📈 Database Statistics:');
      final stats = await dbService.getDatabaseStatistics();
      print(
          '   - Database Size: ${(stats['database']['size'] / 1024).toStringAsFixed(2)} KB');
      print('   - Total Vendors: ${stats['vendors']['totalVendors']}');
      print('   - Total Orders: ${stats['orders']['totalOrders']}');
      print(
          '   - Total Revenue: RM ${stats['orders']['totalRevenue'].toStringAsFixed(2)}');

      print('\n🎉 Database test completed successfully!');
    } catch (e) {
      print('❌ Database test failed: $e');
      print('\n🔧 Troubleshooting:');
      print('1. Make sure you have run the app at least once');
      print('2. Check file permissions');
      print('3. Try running: DatabaseFinder.findAndDisplayDatabaseInfo()');
    }
  }

  static Future<void> findDatabaseLocation() async {
    await DatabaseFinder.findAndDisplayDatabaseInfo();
  }

  static Future<void> showInstructions() async {
    await DatabaseFinder.showDatabaseInstructions();
  }
}



