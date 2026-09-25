import 'package:eventease/features/budget/data/models/budget_category.dart';

enum EventTemplateType {
  blank,
  wedding,
  corporate,
  party,
}

class TemplateTimelineEvent {
  final String title;
  final String category;
  final int offsetDays; // relative offset in days from event date
  final String notes;

  const TemplateTimelineEvent({
    required this.title,
    required this.category,
    required this.offsetDays,
    this.notes = '',
  });
}

class EventTemplate {
  final EventTemplateType type;
  final String title;
  final String description;
  final List<String> defaultChecklistItems;
  final List<BudgetCategory> defaultBudgetCategories;
  final List<TemplateTimelineEvent> defaultTimelineEvents;

  const EventTemplate({
    required this.type,
    required this.title,
    required this.description,
    required this.defaultChecklistItems,
    required this.defaultBudgetCategories,
    this.defaultTimelineEvents = const [],
  });

  static List<EventTemplate> get availableTemplates => [
        _blankTemplate,
        _weddingTemplate,
        _corporateTemplate,
        _partyTemplate,
        _communityTemplate,
        _educationalTemplate,
      ];

  static final _blankTemplate = EventTemplate(
    type: EventTemplateType.blank,
    title: 'Blank (Custom)',
    description: 'Start from scratch. No predefined tools will be generated.',
    defaultChecklistItems: [],
    defaultBudgetCategories: [],
    defaultTimelineEvents: [],
  );

  static final _weddingTemplate = EventTemplate(
    type: EventTemplateType.wedding,
    title: 'Wedding Planner Suite',
    description: 'Includes a complete wedding checklist, budget categories, and run-of-show timeline.',
    defaultChecklistItems: [
      'Set the budget and draft the guest list',
      'Book a venue',
      'Hire a photographer & videographer',
      'Book a caterer and decide the menu',
      'Order the wedding cake',
      'Send save-the-dates or invitations',
      'Buy wedding attire',
      'Confirm RSVP numbers',
      'Finalize seating chart',
    ],
    defaultBudgetCategories: BudgetCategory.getDefaultCategories(),
    defaultTimelineEvents: const [
      TemplateTimelineEvent(title: 'Hair & Makeup Touchup', category: 'Beauty', offsetDays: 0, notes: 'Bridal suite preparation'),
      TemplateTimelineEvent(title: 'Photographer & Videographer Arrival', category: 'Photography', offsetDays: 0, notes: 'Capture detail shots & attire'),
      TemplateTimelineEvent(title: 'Guest Registration & Welcome Refreshments', category: 'Logistics', offsetDays: 0, notes: 'Welcome desk open'),
      TemplateTimelineEvent(title: 'Wedding Ceremony / Akad Nikah', category: 'Ceremony', offsetDays: 0, notes: 'Formal solemnization ceremony'),
      TemplateTimelineEvent(title: 'Grand Entrance & Wedding Banquet', category: 'Catering', offsetDays: 0, notes: 'Buffet / Plated dining service'),
      TemplateTimelineEvent(title: 'Cake Cutting & Speech Ceremony', category: 'Reception', offsetDays: 0, notes: 'Family speeches & photo moment'),
      TemplateTimelineEvent(title: 'Group Photo Session & Event Farewell', category: 'Photography', offsetDays: 0, notes: 'Guest photo sessions'),
    ],
  );

  static final _corporateTemplate = EventTemplate(
    type: EventTemplateType.corporate,
    title: 'Corporate Event / Conference',
    description: 'Pre-fills checklists, AV budget, and conference agenda timeline.',
    defaultChecklistItems: [
      'Define event goals and target audience',
      'Create event budget',
      'Secure venue and date',
      'Confirm keynote speakers and guests',
      'Plan AV and technical requirements',
      'Launch event marketing & ticket sales',
      'Arrange catering and refreshments',
      'Send out attendee info packets',
      'Prepare event badges and check-in desk',
    ],
    defaultBudgetCategories: [
      BudgetCategory(
        id: 'venue',
        name: 'Venue & Logistics',
        allocatedAmount: 0,
        color: '#FF6B6B',
        type: BudgetCategoryType.venue,
        isRequired: true,
      ),
      BudgetCategory(
        id: 'catering',
        name: 'Catering',
        allocatedAmount: 0,
        color: '#4ECDC4',
        type: BudgetCategoryType.catering,
        isRequired: true,
      ),
      BudgetCategory(
        id: 'tech_av',
        name: 'Technology & AV',
        allocatedAmount: 0,
        color: '#F7DC6F',
        type: BudgetCategoryType.stationery,
        isRequired: true,
      ),
      BudgetCategory(
        id: 'marketing',
        name: 'Marketing & PR',
        allocatedAmount: 0,
        color: '#BB8FCE',
        type: BudgetCategoryType.miscellaneous,
        isRequired: false,
      ),
      BudgetCategory(
        id: 'speakers',
        name: 'Speaker Fees & Travel',
        allocatedAmount: 0,
        color: '#45B7D1',
        type: BudgetCategoryType.transportation,
        isRequired: false,
      ),
    ],
    defaultTimelineEvents: const [
      TemplateTimelineEvent(title: 'AV System & Stage Tech Check', category: 'Technical', offsetDays: 0, notes: 'Microphone & projector test'),
      TemplateTimelineEvent(title: 'Attendee Badge Check-In & Welcome Coffee', category: 'Registration', offsetDays: 0, notes: 'QR scanner registration active'),
      TemplateTimelineEvent(title: 'Opening Keynote Address', category: 'Stage', offsetDays: 0, notes: 'Main hall welcome address'),
      TemplateTimelineEvent(title: 'Morning Networking Break', category: 'Catering', offsetDays: 0, notes: 'Coffee & pastries in foyer'),
      TemplateTimelineEvent(title: 'Panel Discussion & Audience Q&A', category: 'Program', offsetDays: 0, notes: 'Moderated panel session'),
      TemplateTimelineEvent(title: 'Executive Luncheon & Networking', category: 'Catering', offsetDays: 0, notes: 'Buffet dining hall open'),
      TemplateTimelineEvent(title: 'Afternoon Track Workshops', category: 'Program', offsetDays: 0, notes: 'Breakout room sessions'),
      TemplateTimelineEvent(title: 'Closing Remarks & Survey Collection', category: 'Stage', offsetDays: 0, notes: 'Wrap-up & attendee gift bags'),
    ],
  );

  static final _partyTemplate = EventTemplate(
    type: EventTemplateType.party,
    title: 'Party & Celebration',
    description: 'Simple checklists, party budget, and celebration day schedule.',
    defaultChecklistItems: [
      'Decide on a theme',
      'Create and send invites',
      'Plan the menu and drinks',
      'Order the cake or special dessert',
      'Buy party decorations',
      'Create a music playlist',
      'Arrange party games or entertainment',
    ],
    defaultBudgetCategories: [
      BudgetCategory(
        id: 'venue',
        name: 'Venue / Rental',
        allocatedAmount: 0,
        color: '#FF6B6B',
        type: BudgetCategoryType.venue,
        isRequired: false,
      ),
      BudgetCategory(
        id: 'food_drinks',
        name: 'Food & Drinks',
        allocatedAmount: 0,
        color: '#4ECDC4',
        type: BudgetCategoryType.catering,
        isRequired: true,
      ),
      BudgetCategory(
        id: 'decoration',
        name: 'Decorations',
        allocatedAmount: 0,
        color: '#FFA07A',
        type: BudgetCategoryType.decoration,
        isRequired: false,
      ),
      BudgetCategory(
        id: 'entertainment',
        name: 'Entertainment',
        allocatedAmount: 0,
        color: '#98D8C8',
        type: BudgetCategoryType.entertainment,
        isRequired: false,
      ),
    ],
    defaultTimelineEvents: const [
      TemplateTimelineEvent(title: 'Decorators & Balloon Setup Arrival', category: 'Decoration', offsetDays: 0, notes: 'Backdrop & table setup'),
      TemplateTimelineEvent(title: 'Sound System & Playlist Check', category: 'Entertainment', offsetDays: 0, notes: 'Music & microphone setup'),
      TemplateTimelineEvent(title: 'Cake & Dessert Table Arrangement', category: 'Catering', offsetDays: 0, notes: 'Cake delivery arrival'),
      TemplateTimelineEvent(title: 'Guest Arrival & Welcome Refreshments', category: 'Logistics', offsetDays: 0, notes: 'Welcome drinks'),
      TemplateTimelineEvent(title: 'Main Party Celebration & Toast', category: 'Program', offsetDays: 0, notes: 'Toast & group celebration'),
      TemplateTimelineEvent(title: 'Cake Cutting & Sing-along', category: 'Program', offsetDays: 0, notes: 'Special cake moment'),
      TemplateTimelineEvent(title: 'DJ Party Music & Interactive Games', category: 'Entertainment', offsetDays: 0, notes: 'Party games & dancing'),
    ],
  );

  static final _communityTemplate = EventTemplate(
    type: EventTemplateType.party,
    title: 'Community Festival / Expo',
    description: 'Checklists for large public events, vendor management, and expo timeline.',
    defaultChecklistItems: [
      'Define event committee and roles',
      'Obtain necessary permits and insurance',
      'Design event layout and site plan',
      'Open vendor registration and selection',
      'Develop event marketing and PR strategy',
      'Arrange volunteer training and scheduling',
      'Set up public health and safety protocols',
      'Plan waste management and cleanup',
    ],
    defaultBudgetCategories: [
      BudgetCategory(
        id: 'logistics',
        name: 'Site Logistics',
        allocatedAmount: 0,
        color: '#FF6B6B',
        type: BudgetCategoryType.venue,
        isRequired: true,
      ),
      BudgetCategory(
        id: 'permits',
        name: 'Permits & Licenses',
        allocatedAmount: 0,
        color: '#4ECDC4',
        type: BudgetCategoryType.miscellaneous,
        isRequired: true,
      ),
    ],
    defaultTimelineEvents: const [
      TemplateTimelineEvent(title: 'Exhibitor Booth Construction & Load-in', category: 'Logistics', offsetDays: -1, notes: 'Hall setup & booth distribution'),
      TemplateTimelineEvent(title: 'Security & First-Aid Crew Briefing', category: 'Operations', offsetDays: 0, notes: 'Safety protocols review'),
      TemplateTimelineEvent(title: 'Exhibitor Final Setup & Pass Check', category: 'Exhibitors', offsetDays: 0, notes: 'Booth power & display check'),
      TemplateTimelineEvent(title: 'Main Gates Open to Public', category: 'Operations', offsetDays: 0, notes: 'Ticketing & security gates active'),
      TemplateTimelineEvent(title: 'Official Opening Ceremony & Stage Performances', category: 'Stage', offsetDays: 0, notes: 'VIP welcome & cultural performances'),
      TemplateTimelineEvent(title: 'Vendor Recognition & Lucky Draw', category: 'Stage', offsetDays: 0, notes: 'Raffle draw on main stage'),
      TemplateTimelineEvent(title: 'Expo Closing & Hall Teardown', category: 'Operations', offsetDays: 0, notes: 'Exhibitor freight load-out'),
    ],
  );

  static final _educationalTemplate = EventTemplate(
    type: EventTemplateType.corporate,
    title: 'Educational Seminar / Graduation',
    description: 'Focus on curriculum planning, materials, certificates, and seminar agenda.',
    defaultChecklistItems: [
      'Finalize educational content or program',
      'Invite guest lecturers or keynote speakers',
      'Print resource materials and handouts',
      'Set up registration and attendee tracking',
      'Prepare certificates and awards',
    ],
    defaultBudgetCategories: [
      BudgetCategory(
        id: 'materials',
        name: 'Educational Materials',
        allocatedAmount: 0,
        color: '#BB8FCE',
        type: BudgetCategoryType.stationery,
        isRequired: true,
      ),
    ],
    defaultTimelineEvents: const [
      TemplateTimelineEvent(title: 'Registration Desk Open & Material Distribution', category: 'Registration', offsetDays: 0, notes: 'Distribute workbooks & badges'),
      TemplateTimelineEvent(title: 'Welcome Speech & Instructor Intro', category: 'Program', offsetDays: 0, notes: 'Opening address'),
      TemplateTimelineEvent(title: 'Morning Module Lecture', category: 'Education', offsetDays: 0, notes: 'First training section'),
      TemplateTimelineEvent(title: 'Tea Break & Discussion Q&A', category: 'Catering', offsetDays: 0, notes: 'Networking coffee break'),
      TemplateTimelineEvent(title: 'Practical Hands-on Workshop', category: 'Education', offsetDays: 0, notes: 'Group exercises'),
      TemplateTimelineEvent(title: 'Certificate Presentation & Group Photo', category: 'Stage', offsetDays: 0, notes: 'Graduation photo session'),
    ],
  );
}
