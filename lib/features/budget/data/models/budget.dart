import 'package:eventease/features/budget/data/models/budget_category.dart';
import 'package:eventease/features/budget/data/models/budget_expense.dart';

class Budget {
  final String id;
  final String eventId;
  final String customerId;
  final double totalBudget;
  final double allocatedBudget;
  final double spentBudget;
  final List<BudgetCategory> categories;
  final List<BudgetExpense> expenses;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.eventId,
    required this.customerId,
    required this.totalBudget,
    required this.allocatedBudget,
    required this.spentBudget,
    required this.categories,
    required this.expenses,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculate remaining budget
  double get remainingBudget => totalBudget - spentBudget;

  // Calculate budget utilization percentage
  double get budgetUtilization => totalBudget > 0 ? (spentBudget / totalBudget) * 100 : 0;

  // Get budget by category
  double getBudgetForCategory(String categoryId) {
    final category = categories.firstWhere(
      (cat) => cat.id == categoryId,
      orElse: () => BudgetCategory(
        id: categoryId,
        name: 'Unknown',
        allocatedAmount: 0,
        spentAmount: 0,
        color: '#FF0000',
        type: BudgetCategoryType.miscellaneous,
      ),
    );
    return category.allocatedAmount;
  }

  // Get spent amount by category
  double getSpentForCategory(String categoryId) {
    return expenses
        .where((expense) => expense.categoryId == categoryId && expense.isPaid)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  // Check if budget is over allocated
  bool get isOverAllocated => allocatedBudget > totalBudget;

  // Check if budget is over spent
  bool get isOverSpent => spentBudget > totalBudget;

  // Get budget alerts
  List<String> getBudgetAlerts() {
    final alerts = <String>[];

    if (isOverAllocated) {
      alerts.add('Budget allocation exceeds total budget by RM ${(allocatedBudget - totalBudget).toStringAsFixed(2)}');
    }

    if (isOverSpent) {
      alerts.add('Budget spent exceeds total budget by RM ${(spentBudget - totalBudget).toStringAsFixed(2)}');
    }

    if (budgetUtilization > 90) {
      alerts.add('Budget utilization is ${budgetUtilization.toStringAsFixed(1)}% - monitor spending closely');
    }

    final unallocatedAmount = totalBudget - allocatedBudget;
    if (unallocatedAmount > totalBudget * 0.2) {
      alerts.add('RM ${unallocatedAmount.toStringAsFixed(2)} remains unallocated');
    }

    return alerts;
  }

  // Create copy with updated values
  Budget copyWith({
    String? id,
    String? eventId,
    String? customerId,
    double? totalBudget,
    double? allocatedBudget,
    double? spentBudget,
    List<BudgetCategory>? categories,
    List<BudgetExpense>? expenses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      customerId: customerId ?? this.customerId,
      totalBudget: totalBudget ?? this.totalBudget,
      allocatedBudget: allocatedBudget ?? this.allocatedBudget,
      spentBudget: spentBudget ?? this.spentBudget,
      categories: categories ?? this.categories,
      expenses: expenses ?? this.expenses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'customerId': customerId,
      'totalBudget': totalBudget,
      'allocatedBudget': allocatedBudget,
      'spentBudget': spentBudget,
      'categories': categories.map((cat) => cat.toJson()).toList(),
      'expenses': expenses.map((exp) => exp.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      eventId: json['eventId'],
      customerId: json['customerId'],
      totalBudget: (json['totalBudget'] ?? 0.0).toDouble(),
      allocatedBudget: (json['allocatedBudget'] ?? 0.0).toDouble(),
      spentBudget: (json['spentBudget'] ?? 0.0).toDouble(),
      categories: (json['categories'] as List? ?? [])
          .map((cat) => BudgetCategory.fromJson(cat))
          .toList(),
      expenses: (json['expenses'] as List? ?? [])
          .map((exp) => BudgetExpense.fromJson(exp))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Supabase Mapping
  factory Budget.fromSupabase(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      eventId: json['event_id'],
      customerId: json['customer_id'],
      totalBudget: (json['total_budget'] ?? 0.0).toDouble(),
      allocatedBudget: (json['allocated_budget'] ?? 0.0).toDouble(),
      spentBudget: (json['spent_budget'] ?? 0.0).toDouble(),
      categories: (json['budget_categories'] as List? ?? [])
          .map((cat) => BudgetCategory.fromSupabase(cat))
          .toList(),
      expenses: (json['budget_expenses'] as List? ?? [])
          .map((exp) => BudgetExpense.fromSupabase(exp))
          .toList(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'event_id': eventId,
      'customer_id': customerId,
      'total_budget': totalBudget,
      'allocated_budget': allocatedBudget,
      'spent_budget': spentBudget,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Aliases for persistence
  Map<String, dynamic> toMap() => toJson();
  factory Budget.fromMap(Map<String, dynamic> map) => Budget.fromJson(map);
}
