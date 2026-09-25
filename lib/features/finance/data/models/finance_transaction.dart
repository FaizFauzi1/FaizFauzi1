import 'package:eventease/shared/models/payment.dart';

enum TransactionType { income, expense, transfer }
enum TransactionCategory {
  // Income Categories
  bookingPayment,
  servicePayment,
  productSale,
  commission,
  refund,
  otherIncome,

  // Expense Categories
  marketing,
  staff,
  rent,
  utilities,
  supplies,
  equipment,
  insurance,
  taxes,
  otherExpense,
}



class FinanceTransaction {
  final String id;
  final String vendorId;
  final TransactionType type;
  final TransactionCategory category;
  final String description;
  final double amount;
  final PaymentMethod paymentMethod;
  final DateTime date;
  final String? reference;
  final String? receiptImage;
  final bool isRecurring;
  final String? recurringId;
  final Map<String, dynamic>? metadata;

  FinanceTransaction({
    required this.id,
    required this.vendorId,
    required this.type,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    required this.date,
    this.reference,
    this.receiptImage,
    this.isRecurring = false,
    this.recurringId,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vendorId': vendorId,
      'type': type.toString(),
      'category': category.toString(),
      'description': description,
      'amount': amount,
      'paymentMethod': paymentMethod.toString(),
      'date': date.toIso8601String(),
      'reference': reference,
      'receiptImage': receiptImage,
      'isRecurring': isRecurring,
      'recurringId': recurringId,
      'metadata': metadata,
    };
  }

  factory FinanceTransaction.fromJson(Map<String, dynamic> json) {
    return FinanceTransaction(
      id: json['id'],
      vendorId: json['vendorId'],
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == json['type'],
      ),
      category: TransactionCategory.values.firstWhere(
        (e) => e.toString() == json['category'],
      ),
      description: json['description'],
      amount: json['amount']?.toDouble() ?? 0.0,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString() == json['paymentMethod'],
      ),
      date: DateTime.parse(json['date']),
      reference: json['reference'],
      receiptImage: json['receiptImage'],
      isRecurring: json['isRecurring'] ?? false,
      recurringId: json['recurringId'],
      metadata: json['metadata'],
    );
  }

  String get categoryDisplayName {
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

  String get paymentMethodDisplayName {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.creditCard:
        return 'Credit Card';
      case PaymentMethod.debitCard:
        return 'Debit Card';
      case PaymentMethod.onlinePayment:
        return 'Online Payment';
      case PaymentMethod.check:
        return 'Check';
      default:
        return 'Unknown';
    }
  }
}

class FinanceSummary {
  final String vendorId;
  final double totalIncome;
  final double totalExpenses;
  final double netProfit;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double monthlyProfit;
  final int totalTransactions;
  final DateTime lastUpdated;

  FinanceSummary({
    required this.vendorId,
    required this.totalIncome,
    required this.totalExpenses,
    required this.netProfit,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlyProfit,
    required this.totalTransactions,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() {
    return {
      'vendorId': vendorId,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netProfit': netProfit,
      'monthlyIncome': monthlyIncome,
      'monthlyExpenses': monthlyExpenses,
      'monthlyProfit': monthlyProfit,
      'totalTransactions': totalTransactions,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory FinanceSummary.fromJson(Map<String, dynamic> json) {
    return FinanceSummary(
      vendorId: json['vendorId'],
      totalIncome: json['totalIncome']?.toDouble() ?? 0.0,
      totalExpenses: json['totalExpenses']?.toDouble() ?? 0.0,
      netProfit: json['netProfit']?.toDouble() ?? 0.0,
      monthlyIncome: json['monthlyIncome']?.toDouble() ?? 0.0,
      monthlyExpenses: json['monthlyExpenses']?.toDouble() ?? 0.0,
      monthlyProfit: json['monthlyProfit']?.toDouble() ?? 0.0,
      totalTransactions: json['totalTransactions'] ?? 0,
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}
