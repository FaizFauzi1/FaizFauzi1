import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class ServicePricingTier {
  final String? id;
  final String? serviceId;
  final String? name; // "Silver", "Gold", "500 Pax"
  final int minPax;
  final int? maxPax;
  final double price;
  final double? originalPrice; // Added: For promotional "cut" pricing
  final DateTime? promoExpiry; // Added: For visual countdowns
  final String? description;

  ServicePricingTier({
    this.id,
    this.serviceId,
    this.name,
    required this.minPax,
    this.maxPax,
    required this.price,
    this.originalPrice,
    this.promoExpiry,
    this.description,
  });

  factory ServicePricingTier.fromJson(Map<String, dynamic> json) {
    return ServicePricingTier(
      id: json['id'],
      serviceId: json['service_id'],
      name: json['name'],
      minPax: json['min_pax'] ?? 0,
      maxPax: json['max_pax'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      originalPrice: json['original_price'] != null ? (json['original_price'] as num).toDouble() : null,
      promoExpiry: json['promo_expiry'] != null ? DateTime.parse(json['promo_expiry']) : null,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'name': name,
      'min_pax': minPax,
      'max_pax': maxPax,
      'price': price,
      'original_price': originalPrice,
      'promo_expiry': promoExpiry?.toIso8601String(),
      'description': description,
    };
  }
}

class ServiceComponent {
  final String? id;
  final String? serviceId;
  final String? parentComponentId; // For nested structures like Sets -> Categories
  final String componentType; // 'decoration', 'catering', 'set', 'category', etc.
  final String name;
  final String? description;
  final bool isOptional;
  final int selectionLimit; // For 'pick X' rules
  final List<ServiceItem> items;

  ServiceComponent({
    this.id,
    this.serviceId,
    this.parentComponentId,
    required this.componentType,
    required this.name,
    this.description,
    this.isOptional = false,
    this.selectionLimit = 0, // 0 means no limit (all included)
    this.items = const [],
  });

  factory ServiceComponent.fromJson(Map<String, dynamic> json) {
    var itemsList = <ServiceItem>[];
    if (json['items'] != null) {
      itemsList = (json['items'] as List)
          .map((i) => ServiceItem.fromJson(i))
          .toList();
    } else if (json['service_items'] != null) {
      itemsList = (json['service_items'] as List)
          .map((i) => ServiceItem.fromJson(i))
          .toList();
    }

    return ServiceComponent(
      id: json['id'],
      serviceId: json['service_id'],
      parentComponentId: json['parent_component_id'],
      componentType: json['component_type'] ?? 'generic',
      name: json['name'] ?? '',
      description: json['description'],
      isOptional: json['is_optional'] ?? false,
      selectionLimit: (json['selection_limit'] as num?)?.toInt() ?? 0,
      items: itemsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'service_id': serviceId,
      'parent_component_id': parentComponentId,
      'component_type': componentType,
      'name': name,
      'description': description,
      'is_optional': isOptional,
      'selection_limit': selectionLimit,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }

  ServiceComponent copyWith({
    String? id,
    String? serviceId,
    String? parentComponentId,
    String? componentType,
    String? name,
    String? description,
    bool? isOptional,
    int? selectionLimit,
    List<ServiceItem>? items,
  }) {
    return ServiceComponent(
      id: id ?? this.id,
      serviceId: serviceId ?? this.serviceId,
      parentComponentId: parentComponentId ?? this.parentComponentId,
      componentType: componentType ?? this.componentType,
      name: name ?? this.name,
      description: description ?? this.description,
      isOptional: isOptional ?? this.isOptional,
      selectionLimit: selectionLimit ?? this.selectionLimit,
      items: items ?? this.items,
    );
  }
}

class ServiceItem {
  final String? id;
  final String? componentId;
  final String name;
  final String? description;
  final int quantity;
  final double unitPrice;
  final bool isIncluded;
  final bool isOptional; // Added for optional items in catering
  final double? extraPrice; // Added for optional items with extra cost
  final String? imageUrl;
  final List<String> galleryUrls;
  final String? pdfUrl;
  final List<String> applicableTierIds;
  final bool isConditionalFree; // Added
  final String? freeCondition; // Added (e.g., "Min 500 pax")
  
  // Transient fields for UI state
  final bool isFree;
  final List<XFile>? newGalleryFiles;
  final PlatformFile? newPdfFile;

  ServiceItem({
    this.id,
    this.componentId,
    required this.name,
    this.description,
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.isIncluded = true,
    this.isOptional = false,
    this.extraPrice,
    this.imageUrl,
    this.galleryUrls = const [],
    this.pdfUrl,
    this.applicableTierIds = const [],
    this.isFree = false,
    this.isConditionalFree = false,
    this.freeCondition,
    this.newGalleryFiles,
    this.newPdfFile,
  });

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id']?.toString(),
      componentId: json['component_id']?.toString(),
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      isFree: json['is_free'] ?? false,
      isConditionalFree: json['is_conditional_free'] ?? false,
      freeCondition: json['free_condition']?.toString(),
      isIncluded: json['is_included'] ?? true,
      isOptional: json['is_optional'] ?? false,
      extraPrice: (json['extra_price'] as num?)?.toDouble(),
      imageUrl: json['image_url']?.toString(),
      galleryUrls: (json['gallery_urls'] is List) 
          ? (json['gallery_urls'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
          : [],
      pdfUrl: json['pdf_url']?.toString(),
      applicableTierIds: (json['applicable_tier_ids'] is List)
          ? (json['applicable_tier_ids'] as List).map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'component_id': componentId,
      'name': name,
      'description': description,
      'quantity': quantity,
      'unit_price': unitPrice,
      'is_free': isFree,
      'is_conditional_free': isConditionalFree,
      'free_condition': freeCondition,
      'is_included': isIncluded,
      'is_optional': isOptional,
      'extra_price': extraPrice,
      'image_url': imageUrl,
      'gallery_urls': galleryUrls,
      'pdf_url': pdfUrl,
      'applicable_tier_ids': applicableTierIds,
    };
  }

  ServiceItem copyWith({
    String? id,
    String? componentId,
    String? name,
    String? description,
    int? quantity,
    double? unitPrice,
    bool? isFree,
    bool? isConditionalFree,
    String? freeCondition,
    bool? isIncluded,
    bool? isOptional,
    double? extraPrice,
    String? imageUrl,
    List<String>? galleryUrls,
    String? pdfUrl,
    List<String>? applicableTierIds,
    List<XFile>? newGalleryFiles,
    PlatformFile? newPdfFile,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      componentId: componentId ?? this.componentId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      isFree: isFree ?? this.isFree,
      isConditionalFree: isConditionalFree ?? this.isConditionalFree,
      freeCondition: freeCondition ?? this.freeCondition,
      isIncluded: isIncluded ?? this.isIncluded,
      isOptional: isOptional ?? this.isOptional,
      extraPrice: extraPrice ?? this.extraPrice,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      applicableTierIds: applicableTierIds ?? this.applicableTierIds,
      newGalleryFiles: newGalleryFiles ?? this.newGalleryFiles,
      newPdfFile: newPdfFile ?? this.newPdfFile,
    );
  }
}
