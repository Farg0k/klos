import 'package:flutter_test/flutter_test.dart';
import 'package:klos/opds/opds2_feed.dart';

const _feed = '''{
  "metadata": {"title": "JSON Catalog"},
  "links": [
    {"rel": "self", "href": "/opds", "type": "application/opds+json"},
    {"rel": "next", "href": "/opds?page=2", "type": "application/opds+json"},
    {"rel": "previous", "href": "/opds?page=0", "type": "application/opds+json"},
    {"rel": "search", "href": "/opds/search{?query}",
     "type": "application/opds+json", "templated": true}
  ],
  "navigation": [
    {"title": "Authors", "href": "/opds/authors", "type": "application/opds+json"}
  ],
  "publications": [
    {
      "metadata": {
        "title": "Book",
        "author": [{"name": "First"}, {"name": "Second"}],
        "description": "A description"
      },
      "links": [
        {"rel": "http://opds-spec.org/acquisition/open-access",
         "href": "/book.epub", "type": "application/epub+zip"},
        {"rel": "self", "href": "/opds/book/1", "type": "application/opds+json"}
      ],
      "images": [{"href": "/cover.jpg", "type": "image/jpeg"}]
    }
  ]
}''';

void main() {
  group('parseOpds2', () {
    test('reads navigation, publications, covers, pagination and search', () {
      final feed = parseOpds2(_feed, Uri.parse('https://host/opds'));

      expect(feed.title, 'JSON Catalog');
      expect(feed.entries, hasLength(2));

      final navigation = feed.entries.first;
      expect(navigation.title, 'Authors');
      expect(navigation.hasNavigation, isTrue);
      expect(navigation.hasAcquisitions, isFalse);
      expect(
        navigation.navigationLinks.single.href.toString(),
        'https://host/opds/authors',
      );

      final book = feed.entries.last;
      expect(book.title, 'Book');
      expect(book.author, 'First, Second');
      expect(book.summary, 'A description');
      expect(book.acquisitionLinks.single.type, 'application/epub+zip');
      expect(
        book.acquisitionLinks.single.href.toString(),
        'https://host/book.epub',
      );
      expect(book.coverLink!.href.toString(), 'https://host/cover.jpg');

      expect(feed.nextPage.toString(), 'https://host/opds?page=2');
      expect(feed.previousPage.toString(), 'https://host/opds?page=0');
      expect(feed.searchTemplate, 'https://host/opds/search{?query}');
      expect(feed.searchDescription, isNull);
    });

    test('accepts a single publication document', () {
      const source = '''{
        "metadata": {
          "title": "Single",
          "author": "Someone",
          "description": "Text"
        },
        "links": [
          {"rel": "http://opds-spec.org/acquisition",
           "href": "book.mobi",
           "type": "application/x-mobipocket-ebook"}
        ]
      }''';

      final feed = parseOpds2(source, Uri.parse('https://host/publication/1'));

      expect(feed.title, 'Single');
      final entry = feed.entries.single;
      expect(entry.title, 'Single');
      expect(entry.author, 'Someone');
      expect(entry.summary, 'Text');
      expect(
        entry.acquisitionLinks.single.href.toString(),
        'https://host/publication/book.mobi',
      );
    });

    test('flattens groups and keeps their entries', () {
      const source = '''{
        "metadata": {"title": "Grouped"},
        "groups": [
          {
            "metadata": {"title": "Group"},
            "navigation": [
              {"title": "In Group", "href": "/group", "type": "application/opds+json"}
            ],
            "publications": [
              {"metadata": {"title": "Group Book"},
               "links": [{"rel": "http://opds-spec.org/acquisition",
                          "href": "/g.epub", "type": "application/epub+zip"}]}
            ]
          }
        ]
      }''';

      final feed = parseOpds2(source, Uri.parse('https://host/opds'));

      expect(feed.entries.map((entry) => entry.title), [
        'In Group',
        'Group Book',
      ]);
    });

    test('uses a cover link when there is no images array', () {
      const source = '''{
        "metadata": {"title": "Covers"},
        "publications": [
          {"metadata": {"title": "With Cover"},
           "links": [
             {"rel": "cover", "href": "/cover.png", "type": "image/png"},
             {"rel": "http://opds-spec.org/acquisition",
              "href": "/b.epub", "type": "application/epub+zip"}
           ]}
        ]
      }''';

      final feed = parseOpds2(source, Uri.parse('https://host/opds'));

      expect(
        feed.entries.single.coverLink!.href.toString(),
        'https://host/cover.png',
      );
      expect(feed.entries.single.acquisitionLinks, hasLength(1));
    });

    test('strips HTML from descriptions and skips untitled publications', () {
      const source = '''{
        "metadata": {"title": "Titles"},
        "publications": [
          {"metadata": {"title": "Book", "description": "<p>Hello <b>there</b></p>"},
           "links": []},
          {"metadata": {"description": "no title"}, "links": []}
        ]
      }''';

      final feed = parseOpds2(source, Uri.parse('https://host/opds'));

      expect(feed.entries, hasLength(1));
      expect(feed.entries.single.summary, 'Hello there');
    });

    test('falls back to the URL when metadata has no title', () {
      final feed = parseOpds2(
        '{"metadata": {}, "navigation": []}',
        Uri.parse('https://host/some/catalog'),
      );

      expect(feed.title, 'catalog');
      expect(feed.entries, isEmpty);
    });

    test('rejects documents that are not JSON objects', () {
      expect(
        () => parseOpds2('<html></html>', Uri.parse('https://host/')),
        throwsFormatException,
      );
      expect(
        () => parseOpds2('[]', Uri.parse('https://host/')),
        throwsFormatException,
      );
    });
  });
}
