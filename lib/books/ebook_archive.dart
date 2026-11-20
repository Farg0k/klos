import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../l10n/l10n.dart';

/// Why a book is being fetched.
///
/// A ZIP can hold several files, so the purpose decides which one is useful:
/// the Kindle wants a format it opens directly, Amazon wants a format it
/// accepts by mail, and the converter needs an EPUB.
enum BookPurpose { download, email, convert }

/// A ZIP archive that does not contain a usable book.
class BookArchiveException implements Exception {
  BookArchiveException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Bytes that should be delivered.
///
/// [mime] and [name] are set only when klos recognised a file inside a ZIP;
/// otherwise the caller keeps the MIME type it already knows.
class BookContent {
  const BookContent(this.bytes, {this.mime, this.name, this.extracted = false});

  final Uint8List bytes;
  final String? mime;
  final String? name;

  /// Whether the bytes were taken out of an archive.
  final bool extracted;
}

/// The largest single book that is unpacked from an archive.
const int maxArchiveBookBytes = 120 * 1024 * 1024;

/// The largest number of entries klos will look through in a ZIP archive.
///
/// The cap keeps a central directory with millions of tiny entries from
/// exhausting the phone's memory while the archive is only being inspected.
const int maxArchiveEntries = 20000;

/// Whether [bytes] start with a ZIP signature (an empty archive counts).
bool looksLikeZip(List<int> bytes) {
  if (bytes.length < 4) return false;
  if (bytes[0] != 0x50 || bytes[1] != 0x4B) return false;
  return (bytes[2] == 0x03 && bytes[3] == 0x04) ||
      (bytes[2] == 0x05 && bytes[3] == 0x06) ||
      (bytes[2] == 0x07 && bytes[3] == 0x08);
}

/// The number of entries declared in the ZIP end-of-central-directory record,
/// or null when it cannot be read.
///
/// Checked before the archive is decoded: a central directory with millions of
/// tiny entries would otherwise create all those objects just to be rejected.
int? zipEntryCount(Uint8List bytes) {
  if (bytes.length < 22) return null;
  final data = ByteData.sublistView(bytes);
  final lowest = bytes.length - 22 - 0xFFFF;
  for (var at = bytes.length - 22; at >= (lowest < 0 ? 0 : lowest); at--) {
    if (!_hasSignature(bytes, at, 0x06054b50)) continue;
    // A real record is the last thing before the optional comment.
    final commentLength = data.getUint16(at + 20, Endian.little);
    if (at + 22 + commentLength != bytes.length) continue;

    final count = data.getUint16(at + 10, Endian.little);
    if (count != 0xFFFF) return count;
    return _zip64EntryCount(bytes, data, at) ?? count;
  }
  return null;
}

int? _zip64EntryCount(Uint8List bytes, ByteData data, int endRecord) {
  final locator = endRecord - 20;
  if (locator < 0 || !_hasSignature(bytes, locator, 0x07064b50)) return null;

  final recordOffset = data.getUint64(locator + 8, Endian.little);
  if (recordOffset < 0 || recordOffset + 40 > bytes.length) return null;
  final record = recordOffset.toInt();
  if (!_hasSignature(bytes, record, 0x06064b50)) return null;

  final count = data.getUint64(record + 32, Endian.little);
  return count < 0 ? null : count;
}

bool _hasSignature(Uint8List bytes, int offset, int signature) {
  if (offset < 0 || offset + 4 > bytes.length) return false;
  return bytes[offset] == (signature & 0xFF) &&
      bytes[offset + 1] == ((signature >> 8) & 0xFF) &&
      bytes[offset + 2] == ((signature >> 16) & 0xFF) &&
      bytes[offset + 3] == ((signature >> 24) & 0xFF);
}

/// Reads a ZIP entry while stopping a suspicious expansion.
///
/// The archive package limits decoding to the size declared in the ZIP header,
/// but that number is only a claim: a malicious archive can understate it and
/// turn a small download into gigabytes of decompressed data. The entry is
/// therefore decoded into a buffer that refuses to grow past [maxBytes].
///
/// Returns null when the entry is larger than [maxBytes]. Decoding errors are
/// rethrown, so the caller can tell a bomb from a damaged archive.
Uint8List? readArchiveEntry(ArchiveFile file, {required int maxBytes}) {
  if (file.size > maxBytes) return null;
  final output = _LimitedMemoryOutput(maxBytes);
  try {
    file.decompress(output);
  } on _ArchiveExpansionLimit {
    return null;
  }
  return output.getBytes();
}

class _ArchiveExpansionLimit implements Exception {
  const _ArchiveExpansionLimit();
}

/// An in-memory output stream that throws instead of growing past [limit].
class _LimitedMemoryOutput extends OutputMemoryStream {
  _LimitedMemoryOutput(this.limit)
    : super(size: limit < 0x8000 ? limit : 0x8000);

  final int limit;

  void _check(int extra) {
    if (length + extra > limit) throw const _ArchiveExpansionLimit();
  }

  @override
  void reserve(int total) => super.reserve(total > limit ? limit : total);

  @override
  void writeByte(int value) {
    _check(1);
    super.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    super.writeBytes(bytes, length: length);
  }

  @override
  void writeBackReference(int distance, int count) {
    _check(count);
    super.writeBackReference(distance, count);
  }

  @override
  void writeStream(InputStream stream) {
    // A memory stream is copied without going through writeBytes.
    if (stream is InputMemoryStream) _check(stream.length);
    super.writeStream(stream);
  }
}

/// Returns the file that should be sent to the device.
///
/// A real EPUB (or a comic archive) is a ZIP too, so it is returned unchanged.
/// Other ZIPs are searched for a suitable book. When nothing suitable is
/// inside, a [BookArchiveException] with a human-readable reason is thrown.
BookContent resolveBook(
  Uint8List bytes, {
  required BookPurpose purpose,
  int maxBytes = maxArchiveBookBytes,
}) {
  if (!looksLikeZip(bytes)) {
    // FB2 is plain XML, so a bare (non-archive) book is recognised here and
    // reported to the caller, which needs the type to convert it.
    return BookContent(bytes, mime: _bareMime(bytes));
  }
  final declaredEntries = zipEntryCount(bytes);
  if (declaredEntries != null && declaredEntries > maxArchiveEntries) {
    throw BookArchiveException(l10n.zipTooManyEntries);
  }

  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes, verify: false);
  } catch (_) {
    throw BookArchiveException(l10n.zipBroken);
  }
  if (archive.files.length > maxArchiveEntries) {
    throw BookArchiveException(l10n.zipTooManyEntries);
  }

  final files = <ArchiveFile>[];
  for (final file in archive.files) {
    if (!_isUsable(file)) continue;
    files.add(file);
  }
  if (files.isEmpty) {
    throw BookArchiveException(l10n.zipNoUsableFiles);
  }

  // EPUB itself is a ZIP: it must be delivered as is, not unpacked. The
  // MIME type is still reported, because a server may label it as ZIP.
  if (_isEpub(files)) {
    return BookContent(bytes, mime: 'application/epub+zip');
  }

  final candidates = _candidates(files, purpose);
  if (candidates.isEmpty) {
    // A comic book (CBZ) is a ZIP full of images: there is no single book
    // inside to extract, so the file is delivered as it is.
    if (purpose == BookPurpose.download && _looksLikeComic(files)) {
      return BookContent(bytes);
    }
    throw BookArchiveException(_noBookMessage(purpose, files));
  }

  final ArchiveFile? chosen = _firstFitting(candidates, maxBytes);
  if (chosen == null) {
    throw BookArchiveException(l10n.zipTooLarge(_megabytes(maxBytes)));
  }

  final Uint8List? content;
  try {
    content = readArchiveEntry(chosen, maxBytes: maxBytes);
  } catch (_) {
    throw BookArchiveException(l10n.zipUnpackFailed(_baseName(chosen.name)));
  }
  if (content == null) {
    throw BookArchiveException(l10n.zipTooLarge(_megabytes(maxBytes)));
  }
  if (content.isEmpty) {
    throw BookArchiveException(l10n.zipEmptyFile(_baseName(chosen.name)));
  }

  final extension = _extension(chosen.name);
  final mime = _mimeForExtension(extension);
  if (mime == null) {
    throw BookArchiveException(l10n.zipUnknownFormat(_baseName(chosen.name)));
  }
  return BookContent(
    content,
    mime: mime,
    name: _normalize(chosen.name),
    extracted: true,
  );
}

const List<String> _downloadExtensions = ['mobi', 'azw3', 'azw', 'pdf', 'txt'];

const List<String> _emailExtensions = [
  'epub',
  'pdf',
  'txt',
  'rtf',
  'doc',
  'docx',
  'html',
  'htm',
];

const List<String> _convertExtensions = ['epub', 'fb2'];

const Set<String> _imageExtensions = {
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'bmp',
  'avif',
};

const Set<String> _bookExtensions = {
  'epub',
  'mobi',
  'azw',
  'azw3',
  'pdf',
  'txt',
  'fb2',
  'cbz',
  'rtf',
  'doc',
  'docx',
  'html',
  'htm',
  'djvu',
};

const Map<String, String> _mimeByExtension = {
  'epub': 'application/epub+zip',
  'mobi': 'application/x-mobipocket-ebook',
  'azw': 'application/vnd.amazon.ebook',
  'azw3': 'application/x-mobi8-ebook',
  'pdf': 'application/pdf',
  'txt': 'text/plain',
  'fb2': 'application/x-fictionbook+xml',
  'rtf': 'application/rtf',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'html': 'text/html',
  'htm': 'text/html',
};

List<String> _priorityFor(BookPurpose purpose) {
  switch (purpose) {
    case BookPurpose.download:
      return _downloadExtensions;
    case BookPurpose.email:
      return _emailExtensions;
    case BookPurpose.convert:
      return _convertExtensions;
  }
}

/// Files inside the archive that could be the book we are looking for,
/// best first.
List<ArchiveFile> _candidates(List<ArchiveFile> files, BookPurpose purpose) {
  final priority = _priorityFor(purpose);
  final candidates = <ArchiveFile>[];
  for (final file in files) {
    if (priority.contains(_extension(file.name))) candidates.add(file);
  }
  candidates.sort((a, b) {
    final left = priority.indexOf(_extension(a.name));
    final right = priority.indexOf(_extension(b.name));
    if (left != right) return left.compareTo(right);

    // A book in the archive root is more likely to be the book itself than
    // a bonus file deep in a subdirectory.
    final depth = _depth(a.name).compareTo(_depth(b.name));
    if (depth != 0) return depth;

    if (a.size != b.size) return a.size.compareTo(b.size);
    return a.name.compareTo(b.name);
  });
  return candidates;
}

bool _isUsable(ArchiveFile file) {
  if (!file.isFile) return false;
  final name = _normalize(file.name).trim();
  if (name.isEmpty) return false;
  if (name.toLowerCase().startsWith('__macosx/')) return false;
  final base = _baseName(name);
  if (base.isEmpty || base.startsWith('.')) return false;
  final lower = base.toLowerCase();
  if (lower == 'thumbs.db' || lower == 'desktop.ini') return false;
  if (_auxiliaryNames.contains(_stem(base).toLowerCase())) return false;
  return true;
}

/// Helper files that often sit next to a book but are not the book itself.
const Set<String> _auxiliaryNames = {
  'readme',
  'license',
  'licence',
  'copyright',
  'comicinfo',
};

ArchiveFile? _firstFitting(List<ArchiveFile> candidates, int maxBytes) {
  for (final file in candidates) {
    if (file.size <= maxBytes) return file;
  }
  return null;
}

bool _isEpub(List<ArchiveFile> files) {
  for (final file in files) {
    final name = _normalize(file.name).toLowerCase();
    if (name == 'meta-inf/container.xml') return true;
    if (name == 'mimetype' && file.size <= 64) {
      try {
        final bytes = readArchiveEntry(file, maxBytes: 64);
        if (bytes != null &&
            utf8.decode(bytes, allowMalformed: true).trim().toLowerCase() ==
                'application/epub+zip') {
          return true;
        }
      } catch (_) {
        // A broken mimetype entry is not a reason to reject the archive.
      }
    }
  }
  return false;
}

/// The MIME type of a book that is not an archive, or null when unknown.
///
/// FB2 is the only plain-XML book klos converts, so its root element is
/// enough to tell it apart before the file is handed to a converter.
String? _bareMime(Uint8List bytes) {
  return _looksLikeFb2(bytes) ? 'application/x-fictionbook+xml' : null;
}

bool _looksLikeFb2(Uint8List bytes) {
  final end = bytes.length < 4096 ? bytes.length : 4096;
  if (end == 0) return false;
  final head = latin1
      .decode(Uint8List.sublistView(bytes, 0, end), allowInvalid: true)
      .toLowerCase();
  return head.contains('<fictionbook');
}

/// A CBZ is a ZIP of page images, not a container for a book file.
bool _looksLikeComic(List<ArchiveFile> files) {
  var images = 0;
  var books = 0;
  for (final file in files) {
    final extension = _extension(file.name);
    if (_imageExtensions.contains(extension)) images++;
    if (_bookExtensions.contains(extension)) books++;
  }
  return images > 0 && books == 0;
}

String _noBookMessage(BookPurpose purpose, List<ArchiveFile> files) {
  final found = <String>{};
  for (final file in files) {
    final extension = _extension(file.name);
    if (extension.isNotEmpty) found.add(extension.toUpperCase());
  }
  final foundText = found.isEmpty
      ? ''
      : l10n.zipFound(found.take(6).join(', '));
  switch (purpose) {
    case BookPurpose.download:
      if (files.any((file) => _extension(file.name) == 'epub')) {
        return '${l10n.zipOnlyEpub}$foundText';
      }
      if (files.any((file) => _extension(file.name) == 'fb2')) {
        return '${l10n.zipOnlyFb2}$foundText';
      }
      return '${l10n.zipNoKindleFile}$foundText';
    case BookPurpose.email:
      return '${l10n.zipNoEmailFile}$foundText';
    case BookPurpose.convert:
      return '${l10n.zipNoConvertible}$foundText';
  }
}

String _normalize(String name) => name.replaceAll('\\', '/');

String _baseName(String name) {
  final normalized = _normalize(name);
  final slash = normalized.lastIndexOf('/');
  return slash < 0 ? normalized : normalized.substring(slash + 1);
}

String _stem(String base) {
  final dot = base.lastIndexOf('.');
  return dot <= 0 ? base : base.substring(0, dot);
}

int _depth(String name) {
  final normalized = _normalize(name);
  var depth = 0;
  for (final rune in normalized.codeUnits) {
    if (rune == 0x2f) depth++;
  }
  return depth;
}

String _extension(String name) {
  final base = _baseName(name);
  final dot = base.lastIndexOf('.');
  if (dot <= 0 || dot == base.length - 1) return '';
  return base.substring(dot + 1).toLowerCase();
}

String? _mimeForExtension(String extension) {
  return _mimeByExtension[extension];
}

int _megabytes(int bytes) => (bytes / (1024 * 1024)).round();
