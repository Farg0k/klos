import 'package:flutter_test/flutter_test.dart';
import 'package:klos/opds/opds_feed.dart';

const _sampleFeed = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom"
      xmlns:dc="http://purl.org/dc/terms/">
  <title>Test Catalog</title>
  <link rel="next" href="page2?x=1&amp;y=2"/>
  <entry>
    <title>Category One</title>
    <link rel="subsection" href="category/one"
          type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  </entry>
  <entry>
    <title>Book Two</title>
    <author><name>Jane Doe</name></author>
    <summary>  A  good
      book. </summary>
    <dc:creator>John Smith</dc:creator>
    <link rel="http://opds-spec.org/acquisition"
          href="../files/book%20two.epub"
          type="application/epub+zip"/>
    <link rel="http://opds-spec.org/acquisition/open-access"
          href="../files/book%20two.mobi"
          type="application/x-mobipocket-ebook"/>
    <link rel="http://opds-spec.org/image"
          href="../covers/two.jpg"
          type="image/jpeg"/>
  </entry>
</feed>''';

void main() {
  group('OpdsFeed.parse', () {
    final baseUrl = Uri.parse('https://example.com/opds/catalog.xml');

    test('parses feed title, entries and resolved links', () {
      final feed = OpdsFeed.parse(_sampleFeed, baseUrl);

      expect(feed.title, 'Test Catalog');
      expect(feed.entries, hasLength(2));
      expect(
        feed.nextPage.toString(),
        'https://example.com/opds/page2?x=1&y=2',
      );

      final navigation = feed.entries.first;
      expect(navigation.title, 'Category One');
      expect(navigation.hasNavigation, isTrue);
      expect(navigation.hasAcquisitions, isFalse);
      expect(
        navigation.navigationLinks.single.href.toString(),
        'https://example.com/opds/category/one',
      );

      final book = feed.entries.last;
      expect(book.title, 'Book Two');
      expect(book.author, 'Jane Doe');
      expect(book.summary, 'A good book.');
      expect(book.hasNavigation, isFalse);
      expect(book.hasAcquisitions, isTrue);
      expect(book.links, hasLength(3));

      final epub = book.acquisitionLinks.first;
      expect(epub.type, 'application/epub+zip');
      expect(epub.href.toString(), 'https://example.com/files/book%20two.epub');
      expect(
        book.acquisitionLinks.last.href.toString(),
        'https://example.com/files/book%20two.mobi',
      );
    });

    test('rejects documents that are not Atom feeds', () {
      expect(
        () => OpdsFeed.parse('<html><body>nope</body></html>', baseUrl),
        throwsFormatException,
      );
    });

    test('rejects malformed XML', () {
      expect(
        () => OpdsFeed.parse('<feed><title>broken', baseUrl),
        throwsFormatException,
      );
    });

    test('keeps feed working when entries have only navigation', () {
      const feedXml = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Root</title>
  <entry>
    <title>Authors</title>
    <link rel="subsection" href="/authors"
          type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  </entry>
</feed>''';
      final feed = OpdsFeed.parse(feedXml, Uri.parse('http://localhost/opds'));
      expect(feed.entries.single.navigationLinks.single.href.path, '/authors');
      expect(feed.entries.single.isFolder, isTrue);
      expect(feed.nextPage, isNull);
      expect(feed.previousPage, isNull);
    });

    test('keeps a book with a series link a book', () {
      const feedXml = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Series</title>
  <entry>
    <title>Second book</title>
    <link rel="http://opds-spec.org/acquisition" href="/books/second.mobi"
          type="application/x-mobipocket-ebook"/>
    <link rel="subsection" href="/series/one"
          type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  </entry>
  <entry>
    <title>The series</title>
    <link rel="subsection" href="/series/one"
          type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  </entry>
</feed>''';
      final feed = OpdsFeed.parse(feedXml, Uri.parse('http://localhost/opds'));

      final book = feed.entries.first;
      expect(book.hasAcquisitions, isTrue);
      expect(book.hasNavigation, isTrue);
      expect(book.isFolder, isFalse);
      expect(feed.entries.last.isFolder, isTrue);
    });

    test('treats a plain Atom link as navigation (Flibusta style)', () {
      const feedXml = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Flibusta catalog</title>
  <entry>
    <title>По авторам</title>
    <link href="/opds/authorsindex"
          type="application/atom+xml;profile=opds-catalog"/>
  </entry>
  <entry>
    <title>Новинки</title>
    <link href="/opds/new" rel="http://opds-spec.org/sort/new"
          type="application/atom+xml;profile=opds-catalog"/>
  </entry>
</feed>''';
      final feed = OpdsFeed.parse(feedXml, Uri.parse('http://localhost/opds'));

      final authors = feed.entries.first;
      expect(authors.hasNavigation, isTrue);
      expect(authors.hasAcquisitions, isFalse);
      expect(
        authors.navigationLinks.single.href.toString(),
        'http://localhost/opds/authorsindex',
      );

      final fresh = feed.entries.last;
      expect(fresh.hasNavigation, isTrue);
      expect(
        fresh.navigationLinks.single.href.toString(),
        'http://localhost/opds/new',
      );
    });

    test('keeps an author biography out of the book downloads', () {
      // Flibusta puts the author's biography into the author feed as a card
      // that also declares its HTML page as an acquisition. The text starts
      // with a double-escaped `&nbsp`, which used to reach the Kindle page.
      const feedXml = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Книги автора</title>
  <entry>
    <id>tag:author:bio:50486</id>
    <title>Об авторе</title>
    <content type="text/html">&lt;img src=&quot;/a.jpg&quot;&gt; &amp;nbsp &lt;p&gt;Джо Аберкромби — писатель.&lt;/p&gt;</content>
    <link href="/a/50486" rel="alternate" type="text/html"/>
    <link href="/a/50486" rel="http://opds-spec.org/acquisition"
          type="text/html"/>
    <link href="/opds/authorsequences/50486"
          type="application/atom+xml;profile=opds-catalog"/>
  </entry>
</feed>''';
      final feed = OpdsFeed.parse(feedXml, Uri.parse('http://localhost/opds'));
      final bio = feed.entries.single;

      expect(bio.summary, 'Джо Аберкромби — писатель.');
      expect(bio.summary, isNot(contains('&nbsp')));
      expect(bio.acquisitionLinks, hasLength(1));
      expect(bio.downloadLinks, isEmpty);
      expect(bio.hasDownloads, isFalse);
      expect(bio.isFolder, isFalse);
    });

    test('decodes the full HTML entity set in feed text', () {
      const feedXml = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Entities</title>
  <entry>
    <title>Entity examples</title>
    <summary>&amp;quot;quoted&amp;quot; &amp;mdash; &amp;copy; &#38;#x1F600; &amp;amp;mdash;</summary>
  </entry>
</feed>''';
      final feed = OpdsFeed.parse(feedXml, Uri.parse('http://localhost/opds'));

      expect(feed.entries.single.summary, '"quoted" — © 😀 —');
    });

    test('prefers a cover thumbnail and falls back to the full image', () {
      const feedXml = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Covers</title>
  <entry>
    <title>With thumbnail</title>
    <link rel="http://opds-spec.org/image" href="/cover-full.jpg"
          type="image/jpeg"/>
    <link rel="http://opds-spec.org/image/thumbnail" href="/cover-thumb.jpg"
          type="image/jpeg"/>
  </entry>
  <entry>
    <title>Full only</title>
    <link rel="http://opds-spec.org/image" href="/only-full.png"
          type="image/png"/>
  </entry>
  <entry>
    <title>No cover</title>
  </entry>
</feed>''';
      final feed = OpdsFeed.parse(feedXml, Uri.parse('http://localhost/opds'));

      expect(
        feed.entries[0].coverLink!.href.toString(),
        'http://localhost/cover-thumb.jpg',
      );
      expect(
        feed.entries[1].coverLink!.href.toString(),
        'http://localhost/only-full.png',
      );
      expect(feed.entries[1].coverLink!.type, 'image/png');
      expect(feed.entries[2].coverLink, isNull);
    });

    test('accepts the legacy thumbnail relation (Flibusta style)', () {
      const feedXml = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Covers</title>
  <entry>
    <title>Legacy</title>
    <link rel="http://opds-spec.org/image" href="/cover.jpg"
          type="image/jpeg"/>
    <link rel="http://opds-spec.org/thumbnail" href="/thumb.jpg"
          type="image/jpeg"/>
  </entry>
</feed>''';
      final feed = OpdsFeed.parse(feedXml, Uri.parse('http://localhost/opds'));

      expect(
        feed.entries.single.coverLink!.href.toString(),
        'http://localhost/thumb.jpg',
      );
    });

    test('reads the search template and OpenSearch description link', () {
      const feedXml = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Searchable</title>
  <link rel="search" href="/opds/search?searchTerm={searchTerms}"
        type="application/atom+xml"/>
  <link rel="search" href="/opds-opensearch.xml"
        type="application/opensearchdescription+xml"/>
</feed>''';
      final feed = OpdsFeed.parse(feedXml, Uri.parse('http://localhost/opds'));

      expect(
        feed.searchTemplate,
        'http://localhost/opds/search?searchTerm={searchTerms}',
      );
      expect(
        feed.searchDescription.toString(),
        'http://localhost/opds-opensearch.xml',
      );
    });

    test('keeps no template when the feed only links to a description', () {
      const feedXml = '''
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Searchable</title>
  <link rel="search" href="/opds-opensearch.xml"
        type="application/opensearchdescription+xml"/>
</feed>''';
      final feed = OpdsFeed.parse(feedXml, Uri.parse('http://localhost/opds'));

      expect(feed.searchTemplate, isNull);
      expect(feed.searchDescription, isNotNull);
    });
  });
}
