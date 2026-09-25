import 'package:flutter/material.dart';

enum EventCategory {
  catering('catering', 'Catering', Icons.restaurant),
  photography('photography', 'Photography', Icons.camera_alt),
  videography('videography', 'Videography', Icons.videocam),
  venue('venue', 'Venue', Icons.location_city),
  decoration('decoration', 'Decoration', Icons.celebration),
  entertainment('entertainment', 'Entertainment', Icons.music_note),
  emcee('emcee', 'Emcee / Host', Icons.mic),
  coordinator('coordinator', 'Event Coordinator', Icons.people),
  transportation('transportation', 'Transportation', Icons.directions_car),
  equipment('equipment', 'Equipment', Icons.build),
  planning('planning', 'Planning', Icons.event_note),
  beauty('beauty', 'Beauty', Icons.face),
  makeupArtist('makeup-artist', 'Makeup Artist', Icons.face),
  hennaArtist('henna-artist', 'Henna Artist', Icons.brush),
  fashion('fashion', 'Fashion', Icons.checkroom),
  accommodation('accommodation', 'Accommodation', Icons.hotel),
  doorgift('doorgift', 'Door Gift', Icons.redeem),
  package('package', 'All-in Package', Icons.card_giftcard),
  other('other', 'Other', Icons.category);

  const EventCategory(this.id, this.displayName, this.icon);

  final String id;
  final String displayName;
  final IconData icon;

  static EventCategory fromId(String id) {
    // Normalize the input for better matching
    final normalizedId = id.toLowerCase().trim();
    
    // Try exact match first
    final exactMatch = EventCategory.values.firstWhere(
      (category) => category.id == normalizedId,
      orElse: () => EventCategory.other,
    );
    
    if (exactMatch != EventCategory.other || normalizedId == 'other') {
      return exactMatch;
    }
    
    // Try display name match (case-insensitive)
    final displayMatch = EventCategory.values.firstWhere(
      (category) => category.displayName.toLowerCase() == normalizedId,
      orElse: () => EventCategory.other,
    );
    
    if (displayMatch != EventCategory.other) {
      return displayMatch;
    }
    
    // Try partial matches for common variations
    if (normalizedId.contains('emcee') || normalizedId.contains('host') || normalizedId.contains('mc')) {
      return EventCategory.emcee;
    }
    if (normalizedId.contains('video')) {
      return EventCategory.videography;
    }
    if (normalizedId.contains('photo') && !normalizedId.contains('booth')) {
      return EventCategory.photography;
    }
    if (normalizedId.contains('coordinator') || normalizedId.contains('planner')) {
      return EventCategory.coordinator;
    }
    if (normalizedId.contains('henna') || normalizedId.contains('inai')) {
      return EventCategory.hennaArtist;
    }
    if (normalizedId.contains('makeup') || normalizedId.contains('mua')) {
      return EventCategory.makeupArtist;
    }
    
    // Log warning for unmatched categories
    print('WARNING: No EventCategory match found for "$id", defaulting to other');
    return EventCategory.other; // Default fallback
  }

  List<String> get subcategories {
    switch (this) {
      case EventCategory.catering:
        return ['Wedding Catering', 'Corporate Catering', 'Party Catering', 'Fine Dining', 'Buffet Service'];
      case EventCategory.photography:
        return ['Wedding Photography', 'Event Photography', 'Portrait Photography', 'Commercial Photography', 'Drone Photography'];
      case EventCategory.videography:
        return ['Wedding Videography', 'Event Videography', 'Corporate Videography', 'Drone Videography', 'Cinematic Video'];
      case EventCategory.venue:
        return ['Ballroom', 'Garden', 'Beach', 'Hotel', 'Convention Center', 'Restaurant'];
      case EventCategory.decoration:
        return ['Floral Decoration', 'Lighting Decoration', 'Theme Decoration', 'Balloon Decoration', 'Table Decoration'];
      case EventCategory.entertainment:
        return ['Live Band', 'DJ', 'Dancers', 'Magicians', 'Photo Booth', 'Karaoke'];
      case EventCategory.emcee:
        return ['Wedding Emcee', 'Corporate Emcee', 'Bilingual Host', 'Event Host', 'Master of Ceremonies'];
      case EventCategory.coordinator:
        return ['Wedding Coordinator', 'Event Coordinator', 'Day-of Coordinator', 'Corporate Event Manager', 'Party Coordinator'];
      case EventCategory.transportation:
        return ['Limousine', 'Party Bus', 'Vintage Car', 'Luxury Van', 'Motorcycle Escort'];
      case EventCategory.equipment:
        return ['Sound System', 'Lighting Equipment', 'AV Equipment', 'Furniture Rental', 'Tent Rental'];
      case EventCategory.beauty:
      case EventCategory.makeupArtist:
      case EventCategory.hennaArtist:
        return ['Bridal Makeup', 'Hair Styling', 'Spa Services', 'Nail Services', 'Skincare', 'Henna / Inai Art'];
      case EventCategory.fashion:
        return ['Dress Rental', 'Suit Rental', 'Accessories', 'Shoes', 'Jewelry'];
      case EventCategory.accommodation:
        return ['Hotel Booking', 'Resort Booking', 'Villa Rental', 'Apartment Rental', 'Guest House'];
      case EventCategory.doorgift:
        return ['Wedding Favors', 'Corporate Gifts', 'Personalized Items', 'Edible Gifts', 'Handmade Gifts'];
      case EventCategory.package:
        return ['Wedding Package', 'Corporate Package', 'Birthday Package', 'Anniversary Package', 'Custom Package', 'Graduation Package', 'Engagement Package', 'Retirement Package', 'Reunion Package', 'Bridal Shower Package'];
      case EventCategory.planning:
        return ['Event Planning', 'Wedding Planning', 'Corporate Planning', 'Party Planning', 'Destination Planning'];
      case EventCategory.other:
        return ['General Service', 'Other'];
    }
  }
}
