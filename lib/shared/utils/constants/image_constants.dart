import 'package:eventease/shared/models/event/event_category.dart';

class ImageConstants {
  // Category-based default placeholders
  static const String venuePlaceholder = 'https://images.unsplash.com/photo-1465101046530-73398c7f28ca?auto=format&fit=crop&q=80&w=800';
  static const String cateringPlaceholder = 'https://images.unsplash.com/photo-1555244162-803834f70033?auto=format&fit=crop&q=80&w=800';
  static const String photographyPlaceholder = 'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&q=80&w=800';
  static const String decorationPlaceholder = 'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?auto=format&fit=crop&q=80&w=800';
  static const String musicPlaceholder = 'https://images.unsplash.com/photo-1514320291840-2e0a9bf2a9ae?auto=format&fit=crop&q=80&w=800';
  static const String floristPlaceholder = 'https://images.unsplash.com/photo-1526047932273-341f2a7631f9?auto=format&fit=crop&q=80&w=800';
  static const String cakePlaceholder = 'https://images.unsplash.com/photo-1535141192574-5d4897c12636?auto=format&fit=crop&q=80&w=800';
  static const String beautyPlaceholder = 'https://images.unsplash.com/photo-1487412720507-e7ab37603c6f?auto=format&fit=crop&q=80&w=800';
  static const String fashionPlaceholder = 'https://images.unsplash.com/photo-1445205170230-053b83016050?auto=format&fit=crop&q=80&w=800';
  static const String plannerPlaceholder = 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&q=80&w=800';
  static const String avatarPlaceholder = 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=100&h=100';
  static const String defaultPlaceholder = 'https://images.unsplash.com/photo-1469334031218-e382a71b716b?auto=format&fit=crop&q=80&w=800';

  /// Returns a default image URL based on the event category.
  static String getDefaultImageUrl(EventCategory category) {
    switch (category) {
      case EventCategory.venue:
        return venuePlaceholder;
      case EventCategory.catering:
        return cateringPlaceholder;
      case EventCategory.photography:
      case EventCategory.videography:
        return photographyPlaceholder;
      case EventCategory.decoration:
        return decorationPlaceholder;
      case EventCategory.entertainment:
        return musicPlaceholder;
      case EventCategory.beauty:
        return beautyPlaceholder;
      case EventCategory.fashion:
        return fashionPlaceholder;
      case EventCategory.planning:
      case EventCategory.coordinator:
        return plannerPlaceholder;
      default:
        return defaultPlaceholder;
    }
  }

  /// Specialized method for Venues (which often have their own specific default).
  static String get defaultVenueImage => venuePlaceholder;
}
