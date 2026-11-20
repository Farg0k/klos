// lib/convert/mobi_book.dart
//
// A minimal MOBI writer (version 6, PalmDB + PalmDOC + MOBI + EXTH).
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

class MobiBook {
  MobiBook({
    required this.title,
    required this.author,
    required this.language,
    required this.html,
    this.images = const [],
    this.coverIndex,
  });

  final String title;
  final String author;
  final String language;

  /// HTML in MOBI style: <img recindex="00001"/>, <mbp:pagebreak/>.
  final String html;

  /// Images (JPEG/GIF) in recindex order (1-based in HTML).
  final List<Uint8List> images;

  /// 0-based cover index in [images].
  final int? coverIndex;
}

class _W {
  final _b = BytesBuilder();
  int get length => _b.length;
  void u8(int v) => _b.addByte(v & 0xFF);
  void u16(int v) {
    u8(v >> 8);
    u8(v);
  }

  void u32(int v) {
    u8(v >> 24);
    u8(v >> 16);
    u8(v >> 8);
    u8(v);
  }

  void bytes(List<int> l) => _b.add(l);
  void zeros(int n) => _b.add(Uint8List(n));
  void str(String s) => _b.add(ascii.encode(s));
  Uint8List take() => _b.toBytes();
}

const _recordSize = 4096;

Uint8List buildMobi(MobiBook book, {bool compress = true}) {
  final textBytes = Uint8List.fromList(utf8.encode(book.html));
  final chunks = _splitUtf8(textBytes, _recordSize);
  final textRecords = chunks
      .map((c) => compress ? palmDocCompress(c) : c)
      .toList();

  final firstImage = 1 + textRecords.length;
  final imgCount = book.images.length;
  final flisIdx = firstImage + imgCount;
  final fcisIdx = flisIdx + 1;
  final eofIdx = fcisIdx + 1;
  final totalRecords = eofIdx + 1;
  final lastContent = firstImage + imgCount - 1;

  final record0 = _buildRecord0(
    book: book,
    compress: compress,
    textLength: textBytes.length,
    textRecordCount: textRecords.length,
    firstImage: firstImage,
    lastContent: lastContent,
    flisIdx: flisIdx,
    fcisIdx: fcisIdx,
  );

  final flis = Uint8List.fromList([
    ...ascii.encode('FLIS'),
    0, 0, 0, 8, 0, 0x41, 0, 0, 0, 0, 0, 0, 0xFF, 0xFF, 0xFF, 0xFF, //
    0, 1, 0, 3, 0, 0, 0, 3, 0, 0, 0, 1, 0xFF, 0xFF, 0xFF, 0xFF,
  ]);

  final fcisW = _W()
    ..str('FCIS')
    ..u32(0x14)
    ..u32(0x10)
    ..u32(1)
    ..u32(0)
    ..u32(textBytes.length)
    ..u32(0)
    ..u32(0x20)
    ..u32(8)
    ..u16(1)
    ..u16(1)
    ..u32(0);
  final fcis = fcisW.take();

  final eof = Uint8List.fromList([0xE9, 0x8E, 0x0D, 0x0A]);

  final records = <Uint8List>[
    record0,
    ...textRecords,
    ...book.images,
    flis,
    fcis,
    eof,
  ];
  assert(records.length == totalRecords);

  // ---- PalmDB header ----
  final w = _W();
  final nameBytes = ascii.encode(_palmName(book.title));
  w.bytes(nameBytes);
  w.zeros(32 - nameBytes.length);
  w.u16(0); // attributes
  w.u16(0); // version
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2082844800;
  w.u32(now); // creation
  w.u32(now); // modification
  w.u32(0); // backup
  w.u32(0); // modification number
  w.u32(0); // app info
  w.u32(0); // sort info
  w.str('BOOK');
  w.str('MOBI');
  w.u32(2 * totalRecords - 1); // unique id seed
  w.u32(0); // next record list
  w.u16(totalRecords);

  var offset = 78 + 8 * totalRecords + 2;
  for (var i = 0; i < records.length; i++) {
    w.u32(offset);
    w.u8(0);
    w.u8(0);
    w.u16(2 * i); // 3-byte uid: a leading 0 byte + u16
    offset += records[i].length;
  }
  w.u16(0); // gap

  for (final r in records) {
    w.bytes(r);
  }
  return w.take();
}

Uint8List _buildRecord0({
  required MobiBook book,
  required bool compress,
  required int textLength,
  required int textRecordCount,
  required int firstImage,
  required int lastContent,
  required int flisIdx,
  required int fcisIdx,
}) {
  const mobiLen = 232;
  final exth = _buildExth(book);
  final nameBytes = utf8.encode(book.title);
  final fullNameOffset = 16 + mobiLen + exth.length;
  final imgCount = book.images.length;

  final w = _W();
  // PalmDOC header (16 bytes)
  w.u16(compress ? 2 : 1);
  w.u16(0);
  w.u32(textLength);
  w.u16(textRecordCount);
  w.u16(_recordSize);
  w.u16(0); // encryption
  w.u16(0);

  // MOBI header (232 bytes)
  w.str('MOBI');
  w.u32(mobiLen);
  w.u32(2); // type: mobi book
  w.u32(65001); // UTF-8
  w.u32(Random().nextInt(0x7FFFFFFF)); // uid
  w.u32(6); // version
  for (var i = 0; i < 10; i++) {
    w.u32(0xFFFFFFFF);
  }
  w.u32(flisIdx); // first non-book record
  w.u32(fullNameOffset);
  w.u32(nameBytes.length);
  w.u32(0x0409); // locale
  w.u32(0); // input language
  w.u32(0); // output language
  w.u32(6); // min version
  w.u32(imgCount > 0 ? firstImage : 0xFFFFFFFF);
  w.u32(0);
  w.u32(0);
  w.u32(0);
  w.u32(0);
  w.u32(0x40); // EXTH flags
  w.zeros(32);
  w.u32(0xFFFFFFFF);
  w.u32(0xFFFFFFFF); // DRM offset
  w.u32(0);
  w.u32(0);
  w.u32(0);
  w.zeros(8);
  w.u16(1); // first content record
  w.u16(lastContent);
  w.u32(1);
  w.u32(fcisIdx);
  w.u32(1);
  w.u32(flisIdx);
  w.u32(1);
  w.zeros(8);
  w.u32(0xFFFFFFFF);
  w.u32(0);
  w.u32(0xFFFFFFFF);
  w.u32(0xFFFFFFFF);
  w.u32(0); // extra data flags
  w.u32(0xFFFFFFFF); // INDX

  w.bytes(exth);
  w.bytes(nameBytes);
  final pad = (4 - (w.length % 4)) % 4;
  w.zeros(pad + 4);
  return w.take();
}

Uint8List _buildExth(MobiBook book) {
  final recs = <MapEntry<int, List<int>>>[];
  void add(int type, List<int> data) => recs.add(MapEntry(type, data));
  void addU32(int type, int v) =>
      add(type, [v >> 24 & 255, v >> 16 & 255, v >> 8 & 255, v & 255]);

  if (book.author.isNotEmpty) add(100, utf8.encode(book.author));
  add(503, utf8.encode(book.title));
  if (book.language.isNotEmpty) add(524, utf8.encode(book.language));
  if (book.coverIndex != null) {
    addU32(201, book.coverIndex!);
    addU32(202, book.coverIndex!);
  }

  final body = _W();
  for (final r in recs) {
    body.u32(r.key);
    body.u32(8 + r.value.length);
    body.bytes(r.value);
  }
  final bodyBytes = body.take();
  var len = 12 + bodyBytes.length;
  final pad = (4 - len % 4) % 4;
  len += pad;

  final w = _W()
    ..str('EXTH')
    ..u32(len)
    ..u32(recs.length)
    ..bytes(bodyBytes)
    ..zeros(pad);
  return w.take();
}

String _palmName(String title) {
  final s = title.runes
      .map((r) => (r >= 32 && r < 127) ? String.fromCharCode(r) : '_')
      .join();
  final t = s.length > 31 ? s.substring(0, 31) : s;
  return t.trim().isEmpty ? 'book' : t;
}

/// Splits UTF-8 into chunks of at most [size] bytes without breaking
/// multi-byte characters.
List<Uint8List> _splitUtf8(Uint8List data, int size) {
  final out = <Uint8List>[];
  var pos = 0;
  while (pos < data.length) {
    var end = min(pos + size, data.length);
    if (end < data.length) {
      while (end > pos && (data[end] & 0xC0) == 0x80) {
        end--;
      }
    }
    out.add(Uint8List.sublistView(data, pos, end));
    pos = end;
  }
  if (out.isEmpty) out.add(Uint8List(0));
  return out;
}

/// PalmDOC (LZ77) compression of a single record.
Uint8List palmDocCompress(Uint8List input) {
  final out = BytesBuilder();
  final n = input.length;
  var i = 0;

  bool isDirect(int c) => c == 0 || (c >= 9 && c <= 0x7F);

  while (i < n) {
    // 1) back-reference
    if (i > 0 && n - i >= 3) {
      var bestLen = 0;
      var bestDist = 0;
      final maxBack = min(i, 2047);
      for (var d = 1; d <= maxBack; d++) {
        var l = 0;
        while (l < 10 && i + l < n && input[i + l - d] == input[i + l]) {
          l++;
        }
        if (l > bestLen) {
          bestLen = l;
          bestDist = d;
          if (l == 10) break;
        }
      }
      if (bestLen >= 3) {
        final code = 0x8000 | (bestDist << 3) | (bestLen - 3);
        out.addByte(code >> 8);
        out.addByte(code & 0xFF);
        i += bestLen;
        continue;
      }
    }

    final c = input[i];

    // 2) space + a character in 0x40..0x7F
    if (c == 0x20 &&
        i + 1 < n &&
        input[i + 1] >= 0x40 &&
        input[i + 1] <= 0x7F) {
      out.addByte(input[i + 1] ^ 0x80);
      i += 2;
      continue;
    }

    // 3) plain byte
    if (isDirect(c)) {
      out.addByte(c);
      i++;
      continue;
    }

    // 4) literal block (1..8 bytes)
    var j = i;
    while (j < n && j - i < 8 && !isDirect(input[j])) {
      j++;
    }
    out.addByte(j - i);
    out.add(Uint8List.sublistView(input, i, j));
    i = j;
  }
  return out.toBytes();
}
