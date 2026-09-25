import 'package:uuid/uuid.dart';

enum BudgetCategoryType {
  venue,
  catering,
  photography,
  decoration,
  entertainment,
  transportation,
  stationery,
  miscellaneous,
}

class BudgetCategory {
  final String id;
  final String name;
  final String description;
  final double allocatedAmount;
  final double spentAmount;
  final String color;
  final BudgetCategoryType type;
  final bool isRequired;
  final DateTime createdAt;
  final DateTime updatedAt;

  BudgetCategory({
    required this.id,
    required this.name,
    this.description = '',
    required this.allocatedAmount,
    this.spentAmount = 0.0,
    required this.color,
    required this.type,
    this.isRequired = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) :
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  // Calculate remaining amount for this category
  double get remainingAmount => allocatedAmount - spentAmount;

  // Check if category is over budget
  bool get isOverBudget => spentAmount > allocatedAmount;

  // Calculate utilization percentage
  double get utilizationPercentage => allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0;

  // Get default categories for event planning
  static List<BudgetCategory> getDefaultCategories() {
    return [
      BudgetCategory(
        id: const Uuid().v4(),
        name: 'Venue',
        description: 'Wedding venue, hall rental, setup costs',
        allocatedAmount: 0,
        color: '#FF6B6B',
        type: BudgetCategoryType.venue,
        isRequired: true,
      ),
      BudgetCategory(
        id: const Uuid().v4(),
        name: 'Catering',
        description: 'Food, beverages, cake, service',
        allocatedAmount: 0,
        color: '#4ECDC4',
        type: BudgetCategoryType.catering,
        isRequired: true,
      ),
      BudgetCategory(
        id: const Uuid().v4(),
        name: 'Photography',
        description: 'Photographer, videographer, albums',
        allocatedAmount: 0,
        color: '#45B7D1',
        type: BudgetCategoryType.photography,
        isRequired: false,
      ),
      BudgetCategory(
        id: const Uuid().v4(),
        name: 'Decoration',
        description: 'Flowers, centerpieces, lighting, theme items',
        allocatedAmount: 0,
        color: '#FFA07A',
        type: BudgetCategoryType.decoration,
        isRequired: false,
      ),
      BudgetCategory(
        id: const Uuid().v4(),
        name: 'Entertainment',
        description: 'Music, DJ, performers, games',
        allocatedAmount: 0,
        color: '#98D8C8',
        type: BudgetCategoryType.entertainment,
        isRequired: false,
      ),
      BudgetCategory(
        id: const Uuid().v4(),
        name: 'Transportation',
        description: 'Limo, shuttle service, parking',
        allocatedAmount: 0,
        color: '#F7DC6F',
        type: BudgetCategoryType.transportation,
        isRequired: false,
      ),
      BudgetCategory(
        id: const Uuid().v4(),
        name: 'Stationery',
        description: 'Invitations, programs, thank you cards',
        allocatedAmount: 0,
        color: '#BB8FCE',
        type: BudgetCategoryType.stationery,
        isRequired: false,
      ),
      BudgetCategory(
        id: const Uuid().v4(),
        name: 'Miscellaneous',
        description: 'Unexpected expenses, tips, contingency',
        allocatedAmount: 0,
        color: '#85C1E9',
        type: BudgetCategoryType.miscellaneous,
        isRequired: false,
      ),
    ];
  }

  // Create copy with updated values
  BudgetCategory copyWith({
    String? id,
    String? name,
    String? description,
    double? allocatedAmount,
    double? spentAmount,
    String? color,
    BudgetCategoryType? type,
    bool? isRequired,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      color: color ?? this.color,
      type: type ?? this.type,
      isRequired: isRequired ?? this.isRequired,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      'color': color,
      'type': type.toString(),
      'isRequired': isRequired,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory BudgetCategory.fromJson(Map<String, dynamic> json) {
    return BudgetCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      allocatedAmount: (json['allocatedAmount'] ?? 0.0).toDouble(),
      spentAmount: (json['spentAmount'] ?? 0.0).toDouble(),
      color: json['color'] ?? '#000000',
      type: BudgetCategoryType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BudgetCategoryType.miscellaneous,
      ),
      isRequired: json['isRequired'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  // Supabase Mapping
  factory BudgetCategory.fromSupabase(Map<String, dynamic> json) {
    return BudgetCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      allocatedAmount: (json['allocated_amount'] ?? 0.0).toDouble(),
      spentAmount: (json['spent_amount'] ?? 0.0).toDouble(),
      color: json['color'] ?? '#000000',
      type: BudgetCategoryType.values.firstWhere(
        (e) => e.toString() == (json['type'] ?? ''),
        orElse: () => BudgetCategoryType.miscellaneous,
      ),
      isRequired: json['is_required'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toSupabaseJson(String budgetId) {
    return {
      'id': id,
      'budget_id': budgetId,
      'name': name,
      'description': description,
      'allocated_amount': allocatedAmount,
      'spent_amount': spentAmount,
      'color': color,
      'type': type.toString(),
      'is_required': isRequired,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Aliases for persistence
  Map<String, dynamic> toMap() => toJson();
  factory BudgetCategory.fromMap(Map<String, dynamic> map) => BudgetCategory.fromJson(map);
}
