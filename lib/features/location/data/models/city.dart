class City {
  final String id;
  final String regionId;
  final String name;
  final String? postcodePrefix;
  final bool isActive;

  City({
    required this.id,
    required this.regionId,
    required this.name,
    this.postcodePrefix,
    this.isActive = true,
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      id: json['id'],
      regionId: json['region_id'],
      name: json['name'],
      postcodePrefix: json['postcode_prefix'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'region_id': regionId,
      'name': name,
      'postcode_prefix': postcodePrefix,
      'is_active': isActive,
    };
  }
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
