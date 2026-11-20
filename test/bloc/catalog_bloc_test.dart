import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/entity/app_settings.dart';
import 'package:klos/features/catalog_screen/bloc/catalog_bloc.dart';
import 'package:klos/l10n/l10n.dart';
import 'package:klos/opds/opds_client.dart';
import 'package:klos/opds/opds_feed.dart';

final _root = Uri.parse('http://example.com/opds');
final _page2 = Uri.parse('http://example.com/opds?page=2');
const _searchTemplate = 'http://example.com/search?q={searchTerms}';

OpdsFeed _feed(Uri url, {Uri? next, String title = 'Catalog'}) {
  return OpdsFeed(
    url: url,
    title: title,
    entries: const [OpdsEntry(title: 'Book')],
    nextPage: next,
  );
}

CatalogBloc _bloc(
  FeedLoader loader, {
  SearchTemplateLoader? searchTemplateLoader,
}) {
  return CatalogBloc(
    settings: const AppSettings(catalogUrl: null),
    initialUrl: _root,
    loader: loader,
    searchTemplateLoader:
        searchTemplateLoader ?? (_, _) async => _searchTemplate,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await L10n.use(const Locale('uk'));
  });

  test('loads the first page', () async {
    final bloc = _bloc((url, _) async => _feed(url));
    addTearDown(bloc.close);

    final ready = bloc.stream.firstWhere(
      (state) => state.status == CatalogStatus.ready,
    );
    bloc.add(const CatalogStarted());
    final state = await ready;

    expect(state.feed?.url, _root);
    expect(state.feed?.entries.single.title, 'Book');
    expect(state.canGoPrevious, isFalse);
  });

  test('pages forward and back through the feed history', () async {
    final requested = <Uri>[];
    final bloc = _bloc((url, _) async {
      requested.add(url);
      return _feed(url, next: url == _root ? _page2 : null);
    });
    addTearDown(bloc.close);

    bloc.add(const CatalogStarted());
    await bloc.stream.firstWhere(
      (state) =>
          state.status == CatalogStatus.ready && state.feed?.url == _root,
    );

    bloc.add(const CatalogNextRequested());
    final second = await bloc.stream.firstWhere(
      (state) => state.feed?.url == _page2,
    );
    expect(second.canGoPrevious, isTrue);

    bloc.add(const CatalogPreviousRequested());
    final back = await bloc.stream.firstWhere(
      (state) => state.feed?.url == _root,
    );
    expect(back.canGoPrevious, isFalse);
    expect(requested, [_root, _page2]);
  });

  test('reloads the current page without growing the history', () async {
    var loads = 0;
    final bloc = _bloc((url, _) async {
      loads++;
      return _feed(url, title: 'Load $loads');
    });
    addTearDown(bloc.close);

    bloc.add(const CatalogStarted());
    await bloc.stream.firstWhere((state) => state.feed?.title == 'Load 1');

    bloc.add(const CatalogReloadRequested());
    final reloaded = await bloc.stream.firstWhere(
      (state) => state.feed?.title == 'Load 2',
    );

    expect(reloaded.canGoPrevious, isFalse);
    expect(loads, 2);
  });

  test('reports a catalog error with the original message', () async {
    final bloc = _bloc((_, _) async => throw OpdsException('boom'));
    addTearDown(bloc.close);

    final failed = bloc.stream.firstWhere(
      (state) => state.status == CatalogStatus.failure,
    );
    bloc.add(const CatalogStarted());
    final state = await failed;

    expect(state.error, 'boom');
    expect(state.feed, isNull);
  });

  test('turns a query into an OpenSearch page', () async {
    final requested = <Uri>[];
    final bloc = _bloc((url, _) async {
      requested.add(url);
      return _feed(url, title: 'Results');
    });
    addTearDown(bloc.close);

    bloc.add(const CatalogStarted());
    await bloc.stream.firstWhere(
      (state) => state.status == CatalogStatus.ready,
    );

    bloc.add(const CatalogSearchRequested('  dune  '));
    final results = await bloc.stream.firstWhere(
      (state) => state.query != null,
    );

    expect(results.query, 'dune');
    expect(results.feed?.title, 'Results');
    expect(results.canGoPrevious, isTrue);
    expect(requested.last.queryParameters['q'], 'dune');
  });

  test('explains when the catalog has no search template', () async {
    final bloc = _bloc(
      (url, _) async => _feed(url),
      searchTemplateLoader: (_, _) async => null,
    );
    addTearDown(bloc.close);

    bloc.add(const CatalogStarted());
    await bloc.stream.firstWhere(
      (state) => state.status == CatalogStatus.ready,
    );

    final failed = bloc.stream.firstWhere(
      (state) => state.status == CatalogStatus.failure,
    );
    bloc.add(const CatalogSearchRequested('dune'));
    final state = await failed;

    expect(state.error, isNotNull);
    expect(state.feed, isNotNull);
  });

  test('offers search only when the feed declares it', () async {
    final withSearch = _bloc(
      (url, _) async => OpdsFeed(
        url: url,
        title: 'Catalog',
        entries: const [],
        searchTemplate: _searchTemplate,
      ),
    );
    addTearDown(withSearch.close);
    withSearch.add(const CatalogStarted());
    final ready = await withSearch.stream.firstWhere(
      (state) => state.status == CatalogStatus.ready,
    );
    expect(ready.canSearch, isTrue);

    final withoutSearch = _bloc((url, _) async => _feed(url));
    addTearDown(withoutSearch.close);
    withoutSearch.add(const CatalogStarted());
    final plain = await withoutSearch.stream.firstWhere(
      (state) => state.status == CatalogStatus.ready,
    );
    expect(plain.canSearch, isFalse);
  });
}
