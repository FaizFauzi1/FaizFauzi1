import 'package:flutter/material.dart';
import 'package:eventease/features/budget/data/models/budget.dart';
import 'package:eventease/features/budget/data/models/budget_category.dart';
import 'package:eventease/features/budget/data/models/budget_expense.dart';
import 'package:eventease/features/customer/data/providers/customer_provider.dart';
import 'package:eventease/features/event/data/models/event_template.dart';
import 'package:eventease/core/services/supabase_service.dart';
import 'package:uuid/uuid.dart';

class BudgetProvider with ChangeNotifier {
  final List<Budget> _budgets = [];
  final CustomerProvider _customerProvider;
  bool _isLoading = false;
  bool _isLoaded = false;
  String? _error;

  BudgetProvider(this._customerProvider);

  bool get isLoading => _isLoading;
  bool get isLoaded => _isLoaded;
  String? get error => _error;
  List<Budget> get budgets => List.unmodifiable(_budgets);

  // Load budgets for a customer from Supabase
  Future<void> loadBudgets(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await SupabaseService.select(
        table: 'budgets',
        columns: '*, budget_categories(*), budget_expenses(*)',
        filters: {'customer_id': customerId},
      );
      
      _budgets.clear();
      _budgets.addAll(data.map((json) => Budget.fromSupabase(json)).toList());
      _isLoaded = true;
    } catch (e) {
      debugPrint('BudgetProvider: load error: $e');
      _error = 'Failed to load budgets';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load budget for an event
  Future<void> loadBudgetForEvent(String eventId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await SupabaseService.select(
        table: 'budgets',
        columns: '*, budget_categories(*), budget_expenses(*)',
        filters: {'event_id': eventId},
      );
      
      if (data.isNotEmpty) {
        final budget = Budget.fromSupabase(data.first);
        final index = _budgets.indexWhere((b) => b.id == budget.id);
        if (index != -1) {
          _budgets[index] = budget;
        } else {
          _budgets.add(budget);
        }
      }
    } catch (e) {
      debugPrint('BudgetProvider: load budget for event error: $e');
    } finally {
      _isLoading = false;
      _isLoaded = true;
      notifyListeners();
    }
  }

  // Get budget by ID
  Budget? getBudgetById(String budgetId) {
    try {
      return _budgets.firstWhere((budget) => budget.id == budgetId);
    } catch (e) {
      return null;
    }
  }

  // Get budget for an event (local)
  Budget? getBudgetForEvent(String eventId) {
    try {
      return _budgets.firstWhere((budget) => budget.eventId == eventId);
    } catch (e) {
      return null;
    }
  }

  // Create new budget in Supabase
  Future<void> createBudget({
    required String eventId,
    required String customerId,
    required double totalBudget,
    EventTemplate? template,
  }) async {
    // Validate UUID format before proceeding
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    if (!uuidRegex.hasMatch(eventId) || !uuidRegex.hasMatch(customerId)) {
      debugPrint('BudgetProvider: Invalid UUID for eventId ($eventId) or customerId ($customerId)');
      _error = 'Invalid event or user ID. Please ensure you have a valid event selected.';
      notifyListeners();
      return;
    }

    final budgetId = const Uuid().v4();
    final categories = template?.defaultBudgetCategories ?? BudgetCategory.getDefaultCategories();

    final budget = Budget(
      id: budgetId,
      eventId: eventId,
      customerId: customerId,
      totalBudget: totalBudget,
      allocatedBudget: 0,
      spentBudget: 0,
      categories: categories,
      expenses: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      // 1. Insert budget
      await SupabaseService.insert(
        table: 'budgets',
        data: budget.toSupabaseJson(),
      );

      // 2. Insert default categories
      for (var category in categories) {
        // Generate a fresh UUID for every category instance
        final uniqueCategory = category.copyWith(id: const Uuid().v4());
        await SupabaseService.insert(
          table: 'budget_categories',
          data: uniqueCategory.toSupabaseJson(budgetId),
        );
      }

      _budgets.add(budget);
      notifyListeners();
    } catch (e) {
      debugPrint('BudgetProvider: create error: $e');
      _error = 'Failed to create budget';
      notifyListeners();
    }
  }

  // Update total budget
  Future<void> updateTotalBudget(String budgetId, double amount) async {
    final budgetIndex = _budgets.indexWhere((b) => b.id == budgetId);
    if (budgetIndex == -1) return;

    final budget = _budgets[budgetIndex];
    final updatedBudget = budget.copyWith(
      totalBudget: amount,
      updatedAt: DateTime.now(),
    );

    try {
      await SupabaseService.update(
        table: 'budgets',
        data: updatedBudget.toSupabaseJson(),
        column: 'id',
        value: budgetId,
      );

      _budgets[budgetIndex] = updatedBudget;
      notifyListeners();
    } catch (e) {
      debugPrint('BudgetProvider: update total budget error: $e');
    }
  }

  // Add custom category
  Future<void> addCategory(String budgetId, String name, double allocatedAmount) async {
    final budgetIndex = _budgets.indexWhere((b) => b.id == budgetId);
    if (budgetIndex == -1) return;

    final newCategory = BudgetCategory(
      id: const Uuid().v4(),
      name: name,
      allocatedAmount: allocatedAmount,
      color: '#45B7D1', // Default blue
      type: BudgetCategoryType.miscellaneous,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      await SupabaseService.insert(
        table: 'budget_categories',
        data: newCategory.toSupabaseJson(budgetId),
      );

      final budget = _budgets[budgetIndex];
      final updatedCategories = [...budget.categories, newCategory];
      
      final newAllocatedBudget = updatedCategories.fold<double>(
        0,
        (sum, category) => sum + category.allocatedAmount,
      );

      final updatedBudget = budget.copyWith(
        categories: updatedCategories,
        allocatedBudget: newAllocatedBudget,
        updatedAt: DateTime.now(),
      );

      await SupabaseService.update(
        table: 'budgets',
        data: updatedBudget.toSupabaseJson(),
        column: 'id',
        value: budgetId,
      );

      _budgets[budgetIndex] = updatedBudget;
      notifyListeners();
    } catch (e) {
      debugPrint('BudgetProvider: add category error: $e');
    }
  }

  // Delete category
  Future<void> deleteCategory(String budgetId, String categoryId) async {
    final budgetIndex = _budgets.indexWhere((b) => b.id == budgetId);
    if (budgetIndex == -1) return;

    try {
      // First delete associated expenses
      await SupabaseService.delete(
        table: 'budget_expenses',
        column: 'category_id',
        value: categoryId,
      );

      // Then delete category
      await SupabaseService.delete(
        table: 'budget_categories',
        column: 'id',
        value: categoryId,
      );

      final budget = _budgets[budgetIndex];
      final updatedCategories = budget.categories.where((c) => c.id != categoryId).toList();
      final updatedExpenses = budget.expenses.where((e) => e.categoryId != categoryId).toList();

      final newAllocatedBudget = updatedCategories.fold<double>(
        0,
        (sum, category) => sum + category.allocatedAmount,
      );
      
      final newSpentBudget = updatedExpenses
          .where((exp) => exp.isPaid)
          .fold<double>(0, (sum, exp) => sum + exp.amount);

      final updatedBudget = budget.copyWith(
        categories: updatedCategories,
        expenses: updatedExpenses,
        allocatedBudget: newAllocatedBudget,
        spentBudget: newSpentBudget,
        updatedAt: DateTime.now(),
      );

      await SupabaseService.update(
        table: 'budgets',
        data: updatedBudget.toSupabaseJson(),
        column: 'id',
        value: budgetId,
      );

      _budgets[budgetIndex] = updatedBudget;
      notifyListeners();
    } catch (e) {
      debugPrint('BudgetProvider: delete category error: $e');
    }
  }

  // Update budget allocation
  Future<void> updateBudgetAllocation(String budgetId, String categoryId, double amount) async {
    final budgetIndex = _budgets.indexWhere((b) => b.id == budgetId);
    if (budgetIndex == -1) return;

    final budget = _budgets[budgetIndex];
    final categoryIndex = budget.categories.indexWhere((c) => c.id == categoryId);
    if (categoryIndex == -1) return;

    final updatedCategory = budget.categories[categoryIndex].copyWith(
      allocatedAmount: amount,
      updatedAt: DateTime.now(),
    );

    try {
      // Sync to Supabase
      await SupabaseService.update(
        table: 'budget_categories',
        data: updatedCategory.toSupabaseJson(budgetId),
        column: 'id',
        value: categoryId,
      );

      // Update local state
      final updatedCategories = List<BudgetCategory>.from(budget.categories);
      updatedCategories[categoryIndex] = updatedCategory;

      final newAllocatedBudget = updatedCategories.fold<double>(
        0,
        (sum, category) => sum + category.allocatedAmount,
      );

      final updatedBudget = budget.copyWith(
        categories: updatedCategories,
        allocatedBudget: newAllocatedBudget,
        updatedAt: DateTime.now(),
      );

      // Sync budget totals to Supabase
      await SupabaseService.update(
        table: 'budgets',
        data: updatedBudget.toSupabaseJson(),
        column: 'id',
        value: budgetId,
      );

      _budgets[budgetIndex] = updatedBudget;
      notifyListeners();
    } catch (e) {
      debugPrint('BudgetProvider: update allocation error: $e');
    }
  }

  // Add expense to budget
  Future<void> addExpense(BudgetExpense expense) async {
    final budgetIndex = _budgets.indexWhere((b) => b.id == expense.budgetId);
    if (budgetIndex == -1) return;

    try {
      // Sync to Supabase
      await SupabaseService.insert(
        table: 'budget_expenses',
        data: expense.toSupabaseJson(),
      );

      final budget = _budgets[budgetIndex];
      final updatedExpenses = [...budget.expenses, expense];

      // Update Category spent amount
      final categoryIndex = budget.categories.indexWhere((c) => c.id == expense.categoryId);
      List<BudgetCategory> updatedCategories = budget.categories;
      if (categoryIndex != -1) {
        final newCategorySpent = updatedExpenses
            .where((e) => e.categoryId == expense.categoryId && e.isPaid)
            .fold<double>(0, (sum, e) => sum + e.amount);
            
        final updatedCategory = budget.categories[categoryIndex].copyWith(
          spentAmount: newCategorySpent,
          updatedAt: DateTime.now(),
        );
        
        await SupabaseService.update(
          table: 'budget_categories',
          data: updatedCategory.toSupabaseJson(budget.id),
          column: 'id',
          value: expense.categoryId,
        );
        
        updatedCategories = List<BudgetCategory>.from(budget.categories);
        updatedCategories[categoryIndex] = updatedCategory;
      }

      final newSpentBudget = updatedExpenses
          .where((exp) => exp.isPaid)
          .fold<double>(0, (sum, exp) => sum + exp.amount);

      final updatedBudget = budget.copyWith(
        expenses: updatedExpenses,
        categories: updatedCategories,
        spentBudget: newSpentBudget,
        updatedAt: DateTime.now(),
      );

      // Sync budget totals to Supabase
      await SupabaseService.update(
        table: 'budgets',
        data: updatedBudget.toSupabaseJson(),
        column: 'id',
        value: expense.budgetId,
      );

      _budgets[budgetIndex] = updatedBudget;
      notifyListeners();
    } catch (e) {
      debugPrint('BudgetProvider: add expense error: $e');
    }
  }

  // Update expense status
  Future<void> updateExpenseStatus(String expenseId, ExpenseStatus status) async {
    for (var i = 0; i < _budgets.length; i++) {
      final budget = _budgets[i];
      final expenseIndex = budget.expenses.indexWhere((exp) => exp.id == expenseId);
      if (expenseIndex != -1) {
        final categoryId = budget.expenses[expenseIndex].categoryId;
        final updatedExpense = budget.expenses[expenseIndex].copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );

        try {
          // Sync to Supabase
          await SupabaseService.update(
            table: 'budget_expenses',
            data: updatedExpense.toSupabaseJson(),
            column: 'id',
            value: expenseId,
          );

          final updatedExpenses = List<BudgetExpense>.from(budget.expenses);
          updatedExpenses[expenseIndex] = updatedExpense;

          // Update Category spent amount
          final categoryIndex = budget.categories.indexWhere((c) => c.id == categoryId);
          List<BudgetCategory> updatedCategories = budget.categories;
          if (categoryIndex != -1) {
            final newCategorySpent = updatedExpenses
                .where((e) => e.categoryId == categoryId && e.isPaid)
                .fold<double>(0, (sum, e) => sum + e.amount);

            final updatedCategory = budget.categories[categoryIndex].copyWith(
              spentAmount: newCategorySpent,
              updatedAt: DateTime.now(),
            );

            await SupabaseService.update(
              table: 'budget_categories',
              data: updatedCategory.toSupabaseJson(budget.id),
              column: 'id',
              value: categoryId,
            );

            updatedCategories = List<BudgetCategory>.from(budget.categories);
            updatedCategories[categoryIndex] = updatedCategory;
          }

          final newSpentBudget = updatedExpenses
              .where((exp) => exp.isPaid)
              .fold<double>(0, (sum, exp) => sum + exp.amount);

          final updatedBudget = budget.copyWith(
            expenses: updatedExpenses,
            categories: updatedCategories,
            spentBudget: newSpentBudget,
            updatedAt: DateTime.now(),
          );

          // Sync budget totals to Supabase
          await SupabaseService.update(
            table: 'budgets',
            data: updatedBudget.toSupabaseJson(),
            column: 'id',
            value: budget.id,
          );

          _budgets[i] = updatedBudget;
          notifyListeners();
        } catch (e) {
          debugPrint('BudgetProvider: update expense status error: $e');
        }
        break;
      }
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId, String budgetId) async {
    try {
      final budgetIndex = _budgets.indexWhere((b) => b.id == budgetId);
      if (budgetIndex == -1) return;

      final budget = _budgets[budgetIndex];
      final expenseIndex = budget.expenses.indexWhere((e) => e.id == expenseId);
      if (expenseIndex == -1) return;

      final categoryId = budget.expenses[expenseIndex].categoryId;

      await SupabaseService.delete(
        table: 'budget_expenses',
        column: 'id',
        value: expenseId,
      );

      final updatedExpenses = budget.expenses.where((exp) => exp.id != expenseId).toList();

      // Update Category spent amount
      final categoryIndex = budget.categories.indexWhere((c) => c.id == categoryId);
      List<BudgetCategory> updatedCategories = budget.categories;
      if (categoryIndex != -1) {
        final newCategorySpent = updatedExpenses
            .where((e) => e.categoryId == categoryId && e.isPaid)
            .fold<double>(0, (sum, e) => sum + e.amount);

        final updatedCategory = budget.categories[categoryIndex].copyWith(
          spentAmount: newCategorySpent,
          updatedAt: DateTime.now(),
        );

        await SupabaseService.update(
          table: 'budget_categories',
          data: updatedCategory.toSupabaseJson(budget.id),
          column: 'id',
          value: categoryId,
        );

        updatedCategories = List<BudgetCategory>.from(budget.categories);
        updatedCategories[categoryIndex] = updatedCategory;
      }

      final newSpentBudget = updatedExpenses
          .where((exp) => exp.isPaid)
          .fold<double>(0, (sum, exp) => sum + exp.amount);

      final updatedBudget = budget.copyWith(
        expenses: updatedExpenses,
        categories: updatedCategories,
        spentBudget: newSpentBudget,
        updatedAt: DateTime.now(),
      );

      await SupabaseService.update(
        table: 'budgets',
        data: updatedBudget.toSupabaseJson(),
        column: 'id',
        value: budgetId,
      );

      _budgets[budgetIndex] = updatedBudget;
      notifyListeners();
    } catch (e) {
      debugPrint('BudgetProvider: delete expense error: $e');
    }
  }

  // Get budget recommendations based on customer data
  Map<String, dynamic> getBudgetRecommendations(String customerId) {
    final customerAnalytics = _customerProvider.getCustomerAnalytics(customerId);
    final recommendations = <String, double>{};

    final avgOrderValue = customerAnalytics['averageOrderValue'] as double? ?? 0.0;
    final totalSpent = customerAnalytics['totalRevenue'] as double? ?? 0.0;

    if (avgOrderValue > 0) {
      recommendations['venue'] = avgOrderValue * 1.5;
      recommendations['catering'] = avgOrderValue * 0.8;
      recommendations['photography'] = avgOrderValue * 0.3;
      recommendations['decoration'] = avgOrderValue * 0.25;
      recommendations['entertainment'] = avgOrderValue * 0.15;
    }

    return {
      'recommendations': recommendations,
      'estimatedTotal': recommendations.values.fold<double>(0, (sum, val) => sum + val),
      'confidence': totalSpent > 1000 ? 'High' : totalSpent > 500 ? 'Medium' : 'Low',
    };
  }

  // Get budget insights
  Map<String, dynamic> getBudgetInsights(String budgetId) {
    final budget = getBudgetById(budgetId);
    if (budget == null) {
      return {'error': 'Budget not found'};
    }

    final alerts = budget.getBudgetAlerts();
    final recommendations = getBudgetRecommendations(budget.customerId);

    return {
      'budget': budget,
      'alerts': alerts,
      'recommendations': recommendations,
      'utilization': budget.budgetUtilization,
      'remaining': budget.remainingBudget,
      'isOverBudget': budget.isOverSpent,
    };
  }
}
