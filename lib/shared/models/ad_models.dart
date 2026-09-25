import 'package:equatable/equatable.dart';

enum AdType { banner, interstitial, native }

enum AdStatus { active, inactive, draft }

enum AdPlatform { android, ios, web }

class AdConfiguration extends Equatable {
  final String id;
  final String name;
  final String description;
  final AdType type;
  final AdStatus status;
  final AdPlatform platform;
  final String adUnitId;
  final String? imageUrl;
  final String? title;
  final String? subtitle;
  final String? callToAction;
  final String? targetUrl;
  final Map<String, dynamic> targeting;
  final DateTime? startDate;
  final DateTime? endDate;
  final int priority;
  final int maxImpressions;
  final int currentImpressions;
  final int maxClicks;
  final int currentClicks;
  final double cpm; // Cost per thousand impressions
  final double cpc; // Cost per click
  final bool isTestAd;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AdConfiguration({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.status,
    required this.platform,
    required this.adUnitId,
    this.imageUrl,
    this.title,
    this.subtitle,
    this.callToAction,
    this.targetUrl,
    this.targeting = const {},
    this.startDate,
    this.endDate,
    this.priority = 1,
    this.maxImpressions = -1, // -1 means unlimited
    this.currentImpressions = 0,
    this.maxClicks = -1, // -1 means unlimited
    this.currentClicks = 0,
    this.cpm = 0.0,
    this.cpc = 0.0,
    this.isTestAd = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AdConfiguration.fromMap(Map<String, dynamic> map) {
    return AdConfiguration(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: AdType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AdType.banner,
      ),
      status: AdStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AdStatus.draft,
      ),
      platform: AdPlatform.values.firstWhere(
        (e) => e.name == map['platform'],
        orElse: () => AdPlatform.android,
      ),
      adUnitId: map['adUnitId'] ?? '',
      imageUrl: map['imageUrl'],
      title: map['title'],
      subtitle: map['subtitle'],
      callToAction: map['callToAction'],
      targetUrl: map['targetUrl'],
      targeting: Map<String, dynamic>.from(map['targeting'] ?? {}),
      startDate: map['startDate'] != null ? DateTime.parse(map['startDate']) : null,
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate']) : null,
      priority: map['priority'] ?? 1,
      maxImpressions: map['maxImpressions'] ?? -1,
      currentImpressions: map['currentImpressions'] ?? 0,
      maxClicks: map['maxClicks'] ?? -1,
      currentClicks: map['currentClicks'] ?? 0,
      cpm: (map['cpm'] ?? 0).toDouble(),
      cpc: (map['cpc'] ?? 0).toDouble(),
      isTestAd: map['isTestAd'] ?? false,
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.name,
      'status': status.name,
      'platform': platform.name,
      'adUnitId': adUnitId,
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'callToAction': callToAction,
      'targetUrl': targetUrl,
      'targeting': targeting,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'priority': priority,
      'maxImpressions': maxImpressions,
      'currentImpressions': currentImpressions,
      'maxClicks': maxClicks,
      'currentClicks': currentClicks,
      'cpm': cpm,
      'cpc': cpc,
      'isTestAd': isTestAd,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AdConfiguration copyWith({
    String? id,
    String? name,
    String? description,
    AdType? type,
    AdStatus? status,
    AdPlatform? platform,
    String? adUnitId,
    String? imageUrl,
    String? title,
    String? subtitle,
    String? callToAction,
    String? targetUrl,
    Map<String, dynamic>? targeting,
    DateTime? startDate,
    DateTime? endDate,
    int? priority,
    int? maxImpressions,
    int? currentImpressions,
    int? maxClicks,
    int? currentClicks,
    double? cpm,
    double? cpc,
    bool? isTestAd,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdConfiguration(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      status: status ?? this.status,
      platform: platform ?? this.platform,
      adUnitId: adUnitId ?? this.adUnitId,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      callToAction: callToAction ?? this.callToAction,
      targetUrl: targetUrl ?? this.targetUrl,
      targeting: targeting ?? this.targeting,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      priority: priority ?? this.priority,
      maxImpressions: maxImpressions ?? this.maxImpressions,
      currentImpressions: currentImpressions ?? this.currentImpressions,
      maxClicks: maxClicks ?? this.maxClicks,
      currentClicks: currentClicks ?? this.currentClicks,
      cpm: cpm ?? this.cpm,
      cpc: cpc ?? this.cpc,
      isTestAd: isTestAd ?? this.isTestAd,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive {
    if (status != AdStatus.active) return false;
    if (startDate != null && DateTime.now().isBefore(startDate!)) return false;
    if (endDate != null && DateTime.now().isAfter(endDate!)) return false;
    if (maxImpressions > 0 && currentImpressions >= maxImpressions) return false;
    if (maxClicks > 0 && currentClicks >= maxClicks) return false;
    return true;
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        type,
        status,
        platform,
        adUnitId,
        imageUrl,
        title,
        subtitle,
        callToAction,
        targetUrl,
        targeting,
        startDate,
        endDate,
        priority,
        maxImpressions,
        currentImpressions,
        maxClicks,
        currentClicks,
        cpm,
        cpc,
        isTestAd,
        createdAt,
        updatedAt,
      ];
}

class AdPlacement {
  final String id;
  final String name;
  final String description;
  final AdType adType;
  final String screen;
  final String position;
  final List<String> adIds;
  final bool isEnabled;
  final int refreshInterval; // in seconds
  final Map<String, dynamic> targeting;

  const AdPlacement({
    required this.id,
    required this.name,
    required this.description,
    required this.adType,
    required this.screen,
    required this.position,
    required this.adIds,
    this.isEnabled = true,
    this.refreshInterval = 30,
    this.targeting = const {},
  });

  factory AdPlacement.fromMap(Map<String, dynamic> map) {
    return AdPlacement(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      adType: AdType.values.firstWhere(
        (e) => e.name == map['adType'],
        orElse: () => AdType.banner,
      ),
      screen: map['screen'] ?? '',
      position: map['position'] ?? '',
      adIds: List<String>.from(map['adIds'] ?? []),
      isEnabled: map['isEnabled'] ?? true,
      refreshInterval: map['refreshInterval'] ?? 30,
      targeting: Map<String, dynamic>.from(map['targeting'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'adType': adType.name,
      'screen': screen,
      'position': position,
      'adIds': adIds,
      'isEnabled': isEnabled,
      'refreshInterval': refreshInterval,
      'targeting': targeting,
    };
  }
}