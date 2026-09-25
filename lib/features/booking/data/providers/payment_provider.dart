import 'package:eventease/core/services/payment_service.dart';
import 'package:eventease/core/config/billplz_config.dart';
import 'package:eventease/features/finance/data/models/finance_transaction.dart';
import 'package:eventease/shared/models/payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:eventease/core/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentTransaction {
  final String id;
  final String bookingId;
  final String? appointmentId;
  final String customerId;
  final String vendorId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final String? transactionId;
  final String? paymentReference;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  PaymentTransaction({
    required this.id,
    required this.bookingId,
    this.appointmentId,
    required this.customerId,
    required this.vendorId,
    required this.amount,
    required this.method,
    required this.status,
    this.transactionId,
    this.paymentReference,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  PaymentTransaction copyWith({
    String? id,
    String? bookingId,
    String? appointmentId,
    String? customerId,
    String? vendorId,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    String? transactionId,
    String? paymentReference,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      appointmentId: appointmentId ?? this.appointmentId,
      customerId: customerId ?? this.customerId,
      vendorId: vendorId ?? this.vendorId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      paymentReference: paymentReference ?? this.paymentReference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      id: json['id'] as String,
      bookingId: json['booking_id'] as String,
      appointmentId: json['appointment_id'] as String?,
      customerId: json['customer_id'] as String,
      vendorId: json['vendor_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.onlineBanking,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: json['transaction_id'] as String?,
      paymentReference: json['payment_reference'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'appointment_id': appointmentId,
      'customer_id': customerId,
      'vendor_id': vendorId,
      'amount': amount,
      'method': method.name,
      'status': status.name,
      'transaction_id': transactionId,
      'payment_reference': paymentReference,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}

class PaymentProvider with ChangeNotifier {
  final List<PaymentTransaction> _transactions = [];
  final List<PaymentTransaction> _customerTransactions = [];
  final List<PaymentTransaction> _vendorTransactions = [];
  final SupabaseClient _supabase;

  PaymentProvider({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  List<PaymentTransaction> get transactions => _transactions;
  List<PaymentTransaction> get customerTransactions => _customerTransactions;
  List<PaymentTransaction> get vendorTransactions => _vendorTransactions;

  // Load customer transactions from database on login/startup
  Future<void> loadCustomerTransactions(String customerId) async {
    try {
      final response = await _supabase
          .from('payment_transactions')
          .select()
          .eq('customer_id', customerId);
      
      _transactions.clear();
      if (response != null) {
        final List<dynamic> list = response as List<dynamic>;
        _transactions.addAll(list.map((json) => PaymentTransaction.fromJson(json as Map<String, dynamic>)));
      }
      notifyListeners();
    } catch (e) {
      print("Error loading customer transactions: $e");
    }
  }

  // Load vendor transactions from database
  Future<void> loadVendorTransactions(String vendorId) async {
    try {
      final response = await _supabase
          .from('payment_transactions')
          .select()
          .eq('vendor_id', vendorId);
      
      _transactions.clear();
      if (response != null) {
        final List<dynamic> list = response as List<dynamic>;
        _transactions.addAll(list.map((json) => PaymentTransaction.fromJson(json as Map<String, dynamic>)));
      }
      notifyListeners();
    } catch (e) {
      print("Error loading vendor transactions: $e");
    }
  }

  // Add transaction
  Future<void> addTransaction(PaymentTransaction transaction) async {
    _transactions.add(transaction);
    notifyListeners();
    try {
      await _supabase.from('payment_transactions').insert(transaction.toJson());
    } catch (e) {
      print("Error saving payment transaction to database: $e");
    }
  }

  // Update payment status
  Future<void> updatePaymentStatus(String transactionId, PaymentStatus status, {String? failureReason}) async {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      final oldTransaction = _transactions[index];
      
      final updatedTransaction = oldTransaction.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        metadata: failureReason != null 
            ? {...(oldTransaction.metadata ?? {}), 'failureReason': failureReason}
            : oldTransaction.metadata,
      );

      _transactions[index] = updatedTransaction;
      notifyListeners();

      try {
        await _supabase
            .from('payment_transactions')
            .update(updatedTransaction.toJson())
            .eq('id', transactionId);
      } catch (e) {
        print("Error updating payment transaction status in DB: $e");
      }
      
      // Trigger Notification if payment is completed
      if (status == PaymentStatus.completed) {
        NotificationService().sendPaymentReceivedNotification(
          customerId: updatedTransaction.customerId,
          vendorId: updatedTransaction.vendorId,
          bookingId: updatedTransaction.bookingId,
          amount: updatedTransaction.amount,
          paymentType: 'Deposit', // In a full implementation, this should be dynamic
        );
      }
    }
  }

  // Process payment with Billplz or Xendit
  Future<String?> processPayment({
    required String bookingId,
    String? appointmentId,
    required String customerId,
    required String vendorId,
    required double amount,
    required PaymentMethod method,
    required String email,
    required String mobile,
    required String name,
    required String description,
    PaymentGatewayProvider gateway = PaymentGatewayProvider.xendit,
    String currency = 'MYR',
    Map<String, dynamic>? metadata,
  }) async {
    final transactionId = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    
    final transaction = PaymentTransaction(
      id: transactionId,
      bookingId: bookingId,
      appointmentId: appointmentId,
      customerId: customerId,
      vendorId: vendorId,
      amount: amount,
      method: method,
      status: PaymentStatus.pending, // Start as pending
      transactionId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: metadata,
    );

    await addTransaction(transaction);

    try {
      if (gateway == PaymentGatewayProvider.xendit) {
        // Create Invoice in Xendit
        final String callbackConfig = dotenv.env['PAYMENT_CALLBACK_URL'] ?? 'https://eventease-web.netlify.app/payment/callback';
        final String redirectUrl = kIsWeb ? Uri.base.toString() : callbackConfig;
        
        final result = await PaymentService.createXenditInvoice(
          email: email,
          name: name,
          amount: amount,
          currency: currency,
          externalId: transactionId,
          description: description,
          redirectUrl: redirectUrl,
          metadata: {
            'booking_id': bookingId,
            'customer_id': customerId,
            ...?(metadata),
          },
        );
        final invoiceUrl = result['invoice_url'] ?? result['url'];
        await updatePaymentStatus(transactionId, PaymentStatus.processing);
        return invoiceUrl;
      } else {
        // Create Bill in Billplz
        final String callbackConfig = dotenv.env['PAYMENT_CALLBACK_URL'] ?? 'https://eventease-web.netlify.app/payment/callback';
        
        final result = await PaymentService.createBill(
          collectionId: BillplzConfig.collectionId,
          email: email,
          mobile: mobile,
          name: name,
          amount: amount,
          callbackUrl: callbackConfig,
          description: description,
          metadata: {
            'booking_id': bookingId,
            'customer_id': customerId,
            ...?(metadata),
          },
        );

        final billUrl = result['url'];
        await updatePaymentStatus(transactionId, PaymentStatus.processing);
        return billUrl;
      }
      
    } catch (e) {
      print("ERROR in PaymentProvider.processPayment: $e");
      await updatePaymentStatus(transactionId, PaymentStatus.failed, failureReason: e.toString());
      return null;
    }
  }

  // Refund payment
  Future<void> refundPayment(String transactionId, {String? reason}) async {
    await updatePaymentStatus(transactionId, PaymentStatus.refunded);
  }

  // Get payment statistics
  Map<String, dynamic> getPaymentStats(String userId, bool isVendor) {
    final userTransactions = isVendor
      ? _transactions.where((t) => t.vendorId == userId).toList()
      : _transactions.where((t) => t.customerId == userId).toList();

    final totalAmount = userTransactions
        .where((t) => t.status == PaymentStatus.completed)
        .fold(0.0, (sum, t) => sum + t.amount);

    return {
      'totalTransactions': userTransactions.length,
      'completedTransactions': userTransactions.where((t) => t.status == PaymentStatus.completed).length,
      'pendingTransactions': userTransactions.where((t) => t.status == PaymentStatus.pending || t.status == PaymentStatus.processing).length,
      'failedTransactions': userTransactions.where((t) => t.status == PaymentStatus.failed).length,
      'totalAmount': totalAmount,
      'refundedAmount': userTransactions
          .where((t) => t.status == PaymentStatus.refunded)
          .fold(0.0, (sum, t) => sum + t.amount),
    };
  }

  // Create payment from chat request
  Future<void> createPaymentFromChat({
    required String bookingId,
    String? appointmentId,
    required String customerId,
    required String vendorId,
    required double amount,
    required String description,
    PaymentMethod method = PaymentMethod.onlineBanking,
  }) async {
    final transaction = PaymentTransaction(
      id: 'pay_${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      appointmentId: appointmentId,
      customerId: customerId,
      vendorId: vendorId,
      amount: amount,
      method: method,
      status: PaymentStatus.pending,
      paymentReference: 'REF_${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      metadata: {'description': description, 'source': 'chat_request'},
    );

    await addTransaction(transaction);
  }

  // Clear all data (for logout)
  void clearData() {
    _transactions.clear();
    _customerTransactions.clear();
    _vendorTransactions.clear();
    notifyListeners();
  }
}
