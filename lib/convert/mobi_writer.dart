import 'dart:convert';
import 'dart:typed_data';

import '../l10n/l10n.dart';

/// An image resource embedded into a MOBI file.
class MobiImage {
  const MobiImage({
    required this.bytes,
    required this.mimeType,
    required this.name,
  });

  final Uint8List bytes;
  final String mimeType;
  final String name;
}

/// Minimal MOBI 6 (KF7) writer.
///
/// It creates a PalmDB container with one uncompressed text stream, optional
/// image records and EXTH metadata. It is intentionally simple: no DRM, no
/// Huffman compression, no NCX index. Old Kindle firmware reads this format;
/// complex EPUB layouts are simplified by [EpubParser].
class MobiWriter {
  static const int _recordSize = 4096;
  static const int _mobiHeaderLength = 232;
  static const int _palmEpochOffset = 2082844800; // 1904-01-01 → 1970-01-01

  static Uint8List build({
    required String title,
    String? author,
    String? language,
    required String html,
    List<MobiImage> images = const [],
    int? coverIndex,
  }) {
    final safeTitle = title.trim().isEmpty ? 'book' : title.trim();
    final titleBytes = Uint8List.fromList(utf8.encode(safeTitle));
    final textBytes = Uint8List.fromList(utf8.encode(html));

    if (textBytes.length > 128 * 1024 * 1024) {
      throw FormatException(l10n.mobiTextTooLarge);
    }

    final textRecords = <Uint8List>[];
    for (var offset = 0; offset < textBytes.length; offset += _recordSize) {
      final end = offset + _recordSize;
      textRecords.add(
        Uint8List.sublistView(
          textBytes,
          offset,
          end < textBytes.length ? end : textBytes.length,
        ),
      );
    }
    if (textRecords.isEmpty) {
      textRecords.add(Uint8List.fromList(utf8.encode('<p></p>')));
    }

    final firstImageIndex = images.isEmpty
        ? 0xFFFFFFFF
        : 1 + textRecords.length;
    final lastContentRecord = images.isEmpty
        ? textRecords.length
        : firstImageIndex + images.length - 1;

    final exth = _buildExth(
      title: safeTitle,
      author: author,
      language: language,
      coverIndex: coverIndex,
    );

    final fullNameOffset = 16 + _mobiHeaderLength + exth.length;
    final mobiHeader = _buildMobiHeader(
      uniqueId: DateTime.now().millisecondsSinceEpoch & 0x7FFFFFFF,
      firstNonBookIndex: 1 + textRecords.length,
      fullNameOffset: fullNameOffset,
      fullNameLength: titleBytes.length,
      firstImageIndex: firstImageIndex,
      lastContentRecord: lastContentRecord,
    );

    final palmdoc = Uint8List(16);
    final pd = ByteData.sublistView(palmdoc);
    pd.setUint16(0, 1); // no compression
    pd.setUint16(2, 0);
    pd.setUint32(4, textBytes.length);
    pd.setUint16(8, textRecords.length);
    pd.setUint16(10, _recordSize);
    pd.setUint16(12, 0); // no encryption
    pd.setUint16(14, 0);

    final recordZero = BytesBuilder(copy: false)
      ..add(palmdoc)
      ..add(mobiHeader)
      ..add(exth)
      ..add(titleBytes)
      ..add(const [0, 0]);
    while (recordZero.length % 4 != 0) {
      recordZero.addByte(0);
    }

    final records = <Uint8List>[
      recordZero.takeBytes(),
      ...textRecords,
      for (final image in images) image.bytes,
      Uint8List.fromList(const [0xE9, 0x8E, 0x0D, 0x0A]),
    ];

    return _buildPalmDatabase(title: safeTitle, records: records);
  }

  static Uint8List _buildMobiHeader({
    required int uniqueId,
    required int firstNonBookIndex,
    required int fullNameOffset,
    required int fullNameLength,
    required int firstImageIndex,
    required int lastContentRecord,
  }) {
    final header = Uint8List(_mobiHeaderLength);
    final data = ByteData.sublistView(header);

    header.setRange(0, 4, ascii.encode('MOBI'));
    data.setUint32(4, _mobiHeaderLength);
    data.setUint32(8, 2); // Mobipocket book
    data.setUint32(12, 65001); // UTF-8
    data.setUint32(16, uniqueId);
    data.setUint32(20, 6); // MOBI 6
    for (var offset = 24; offset <= 60; offset += 4) {
      data.setUint32(offset, 0xFFFFFFFF); // no indexes
    }
    data.setUint32(64, firstNonBookIndex);
    data.setUint32(68, fullNameOffset);
    data.setUint32(72, fullNameLength);
    data.setUint32(76, 1033); // en-US locale
    data.setUint32(80, 0);
    data.setUint32(84, 0);
    data.setUint32(88, 6); // minimum version
    data.setUint32(92, firstImageIndex);
    data.setUint32(96, 0); // huffman record
    data.setUint32(100, 0); // huffman count
    data.setUint32(104, 0); // huffman table
    data.setUint32(108, 0); // huffman length
    data.setUint32(112, 0x40); // EXTH present
    data.setUint32(148, 0xFFFFFFFF); // unknown
    data.setUint32(152, 0xFFFFFFFF); // DRM offset
    data.setUint32(156, 0xFFFFFFFF); // DRM count
    data.setUint32(160, 0); // DRM size
    data.setUint32(164, 0); // DRM flags
    data.setUint16(176, 1); // first content record
    data.setUint16(178, lastContentRecord);
    data.setUint32(180, 1); // unknown
    data.setUint32(184, 0xFFFFFFFF); // FCIS record
    data.setUint32(188, 0); // FCIS count
    data.setUint32(192, 0xFFFFFFFF); // FLIS record
    data.setUint32(196, 0); // FLIS count
    data.setUint32(208, 0xFFFFFFFF); // unknown
    data.setUint32(212, 0); // compilation sections
    data.setUint32(216, 0xFFFFFFFF);
    data.setUint32(220, 0xFFFFFFFF);
    data.setUint32(224, 0); // extra record data flags
    data.setUint32(228, 0xFFFFFFFF); // INDX record
    return header;
  }

  static Uint8List _buildExth({
    required String title,
    String? author,
    String? language,
    int? coverIndex,
  }) {
    final records = <int, List<int>>{
      501: ascii.encode('EBOK'),
      503: utf8.encode(title),
      204: _uint32(201), // creator software: kindlegen-like
      205: _uint32(1),
      206: _uint32(2),
      207: _uint32(33307),
    };

    final authorText = author?.trim() ?? '';
    if (authorText.isNotEmpty) {
      records[100] = utf8.encode(authorText);
    }
    final languageText = _normalizeLanguage(language);
    if (languageText != null) {
      records[524] = utf8.encode(languageText);
    }
    if (coverIndex != null) {
      // Cover and thumbnail offsets are zero-based relative to the first
      // image record.
      records[201] = _uint32(coverIndex);
      records[202] = _uint32(coverIndex);
    }

    final types = records.keys.toList()..sort();
    final body = BytesBuilder(copy: false);
    for (final type in types) {
      final value = records[type]!;
      body
        ..add(_uint32(type))
        ..add(_uint32(8 + value.length))
        ..add(value);
    }

    final bodyBytes = body.takeBytes();
    final header = BytesBuilder(copy: false)
      ..add(ascii.encode('EXTH'))
      ..add(_uint32(12 + bodyBytes.length))
      ..add(_uint32(types.length))
      ..add(bodyBytes);
    while (header.length % 4 != 0) {
      header.addByte(0);
    }
    return header.takeBytes();
  }

  static Uint8List _buildPalmDatabase({
    required String title,
    required List<Uint8List> records,
  }) {
    final name = _pdbName(title);
    final headerSize = 78 + records.length * 8 + 2;
    final output = BytesBuilder(copy: false);

    output.add(name);
    output
      ..add(_uint16(0)) // attributes
      ..add(_uint16(0)) // version
      ..add(_uint32(_palmTimestamp()))
      ..add(_uint32(_palmTimestamp()))
      ..add(_uint32(0)) // last backup
      ..add(_uint32(0)) // modification number
      ..add(_uint32(0)) // app info
      ..add(_uint32(0)) // sort info
      ..add(ascii.encode('BOOK'))
      ..add(ascii.encode('MOBI'))
      ..add(_uint32(0)) // unique id seed
      ..add(_uint32(0)) // next record list
      ..add(_uint16(records.length));

    var offset = headerSize;
    for (var index = 0; index < records.length; index++) {
      output
        ..add(_uint32(offset))
        ..addByte(0) // attributes
        ..add(_uint24(index)); // unique id
      offset += records[index].length;
    }
    output.add(_uint16(0)); // gap between record list and first record

    for (final record in records) {
      output.add(record);
    }
    return output.takeBytes();
  }

  static Uint8List _pdbName(String title) {
    final name = Uint8List(32);
    var encoded = utf8.encode(title);
    if (encoded.length > 31) {
      var end = 31;
      while (end > 0 && (encoded[end] & 0xC0) == 0x80) {
        end--;
      }
      encoded = encoded.sublist(0, end);
    }
    name.setRange(0, encoded.length, encoded);
    return name;
  }

  static int _palmTimestamp() {
    final seconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    return (seconds + _palmEpochOffset) & 0xFFFFFFFF;
  }

  static String? _normalizeLanguage(String? language) {
    final value = language?.trim().toLowerCase() ?? '';
    if (value.isEmpty) return null;
    final primary = value.split(RegExp(r'[-_]')).first;
    if (primary.length < 2 || primary.length > 3) return null;
    return primary;
  }

  static Uint8List _uint16(int value) {
    final bytes = Uint8List(2);
    ByteData.sublistView(bytes).setUint16(0, value);
    return bytes;
  }

  static Uint8List _uint24(int value) {
    return Uint8List.fromList([
      (value >> 16) & 0xFF,
      (value >> 8) & 0xFF,
      value & 0xFF,
    ]);
  }

  static Uint8List _uint32(int value) {
    final bytes = Uint8List(4);
    ByteData.sublistView(bytes).setUint32(0, value);
    return bytes;
  }
}
