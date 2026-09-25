import 'package:eventease/core/database/database_helper.dart';
import 'package:eventease/features/customer/data/models/customer.dart';
import 'dart:convert';

class CustomerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Convert Customer model to Map for database storage
  Map<String, dynamic> _customerToMap(Customer customer) {
    return {
      'id': customer.id,
      'name': customer.name,
      'email': customer.email,
      'phone': customer.phone,
      'preferences': customer.preferences.isNotEmpty
          ? jsonEncode(customer.preferences)
          : null,
      'createdAt': customer.createdAt.toIso8601String(),
      'lastActive': customer.lastActive.toIso8601String(),
      'status': customer.status.name,
      'segment': customer.segment.name,
      'favoriteCategories': customer.favoriteCategories.isNotEmpty
          ? jsonEncode(customer.favoriteCategories)
          : null,
      'totalSpent': customer.totalSpent,
      'totalBookings': customer.totalBookings,
      'averageRating': customer.averageRating,
      'reviewCount': customer.reviewCount,
      'analytics':
          customer.analytics.isNotEmpty ? jsonEncode(customer.analytics) : null,
      'isPremium': customer.isPremium ? 1 : 0,
      'profileImage': customer.profileImage,
    };
  }

  // Convert Map from database to Customer model
  Customer _mapToCustomer(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      preferences: map['preferences'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['preferences']))
          : {},
      createdAt: DateTime.parse(map['createdAt']),
      lastActive: DateTime.parse(map['lastActive']),
      status: CustomerStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CustomerStatus.active,
      ),
      segment: CustomerSegment.values.firstWhere(
        (e) => e.name == map['segment'],
        orElse: () => CustomerSegment.newCustomer,
      ),
      favoriteCategories: map['favoriteCategories'] != null
          ? List<String>.from(jsonDecode(map['favoriteCategories']))
          : [],
      totalSpent: map['totalSpent']?.toDouble() ?? 0.0,
      totalBookings: map['totalBookings'] ?? 0,
      averageRating: map['averageRating']?.toDouble() ?? 0.0,
      reviewCount: map['reviewCount'] ?? 0,
      analytics: map['analytics'] != null
          ? Map<String, dynamic>.from(jsonDecode(map['analytics']))
          : {},
      isPremium: map['isPremium'] == 1,
      profileImage: map['profileImage'],
    );
  }

  // CRUD Operations
  Future<int> insertCustomer(Customer customer) async {
    return await _dbHelper.insertCustomer(_customerToMap(customer));
  }

  Future<List<Customer>> getAllCustomers() async {
    final maps = await _dbHelper.getAllCustomers();
    return maps.map((map) => _mapToCustomer(map)).toList();
  }

  Future<Customer?> getCustomerById(String id) async {
    final map = await _dbHelper.getCustomerById(id);
    return map != null ? _mapToCustomer(map) : null;
  }

  Future<Customer?> getCustomerByEmail(String email) async {
    final map = await _dbHelper.getCustomerByEmail(email);
    return map != null ? _mapToCustomer(map) : null;
  }

  Future<int> updateCustomer(Customer customer) async {
    return await _dbHelper.updateCustomer(
        customer.id, _customerToMap(customer));
  }

  Future<int> deleteCustomer(String id) async {
    return await _dbHelper.deleteCustomer(id);
  }

  // Additional helper methods
  Future<List<Customer>> getActiveCustomers() async {
    final allCustomers = await getAllCustomers();
    return allCustomers
        .where((customer) => customer.status == CustomerStatus.active)
        .toList();
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final allCustomers = await getAllCustomers();
    return allCustomers.where((customer) {
      return customer.name.toLowerCase().contains(query.toLowerCase()) ||
          customer.email.toLowerCase().contains(query.toLowerCase()) ||
          (customer.phone != null && customer.phone!.contains(query));
    }).toList();
  }

  Future<List<Customer>> getCustomersBySegment(CustomerSegment segment) async {
    final allCustomers = await getAllCustomers();
    return allCustomers
        .where((customer) => customer.segment == segment)
        .toList();
  }

  Future<List<Customer>> getVipCustomers() async {
    return getCustomersBySegment(CustomerSegment.vipCustomer);
  }

  Future<List<Customer>> getRegularCustomers() async {
    return getCustomersBySegment(CustomerSegment.regularCustomer);
  }
}
