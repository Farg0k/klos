// lib/convert/fb2_to_mobi.dart (public API)
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import 'fb2.dart';
import 'mobi_book.dart';

export 'mobi_book.dart' show MobiBook;

/// Synchronous conversion. Accepts .fb2 or .fb2.zip bytes (detected by the
/// "PK" signature) and returns .mobi bytes.
Uint8List convertFb2ToMobiSync(Uint8List input, {bool compress = true}) {
  var bytes = input;

  if (bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B) {
    final archive = ZipDecoder().decodeBytes(bytes);
    final f = archive.files.firstWhere(
      (f) => f.isFile && f.name.toLowerCase().endsWith('.fb2'),
      orElse: () => throw const FormatException('В архіві немає .fb2'),
    );
    bytes = Uint8List.fromList(f.content as List<int>);
  }

  final doc = XmlDocument.parse(decodeFb2Bytes(bytes));
  final book = Fb2Converter(doc).convert();
  return buildMobi(book, compress: compress);
}

/// The same, but on a separate isolate — does not block the UI.
Future<Uint8List> convertFb2ToMobi(Uint8List input, {bool compress = true}) =>
    Isolate.run(() => convertFb2ToMobiSync(input, compress: compress));
