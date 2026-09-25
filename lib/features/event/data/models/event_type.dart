import 'package:flutter/material.dart';

enum EventType {
  // Social Events
  wedding('wedding', 'Wedding', Icons.favorite, 'social', '#E91E63'),
  engagement('engagement', 'Engagement', Icons.favorite_border, 'social', '#F06292'),
  birthday('birthday', 'Birthday Party', Icons.cake, 'social', '#FF9800'),
  anniversary('anniversary', 'Anniversary', Icons.celebration, 'social', '#9C27B0'),
  babyShower('baby_shower', 'Baby Shower', Icons.child_care, 'social', '#81C784'),
  
  // Corporate Events
  corporate('corporate', 'Corporate Event', Icons.business, 'corporate', '#2196F3'),
  conference('conference', 'Conference', Icons.groups, 'corporate', '#1976D2'),
  productLaunch('product_launch', 'Product Launch', Icons.rocket_launch, 'corporate', '#00BCD4'),
  
  // Community Events
  expo('expo', 'Expo / Fair', Icons.store, 'community', '#4CAF50'),
  festival('festival', 'Festival', Icons.festival, 'community', '#FF5722'),
  charity('charity', 'Charity Event', Icons.volunteer_activism, 'community', '#E91E63'),
  sports('sports', 'Sports Event', Icons.sports, 'community', '#FF9800'),
  
  // Cultural & Educational
  religious('religious', 'Religious Event', Icons.mosque, 'cultural', '#009688'),
  graduation('graduation', 'Graduation', Icons.school, 'educational', '#3F51B5'),
  
  // Memorial
  funeral('funeral', 'Funeral', Icons.local_florist, 'memorial', '#757575'),
  
  // Fallback
  party('party', 'Party', Icons.party_mode, 'social', '#FF9800'),
  seminar('seminar', 'Seminar', Icons.school, 'educational', '#3F51B5'),
  retirement('retirement', 'Retirement', Icons.emoji_events, 'social', '#9C27B0'),
  other('other', 'Other', Icons.more_horiz, 'other', '#9E9E9E');

  const EventType(this.id, this.displayName, this.icon, this.categoryGroup, this.colorHex);

  final String id;
  final String displayName;
  final IconData icon;
  final String categoryGroup;
  final String colorHex;

  Color get color {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.blue;
    }
  }

  static EventType fromId(String id) {
    return EventType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => EventType.other,
    );
  }

  static List<EventType> getByCategoryGroup(String group) {
    return EventType.values.where((e) => e.categoryGroup == group).toList();
  }

  static List<EventType> getSocialEvents() {
    return getByCategoryGroup('social');
  }

  static List<EventType> getCorporateEvents() {
    return getByCategoryGroup('corporate');
  }

  static List<EventType> getCommunityEvents() {
    return getByCategoryGroup('community');
  }
}
