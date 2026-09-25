import 'package:equatable/equatable.dart';

class SearchAnalytics extends Equatable {
  final String id;
  final String? userId;
  final String searchQuery;
  final String? location;
  final String? category;
  final int guestCount;
  final DateTime dateRangeStart;
  final DateTime? dateRangeEnd;
  final int resultsCount;
  final List<String> clickedServiceIds;
  final Map<String, dynamic> filters;
  final DateTime createdAt;

  const SearchAnalytics({
    required this.id,
    this.userId,
    required this.searchQuery,
    this.location,
    this.category,
    required this.guestCount,
    required this.dateRangeStart,
    this.dateRangeEnd,
    required this.resultsCount,
    required this.clickedServiceIds,
    required this.filters,
    required this.createdAt,
  });

  factory SearchAnalytics.fromJson(Map<String, dynamic> json) {
    return SearchAnalytics(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      searchQuery: json['search_query'] as String,
      location: json['location'] as String?,
      category: json['category'] as String?,
      guestCount: json['guest_count'] ?? 0,
      dateRangeStart: DateTime.parse(json['date_range_start']),
      dateRangeEnd: json['date_range_end'] != null
          ? DateTime.parse(json['date_range_end'])
          : null,
      resultsCount: json['results_count'] ?? 0,
      clickedServiceIds: List<String>.from(json['clicked_service_ids'] ?? []),
      filters: Map<String, dynamic>.from(json['filters'] ?? {}),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'search_query': searchQuery,
      'location': location,
      'category': category,
      'guest_count': guestCount,
      'date_range_start': dateRangeStart.toIso8601String(),
      'date_range_end': dateRangeEnd?.toIso8601String(),
      'results_count': resultsCount,
      'clicked_service_ids': clickedServiceIds,
      'filters': filters,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SearchAnalytics copyWith({
    String? id,
    String? userId,
    String? searchQuery,
    String? location,
    String? category,
    int? guestCount,
    DateTime? dateRangeStart,
    DateTime? dateRangeEnd,
    int? resultsCount,
    List<String>? clickedServiceIds,
    Map<String, dynamic>? filters,
    DateTime? createdAt,
  }) {
    return SearchAnalytics(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      searchQuery: searchQuery ?? this.searchQuery,
      location: location ?? this.location,
      category: category ?? this.category,
      guestCount: guestCount ?? this.guestCount,
      dateRangeStart: dateRangeStart ?? this.dateRangeStart,
      dateRangeEnd: dateRangeEnd ?? this.dateRangeEnd,
      resultsCount: resultsCount ?? this.resultsCount,
      clickedServiceIds: clickedServiceIds ?? this.clickedServiceIds,
      filters: filters ?? this.filters,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        searchQuery,
        location,
        category,
        guestCount,
        dateRangeStart,
        dateRangeEnd,
        resultsCount,
        clickedServiceIds,
        filters,
        createdAt,
      ];
}
