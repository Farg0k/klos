import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../entity/app_settings.dart';
import '../../../l10n/l10n.dart';
import '../../../opds/opds_client.dart';
import '../../../opds/opds_feed.dart';
import '../../../opds/opensearch.dart';

part 'catalog_event.dart';
part 'catalog_state.dart';

/// Loads an OPDS feed in the app, independent of the local HTTP server.
typedef FeedLoader = Future<OpdsFeed> Function(Uri url, AppSettings settings);

/// Resolves the OpenSearch URL template for [feed], or null when it cannot.
typedef SearchTemplateLoader = Future<String?> Function(
  OpdsFeed feed,
  AppSettings settings,
);

/// Reads the catalog for the in-app browser.
///
/// Navigation into a subcatalog opens another screen, so this bloc only has to
/// page forward and back inside one feed. Search results open as another page
/// in the same history.
class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  CatalogBloc({
    required this.settings,
    required this.initialUrl,
    FeedLoader? loader,
    SearchTemplateLoader? searchTemplateLoader,
  }) : _loader = loader ?? _loadFeed,
       _templateLoader = searchTemplateLoader ?? _loadSearchTemplate,
       super(CatalogState.initial()) {
    on<CatalogStarted>(_onStarted);
    on<CatalogReloadRequested>(_onReload);
    on<CatalogSearchRequested>(_onSearch);
    on<CatalogNextRequested>(_onNext);
    on<CatalogPreviousRequested>(_onPrevious);
  }

  final AppSettings settings;
  final Uri initialUrl;
  final FeedLoader _loader;
  final SearchTemplateLoader _templateLoader;

  /// Feeds loaded in this screen, current page last.
  final List<_Page> _history = [];

  Future<void> _onStarted(
    CatalogStarted event,
    Emitter<CatalogState> emit,
  ) async {
    await _load(initialUrl, emit);
  }

  Future<void> _onReload(
    CatalogReloadRequested event,
    Emitter<CatalogState> emit,
  ) async {
    final url = state.feed?.url ?? initialUrl;
    await _load(url, emit, replace: true, query: state.query);
  }

  Future<void> _onNext(
    CatalogNextRequested event,
    Emitter<CatalogState> emit,
  ) async {
    final next = state.feed?.nextPage;
    if (next == null) return;
    await _load(next, emit, query: state.query);
  }

  /// Runs an OpenSearch query against the current feed.
  ///
  /// The results become a new page in the history, so «Back» returns to the
  /// feed the query was made from.
  Future<void> _onSearch(
    CatalogSearchRequested event,
    Emitter<CatalogState> emit,
  ) async {
    final feed = state.feed;
    final query = event.query.trim();
    if (feed == null || query.isEmpty) return;

    emit(state.copyWith(status: CatalogStatus.loading, clearError: true));
    String? template;
    try {
      template = await _templateLoader(feed, settings);
    } catch (_) {
      template = null;
    }

    final target = template == null ? null : buildSearchUrl(template, query);
    if (target == null) {
      emit(
        state.copyWith(
          status: CatalogStatus.failure,
          error: l10n.searchUrlFailed,
        ),
      );
      return;
    }
    await _load(target, emit, query: query);
  }

  void _onPrevious(CatalogPreviousRequested event, Emitter<CatalogState> emit) {
    if (_history.length < 2) return;
    _history.removeLast();
    final page = _history.last;
    emit(
      CatalogState(
        status: CatalogStatus.ready,
        feed: page.feed,
        query: page.query,
        canGoPrevious: _history.length > 1,
      ),
    );
  }

  Future<void> _load(
    Uri url,
    Emitter<CatalogState> emit, {
    bool replace = false,
    String? query,
  }) async {
    emit(state.copyWith(status: CatalogStatus.loading, clearError: true));
    try {
      final feed = await _loader(url, settings);
      final page = _Page(feed, query);
      if (replace && _history.isNotEmpty) {
        _history[_history.length - 1] = page;
      } else {
        _history.add(page);
      }
      emit(
        CatalogState(
          status: CatalogStatus.ready,
          feed: feed,
          canGoPrevious: _history.length > 1,
          query: query,
        ),
      );
    } on OpdsException catch (error) {
      emit(state.copyWith(status: CatalogStatus.failure, error: error.message));
    } catch (error) {
      emit(state.copyWith(status: CatalogStatus.failure, error: '$error'));
    }
  }

  static Future<OpdsFeed> _loadFeed(Uri url, AppSettings settings) async {
    final client = OpdsClient(
      username: settings.username,
      password: settings.password,
    );
    try {
      return await client.fetchFeed(url);
    } finally {
      client.close();
    }
  }

  /// Reads the search template, following the OpenSearch description link when
  /// the feed does not declare a template directly.
  static Future<String?> _loadSearchTemplate(
    OpdsFeed feed,
    AppSettings settings,
  ) async {
    if (feed.searchTemplate != null) return feed.searchTemplate;

    final description = feed.searchDescription;
    if (description == null) return null;

    final client = OpdsClient(
      username: settings.username,
      password: settings.password,
    );
    try {
      final text = await client.fetchText(description);
      return parseSearchDescription(text.body, text.url);
    } finally {
      client.close();
    }
  }
}

/// One loaded feed and the query that produced it, kept for the back button.
class _Page {
  const _Page(this.feed, this.query);

  final OpdsFeed feed;
  final String? query;
}
