import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/entity/app_settings.dart';
import 'package:klos/l10n/l10n.dart';
import 'package:klos/local/local_files.dart';
import 'package:klos/local/local_storage.dart';
import 'package:klos/mail/kindle_mailer.dart';
import 'package:klos/server/proxy_server.dart';
import 'package:klos/server/url_codec.dart';

const _authority = 'com.android.externalstorage.documents';
const _treeId = 'primary:Books';

final String _rootUri =
    'content://$_authority/tree/${Uri.encodeComponent(_treeId)}';

String _documentUri(String documentId) {
  return 'content://$_authority/tree/${Uri.encodeComponent(_treeId)}'
      '/document/${Uri.encodeComponent(documentId)}';
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
    <dc:title>Локальна книга</dc:title>
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

Uint8List _epubBytes() {
  final archive = Archive();
  archive.add(_stamped(ArchiveFile.string('mimetype', 'application/epub+zip')));
  archive.add(
    _stamped(ArchiveFile.string('META-INF/container.xml', _epubContainer)),
  );
  archive.add(_stamped(ArchiveFile.string('OEBPS/content.opf', _epubOpf)));
  archive.add(
    _stamped(
      ArchiveFile.string(
        'OEBPS/chapter1.xhtml',
        '<html><body><h1>Розділ</h1><p>Текст.</p></body></html>',
      ),
    ),
  );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

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
      <book-title>Місцева книга</book-title>
      <lang>uk</lang>
      <author><first-name>Леся</first-name><last-name>Українка</last-name></author>
    </title-info>
  </description>
  <body>
    <section><title><p>Розділ</p></title><p>Привіт, світе!</p></section>
  </body>
</FictionBook>
''';

Uint8List _fb2Bytes() => Uint8List.fromList(utf8.encode(_fb2Document));

LocalEntry _folder(String name) {
  final id = '$_treeId/$name';
  return LocalEntry(
    name: name,
    uri: _documentUri(id),
    mime: localDirectoryMime,
    isDirectory: true,
  );
}

LocalEntry _file(String name, {String mime = '', int size = 0}) {
  final id = '$_treeId/$name';
  return LocalEntry(name: name, uri: _documentUri(id), mime: mime, size: size);
}

/// In-memory folder tree with the same URI shape Android produces.
class _FakeLocalStorage implements LocalStorage {
  _FakeLocalStorage({required this.rootUri});

  final String rootUri;
  final Map<String, List<LocalEntry>> folders = {};
  final Map<String, Uint8List> files = {};
  final Map<String, String> folderNames = {};
  final List<String> readUris = [];
  final List<String> listUris = [];
  final List<LocalSavedFile> written = [];
  bool hasAccess = true;

  @override
  Future<LocalFolder?> pickFolder() async {
    return LocalFolder(uri: rootUri, name: 'Books');
  }

  @override
  Future<bool> checkAccess(String uri) async => hasAccess;

  @override
  Future<String?> folderName(String uri) async => null;

  @override
  Future<List<LocalEntry>> list(String uri) async {
    listUris.add(uri);
    if (!hasAccess) {
      throw LocalStorageException('Доступ до папки втрачено');
    }
    return folders[uri] ?? const [];
  }

  @override
  Future<Uint8List> read(String uri, {required int maxBytes}) async {
    readUris.add(uri);
    final bytes = files[uri];
    if (bytes == null) throw LocalStorageException('Файл не знайдено');
    if (bytes.length > maxBytes) {
      throw LocalStorageException('Файл завеликий');
    }
    return bytes;
  }

  @override
  Future<LocalSavedFile> write({
    required String folderUri,
    required String name,
    required String mime,
    required Uint8List bytes,
  }) async {
    final uri = _documentUri('$_treeId/$name');
    files[uri] = bytes;
    final saved = LocalSavedFile(name: name, uri: uri);
    written.add(saved);
    return saved;
  }

  @override
  Future<LocalParent?> parentOf({
    required String treeUri,
    required String uri,
  }) async {
    if (uri == treeUri) return null;
    final name = folderNames[uri];
    if (name == null) return null;
    return LocalParent(uri: treeUri, name: name);
  }
}

class _ControlledMailer extends KindleMailer {
  final started = Completer<void>();
  final release = Completer<void>();
  final titles = <String>[];
  final mimes = <String>[];
  final bytes = <Uint8List>[];

  @override
  Future<void> sendBookBytes({
    required AppSettings settings,
    required Uint8List bytes,
    String? title,
    String mime = 'application/octet-stream',
    void Function()? onSending,
  }) async {
    this.bytes.add(bytes);
    titles.add(title ?? '');
    mimes.add(mime);
    if (!started.isCompleted) started.complete();
    await release.future;
    onSending?.call();
  }
}

_FakeLocalStorage _fixtureStorage() {
  final storage = _FakeLocalStorage(rootUri: _rootUri);
  storage.folders[_rootUri] = [
    _folder('Sub'),
    _file('Book.mobi', mime: 'application/octet-stream', size: 2048),
    _file('Novel.epub', mime: 'application/epub+zip', size: 4096),
    _file('Comic.zip', mime: 'application/zip', size: 1024),
    _file('Fiction.fb2.zip', mime: 'application/zip', size: 2048),
    _file('notes.txt', size: 120),
    _file('Archive.fb2', mime: 'application/x-fictionbook+xml'),
    // Not books: filtered out of the Kindle page.
    _file('cover.jpg', mime: 'image/jpeg'),
    _file('.hidden.epub', mime: 'application/epub+zip'),
  ];
  final childUri = _documentUri('$_treeId/Sub');
  storage.folderNames[childUri] = 'Sub';
  storage.folders[childUri] = [_file('Nested.pdf', mime: 'application/pdf')];
  storage.files[_documentUri('$_treeId/Book.mobi')] = Uint8List.fromList(
    utf8.encode('MOBI-BYTES'),
  );
  storage.files[_documentUri('$_treeId/Novel.epub')] = _epubBytes();
  storage.files[_documentUri('$_treeId/Comic.zip')] = _zipBytes({
    'book.mobi': utf8.encode('ZIPPED-MOBI'),
  });
  storage.files[_documentUri('$_treeId/Fiction.fb2.zip')] = _zipBytes({
    'book.fb2': _fb2Bytes(),
  });
  storage.files[_documentUri('$_treeId/Archive.fb2')] = _fb2Bytes();
  storage.files[_documentUri('$_treeId/notes.txt')] = Uint8List.fromList(
    utf8.encode('TEXT'),
  );
  return storage;
}

void main() {
  setUpAll(() async {
    await L10n.use(const Locale('uk'));
  });

  late _FakeLocalStorage storage;
  late List<String> logs;
  late OpdsProxyServer proxy;
  late HttpClient client;

  AppSettings settingsFor({
    String? folderUri,
    String kindleEmail = '',
    String smtpHost = '',
    String senderEmail = '',
  }) {
    return AppSettings(
      catalogUrl: null,
      kindleEmail: kindleEmail,
      smtpHost: smtpHost,
      senderEmail: senderEmail,
      localFolderUri: folderUri ?? _rootUri,
      localFolderName: 'Books',
    );
  }

  Future<void> startProxy(
    AppSettings settings, {
    KindleMailer? mailer,
    Future<void> Function(File file, String title, String mime, String to)?
    shareFile,
    Future<Directory> Function()? shareDirectoryProvider,
    bool Function()? canShare,
  }) async {
    await proxy.stop();
    proxy = OpdsProxyServer(
      settingsProvider: () => settings,
      log: logs.add,
      localStorage: storage,
      mailer: mailer,
      shareFile: shareFile,
      shareDirectoryProvider: shareDirectoryProvider,
      canShare: canShare,
    );
    await proxy.start(port: 0);
  }

  setUp(() async {
    storage = _fixtureStorage();
    logs = [];
    proxy = OpdsProxyServer(
      settingsProvider: () => settingsFor(),
      log: logs.add,
      localStorage: storage,
    );
    await proxy.start(port: 0);
    client = HttpClient();
  });

  tearDown(() async {
    client.close(force: true);
    await proxy.stop();
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

  group('local folder page', () {
    test('shows the local folder at the root when no catalog is set', () async {
      final (status, body, _) = await get('/');

      expect(status, 200);
      expect(body, contains('<h1>Books</h1>'));
      expect(body, contains('Book.mobi'));
      expect(body, isNot(contains(l10n.notConfiguredBody)));
    });

    test('lists books and subfolders but hides other files', () async {
      final (status, body, _) = await get('/local');

      expect(status, 200);
      expect(body, contains('<h1>Books</h1>'));
      expect(body, contains('Sub'));
      expect(body, contains('Book.mobi'));
      expect(body, contains('Novel.epub'));
      expect(body, contains('Comic.zip'));
      expect(body, contains('notes.txt'));
      expect(body, contains('Archive.fb2'));
      expect(body, isNot(contains('cover.jpg')));
      expect(body, isNot(contains('.hidden.epub')));
      // The listing reads only the chosen folder.
      expect(storage.listUris, [_rootUri]);
    });

    test('marks the MOBI download as the primary action', () async {
      final (status, body, _) = await get('/local');
      expect(status, 200);

      final entry = body.substring(body.indexOf('Book.mobi'));
      final actions = entry.substring(entry.indexOf('<div class="actions">'));
      final primary = actions.indexOf('class="button primary"');

      expect(primary, isNot(-1));
      expect(primary, lessThan(actions.indexOf('MOBI (')));
      expect(actions, contains('MOBI (завантажити)'));
    });

    test('offers a converted download and mail for an EPUB', () async {
      await startProxy(
        settingsFor(
          kindleEmail: 'reader@kindle.com',
          smtpHost: 'smtp.example.com',
          senderEmail: 'sender@example.com',
        ),
      );

      final (status, body, _) = await get('/local');
      expect(status, 200);
      expect(body, contains('EPUB (на пошту)'));
      expect(body, contains('/local/send/'));
      expect(body, contains('EPUB (завантажити)'));
      expect(body, contains('/local/download/'));
      expect(body, isNot(contains('конвертувати')));
    });

    test(
      'offers a converted download for FB2 without a Kindle address',
      () async {
        final (status, body, _) = await get('/local');
        expect(status, 200);
        expect(body, contains('FB2 (завантажити)'));
        expect(body, isNot(contains('FB2 (на пошту)')));
        expect(body, isNot(contains('конвертувати')));
      },
    );

    test('offers no mail for FB2 even with a Kindle address', () async {
      await startProxy(
        settingsFor(
          kindleEmail: 'reader@kindle.com',
          smtpHost: 'smtp.example.com',
          senderEmail: 'sender@example.com',
        ),
      );

      final (status, body, _) = await get('/local');
      expect(status, 200);
      // Amazon rejects FB2 by email, so klos keeps only the converted download.
      expect(body, contains('FB2 (завантажити)'));
      expect(body, isNot(contains('FB2 (на пошту)')));
    });

    test('browses a subfolder and links back up', () async {
      final childUri = _documentUri('$_treeId/Sub');
      final (status, body, _) = await get(localDirHref(childUri));

      expect(status, 200);
      expect(body, contains('<h1>Sub</h1>'));
      expect(body, contains('Nested.pdf'));
      expect(body, contains('↑ Вгору'));
      expect(body, contains(localDirHref(_rootUri)));
      expect(storage.listUris, [childUri]);
    });

    test('rejects a folder link outside the chosen tree', () async {
      final outside = _documentUri('primary:Other/Secret');
      final (status, body, _) = await get(localDirHref(outside));

      expect(status, 400);
      expect(body, contains('не належить вибраній папці'));
      expect(storage.listUris, isEmpty);
    });

    test('rejects a link from another document authority', () async {
      final outside =
          'content://com.example.other/tree/${Uri.encodeComponent(_treeId)}'
          '/document/${Uri.encodeComponent('$_treeId/Book.mobi')}';
      final (status, body, _) = await get(localDirHref(outside));

      expect(status, 400);
      expect(body, contains('не належить вибраній папці'));
    });

    test('explains when no folder is connected yet', () async {
      await startProxy(settingsFor(folderUri: ''));
      final (status, body, _) = await get('/local');

      expect(status, 200);
      expect(body, contains('Папку ще не підключено'));
      expect(storage.listUris, isEmpty);
    });

    test('reports a lost folder permission', () async {
      storage.hasAccess = false;
      final (status, body, _) = await get('/local');

      expect(status, 403);
      expect(body, contains('Доступ до папки втрачено'));
    });
  });

  group('local files delivery', () {
    test('downloads a MOBI file from the folder', () async {
      final uri = Uri.parse(_documentUri('$_treeId/Book.mobi'));
      final href = localDownloadHref(
        uri,
        title: 'Book',
        type: 'application/x-mobipocket-ebook',
      );
      final (status, bytes, headers) = await getBytes(href);

      expect(status, 200);
      expect(bytes, utf8.encode('MOBI-BYTES'));
      expect(headers.contentType?.mimeType, 'application/x-mobipocket-ebook');
      expect(headers.value('content-disposition'), contains('Book.mobi'));
      expect(storage.readUris, [uri.toString()]);
    });

    test('takes the Kindle format out of a local ZIP', () async {
      final uri = Uri.parse(_documentUri('$_treeId/Comic.zip'));
      final href = localDownloadHref(
        uri,
        title: 'Comic',
        type: 'application/zip',
      );
      final (status, bytes, headers) = await getBytes(href);

      expect(status, 200);
      expect(bytes, utf8.encode('ZIPPED-MOBI'));
      expect(headers.contentType?.mimeType, 'application/x-mobipocket-ebook');
      expect(headers.value('content-disposition'), contains('Comic.mobi'));
    });

    test('refuses a download link outside the chosen folder', () async {
      final uri = Uri.parse(_documentUri('primary:Other/Secret.epub'));
      final href = localDownloadHref(uri, title: 'Secret');

      final (status, body, _) = await get(href);
      expect(status, 400);
      expect(body, contains('не належить вибраній папці'));
      expect(storage.readUris, isEmpty);
    });

    test('converts a local EPUB into MOBI on download', () async {
      final uri = Uri.parse(_documentUri('$_treeId/Novel.epub'));
      final href = localDownloadHref(
        uri,
        title: 'Novel',
        type: 'application/epub+zip',
      );
      final (status, bytes, headers) = await getBytes(href);

      expect(status, 200);
      expect(headers.contentType?.mimeType, 'application/x-mobipocket-ebook');
      expect(headers.value('content-disposition'), contains('Novel.mobi'));
      expect(String.fromCharCodes(bytes.sublist(60, 68)), 'BOOKMOBI');
      expect(storage.readUris, [uri.toString()]);
    });

    test('converts a local FB2 into MOBI on download', () async {
      final uri = Uri.parse(_documentUri('$_treeId/Archive.fb2'));
      final href = localDownloadHref(
        uri,
        title: 'Archive',
        type: 'application/x-fictionbook+xml',
      );
      final (status, bytes, headers) = await getBytes(href);

      expect(status, 200);
      expect(headers.contentType?.mimeType, 'application/x-mobipocket-ebook');
      expect(headers.value('content-disposition'), contains('Archive.mobi'));
      expect(String.fromCharCodes(bytes.sublist(60, 68)), 'BOOKMOBI');
      expect(storage.readUris, [uri.toString()]);
    });

    test('converts a local ZIP of FB2 on download', () async {
      final uri = Uri.parse(_documentUri('$_treeId/Fiction.fb2.zip'));
      final href = localDownloadHref(
        uri,
        title: 'Fiction',
        type: 'application/zip',
      );
      final (status, bytes, headers) = await getBytes(href);

      expect(status, 200);
      expect(headers.contentType?.mimeType, 'application/x-mobipocket-ebook');
      expect(headers.value('content-disposition'), contains('Fiction.mobi'));
      expect(String.fromCharCodes(bytes.sublist(60, 68)), 'BOOKMOBI');
    });

    test('no longer exposes a separate conversion route', () async {
      final (status, _, _) = await get('/local/convert');
      expect(status, 404);
    });

    test('emails a local EPUB and shows the result', () async {
      final mailer = _ControlledMailer();
      addTearDown(() {
        if (!mailer.release.isCompleted) mailer.release.complete();
      });

      await startProxy(
        settingsFor(
          kindleEmail: 'reader@kindle.com',
          smtpHost: 'smtp.example.com',
          senderEmail: 'sender@example.com',
        ),
        mailer: mailer,
      );

      final uri = Uri.parse(_documentUri('$_treeId/Novel.epub'));
      final href = localMailHref(
        uri,
        title: 'Novel',
        type: 'application/epub+zip',
      );
      final (status, body, headers) = await get(href);

      expect(status, 200);
      expect(headers.contentType?.mimeType, 'text/html');
      final match = RegExp(r'/mail/([A-Za-z0-9-]+)').firstMatch(body);
      expect(
        match,
        isNotNull,
        reason: 'the status page should link to the job',
      );

      await mailer.started.future;
      mailer.release.complete();

      final finished = await waitForBody(
        '/mail/${match!.group(1)}',
        'Лист надіслано',
      );
      expect(finished, contains('Лист надіслано'));
      expect(finished, contains('reader@kindle.com'));
      expect(mailer.titles, ['Novel']);
      expect(mailer.mimes, ['application/epub+zip']);
      expect(mailer.bytes.single, _epubBytes());
    });

    test(
      'opens the mail app instead of SMTP when it is not configured',
      () async {
        final shared = <String>[];
        final shareDir = await Directory.systemTemp.createTemp('klos_local');
        addTearDown(() async {
          if (await shareDir.exists()) await shareDir.delete(recursive: true);
        });

        await startProxy(
          settingsFor(kindleEmail: 'reader@kindle.com'),
          shareFile: (file, title, mime, to) async {
            shared.add('$title|$mime|$to|${file.path}');
          },
          shareDirectoryProvider: () async => shareDir,
        );

        final uri = Uri.parse(_documentUri('$_treeId/Novel.epub'));
        final href = localMailHref(
          uri,
          title: 'Novel',
          type: 'application/epub+zip',
        );
        final (status, body, _) = await get(href);

        expect(status, 200);
        expect(body, contains('Файл готовий'));
        expect(body, contains('reader@kindle.com'));
        expect(shared, hasLength(1));

        final parts = shared.single.split('|');
        expect(parts[0], 'Novel');
        expect(parts[1], 'application/epub+zip');
        expect(parts[2], 'reader@kindle.com');
        final file = File(parts[3]);
        expect(await file.exists(), isTrue);
        expect(await file.readAsBytes(), _epubBytes());
      },
    );

    test('refuses to email without a Kindle address', () async {
      await startProxy(settingsFor());

      final uri = Uri.parse(_documentUri('$_treeId/Novel.epub'));
      final href = localMailHref(
        uri,
        title: 'Novel',
        type: 'application/epub+zip',
      );
      final (status, body, _) = await get(href);

      expect(status, 400);
      expect(body, contains('Адресу Kindle не вказано'));
      expect(storage.readUris, isEmpty);
    });
  });

  group('LocalStorage.isUnder', () {
    test('accepts the tree root and documents below it', () {
      expect(LocalStorage.isUnder(_rootUri, _rootUri), isTrue);
      expect(
        LocalStorage.isUnder(_rootUri, _documentUri('$_treeId/Book.mobi')),
        isTrue,
      );
      expect(
        LocalStorage.isUnder(_rootUri, _documentUri('$_treeId/Sub/Deep.epub')),
        isTrue,
      );
    });

    test('rejects another tree in the same provider', () {
      final other =
          'content://$_authority/tree/'
          '${Uri.encodeComponent('primary:Other')}';
      expect(LocalStorage.isUnder(_rootUri, other), isFalse);
      expect(
        LocalStorage.isUnder(
          _rootUri,
          _documentUri('primary:Other/Secret.epub'),
        ),
        isFalse,
      );
    });

    test('rejects similar-looking document ids and other authorities', () {
      expect(
        LocalStorage.isUnder(
          _rootUri,
          _documentUri('primary:Books2/Book.epub'),
        ),
        isFalse,
      );
      expect(
        LocalStorage.isUnder(
          _rootUri,
          'content://com.example.other/tree/'
          '${Uri.encodeComponent(_treeId)}/document/'
          '${Uri.encodeComponent('$_treeId/Book.mobi')}',
        ),
        isFalse,
      );
      expect(
        LocalStorage.isUnder(_rootUri, 'https://example.com/Book.mobi'),
        isFalse,
      );
      expect(LocalStorage.isUnder('', _rootUri), isFalse);
    });
  });

  group('local file helpers', () {
    test('picks a MIME type from the extension when needed', () {
      expect(
        localMimeFor('Book.mobi', 'application/octet-stream'),
        'application/x-mobipocket-ebook',
      );
      expect(localMimeFor('Book.epub', ''), 'application/epub+zip');
      expect(localMimeFor('notes.txt', ''), 'text/plain');
      expect(
        localMimeFor('Book.epub', 'application/epub+zip; charset=binary'),
        'application/epub+zip',
      );
    });

    test('lists only plausible books', () {
      expect(isLocalBookName('Book.epub'), isTrue);
      expect(isLocalBookName('notes.txt'), isTrue);
      expect(isLocalBookName('cover.jpg'), isFalse);
      expect(isLocalBookName('.hidden.epub'), isFalse);
      expect(isLocalBookName('report.pdf'), isTrue);
      expect(isLocalBookName('Thumbs.db'), isFalse);
      expect(isLocalBookName('~\$draft.docx'), isFalse);
      expect(
        isLocalBookName('без-розширення', mime: 'application/epub+zip'),
        isTrue,
      );
    });

    test('sorts folders first and formats sizes', () {
      final entries = [_file('b.epub'), _folder('A'), _file('C.epub')]
        ..sort(compareLocalEntries);

      expect(entries.map((entry) => entry.name), ['A', 'b.epub', 'C.epub']);
      expect(formatFileSize(0), '');
      expect(formatFileSize(512), contains('Б'));
      expect(formatFileSize(2048), contains('КБ'));
      expect(formatFileSize(3 * 1024 * 1024), contains('МБ'));
      expect(localBookTitle('Some Book.epub'), 'Some Book');
    });
  });
}
