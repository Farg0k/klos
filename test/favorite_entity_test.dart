import 'package:flutter_test/flutter_test.dart';
import 'package:klos/entity/favorite.dart';
import 'package:klos/entity/favorite_entity.dart';
import 'package:klos/opds/opds_feed.dart';

void main() {
  test('round-trips a favorite through the ObjectBox entity', () {
    final favorite = Favorite(
      id: 7,
      key: 'http://example.com/%D0%BA%D0%BD%D0%B8%D0%B3%D0%B0.epub',
      title: 'Книга',
      author: 'Автор',
      summary: 'Опис книги',
      links: [
        OpdsLink(
          href: Uri.parse(
            'http://example.com/%D0%BA%D0%BD%D0%B8%D0%B3%D0%B0.epub',
          ),
          rel: 'http://opds-spec.org/acquisition',
          type: 'application/epub+zip',
          title: 'EPUB',
        ),
        OpdsLink(
          href: Uri.parse('http://example.com/cover.jpg'),
          rel: 'http://opds-spec.org/image/thumbnail',
          type: 'image/jpeg',
        ),
      ],
      catalogUrl: 'http://example.com/opds',
      addedAt: DateTime(2024, 5, 1, 12, 30),
    );

    final restored = FavoriteEntity.fromFavorite(favorite).toFavorite();

    expect(restored.id, 7);
    expect(restored.key, favorite.key);
    expect(restored.title, 'Книга');
    expect(restored.author, 'Автор');
    expect(restored.summary, 'Опис книги');
    expect(restored.catalogUrl, 'http://example.com/opds');
    expect(restored.addedAt, favorite.addedAt);
    expect(restored.links, hasLength(2));
    expect(restored.links.first.type, 'application/epub+zip');
    expect(restored.links.first.title, 'EPUB');
    expect(restored.links.last.isThumbnail, isTrue);
  });

  test('reads an empty link list as no links', () {
    final restored = FavoriteEntity(
      key: 'http://example.com/book.epub',
      title: 'Book',
    ).toFavorite();

    expect(restored.links, isEmpty);
    expect(restored.author, isNull);
    expect(restored.summary, isNull);
  });

  test('skips broken link JSON', () {
    final restored = FavoriteEntity(
      key: 'http://example.com/book.epub',
      title: 'Book',
      links: 'not json',
    ).toFavorite();

    expect(restored.links, isEmpty);
  });

  test('builds a favorite only from downloadable entries', () {
    final navigation = OpdsEntry(
      title: 'Authors',
      links: [
        OpdsLink(
          href: Uri.parse('http://example.com/authors'),
          rel: 'subsection',
        ),
      ],
    );
    expect(Favorite.fromEntry(navigation), isNull);

    final book = OpdsEntry(
      title: 'Book',
      links: [
        OpdsLink(
          href: Uri.parse('http://example.com/book.epub'),
          rel: 'http://opds-spec.org/acquisition',
          type: 'application/epub+zip',
        ),
        OpdsLink(
          href: Uri.parse('http://example.com/cover.jpg'),
          rel: 'http://opds-spec.org/image',
          type: 'image/jpeg',
        ),
      ],
    );
    final favorite = Favorite.fromEntry(book, catalogUrl: 'http://example.com');

    expect(favorite, isNotNull);
    expect(favorite!.key, 'http://example.com/book.epub');
    expect(favorite.links, hasLength(2));
    expect(favorite.toEntry().acquisitionLinks, hasLength(1));
    expect(favorite.toEntry().coverLink, isNotNull);
  });

  test('does not treat an HTML author page as a book', () {
    final bio = OpdsEntry(
      title: 'Об авторе',
      summary: 'Джо Аберкромби — писатель.',
      links: [
        OpdsLink(
          href: Uri.parse('http://example.com/a/50486'),
          rel: 'http://opds-spec.org/acquisition',
          type: 'text/html',
        ),
        OpdsLink(
          href: Uri.parse('http://example.com/opds/authorsequences/50486'),
          rel: 'http://www.feedbooks.com/opds/facet',
          type: 'application/atom+xml;profile=opds-catalog',
        ),
      ],
    );

    expect(bio.downloadLinks, isEmpty);
    expect(Favorite.keyFor(bio), isNull);
    expect(Favorite.fromEntry(bio), isNull);
  });
}
