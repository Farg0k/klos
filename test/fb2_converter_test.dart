import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klos/convert/book_converter.dart';
import 'package:klos/convert/fb2_to_mobi.dart';
import 'package:klos/convert/mobi_book.dart';

const _fb2 = '''
<?xml version="1.0" encoding="utf-8"?>
<FictionBook xmlns="http://www.gribuser.ru/xml/fictionbook/2.0">
  <description>
    <title-info>
      <book-title>Тестова книга</book-title>
      <lang>uk</lang>
      <author><first-name>Тарас</first-name><last-name>Шевченко</last-name></author>
    </title-info>
  </description>
  <body>
    <section>
      <title><p>Розділ</p></title>
      <p>Привіт, світе!</p>
    </section>
  </body>
</FictionBook>
''';

void main() {
  test('converts an FB2 document into a PalmDB MOBI', () {
    final mobi = convertFb2ToMobiSync(Uint8List.fromList(utf8.encode(_fb2)));

    expect(mobi.length, greaterThan(200));
    // PalmDB header: 32-byte name, 28 bytes of fields, then type/creator.
    expect(ascii.decode(mobi.sublist(60, 68)), 'BOOKMOBI');
    // The book title travels in the EXTH metadata as UTF-8.
    expect(utf8.decode(mobi, allowMalformed: true), contains('Тестова книга'));
  });

  test('unpacks .fb2.zip before converting', () {
    final bytes = utf8.encode(_fb2);
    final zip = ZipEncoder().encode(
      Archive()..addFile(ArchiveFile('book.fb2', bytes.length, bytes)),
    );

    final mobi = convertFb2ToMobiSync(Uint8List.fromList(zip));
    expect(ascii.decode(mobi.sublist(60, 68)), 'BOOKMOBI');
  });

  test('the dispatcher converts by MIME type and rejects the rest', () {
    final mobi = convertBookToMobiSync(
      Uint8List.fromList(utf8.encode(_fb2)),
      mime: 'application/x-fictionbook+xml',
    );
    expect(ascii.decode(mobi.sublist(60, 68)), 'BOOKMOBI');

    expect(
      () => convertBookToMobiSync(
        Uint8List.fromList(utf8.encode('PDF-BYTES')),
        mime: 'application/pdf',
      ),
      throwsA(isA<EpubConversionException>()),
    );
  });

  test('PalmDOC compression round-trips', () {
    final source = Uint8List.fromList(
      utf8.encode('аааааааааа привіт привіт привіт ' * 40),
    );
    final packed = palmDocCompress(source);

    expect(packed.length, lessThan(source.length));
    expect(_palmDocDecompress(packed), source);
  });
}

/// Reference PalmDOC (LZ77) decoder used to check [palmDocCompress].
Uint8List _palmDocDecompress(List<int> input) {
  final out = <int>[];
  var i = 0;
  while (i < input.length) {
    final c = input[i++];
    if (c == 0) {
      out.add(0);
    } else if (c >= 1 && c <= 8) {
      for (var j = 0; j < c && i < input.length; j++) {
        out.add(input[i++]);
      }
    } else if (c <= 0x7F) {
      out.add(c);
    } else if (c >= 0xC0) {
      out
        ..add(0x20)
        ..add(c ^ 0x80);
    } else {
      final code = (c << 8) | input[i++];
      final length = (code & 7) + 3;
      final distance = (code >> 3) & 0x7FF;
      final start = out.length - distance;
      for (var j = 0; j < length; j++) {
        out.add(out[start + j]);
      }
    }
  }
  return Uint8List.fromList(out);
}
