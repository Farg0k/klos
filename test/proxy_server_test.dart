import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/entity/app_settings.dart';
import 'package:klos/entity/favorite.dart';
import 'package:klos/books/ebook_archive.dart';
import 'package:klos/l10n/l10n.dart';
import 'package:klos/mail/kindle_mailer.dart';
import 'package:klos/opds/opds_feed.dart';
import 'package:klos/server/proxy_server.dart';
import 'package:klos/server/url_codec.dart';

class _ControlledMailer extends KindleMailer {
  _ControlledMailer({this.failure});

  final String? failure;
  final started = Completer<void>();
  final release = Completer<void>();
  final sent = <String>[];

  @override
  Future<void> sendBook({
    required AppSettings settings,
    required Uri url,
    String? title,
    String? mime,
    void Function()? onSending,
  }) async {
    if (!started.isCompleted) started.complete();
    await release.future;
    onSending?.call();
    if (failure != null) throw KindleMailException(failure!);
    sent.add(title ?? '');
  }
}

AppSettings _mailSettings(String remoteBase) {
  return AppSettings(
    catalogUrl: Uri.parse('$remoteBase/opds'),
    kindleEmail: 'reader@kindle.com',
    smtpHost: 'smtp.example.com',
    senderEmail: 'sender@example.com',
  );
}

const _feed = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Fixture Catalog</title>
  <link rel="next" href="/opds?page=2" type="application/atom+xml"/>
  <link rel="search" href="/opds/search?searchTerm={searchTerms}"
        type="application/atom+xml"/>
  <link rel="search" href="/osd.xml"
        type="application/opensearchdescription+xml"/>
  <entry>
    <title>Subcategory</title>
    <link rel="subsection" href="/sub"
          type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
  </entry>
  <entry>
    <title>За авторами</title>
    <content type="text">Пошук книг за авторами</content>
    <link href="/authors"
          type="application/atom+xml;profile=opds-catalog"/>
  </entry>
  <entry>
    <title>Mobi Book</title>
    <link rel="http://opds-spec.org/acquisition" href="/book.mobi"
          type="application/x-mobipocket-ebook"/>
  </entry>
  <entry>
    <title>Fixture Book</title>
    <author><name>Tester</name></author>
    <link rel="http://opds-spec.org/image/thumbnail" href="/cover.jpg"
          type="image/jpeg"/>
    <link rel="http://opds-spec.org/acquisition" href="/book.epub"
          type="application/epub+zip"/>
  </entry>
  <entry>
    <title>Zipped Book</title>
    <link rel="http://opds-spec.org/acquisition" href="/book.zip"
          type="application/zip"/>
  </entry>
  <entry>
    <title>Mixed Formats Book</title>
    <link rel="http://opds-spec.org/acquisition" href="/book.epub"
          type="application/epub+zip"/>
    <link rel="http://opds-spec.org/acquisition" href="/book.mobi"
          type="application/x-mobipocket-ebook"/>
  </entry>
</feed>''';

const _feedPage2 = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Page 2</title>
  <link rel="next" href="/opds?page=3" type="application/atom+xml"/>
  <entry>
    <title>Second Page Book</title>
    <link rel="http://opds-spec.org/acquisition" href="/book.mobi"
          type="application/x-mobipocket-ebook"/>
  </entry>
</feed>''';

const _feedPage3 = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Page 3</title>
  <entry>
    <title>Third Page Book</title>
    <link rel="http://opds-spec.org/acquisition" href="/book.mobi"
          type="application/x-mobipocket-ebook"/>
  </entry>
</feed>''';

const _subFeed = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Subcategory</title>
  <entry>
    <title>Nested Book</title>
    <link rel="http://opds-spec.org/acquisition" href="/book.epub"
          type="application/epub+zip"/>
  </entry>
</feed>''';

// An author page as Flibusta serves it: the biography is a card that also
// declares its HTML page as an acquisition, and its text starts with a
// double-escaped `&nbsp` between the two portraits.
const _authorFeed = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Книги автора</title>
  <entry>
    <title>Об авторе</title>
    <content type="text/html">&lt;img src=&quot;/a.jpg&quot;&gt; &amp;nbsp &lt;p&gt;Джо Аберкромби — писатель.&lt;/p&gt;</content>
    <link href="/a/50486" rel="alternate" type="text/html"/>
    <link href="/a/50486" rel="http://opds-spec.org/acquisition"
          type="text/html"/>
    <link href="/opds/authorsequences/50486"
          type="application/atom+xml;profile=opds-catalog"/>
  </entry>
</feed>''';

const _osdFeed = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Catalog via OpenSearch</title>
  <link rel="search" href="/osd.xml"
        type="application/opensearchdescription+xml"/>
  <entry>
    <title>OSD Book</title>
    <link rel="http://opds-spec.org/acquisition" href="/book.epub"
          type="application/epub+zip"/>
  </entry>
</feed>''';

const _osd = '''<?xml version="1.0" encoding="UTF-8"?>
<OpenSearchDescription xmlns="http://a9.com/-/spec/opensearch/1.1/">
  <ShortName>Fixture</ShortName>
  <Url type="application/atom+xml"
       template="/opds/search?searchTerm={searchTerms}&amp;searchType=books&amp;pageNumber={startPage?}"/>
</OpenSearchDescription>''';

const _searchFeed = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom">
  <title>Search Results</title>
  <entry>
    <title>Found Book</title>
    <link rel="http://opds-spec.org/acquisition" href="/book.epub"
          type="application/epub+zip"/>
  </entry>
</feed>''';

const _jsonFeed = '''{
  "metadata": {"title": "JSON Catalog"},
  "links": [
    {"rel": "self", "href": "/opds2", "type": "application/opds+json"},
    {"rel": "search", "href": "/opds2/search{?query}",
     "type": "application/opds+json", "templated": true}
  ],
  "navigation": [
    {"title": "JSON Authors", "href": "/sub", "type": "application/opds+json"}
  ],
  "publications": [
    {
      "metadata": {
        "title": "JSON Book",
        "author": [{"name": "Json Author"}],
        "description": "From JSON"
      },
      "links": [
        {"rel": "http://opds-spec.org/acquisition/open-access",
         "href": "/book.epub", "type": "application/epub+zip"}
      ],
      "images": [{"href": "/cover.jpg", "type": "image/jpeg"}]
    }
  ]
}''';

const _jsonSearchFeed = '''{
  "metadata": {"title": "JSON Results"},
  "publications": [
    {
      "metadata": {"title": "JSON Found"},
      "links": [
        {"rel": "http://opds-spec.org/acquisition",
         "href": "/book.epub", "type": "application/epub+zip"}
      ]
    }
  ]
}''';

const _epubContainer = '''<?xml version="1.0" encoding="utf-8"?>
<container version="1.0"
    xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf"
        media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

const _epubOpf = '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0"
    unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Конвертована книга</dc:title>
    <dc:creator>Тестовий автор</dc:creator>
    <dc:language>uk</dc:language>
  </metadata>
  <manifest>
    <item id="ch1" href="chapter1.xhtml"
        media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
  </spine>
</package>''';

const _epubChapter = '''<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Перший</title></head>
<body>
  <h1>Перший розділ</h1>
  <p>Текст для конвертації.</p>
</body>
</html>''';

Uint8List _epubBytes() {
  final archive = Archive();
  archive.add(_stamped(ArchiveFile.string('mimetype', 'application/epub+zip')));
  archive.add(
    _stamped(ArchiveFile.string('META-INF/container.xml', _epubContainer)),
  );
  archive.add(_stamped(ArchiveFile.string('OEBPS/content.opf', _epubOpf)));
  archive.add(
    _stamped(ArchiveFile.string('OEBPS/chapter1.xhtml', _epubChapter)),
  );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// ZIP entries default to the current time, which would make the fixture
/// differ between two calls in the same test.
ArchiveFile _stamped(ArchiveFile file) {
  file.lastModTime = 0;
  file.creationTime = 0;
  return file;
}

Uint8List _zipBytes(Map<String, List<int>> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    archive.add(_stamped(ArchiveFile.bytes(entry.key, entry.value)));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const String _fb2Document = '''
<?xml version="1.0" encoding="utf-8"?>
<FictionBook xmlns="http://www.gribuser.ru/xml/fictionbook/2.0">
  <description>
    <title-info>
      <book-title>FB2 Book</book-title>
      <lang>uk</lang>
      <author><first-name>Тарас</first-name><last-name>Шевченко</last-name></author>
    </title-info>
  </description>
  <body>
    <section><title><p>Розділ</p></title><p>Привіт, світе!</p></section>
  </body>
</FictionBook>
''';

Uint8List _fb2Bytes() => Uint8List.fromList(utf8.encode(_fb2Document));

void main() {
  setUpAll(() async {
    await L10n.use(const Locale('uk'));
  });

  late HttpServer remote;
  late OpdsProxyServer proxy;
  late HttpClient client;
  late List<String> logs;
  late String remoteBase;
  late int downloadRequests;
  late int epubRequests;
  late int osdRequests;
  late List<Uri> searchRequests;

  setUp(() async {
    downloadRequests = 0;
    epubRequests = 0;
    osdRequests = 0;
    searchRequests = <Uri>[];
    remote = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    remoteBase = 'http://127.0.0.1:${remote.port}';
    remote.listen((request) async {
      final response = request.response;
      switch (request.uri.path) {
        case '/opds':
          response.headers.contentType = ContentType(
            'application',
            'atom+xml',
            charset: 'utf-8',
          );
          final page = request.uri.queryParameters['page'];
          response.write(switch (page) {
            '2' => _feedPage2,
            '3' => _feedPage3,
            _ => _feed,
          });
          break;
        case '/sub':
          response.headers.contentType = ContentType(
            'application',
            'atom+xml',
            charset: 'utf-8',
          );
          response.write(_subFeed);
          break;
        case '/author':
          response.headers.contentType = ContentType(
            'application',
            'atom+xml',
            charset: 'utf-8',
          );
          response.write(_authorFeed);
          break;
        case '/osd-feed':
          response.headers.contentType = ContentType(
            'application',
            'atom+xml',
            charset: 'utf-8',
          );
          response.write(_osdFeed);
          break;
        case '/osd.xml':
          osdRequests++;
          response.headers.contentType = ContentType(
            'application',
            'opensearchdescription+xml',
            charset: 'utf-8',
          );
          response.write(_osd);
          break;
        case '/opds/search':
          searchRequests.add(request.uri);
          response.headers.contentType = ContentType(
            'application',
            'atom+xml',
            charset: 'utf-8',
          );
          response.write(_searchFeed);
          break;
        case '/opds2':
          response.headers.contentType = ContentType(
            'application',
            'opds+json',
            charset: 'utf-8',
          );
          response.write(_jsonFeed);
          break;
        case '/opds2/search':
          searchRequests.add(request.uri);
          response.headers.contentType = ContentType(
            'application',
            'opds+json',
            charset: 'utf-8',
          );
          response.write(_jsonSearchFeed);
          break;
        case '/book.epub':
          downloadRequests++;
          final bytes = utf8.encode('EPUB-BYTES');
          response.headers.contentType = ContentType('application', 'epub+zip');
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/book.pdf':
          downloadRequests++;
          final bytes = utf8.encode('PDF-BYTES');
          response.headers.contentType = ContentType('application', 'pdf');
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/cover.jpg':
          final bytes = utf8.encode('COVER-BYTES');
          response.headers.contentType = ContentType('image', 'jpeg');
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/convertible.epub':
          epubRequests++;
          final bytes = _epubBytes();
          response.headers.contentType = ContentType('application', 'epub+zip');
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/slow.epub':
          epubRequests++;
          await Future<void>.delayed(const Duration(milliseconds: 300));
          final bytes = _epubBytes();
          response.headers.contentType = ContentType('application', 'epub+zip');
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/book.zip':
          downloadRequests++;
          final bytes = _zipBytes({'book.epub': _epubBytes()});
          response.headers.contentType = ContentType('application', 'zip');
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/slow-download.zip':
          downloadRequests++;
          await Future<void>.delayed(const Duration(milliseconds: 300));
          final bytes = _zipBytes({'book.epub': _epubBytes()});
          response.headers.contentType = ContentType('application', 'zip');
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/book-mobi.zip':
          downloadRequests++;
          final bytes = _zipBytes({
            'book.epub': _epubBytes(),
            'book.mobi': utf8.encode('MOBI-BYTES'),
          });
          response.headers.contentType = ContentType('application', 'zip');
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/book-fb2.zip':
          downloadRequests++;
          final bytes = _zipBytes({
            'book.fb2': _fb2Bytes(),
            'cover.jpg': utf8.encode('COVER-BYTES'),
          });
          response.headers.contentType = ContentType('application', 'zip');
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/book.fb2':
          downloadRequests++;
          final bytes = _fb2Bytes();
          response.headers.contentType = ContentType(
            'application',
            'x-fictionbook+xml',
          );
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/no-convertible.zip':
          downloadRequests++;
          final bytes = _zipBytes({
            'notes.txt': utf8.encode('NOTES'),
            'cover.jpg': utf8.encode('COVER-BYTES'),
          });
          response.headers.contentType = ContentType('application', 'zip');
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/zipped.epub':
          downloadRequests++;
          final bytes = _zipBytes({'book.epub': _epubBytes()});
          response.headers.contentType = ContentType('application', 'zip');
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/comic.cbz':
          downloadRequests++;
          final bytes = _zipBytes({
            '001.jpg': utf8.encode('PAGE-1'),
            '002.jpg': utf8.encode('PAGE-2'),
          });
          response.headers.contentType = ContentType('application', 'x-cbz');
          response.contentLength = bytes.length;
          response.add(bytes);
          break;
        case '/login':
          response.headers.contentType = ContentType.html;
          response.write('<html><body>Login required</body></html>');
          break;
        case '/protected':
          final expected = 'Basic ${base64.encode(utf8.encode('user:pass'))}';
          if (request.headers.value(HttpHeaders.authorizationHeader) !=
              expected) {
            response.statusCode = HttpStatus.unauthorized;
            response.write('denied');
            break;
          }
          response.headers.contentType = ContentType(
            'application',
            'atom+xml',
            charset: 'utf-8',
          );
          response.write(
            '<feed xmlns="http://www.w3.org/2005/Atom">'
            '<title>Protected Catalog</title></feed>',
          );
          break;
        default:
          response.statusCode = HttpStatus.notFound;
      }
      await response.close();
    });

    logs = [];
    proxy = OpdsProxyServer(
      settingsProvider: () =>
          AppSettings(catalogUrl: Uri.parse('$remoteBase/opds')),
      log: logs.add,
    );
    await proxy.start(port: 0);

    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await proxy.stop();
    await remote.close(force: true);
  });

  Future<(int, String, HttpHeaders)> get(String path) async {
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:${proxy.port}$path'),
    );
    final response = await request.close();
    final body = await utf8.decoder.bind(response).join();
    return (response.statusCode, body, response.headers);
  }

  Future<(int, List<int>, HttpHeaders)> getBytes(String path) async {
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:${proxy.port}$path'),
    );
    final response = await request.close();
    final bytes = await response.fold<List<int>>(
      <int>[],
      (previous, chunk) => previous..addAll(chunk),
    );
    return (response.statusCode, bytes, response.headers);
  }

  Future<String> waitForBody(String path, String needle) async {
    var body = '';
    for (var attempt = 0; attempt < 200; attempt++) {
      final (_, page, _) = await get(path);
      body = page;
      if (body.contains(needle)) return body;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return body;
  }

  test('renders the root OPDS feed as HTML', () async {
    final (status, body, _) = await get('/');
    expect(status, 200);
    expect(body, contains('Fixture Catalog'));
    expect(body, contains('Fixture Book'));
    expect(body, contains('Subcategory'));
    expect(body, contains('/download/'));
    expect(body, contains('EPUB'));
    // A plain Atom link without rel="subsection" (Flibusta-style) must still
    // be rendered as a working navigation link.
    expect(body, contains('<b>За авторами</b></a>'));
    expect(body, contains('/browse?u='));
    expect(body, contains('/image?u='));
    expect(logs, isNotEmpty);
  });

  test('emphasises MOBI and puts it before the other formats', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => AppSettings(
        catalogUrl: Uri.parse('$remoteBase/opds'),
        kindleEmail: 'reader@kindle.com',
        smtpHost: 'smtp.example.com',
        senderEmail: 'sender@example.com',
      ),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/');
    expect(status, 200);

    final entry = body.substring(body.indexOf('Mixed Formats Book'));
    final actions = entry.substring(entry.indexOf('<div class="actions">'));
    final primary = actions.indexOf('class="button primary"');

    expect(primary, isNot(-1));
    expect(primary, lessThan(actions.indexOf('EPUB (')));
    expect(actions, contains('MOBI (завантажити)'));
  });

  test('shows big pager buttons above and below the list', () async {
    final (status, body, _) = await get('/');
    expect(status, 200);

    final top = body.indexOf('<div class="pager">');
    final list = body.indexOf('<ul class="books">');
    final bottom = body.lastIndexOf('<div class="pager">');

    expect(top, isNot(-1));
    expect(top, lessThan(list));
    expect(bottom, greaterThan(list));
    expect(RegExp('class="pager"').allMatches(body).length, 2);

    // The first page has no previous link, but the button is still shown in
    // both pagers, and Next is a link in both.
    expect(RegExp('class="button disabled"').allMatches(body).length, 2);
    expect(RegExp('Далі &gt;').allMatches(body).length, 2);
  });

  test('remembers the previous page when the feed has no Back link', () async {
    final page1 = browseHref(Uri.parse('$remoteBase/opds'));
    expect((await get(page1)).$1, 200);

    final page2 = browseHref(Uri.parse('$remoteBase/opds?page=2'));
    final (status2, body2, _) = await get(page2);
    expect(status2, 200);
    expect(body2, contains('Page 2'));
    // `_feedPage2` links only forward, but klos remembers where the reader
    // came from and still offers a working Back button.
    expect(
      body2,
      contains('href="${browseHref(Uri.parse('$remoteBase/opds'))}"'),
    );

    final page3 = browseHref(Uri.parse('$remoteBase/opds?page=3'));
    final (_, body3, _) = await get(page3);
    expect(
      body3,
      contains('href="${browseHref(Uri.parse('$remoteBase/opds?page=2'))}"'),
    );
  });

  test('shows a search form when the catalog declares search', () async {
    final (status, body, _) = await get('/');
    expect(status, 200);
    expect(body, contains('action="/search"'));
    expect(body, contains('name="q"'));
    expect(body, contains('$remoteBase/opds/search?searchTerm={searchTerms}'));
  });

  test('runs a search query and renders the results', () async {
    final href = searchHref(
      '$remoteBase/opds/search?searchTerm={searchTerms}',
      'Шевченко',
    );
    final (status, body, _) = await get(href);
    expect(status, 200);
    expect(body, contains('Search Results'));
    expect(body, contains('Found Book'));
    expect(body, contains('Результати пошуку'));
    expect(body, contains('value="Шевченко"'));

    expect(searchRequests, hasLength(1));
    expect(searchRequests.single.queryParameters['searchTerm'], 'Шевченко');
  });

  test('resolves the search template from an OpenSearch description', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () =>
          AppSettings(catalogUrl: Uri.parse('$remoteBase/osd-feed')),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/');
    expect(status, 200);
    expect(body, contains('action="/search"'));
    expect(body, contains('searchType=books'));
    expect(osdRequests, 1);

    // The resolved template is cached: another page load does not refetch it.
    await get('/');
    expect(osdRequests, 1);

    // Optional parameters are dropped when the query URL is built.
    final href = searchHref(
      '$remoteBase/opds/search?searchTerm={searchTerms}'
          '&searchType=books&pageNumber={startPage?}',
      'книга',
    );
    final (searchStatus, results, _) = await get(href);
    expect(searchStatus, 200);
    expect(results, contains('Search Results'));
    expect(searchRequests.single.queryParameters, {
      'searchTerm': 'книга',
      'searchType': 'books',
    });
  });

  test('rejects a search without a template', () async {
    final (status, body, _) = await get('/search?q=book');
    expect(status, 400);
    expect(body, contains('шаблону пошуку'));
  });

  test('sends an empty query back to the catalog', () async {
    final template = Uri.encodeQueryComponent(
      '$remoteBase/opds/search?searchTerm={searchTerms}',
    );
    final raw = HttpClient();
    try {
      final request = await raw.getUrl(
        Uri.parse('http://127.0.0.1:${proxy.port}/search?u=$template&q='),
      );
      request.followRedirects = false;
      final response = await request.close();
      expect(response.statusCode, 302);
      expect(response.headers.value(HttpHeaders.locationHeader), '/');
      await response.drain<void>();
    } finally {
      raw.close(force: true);
    }
  });

  test('renders an OPDS 2.0 JSON catalog', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () =>
          AppSettings(catalogUrl: Uri.parse('$remoteBase/opds2')),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/');
    expect(status, 200);
    expect(body, contains('JSON Catalog'));
    expect(body, contains('JSON Book'));
    expect(body, contains('Json Author'));
    expect(body, contains('From JSON'));
    expect(body, contains('EPUB (завантажити)'));
    expect(body, contains('JSON Authors'));
    expect(body, contains('/browse?u='));
    expect(body, contains('/image?u='));
    expect(body, contains('action="/search"'));
    expect(body, contains('{?query}'));
  });

  test('runs an OPDS 2.0 search', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () =>
          AppSettings(catalogUrl: Uri.parse('$remoteBase/opds2')),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final href = searchHref('$remoteBase/opds2/search{?query}', 'json');
    final (status, body, _) = await get(href);

    expect(status, 200);
    expect(body, contains('JSON Found'));
    expect(body, contains('Результати пошуку'));
    expect(searchRequests, hasLength(1));
    expect(searchRequests.single.queryParameters['query'], 'json');
  });

  test('serves an SVG favicon and links it from every page', () async {
    final (status, body, _) = await get('/');
    expect(status, 200);
    expect(body, contains('rel="icon"'));
    expect(body, contains('/icon.svg'));

    final (iconStatus, svg, headers) = await get('/icon.svg');
    expect(iconStatus, 200);
    expect(headers.contentType?.mimeType, 'image/svg+xml');
    expect(svg, contains('<svg'));
    expect(svg, contains('</svg>'));
  });

  test('hides covers when the setting is off', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => AppSettings(
        catalogUrl: Uri.parse('$remoteBase/opds'),
        showCovers: false,
      ),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/');
    expect(status, 200);
    expect(body, contains('Fixture Book'));
    expect(body, isNot(contains('/image?u=')));
  });

  test('proxies a cover image through /image', () async {
    final href = imageHref(
      Uri.parse('$remoteBase/cover.jpg'),
      type: 'image/jpeg',
    );
    final (status, bytes, headers) = await getBytes(href);

    expect(status, 200);
    expect(headers.contentType?.mimeType, 'image/jpeg');
    expect(utf8.decode(bytes), 'COVER-BYTES');
  });

  test('shows mail only for formats Kindle cannot open', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => AppSettings(
        catalogUrl: Uri.parse('$remoteBase/opds'),
        kindleEmail: 'reader@kindle.com',
        smtpHost: 'smtp.example.com',
        senderEmail: 'sender@example.com',
      ),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/');
    expect(status, 200);

    // MOBI is opened by the Kindle directly: only the download link.
    expect(body, contains('MOBI (завантажити)'));
    expect(body, isNot(contains('MOBI (на пошту)')));
    expect(body, isNot(contains('MOBI (на телефон)')));

    // EPUB cannot be opened directly: it is converted on download and can
    // also be emailed.
    expect(body, contains('EPUB (на пошту)'));
    expect(body, contains('EPUB (завантажити)'));
    expect(body, isNot(contains('EPUB (конвертувати)')));
    expect(body, isNot(contains('EPUB (на телефон)')));
    // The email button shows progress while the book is prepared, exactly
    // like the download button, so the tap is visible on the Kindle.
    expect(body, contains('data-klos-busy-label="Надсилання…"'));
  });

  test('browses a subsection by token', () async {
    final target = Uri.parse('$remoteBase/sub');
    final (status, body, _) = await get('/browse?u=${encodeTarget(target)}');
    expect(status, 200);
    expect(body, contains('Nested Book'));
  });

  test('renders an author biography without its HTML entity', () async {
    final target = Uri.parse('$remoteBase/author');
    final (status, body, _) = await get('/browse?u=${encodeTarget(target)}');
    expect(status, 200);
    expect(body, contains('Джо Аберкромби — писатель.'));
    // The feed double-escapes the non-breaking space, which used to appear as
    // a literal `&nbsp` in front of the author's name.
    expect(body, isNot(contains('&nbsp')));
    // The author's web page is not a book: no download or mail buttons.
    expect(body, isNot(contains('/download/')));
    expect(body, isNot(contains('/send/')));
  });

  test('serves the raw OPDS document', () async {
    final target = Uri.parse('$remoteBase/opds');
    final (status, body, headers) = await get(
      '/opds?u=${encodeTarget(target)}',
    );
    expect(status, 200);
    expect(headers.contentType?.mimeType, 'application/atom+xml');
    expect(body, contains('<feed'));
  });

  test('proxies a book download with a safe filename', () async {
    final target = Uri.parse('$remoteBase/book.pdf');
    final href = downloadHref(
      target,
      title: 'Fixture Book',
      type: 'application/pdf',
    );
    expect(
      Uri.parse(href).path,
      '/download/Fixture_Book.pdf',
      reason:
          'Kindle may use the URL basename instead of '
          'Content-Disposition',
    );

    final (status, body, headers) = await get(href);

    expect(status, 200);
    expect(body, 'PDF-BYTES');
    expect(headers.contentType?.mimeType, 'application/pdf');
    final disposition = headers.value('content-disposition') ?? '';
    expect(disposition, contains('filename="Fixture Book.pdf"'));
    expect(disposition, contains('filename*=UTF-8'));
  });

  test('passes Basic credentials to the OPDS server', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => AppSettings(
        catalogUrl: Uri.parse('$remoteBase/protected'),
        username: 'user',
        password: 'pass',
      ),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/');
    expect(status, 200);
    expect(body, contains('Protected Catalog'));
  });

  test('does not save a remote HTML login page as a book', () async {
    final href = downloadHref(
      Uri.parse('$remoteBase/login'),
      title: 'Book',
      type: 'application/epub+zip',
    );
    final (status, body, _) = await get(href);
    expect(status, 502);
    expect(body, contains('HTML-сторінку замість файлу'));
  });

  test('answers HEAD without downloading the remote file', () async {
    final target = Uri.parse('$remoteBase/book.epub');
    final href = downloadHref(
      target,
      title: 'Fixture Book',
      type: 'application/epub+zip',
    );
    final request = await client.headUrl(
      Uri.parse('http://127.0.0.1:${proxy.port}$href'),
    );
    final response = await request.close();
    await response.drain<void>();

    expect(response.statusCode, 200);
    expect(downloadRequests, 0);
    expect(
      response.headers.value('content-disposition'),
      contains('Fixture Book.epub'),
    );
  });

  test('returns 404 for unknown local paths', () async {
    final (status, body, _) = await get('/nope');
    expect(status, 404);
    expect(body, contains('не знайдено'));
  });

  test('lists the books saved in the app on /favorites', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () =>
          AppSettings(catalogUrl: Uri.parse('$remoteBase/opds')),
      log: logs.add,
      favoritesProvider: () => [
        Favorite(
          key: '$remoteBase/book.epub',
          title: 'Saved Book',
          author: 'Saved Author',
          links: [
            OpdsLink(
              href: Uri.parse('$remoteBase/book.epub'),
              rel: 'http://opds-spec.org/acquisition',
              type: 'application/epub+zip',
            ),
          ],
          addedAt: DateTime(2024),
        ),
      ],
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/favorites');
    expect(status, 200);
    expect(body, contains('Saved Book'));
    expect(body, contains('Saved Author'));
    expect(body, contains('/download/'));
    expect(body, contains('Обране'));
    expect(logs, contains(contains('Обране')));
  });

  test('explains that favorites are empty on the Kindle', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () =>
          AppSettings(catalogUrl: Uri.parse('$remoteBase/opds')),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/favorites/');
    expect(status, 200);
    expect(body, contains(l10n.favoritesEmptyOnKindleShort));
  });

  test('links the favorites page from the navigation bar', () async {
    final (_, body, _) = await get('/');
    expect(body, contains('href="/favorites"'));
  });

  test('renders an error page when the remote feed is unreachable', () async {
    await proxy.stop();

    // Find a free port, then close it so connection attempts are refused.
    final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final closedPort = probe.port;
    await probe.close(force: true);

    proxy = OpdsProxyServer(
      settingsProvider: () => AppSettings(
        catalogUrl: Uri.parse('http://127.0.0.1:$closedPort/opds'),
      ),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/');
    expect(status, 502);
    expect(body, contains('Помилка'));
  });

  test('logs a failed download, not only the error page', () async {
    await proxy.stop();

    // Find a free port, then close it so connection attempts are refused.
    final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final closedPort = probe.port;
    await probe.close(force: true);

    proxy = OpdsProxyServer(
      settingsProvider: () =>
          AppSettings(catalogUrl: Uri.parse('$remoteBase/opds')),
      log: logs.add,
    );
    await proxy.start(port: 0);

    logs.clear();
    final href = downloadHref(
      Uri.parse('http://127.0.0.1:$closedPort/book.epub'),
      title: 'Gone Book',
      type: 'application/epub+zip',
    );
    final (status, body, _) = await get(href);
    expect(status, 502);
    expect(body, contains('Помилка'));
    // Whatever the Kindle sees must also reach the in-app log.
    expect(logs.any((line) => line.contains('Помилка запиту')), isTrue);
  });

  test('renders mail and download links for an EPUB', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => _mailSettings(remoteBase),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/');
    expect(status, 200);
    expect(body, contains('/send/'));
    expect(body, contains('EPUB (на пошту)'));

    // EPUB cannot be opened directly: it is offered both for email and for
    // download (which converts it to MOBI). (The MOBI entry in the fixture
    // still gets only a plain download link, because the Kindle opens it
    // directly.)
    expect(body, contains('EPUB (завантажити)'));
    expect(body, contains('/download/Fixture_Book.epub'));
  });

  test('explains how to configure email when /send is opened', () async {
    final href = mailHref(
      Uri.parse('$remoteBase/book.epub'),
      title: 'Fixture Book',
      type: 'application/epub+zip',
    );
    final (status, body, _) = await get(href);
    expect(status, 400);
    expect(body, contains('Адресу Kindle не вказано'));
  });

  test('returns 404 for unknown mail job ids', () async {
    final (status, body, _) = await get('/mail/missing');
    expect(status, 404);
    expect(body, contains('не знайдено'));
  });

  test('queues a book email and shows the result', () async {
    final mailer = _ControlledMailer();
    addTearDown(() {
      if (!mailer.release.isCompleted) mailer.release.complete();
    });

    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => _mailSettings(remoteBase),
      log: logs.add,
      mailer: mailer,
    );
    await proxy.start(port: 0);

    final href = mailHref(
      Uri.parse('$remoteBase/book.epub'),
      title: 'Fixture Book',
      type: 'application/epub+zip',
    );
    final (status, body, headers) = await get(href);
    expect(status, 200);
    expect(headers.contentType?.mimeType, 'text/html');
    expect(body, contains('Fixture Book'));

    final match = RegExp(r'/mail/([A-Za-z0-9-]+)').firstMatch(body);
    expect(match, isNotNull, reason: 'the status page should link to the job');
    final id = match!.group(1)!;

    await mailer.started.future;
    mailer.release.complete();

    final finished = await waitForBody('/mail/$id', 'Лист надіслано');
    expect(finished, contains('Лист надіслано'));
    expect(finished, contains('reader@kindle.com'));
    expect(mailer.sent, ['Fixture Book']);
    expect(logs.any((line) => line.contains('надіслано')), isTrue);
  });

  test('answers HEAD on a mail link without sending a letter', () async {
    final mailer = _ControlledMailer();
    addTearDown(() {
      if (!mailer.release.isCompleted) mailer.release.complete();
    });

    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => _mailSettings(remoteBase),
      log: logs.add,
      mailer: mailer,
    );
    await proxy.start(port: 0);

    final href = mailHref(
      Uri.parse('$remoteBase/book.epub'),
      title: 'Fixture Book',
      type: 'application/epub+zip',
    );
    final request = await client.headUrl(
      Uri.parse('http://127.0.0.1:${proxy.port}$href'),
    );
    final response = await request.close();
    await response.drain<void>();

    expect(response.statusCode, 200);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(mailer.started.isCompleted, isFalse);
    expect(logs.where((line) => line.contains('у черзі')), isEmpty);
  });

  test('shows an SMTP error with a retry link on the status page', () async {
    final mailer = _ControlledMailer(
      failure: 'SMTP-сервер відхилив логін або пароль.',
    );
    addTearDown(() {
      if (!mailer.release.isCompleted) mailer.release.complete();
    });

    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => _mailSettings(remoteBase),
      log: logs.add,
      mailer: mailer,
    );
    await proxy.start(port: 0);

    final href = mailHref(
      Uri.parse('$remoteBase/book.epub'),
      title: 'Fixture Book',
      type: 'application/epub+zip',
    );
    final (status, body, _) = await get(href);
    expect(status, 200);

    final match = RegExp(r'/mail/([A-Za-z0-9-]+)').firstMatch(body);
    expect(match, isNotNull);

    await mailer.started.future;
    mailer.release.complete();

    final failed = await waitForBody(
      '/mail/${match!.group(1)}',
      'Не вдалося надіслати',
    );
    expect(failed, contains('SMTP-сервер відхилив логін або пароль.'));
    expect(failed, contains('Спробувати ще раз'));
    expect(failed, contains('/send/'));
  });

  test('converts an EPUB on download and returns MOBI bytes', () async {
    final href = downloadHref(
      Uri.parse('$remoteBase/convertible.epub'),
      title: 'Fixture Book',
      type: 'application/epub+zip',
    );
    final (status, bytes, headers) = await getBytes(href);

    expect(status, 200);
    expect(headers.contentType?.mimeType, 'application/x-mobipocket-ebook');
    expect(headers.value('content-disposition'), contains('Fixture Book.mobi'));
    expect(String.fromCharCodes(bytes.sublist(60, 68)), 'BOOKMOBI');

    var converted = false;
    for (var attempt = 0; attempt < 100 && !converted; attempt++) {
      converted = logs.any((line) => line.contains('Конвертація: готово'));
      if (!converted) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    }
    expect(converted, isTrue);
  });

  test('downloads a file once when the same link is pressed twice', () async {
    final href = downloadHref(
      Uri.parse('$remoteBase/slow-download.zip'),
      title: 'Slow ZIP',
      type: 'application/zip',
    );
    final before = downloadRequests;
    final responses = await Future.wait([getBytes(href), getBytes(href)]);

    expect(responses.every((response) => response.$1 == 200), isTrue);
    expect(downloadRequests - before, 1);
    expect(responses[0].$2, responses[1].$2);
  });

  test('converts a book once when the same link is pressed twice', () async {
    final href = downloadHref(
      Uri.parse('$remoteBase/slow.epub'),
      title: 'Slow Book',
      type: 'application/epub+zip',
    );
    final before = epubRequests;
    final responses = await Future.wait([getBytes(href), getBytes(href)]);

    expect(responses.every((response) => response.$1 == 200), isTrue);
    expect(epubRequests - before, 1);
    expect(responses[0].$2, responses[1].$2);
  });

  test('answers HEAD on /download without downloading the EPUB', () async {
    final href = downloadHref(
      Uri.parse('$remoteBase/convertible.epub'),
      title: 'Fixture Book',
      type: 'application/epub+zip',
    );
    final request = await client.headUrl(
      Uri.parse('http://127.0.0.1:${proxy.port}$href'),
    );
    final response = await request.close();
    await response.drain<void>();

    expect(response.statusCode, 200);
    expect(epubRequests, 0);
  });

  test('no longer exposes a separate conversion route', () async {
    final (status, _, _) = await get('/convert');
    expect(status, 404);
  });

  test('prepares a book and opens the mail app without SMTP', () async {
    final shared = <String>[];
    final shareDir = await Directory.systemTemp.createTemp('klos_share_test');
    addTearDown(() async {
      if (await shareDir.exists()) await shareDir.delete(recursive: true);
    });

    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => AppSettings(
        catalogUrl: Uri.parse('$remoteBase/opds'),
        kindleEmail: 'reader@kindle.com',
      ),
      log: logs.add,
      shareFile: (file, title, mime, to) async {
        shared.add('$title|$mime|$to|${file.path}');
      },
      shareDirectoryProvider: () async => shareDir,
    );
    await proxy.start(port: 0);

    final href = mailHref(
      Uri.parse('$remoteBase/convertible.epub'),
      title: 'Fixture Book',
      type: 'application/epub+zip',
    );
    final (status, body, _) = await get(href);

    expect(status, 200);
    expect(body, contains('Файл готовий'));
    expect(body, contains('reader@kindle.com'));
    expect(shared, hasLength(1));
    final parts = shared.single.split('|');
    expect(parts[0], 'Fixture Book');
    expect(parts[1], 'application/epub+zip');
    expect(parts[2], 'reader@kindle.com');
    final file = File(parts[3]);
    expect(await file.exists(), isTrue);
  });

  test(
    'refuses to open the mail app while klos is not in the foreground',
    () async {
      await proxy.stop();
      proxy = OpdsProxyServer(
        settingsProvider: () => AppSettings(
          catalogUrl: Uri.parse('$remoteBase/opds'),
          kindleEmail: 'reader@kindle.com',
        ),
        log: logs.add,
        shareFile: (file, title, mime, to) async {},
        canShare: () => false,
      );
      await proxy.start(port: 0);

      final href = mailHref(
        Uri.parse('$remoteBase/convertible.epub'),
        title: 'Fixture Book',
        type: 'application/epub+zip',
      );
      final (status, body, _) = await get(href);
      expect(status, 400);
      expect(body, contains('не відкритий'));
      expect(epubRequests, 0);
    },
  );

  test('refuses to email without a Kindle address', () async {
    final href = mailHref(
      Uri.parse('$remoteBase/convertible.epub'),
      title: 'Fixture Book',
      type: 'application/epub+zip',
    );
    final (status, body, _) = await get(href);
    expect(status, 400);
    expect(body, contains('Адресу Kindle не вказано'));
  });

  test('shows a converted download without a Kindle address', () async {
    final (status, body, _) = await get('/');
    expect(status, 200);
    expect(body, contains('EPUB (завантажити)'));
    expect(body, contains('/download/'));
    expect(body, contains('onclick="return klosBusy(this)"'));
    expect(body, isNot(contains('EPUB (на пошту)')));
    expect(body, isNot(contains('EPUB (конвертувати)')));
    expect(body, isNot(contains('/send/')));
  });

  test('shows «на пошту» with only a Kindle address', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => AppSettings(
        catalogUrl: Uri.parse('$remoteBase/opds'),
        kindleEmail: 'reader@kindle.com',
      ),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/');
    expect(status, 200);
    expect(body, contains('EPUB (на пошту)'));
    expect(body, contains('/send/'));
    expect(body, contains('EPUB (завантажити)'));
    expect(body, isNot(contains('EPUB (на телефон)')));
  });

  test('shows mail and a converted download together', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => AppSettings(
        catalogUrl: Uri.parse('$remoteBase/opds'),
        kindleEmail: 'reader@kindle.com',
        smtpHost: 'smtp.example.com',
        senderEmail: 'sender@example.com',
      ),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/');
    expect(status, 200);
    expect(body, contains('EPUB (на пошту)'));
    expect(body, contains('EPUB (завантажити)'));
    expect(body, isNot(contains('EPUB (конвертувати)')));
    expect(body, isNot(contains('EPUB (на телефон)')));
  });

  test('offers a download but no mail for a ZIP link', () async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => AppSettings(
        catalogUrl: Uri.parse('$remoteBase/opds'),
        kindleEmail: 'reader@kindle.com',
      ),
      log: logs.add,
    );
    await proxy.start(port: 0);

    final (status, body, _) = await get('/');
    expect(status, 200);
    expect(body, contains('ZIP (завантажити)'));
    // A ZIP may hold an FB2, which Amazon rejects by email, so klos never
    // offers send to Kindle for an archive.
    expect(body, isNot(contains('ZIP (на пошту)')));
    expect(body, isNot(contains('ZIP (конвертувати)')));
    expect(body, contains('data-klos-busy-label="Завантаження…"'));
    expect(body, isNot(contains('data-klos-busy-label="Конвертація…"')));
  });

  group('ZIP archives', () {
    test('converts a ZIP of EPUB on download', () async {
      final href = downloadHref(
        Uri.parse('$remoteBase/book.zip'),
        title: 'Zipped Book',
        type: 'application/zip',
      );
      final (status, bytes, headers) = await getBytes(href);

      expect(status, 200);
      expect(headers.contentType?.mimeType, 'application/x-mobipocket-ebook');
      expect(headers.value('content-disposition'), contains('.mobi'));
      expect(String.fromCharCodes(bytes.sublist(60, 68)), 'BOOKMOBI');
    });

    test('prefers a format the Kindle opens directly', () async {
      final href = downloadHref(
        Uri.parse('$remoteBase/book-mobi.zip'),
        title: 'Zipped Book',
        type: 'application/zip',
      );
      final (status, bytes, headers) = await getBytes(href);

      expect(status, 200);
      expect(headers.contentType?.mimeType, 'application/x-mobipocket-ebook');
      expect(headers.value('content-disposition'), contains('.mobi'));
      expect(bytes, utf8.encode('MOBI-BYTES'));
    });

    test('converts a ZIP of FB2 on download', () async {
      final href = downloadHref(
        Uri.parse('$remoteBase/book-fb2.zip'),
        title: 'Zipped Book',
        type: 'application/zip',
      );
      final (status, bytes, headers) = await getBytes(href);

      expect(status, 200);
      expect(headers.contentType?.mimeType, 'application/x-mobipocket-ebook');
      expect(headers.value('content-disposition'), contains('.mobi'));
      expect(String.fromCharCodes(bytes.sublist(60, 68)), 'BOOKMOBI');
    });

    test('detects a ZIP even when the server calls it EPUB', () async {
      final href = downloadHref(
        Uri.parse('$remoteBase/zipped.epub'),
        title: 'Zipped Book',
        type: 'application/epub+zip',
      );
      final (status, bytes, headers) = await getBytes(href);

      expect(status, 200);
      expect(headers.contentType?.mimeType, 'application/x-mobipocket-ebook');
      expect(bytes.length, greaterThan(64));
    });

    test('delivers a CBZ comic as is', () async {
      final href = downloadHref(
        Uri.parse('$remoteBase/comic.cbz'),
        title: 'Comic',
        type: 'application/x-cbz',
      );
      final (status, bytes, headers) = await getBytes(href);

      expect(status, 200);
      expect(headers.contentType?.mimeType, 'application/x-cbz');
      expect(headers.value('content-disposition'), contains('Comic.cbz'));
      expect(
        looksLikeZip(bytes),
        isTrue,
        reason: 'A CBZ must not be unpacked into page images',
      );
    });

    test('unpacks a ZIP of EPUB on download', () async {
      final href = downloadHref(
        Uri.parse('$remoteBase/book.zip'),
        title: 'Zipped Book',
        type: 'application/zip',
      );
      final (status, bytes, headers) = await getBytes(href);

      expect(status, 200);
      expect(headers.contentType?.mimeType, 'application/x-mobipocket-ebook');
      expect(bytes.length, greaterThan(64));
    });

    test('converts a bare FB2 file into MOBI', () async {
      final href = downloadHref(
        Uri.parse('$remoteBase/book.fb2'),
        title: 'FB2 Book',
        type: 'application/x-fictionbook+xml',
      );
      final (status, bytes, headers) = await getBytes(href);

      expect(status, 200);
      expect(headers.contentType?.mimeType, 'application/x-mobipocket-ebook');
      expect(headers.value('content-disposition'), contains('FB2 Book.mobi'));
      expect(String.fromCharCodes(bytes.sublist(60, 68)), 'BOOKMOBI');
    });

    test('attaches the unpacked EPUB to the mail app', () async {
      final shared = <String>[];
      final shareDir = await Directory.systemTemp.createTemp('klos_share_zip');
      addTearDown(() async {
        if (await shareDir.exists()) await shareDir.delete(recursive: true);
      });

      await proxy.stop();
      proxy = OpdsProxyServer(
        settingsProvider: () => AppSettings(
          catalogUrl: Uri.parse('$remoteBase/opds'),
          kindleEmail: 'reader@kindle.com',
        ),
        log: logs.add,
        shareFile: (file, title, mime, to) async {
          shared.add('$title|$mime|$to|${file.path}');
        },
        shareDirectoryProvider: () async => shareDir,
      );
      await proxy.start(port: 0);

      final href = mailHref(
        Uri.parse('$remoteBase/book.zip'),
        title: 'Zipped Book',
        type: 'application/zip',
      );
      final (status, body, _) = await get(href);

      expect(status, 200);
      expect(body, contains('Файл готовий'));
      expect(shared, hasLength(1));
      final parts = shared.single.split('|');
      expect(parts[0], 'Zipped Book');
      expect(parts[1], 'application/epub+zip');
      expect(parts[2], 'reader@kindle.com');
      final file = File(parts[3]);
      expect(await file.readAsBytes(), equals(_epubBytes()));
    });
  });
}
