import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/commission.dart';

class CommissionProvider with ChangeNotifier {
  final List<CommissionRate> _commissionRates = [];
  final List<CommissionTransaction> _commissionTransactions = [];
  final List<CommissionSummary> _commissionSummaries = [];

  UnmodifiableListView<CommissionRate> get commissionRates => UnmodifiableListView(_commissionRates);
  UnmodifiableListView<CommissionTransaction> get commissionTransactions => UnmodifiableListView(_commissionTransactions);
  UnmodifiableListView<CommissionSummary> get commissionSummaries => UnmodifiableListView(_commissionSummaries);

  CommissionProvider() {
    _initializeDefaultRates();
  }

  void _initializeDefaultRates() {
    // Initialize with default commission rates for different vendor types
    _commissionRates.addAll([
      CommissionRate(
        id: 'default_booking',
        vendorId: 'all',
        type: CommissionType.booking,
        percentage: 10.0,
        effectiveFrom: DateTime.now(),
      ),
      CommissionRate(
        id: 'default_service',
        vendorId: 'all',
        type: CommissionType.service,
        percentage: 8.0,
        effectiveFrom: DateTime.now(),
      ),
      CommissionRate(
        id: 'default_package',
        vendorId: 'all',
        type: CommissionType.package,
        percentage: 12.0,
        effectiveFrom: DateTime.now(),
      ),
    ]);
  }

  // Commission Rate Management
  void addCommissionRate(CommissionRate rate) {
    _commissionRates.add(rate);
    notifyListeners();
  }

  void updateCommissionRate(String rateId, CommissionRate updatedRate) {
    final index = _commissionRates.indexWhere((r) => r.id == rateId);
    if (index != -1) {
      _commissionRates[index] = updatedRate;
      notifyListeners();
    }
  }

  void removeCommissionRate(String rateId) {
    _commissionRates.removeWhere((r) => r.id == rateId);
    notifyListeners();
  }

  CommissionRate? getCommissionRate(String vendorId, CommissionType type) {
    // First try to find vendor-specific rate
    try {
      final vendorRate = _commissionRates.firstWhere(
        (r) => r.vendorId == vendorId && r.type == type && r.isActive,
      );
      return vendorRate;
    } catch (e) {
      // Fall back to default rate
      try {
        return _commissionRates.firstWhere(
          (r) => r.vendorId == 'all' && r.type == type && r.isActive,
        );
      } catch (e) {
        return null;
      }
    }
  }

  // Commission Transaction Management
  void addCommissionTransaction(CommissionTransaction transaction) {
    _commissionTransactions.add(transaction);
    _updateCommissionSummary(transaction.vendorId);
    notifyListeners();
  }

  void updateTransactionStatus(String transactionId, CommissionStatus status, {String? paymentReference}) {
    final transaction = _commissionTransactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw Exception('Transaction not found'),
    );

    transaction.status = status;
    if (status == CommissionStatus.paid) {
      transaction.paidAt = DateTime.now();
      transaction.paymentReference = paymentReference;
    }

    _updateCommissionSummary(transaction.vendorId);
    notifyListeners();
  }

  CommissionTransaction? getTransactionById(String id) {
    try {
      return _commissionTransactions.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<CommissionTransaction> getTransactionsByVendor(String vendorId) {
    return _commissionTransactions.where((t) => t.vendorId == vendorId).toList();
  }

  List<CommissionTransaction> getTransactionsByStatus(CommissionStatus status) {
    return _commissionTransactions.where((t) => t.status == status).toList();
  }

  // Commission Summary Management
  void _updateCommissionSummary(String vendorId) {
    final vendorTransactions = getTransactionsByVendor(vendorId);

    double totalEarnings = 0.0;
    double totalCommission = 0.0;
    double pendingPayments = 0.0;
    double paidPayments = 0.0;
    int pendingTransactions = 0;

    for (final transaction in vendorTransactions) {
      totalEarnings += transaction.vendorEarnings;
      totalCommission += transaction.commissionAmount;

      if (transaction.status == CommissionStatus.pending) {
        pendingPayments += transaction.vendorEarnings;
        pendingTransactions++;
      } else if (transaction.status == CommissionStatus.paid) {
        paidPayments += transaction.vendorEarnings;
      }
    }

    final existingSummaryIndex = _commissionSummaries.indexWhere((s) => s.vendorId == vendorId);

    final summary = CommissionSummary(
      vendorId: vendorId,
      totalEarnings: totalEarnings,
      totalCommission: totalCommission,
      pendingPayments: pendingPayments,
      paidPayments: paidPayments,
      totalTransactions: vendorTransactions.length,
      pendingTransactions: pendingTransactions,
      lastUpdated: DateTime.now(),
    );

    if (existingSummaryIndex != -1) {
      _commissionSummaries[existingSummaryIndex] = summary;
    } else {
      _commissionSummaries.add(summary);
    }
  }

  CommissionSummary? getCommissionSummary(String vendorId) {
    try {
      return _commissionSummaries.firstWhere((s) => s.vendorId == vendorId);
    } catch (e) {
      return null;
    }
  }

  // Utility Methods
  double calculateCommission(String vendorId, CommissionType type, double amount) {
    final rate = getCommissionRate(vendorId, type);
    return rate?.calculateCommission(amount) ?? (amount * 0.1); // Default 10%
  }

  void processBookingCommission(String vendorId, String bookingId, CommissionType type, double totalAmount) {
    final commissionAmount = calculateCommission(vendorId, type, totalAmount);
    final platformFee = commissionAmount;
    final vendorEarnings = totalAmount - platformFee;

    final transaction = CommissionTransaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      vendorId: vendorId,
      bookingId: bookingId,
      type: type,
      totalAmount: totalAmount,
      commissionAmount: commissionAmount,
      platformFee: platformFee,
      vendorEarnings: vendorEarnings,
      createdAt: DateTime.now(),
    );

    addCommissionTransaction(transaction);
  }

  // Bulk Operations
  void markTransactionsAsPaid(List<String> transactionIds, String paymentReference) {
    for (final id in transactionIds) {
      updateTransactionStatus(id, CommissionStatus.paid, paymentReference: paymentReference);
    }
    notifyListeners();
  }

  List<CommissionTransaction> getPendingPayments() {
    return getTransactionsByStatus(CommissionStatus.pending);
  }

  double getTotalPendingPayments() {
    return getPendingPayments().fold(0.0, (sum, t) => sum + t.vendorEarnings);
  }

  // Analytics
  Map<String, dynamic> getCommissionAnalytics(String vendorId) {
    final summary = getCommissionSummary(vendorId);
    final transactions = getTransactionsByVendor(vendorId);

    if (summary == null) return {};

    final monthlyData = <String, Map<String, double>>{};
    for (final transaction in transactions) {
      final monthKey = '${transaction.createdAt.year}-${transaction.createdAt.month.toString().padLeft(2, '0')}';

      monthlyData[monthKey] ??= {'earnings': 0.0, 'commission': 0.0};
      monthlyData[monthKey]!['earnings'] = monthlyData[monthKey]!['earnings']! + transaction.vendorEarnings;
      monthlyData[monthKey]!['commission'] = monthlyData[monthKey]!['commission']! + transaction.commissionAmount;
    }

    return {
      'summary': summary.toJson(),
      'monthlyData': monthlyData,
      'recentTransactions': transactions.take(10).map((t) => t.toJson()).toList(),
    };
  }
}
