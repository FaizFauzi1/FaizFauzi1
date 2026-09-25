import 'finance_transaction.dart';

enum ExpenseStatus { pending, approved, paid, rejected, cancelled }
enum ExpensePriority { low, medium, high, urgent }

class Expense {
  final String id;
  final String vendorId;
  final String title;
  final String description;
  final double amount;
  final TransactionCategory category;
  final ExpenseStatus status;
  final ExpensePriority priority;
  final DateTime date;
  final DateTime? dueDate;
  final String? receiptImage;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? paymentReference;
  final DateTime? paidAt;
  final Map<String, dynamic>? metadata;
  final bool isRecurring;
  final String? recurringId;

  Expense({
    required this.id,
    required this.vendorId,
    required this.title,
    required this.description,
    required this.amount,
    required this.category,
    required this.status,
    required this.priority,
    required this.date,
    this.dueDate,
    this.receiptImage,
    this.approvedBy,
    this.approvedAt,
    this.paymentReference,
    this.paidAt,
    this.metadata,
    this.isRecurring = false,
    this.recurringId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'title': title,
      'description': description,
      'amount': amount,
      'category': category.toString(),
      'status': status.toString(),
      'priority': priority.toString(),
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'receiptImage': receiptImage,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt?.toIso8601String(),
      'paymentReference': paymentReference,
      'paidAt': paidAt?.toIso8601String(),
      'metadata': metadata,
      'isRecurring': isRecurring,
      'recurringId': recurringId,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      vendorId: json['vendorId'],
      title: json['title'],
      description: json['description'],
      amount: json['amount']?.toDouble() ?? 0.0,
      category: TransactionCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
      ),
      status: ExpenseStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
      ),
      priority: ExpensePriority.values.firstWhere(
        (e) => e.toString() == json['priority'],
      ),
      date: DateTime.parse(json['date']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      receiptImage: json['receiptImage'],
      approvedBy: json['approvedBy'],
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      paymentReference: json['paymentReference'],
      paidAt: json['paidAt'] != null ? DateTime.parse(json['paidAt']) : null,
      metadata: json['metadata'],
      isRecurring: json['isRecurring'] ?? false,
      recurringId: json['recurringId'],
    );
  }

  factory Expense.fromSupabase(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      vendorId: json['vendor_id'],
      title: json['title'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      category: TransactionCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => TransactionCategory.otherExpense,
      ),
      status: ExpenseStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => ExpenseStatus.pending,
      ),
      priority: ExpensePriority.values.firstWhere(
        (e) => e.toString().split('.').last == json['priority'],
        orElse: () => ExpensePriority.medium,
      ),
      date: DateTime.parse(json['date']),
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      receiptImage: json['receipt_image'],
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      paymentReference: json['payment_reference'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      metadata: json['metadata'],
      isRecurring: json['is_recurring'] ?? false,
      recurringId: json['recurring_id'],
    );
  }

  String get statusDisplayName {
    switch (status) {
      case ExpenseStatus.pending:
        return 'Pending';
      case ExpenseStatus.approved:
        return 'Approved';
      case ExpenseStatus.paid:
        return 'Paid';
      case ExpenseStatus.rejected:
        return 'Rejected';
      case ExpenseStatus.cancelled:
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String get priorityDisplayName {
    switch (priority) {
      case ExpensePriority.low:
        return 'Low';
      case ExpensePriority.medium:
        return 'Medium';
      case ExpensePriority.high:
        return 'High';
      case ExpensePriority.urgent:
        return 'Urgent';
      default:
        return 'Unknown';
    }
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.now().isAfter(dueDate!) && status != ExpenseStatus.paid;
  }

  bool get needsApproval {
    return status == ExpenseStatus.pending && amount > 1000; // Example threshold
  }
}

class ExpenseCategoryBudget {
  final String id;
  final String vendorId;
  final TransactionCategory category;
  final double budgetedAmount;
  final double spentAmount;
  final DateTime periodStart;
  final DateTime periodEnd;
  final bool isActive;

  ExpenseCategoryBudget({
    required this.id,
    required this.vendorId,
    required this.category,
    required this.budgetedAmount,
    required this.spentAmount,
    required this.periodStart,
    required this.periodEnd,
    required this.isActive,
  });

  double get remainingAmount => budgetedAmount - spentAmount;
  double get utilizationPercentage => spentAmount / budgetedAmount * 100;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'category': category.toString(),
      'budgetedAmount': budgetedAmount,
      'spentAmount': spentAmount,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'isActive': isActive,
    };
  }

  factory ExpenseCategoryBudget.fromJson(Map<String, dynamic> json) {
    return ExpenseCategoryBudget(
      id: json['id'],
      vendorId: json['vendorId'],
      category: TransactionCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
      ),
      budgetedAmount: json['budgetedAmount']?.toDouble() ?? 0.0,
      spentAmount: json['spentAmount']?.toDouble() ?? 0.0,
      periodStart: DateTime.parse(json['periodStart']),
      periodEnd: DateTime.parse(json['periodEnd']),
      isActive: json['isActive'] ?? true,
    );
  }

  factory ExpenseCategoryBudget.fromSupabase(Map<String, dynamic> json) {
    return ExpenseCategoryBudget(
      id: json['id'],
      vendorId: json['vendor_id'],
      category: TransactionCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
        orElse: () => TransactionCategory.otherExpense,
      ),
      budgetedAmount: (json['budgeted_amount'] as num).toDouble(),
      spentAmount: (json['spent_amount'] as num).toDouble(),
      periodStart: DateTime.parse(json['period_start']),
      periodEnd: DateTime.parse(json['period_end']),
      isActive: json['is_active'] ?? true,
    );
  }
}
