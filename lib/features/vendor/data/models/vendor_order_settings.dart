import 'package:equatable/equatable.dart';

/// Vendor-specific settings for customizing the order form in chat
class VendorOrderSettings extends Equatable {
  final String vendorId;
  final bool requireEventDate;
  final bool requireEventTime;
  final bool requireDeliveryAddress;
  final bool requireSpecialRequirements;
  final bool showQuantityField;
  final bool showDeliveryMethod;
  final String defaultDeliveryMethod; // 'Pickup' or 'Delivery'
  final int minOrderQuantity;
  final int maxOrderQuantity;
  final List<CustomOrderField> customFields;
  final bool autoApproveOrders;
  final String? orderInstructions; // Custom message to show in order dialog
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorOrderSettings({
    required this.vendorId,
    this.requireEventDate = true,
    this.requireEventTime = false,
    this.requireDeliveryAddress = false,
    this.requireSpecialRequirements = false,
    this.showQuantityField = true,
    this.showDeliveryMethod = true,
    this.defaultDeliveryMethod = 'Pickup',
    this.minOrderQuantity = 1,
    this.maxOrderQuantity = 999,
    this.customFields = const [],
    this.autoApproveOrders = false,
    this.orderInstructions,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Default settings for vendors who haven't customized their order form
  factory VendorOrderSettings.defaultSettings(String vendorId) {
    return VendorOrderSettings(
      vendorId: vendorId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  factory VendorOrderSettings.fromSupabase(Map<String, dynamic> json) {
    return VendorOrderSettings(
      vendorId: json['vendor_id'] as String,
      requireEventDate: json['require_event_date'] as bool? ?? true,
      requireEventTime: json['require_event_time'] as bool? ?? false,
      requireDeliveryAddress: json['require_delivery_address'] as bool? ?? false,
      requireSpecialRequirements: json['require_special_requirements'] as bool? ?? false,
      showQuantityField: json['show_quantity_field'] as bool? ?? true,
      showDeliveryMethod: json['show_delivery_method'] as bool? ?? true,
      defaultDeliveryMethod: json['default_delivery_method'] as String? ?? 'Pickup',
      minOrderQuantity: json['min_order_quantity'] as int? ?? 1,
      maxOrderQuantity: json['max_order_quantity'] as int? ?? 999,
      customFields: (json['custom_fields'] as List?)
              ?.map((f) => CustomOrderField.fromJson(f as Map<String, dynamic>))
              .toList() ??
          const [],
      autoApproveOrders: json['auto_approve_orders'] as bool? ?? false,
      orderInstructions: json['order_instructions'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toSupabaseJson() {
    return {
      'vendor_id': vendorId,
      'require_event_date': requireEventDate,
      'require_event_time': requireEventTime,
      'require_delivery_address': requireDeliveryAddress,
      'require_special_requirements': requireSpecialRequirements,
      'show_quantity_field': showQuantityField,
      'show_delivery_method': showDeliveryMethod,
      'default_delivery_method': defaultDeliveryMethod,
      'min_order_quantity': minOrderQuantity,
      'max_order_quantity': maxOrderQuantity,
      'custom_fields': customFields.map((f) => f.toJson()).toList(),
      'auto_approve_orders': autoApproveOrders,
      'order_instructions': orderInstructions,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  VendorOrderSettings copyWith({
    String? vendorId,
    bool? requireEventDate,
    bool? requireEventTime,
    bool? requireDeliveryAddress,
    bool? requireSpecialRequirements,
    bool? showQuantityField,
    bool? showDeliveryMethod,
    String? defaultDeliveryMethod,
    int? minOrderQuantity,
    int? maxOrderQuantity,
    List<CustomOrderField>? customFields,
    bool? autoApproveOrders,
    String? orderInstructions,
  }) {
    return VendorOrderSettings(
      vendorId: vendorId ?? this.vendorId,
      requireEventDate: requireEventDate ?? this.requireEventDate,
      requireEventTime: requireEventTime ?? this.requireEventTime,
      requireDeliveryAddress: requireDeliveryAddress ?? this.requireDeliveryAddress,
      requireSpecialRequirements: requireSpecialRequirements ?? this.requireSpecialRequirements,
      showQuantityField: showQuantityField ?? this.showQuantityField,
      showDeliveryMethod: showDeliveryMethod ?? this.showDeliveryMethod,
      defaultDeliveryMethod: defaultDeliveryMethod ?? this.defaultDeliveryMethod,
      minOrderQuantity: minOrderQuantity ?? this.minOrderQuantity,
      maxOrderQuantity: maxOrderQuantity ?? this.maxOrderQuantity,
      customFields: customFields ?? this.customFields,
      autoApproveOrders: autoApproveOrders ?? this.autoApproveOrders,
      orderInstructions: orderInstructions ?? this.orderInstructions,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        vendorId,
        requireEventDate,
        requireEventTime,
        requireDeliveryAddress,
        requireSpecialRequirements,
        showQuantityField,
        showDeliveryMethod,
        defaultDeliveryMethod,
        minOrderQuantity,
        maxOrderQuantity,
        customFields,
        autoApproveOrders,
        orderInstructions,
      ];
}

/// Custom field definition for vendor order forms
class CustomOrderField extends Equatable {
  final String id;
  final String label;
  final String fieldType; // 'text', 'number', 'dropdown', 'checkbox', 'date'
  final bool required;
  final String? placeholder;
  final List<String>? options; // For dropdown fields
  final String? defaultValue;
  final int order; // Display order

  const CustomOrderField({
    required this.id,
    required this.label,
    required this.fieldType,
    this.required = false,
    this.placeholder,
    this.options,
    this.defaultValue,
    this.order = 0,
  });

  factory CustomOrderField.fromJson(Map<String, dynamic> json) {
    return CustomOrderField(
      id: json['id'] as String,
      label: json['label'] as String,
      fieldType: json['field_type'] as String,
      required: json['required'] as bool? ?? false,
      placeholder: json['placeholder'] as String?,
      options: (json['options'] as List?)?.cast<String>(),
      defaultValue: json['default_value'] as String?,
      order: json['order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'field_type': fieldType,
      'required': required,
      'placeholder': placeholder,
      'options': options,
      'default_value': defaultValue,
      'order': order,
    };
  }

  @override
  List<Object?> get props => [
        id,
        label,
        fieldType,
        required,
        placeholder,
        options,
        defaultValue,
        order,
      ];
}
