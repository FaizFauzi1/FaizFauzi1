import 'package:equatable/equatable.dart';

enum BankAccountStatus { pending, verified, rejected, suspended }

class BankAccount extends Equatable {
  final String id;
  final String userId;
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String? iban;
  final String? swiftCode;
  final String? routingNumber;
  final BankAccountStatus status;
  final String? rejectionReason;
  final bool isPrimary;
  final Map<String, dynamic> verificationData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BankAccount({
    required this.id,
    required this.userId,
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    this.iban,
    this.swiftCode,
    this.routingNumber,
    this.status = BankAccountStatus.pending,
    this.rejectionReason,
    this.isPrimary = false,
    required this.verificationData,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      bankName: json['bank_name'] as String,
      accountHolderName: json['account_holder_name'] as String,
      accountNumber: json['account_number'] as String,
      iban: json['iban'] as String?,
      swiftCode: json['swift_code'] as String?,
      routingNumber: json['routing_number'] as String?,
      status: BankAccountStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => BankAccountStatus.pending,
      ),
      rejectionReason: json['rejection_reason'] as String?,
      isPrimary: json['is_primary'] ?? false,
      verificationData: Map<String, dynamic>.from(json['verification_data'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'bank_name': bankName,
      'account_holder_name': accountHolderName,
      'account_number': accountNumber,
      'iban': iban,
      'swift_code': swiftCode,
      'routing_number': routingNumber,
      'status': status.name,
      'rejection_reason': rejectionReason,
      'is_primary': isPrimary,
      'verification_data': verificationData,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  BankAccount copyWith({
    String? id,
    String? userId,
    String? bankName,
    String? accountHolderName,
    String? accountNumber,
    String? iban,
    String? swiftCode,
    String? routingNumber,
    BankAccountStatus? status,
    String? rejectionReason,
    bool? isPrimary,
    Map<String, dynamic>? verificationData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BankAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      bankName: bankName ?? this.bankName,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      accountNumber: accountNumber ?? this.accountNumber,
      iban: iban ?? this.iban,
      swiftCode: swiftCode ?? this.swiftCode,
      routingNumber: routingNumber ?? this.routingNumber,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      isPrimary: isPrimary ?? this.isPrimary,
      verificationData: verificationData ?? this.verificationData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        bankName,
        accountHolderName,
        accountNumber,
        iban,
        swiftCode,
        routingNumber,
        status,
        rejectionReason,
        isPrimary,
        verificationData,
        createdAt,
        updatedAt,
      ];
}
