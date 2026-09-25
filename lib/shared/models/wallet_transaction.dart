import 'package:equatable/equatable.dart';

enum TransactionType { credit, debit }

class WalletTransaction extends Equatable {
  final String id;
  final String walletId;
  final TransactionType transactionType;
  final double amount;
  final double balanceBefore;
  final double balanceAfter;
  final String referenceType;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.transactionType,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.referenceType,
    this.referenceId,
    this.description,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      transactionType: TransactionType.values.firstWhere(
        (type) => type.name == json['transaction_type'],
        orElse: () => TransactionType.credit,
      ),
      amount: (json['amount'] ?? 0).toDouble(),
      balanceBefore: (json['balance_before'] ?? 0).toDouble(),
      balanceAfter: (json['balance_after'] ?? 0).toDouble(),
      referenceType: json['reference_type'] as String,
      referenceId: json['reference_id'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'transaction_type': transactionType.name,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        walletId,
        transactionType,
        amount,
        balanceBefore,
        balanceAfter,
        referenceType,
        referenceId,
        description,
        createdAt,
      ];
}
