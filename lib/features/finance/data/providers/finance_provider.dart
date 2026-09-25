import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/finance_transaction.dart';
import '../models/expense.dart';
import '../models/commission.dart';
import 'package:eventease/shared/models/payment.dart';

class FinanceProvider with ChangeNotifier {
  final List<FinanceTransaction> _transactions = [];
  final List<Expense> _expenses = [];
  final List<ExpenseCategoryBudget> _budgets = [];
  bool _isLoading = false;
  String? _error;
  final Map<String, FinanceSummary> _summaries = {};

  UnmodifiableListView<FinanceTransaction> get transactions => UnmodifiableListView(_transactions);
  UnmodifiableListView<Expense> get expenses => UnmodifiableListView(_expenses);
  UnmodifiableListView<ExpenseCategoryBudget> get budgets => UnmodifiableListView(_budgets);
  bool get isLoading => _isLoading;
  String? get error => _error;

  FinanceProvider() {
    // Data should be loaded explicitly with loadVendorFinancialData(vendorId)
  }

  Future<void> loadVendorFinancialData(String vendorUserId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // 1. Get the actual vendor_profile id first (check user_id then id)
      var profileResponseList = await SupabaseService.select(
        table: 'vendor_profiles',
        filters: {'user_id': vendorUserId},
      );
      
      if (profileResponseList.isEmpty) {
        profileResponseList = await SupabaseService.select(
          table: 'vendor_profiles',
          filters: {'id': vendorUserId},
        );
      }
      
      final Map<String, dynamic>? profileResponse = profileResponseList.isNotEmpty ? profileResponseList.first : null;
      final vendorId = profileResponse != null ? profileResponse['id'] : vendorUserId;

      // 2. Fetch dedicated expenses
      final expensesResponse = await SupabaseService.select(
        table: 'expenses',
        filters: {'vendor_id': vendorId},
      );
      
      _expenses.clear();
      _expenses.addAll(expensesResponse.map((data) => Expense.fromSupabase(data)).toList());

      // 4. Fetch budgets
      final budgetsResponse = await SupabaseService.select(
        table: 'expense_budgets',
        filters: {'vendor_id': vendorId},
      );
      
      _budgets.clear();
      _budgets.addAll(budgetsResponse.map((data) => ExpenseCategoryBudget.fromSupabase(data)).toList());

      // 5. Fetch vendor payouts
      final payoutsResponse = await SupabaseService.select(
        table: 'vendor_payouts',
        filters: {'vendor_id': vendorId},
      );

      // Map payouts to transactions for the list
      _transactions.clear();
      _transactions.addAll(payoutsResponse.map((p) => FinanceTransaction(
        id: p['id'],
        vendorId: vendorId,
        type: TransactionType.expense, // Payout is an expense/withdrawal from system view
        category: TransactionCategory.otherExpense,
        description: 'Vendor Payout - ${p['reference_id'] ?? p['id']}',
        amount: (p['amount'] as num).toDouble(),
        paymentMethod: PaymentMethod.bankTransfer,
        date: DateTime.parse(p['created_at']),
      )).toList());

      // Add income from bookings (simplified for now)
      final bookingRevenueResponse = await SupabaseService.select(
        table: 'bookings',
        filters: {'vendor_id': vendorId, 'status': 'confirmed'},
      );

      _transactions.addAll(bookingRevenueResponse.map((b) => FinanceTransaction(
        id: b['id'],
        vendorId: vendorId,
        type: TransactionType.income,
        category: TransactionCategory.bookingPayment,
        description: 'Booking Payment - ${b['notes'] ?? 'Order #' + b['id'].substring(0,8)}',
        amount: (b['total_amount'] as num).toDouble(),
        paymentMethod: PaymentMethod.onlinePayment,
        date: DateTime.parse(b['created_at']),
      )).toList());

      _transactions.sort((a, b) => b.date.compareTo(a.date));

      _updateSummary(vendorId);

    } catch (e) {
      print('Error loading financial data: $e');
      _error = 'Failed to load financial records';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Transaction Management
  void addTransaction(FinanceTransaction transaction) {
    _transactions.add(transaction);
    _updateSummary(transaction.vendorId);
    _updateBudgetSpending(transaction);
    notifyListeners();
  }

  void updateTransaction(String transactionId, FinanceTransaction updatedTransaction) {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      final oldTransaction = _transactions[index];
      _transactions[index] = updatedTransaction;
      _updateSummary(updatedTransaction.vendorId);
      _updateBudgetSpending(updatedTransaction);
      // Revert old transaction's budget impact
      _updateBudgetSpending(oldTransaction, isReverting: true);
      notifyListeners();
    }
  }

  void deleteTransaction(String transactionId) {
    final transaction = _transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw Exception('Transaction not found'),
    );
    _transactions.removeWhere((t) => t.id == transactionId);
    _updateSummary(transaction.vendorId);
    _updateBudgetSpending(transaction, isReverting: true);
    notifyListeners();
  }

  List<FinanceTransaction> getTransactionsByVendor(String vendorId) {
    return _transactions.where((t) => t.vendorId == vendorId).toList();
  }

  List<FinanceTransaction> getTransactionsByCategory(TransactionCategory category) {
    return _transactions.where((t) => t.category == category).toList();
  }

  List<FinanceTransaction> getTransactionsByDateRange(DateTime start, DateTime end) {
    return _transactions.where((t) => t.date.isAfter(start) && t.date.isBefore(end)).toList();
  }

  // Expense Management
  void addExpense(Expense expense) {
    _expenses.add(expense);
    _updateSummary(expense.vendorId);
    _updateBudgetSpending(expense);
    notifyListeners();
  }

  void updateExpense(String expenseId, Expense updatedExpense) {
    final index = _expenses.indexWhere((e) => e.id == expenseId);
    if (index != -1) {
      final oldExpense = _expenses[index];
      _expenses[index] = updatedExpense;
      _updateSummary(updatedExpense.vendorId);
      _updateBudgetSpending(updatedExpense);
      _updateBudgetSpending(oldExpense, isReverting: true);
      notifyListeners();
    }
  }

  void deleteExpense(String expenseId) {
    final expense = _expenses.firstWhere(
      (e) => e.id == expenseId,
      orElse: () => throw Exception('Expense not found'),
    );
    _expenses.removeWhere((e) => e.id == expenseId);
    _updateSummary(expense.vendorId);
    _updateBudgetSpending(expense, isReverting: true);
    notifyListeners();
  }

  List<Expense> getExpensesByVendor(String vendorId) {
    return _expenses.where((e) => e.vendorId == vendorId).toList();
  }

  List<Expense> getPendingExpenses() {
    return _expenses.where((e) => e.status == ExpenseStatus.pending).toList();
  }

  List<Expense> getOverdueExpenses() {
    return _expenses.where((e) => e.isOverdue).toList();
  }

  // Budget Management
  void addBudget(ExpenseCategoryBudget budget) {
    _budgets.add(budget);
    notifyListeners();
  }

  void updateBudget(String budgetId, ExpenseCategoryBudget updatedBudget) {
    final index = _budgets.indexWhere((b) => b.id == budgetId);
    if (index != -1) {
      _budgets[index] = updatedBudget;
      notifyListeners();
    }
  }

  void deleteBudget(String budgetId) {
    _budgets.removeWhere((b) => b.id == budgetId);
    notifyListeners();
  }

  ExpenseCategoryBudget? getBudgetByCategory(String vendorId, TransactionCategory category) {
    try {
      return _budgets.firstWhere(
        (b) => b.vendorId == vendorId && b.category == category && b.isActive,
      );
    } catch (e) {
      try {
        return _budgets.firstWhere(
          (b) => b.vendorId == 'all' && b.category == category && b.isActive,
        );
      } catch (e) {
        return null;
      }
    }
  }

  // Summary Management
  void _updateSummary(String vendorId) {
    final vendorTransactions = getTransactionsByVendor(vendorId);
    final vendorExpenses = getExpensesByVendor(vendorId);

    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    double monthlyIncome = 0.0;
    double monthlyExpenses = 0.0;
    int totalTransactions = vendorTransactions.length + vendorExpenses.length;

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    for (final transaction in vendorTransactions) {
      if (transaction.type == TransactionType.income) {
        totalIncome += transaction.amount;
        if (transaction.date.isAfter(monthStart)) {
          monthlyIncome += transaction.amount;
        }
      } else {
        totalExpenses += transaction.amount;
        if (transaction.date.isAfter(monthStart)) {
          monthlyExpenses += transaction.amount;
        }
      }
    }

    for (final expense in vendorExpenses) {
      totalExpenses += expense.amount;
      if (expense.date.isAfter(monthStart)) {
        monthlyExpenses += expense.amount;
      }
    }

    final summary = FinanceSummary(
      vendorId: vendorId,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      netProfit: totalIncome - totalExpenses,
      monthlyIncome: monthlyIncome,
      monthlyExpenses: monthlyExpenses,
      monthlyProfit: monthlyIncome - monthlyExpenses,
      totalTransactions: totalTransactions,
      lastUpdated: DateTime.now(),
    );

    _summaries[vendorId] = summary;
  }

  FinanceSummary? getSummary(String vendorId) {
    return _summaries[vendorId];
  }

  // Budget Spending Updates
  void _updateBudgetSpending(dynamic item, {bool isReverting = false}) {
    double amount = 0.0;
    TransactionCategory? category;
    String? vendorId;

    if (item is FinanceTransaction) {
      amount = item.amount;
      category = item.category;
      vendorId = item.vendorId;
    } else if (item is Expense) {
      amount = item.amount;
      category = item.category;
      vendorId = item.vendorId;
    }

    if (category != null && vendorId != null) {
      final budget = getBudgetByCategory(vendorId, category);
      if (budget != null) {
        final index = _budgets.indexWhere((b) => b.id == budget.id);
        if (index != -1) {
          final currentBudget = _budgets[index];
          final multiplier = isReverting ? -1 : 1;
          _budgets[index] = ExpenseCategoryBudget(
            id: currentBudget.id,
            vendorId: currentBudget.vendorId,
            category: currentBudget.category,
            budgetedAmount: currentBudget.budgetedAmount,
            spentAmount: currentBudget.spentAmount + (amount * multiplier),
            periodStart: currentBudget.periodStart,
            periodEnd: currentBudget.periodEnd,
            isActive: currentBudget.isActive,
          );
        }
      }
    }
  }

  // Analytics Methods
  Map<String, dynamic> getFinancialAnalytics(String vendorId) {
    final summary = getSummary(vendorId);
    final transactions = getTransactionsByVendor(vendorId);
    final expenses = getExpensesByVendor(vendorId);

    if (summary == null) return {};

    // Category-wise breakdown
    final categoryBreakdown = <String, double>{};
    for (final transaction in transactions) {
      final categoryName = _getCategoryDisplayName(transaction.category);
      categoryBreakdown[categoryName] = (categoryBreakdown[categoryName] ?? 0) + transaction.amount;
    }

    // Monthly trends
    final monthlyTrends = <String, Map<String, double>>{};
    for (final transaction in transactions) {
      final monthKey = '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      monthlyTrends[monthKey] ??= {'income': 0.0, 'expenses': 0.0};
      if (transaction.type == TransactionType.income) {
        monthlyTrends[monthKey]!['income'] = monthlyTrends[monthKey]!['income']! + transaction.amount;
      } else {
        monthlyTrends[monthKey]!['expenses'] = monthlyTrends[monthKey]!['expenses']! + transaction.amount;
      }
    }

    // Expense breakdown by category
    final expenseBreakdown = <String, double>{};
    for (final expense in expenses) {
      final categoryName = _getCategoryDisplayName(expense.category);
      expenseBreakdown[categoryName] = (expenseBreakdown[categoryName] ?? 0) + expense.amount;
    }

    return {
      'summary': summary.toJson(),
      'categoryBreakdown': categoryBreakdown,
      'monthlyTrends': monthlyTrends,
      'expenseBreakdown': expenseBreakdown,
      'recentTransactions': transactions.take(10).map((t) => t.toJson()).toList(),
      'pendingExpenses': getPendingExpenses().map((e) => e.toJson()).toList(),
    };
  }

  // Utility Methods
  double getTotalIncome(String vendorId, {DateTime? startDate, DateTime? endDate}) {
    final transactions = getTransactionsByVendor(vendorId);
    double total = 0.0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.income) {
        if (startDate != null && endDate != null) {
          if (transaction.date.isAfter(startDate) && transaction.date.isBefore(endDate)) {
            total += transaction.amount;
          }
        } else {
          total += transaction.amount;
        }
      }
    }

    return total;
  }

  double getTotalExpenses(String vendorId, {DateTime? startDate, DateTime? endDate}) {
    final transactions = getTransactionsByVendor(vendorId);
    final expenses = getExpensesByVendor(vendorId);
    double total = 0.0;

    for (final transaction in transactions) {
      if (transaction.type == TransactionType.expense) {
        if (startDate != null && endDate != null) {
          if (transaction.date.isAfter(startDate) && transaction.date.isBefore(endDate)) {
            total += transaction.amount;
          }
        } else {
          total += transaction.amount;
        }
      }
    }

    for (final expense in expenses) {
      if (startDate != null && endDate != null) {
        if (expense.date.isAfter(startDate) && expense.date.isBefore(endDate)) {
          total += expense.amount;
        }
      } else {
        total += expense.amount;
      }
    }

    return total;
  }

  void processCommissionTransaction(CommissionTransaction commission) {
    final transaction = FinanceTransaction(
      id: 'fin_${commission.id}',
      vendorId: commission.vendorId,
      type: TransactionType.income,
      category: TransactionCategory.commission,
      description: 'Commission from ${commission.type.toString().split('.').last} booking',
      amount: commission.vendorEarnings,
      paymentMethod: PaymentMethod.bankTransfer,
      date: commission.createdAt,
      reference: commission.id,
      metadata: {
        'commissionId': commission.id,
        'bookingId': commission.bookingId,
        'commissionType': commission.type.toString(),
      },
    );

    addTransaction(transaction);
  }

  // Bulk Operations
  void bulkUpdateTransactions(List<String> transactionIds, Map<String, dynamic> updates) {
    for (final id in transactionIds) {
      final transaction = _transactions.firstWhere(
        (t) => t.id == id,
        orElse: () => throw Exception('Transaction not found'),
      );

      final updatedTransaction = FinanceTransaction(
        id: transaction.id,
        vendorId: transaction.vendorId,
        type: updates['type'] ?? transaction.type,
        category: updates['category'] ?? transaction.category,
        description: updates['description'] ?? transaction.description,
        amount: updates['amount'] ?? transaction.amount,
        paymentMethod: updates['paymentMethod'] ?? transaction.paymentMethod,
        date: updates['date'] ?? transaction.date,
        reference: updates['reference'] ?? transaction.reference,
        receiptImage: updates['receiptImage'] ?? transaction.receiptImage,
        isRecurring: updates['isRecurring'] ?? transaction.isRecurring,
        recurringId: updates['recurringId'] ?? transaction.recurringId,
        metadata: updates['metadata'] ?? transaction.metadata,
      );

      updateTransaction(id, updatedTransaction);
    }
  }

  void bulkUpdateExpenses(List<String> expenseIds, Map<String, dynamic> updates) {
    for (final id in expenseIds) {
      final expense = _expenses.firstWhere(
        (e) => e.id == id,
        orElse: () => throw Exception('Expense not found'),
      );

      final updatedExpense = Expense(
        id: expense.id,
        vendorId: expense.vendorId,
        title: updates['title'] ?? expense.title,
        description: updates['description'] ?? expense.description,
        amount: updates['amount'] ?? expense.amount,
        category: updates['category'] ?? expense.category,
        status: updates['status'] ?? expense.status,
        priority: updates['priority'] ?? expense.priority,
        date: updates['date'] ?? expense.date,
        dueDate: updates['dueDate'] ?? expense.dueDate,
        receiptImage: updates['receiptImage'] ?? expense.receiptImage,
        approvedBy: updates['approvedBy'] ?? expense.approvedBy,
        approvedAt: updates['approvedAt'] ?? expense.approvedAt,
        paymentReference: updates['paymentReference'] ?? expense.paymentReference,
        paidAt: updates['paidAt'] ?? expense.paidAt,
        metadata: updates['metadata'] ?? expense.metadata,
        isRecurring: updates['isRecurring'] ?? expense.isRecurring,
        recurringId: updates['recurringId'] ?? expense.recurringId,
      );

      updateExpense(id, updatedExpense);
    }
  }

  // Helper method to get category display name
  String _getCategoryDisplayName(TransactionCategory category) {
    switch (category) {
      case TransactionCategory.bookingPayment:
        return 'Booking Payment';
      case TransactionCategory.servicePayment:
        return 'Service Payment';
      case TransactionCategory.productSale:
        return 'Product Sale';
      case TransactionCategory.commission:
        return 'Commission';
      case TransactionCategory.refund:
        return 'Refund';
      case TransactionCategory.otherIncome:
        return 'Other Income';
      case TransactionCategory.marketing:
        return 'Marketing';
      case TransactionCategory.staff:
        return 'Staff';
      case TransactionCategory.rent:
        return 'Rent';
      case TransactionCategory.utilities:
        return 'Utilities';
      case TransactionCategory.supplies:
        return 'Supplies';
      case TransactionCategory.equipment:
        return 'Equipment';
      case TransactionCategory.insurance:
        return 'Insurance';
      case TransactionCategory.taxes:
        return 'Taxes';
      case TransactionCategory.otherExpense:
        return 'Other Expense';
      default:
        return 'Unknown';
    }
  }
}
