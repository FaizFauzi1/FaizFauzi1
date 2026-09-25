enum GroupType {
  regional, // Regional groups (e.g., "Klang Valley Vendors")
  service, // Service-specific groups (e.g., "All DJs in Malaysia")
  business, // Business level groups (e.g., "Premium Vendors Only")
  event, // Event-specific groups (e.g., "Wedding Vendors")
  custom, // Custom user-created groups
}

enum GroupVisibility {
  public, // Anyone can see and join
  private, // Invite-only
  moderated, // Requires approval to join
}

class VendorGroup {
  final String id;
  final String name;
  final String description;
  final String createdBy; // Vendor ID who created the group
  final String creatorName;
  final GroupType type;
  final GroupVisibility visibility;
  final List<String> memberIds; // Vendor IDs who are members
  final List<String> adminIds; // Vendor IDs who are admins
  final List<String> pendingMemberIds; // Vendor IDs waiting for approval
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? coverImageUrl;
  final Map<String, dynamic> settings; // Group settings
  final List<String> tags; // Tags for categorization
  final int maxMembers; // Maximum number of members (0 = unlimited)

  const VendorGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.creatorName,
    required this.type,
    this.visibility = GroupVisibility.public,
    this.memberIds = const [],
    this.adminIds = const [],
    this.pendingMemberIds = const [],
    required this.createdAt,
    this.updatedAt,
    this.coverImageUrl,
    this.settings = const {},
    this.tags = const [],
    this.maxMembers = 0,
  });

  // Copy with method
  VendorGroup copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    String? creatorName,
    GroupType? type,
    GroupVisibility? visibility,
    List<String>? memberIds,
    List<String>? adminIds,
    List<String>? pendingMemberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverImageUrl,
    Map<String, dynamic>? settings,
    List<String>? tags,
    int? maxMembers,
  }) {
    return VendorGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      creatorName: creatorName ?? this.creatorName,
      type: type ?? this.type,
      visibility: visibility ?? this.visibility,
      memberIds: memberIds ?? this.memberIds,
      adminIds: adminIds ?? this.adminIds,
      pendingMemberIds: pendingMemberIds ?? this.pendingMemberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      settings: settings ?? this.settings,
      tags: tags ?? this.tags,
      maxMembers: maxMembers ?? this.maxMembers,
    );
  }

  // JSON serialization
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'creatorName': creatorName,
      'type': type.toString().split('.').last,
      'visibility': visibility.toString().split('.').last,
      'memberIds': memberIds,
      'adminIds': adminIds,
      'pendingMemberIds': pendingMemberIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'coverImageUrl': coverImageUrl,
      'settings': settings,
      'tags': tags,
      'maxMembers': maxMembers,
    };
  }

  factory VendorGroup.fromJson(Map<String, dynamic> json) {
    return VendorGroup(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      createdBy: json['createdBy'],
      creatorName: json['creatorName'],
      type: GroupType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
      ),
      visibility: GroupVisibility.values.firstWhere(
        (e) => e.toString().split('.').last == json['visibility'],
      ),
      memberIds: List<String>.from(json['memberIds'] ?? []),
      adminIds: List<String>.from(json['adminIds'] ?? []),
      pendingMemberIds: List<String>.from(json['pendingMemberIds'] ?? []),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      coverImageUrl: json['coverImageUrl'],
      settings: Map<String, dynamic>.from(json['settings'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      maxMembers: (json['maxMembers'] as num?)?.toInt() ?? 0,
    );
  }

  // Helper methods
  bool get isPublic => visibility == GroupVisibility.public;
  bool get isPrivate => visibility == GroupVisibility.private;
  bool get isModerated => visibility == GroupVisibility.moderated;

  bool get hasUnlimitedMembers => maxMembers == 0;
  bool get isFull => !hasUnlimitedMembers && memberIds.length >= maxMembers;

  String get typeDisplayName {
    switch (type) {
      case GroupType.regional:
        return 'Regional';
      case GroupType.service:
        return 'Service';
      case GroupType.business:
        return 'Business';
      case GroupType.event:
        return 'Event';
      case GroupType.custom:
        return 'Custom';
    }
  }

  String get visibilityDisplayName {
    switch (visibility) {
      case GroupVisibility.public:
        return 'Public';
      case GroupVisibility.private:
        return 'Private';
      case GroupVisibility.moderated:
        return 'Moderated';
    }
  }

  // Check if a vendor is a member
  bool isMember(String vendorId) {
    return memberIds.contains(vendorId);
  }

  // Check if a vendor is an admin
  bool isAdmin(String vendorId) {
    return adminIds.contains(vendorId);
  }

  // Check if a vendor is the creator
  bool isCreator(String vendorId) {
    return createdBy == vendorId;
  }

  // Check if a vendor has admin privileges (creator or admin)
  bool hasAdminPrivileges(String vendorId) {
    return isCreator(vendorId) || isAdmin(vendorId);
  }

  // Check if a vendor is pending approval
  bool isPendingMember(String vendorId) {
    return pendingMemberIds.contains(vendorId);
  }

  // Get total number of members
  int get totalMembers => memberIds.length;

  // Get total number of pending members
  int get totalPendingMembers => pendingMemberIds.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is VendorGroup &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.createdBy == createdBy &&
        other.creatorName == creatorName &&
        other.type == type &&
        other.visibility == visibility &&
        other.memberIds == memberIds &&
        other.adminIds == adminIds &&
        other.pendingMemberIds == pendingMemberIds &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.coverImageUrl == coverImageUrl &&
        other.settings == settings &&
        other.tags == tags &&
        other.maxMembers == maxMembers;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        description.hashCode ^
        createdBy.hashCode ^
        creatorName.hashCode ^
        type.hashCode ^
        visibility.hashCode ^
        memberIds.hashCode ^
        adminIds.hashCode ^
        pendingMemberIds.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        coverImageUrl.hashCode ^
        settings.hashCode ^
        tags.hashCode ^
        maxMembers.hashCode;
  }
}
