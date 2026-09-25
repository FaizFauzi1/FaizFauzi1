/// Event type master data model
class EventType {
  final String code;
  final String displayName;
  final String? category; // 'wedding', 'corporate', 'social'
  final bool isActive;

  EventType({
    required this.code,
    required this.displayName,
    this.category,
    this.isActive = true,
  });

  factory EventType.fromJson(Map<String, dynamic> json) {
    return EventType(
      code: json['code'] ?? '',
      displayName: json['display_name'] ?? '',
      category: json['category'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'display_name': displayName,
      'category': category,
      'is_active': isActive,
    };
  }
}

/// Predefined event types for the platform
class PredefinedEventTypes {
  static final List<EventType> weddingEvents = [
    EventType(code: 'akad', displayName: 'Akad Nikah', category: 'wedding'),
    EventType(code: 'sanding', displayName: 'Persandingan', category: 'wedding'),
    EventType(code: 'bertandang', displayName: 'Bertandang', category: 'wedding'),
    EventType(code: 'engagement', displayName: 'Engagement', category: 'wedding'),
    EventType(code: 'henna', displayName: 'Henna Night', category: 'wedding'),
  ];

  static final List<EventType> corporateEvents = [
    EventType(code: 'corporate_meeting', displayName: 'Corporate Meeting', category: 'corporate'),
    EventType(code: 'conference', displayName: 'Conference', category: 'corporate'),
    EventType(code: 'seminar', displayName: 'Seminar', category: 'corporate'),
    EventType(code: 'product_launch', displayName: 'Product Launch', category: 'corporate'),
    EventType(code: 'team_building', displayName: 'Team Building', category: 'corporate'),
    EventType(code: 'annual_dinner', displayName: 'Annual Dinner', category: 'corporate'),
  ];

  static final List<EventType> socialEvents = [
    EventType(code: 'birthday', displayName: 'Birthday Party', category: 'social'),
    EventType(code: 'anniversary', displayName: 'Anniversary', category: 'social'),
    EventType(code: 'graduation', displayName: 'Graduation', category: 'social'),
    EventType(code: 'baby_shower', displayName: 'Baby Shower', category: 'social'),
    EventType(code: 'reunion', displayName: 'Reunion', category: 'social'),
    EventType(code: 'other', displayName: 'Other', category: 'social'),
  ];

  static List<EventType> getAllEventTypes() {
    return [
      ...weddingEvents,
      ...corporateEvents,
      ...socialEvents,
    ];
  }

  static List<EventType> getEventTypesByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'wedding':
        return weddingEvents;
      case 'corporate':
        return corporateEvents;
      case 'social':
        return socialEvents;
      default:
        return getAllEventTypes();
    }
  }
  static String getDisplayNameByCode(String code) {
    try {
      return getAllEventTypes().firstWhere((et) => et.code == code).displayName;
    } catch (_) {
      // If not found, capitalize the code and return it
      if (code.isEmpty) return 'Other';
      return code[0].toUpperCase() + code.substring(1).replaceAll('_', ' ');
    }
  }
}
