import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import '../books/ebook_archive.dart';
import '../l10n/l10n.dart';
import 'mobi_writer.dart';

/// A user-facing EPUB conversion problem.
class EpubFormatException implements Exception {
  EpubFormatException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Everything needed to write a MOBI file.
class EpubBook {
  const EpubBook({
    required this.title,
    this.author,
    this.language,
    required this.html,
    required this.images,
    this.coverIndex,
  });

  final String title;
  final String? author;
  final String? language;
  final String html;
  final List<MobiImage> images;

  /// Zero-based index of the cover image in [images].
  final int? coverIndex;
}

/// Parses an EPUB archive into a simplified, MOBI-friendly book.
///
/// This is intentionally not a full EPUB renderer. It keeps the reading order,
/// headings, basic formatting, tables and images. Scripts, styles, fonts and
/// complex layouts are dropped. DRM-protected books are rejected.
class EpubParser {
  EpubParser._(this._files, this._byLower);

  static const int _maxImageBytes = 20 * 1024 * 1024;
  static const int _maxTotalImageBytes = 64 * 1024 * 1024;
  static const int _maxEntryBytes = 32 * 1024 * 1024;
  static const int _maxTotalTextBytes = 96 * 1024 * 1024;
  static const int _maxZipEntries = 10000;
  static const int _maxLabelLength = 120;

  static const Set<String> _drmAlgorithms = {
    'http://www.idpf.org/2008/embedding',
    'http://ns.adobe.com/pdf/enc#RC',
  };

  final Map<String, ArchiveFile> _files;
  final Map<String, ArchiveFile> _byLower;

  static EpubBook parse(Uint8List bytes, {String? fallbackTitle}) {
    final declaredEntries = zipEntryCount(bytes);
    if (declaredEntries != null && declaredEntries > _maxZipEntries) {
      throw EpubFormatException(l10n.epubTooManyEntries);
    }

    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: false);
    } catch (error) {
      throw EpubFormatException(l10n.epubNotZip('$error'));
    }
    if (archive.files.length > _maxZipEntries) {
      throw EpubFormatException(l10n.epubTooManyEntries);
    }

    final files = <String, ArchiveFile>{};
    final byLower = <String, ArchiveFile>{};
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final name = _normalizeEntry(file.name);
      if (name.isEmpty) continue;
      files[name] = file;
      byLower[name.toLowerCase()] = file;
    }
    if (files.isEmpty) {
      throw EpubFormatException(l10n.epubEmpty);
    }

    return EpubParser._(files, byLower)._parse(fallbackTitle: fallbackTitle);
  }

  EpubBook _parse({String? fallbackTitle}) {
    _checkDrm();

    final opfPath = _findOpfPath();
    final opfFile = _file(opfPath);
    if (opfFile == null) {
      throw EpubFormatException(l10n.epubNoOpf);
    }

    final XmlDocument opf;
    try {
      opf = XmlDocument.parse(
        _decodeText(_entryBytes(opfFile, _maxEntryBytes)),
      );
    } on EpubFormatException {
      rethrow;
    } catch (error) {
      throw EpubFormatException(l10n.epubOpfFailed('$error'));
    }

    final opfDir = p.posix.dirname(opfPath);
    final baseDir = opfDir == '.' ? '' : opfDir;

    final metadata = _firstElement(opf, 'metadata');
    final title = _cleanText(
      _firstText(metadata, 'title') ?? fallbackTitle ?? '',
    );
    final safeTitle = title.isEmpty ? 'book' : title;
    final author = _cleanText(_firstText(metadata, 'creator') ?? '');
    final language = _cleanText(_firstText(metadata, 'language') ?? '');

    final manifest = <String, _ManifestItem>{};
    final manifestElement = _firstElement(opf, 'manifest');
    if (manifestElement != null) {
      for (final element in _descendants(manifestElement, 'item')) {
        final id = element.getAttribute('id')?.trim() ?? '';
        final href = element.getAttribute('href')?.trim() ?? '';
        if (id.isEmpty || href.isEmpty) continue;
        manifest[id] = _ManifestItem(
          id: id,
          href: href,
          mediaType: element.getAttribute('media-type')?.trim() ?? '',
          properties: element.getAttribute('properties')?.trim() ?? '',
        );
      }
    }
    if (manifest.isEmpty) {
      throw EpubFormatException(l10n.epubNoManifest);
    }

    final itemByPath = <String, _ManifestItem>{};
    for (final item in manifest.values) {
      final path = _resolveHref(baseDir, item.href);
      if (path != null) itemByPath[path] = item;
    }

    final spineIds = <String>[];
    final spineElement = _firstElement(opf, 'spine');
    if (spineElement != null) {
      for (final element in _descendants(spineElement, 'itemref')) {
        final idref = element.getAttribute('idref')?.trim() ?? '';
        if (idref.isEmpty) continue;
        final linear = element.getAttribute('linear')?.trim().toLowerCase();
        if (linear == 'no') continue;
        if (manifest.containsKey(idref)) spineIds.add(idref);
      }
    }
    if (spineIds.isEmpty) {
      for (final item in manifest.values) {
        if (_isHtml(item.mediaType) || _looksLikeHtml(item.href)) {
          spineIds.add(item.id);
        }
      }
    }
    if (spineIds.isEmpty) {
      throw EpubFormatException(l10n.epubNoText);
    }

    final images = <MobiImage>[];
    final imageIndexByPath = <String, int>{};
    var totalImageBytes = 0;

    int? addImage(String path, {String? declaredMime}) {
      final normalized = _normalizeEntry(path);
      final existing = imageIndexByPath[normalized];
      if (existing != null) return existing;

      final file = _file(normalized);
      if (file == null) return null;
      if (totalImageBytes + file.size > _maxTotalImageBytes) return null;
      final Uint8List? bytes;
      try {
        bytes = readArchiveEntry(file, maxBytes: _maxImageBytes);
      } catch (_) {
        return null;
      }
      if (bytes == null) return null;
      if (totalImageBytes + bytes.length > _maxTotalImageBytes) return null;
      final mime = _imageMime(bytes, declaredMime, normalized);
      if (mime == null) return null;

      final index = images.length;
      images.add(
        MobiImage(
          bytes: bytes,
          mimeType: mime,
          name: p.posix.basename(normalized),
        ),
      );
      totalImageBytes += bytes.length;
      imageIndexByPath[normalized] = index;
      return index;
    }

    // The cover must be the first image so the EXTH cover offset stays 0.
    final coverPath = _findCoverPath(manifest, metadata, baseDir);
    final coverItem = coverPath == null ? null : itemByPath[coverPath];
    final coverImageIndex = coverPath == null
        ? null
        : addImage(coverPath, declaredMime: coverItem?.mediaType);

    final chapters = <_Chapter>[];
    var coverReferencedInFirstChapter = false;
    var totalTextBytes = 0;

    for (final id in spineIds) {
      final item = manifest[id];
      if (item == null) continue;
      if (!_isHtml(item.mediaType) && !_looksLikeHtml(item.href)) continue;

      final path = _resolveHref(baseDir, item.href);
      if (path == null) continue;
      final file = _file(path);
      if (file == null) continue;

      final Uint8List bytes;
      try {
        bytes = _entryBytes(file, _maxEntryBytes);
      } on EpubFormatException {
        rethrow;
      } catch (_) {
        continue;
      }
      totalTextBytes += bytes.length;
      if (totalTextBytes > _maxTotalTextBytes) {
        throw EpubFormatException(l10n.epubExpandsTooMuch);
      }

      final dom.Document document;
      try {
        document = html_parser.parse(_decodeText(bytes));
      } catch (_) {
        continue;
      }

      final chapterDir = p.posix.dirname(path);
      final sanitizer = _HtmlSanitizer(
        resolveImage: (src) {
          final resolved = _resolveHref(chapterDir, src);
          if (resolved == null) return null;
          final imageItem = itemByPath[resolved];
          return addImage(resolved, declaredMime: imageItem?.mediaType);
        },
      );

      final html = sanitizer.sanitize(document);
      if (html.trim().isEmpty) continue;

      if (chapters.isEmpty &&
          coverImageIndex != null &&
          sanitizer.usedImages.contains(coverImageIndex)) {
        coverReferencedInFirstChapter = true;
      }

      chapters.add(
        _Chapter(
          id: 'ch${chapters.length}',
          label: _chapterLabel(document, item, chapters.length),
          html: html,
        ),
      );
    }

    if (chapters.isEmpty) {
      throw EpubFormatException(l10n.epubTextNotFound);
    }

    final includeCoverPage =
        coverImageIndex != null && !coverReferencedInFirstChapter;

    final html = _assembleHtml(
      title: safeTitle,
      author: author,
      chapters: chapters,
      coverPageIndex: includeCoverPage ? coverImageIndex : null,
    );

    return EpubBook(
      title: safeTitle,
      author: author.isEmpty ? null : author,
      language: language.isEmpty ? null : language,
      html: html,
      images: List.unmodifiable(images),
      coverIndex: coverImageIndex,
    );
  }

  void _checkDrm() {
    final file = _file('META-INF/encryption.xml');
    if (file == null) return;

    final Uint8List? bytes;
    try {
      bytes = readArchiveEntry(file, maxBytes: _maxEntryBytes);
    } catch (_) {
      return;
    }
    if (bytes == null) return;

    final XmlDocument document;
    try {
      document = XmlDocument.parse(_decodeText(bytes));
    } catch (_) {
      return;
    }

    for (final element in _descendants(document, 'EncryptionMethod')) {
      final algorithm = element.getAttribute('Algorithm')?.trim() ?? '';
      if (algorithm.isEmpty) continue;
      if (!_drmAlgorithms.contains(algorithm)) {
        throw EpubFormatException(l10n.epubDrm);
      }
    }
  }

  String _findOpfPath() {
    final container = _file('META-INF/container.xml');
    if (container != null) {
      Uint8List? bytes;
      try {
        bytes = readArchiveEntry(container, maxBytes: _maxEntryBytes);
      } catch (_) {
        bytes = null;
      }
      if (bytes != null) {
        try {
          final document = XmlDocument.parse(_decodeText(bytes));
          final rootfiles = _descendants(document, 'rootfile').toList();
          for (final rootfile in rootfiles) {
            final mediaType = rootfile.getAttribute('media-type') ?? '';
            if (!mediaType.contains('oebps-package')) continue;
            final path = rootfile.getAttribute('full-path')?.trim() ?? '';
            if (path.isNotEmpty) {
              return _normalizeEntry(_decodePath(path));
            }
          }
          for (final rootfile in rootfiles) {
            final path = rootfile.getAttribute('full-path')?.trim() ?? '';
            if (path.isNotEmpty) {
              return _normalizeEntry(_decodePath(path));
            }
          }
        } catch (_) {
          // Fall back to scanning the archive below.
        }
      }
    }

    for (final name in _files.keys) {
      if (name.toLowerCase().endsWith('.opf')) return name;
    }
    throw EpubFormatException(l10n.epubNoOpf);
  }

  String? _findCoverPath(
    Map<String, _ManifestItem> manifest,
    XmlElement? metadata,
    String baseDir,
  ) {
    for (final item in manifest.values) {
      if (!item.properties.split(RegExp(r'\s+')).contains('cover-image')) {
        continue;
      }
      return _resolveHref(baseDir, item.href);
    }

    if (metadata != null) {
      for (final element in _descendants(metadata, 'meta')) {
        final name = element.getAttribute('name')?.trim().toLowerCase();
        if (name != 'cover') continue;
        final content = element.getAttribute('content')?.trim() ?? '';
        final item = manifest[content];
        if (item == null) continue;
        return _resolveHref(baseDir, item.href);
      }
    }

    for (final item in manifest.values) {
      if (!item.mediaType.toLowerCase().startsWith('image/')) continue;
      final haystack = '${item.id} ${item.href}'.toLowerCase();
      if (!haystack.contains('cover')) continue;
      return _resolveHref(baseDir, item.href);
    }
    return null;
  }

  String _chapterLabel(dom.Document document, _ManifestItem item, int index) {
    for (final tag in const ['h1', 'h2', 'h3']) {
      final element = document.querySelector(tag);
      final text = _cleanText(element?.text ?? '');
      if (text.isNotEmpty) return _truncateLabel(text);
    }

    final title = _cleanText(document.querySelector('title')?.text ?? '');
    if (title.isNotEmpty) return _truncateLabel(title);

    if (item.id.isNotEmpty) return _truncateLabel(item.id);
    return l10n.epubChapter(index + 1);
  }

  ArchiveFile? _file(String path) {
    final normalized = _normalizeEntry(path);
    return _files[normalized] ?? _byLower[normalized.toLowerCase()];
  }

  /// Reads an entry with a size cap so a bomb cannot exhaust memory.
  static Uint8List _entryBytes(ArchiveFile file, int maxBytes) {
    final bytes = readArchiveEntry(file, maxBytes: maxBytes);
    if (bytes == null) {
      throw EpubFormatException(l10n.epubEntryTooLarge);
    }
    return bytes;
  }

  static Iterable<XmlElement> _descendants(XmlNode node, String localName) {
    return node.descendants.whereType<XmlElement>().where(
      (element) => element.name.local == localName,
    );
  }

  static XmlElement? _firstElement(XmlNode node, String localName) {
    for (final element in _descendants(node, localName)) {
      return element;
    }
    return null;
  }

  static String? _firstText(XmlNode? node, String localName) {
    if (node == null) return null;
    for (final element in _descendants(node, localName)) {
      final text = element.innerText.trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static String _normalizeEntry(String name) {
    var value = name.replaceAll('\\', '/').trim();
    while (value.startsWith('./')) {
      value = value.substring(2);
    }
    while (value.startsWith('/')) {
      value = value.substring(1);
    }
    if (value.isEmpty) return '';
    final normalized = p.posix.normalize(value);
    return normalized == '.' ? '' : normalized;
  }

  static String _decodePath(String value) {
    try {
      return Uri.decodeComponent(value);
    } on ArgumentError {
      return value;
    }
  }

  static String? _resolveHref(String baseDir, String href) {
    var value = href.trim();
    if (value.isEmpty) return null;
    final lower = value.toLowerCase();
    if (lower.startsWith('data:') ||
        lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('mailto:')) {
      return null;
    }

    final cut = value.indexOf(RegExp(r'[#?]'));
    if (cut >= 0) value = value.substring(0, cut);
    value = _decodePath(value).replaceAll('\\', '/');
    if (value.isEmpty) return null;
    while (value.startsWith('/')) {
      value = value.substring(1);
    }

    final joined = baseDir.isEmpty ? value : p.posix.join(baseDir, value);
    final normalized = p.posix.normalize(joined);
    if (normalized == '.' || normalized.startsWith('../')) return null;
    return normalized;
  }

  static bool _isHtml(String mime) {
    final value = mime.toLowerCase();
    return value.contains('xhtml') ||
        value.contains('html') ||
        value == 'application/xml';
  }

  static bool _looksLikeHtml(String href) {
    final lower = href.toLowerCase();
    return lower.endsWith('.xhtml') ||
        lower.endsWith('.html') ||
        lower.endsWith('.htm');
  }

  static String? _imageMime(Uint8List bytes, String? declared, String path) {
    final value = (declared ?? '').toLowerCase();
    if (value.contains('jpeg') || value.contains('jpg')) return 'image/jpeg';
    if (value.contains('png')) return 'image/png';
    if (value.contains('gif')) return 'image/gif';
    if (value.contains('svg')) return null;

    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'image/jpeg';
    }
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x38) {
      return 'image/gif';
    }

    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    return null;
  }

  static String _assembleHtml({
    required String title,
    required String author,
    required List<_Chapter> chapters,
    int? coverPageIndex,
  }) {
    const pageBreak = '<mbp:pagebreak/>\n';

    final prefix = StringBuffer()
      ..write('<html><head>')
      ..write(
        '<meta http-equiv="Content-Type" '
        'content="text/html; charset=utf-8"/>',
      )
      ..write('</head><body>\n')
      ..write('<h1>${_escapeHtml(title)}</h1>\n');
    if (author.isNotEmpty) {
      prefix.write('<p>${_escapeHtml(author)}</p>\n');
    }
    prefix.write(pageBreak);

    final entries = <_TocEntry>[];
    if (coverPageIndex != null) {
      entries.add(_TocEntry(id: 'cover', label: l10n.coverLabel));
    }
    for (final chapter in chapters) {
      entries.add(_TocEntry(id: chapter.id, label: chapter.label));
    }

    String renderToc(String Function(_TocEntry entry) positionFor) {
      final out = StringBuffer('<h2>${_escapeHtml(l10n.contentsLabel)}</h2>\n');
      for (final entry in entries) {
        out
          ..write('<p><a filepos="${positionFor(entry)}">')
          ..write(_escapeHtml(entry.label))
          ..write('</a></p>\n');
      }
      out.write(pageBreak);
      return out.toString();
    }

    // Every position is exactly ten digits.  The skeleton therefore has the
    // same byte length as the finished TOC, so offsets stay valid.
    final tocSkeleton = renderToc((_) => '0000000000');

    final suffix = <_Part>[];
    if (coverPageIndex != null) {
      suffix.add(const _Target('cover'));
      suffix.add(
        _Text(
          '<div><img recindex="${coverPageIndex + 1}" '
          'alt="${_escapeHtml(l10n.coverLabel)}"/></div>\n$pageBreak',
        ),
      );
    }
    for (final chapter in chapters) {
      suffix.add(_Target(chapter.id));
      suffix.add(_Text('${chapter.html}\n$pageBreak'));
    }
    suffix.add(const _Text('</body></html>\n'));

    final baseOffset = utf8.encode('$prefix$tocSkeleton').length;
    final offsets = <String, int>{};
    var offset = baseOffset;
    for (final part in suffix) {
      if (part is _Target) {
        offsets[part.id] = offset;
        offset += utf8.encode('<a name="${part.id}"></a>').length;
      } else if (part is _Text) {
        offset += utf8.encode(part.value).length;
      }
    }

    final toc = renderToc(
      (entry) => offsets[entry.id]!.toString().padLeft(10, '0'),
    );
    assert(
      utf8.encode(toc).length == utf8.encode(tocSkeleton).length,
      'TOC skeleton and finished TOC must have the same byte length',
    );

    final out = StringBuffer()
      ..write(prefix)
      ..write(toc);
    for (final part in suffix) {
      if (part is _Target) {
        out.write('<a name="${part.id}"></a>');
      } else if (part is _Text) {
        out.write(part.value);
      }
    }
    return out.toString();
  }

  static String _decodeText(Uint8List bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(Uint8List.sublistView(bytes, 3), allowMalformed: true);
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return _decodeUtf16(bytes, Endian.little);
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return _decodeUtf16(bytes, Endian.big);
    }

    final headLength = bytes.length < 512 ? bytes.length : 512;
    final head = latin1.decode(
      bytes.sublist(0, headLength),
      allowInvalid: true,
    );
    final match = RegExp(
      r'''(?:encoding\s*=\s*["']([A-Za-z0-9._-]+)["'])|'''
      r'''(?:charset\s*=\s*["']?([A-Za-z0-9._-]+))''',
      caseSensitive: false,
    ).firstMatch(head);
    final name = match?.group(1) ?? match?.group(2);
    final encoding = name == null ? null : Encoding.getByName(name);
    if (encoding != null && encoding != latin1) {
      try {
        return encoding.decode(bytes);
      } on FormatException {
        // Fall through to UTF-8 with replacement characters.
      }
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  static String _decodeUtf16(Uint8List bytes, Endian endian) {
    final data = ByteData.sublistView(bytes);
    final units = <int>[];
    for (var index = 2; index + 1 < bytes.length; index += 2) {
      units.add(data.getUint16(index, endian));
    }
    return String.fromCharCodes(units);
  }

  static String _cleanText(String value) {
    return value
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _truncateLabel(String value) {
    if (value.length <= _maxLabelLength) return value;
    return '${value.substring(0, _maxLabelLength - 3).trimRight()}...';
  }

  static String _escapeHtml(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}

class _ManifestItem {
  const _ManifestItem({
    required this.id,
    required this.href,
    required this.mediaType,
    required this.properties,
  });

  final String id;
  final String href;
  final String mediaType;
  final String properties;
}

class _Chapter {
  const _Chapter({required this.id, required this.label, required this.html});

  final String id;
  final String label;
  final String html;
}

class _TocEntry {
  const _TocEntry({required this.id, required this.label});

  final String id;
  final String label;
}

sealed class _Part {
  const _Part();
}

class _Text extends _Part {
  const _Text(this.value);

  final String value;
}

class _Target extends _Part {
  const _Target(this.id);

  final String id;
}

/// Converts EPUB XHTML into the small HTML subset that MOBI readers support.
class _HtmlSanitizer {
  _HtmlSanitizer({required this.resolveImage});

  final int? Function(String src) resolveImage;
  final Set<int> usedImages = {};
  final StringBuffer _out = StringBuffer();
  int _preDepth = 0;

  static const Set<String> _dropTags = {
    'script',
    'style',
    'noscript',
    'iframe',
    'object',
    'embed',
    'applet',
    'audio',
    'video',
    'canvas',
    'map',
    'area',
    'head',
    'title',
    'meta',
    'link',
    'base',
    'template',
    'form',
    'input',
    'button',
    'select',
    'option',
    'textarea',
    'frameset',
    'noframes',
    'param',
    'source',
    'track',
  };

  static const Set<String> _allowedTags = {
    'p',
    'div',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'blockquote',
    'pre',
    'ul',
    'ol',
    'li',
    'table',
    'thead',
    'tbody',
    'tfoot',
    'tr',
    'td',
    'th',
    'caption',
    'dl',
    'dt',
    'dd',
    'b',
    'strong',
    'i',
    'em',
    'u',
    's',
    'strike',
    'sub',
    'sup',
    'small',
    'big',
    'span',
    'code',
    'tt',
    'kbd',
    'var',
    'cite',
    'abbr',
    'acronym',
    'q',
    'mark',
    'ins',
    'del',
  };

  static const List<String> _keptAttributes = [
    'colspan',
    'rowspan',
    'start',
    'title',
  ];

  String sanitize(dom.Document document) {
    final body = document.body;
    if (body != null) {
      _writeChildren(body);
    } else {
      _writeChildren(document);
    }
    return _out.toString().trim();
  }

  void _writeChildren(dom.Node node) {
    for (final child in node.nodes) {
      _writeNode(child);
    }
  }

  void _writeNode(dom.Node node) {
    if (node is dom.Text) {
      var text = node.data;
      if (_preDepth == 0) {
        text = text
            .replaceAll('\u00A0', ' ')
            .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
            .replaceAll(RegExp(r' {2,}'), ' ');
      }
      _out.write(_escapeText(text));
      return;
    }
    if (node is! dom.Element) return;

    final tag = (node.localName ?? '').toLowerCase();
    if (_dropTags.contains(tag)) return;

    if (tag == 'img') {
      _writeImage(node);
      return;
    }
    if (tag == 'image') {
      _writeSvgImage(node);
      return;
    }
    if (tag == 'a') {
      _writeAnchor(node);
      return;
    }
    if (tag == 'br') {
      _out.write('<br/>');
      return;
    }
    if (tag == 'hr') {
      _out.write('<hr/>');
      return;
    }
    if (tag == 'pre') {
      _preDepth++;
      _out.write('<pre>');
      _writeChildren(node);
      _out.write('</pre>');
      _preDepth--;
      return;
    }

    if (_allowedTags.contains(tag)) {
      _out.write('<$tag');
      _writeAttributes(tag, node);
      _out.write('>');
      _writeChildren(node);
      _out.write('</$tag>');
    } else {
      _writeChildren(node);
    }
  }

  void _writeAttributes(String tag, dom.Element element) {
    if (tag != 'td' && tag != 'th' && tag != 'ol') return;
    for (final name in _keptAttributes) {
      final value = element.attributes[name]?.trim() ?? '';
      if (value.isEmpty) continue;
      _out.write(' $name="${_escapeAttribute(value)}"');
    }
  }

  void _writeImage(dom.Element element) {
    final src =
        element.attributes['src'] ?? element.attributes['data-src'] ?? '';
    final index = _indexFor(src);
    if (index == null) return;

    usedImages.add(index);
    _out.write('<img recindex="${index + 1}"');
    final alt = element.attributes['alt']?.trim() ?? '';
    if (alt.isNotEmpty) {
      _out.write(' alt="${_escapeAttribute(alt)}"');
    }
    _out.write('/>');
  }

  void _writeSvgImage(dom.Element element) {
    final href =
        element.attributes['xlink:href'] ?? element.attributes['href'] ?? '';
    final index = _indexFor(href);
    if (index == null) return;

    usedImages.add(index);
    _out.write('<img recindex="${index + 1}"/>');
  }

  int? _indexFor(String raw) {
    final src = raw.trim();
    if (src.isEmpty) return null;
    final lower = src.toLowerCase();
    if (lower.startsWith('data:') ||
        lower.startsWith('http://') ||
        lower.startsWith('https://')) {
      return null;
    }
    return resolveImage(src);
  }

  void _writeAnchor(dom.Element element) {
    final href = element.attributes['href']?.trim() ?? '';
    final lower = href.toLowerCase();
    final external =
        lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('mailto:');
    if (!external) {
      _writeChildren(element);
      return;
    }

    _out.write('<a href="${_escapeAttribute(href)}">');
    _writeChildren(element);
    _out.write('</a>');
  }

  static String _escapeText(String value) {
    return value
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }

  static String _escapeAttribute(String value) {
    return _escapeText(value).replaceAll('"', '&quot;');
  }
}
