import 'package:eventease/core/database/database_service.dart';
import 'package:eventease/core/database/database_test.dart';
import 'package:eventease/core/database/database_finder.dart';

/// Example usage of the enhanced EventEase database system
class DatabaseUsageExample {
  static Future<void> runExample() async {
    print('🚀 EventEase Database Usage Example\n');

    // 1. Initialize the database service
    final dbService = DatabaseService();
    await dbService.initializeDatabase();

    // 2. Find your database location
    print('📍 Finding your database...');
    await DatabaseFinder.findAndDisplayDatabaseInfo();

    // 3. Example: Working with vendors
    print('\n🏪 Vendor Management Examples:');

    // Get all vendors
    final allVendors = await dbService.vendors.getAllVendors();
    print('   Total vendors: ${allVendors.length}');

    // Search vendors
    final cateringVendors = await dbService.vendors.searchVendors(
      query: 'catering',
      category: 'catering',
      minRating: 4.0,
    );
    print('   Catering vendors with 4+ rating: ${cateringVendors.length}');

    // Get featured vendors
    final featuredVendors = await dbService.vendors.getFeaturedVendors();
    print('   Featured vendors: ${featuredVendors.length}');

    // 4. Example: Working with orders
    print('\n📦 Order Management Examples:');

    // Get all orders
    final allOrders = await dbService.orders.getAllOrders();
    print('   Total orders: ${allOrders.length}');

    // Get today's orders
    final todaysOrders = await dbService.orders.getTodaysOrders();
    print('   Today\'s orders: ${todaysOrders.length}');

    // Get order statistics
    final orderStats = await dbService.orders.getOrderStatistics();
    print(
        '   Total revenue: RM ${orderStats['totalRevenue'].toStringAsFixed(2)}');
    print(
        '   Average order value: RM ${orderStats['averageOrderValue'].toStringAsFixed(2)}');

    // 5. Example: Working with cart
    print('\n🛒 Cart Management Examples:');

    // Add item to cart (example)
    // final cartItem = CartItem(...);
    // await dbService.cart.addToCart(cartItem, 'customer_123');

    // Get cart summary
    // final cartSummary = await dbService.cart.getCartSummary('customer_123');
    // print('   Cart total: RM ${cartSummary['total'].toStringAsFixed(2)}');

    // 6. Example: Working with favorites
    print('\n❤️ Favorites Management Examples:');

    // Add to favorites
    // await dbService.favorites.addToFavorites('customer_123', 'vendor_001', 'vendor');

    // Get favorites
    // final favorites = await dbService.favorites.getFavorites('customer_123');
    // print('   Customer favorites: ${favorites.length}');

    // 7. Database health check
    print('\n🏥 Database Health Check:');
    final health = await dbService.healthCheck();
    print('   Status: ${health['status']}');

    // 8. Get database statistics
    print('\n📊 Database Statistics:');
    final stats = await dbService.getDatabaseStatistics();
    print(
        '   Database size: ${(stats['database']['size'] / 1024).toStringAsFixed(2)} KB');
    print('   Total vendors: ${stats['vendors']['totalVendors']}');
    print('   Total orders: ${stats['orders']['totalOrders']}');

    print('\n✅ Example completed successfully!');
  }

  static Future<void> quickTest() async {
    print('🧪 Running Quick Database Test...\n');
    await DatabaseTest.runDatabaseTest();
  }

  static Future<void> findDatabase() async {
    print('🔍 Finding Database Location...\n');
    await DatabaseFinder.findAndDisplayDatabaseInfo();
  }

  static Future<void> showInstructions() async {
    print('📖 Database Instructions...\n');
    await DatabaseFinder.showDatabaseInstructions();
  }
}

/// How to use this in your app:
/// 
/// 1. In your main.dart or any widget:
///    ```dart
///    // Initialize database
///    final dbService = DatabaseService();
///    await dbService.initializeDatabase();
///    
///    // Use repositories
///    final vendors = await dbService.vendors.getAllVendors();
///    final orders = await dbService.orders.getOrdersByCustomer('customer_123');
///    ```
/// 
/// 2. In your providers (like CartProvider):
///    ```dart
///    final cartRepo = CartRepository();
///    await cartRepo.addToCart(cartItem, customerId);
///    final cartItems = await cartRepo.getCartItems(customerId);
///    ```
/// 
/// 3. Find your database:
///    ```dart
///    await DatabaseFinder.findAndDisplayDatabaseInfo();
///    ```
/// 
/// 4. Run tests:
///    ```dart
///    await DatabaseTest.runDatabaseTest();
///    ```



