enum ExpenseStatus {
  pending,
  approved,
  paid,
  cancelled,
}

class BudgetExpense {
  final String id;
  final String budgetId;
  final String categoryId;
  final String vendorId;
  final String description;
  final double amount;
  final ExpenseStatus status;
  final DateTime expenseDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? receiptUrl;
  final String? notes;
  final bool isRecurring;

  BudgetExpense({
    required this.id,
    required this.budgetId,
    required this.categoryId,
    required this.vendorId,
    required this.description,
    required this.amount,
    this.status = ExpenseStatus.pending,
    required this.expenseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.receiptUrl,
    this.notes,
    this.isRecurring = false,
  }) :
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Check if expense is approved or paid
  bool get isApproved => status == ExpenseStatus.approved || status == ExpenseStatus.paid;

  // Check if expense is paid
  bool get isPaid => status == ExpenseStatus.paid;

  // Create copy with updated values
  BudgetExpense copyWith({
    String? id,
    String? budgetId,
    String? categoryId,
    String? vendorId,
    String? description,
    double? amount,
    ExpenseStatus? status,
    DateTime? expenseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? receiptUrl,
    String? notes,
    bool? isRecurring,
  }) {
    return BudgetExpense(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      categoryId: categoryId ?? this.categoryId,
      vendorId: vendorId ?? this.vendorId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      notes: notes ?? this.notes,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'budgetId': budgetId,
      'categoryId': categoryId,
      'vendorId': vendorId,
      'description': description,
      'amount': amount,
      'status': status.toString(),
      'expenseDate': expenseDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'receiptUrl': receiptUrl,
      'notes': notes,
      'isRecurring': isRecurring,
    };
  }

  // Create from JSON
  factory BudgetExpense.fromJson(Map<String, dynamic> json) {
    return BudgetExpense(
      id: json['id'],
      budgetId: json['budgetId'],
      categoryId: json['categoryId'],
      vendorId: json['vendorId'],
      description: json['description'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: ExpenseStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => ExpenseStatus.pending,
      ),
      expenseDate: DateTime.parse(json['expenseDate']),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      receiptUrl: json['receiptUrl'],
      notes: json['notes'],
      isRecurring: json['isRecurring'] ?? false,
    );
  }

  // Supabase Mapping
  factory BudgetExpense.fromSupabase(Map<String, dynamic> json) {
    return BudgetExpense(
      id: json['id'],
      budgetId: json['budget_id'],
      categoryId: json['category_id'],
      vendorId: json['vendor_id'],
      description: json['description'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: ExpenseStatus.values.firstWhere(
        (e) => e.toString() == (json['status'] ?? ''),
        orElse: () => ExpenseStatus.pending,
      ),
      expenseDate: DateTime.parse(json['expense_date']),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      receiptUrl: json['receipt_url'],
      notes: json['notes'],
      isRecurring: json['is_recurring'] ?? false,
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'id': id,
      'budget_id': budgetId,
      'category_id': categoryId,
      'vendor_id': vendorId,
      'description': description,
      'amount': amount,
      'status': status.toString(),
      'expense_date': expenseDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'receipt_url': receiptUrl,
      'notes': notes,
      'is_recurring': isRecurring,
    };
  }

  // Aliases for persistence
  Map<String, dynamic> toMap() => toJson();
  factory BudgetExpense.fromMap(Map<String, dynamic> map) => BudgetExpense.fromJson(map);
}
