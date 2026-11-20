import 'package:flutter_test/flutter_test.dart';
import 'package:klos/entity/favorite.dart';
import 'package:klos/features/favorites_screen/bloc/favorites_bloc.dart';
import 'package:klos/opds/opds_feed.dart';

import '../helpers/test_locator.dart';

OpdsEntry _book({String title = 'Book'}) {
  return OpdsEntry(
    title: title,
    author: 'Author',
    links: [
      OpdsLink(
        href: Uri.parse('http://example.com/$title.epub'),
        rel: 'http://opds-spec.org/acquisition',
        type: 'application/epub+zip',
      ),
    ],
  );
}

OpdsEntry _navigation() {
  return OpdsEntry(
    title: 'Authors',
    links: [
      OpdsLink(
        href: Uri.parse('http://example.com/authors'),
        rel: 'subsection',
        type: 'application/atom+xml;profile=opds-catalog',
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeObjectBoxService storage;
  late FavoritesBloc bloc;

  setUp(() async {
    storage = await setUpTestLocator();
    bloc = FavoritesBloc();
  });

  tearDown(() async {
    await bloc.close();
    await tearDownTestLocator();
  });

  test('adds a book and stores it', () async {
    final entry = _book();
    bloc.add(FavoriteToggled(entry));
    final saved = await bloc.stream.firstWhere((state) => !state.isEmpty);

    expect(saved.count, 1);
    expect(saved.contains(Favorite.keyFor(entry)), isTrue);
    expect(storage.getFavorites().single.title, 'Book');
  });

  test('toggles the same book off again', () async {
    final entry = _book();
    final key = Favorite.keyFor(entry);

    bloc.add(FavoriteToggled(entry));
    await bloc.stream.firstWhere((state) => state.contains(key));

    bloc.add(FavoriteToggled(entry));
    final empty = await bloc.stream.firstWhere((state) => !state.contains(key));

    expect(empty.isEmpty, isTrue);
    expect(storage.getFavorites(), isEmpty);
  });

  test('ignores navigation entries', () async {
    bloc.add(FavoriteToggled(_navigation()));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.isEmpty, isTrue);
    expect(storage.getFavorites(), isEmpty);
  });

  test('removes a saved book by key', () async {
    final entry = _book();
    final key = Favorite.keyFor(entry)!;

    bloc.add(FavoriteToggled(entry));
    await bloc.stream.firstWhere((state) => state.contains(key));

    bloc.add(FavoriteRemoved(key));
    final empty = await bloc.stream.firstWhere((state) => state.isEmpty);

    expect(empty.favorites, isEmpty);
    expect(storage.getFavorites(), isEmpty);
  });

  test('lists the newest book first', () async {
    final first = _book(title: 'First');
    final second = _book(title: 'Second');

    bloc.add(FavoriteToggled(first));
    await bloc.stream.firstWhere((state) => state.count == 1);

    // ObjectBox stores milliseconds, so separate the two adds a little.
    await Future<void>.delayed(const Duration(milliseconds: 5));
    bloc.add(FavoriteToggled(second));
    final both = await bloc.stream.firstWhere((state) => state.count == 2);

    expect(both.favorites.first.title, 'Second');
  });
}
