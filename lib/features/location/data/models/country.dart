class Country {
  final String id;
  final String name;
  final String code;
  final bool isActive;

  const Country({
    required this.id,
    required this.name,
    required this.code,
    this.isActive = true,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    return Country(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'is_active': isActive,
      };
}
