enum IncidentType { booth, technical, crowdControl }

enum IncidentStatus { open, inProgress, resolved }

enum IncidentPriority { low, medium, high, critical }

class ExpoIncident {
  final String id;
  final IncidentType type;
  final String title;
  final String description;
  final String location;
  final IncidentStatus status;
  final IncidentPriority priority;
  final String reportedBy;
  final DateTime reportedAt;
  final String? assignedStaff;

  static IncidentType typeFromDb(String? value) {
    return switch (value) {
      'technical' => IncidentType.technical,
      'crowd_control' => IncidentType.crowdControl,
      _ => IncidentType.booth,
    };
  }

  static IncidentStatus statusFromDb(String? value) {
    return switch (value) {
      'in_progress' => IncidentStatus.inProgress,
      'resolved' => IncidentStatus.resolved,
      _ => IncidentStatus.open,
    };
  }

  static IncidentPriority priorityFromDb(String? value) {
    return switch (value) {
      'critical' => IncidentPriority.critical,
      'high' => IncidentPriority.high,
      'low' => IncidentPriority.low,
      _ => IncidentPriority.medium,
    };
  }

  factory ExpoIncident.fromRow(Map<String, dynamic> row) {
    final staff = row['staff'] as Map<String, dynamic>?;
    return ExpoIncident(
      id: row['id'] as String,
      type: typeFromDb(row['incident_type'] as String?),
      title: row['title'] as String,
      description: (row['description'] as String?) ?? '',
      location: (row['location'] as String?) ?? '—',
      status: statusFromDb(row['status'] as String?),
      priority: priorityFromDb(row['priority'] as String?),
      reportedBy: (row['reported_by'] as String?) ?? 'Staff',
      reportedAt: DateTime.parse((row['reported_at'] ?? row['created_at']) as String),
      assignedStaff: staff?['full_name'] as String?,
    );
  }

  const ExpoIncident({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.location,
    required this.status,
    required this.priority,
    required this.reportedBy,
    required this.reportedAt,
    this.assignedStaff,
  });

  static List<ExpoIncident> sampleData() {
    final now = DateTime.now();
    return [
      ExpoIncident(
        id: 'inc1',
        type: IncidentType.booth,
        title: 'Power outage at booth A-03',
        description: 'Photography booth lost power. Extension cord needed.',
        location: 'Zone A · A-03',
        status: IncidentStatus.inProgress,
        priority: IncidentPriority.high,
        reportedBy: 'Sarah Wong (LensArt)',
        reportedAt: now.subtract(const Duration(minutes: 18)),
        assignedStaff: 'Tech Team · Ali',
      ),
      ExpoIncident(
        id: 'inc2',
        type: IncidentType.crowdControl,
        title: 'Queue overflow at registration',
        description: 'Main entrance queue exceeding capacity.',
        location: 'Hall 1 Entrance',
        status: IncidentStatus.open,
        priority: IncidentPriority.medium,
        reportedBy: 'Registration Lead',
        reportedAt: now.subtract(const Duration(minutes: 8)),
      ),
      ExpoIncident(
        id: 'inc3',
        type: IncidentType.technical,
        title: 'WiFi down in VIP lounge',
        description: 'Lead capture tablets offline.',
        location: 'VIP Lounge',
        status: IncidentStatus.resolved,
        priority: IncidentPriority.low,
        reportedBy: 'Staff · Mei',
        reportedAt: now.subtract(const Duration(hours: 1)),
        assignedStaff: 'IT · Kumar',
      ),
    ];
  }
}

enum TimelineItemStatus { upcoming, live, completed }

class ExpoTimelineItem {
  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final String location;
  final TimelineItemStatus status;

  static TimelineItemStatus timelineStatusFromDb(String? value) {
    return switch (value) {
      'live' => TimelineItemStatus.live,
      'completed' => TimelineItemStatus.completed,
      'cancelled' => TimelineItemStatus.completed,
      _ => TimelineItemStatus.upcoming,
    };
  }

  factory ExpoTimelineItem.fromRow(Map<String, dynamic> row) {
    return ExpoTimelineItem(
      id: row['id'] as String,
      title: row['title'] as String,
      startAt: DateTime.parse(row['start_at'] as String),
      endAt: DateTime.parse(row['end_at'] as String),
      location: (row['location'] as String?) ?? '—',
      status: timelineStatusFromDb(row['status'] as String?),
    );
  }

  const ExpoTimelineItem({
    required this.id,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.location,
    required this.status,
  });

  static List<ExpoTimelineItem> sampleData() {
    final now = DateTime.now();
    return [
      ExpoTimelineItem(
        id: 'tl1',
        title: 'Doors open · General admission',
        startAt: now.subtract(const Duration(hours: 2)),
        endAt: now.add(const Duration(hours: 6)),
        location: 'Main Hall',
        status: TimelineItemStatus.live,
      ),
      ExpoTimelineItem(
        id: 'tl2',
        title: 'Bridal fashion show',
        startAt: now.add(const Duration(minutes: 45)),
        endAt: now.add(const Duration(hours: 1, minutes: 15)),
        location: 'Central Stage',
        status: TimelineItemStatus.upcoming,
      ),
      ExpoTimelineItem(
        id: 'tl3',
        title: 'VIP lounge cocktail hour',
        startAt: now.subtract(const Duration(minutes: 30)),
        endAt: now.add(const Duration(hours: 1, minutes: 30)),
        location: 'VIP Lounge',
        status: TimelineItemStatus.live,
      ),
      ExpoTimelineItem(
        id: 'tl4',
        title: 'Opening ceremony',
        startAt: now.subtract(const Duration(hours: 2, minutes: 30)),
        endAt: now.subtract(const Duration(hours: 2)),
        location: 'Central Stage',
        status: TimelineItemStatus.completed,
      ),
      ExpoTimelineItem(
        id: 'tl5',
        title: 'Prize draw & closing',
        startAt: now.add(const Duration(hours: 5)),
        endAt: now.add(const Duration(hours: 5, minutes: 30)),
        location: 'Central Stage',
        status: TimelineItemStatus.upcoming,
      ),
    ];
  }
}

class LiveBoothActivity {
  final String boothNumber;
  final String vendorName;
  final int leadsToday;
  final bool isActive;
  final String statusNote;

  const LiveBoothActivity({
    required this.boothNumber,
    required this.vendorName,
    required this.leadsToday,
    required this.isActive,
    required this.statusNote,
  });

  static List<LiveBoothActivity> sampleData() => const [
        LiveBoothActivity(boothNumber: 'A-01', vendorName: 'Glam Bridal Studio', leadsToday: 24, isActive: true, statusNote: 'Busy'),
        LiveBoothActivity(boothNumber: 'A-02', vendorName: 'Royal Catering Co', leadsToday: 31, isActive: true, statusNote: 'Tastings ongoing'),
        LiveBoothActivity(boothNumber: 'A-03', vendorName: 'LensArt Photography', leadsToday: 8, isActive: false, statusNote: 'Power issue'),
        LiveBoothActivity(boothNumber: 'VIP-01', vendorName: 'Grand Ballroom Décor', leadsToday: 18, isActive: true, statusNote: 'VIP demos'),
      ];
}

class EmergencyAlert {
  final String id;
  final String message;
  final DateTime sentAt;
  final List<String> recipientGroups;
  final bool acknowledged;

  factory EmergencyAlert.fromRow(Map<String, dynamic> row) {
    final groups = row['recipient_groups'];
    return EmergencyAlert(
      id: row['id'] as String,
      message: row['message'] as String,
      sentAt: DateTime.parse((row['sent_at'] ?? row['created_at']) as String),
      recipientGroups: groups is List ? groups.map((e) => '$e').toList() : const [],
      acknowledged: row['acknowledged'] as bool? ?? false,
    );
  }

  const EmergencyAlert({
    required this.id,
    required this.message,
    required this.sentAt,
    required this.recipientGroups,
    required this.acknowledged,
  });

  static List<EmergencyAlert> sampleHistory() {
    final now = DateTime.now();
    return [
      EmergencyAlert(
        id: 'ea1',
        message: 'Registration queue backup — redirect to Side Entrance B',
        sentAt: now.subtract(const Duration(minutes: 12)),
        recipientGroups: ['Registration team', 'Crowd control'],
        acknowledged: true,
      ),
    ];
  }
}

class LiveExpoStats {
  final int visitorsNow;
  final int activeBooths;
  final int hourlyRate;
  final int leadsToday;

  const LiveExpoStats({
    required this.visitorsNow,
    required this.activeBooths,
    required this.hourlyRate,
    required this.leadsToday,
  });
}
