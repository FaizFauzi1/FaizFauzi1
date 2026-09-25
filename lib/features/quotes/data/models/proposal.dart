/// Vendor proposal / quote model for interactive proposal builder.
class Proposal {
  final String id;
  final String vendorId;
  final String customerId;
  final String? bookingId;
  final String title;
  final String status;
  final double baseAmount;
  final List<ProposalAddon> addons;
  final DateTime? expiresAt;
  final int version;
  final DateTime createdAt;

  const Proposal({
    required this.id,
    required this.vendorId,
    required this.customerId,
    this.bookingId,
    required this.title,
    this.status = 'draft',
    required this.baseAmount,
    this.addons = const [],
    this.expiresAt,
    this.version = 1,
    required this.createdAt,
  });

  double get total =>
      baseAmount + addons.where((a) => a.selected).fold(0.0, (s, a) => s + a.price);

  factory Proposal.fromJson(Map<String, dynamic> json) => Proposal(
        id: json['id'] as String,
        vendorId: json['vendor_id'] as String,
        customerId: json['customer_id'] as String,
        bookingId: json['booking_id'] as String?,
        title: json['title'] as String? ?? 'Proposal',
        status: json['status'] as String? ?? 'draft',
        baseAmount: (json['base_amount'] as num?)?.toDouble() ?? 0,
        addons: (json['addons'] as List?)
                ?.map((e) => ProposalAddon.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        expiresAt: json['expires_at'] != null
            ? DateTime.parse(json['expires_at'] as String)
            : null,
        version: json['version'] as int? ?? 1,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'vendor_id': vendorId,
        'customer_id': customerId,
        'booking_id': bookingId,
        'title': title,
        'status': status,
        'base_amount': baseAmount,
        'addons': addons.map((a) => a.toJson()).toList(),
        'expires_at': expiresAt?.toIso8601String(),
        'version': version,
        'created_at': createdAt.toIso8601String(),
      };
}

class ProposalAddon {
  final String id;
  final String name;
  final double price;
  final bool selected;

  const ProposalAddon({
    required this.id,
    required this.name,
    required this.price,
    this.selected = false,
  });

  ProposalAddon copyWith({bool? selected}) => ProposalAddon(
        id: id,
        name: name,
        price: price,
        selected: selected ?? this.selected,
      );

  factory ProposalAddon.fromJson(Map<String, dynamic> json) => ProposalAddon(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        selected: json['selected'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'selected': selected,
      };
}
