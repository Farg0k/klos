import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/convert/epub_converter.dart';
import 'package:klos/l10n/l10n.dart';

/// A valid 1x1 transparent PNG.
const _pngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8'
    'z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

const _container = '''<?xml version="1.0" encoding="utf-8"?>
<container version="1.0"
    xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf"
        media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

const _opf = '''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0"
    unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Тестова книга</dc:title>
    <dc:creator>Автор Тест</dc:creator>
    <dc:language>uk</dc:language>
    <meta name="cover" content="cover-image"/>
  </metadata>
  <manifest>
    <item id="cover-image" href="images/cover.png" media-type="image/png"/>
    <item id="ch1" href="chapter1.xhtml"
        media-type="application/xhtml+xml"/>
    <item id="ch2" href="text/chapter2.html"
        media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
    <itemref idref="ch2"/>
  </spine>
</package>''';

const _chapter1 = '''<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>Заголовок документа</title>
  <style>p { color: red; }</style>
  <script>alert(1)</script>
</head>
<body>
  <h1>Розділ перший</h1>
  <p>Привіт <b>світ</b> &amp; всі.</p>
  <p><img src="images/cover.png" alt="Обкладинка"/></p>
  <p><a href="chapter2.xhtml">Далі</a>
     <a href="https://example.com">сайт</a></p>
</body>
</html>''';

const _chapter2 = '''<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
<head><title>Другий</title></head>
<body>
  <h2>Розділ другий</h2>
  <p id="note"><img src="../images/cover.png"/> Кінець.</p>
</body>
</html>''';

void main() {
  setUpAll(() async {
    await L10n.use(const Locale('uk'));
  });

  test('converts a simple EPUB into a readable MOBI structure', () {
    final mobi = convertEpubSync(_buildEpub());

    expect(_ascii(mobi, 60, 4), 'BOOK');
    expect(_ascii(mobi, 64, 4), 'MOBI');

    final recordCount = _uint16(mobi, 76);
    expect(recordCount, greaterThanOrEqualTo(4));

    final recordOffsets = <int>[
      for (var i = 0; i < recordCount; i++) _uint32(mobi, 78 + i * 8),
    ];
    final record0 = recordOffsets.first;

    // PalmDOC header.
    expect(_uint16(mobi, record0), 1, reason: 'no compression');
    final textLength = _uint32(mobi, record0 + 4);
    final textRecordCount = _uint16(mobi, record0 + 8);
    expect(textRecordCount, greaterThan(0));

    // MOBI header.
    expect(_ascii(mobi, record0 + 16, 4), 'MOBI');
    expect(_uint32(mobi, record0 + 16 + 4), 232);
    expect(_uint32(mobi, record0 + 16 + 8), 2);
    expect(_uint32(mobi, record0 + 16 + 12), 65001);
    expect(_uint32(mobi, record0 + 16 + 20), 6);
    expect(_uint32(mobi, record0 + 16 + 92), 1 + textRecordCount);
    expect(_uint32(mobi, record0 + 16 + 112), 0x40);

    // EXTH metadata.
    final exthOffset = record0 + 16 + 232;
    expect(_ascii(mobi, exthOffset, 4), 'EXTH');
    final exthLength = _uint32(mobi, exthOffset + 4);
    final exthCount = _uint32(mobi, exthOffset + 8);
    final exthRecords = <int, Uint8List>{};
    var cursor = exthOffset + 12;
    final exthEnd = exthOffset + exthLength;
    for (var i = 0; i < exthCount; i++) {
      final type = _uint32(mobi, cursor);
      final length = _uint32(mobi, cursor + 4);
      exthRecords[type] = Uint8List.fromList(
        mobi.sublist(cursor + 8, cursor + length),
      );
      cursor += length;
    }
    expect(cursor, lessThanOrEqualTo(exthEnd));
    expect(utf8.decode(exthRecords[503]!), 'Тестова книга');
    expect(utf8.decode(exthRecords[100]!), 'Автор Тест');
    expect(utf8.decode(exthRecords[524]!), 'uk');
    expect(_uint32(exthRecords[201]!, 0), 0);
    expect(_uint32(exthRecords[202]!, 0), 0);

    final titleOffset = _uint32(mobi, record0 + 16 + 68);
    final titleLength = _uint32(mobi, record0 + 16 + 72);
    expect(
      utf8.decode(
        mobi.sublist(
          record0 + titleOffset,
          record0 + titleOffset + titleLength,
        ),
      ),
      'Тестова книга',
    );
    expect(
      titleOffset,
      16 + 232 + ((exthLength + 3) ~/ 4) * 4,
      reason: 'title follows the padded EXTH block',
    );

    // Rebuild the text stream from its records.
    final text = BytesBuilder(copy: false);
    for (var i = 1; i <= textRecordCount; i++) {
      final start = recordOffsets[i];
      final end = i + 1 < recordCount ? recordOffsets[i + 1] : mobi.length - 4;
      text.add(mobi.sublist(start, end));
    }
    final textBytes = text.takeBytes();
    expect(textBytes.length, textLength);
    final html = utf8.decode(textBytes);

    expect(html, contains('Розділ перший'));
    expect(html, contains('Розділ другий'));
    expect(html, contains('<b>світ</b>'));
    expect(html, contains('&amp; всі'));
    expect(html, isNot(contains('alert(1)')));
    expect(html, isNot(contains('color: red')));
    expect(html, contains('<img recindex="1" alt="Обкладинка"/>'));
    expect(html, contains('href="https://example.com"'));
    expect(html, isNot(contains('href="chapter2.xhtml"')));

    // Every generated TOC link is ten digits wide and points at an anchor.
    final tocLinks = RegExp(r'<a filepos="(\d{10})">([^<]+)</a>')
        .allMatches(html)
        .toList();
    expect(tocLinks, hasLength(2));
    for (final link in tocLinks) {
      final offset = int.parse(link.group(1)!);
      final remainder = utf8.decode(textBytes.sublist(offset));
      expect(remainder, startsWith('<a name="ch'));
    }

    // Cover is not duplicated when the first chapter already shows it.
    expect(html, isNot(contains('alt="Обкладинка"/></div>')));
  });

  test('rejects books protected by real DRM', () {
    final epub = _buildEpub(
      encryption:
          '<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:'
          'container"><EncryptedData xmlns="http://www.w3.org/2001/04/'
          'xmlenc#"><EncryptionMethod Algorithm="http://www.w3.org/2001/04/'
          'xmlenc#aes128-cbc"/></EncryptedData></encryption>',
    );

    expect(
      () => convertEpubSync(epub),
      throwsA(
        isA<EpubConversionException>().having(
          (error) => error.message,
          'message',
          contains('DRM'),
        ),
      ),
    );
  });

  test('rejects an EPUB entry that is too large to convert', () {
    final huge = '<html><body>${'x' * (33 * 1024 * 1024)}</body></html>';

    expect(
      () => convertEpubSync(_buildEpub(chapter1: huge)),
      throwsA(
        isA<EpubConversionException>().having(
          (error) => error.message,
          'message',
          contains('завеликий'),
        ),
      ),
    );
  });

  test('allows font obfuscation but still converts the text', () {
    final epub = _buildEpub(
      encryption:
          '<encryption xmlns="urn:oasis:names:tc:opendocument:xmlns:'
          'container"><EncryptedData xmlns="http://www.w3.org/2001/04/'
          'xmlenc#"><EncryptionMethod Algorithm="http://www.idpf.org/2008/'
          'embedding"/></EncryptedData></encryption>',
    );

    final mobi = convertEpubSync(epub);
    expect(mobi.length, greaterThan(100));
  });

  test('uses the fallback title when metadata has no title', () {
    final epub = _buildEpub(
      opf: _opf.replaceFirst('<dc:title>Тестова книга</dc:title>', ''),
    );
    final mobi = convertEpubSync(epub, fallbackTitle: 'Запасна назва');

    final recordCount = _uint16(mobi, 76);
    final record0 = _uint32(mobi, 78);
    final titleOffset = _uint32(mobi, record0 + 16 + 68);
    final titleLength = _uint32(mobi, record0 + 16 + 72);
    expect(
      utf8.decode(
        mobi.sublist(
          record0 + titleOffset,
          record0 + titleOffset + titleLength,
        ),
      ),
      'Запасна назва',
    );
    expect(recordCount, greaterThan(1));
  });
}

Uint8List _buildEpub({String? opf, String? encryption, String? chapter1}) {
  final archive = Archive();
  archive.add(ArchiveFile.string('mimetype', 'application/epub+zip'));
  archive.add(ArchiveFile.string('META-INF/container.xml', _container));
  archive.add(ArchiveFile.string('OEBPS/content.opf', opf ?? _opf));
  archive.add(
    ArchiveFile.string('OEBPS/chapter1.xhtml', chapter1 ?? _chapter1),
  );
  archive.add(ArchiveFile.string('OEBPS/text/chapter2.html', _chapter2));
  archive.add(
    ArchiveFile.bytes('OEBPS/images/cover.png', base64.decode(_pngBase64)),
  );
  if (encryption != null) {
    archive.add(ArchiveFile.string('META-INF/encryption.xml', encryption));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

String _ascii(Uint8List bytes, int offset, int length) {
  return ascii.decode(bytes.sublist(offset, offset + length));
}

int _uint16(Uint8List bytes, int offset) {
  return ByteData.sublistView(bytes).getUint16(offset);
}

int _uint32(Uint8List bytes, int offset) {
  return ByteData.sublistView(bytes).getUint32(offset);
}
