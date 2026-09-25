import 'dart:convert';
import 'package:flutter/material.dart';

/// Represents a single milestone in the pre-wedding preparation timeline.
/// e.g. "3 months before – Food Tasting"
class WeddingPrepMilestone {
  final String id;
  final int weeksBeforeEvent; // e.g. 12 = 3 months, 8 = 2 months
  final String title;
  final String description;
  final String iconName; // stored as string for serialization
  final bool isVendorResponsibility; // true = vendor handles, false = couple handles
  bool isEnabled; // vendor can toggle on/off

  WeddingPrepMilestone({
    required this.id,
    required this.weeksBeforeEvent,
    required this.title,
    required this.description,
    this.iconName = 'check_circle',
    this.isVendorResponsibility = false,
    this.isEnabled = true,
  });

  // Human-readable label e.g. "3 Months Before"
  String get timeLabel {
    if (weeksBeforeEvent >= 52) {
      final months = (weeksBeforeEvent / 4.33).round();
      final years = (months / 12).floor();
      return '$years Year${years > 1 ? 's' : ''} Before';
    }
    if (weeksBeforeEvent >= 8) {
      final months = (weeksBeforeEvent / 4.33).round();
      return '$months Month${months > 1 ? 's' : ''} Before';
    }
    if (weeksBeforeEvent >= 2) {
      return '$weeksBeforeEvent Weeks Before';
    }
    if (weeksBeforeEvent == 1) return '1 Week Before';
    return 'Day Before';
  }

  String get timeLabelShort {
    if (weeksBeforeEvent >= 8) {
      final months = (weeksBeforeEvent / 4.33).round();
      return '${months}M';
    }
    return '${weeksBeforeEvent}W';
  }

  IconData get iconData {
    switch (iconName) {
      case 'restaurant': return Icons.restaurant;
      case 'location_on': return Icons.location_on;
      case 'checkroom': return Icons.checkroom;
      case 'people': return Icons.people;
      case 'camera_alt': return Icons.camera_alt;
      case 'music_note': return Icons.music_note;
      case 'cake': return Icons.cake;
      case 'local_florist': return Icons.local_florist;
      case 'directions_car': return Icons.directions_car;
      case 'credit_card': return Icons.credit_card;
      case 'edit_note': return Icons.edit_note;
      case 'phone': return Icons.phone;
      case 'hotel': return Icons.hotel;
      case 'spa': return Icons.spa;
      case 'star': return Icons.star;
      case 'check_circle': return Icons.check_circle;
      default: return Icons.check_circle_outline;
    }
  }

  WeddingPrepMilestone copyWith({
    String? id,
    int? weeksBeforeEvent,
    String? title,
    String? description,
    String? iconName,
    bool? isVendorResponsibility,
    bool? isEnabled,
  }) {
    return WeddingPrepMilestone(
      id: id ?? this.id,
      weeksBeforeEvent: weeksBeforeEvent ?? this.weeksBeforeEvent,
      title: title ?? this.title,
      description: description ?? this.description,
      iconName: iconName ?? this.iconName,
      isVendorResponsibility: isVendorResponsibility ?? this.isVendorResponsibility,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'weeks_before_event': weeksBeforeEvent,
    'title': title,
    'description': description,
    'icon_name': iconName,
    'is_vendor_responsibility': isVendorResponsibility,
    'is_enabled': isEnabled,
  };

  factory WeddingPrepMilestone.fromJson(Map<String, dynamic> json) {
    return WeddingPrepMilestone(
      id: json['id'] ?? '',
      weeksBeforeEvent: (json['weeks_before_event'] as num?)?.toInt() ?? 4,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      iconName: json['icon_name'] ?? 'check_circle',
      isVendorResponsibility: json['is_vendor_responsibility'] ?? false,
      isEnabled: json['is_enabled'] ?? true,
    );
  }
}

/// Provides app-suggested pre-wedding preparation milestones for wedding packages.
class WeddingPrepTimeline {
  /// Returns the default suggested milestone list for a wedding package.
  static List<WeddingPrepMilestone> get suggested => weddingSuggested;

  static List<WeddingPrepMilestone> get weddingSuggested => [
    WeddingPrepMilestone(
      id: 'book_venue',
      weeksBeforeEvent: 52,
      title: 'Book Venue & Main Vendors',
      description: 'Confirm venue, caterer, photographer, and key vendors. Sign contracts and pay deposits.',
      iconName: 'location_on',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'food_tasting',
      weeksBeforeEvent: 13, // ~3 months
      title: 'Food Tasting Session',
      description: 'Attend food tasting with your partner to confirm menu. Select from available menu options.',
      iconName: 'restaurant',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'site_visit',
      weeksBeforeEvent: 12,
      title: 'Venue Site Visit',
      description: 'Walkthrough the venue to plan decoration layout, seating arrangement, and logistics.',
      iconName: 'location_on',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'suit_fitting',
      weeksBeforeEvent: 10, // ~2.5 months
      title: '1st Suit / Baju Fitting',
      description: 'First fitting session for groom\'s suit or baju pengantin. Measurements and style selection.',
      iconName: 'checkroom',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'dress_fitting_1',
      weeksBeforeEvent: 10,
      title: '1st Wedding Dress Fitting',
      description: 'Initial fitting for the bride\'s wedding dress or kebaya. Adjustments to be discussed.',
      iconName: 'checkroom',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'photography_meetup',
      weeksBeforeEvent: 9,
      title: 'Photography Pre-Meeting',
      description: 'Meet photographer to discuss shot list, angle preferences, timeline of the day, and key moments.',
      iconName: 'camera_alt',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'invitation_send',
      weeksBeforeEvent: 8, // 2 months
      title: 'Send Wedding Invitations',
      description: 'Send invitations to all guests. Ensure RSVP deadline is at least 3 weeks before the event.',
      iconName: 'edit_note',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'decoration_planning',
      weeksBeforeEvent: 8,
      title: 'Decoration Planning Meeting',
      description: 'Discuss floral arrangements, table centrepieces, backdrop design, colour theme, and props.',
      iconName: 'local_florist',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'suit_fitting_2',
      weeksBeforeEvent: 6, // 1.5 months
      title: 'Final Suit / Baju Fitting',
      description: 'Final fitting and approval. Ensure all alterations are complete and outfit is ready.',
      iconName: 'checkroom',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'headcount_confirm',
      weeksBeforeEvent: 4, // 1 month
      title: 'Confirm Final Headcount',
      description: 'Submit final confirmed guest count to caterer. Adjustments after this point may incur charges.',
      iconName: 'people',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'final_payment',
      weeksBeforeEvent: 3, // 3 weeks
      title: 'Final Payment Settlement',
      description: 'Settle remaining balance with all vendors. Collect receipts and confirm all bookings.',
      iconName: 'credit_card',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'makeup_trial',
      weeksBeforeEvent: 3,
      title: 'Hair & Makeup Trial',
      description: 'Trial run with makeup artist and hairstylist. Finalise look for the wedding day.',
      iconName: 'spa',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'vendor_call',
      weeksBeforeEvent: 1, // 1 week
      title: 'Final Vendor Check-In Call',
      description: 'Confirm arrival times, setup schedule, and final details with all vendors.',
      iconName: 'phone',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'rehearsal',
      weeksBeforeEvent: 1,
      title: 'Wedding Rehearsal',
      description: 'Run-through of ceremony sequence with family and wedding party.',
      iconName: 'star',
      isVendorResponsibility: false,
    ),
  ];

  static List<WeddingPrepMilestone> get corporateSuggested => [
    WeddingPrepMilestone(
      id: 'corp_venue_lock',
      weeksBeforeEvent: 16,
      title: 'Lock Venue & Event Dates',
      description: 'Sign venue contract, secure deposit, and establish primary contact personnel.',
      iconName: 'location_on',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'corp_speakers',
      weeksBeforeEvent: 12,
      title: 'Confirm Keynote Speakers & VIPs',
      description: 'Finalize speaker contracts, speech topics, and accommodation/travel arrangements.',
      iconName: 'people',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'corp_av_specs',
      weeksBeforeEvent: 10,
      title: 'AV & Technical Specs Review',
      description: 'Review sound systems, stage lighting, live-streaming setup, and presentation screens.',
      iconName: 'phone',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'corp_marketing',
      weeksBeforeEvent: 8,
      title: 'Launch Marketing & Registration',
      description: 'Publish landing page, ticketing, email campaigns, and promotional assets.',
      iconName: 'edit_note',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'corp_catering',
      weeksBeforeEvent: 6,
      title: 'Finalize Catering & Dietary Needs',
      description: 'Select coffee break menus, luncheon buffets, and accommodate special dietary requests.',
      iconName: 'restaurant',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'corp_badges',
      weeksBeforeEvent: 4,
      title: 'Badge & Pass Printing Prep',
      description: 'Prepare attendee badges, lanyard designs, and QR check-in terminal configs.',
      iconName: 'credit_card',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'corp_briefing',
      weeksBeforeEvent: 2,
      title: 'Run-of-Show & Stage Briefing',
      description: 'Detailed run-of-show review with emcee, stage manager, and technical team.',
      iconName: 'phone',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'corp_dry_run',
      weeksBeforeEvent: 1,
      title: 'Technical Rehearsal & Dry Run',
      description: 'Full audio/visual check, slide presentation testing, and stage walk-through.',
      iconName: 'star',
      isVendorResponsibility: true,
    ),
  ];

  static List<WeddingPrepMilestone> get partySuggested => [
    WeddingPrepMilestone(
      id: 'party_theme',
      weeksBeforeEvent: 8,
      title: 'Choose Party Theme & Venue',
      description: 'Decide party theme, guest count, and reserve venue or private hall.',
      iconName: 'location_on',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'party_invites',
      weeksBeforeEvent: 6,
      title: 'Send Invitations & Collect RSVPs',
      description: 'Send out digital/printed invitations with deadline for headcounts.',
      iconName: 'edit_note',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'party_cake',
      weeksBeforeEvent: 4,
      title: 'Order Custom Cake & Desserts',
      description: 'Select cake design, flavors, and confirm delivery time with baker.',
      iconName: 'cake',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'party_entertainment',
      weeksBeforeEvent: 3,
      title: 'Plan DJ, Games & Activities',
      description: 'Book DJ/musicians, curate music playlists, and prepare party games/props.',
      iconName: 'music_note',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'party_catering',
      weeksBeforeEvent: 2,
      title: 'Confirm Food & Beverage Order',
      description: 'Finalize finger food, buffet menu, drinks station, and tableware setup.',
      iconName: 'restaurant',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'party_decor',
      weeksBeforeEvent: 1,
      title: 'Finalize Decor & Backdrop Details',
      description: 'Confirm balloon arches, photo booth backdrop, lighting, and table centers.',
      iconName: 'local_florist',
      isVendorResponsibility: true,
    ),
  ];

  static List<WeddingPrepMilestone> get expoSuggested => [
    WeddingPrepMilestone(
      id: 'expo_permits',
      weeksBeforeEvent: 24,
      title: 'Secure Permits & Venue Contract',
      description: 'Obtain venue licensing, safety permits, and insurance policies for exhibition.',
      iconName: 'location_on',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'expo_floorplan',
      weeksBeforeEvent: 16,
      title: 'Finalize Floorplan & Booth Layout',
      description: 'Design hall map, booth dimensions, walkway clearances, and emergency exits.',
      iconName: 'edit_note',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'expo_reg',
      weeksBeforeEvent: 12,
      title: 'Open Exhibitor Registrations',
      description: 'Launch vendor booth sales, sponsorship packages, and exhibitor guidelines.',
      iconName: 'people',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'expo_crew',
      weeksBeforeEvent: 8,
      title: 'Contract Security, Medical & AV Crew',
      description: 'Hire security personnel, first aid staff, AV technicians, and cleaning team.',
      iconName: 'phone',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'expo_signage',
      weeksBeforeEvent: 4,
      title: 'Print Banners & Directional Signage',
      description: 'Print hall maps, welcome arches, booth numbers, and badge lanyards.',
      iconName: 'star',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'expo_loadin',
      weeksBeforeEvent: 2,
      title: 'Confirm Exhibitor Load-in Schedule',
      description: 'Issue load-in passes, power connection specs, and freight delivery slots.',
      iconName: 'directions_car',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'expo_briefing',
      weeksBeforeEvent: 1,
      title: 'Booth Setup & Crew Briefing',
      description: 'On-site booth setup inspection, sound check on main stage, and security briefing.',
      iconName: 'star',
      isVendorResponsibility: true,
    ),
  ];

  static List<WeddingPrepMilestone> get seminarSuggested => [
    WeddingPrepMilestone(
      id: 'sem_agenda',
      weeksBeforeEvent: 12,
      title: 'Define Agenda & Lock Trainers',
      description: 'Finalize course topics, learning objectives, and confirm lead instructor availability.',
      iconName: 'people',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'sem_registration',
      weeksBeforeEvent: 8,
      title: 'Open Registration & Course Link',
      description: 'Publish course syllabus, pricing tiers, and online attendee signups.',
      iconName: 'edit_note',
      isVendorResponsibility: false,
    ),
    WeddingPrepMilestone(
      id: 'sem_hall',
      weeksBeforeEvent: 4,
      title: 'Confirm Workshop Hall & Seating',
      description: 'Review classroom layout, projector placement, and power outlet availability.',
      iconName: 'location_on',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'sem_materials',
      weeksBeforeEvent: 3,
      title: 'Print Workbooks & Certificates',
      description: 'Print participant workbooks, name tags, slides, and completion certificates.',
      iconName: 'credit_card',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'sem_av',
      weeksBeforeEvent: 2,
      title: 'Test Projection & Microphones',
      description: 'Test presentation clickers, HDMI inputs, lapel mics, and recording system.',
      iconName: 'phone',
      isVendorResponsibility: true,
    ),
    WeddingPrepMilestone(
      id: 'sem_reminders',
      weeksBeforeEvent: 1,
      title: 'Send Attendee Info Packets',
      description: 'Dispatch parking guides, pre-reading materials, and arrival schedule.',
      iconName: 'edit_note',
      isVendorResponsibility: false,
    ),
  ];

  static Map<String, String> get eventTypeNames => {
    'wedding': 'Wedding',
    'corporate': 'Corporate Event / Conference',
    'party': 'Birthday & Social Party',
    'expo': 'Live Expo & Exhibition',
    'seminar': 'Seminar & Workshop',
  };

  static List<WeddingPrepMilestone> getSuggestedForEventType(String eventType) {
    switch (eventType.toLowerCase().trim()) {
      case 'corporate':
      case 'conference':
      case 'meeting':
        return corporateSuggested;
      case 'party':
      case 'birthday':
      case 'social':
      case 'anniversary':
        return partySuggested;
      case 'expo':
      case 'exhibition':
      case 'festival':
      case 'community':
        return expoSuggested;
      case 'seminar':
      case 'workshop':
      case 'educational':
      case 'training':
        return seminarSuggested;
      case 'wedding':
      case 'akad':
      case 'sanding':
      default:
        return weddingSuggested;
    }
  }

  static List<WeddingPrepMilestone> fromJsonList(dynamic data) {
    if (data == null) return [];
    try {
      List<dynamic> list;
      if (data is String) {
        list = jsonDecode(data) as List<dynamic>;
      } else if (data is List) {
        list = data;
      } else {
        return [];
      }
      return list.map((e) => WeddingPrepMilestone.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (_) {
      return [];
    }
  }

  static List<Map<String, dynamic>> toJsonList(List<WeddingPrepMilestone> items) {
    return items.map((e) => e.toJson()).toList();
  }

  /// Groups milestones by their approximate time label for UI display.
  static Map<String, List<WeddingPrepMilestone>> groupByTime(List<WeddingPrepMilestone> items) {
    final Map<String, List<WeddingPrepMilestone>> grouped = {};
    for (final item in items) {
      final label = item.timeLabel;
      grouped.putIfAbsent(label, () => []).add(item);
    }
    return grouped;
  }
}
