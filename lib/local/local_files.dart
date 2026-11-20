import 'package:intl/intl.dart';

import '../books/ebook_formats.dart';
import '../l10n/l10n.dart';

/// MIME type Android's Storage Access Framework uses for a folder.
const String localDirectoryMime = 'vnd.android.document/directory';

/// One file or folder inside the folder chosen in the settings.
class LocalEntry {
  const LocalEntry({
    required this.name,
    required this.uri,
    this.mime = '',
    this.size = 0,
    this.isDirectory = false,
  });

  factory LocalEntry.fromMap(Map<Object?, Object?> map) {
    final rawMime = (map['mimeType'] as String? ?? '').trim();
    return LocalEntry(
      name: (map['name'] as String? ?? '').trim(),
      uri: (map['uri'] as String? ?? '').trim(),
      mime: rawMime,
      size: (map['size'] as num?)?.toInt() ?? 0,
      isDirectory: map['isDirectory'] == true || rawMime == localDirectoryMime,
    );
  }

  final String name;

  /// `content://` document URI that is valid only while the app keeps the
  /// persisted folder permission.
  final String uri;

  /// MIME type reported by the document provider; often
  /// `application/octet-stream`, so [effectiveMime] is usually better.
  final String mime;

  final int size;
  final bool isDirectory;

  /// MIME type with a fallback derived from the file extension.
  String get effectiveMime => localMimeFor(name, mime);

  /// File name without its extension, used as the book title.
  String get title => localBookTitle(name);
}

/// A folder chosen through the Storage Access Framework.
class LocalFolder {
  const LocalFolder({required this.uri, required this.name});

  final String uri;
  final String name;
}

/// A file klos wrote into the folder chosen in the settings.
class LocalSavedFile {
  const LocalSavedFile({required this.name, required this.uri});

  final String name;

  /// `content://` document URI of the written file.
  final String uri;
}

/// A folder above the one being browsed, plus the browsed folder's own name.
class LocalParent {
  const LocalParent({required this.uri, required this.name});

  final String uri;
  final String name;
}

/// A user-facing problem while reading the chosen folder.
class LocalStorageException implements Exception {
  LocalStorageException(this.message);

  final String message;

  @override
  String toString() => message;
}

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
  'zip',
};

const Map<String, String> _mimeByExtension = {
  'epub': 'application/epub+zip',
  'mobi': 'application/x-mobipocket-ebook',
  'azw': 'application/vnd.amazon.ebook',
  'azw3': 'application/x-mobi8-ebook',
  'pdf': 'application/pdf',
  'txt': 'text/plain',
  'fb2': 'application/x-fictionbook+xml',
  'djvu': 'image/vnd.djvu',
  'cbz': 'application/vnd.comicbook+zip',
  'rtf': 'application/rtf',
  'doc': 'application/msword',
  'docx':
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'html': 'text/html',
  'htm': 'text/html',
  'zip': 'application/zip',
};

/// Lower-case extension without the dot, or an empty string.
String localExtension(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0 || dot == name.length - 1) return '';
  return name.substring(dot + 1).toLowerCase();
}

/// Book title derived from the file name: the name without its extension.
String localBookTitle(String name) {
  final dot = name.lastIndexOf('.');
  if (dot <= 0) return name;
  return name.substring(0, dot).trim().isEmpty ? name : name.substring(0, dot);
}

/// Whether a file in the chosen folder is a book klos can list.
///
/// Folders are handled separately. Images, system files and partially
/// downloaded files are skipped so the Kindle page only shows useful items.
bool isLocalBookName(String name, {String? mime}) {
  if (name.isEmpty || name.startsWith('.')) return false;
  if (name.startsWith('~\$')) return false;
  final lower = name.toLowerCase();
  if (lower == 'thumbs.db' || lower == 'desktop.ini') return false;
  if (lower.startsWith('__macosx')) return false;
  if (_bookExtensions.contains(localExtension(name))) return true;
  return EbookFormat.match(mime) != null;
}

/// The best MIME type for a file in the chosen folder.
///
/// Providers often report `application/octet-stream` for ebooks, which hides
/// the format from the catalog, so the extension is used as a fallback.
String localMimeFor(String name, String? reported) {
  final clean = (reported ?? '').split(';').first.trim().toLowerCase();
  final usable =
      clean.isNotEmpty &&
      clean != 'application/octet-stream' &&
      clean != 'binary/octet-stream' &&
      clean != 'application/unknown';
  if (usable) return clean;
  return _mimeByExtension[localExtension(name)] ??
      (clean.isEmpty ? 'application/octet-stream' : clean);
}

/// Folders first, then names in case-insensitive alphabetical order.
int compareLocalEntries(LocalEntry a, LocalEntry b) {
  if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
  return a.name.toLowerCase().compareTo(b.name.toLowerCase());
}

/// Short localized file size for the catalog, or an empty string when unknown.
String formatFileSize(int bytes) {
  if (bytes <= 0) return '';
  const kb = 1024;
  const mb = 1024 * 1024;
  if (bytes < kb) return l10n.fileSizeBytes(bytes);
  if (bytes < mb) return l10n.fileSizeKb(_decimal(bytes / kb));
  return l10n.fileSizeMb(_decimal(bytes / mb));
}

String _decimal(double value) {
  return NumberFormat('0.#', L10n.languageCode).format(value);
}
