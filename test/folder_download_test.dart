import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/books/ebook_archive.dart';
import 'package:klos/books/kindle_file.dart';
import 'package:klos/entity/app_settings.dart';
import 'package:klos/local/folder_download.dart';
import 'package:klos/local/local_files.dart';
import 'package:klos/local/local_storage.dart';
import 'package:klos/opds/opds_feed.dart';

const String _mobiMime = 'application/x-mobipocket-ebook';
const String _folderUri =
    'content://com.android.externalstorage.documents/tree/primary%3ABooks';

const _settings = AppSettings(
  catalogUrl: null,
  localFolderUri: _folderUri,
  localFolderName: 'Books',
);

class _FakeStorage implements LocalStorage {
  final List<LocalSavedFile> written = [];
  final List<Uint8List> bytes = [];
  final List<String> mimes = [];

  @override
  Future<LocalFolder?> pickFolder() async => null;

  @override
  Future<bool> checkAccess(String uri) async => true;

  @override
  Future<String?> folderName(String uri) async => 'Books';

  @override
  Future<List<LocalEntry>> list(String uri) async => const [];

  @override
  Future<Uint8List> read(String uri, {required int maxBytes}) async =>
      Uint8List(0);

  @override
  Future<LocalSavedFile> write({
    required String folderUri,
    required String name,
    required String mime,
    required Uint8List bytes,
  }) async {
    written.add(LocalSavedFile(name: name, uri: '$folderUri/document/$name'));
    this.bytes.add(bytes);
    mimes.add(mime);
    return written.last;
  }

  @override
  Future<LocalParent?> parentOf({
    required String treeUri,
    required String uri,
  }) async => null;
}

OpdsEntry _entry({
  required String title,
  required String url,
  required String mime,
}) {
  return OpdsEntry(
    title: title,
    links: [
      OpdsLink(
        href: Uri.parse(url),
        rel: 'http://opds-spec.org/acquisition',
        type: mime,
      ),
    ],
  );
}

FolderDownloader _downloader(
  _FakeStorage storage,
  RemoteBook remote, {
  AppSettings settings = _settings,
  bool Function()? onLoad,
}) {
  return FolderDownloader(
    settings: settings,
    storage: storage,
    languageCode: 'en',
    load: (link) async {
      onLoad?.call();
      return remote;
    },
  );
}

Uint8List _zipBytes(Map<String, List<int>> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    final file = ArchiveFile.bytes(entry.key, entry.value);
    file.lastModTime = 0;
    file.creationTime = 0;
    archive.add(file);
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

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
    <dc:title>Книга</dc:title>
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

Uint8List _epubBytes() {
  final archive = Archive();
  for (final entry in {
    'mimetype': 'application/epub+zip',
    'META-INF/container.xml': _epubContainer,
    'OEBPS/content.opf': _epubOpf,
    'OEBPS/chapter1.xhtml':
        '<html><body><h1>Розділ</h1><p>Текст.</p></body></html>',
  }.entries) {
    final file = ArchiveFile.string(entry.key, entry.value);
    file.lastModTime = 0;
    file.creationTime = 0;
    archive.add(file);
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

const String _fb2Document = '''
<?xml version="1.0" encoding="utf-8"?>
<FictionBook xmlns="http://www.gribuser.ru/xml/fictionbook/2.0">
  <description>
    <title-info>
      <book-title>Книга</book-title>
      <lang>uk</lang>
      <author><first-name>Леся</first-name><last-name>Українка</last-name></author>
    </title-info>
  </description>
  <body>
    <section><title><p>Розділ</p></title><p>Привіт, світе!</p></section>
  </body>
</FictionBook>
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('saves a Kindle format untouched', () async {
    final storage = _FakeStorage();
    final mobi = Uint8List.fromList(utf8.encode('MOBI-BYTES'));
    final entry = _entry(
      title: 'Тест',
      url: 'https://catalog/books/book.mobi',
      mime: _mobiMime,
    );
    final downloader = _downloader(
      storage,
      RemoteBook(
        bytes: mobi,
        url: Uri.parse('https://catalog/books/book.mobi'),
        mime: _mobiMime,
      ),
    );

    final saved = await downloader.download(entry);

    expect(saved.mime, _mobiMime);
    expect(saved.name, 'Test.mobi');
    expect(storage.written.single.name, 'Test.mobi');
    expect(storage.bytes.single, mobi);
  });

  test('takes a MOBI out of a ZIP archive', () async {
    final storage = _FakeStorage();
    final mobi = Uint8List.fromList(utf8.encode('MOBI-BYTES'));
    final archive = _zipBytes({'book.mobi': mobi});
    final entry = _entry(
      title: 'Pack',
      url: 'https://catalog/books/pack.zip',
      mime: 'application/zip',
    );
    final downloader = _downloader(
      storage,
      RemoteBook(
        bytes: archive,
        url: Uri.parse('https://catalog/books/pack.zip'),
        mime: 'application/zip',
      ),
    );

    final saved = await downloader.download(entry);

    expect(saved.mime, _mobiMime);
    expect(saved.name, 'Pack.mobi');
    expect(storage.bytes.single, mobi);
  });

  test('converts an EPUB outside an archive into MOBI', () async {
    final storage = _FakeStorage();
    final epub = _epubBytes();
    final entry = _entry(
      title: 'Ebook',
      url: 'https://catalog/books/book.epub',
      mime: 'application/epub+zip',
    );
    final downloader = _downloader(
      storage,
      RemoteBook(
        bytes: epub,
        url: Uri.parse('https://catalog/books/book.epub'),
        mime: 'application/epub+zip',
      ),
    );

    final saved = await downloader.download(entry);

    expect(saved.mime, _mobiMime);
    expect(saved.name, 'Ebook.mobi');
    expect(storage.mimes.single, _mobiMime);
    expect(storage.bytes.single, isNotEmpty);
    expect(storage.bytes.single, isNot(epub));
  });

  test('converts an FB2 from a ZIP archive into MOBI', () async {
    final storage = _FakeStorage();
    final archive = _zipBytes({'book.fb2': utf8.encode(_fb2Document)});
    final entry = _entry(
      title: 'Fb2 pack',
      url: 'https://catalog/books/pack.zip',
      mime: 'application/zip',
    );
    final downloader = _downloader(
      storage,
      RemoteBook(
        bytes: archive,
        url: Uri.parse('https://catalog/books/pack.zip'),
        mime: 'application/zip',
      ),
    );

    final saved = await downloader.download(entry);

    expect(saved.mime, _mobiMime);
    expect(saved.name, 'Fb2 pack.mobi');
    expect(storage.mimes.single, _mobiMime);
    expect(storage.bytes.single, isNotEmpty);
  });

  test('refuses to download without a chosen folder', () async {
    final storage = _FakeStorage();
    var loaded = false;
    final entry = _entry(
      title: 'Book',
      url: 'https://catalog/books/book.mobi',
      mime: _mobiMime,
    );
    final downloader = _downloader(
      storage,
      RemoteBook(
        bytes: Uint8List.fromList([1, 2, 3]),
        url: Uri.parse('https://catalog/books/book.mobi'),
        mime: _mobiMime,
      ),
      settings: const AppSettings(catalogUrl: null),
      onLoad: () {
        loaded = true;
        return true;
      },
    );

    await expectLater(
      downloader.download(entry),
      throwsA(isA<LocalStorageException>()),
    );
    expect(storage.written, isEmpty);
    expect(loaded, isFalse);
  });

  test('reports an archive with no Kindle or convertible book', () async {
    final storage = _FakeStorage();
    final archive = _zipBytes({
      'comic.cbz': Uint8List.fromList([1, 2, 3]),
    });
    final entry = _entry(
      title: 'Comic',
      url: 'https://catalog/books/comic.zip',
      mime: 'application/zip',
    );
    final downloader = _downloader(
      storage,
      RemoteBook(
        bytes: archive,
        url: Uri.parse('https://catalog/books/comic.zip'),
        mime: 'application/zip',
      ),
    );

    await expectLater(
      downloader.download(entry),
      throwsA(isA<BookArchiveException>()),
    );
    expect(storage.written, isEmpty);
  });

  test('prefers a Kindle format, then a convertible one', () {
    final epub = OpdsLink(
      href: Uri.parse('https://catalog/book.epub'),
      rel: 'http://opds-spec.org/acquisition',
      type: 'application/epub+zip',
    );
    final mobi = OpdsLink(
      href: Uri.parse('https://catalog/book.mobi'),
      rel: 'http://opds-spec.org/acquisition',
      type: _mobiMime,
    );
    final pdf = OpdsLink(
      href: Uri.parse('https://catalog/book.pdf'),
      rel: 'http://opds-spec.org/acquisition',
      type: 'application/pdf',
    );
    final cover = OpdsLink(
      href: Uri.parse('https://catalog/cover.jpg'),
      rel: 'http://opds-spec.org/image',
      type: 'image/jpeg',
    );

    expect(FolderDownloader.preferredDownloadLink([epub, mobi, cover]), mobi);
    expect(FolderDownloader.preferredDownloadLink([epub, pdf]), pdf);
    expect(FolderDownloader.preferredDownloadLink([cover, epub]), epub);
    expect(FolderDownloader.preferredDownloadLink([cover]), isNull);
  });
}
