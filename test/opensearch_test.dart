import 'package:flutter_test/flutter_test.dart';
import 'package:klos/opds/opensearch.dart';

void main() {
  group('buildSearchUrl', () {
    test('fills the query and drops optional and unknown parameters', () {
      final url = buildSearchUrl(
        'http://host/opds/search?searchTerm={searchTerms}'
            '&searchType=books&pageNumber={startPage?}',
        'Тарас Шевченко',
      );

      expect(url, isNotNull);
      expect(url!.path, '/opds/search');
      expect(url.queryParameters['searchTerm'], 'Тарас Шевченко');
      expect(url.queryParameters['searchType'], 'books');
      expect(url.toString(), isNot(contains('startPage')));
      expect(url.toString(), isNot(contains('{')));
    });

    test('works when the first parameter is optional', () {
      final url = buildSearchUrl(
        'http://host/s?page={startPage?}&q={searchTerms}',
        'книга',
      );

      expect(url, isNotNull);
      expect(url!.path, '/s');
      expect(url.queryParameters, {'q': 'книга'});
    });

    test('returns null without a searchTerms placeholder', () {
      expect(buildSearchUrl('http://host/opds', 'book'), isNull);
      expect(buildSearchUrl('http://host/opds?q=', 'book'), isNull);
    });

    test('fills an OPDS 2.0 URI template', () {
      final url = buildSearchUrl('http://host/search{?query}', 'книга');

      expect(url, isNotNull);
      expect(url!.path, '/search');
      expect(url.queryParameters, {'query': 'книга'});
      expect(url.toString(), isNot(contains('{')));
    });

    test('appends to an existing query string', () {
      final url = buildSearchUrl('http://host/search?lang=uk{&query}', 'книга');

      expect(url, isNotNull);
      expect(url!.queryParameters, {'lang': 'uk', 'query': 'книга'});
    });
  });

  group('parseSearchDescription', () {
    test('reads the Atom URL template and resolves it', () {
      const source = '''<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <ShortName>Fixture</ShortName>
  <Url type="application/atom+xml"
       template="/search?q={searchTerms}&amp;page={startPage?}"/>
</OpenSearchDescription>''';

      final template = parseSearchDescription(
        source,
        Uri.parse('http://host/osd.xml'),
      );

      expect(template, 'http://host/search?q={searchTerms}&page={startPage?}');
    });

    test(
      'returns null for a document that is not an OpenSearch description',
      () {
        expect(
          parseSearchDescription(
            '<html><body>Not a description</body></html>',
            Uri.parse('http://host/'),
          ),
          isNull,
        );
      },
    );
  });

  group('isSearchTemplate', () {
    test('requires a searchTerms placeholder', () {
      expect(isSearchTemplate('http://host/s?q={searchTerms}'), isTrue);
      expect(isSearchTemplate('http://host/s'), isFalse);
    });

    test('accepts OPDS 2.0 URI templates', () {
      expect(isSearchTemplate('http://host/s{?query}'), isTrue);
      expect(isSearchTemplate('http://host/s?a=b{&query}'), isTrue);
    });
  });
}
