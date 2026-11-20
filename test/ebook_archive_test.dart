import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/books/ebook_archive.dart';
import 'package:klos/l10n/l10n.dart';

Uint8List _zip(Map<String, List<int>> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    archive.add(ArchiveFile.bytes(entry.key, entry.value));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

Uint8List _withDeclaredEntryCount(Uint8List bytes, int count) {
  final copy = Uint8List.fromList(bytes);
  final data = ByteData.sublistView(copy);
  for (var at = copy.length - 22; at >= 0; at--) {
    if (copy[at] == 0x50 &&
        copy[at + 1] == 0x4B &&
        copy[at + 2] == 0x05 &&
        copy[at + 3] == 0x06) {
      data.setUint16(at + 10, count, Endian.little);
      return copy;
    }
  }
  throw StateError('no ZIP end record');
}

Uint8List _epub({String body = 'EPUB-CONTENT'}) {
  return _zip({
    'mimetype': utf8.encode('application/epub+zip'),
    'META-INF/container.xml': utf8.encode('<container/>'),
    'OEBPS/content.opf': utf8.encode('<package/>'),
    'OEBPS/chapter1.xhtml': utf8.encode('<html><body>$body</body></html>'),
  });
}

Matcher _archiveError(String needle) {
  return isA<BookArchiveException>().having(
    (error) => error.message,
    'message',
    contains(needle),
  );
}

void main() {
  setUpAll(() async {
    await L10n.use(const Locale('uk'));
  });

  group('looksLikeZip', () {
    test('recognizes ZIP signatures', () {
      expect(looksLikeZip([0x50, 0x4B, 0x03, 0x04]), isTrue);
      expect(looksLikeZip([0x50, 0x4B, 0x05, 0x06]), isTrue);
      expect(looksLikeZip([0x50, 0x4B, 0x07, 0x08]), isTrue);
    });

    test('rejects other bytes', () {
      expect(looksLikeZip(utf8.encode('EPUB-BYTES')), isFalse);
      expect(looksLikeZip([0x50, 0x4B]), isFalse);
      expect(looksLikeZip(const []), isFalse);
    });
  });

  group('readArchiveEntry', () {
    test('reads the entry count from the ZIP end record', () {
      final bytes = _zip({
        'a.txt': utf8.encode('a'),
        'b.txt': utf8.encode('b'),
      });

      expect(zipEntryCount(bytes), 2);
    });

    test('stops an entry that expands past its declared size', () {
      final file = ArchiveFile.noCompress('bomb.mobi', 10, Uint8List(200000));

      expect(readArchiveEntry(file, maxBytes: 1000), isNull);
    });

    test('rejects an entry whose declared size is too large', () {
      final file = ArchiveFile.noCompress('big.mobi', 5000, Uint8List(1));

      expect(readArchiveEntry(file, maxBytes: 1000), isNull);
    });

    test('reads a normal entry', () {
      final file = ArchiveFile.noCompress('book.txt', 5, utf8.encode('hello'));

      expect(utf8.decode(readArchiveEntry(file, maxBytes: 1000)!), 'hello');
    });
  });

  group('resolveBook', () {
    test('rejects an archive that declares too many entries', () {
      final bytes = _withDeclaredEntryCount(
        _zip({'book.mobi': utf8.encode('MOBI')}),
        25000,
      );

      expect(
        () => resolveBook(bytes, purpose: BookPurpose.download),
        throwsA(_archiveError('забагато')),
      );
    });

    test('passes bytes that are not a ZIP through', () {
      final bytes = Uint8List.fromList(utf8.encode('plain text'));
      final content = resolveBook(bytes, purpose: BookPurpose.download);

      expect(content.bytes, same(bytes));
      expect(content.mime, isNull);
      expect(content.extracted, isFalse);
    });

    test('extracts the EPUB from a ZIP', () {
      final epub = _epub();
      final archive = _zip({
        'notes.nfo': utf8.encode('not a book'),
        '__MACOSX/._book.epub': utf8.encode('junk'),
        '.DS_Store': utf8.encode('junk'),
        'folder/book.epub': epub,
      });

      final content = resolveBook(archive, purpose: BookPurpose.convert);

      expect(content.mime, 'application/epub+zip');
      expect(content.name, 'folder/book.epub');
      expect(content.bytes, equals(epub));
      expect(content.extracted, isTrue);
    });

    test('suggests conversion or mail for a ZIP of EPUB', () {
      final archive = _zip({'book.epub': _epub()});

      expect(
        () => resolveBook(archive, purpose: BookPurpose.download),
        throwsA(_archiveError('лише EPUB')),
      );
    });

    test('keeps a real EPUB untouched', () {
      final epub = _epub();
      final content = resolveBook(epub, purpose: BookPurpose.download);

      expect(content.bytes, equals(epub));
      expect(content.mime, 'application/epub+zip');
      expect(
        content.extracted,
        isFalse,
        reason: 'A real EPUB is not unpacked, so nothing was extracted',
      );
    });

    test('recognises a bare FB2 file', () {
      final fb2 = Uint8List.fromList(
        utf8.encode('<?xml version="1.0"?><FictionBook><body/></FictionBook>'),
      );

      final content = resolveBook(fb2, purpose: BookPurpose.convert);

      expect(content.mime, 'application/x-fictionbook+xml');
      expect(content.bytes, equals(fb2));
      expect(content.extracted, isFalse);
    });

    test('prefers a format the Kindle opens directly', () {
      final archive = _zip({
        'book.epub': _epub(),
        'book.mobi': utf8.encode('MOBI-BYTES'),
      });

      final content = resolveBook(archive, purpose: BookPurpose.download);

      expect(content.mime, 'application/x-mobipocket-ebook');
      expect(utf8.decode(content.bytes), 'MOBI-BYTES');
    });

    test('prefers the book in the archive root', () {
      final archive = _zip({
        'bonus/book.epub': utf8.encode('BONUS'),
        'book.epub': utf8.encode('MAIN'),
      });

      final content = resolveBook(archive, purpose: BookPurpose.convert);

      expect(utf8.decode(content.bytes), 'MAIN');
    });

    test('reports a ZIP that holds only an FB2', () {
      final archive = _zip({
        'book.fb2': utf8.encode('FB2-BYTES'),
        'cover.jpg': utf8.encode('COVER'),
      });

      expect(
        () => resolveBook(archive, purpose: BookPurpose.download),
        throwsA(_archiveError('лише FB2')),
      );
    });

    test('reports a ZIP with no Kindle format at all', () {
      final archive = _zip({
        'book.djvu': utf8.encode('DJVU-BYTES'),
        'cover.jpg': utf8.encode('COVER'),
      });

      expect(
        () => resolveBook(archive, purpose: BookPurpose.download),
        throwsA(_archiveError('Kindle відкриває')),
      );
    });

    test('extracts an FB2 from a ZIP for conversion', () {
      final fb2 = utf8.encode('<FictionBook><body/></FictionBook>');
      final archive = _zip({
        'book.fb2': fb2,
        'cover.jpg': utf8.encode('COVER'),
      });

      final content = resolveBook(archive, purpose: BookPurpose.convert);

      expect(content.mime, 'application/x-fictionbook+xml');
      expect(content.name, 'book.fb2');
      expect(content.bytes, equals(fb2));
      expect(content.extracted, isTrue);
    });

    test('reports a ZIP without anything to convert', () {
      final archive = _zip({
        'notes.txt': utf8.encode('NOTES'),
        'cover.jpg': utf8.encode('COVER'),
      });

      expect(
        () => resolveBook(archive, purpose: BookPurpose.convert),
        throwsA(_archiveError('немає EPUB або FB2')),
      );
    });

    test('does not send FB2 by mail', () {
      final archive = _zip({
        'book.fb2': utf8.encode('FB2-BYTES'),
        'cover.jpg': utf8.encode('COVER'),
      });

      expect(
        () => resolveBook(archive, purpose: BookPurpose.email),
        throwsA(_archiveError('Amazon')),
      );
    });

    test('sends EPUB by mail even when a TXT is present', () {
      final epub = _epub();
      final archive = _zip({
        'book.txt': utf8.encode('TEXT'),
        'book.epub': epub,
      });

      final content = resolveBook(archive, purpose: BookPurpose.email);

      expect(content.mime, 'application/epub+zip');
      expect(content.bytes, equals(epub));
    });

    test('needs an EPUB for conversion', () {
      final archive = _zip({
        'book.pdf': utf8.encode('PDF-BYTES'),
        'book.mobi': utf8.encode('MOBI-BYTES'),
      });

      expect(
        () => resolveBook(archive, purpose: BookPurpose.convert),
        throwsA(_archiveError('немає EPUB')),
      );
    });

    test('keeps a comic book (CBZ-like ZIP) as is', () {
      final comic = _zip({
        '001.jpg': utf8.encode('PAGE-1'),
        '002.png': utf8.encode('PAGE-2'),
        'readme.txt': utf8.encode('Scanned by a fan'),
      });

      final content = resolveBook(comic, purpose: BookPurpose.download);

      expect(content.bytes, same(comic));
      expect(content.mime, isNull);
    });

    test('refuses to mail a comic book', () {
      final comic = _zip({
        '001.jpg': utf8.encode('PAGE-1'),
        '002.png': utf8.encode('PAGE-2'),
      });

      expect(
        () => resolveBook(comic, purpose: BookPurpose.email),
        throwsA(_archiveError('Amazon')),
      );
    });

    test('honours the size limit', () {
      final archive = _zip({
        'book.epub': Uint8List.fromList(List.filled(100, 65)),
      });

      expect(
        () => resolveBook(archive, purpose: BookPurpose.convert, maxBytes: 10),
        throwsA(_archiveError('завеликий')),
      );
    });
  });
}
