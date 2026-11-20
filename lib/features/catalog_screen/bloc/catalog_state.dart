part of 'catalog_bloc.dart';

enum CatalogStatus { initial, loading, ready, failure }

class CatalogState extends Equatable {
  const CatalogState({
    required this.status,
    this.feed,
    this.error,
    this.query,
    this.canGoPrevious = false,
  });

  factory CatalogState.initial() =>
      const CatalogState(status: CatalogStatus.initial);

  final CatalogStatus status;
  final OpdsFeed? feed;
  final String? error;

  /// Search query whose results are on screen, or null for a normal page.
  final String? query;

  /// Whether a previous page of this feed can be shown from history.
  final bool canGoPrevious;

  bool get isLoading => status == CatalogStatus.loading;

  /// Whether the current feed offers an OpenSearch template.
  bool get canSearch {
    final current = feed;
    if (current == null) return false;
    return current.searchTemplate != null || current.searchDescription != null;
  }

  CatalogState copyWith({
    CatalogStatus? status,
    OpdsFeed? feed,
    String? error,
    String? query,
    bool clearError = false,
    bool? canGoPrevious,
  }) {
    return CatalogState(
      status: status ?? this.status,
      feed: feed ?? this.feed,
      error: clearError ? null : (error ?? this.error),
      query: query ?? this.query,
      canGoPrevious: canGoPrevious ?? this.canGoPrevious,
    );
  }

  @override
  List<Object?> get props => [status, feed, error, query, canGoPrevious];
}
