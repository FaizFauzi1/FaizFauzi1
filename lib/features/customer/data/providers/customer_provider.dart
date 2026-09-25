import 'package:flutter/material.dart';
import 'package:eventease/features/customer/data/models/customer.dart';
import 'package:eventease/features/support/data/models/customer_interaction.dart';
import 'package:eventease/features/booking/data/models/booking.dart';
import 'package:eventease/features/booking/data/providers/booking_provider.dart';
import 'package:eventease/features/chat/data/providers/chat_provider.dart';
import 'package:eventease/features/booking/data/models/installment_plan.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerProvider with ChangeNotifier {
  final List<Customer> _customers = [];
  final List<CustomerInteraction> _interactions = [];
  final BookingProvider _bookingProvider;
  final ChatProvider _chatProvider;

  CustomerProvider(this._bookingProvider, this._chatProvider) {
    _initializeCustomers();
    _initializeInteractions();
  }

  // Getters
  List<Customer> get customers => List.unmodifiable(_customers);
  List<CustomerInteraction> get interactions => List.unmodifiable(_interactions);

  // Get customer by ID
  Customer? getCustomerById(String customerId) {
    try {
      return _customers.firstWhere(
        (customer) => customer.id == customerId,
      );
    } catch (e) {
      return null;
    }
  }

  // Get customer by email
  Customer? getCustomerByEmail(String email) {
    try {
      return _customers.firstWhere((customer) => customer.email == email);
    } catch (e) {
      return null;
    }
  }

  // Get customers for a specific vendor
  List<Customer> getCustomersForVendor(String vendorId) {
    final vendorBookings = _bookingProvider.bookings
        .where((booking) => booking.vendorId == vendorId)
        .toList();

    final customerEmails = vendorBookings
        .map((booking) => booking.customerEmail)
        .toSet()
        .toList();

    return customerEmails
        .map((email) => getCustomerByEmail(email))
        .where((customer) => customer != null)
        .cast<Customer>()
        .toList();
  }

  // Get customer interactions for a vendor
  List<CustomerInteraction> getInteractionsForVendor(String vendorId) {
    return _interactions
        .where((interaction) => interaction.vendorId == vendorId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get customer interactions for a specific customer
  List<CustomerInteraction> getInteractionsForCustomer(String customerId) {
    return _interactions
        .where((interaction) => interaction.customerId == customerId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get customer analytics for a vendor
  Map<String, dynamic> getCustomerAnalytics(String vendorId) {
    final vendorCustomers = getCustomersForVendor(vendorId);
    final vendorInteractions = getInteractionsForVendor(vendorId);

    if (vendorCustomers.isEmpty) {
      return {
        'totalCustomers': 0,
        'newCustomers': 0,
        'returningCustomers': 0,
        'vipCustomers': 0,
        'totalRevenue': 0.0,
        'averageOrderValue': 0.0,
        'customerRetentionRate': 0.0,
        'recentInteractions': 0,
      };
    }

    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final newCustomers = vendorCustomers
        .where((customer) => customer.createdAt.isAfter(thirtyDaysAgo))
        .length;

    final returningCustomers = vendorCustomers
        .where((customer) => customer.totalBookings > 1)
        .length;

    final vipCustomers = vendorCustomers
        .where((customer) => customer.segment == CustomerSegment.vipCustomer)
        .length;

    final totalRevenue = vendorCustomers
        .fold<double>(0, (sum, customer) => sum + customer.totalSpent);

    final averageOrderValue = totalRevenue / vendorCustomers.length;

    final recentInteractions = vendorInteractions
        .where((interaction) => interaction.timestamp.isAfter(thirtyDaysAgo))
        .length;

    // Calculate retention rate (simplified)
    final activeCustomers = vendorCustomers
        .where((customer) => customer.lastActive.isAfter(thirtyDaysAgo))
        .length;

    final customerRetentionRate = vendorCustomers.isNotEmpty
        ? (activeCustomers / vendorCustomers.length) * 100
        : 0.0;

    return {
      'totalCustomers': vendorCustomers.length,
      'newCustomers': newCustomers,
      'returningCustomers': returningCustomers,
      'vipCustomers': vipCustomers,
      'totalRevenue': totalRevenue,
      'averageOrderValue': averageOrderValue,
      'customerRetentionRate': customerRetentionRate,
      'recentInteractions': recentInteractions,
    };
  }

  // Get customer segments distribution
  Map<CustomerSegment, int> getCustomerSegments(String vendorId) {
    final vendorCustomers = getCustomersForVendor(vendorId);
    final segments = <CustomerSegment, int>{};

    for (final segment in CustomerSegment.values) {
      segments[segment] = vendorCustomers
          .where((customer) => customer.segment == segment)
          .length;
    }

    return segments;
  }

  // Get top customers by spending
  List<Customer> getTopCustomersBySpending(String vendorId, {int limit = 10}) {
    final vendorCustomers = getCustomersForVendor(vendorId);
    return vendorCustomers
      ..sort((a, b) => b.totalSpent.compareTo(a.totalSpent))
      ..take(limit)
      .toList();
  }

  // Get recent customer interactions
  List<CustomerInteraction> getRecentInteractions(String vendorId, {int limit = 20}) {
    return getInteractionsForVendor(vendorId).take(limit).toList();
  }

  // Add new customer interaction
  void addInteraction(CustomerInteraction interaction) {
    _interactions.add(interaction);
    notifyListeners();
  }

  // Mark interaction as read
  void markInteractionAsRead(String interactionId) {
    final index = _interactions.indexWhere((i) => i.id == interactionId);
    if (index != -1) {
      _interactions[index] = _interactions[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  // Update customer information
  void updateCustomer(Customer updatedCustomer) {
    final index = _customers.indexWhere((c) => c.id == updatedCustomer.id);
    if (index != -1) {
      _customers[index] = updatedCustomer;
      notifyListeners();
    }
  }

  // Initialize customers from booking data
  void _initializeCustomers() {
    final allBookings = _bookingProvider.bookings;
    final customerEmails = allBookings
        .map((booking) => booking.customerEmail)
        .toSet()
        .toList();

    for (final email in customerEmails) {
      if (getCustomerByEmail(email) == null) {
        final customer = Customer.fromBookingData(email, allBookings);
        _customers.add(customer);
      }
    }
  }

  // Initialize interactions from existing data
  void _initializeInteractions() {
    // Create interactions from booking history
    for (final booking in _bookingProvider.bookings) {
      final interaction = CustomerInteraction.fromBookingEvent(
        booking.customerEmail,
        booking.vendorId,
        booking.status,
        booking.id,
        booking.amount,
      );
      _interactions.add(interaction);
    }

    // Create interactions from chat messages (if available)
    // This would be enhanced when chat data is available
  }

  /// Get customer bookings with installment payment details
  /// Returns a list of bookings that have installment plans with detailed payment information
  Future<List<Map<String, dynamic>>> getCustomerBookingsWithInstallments(String customerId) async {
    try {
      final supabase = Supabase.instance.client;
      
      // Fetch bookings with installment plans and payments
      final response = await supabase
          .from('bookings')
          .select('''
            *,
            vendor_services(name, vendor_id),
            customer_user(name, email, phone),
            installment_plans(
              *,
              installment_payments(*)
            )
          ''')
          .eq('customer_id', customerId)
          .not('installment_plans', 'is', null)
          .order('event_date', ascending: true);

      final bookingsWithInstallments = <Map<String, dynamic>>[];

      for (final bookingData in response as List) {
        final installmentPlans = bookingData['installment_plans'] as List?;
        
        if (installmentPlans != null && installmentPlans.isNotEmpty) {
          for (final planData in installmentPlans) {
            final plan = InstallmentPlan.fromSupabase(planData);
            final payments = plan.payments;
            
            // Calculate payment statistics
            final totalPaid = payments
                .where((p) => p.status == InstallmentPaymentStatus.paid)
                .fold<double>(0, (sum, p) => sum + p.amount);
            
            final pendingPayments = payments
                .where((p) => p.status == InstallmentPaymentStatus.pending)
                .toList();
            
            final latePayments = payments
                .where((p) => p.status == InstallmentPaymentStatus.late)
                .toList();
            
            final nextPayment = pendingPayments.isNotEmpty
                ? pendingPayments.reduce((a, b) => 
                    a.dueDate.isBefore(b.dueDate) ? a : b)
                : null;

            bookingsWithInstallments.add({
              'booking_id': bookingData['id'],
              'service_name': bookingData['vendor_services']?['name'] ?? 'Unknown Service',
              'vendor_id': bookingData['vendor_services']?['vendor_id'],
              'event_date': DateTime.parse(bookingData['event_date']),
              'booking_status': bookingData['status'],
              'total_amount': plan.totalAmount,
              'deposit_amount': plan.depositAmount,
              'remaining_balance': plan.remainingBalance,
              'total_paid': totalPaid,
              'number_of_installments': plan.numberOfInstallments,
              'installment_plan_status': plan.status.name,
              'next_payment': nextPayment != null ? {
                'id': nextPayment.id,
                'amount': nextPayment.amount,
                'due_date': nextPayment.dueDate,
                'status': nextPayment.status.name,
                'days_until_due': nextPayment.dueDate.difference(DateTime.now()).inDays,
              } : null,
              'pending_payments_count': pendingPayments.length,
              'late_payments_count': latePayments.length,
              'all_payments': payments.map((p) => {
                'id': p.id,
                'amount': p.amount,
                'due_date': p.dueDate,
                'status': p.status.name,
                'payment_id': p.paymentId,
                'is_overdue': p.status == InstallmentPaymentStatus.pending && 
                              p.dueDate.isBefore(DateTime.now()),
              }).toList(),
              'created_at': plan.createdAt,
              'updated_at': plan.updatedAt,
            });
          }
        }
      }

      return bookingsWithInstallments;
    } catch (e) {
      print('Error fetching customer bookings with installments: $e');
      return [];
    }
  }

  /// Get upcoming installment payments for a customer
  /// Returns payments due within the specified number of days
  Future<List<Map<String, dynamic>>> getUpcomingInstallmentPayments(
    String customerId, {
    int daysAhead = 30,
  }) async {
    try {
      final bookingsWithInstallments = await getCustomerBookingsWithInstallments(customerId);
      final upcomingPayments = <Map<String, dynamic>>[];
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: daysAhead));

      for (final booking in bookingsWithInstallments) {
        final allPayments = booking['all_payments'] as List<Map<String, dynamic>>;
        
        for (final payment in allPayments) {
          final dueDate = payment['due_date'] as DateTime;
          final status = payment['status'] as String;
          
          // Include pending payments due within the timeframe or late payments
          if ((status == 'pending' && dueDate.isBefore(futureDate)) || 
              status == 'late') {
            upcomingPayments.add({
              ...payment,
              'booking_id': booking['booking_id'],
              'service_name': booking['service_name'],
              'event_date': booking['event_date'],
              'total_booking_amount': booking['total_amount'],
            });
          }
        }
      }

      // Sort by due date (earliest first)
      upcomingPayments.sort((a, b) => 
        (a['due_date'] as DateTime).compareTo(b['due_date'] as DateTime));

      return upcomingPayments;
    } catch (e) {
      print('Error fetching upcoming installment payments: $e');
      return [];
    }
  }

  /// Get installment payment summary for a customer
  Future<Map<String, dynamic>> getInstallmentPaymentSummary(String customerId) async {
    try {
      final bookingsWithInstallments = await getCustomerBookingsWithInstallments(customerId);
      
      double totalOutstanding = 0;
      double totalPaid = 0;
      int totalPendingPayments = 0;
      int totalLatePayments = 0;
      int activeInstallmentPlans = 0;

      for (final booking in bookingsWithInstallments) {
        if (booking['installment_plan_status'] == 'active') {
          activeInstallmentPlans++;
          totalOutstanding += (booking['remaining_balance'] as double) - 
                            (booking['total_paid'] as double);
          totalPaid += booking['total_paid'] as double;
          totalPendingPayments += booking['pending_payments_count'] as int;
          totalLatePayments += booking['late_payments_count'] as int;
        }
      }

      return {
        'active_installment_plans': activeInstallmentPlans,
        'total_outstanding_balance': totalOutstanding,
        'total_paid': totalPaid,
        'total_pending_payments': totalPendingPayments,
        'total_late_payments': totalLatePayments,
        'has_late_payments': totalLatePayments > 0,
      };
    } catch (e) {
      print('Error fetching installment payment summary: $e');
      return {
        'active_installment_plans': 0,
        'total_outstanding_balance': 0.0,
        'total_paid': 0.0,
        'total_pending_payments': 0,
        'total_late_payments': 0,
        'has_late_payments': false,
      };
    }
  }

  // Refresh customer data
  void refreshCustomerData() {
    _customers.clear();
    _interactions.clear();
    _initializeCustomers();
    _initializeInteractions();
    notifyListeners();
  }

  // Get customer lifetime value prediction (simplified)
  double getCustomerLifetimeValue(Customer customer) {
    // Simple prediction based on current spending and booking frequency
    if (customer.totalBookings == 0) return 0.0;

    final averageOrderValue = customer.totalSpent / customer.totalBookings;
    final bookingFrequency = customer.totalBookings /
        (DateTime.now().difference(customer.createdAt).inDays / 30.0);

    // Assume 12 months lifetime
    return averageOrderValue * bookingFrequency * 12;
  }

  // Get customer churn risk (simplified)
  String getCustomerChurnRisk(Customer customer) {
    final daysSinceLastActive = DateTime.now().difference(customer.lastActive).inDays;

    if (daysSinceLastActive > 90) return 'High';
    if (daysSinceLastActive > 30) return 'Medium';
    return 'Low';
  }

  // Get customer recommendations for vendor
  List<String> getCustomerRecommendations(String vendorId) {
    final analytics = getCustomerAnalytics(vendorId);
    final recommendations = <String>[];

    if (analytics['customerRetentionRate'] < 50) {
      recommendations.add('Implement customer loyalty program');
    }

    if (analytics['newCustomers'] < analytics['totalCustomers'] * 0.2) {
      recommendations.add('Launch targeted marketing campaigns');
    }

    if (analytics['averageOrderValue'] < 1000) {
      recommendations.add('Create upsell opportunities');
    }

    if (analytics['recentInteractions'] < 10) {
      recommendations.add('Increase customer engagement');
    }

    return recommendations;
  }
}
