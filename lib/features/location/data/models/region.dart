class Region {
  final String id;
  final String name;
  final String? code;
  final String countryCode;
  final bool isActive;

  Region({
    required this.id,
    required this.name,
    this.code,
    this.countryCode = 'MY',
    this.isActive = true,
  });

  factory Region.fromJson(Map<String, dynamic> json) {
    return Region(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      countryCode: json['country_code'] ?? 'MY',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'country_code': countryCode,
      'is_active': isActive,
    };
  }
}
