import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:eventease/features/services/data/models/finance/shop_performance.dart';

// Auth models
class User {
  final String id;
  final String name;
  final String email;
  final String password;
  final String role;
  final String? phone;
  final DateTime createdAt;
  final bool isSeedUser;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.phone,
    required this.createdAt,
    this.isSeedUser = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'isSeedUser': isSeedUser,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      role: json['role'],
      phone: json['phone'],
      createdAt: DateTime.parse(json['createdAt']),
      isSeedUser: json['isSeedUser'] ?? false,
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'eventease.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Returns the full path to the database file.
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'eventease.db');
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table for auth
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL,
        phone TEXT,
        createdAt TEXT NOT NULL,
        isSeedUser INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create vendors table
    await db.execute('''
      CREATE TABLE vendors (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        categories TEXT NOT NULL,
        subcategories TEXT,
        venueType TEXT,
        description TEXT NOT NULL,
        location TEXT NOT NULL,
        images TEXT,
        rating REAL NOT NULL DEFAULT 0.0,
        reviewCount INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'pending',
        documents TEXT,
        subscriptionTier TEXT NOT NULL DEFAULT 'free',
        logistics TEXT,
        contactInfo TEXT,
        email TEXT,
        phone TEXT,
        sampleServiceIds TEXT,
        planningHorizon INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        pendingBookings INTEGER DEFAULT 0,
        isActive INTEGER NOT NULL DEFAULT 1,
        imageUrl TEXT,
        offeredServices TEXT,
        pricing TEXT,
        availability TEXT,
        portfolio TEXT,
        socialMedia TEXT,
        tags TEXT,
        verified INTEGER DEFAULT 0,
        featured INTEGER DEFAULT 0
      )
    ''');

    // Create vendor_services table
    await db.execute('''
      CREATE TABLE vendor_services (
        id TEXT PRIMARY KEY,
        vendorId TEXT NOT NULL,
        vendorName TEXT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        category TEXT NOT NULL,
        subcategory TEXT,
        basePrice REAL NOT NULL,
        hourlyRate REAL,
        active INTEGER NOT NULL DEFAULT 1,
        approvalStatus TEXT NOT NULL DEFAULT 'pending',
        availability TEXT,
        maxBookingsPerDay INTEGER NOT NULL DEFAULT 10,
        advanceBookingDays INTEGER NOT NULL DEFAULT 7,
        type TEXT NOT NULL,
        images TEXT,
        options TEXT,
        requirements TEXT,
        logistics TEXT,
        status TEXT NOT NULL DEFAULT 'active',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        supportsAppointments INTEGER NOT NULL DEFAULT 0,
        supportsRentals INTEGER NOT NULL DEFAULT 0,
        amenities TEXT,
        cancellationPolicy TEXT,
        reviews TEXT,
        packages TEXT,
        allowedActions TEXT,
        locations TEXT,
        FOREIGN KEY (vendorId) REFERENCES vendors (id) ON DELETE CASCADE
      )
    ''');

    // Create customers table
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        phone TEXT,
        address TEXT,
        preferences TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1,
        profileImage TEXT,
        dateOfBirth TEXT,
        gender TEXT,
        location TEXT,
        interests TEXT,
        budgetRange TEXT,
        eventTypes TEXT,
        notificationSettings TEXT
      )
    ''');

    // Create orders table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        vendorId TEXT,
        orderNumber TEXT UNIQUE NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        totalAmount REAL NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL DEFAULT 0.0,
        serviceCharge REAL NOT NULL DEFAULT 0.0,
        discount REAL NOT NULL DEFAULT 0.0,
        paymentStatus TEXT NOT NULL DEFAULT 'pending',
        paymentMethod TEXT,
        paymentId TEXT,
        orderDate TEXT NOT NULL,
        deliveryDate TEXT,
        notes TEXT,
        shippingAddress TEXT,
        billingAddress TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE,
        FOREIGN KEY (vendorId) REFERENCES vendors (id) ON DELETE SET NULL
      )
    ''');

    // Create order_items table
    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        orderId TEXT NOT NULL,
        serviceId TEXT NOT NULL,
        serviceName TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unitPrice REAL NOT NULL,
        totalPrice REAL NOT NULL,
        vendorId TEXT NOT NULL,
        vendorName TEXT,
        serviceType TEXT NOT NULL,
        options TEXT,
        requirements TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (orderId) REFERENCES orders (id) ON DELETE CASCADE,
        FOREIGN KEY (serviceId) REFERENCES vendor_services (id) ON DELETE CASCADE,
        FOREIGN KEY (vendorId) REFERENCES vendors (id) ON DELETE CASCADE
      )
    ''');

    // Create cart_items table
    await db.execute('''
      CREATE TABLE cart_items (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        serviceId TEXT NOT NULL,
        serviceName TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        unitPrice REAL NOT NULL,
        totalPrice REAL NOT NULL,
        vendorId TEXT NOT NULL,
        vendorName TEXT,
        serviceType TEXT NOT NULL,
        options TEXT,
        requirements TEXT,
        addedAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE,
        FOREIGN KEY (serviceId) REFERENCES vendor_services (id) ON DELETE CASCADE,
        FOREIGN KEY (vendorId) REFERENCES vendors (id) ON DELETE CASCADE
      )
    ''');

    // Create favorites table
    await db.execute('''
      CREATE TABLE favorites (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        itemId TEXT NOT NULL,
        itemType TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Create events table
    await db.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        eventType TEXT NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        location TEXT,
        guestCount INTEGER,
        budget REAL,
        status TEXT NOT NULL DEFAULT 'planning',
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE
      )
    ''');

    // Create bookings table
    await db.execute('''
      CREATE TABLE bookings (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        vendorId TEXT NOT NULL,
        serviceId TEXT NOT NULL,
        eventId TEXT,
        bookingDate TEXT NOT NULL,
        startTime TEXT,
        endTime TEXT,
        status TEXT NOT NULL DEFAULT 'pending',
        totalAmount REAL NOT NULL,
        deposit REAL NOT NULL DEFAULT 0.0,
        notes TEXT,
        specialRequirements TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE,
        FOREIGN KEY (vendorId) REFERENCES vendors (id) ON DELETE CASCADE,
        FOREIGN KEY (serviceId) REFERENCES vendor_services (id) ON DELETE CASCADE,
        FOREIGN KEY (eventId) REFERENCES events (id) ON DELETE SET NULL
      )
    ''');

    // Create chat_conversations table
    await db.execute('''
      CREATE TABLE chat_conversations (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        vendorId TEXT NOT NULL,
        vendorName TEXT NOT NULL,
        vendorEmail TEXT NOT NULL,
        vendorPhone TEXT,
        vendorAvatar TEXT,
        isOnline INTEGER NOT NULL DEFAULT 0,
        lastMessageTime TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE,
        FOREIGN KEY (vendorId) REFERENCES vendors (id) ON DELETE CASCADE
      )
    ''');

    // Create chat_messages table
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        conversationId TEXT NOT NULL,
        senderId TEXT NOT NULL,
        senderType TEXT NOT NULL,
        message TEXT NOT NULL,
        messageType TEXT NOT NULL DEFAULT 'text',
        timestamp TEXT NOT NULL,
        isRead INTEGER NOT NULL DEFAULT 0,
        metadata TEXT,
        FOREIGN KEY (conversationId) REFERENCES chat_conversations (id) ON DELETE CASCADE
      )
    ''');

    // Create reviews table
    await db.execute('''
      CREATE TABLE reviews (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        vendorId TEXT NOT NULL,
        serviceId TEXT,
        orderId TEXT,
        rating INTEGER NOT NULL,
        comment TEXT,
        images TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (customerId) REFERENCES customers (id) ON DELETE CASCADE,
        FOREIGN KEY (vendorId) REFERENCES vendors (id) ON DELETE CASCADE,
        FOREIGN KEY (serviceId) REFERENCES vendor_services (id) ON DELETE SET NULL,
        FOREIGN KEY (orderId) REFERENCES orders (id) ON DELETE SET NULL
      )
    ''');

    // Create shop_performance table
    await db.execute('''
      CREATE TABLE shop_performance (
        id TEXT PRIMARY KEY,
        vendorId TEXT NOT NULL,
        date TEXT NOT NULL,
        totalRevenue REAL NOT NULL,
        totalOrders INTEGER NOT NULL,
        uniqueCustomers INTEGER NOT NULL,
        averageOrderValue REAL NOT NULL,
        conversionRate REAL NOT NULL,
        revenueByCategory TEXT NOT NULL,
        ordersByCategory TEXT NOT NULL,
        topProducts TEXT NOT NULL,
        customerSegments TEXT NOT NULL,
        metadata TEXT,
        FOREIGN KEY (vendorId) REFERENCES vendors (id) ON DELETE CASCADE
      )
    ''');

    // Create product_performance table
    await db.execute('''
      CREATE TABLE product_performance (
        productId TEXT PRIMARY KEY,
        productName TEXT NOT NULL,
        unitsSold INTEGER NOT NULL,
        revenue REAL NOT NULL,
        profit REAL NOT NULL,
        views INTEGER NOT NULL,
        clicks INTEGER NOT NULL,
        conversionRate REAL NOT NULL,
        averageRating REAL NOT NULL,
        reviewCount INTEGER NOT NULL,
        isActive INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Create customer_segments table
    await db.execute('''
      CREATE TABLE customer_segments (
        segmentId TEXT PRIMARY KEY,
        segmentName TEXT NOT NULL,
        customerCount INTEGER NOT NULL,
        totalRevenue REAL NOT NULL,
        averageOrderValue REAL NOT NULL,
        totalOrders INTEGER NOT NULL,
        retentionRate REAL NOT NULL,
        demographics TEXT NOT NULL
      )
    ''');

    // Create indexes for better performance
    await db
        .execute('CREATE INDEX idx_vendors_category ON vendors(categories)');
    await db.execute('CREATE INDEX idx_vendors_status ON vendors(status)');
    await db.execute(
        'CREATE INDEX idx_vendor_services_vendor ON vendor_services(vendorId)');
    await db.execute(
        'CREATE INDEX idx_vendor_services_category ON vendor_services(category)');
    await db.execute('CREATE INDEX idx_orders_customer ON orders(customerId)');
    await db.execute('CREATE INDEX idx_orders_vendor ON orders(vendorId)');
    await db.execute('CREATE INDEX idx_orders_status ON orders(status)');
    await db.execute(
        'CREATE INDEX idx_cart_items_customer ON cart_items(customerId)');
    await db.execute(
        'CREATE INDEX idx_favorites_customer ON favorites(customerId)');
    await db
        .execute('CREATE INDEX idx_bookings_customer ON bookings(customerId)');
    await db.execute('CREATE INDEX idx_bookings_vendor ON bookings(vendorId)');
    await db.execute(
        'CREATE INDEX idx_chat_conversations_customer ON chat_conversations(customerId)');
    await db.execute(
        'CREATE INDEX idx_chat_messages_conversation ON chat_messages(conversationId)');
    await db.execute('CREATE INDEX idx_reviews_vendor ON reviews(vendorId)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add migration logic as needed
    }
  }

  // Auth CRUD operations
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('users', user.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (results.isNotEmpty) {
      return User.fromJson(results.first);
    }
    return null;
  }

  Future<User?> getUserById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      return User.fromJson(results.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query('users');
    return results.map((map) => User.fromJson(map)).toList();
  }

  Future<int> updateUser(String id, Map<String, dynamic> userData) async {
    Database db = await database;
    return await db.update('users', userData, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteUser(String id) async {
    Database db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // Shop Performance CRUD operations
  Future<int> insertShopPerformance(Map<String, dynamic> performance) async {
    Database db = await database;
    return await db.insert('shop_performance', performance,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getShopPerformances(
      String vendorId) async {
    Database db = await database;
    return await db.query('shop_performance',
        where: 'vendorId = ?', whereArgs: [vendorId]);
  }

  Future<Map<String, dynamic>?> getLatestShopPerformance(
      String vendorId) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'shop_performance',
      where: 'vendorId = ?',
      whereArgs: [vendorId],
      orderBy: 'date DESC',
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateShopPerformance(
      String id, Map<String, dynamic> performance) async {
    Database db = await database;
    return await db.update('shop_performance', performance,
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteShopPerformance(String id) async {
    Database db = await database;
    return await db
        .delete('shop_performance', where: 'id = ?', whereArgs: [id]);
  }

  // Product Performance CRUD operations
  Future<int> insertProductPerformance(Map<String, dynamic> product) async {
    Database db = await database;
    return await db.insert('product_performance', product,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getProductPerformances() async {
    Database db = await database;
    return await db.query('product_performance');
  }

  Future<Map<String, dynamic>?> getProductPerformance(String productId) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'product_performance',
      where: 'productId = ?',
      whereArgs: [productId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateProductPerformance(
      String productId, Map<String, dynamic> product) async {
    Database db = await database;
    return await db.update('product_performance', product,
        where: 'productId = ?', whereArgs: [productId]);
  }

  Future<int> deleteProductPerformance(String productId) async {
    Database db = await database;
    return await db.delete('product_performance',
        where: 'productId = ?', whereArgs: [productId]);
  }

  // Customer Segment CRUD operations
  Future<int> insertCustomerSegment(Map<String, dynamic> segment) async {
    Database db = await database;
    return await db.insert('customer_segment', segment,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCustomerSegments() async {
    Database db = await database;
    return await db.query('customer_segment');
  }

  Future<Map<String, dynamic>?> getCustomerSegment(String segmentId) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'customer_segment',
      where: 'segmentId = ?',
      whereArgs: [segmentId],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateCustomerSegment(
      String segmentId, Map<String, dynamic> segment) async {
    Database db = await database;
    return await db.update('customer_segment', segment,
        where: 'segmentId = ?', whereArgs: [segmentId]);
  }

  Future<int> deleteCustomerSegment(String segmentId) async {
    Database db = await database;
    return await db.delete('customer_segment',
        where: 'segmentId = ?', whereArgs: [segmentId]);
  }

  // ==================== VENDOR CRUD OPERATIONS ====================
  Future<int> insertVendor(Map<String, dynamic> vendor) async {
    Database db = await database;
    return await db.insert('vendors', vendor,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllVendors() async {
    Database db = await database;
    return await db.query('vendors', orderBy: 'createdAt DESC');
  }

  Future<Map<String, dynamic>?> getVendorById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'vendors',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getVendorsByCategory(
      String category) async {
    Database db = await database;
    return await db.query(
      'vendors',
      where: 'categories LIKE ?',
      whereArgs: ['%$category%'],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updateVendor(String id, Map<String, dynamic> vendor) async {
    Database db = await database;
    return await db.update('vendors', vendor, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteVendor(String id) async {
    Database db = await database;
    return await db.delete('vendors', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== VENDOR SERVICES CRUD OPERATIONS ====================
  Future<int> insertVendorService(Map<String, dynamic> service) async {
    Database db = await database;
    return await db.insert('vendor_services', service,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllVendorServices() async {
    Database db = await database;
    return await db.query('vendor_services', orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> getVendorServicesByVendor(
      String vendorId) async {
    Database db = await database;
    return await db.query(
      'vendor_services',
      where: 'vendorId = ?',
      whereArgs: [vendorId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getVendorServicesByCategory(
      String category) async {
    Database db = await database;
    return await db.query(
      'vendor_services',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'createdAt DESC',
    );
  }

  Future<Map<String, dynamic>?> getVendorServiceById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'vendor_services',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateVendorService(
      String id, Map<String, dynamic> service) async {
    Database db = await database;
    return await db
        .update('vendor_services', service, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteVendorService(String id) async {
    Database db = await database;
    return await db.delete('vendor_services', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CUSTOMER CRUD OPERATIONS ====================
  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    Database db = await database;
    return await db.insert('customers', customer,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    Database db = await database;
    return await db.query('customers', orderBy: 'createdAt DESC');
  }

  Future<Map<String, dynamic>?> getCustomerById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<Map<String, dynamic>?> getCustomerByEmail(String email) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'customers',
      where: 'email = ?',
      whereArgs: [email],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateCustomer(String id, Map<String, dynamic> customer) async {
    Database db = await database;
    return await db
        .update('customers', customer, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCustomer(String id) async {
    Database db = await database;
    return await db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== ORDER CRUD OPERATIONS ====================
  Future<int> insertOrder(Map<String, dynamic> order) async {
    Database db = await database;
    return await db.insert('orders', order,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getAllOrders() async {
    Database db = await database;
    return await db.query('orders', orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> getOrdersByCustomer(
      String customerId) async {
    Database db = await database;
    return await db.query(
      'orders',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getOrdersByVendor(String vendorId) async {
    Database db = await database;
    return await db.query(
      'orders',
      where: 'vendorId = ?',
      whereArgs: [vendorId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<Map<String, dynamic>?> getOrderById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateOrder(String id, Map<String, dynamic> order) async {
    Database db = await database;
    return await db.update('orders', order, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteOrder(String id) async {
    Database db = await database;
    return await db.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== ORDER ITEMS CRUD OPERATIONS ====================
  Future<int> insertOrderItem(Map<String, dynamic> orderItem) async {
    Database db = await database;
    return await db.insert('order_items', orderItem,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getOrderItemsByOrder(
      String orderId) async {
    Database db = await database;
    return await db.query(
      'order_items',
      where: 'orderId = ?',
      whereArgs: [orderId],
      orderBy: 'createdAt ASC',
    );
  }

  Future<int> updateOrderItem(String id, Map<String, dynamic> orderItem) async {
    Database db = await database;
    return await db
        .update('order_items', orderItem, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteOrderItem(String id) async {
    Database db = await database;
    return await db.delete('order_items', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CART ITEMS CRUD OPERATIONS ====================
  Future<int> insertCartItem(Map<String, dynamic> cartItem) async {
    Database db = await database;
    return await db.insert('cart_items', cartItem,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getCartItemsByCustomer(
      String customerId) async {
    Database db = await database;
    return await db.query(
      'cart_items',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'addedAt DESC',
    );
  }

  Future<int> updateCartItem(String id, Map<String, dynamic> cartItem) async {
    Database db = await database;
    return await db
        .update('cart_items', cartItem, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCartItem(String id) async {
    Database db = await database;
    return await db.delete('cart_items', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clearCart(String customerId) async {
    Database db = await database;
    return await db
        .delete('cart_items', where: 'customerId = ?', whereArgs: [customerId]);
  }

  // ==================== FAVORITES CRUD OPERATIONS ====================
  Future<int> insertFavorite(Map<String, dynamic> favorite) async {
    Database db = await database;
    return await db.insert('favorites', favorite,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getFavoritesByCustomer(
      String customerId) async {
    Database db = await database;
    return await db.query(
      'favorites',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<bool> isFavorite(
      String customerId, String itemId, String itemType) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'favorites',
      where: 'customerId = ? AND itemId = ? AND itemType = ?',
      whereArgs: [customerId, itemId, itemType],
    );
    return results.isNotEmpty;
  }

  Future<int> removeFavorite(
      String customerId, String itemId, String itemType) async {
    Database db = await database;
    return await db.delete(
      'favorites',
      where: 'customerId = ? AND itemId = ? AND itemType = ?',
      whereArgs: [customerId, itemId, itemType],
    );
  }

  // ==================== EVENTS CRUD OPERATIONS ====================
  Future<int> insertEvent(Map<String, dynamic> event) async {
    Database db = await database;
    return await db.insert('events', event,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getEventsByCustomer(
      String customerId) async {
    Database db = await database;
    return await db.query(
      'events',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'startDate ASC',
    );
  }

  Future<Map<String, dynamic>?> getEventById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'events',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateEvent(String id, Map<String, dynamic> event) async {
    Database db = await database;
    return await db.update('events', event, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteEvent(String id) async {
    Database db = await database;
    return await db.delete('events', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== BOOKINGS CRUD OPERATIONS ====================
  Future<int> insertBooking(Map<String, dynamic> booking) async {
    Database db = await database;
    return await db.insert('bookings', booking,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getBookingsByCustomer(
      String customerId) async {
    Database db = await database;
    return await db.query(
      'bookings',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'bookingDate ASC',
    );
  }

  Future<List<Map<String, dynamic>>> getBookingsByVendor(
      String vendorId) async {
    Database db = await database;
    return await db.query(
      'bookings',
      where: 'vendorId = ?',
      whereArgs: [vendorId],
      orderBy: 'bookingDate ASC',
    );
  }

  Future<Map<String, dynamic>?> getBookingById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'bookings',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateBooking(String id, Map<String, dynamic> booking) async {
    Database db = await database;
    return await db
        .update('bookings', booking, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteBooking(String id) async {
    Database db = await database;
    return await db.delete('bookings', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CHAT CONVERSATIONS CRUD OPERATIONS ====================
  Future<int> insertChatConversation(Map<String, dynamic> conversation) async {
    Database db = await database;
    return await db.insert('chat_conversations', conversation,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getChatConversationsByCustomer(
      String customerId) async {
    Database db = await database;
    return await db.query(
      'chat_conversations',
      where: 'customerId = ?',
      whereArgs: [customerId],
      orderBy: 'lastMessageTime DESC',
    );
  }

  Future<Map<String, dynamic>?> getChatConversationById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'chat_conversations',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateChatConversation(
      String id, Map<String, dynamic> conversation) async {
    Database db = await database;
    return await db.update('chat_conversations', conversation,
        where: 'id = ?', whereArgs: [id]);
  }

  // ==================== CHAT MESSAGES CRUD OPERATIONS ====================
  Future<int> insertChatMessage(Map<String, dynamic> message) async {
    Database db = await database;
    return await db.insert('chat_messages', message,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getChatMessagesByConversation(
      String conversationId) async {
    Database db = await database;
    return await db.query(
      'chat_messages',
      where: 'conversationId = ?',
      whereArgs: [conversationId],
      orderBy: 'timestamp ASC',
    );
  }

  Future<int> updateChatMessage(String id, Map<String, dynamic> message) async {
    Database db = await database;
    return await db
        .update('chat_messages', message, where: 'id = ?', whereArgs: [id]);
  }

  // ==================== REVIEWS CRUD OPERATIONS ====================
  Future<int> insertReview(Map<String, dynamic> review) async {
    Database db = await database;
    return await db.insert('reviews', review,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getReviewsByVendor(String vendorId) async {
    Database db = await database;
    return await db.query(
      'reviews',
      where: 'vendorId = ?',
      whereArgs: [vendorId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getReviewsByService(
      String serviceId) async {
    Database db = await database;
    return await db.query(
      'reviews',
      where: 'serviceId = ?',
      whereArgs: [serviceId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<Map<String, dynamic>?> getReviewById(String id) async {
    Database db = await database;
    List<Map<String, dynamic>> results = await db.query(
      'reviews',
      where: 'id = ?',
      whereArgs: [id],
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> updateReview(String id, Map<String, dynamic> review) async {
    Database db = await database;
    return await db.update('reviews', review, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteReview(String id) async {
    Database db = await database;
    return await db.delete('reviews', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== UTILITY METHODS ====================
  Future<void> clearAllData() async {
    Database db = await database;
    await db.delete('shop_performance');
    await db.delete('product_performance');
    await db.delete('customer_segments');
    await db.delete('reviews');
    await db.delete('chat_messages');
    await db.delete('chat_conversations');
    await db.delete('bookings');
    await db.delete('events');
    await db.delete('favorites');
    await db.delete('cart_items');
    await db.delete('order_items');
    await db.delete('orders');
    await db.delete('vendor_services');
    await db.delete('vendors');
    await db.delete('customers');
  }

  Future<void> close() async {
    Database db = await database;
    db.close();
  }

  // Helper methods for converting complex objects to/from JSON strings
  static Map<String, dynamic> shopPerformanceToMap(
      ShopPerformance performance) {
    return {
      'id': performance.id,
      'vendorId': performance.vendorId,
      'date': performance.date.toIso8601String(),
      'totalRevenue': performance.totalRevenue,
      'totalOrders': performance.totalOrders,
      'uniqueCustomers': performance.uniqueCustomers,
      'averageOrderValue': performance.averageOrderValue,
      'conversionRate': performance.conversionRate,
      'revenueByCategory': jsonEncode(performance.revenueByCategory),
      'ordersByCategory': jsonEncode(performance.ordersByCategory),
      'topProducts':
          jsonEncode(performance.topProducts.map((p) => p.toJson()).toList()),
      'customerSegments': jsonEncode(
          performance.customerSegments.map((s) => s.toJson()).toList()),
      'metadata': performance.metadata != null
          ? jsonEncode(performance.metadata)
          : null,
    };
  }

  static ShopPerformance mapToShopPerformance(Map<String, dynamic> map) {
    return ShopPerformance(
      id: map['id'],
      vendorId: map['vendorId'],
      date: DateTime.parse(map['date']),
      totalRevenue: map['totalRevenue'],
      totalOrders: map['totalOrders'],
      uniqueCustomers: map['uniqueCustomers'],
      averageOrderValue: map['averageOrderValue'],
      conversionRate: map['conversionRate'],
      revenueByCategory:
          Map<String, double>.from(jsonDecode(map['revenueByCategory'])),
      ordersByCategory:
          Map<String, int>.from(jsonDecode(map['ordersByCategory'])),
      topProducts: (jsonDecode(map['topProducts']) as List)
          .map((p) => ProductPerformance(
                productId: p['productId'],
                productName: p['productName'],
                unitsSold: p['unitsSold'],
                revenue: p['revenue'],
                profit: p['profit'],
                views: p['views'],
                clicks: p['clicks'],
                conversionRate: p['conversionRate'],
                averageRating: p['averageRating'],
                reviewCount: p['reviewCount'],
                isActive: p['isActive'],
              ))
          .toList(),
      customerSegments: (jsonDecode(map['customerSegments']) as List)
          .map((s) => CustomerSegment(
                segmentId: s['segmentId'],
                segmentName: s['segmentName'],
                customerCount: s['customerCount'],
                totalRevenue: s['totalRevenue'],
                averageOrderValue: s['averageOrderValue'],
                totalOrders: s['totalOrders'],
                retentionRate: s['retentionRate'],
                demographics: Map<String, dynamic>.from(s['demographics']),
              ))
          .toList(),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['metadata']))
          : null,
    );
  }

  static Map<String, dynamic> productPerformanceToMap(
      ProductPerformance product) {
    return {
      'productId': product.productId,
      'productName': product.productName,
      'unitsSold': product.unitsSold,
      'revenue': product.revenue,
      'profit': product.profit,
      'views': product.views,
      'clicks': product.clicks,
      'conversionRate': product.conversionRate,
      'averageRating': product.averageRating,
      'reviewCount': product.reviewCount,
      'isActive': product.isActive ? 1 : 0,
    };
  }

  static ProductPerformance mapToProductPerformance(Map<String, dynamic> map) {
    return ProductPerformance(
      productId: map['productId'],
      productName: map['productName'],
      unitsSold: map['unitsSold'],
      revenue: map['revenue'],
      profit: map['profit'],
      views: map['views'],
      clicks: map['clicks'],
      conversionRate: map['conversionRate'],
      averageRating: map['averageRating'],
      reviewCount: map['reviewCount'],
      isActive: map['isActive'] == 1,
    );
  }

  static Map<String, dynamic> customerSegmentToMap(CustomerSegment segment) {
    return {
      'segmentId': segment.segmentId,
      'segmentName': segment.segmentName,
      'customerCount': segment.customerCount,
      'totalRevenue': segment.totalRevenue,
      'averageOrderValue': segment.averageOrderValue,
      'totalOrders': segment.totalOrders,
      'retentionRate': segment.retentionRate,
      'demographics': jsonEncode(segment.demographics),
    };
  }

  static CustomerSegment mapToCustomerSegment(Map<String, dynamic> map) {
    return CustomerSegment(
      segmentId: map['segmentId'],
      segmentName: map['segmentName'],
      customerCount: map['customerCount'],
      totalRevenue: map['totalRevenue'],
      averageOrderValue: map['averageOrderValue'],
      totalOrders: map['totalOrders'],
      retentionRate: map['retentionRate'],
      demographics: Map<String, dynamic>.from(jsonDecode(map['demographics'])),
    );
  }
}
