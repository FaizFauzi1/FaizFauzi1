import 'package:equatable/equatable.dart';

enum SearchType { vendor, service, location, category }

class SearchHistory extends Equatable {
  final String id;
  final String? userId;
  final String searchQuery;
  final SearchType searchType;
  final Map<String, dynamic>? filters;
  final int resultsCount;
  final DateTime createdAt;

  const SearchHistory({
    required this.id,
    this.userId,
    required this.searchQuery,
    required this.searchType,
    this.filters,
    this.resultsCount = 0,
    required this.createdAt,
  });

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      searchQuery: json['search_query'] as String,
      searchType: SearchType.values.firstWhere(
        (type) => type.name == json['search_type'],
        orElse: () => SearchType.vendor,
      ),
      filters: json['filters'] as Map<String, dynamic>?,
      resultsCount: json['results_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'search_query': searchQuery,
      'search_type': searchType.name,
      'filters': filters,
      'results_count': resultsCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  SearchHistory copyWith({
    String? id,
    String? userId,
    String? searchQuery,
    SearchType? searchType,
    Map<String, dynamic>? filters,
    int? resultsCount,
    DateTime? createdAt,
  }) {
    return SearchHistory(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      searchQuery: searchQuery ?? this.searchQuery,
      searchType: searchType ?? this.searchType,
      filters: filters ?? this.filters,
      resultsCount: resultsCount ?? this.resultsCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        searchQuery,
        searchType,
        filters,
        resultsCount,
        createdAt,
      ];
}
