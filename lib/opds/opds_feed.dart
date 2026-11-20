import 'package:html/parser.dart' as html_parser;
import 'package:xml/xml.dart';

import '../l10n/l10n.dart';
import 'opensearch.dart';

const String _acquisitionRel = 'http://opds-spec.org/acquisition';

/// A link inside an OPDS entry or feed.
class OpdsLink {
  const OpdsLink({required this.href, this.rel = '', this.type, this.title});

  final Uri href;
  final String rel;
  final String? type;
  final String? title;

  bool get isAcquisition =>
      rel == 'enclosure' || rel.startsWith(_acquisitionRel);

  /// A plain web page rather than a book file.
  ///
  /// Flibusta's author page has a card titled «Об авторе» ("About the
  /// author") whose acquisition link points at the author's HTML page.
  /// Offering it as a book download would save a web page into the Kindle
  /// folder.
  bool get isWebPage => (type ?? '').toLowerCase().startsWith('text/html');

  /// Cover thumbnail. The current relation is
  /// `http://opds-spec.org/image/thumbnail`; older catalogs (for example
  /// Flibusta) still use the legacy `http://opds-spec.org/thumbnail`.
  bool get isThumbnail =>
      rel.startsWith('http://opds-spec.org/image/thumbnail') ||
      rel.startsWith('http://opds-spec.org/thumbnail');

  /// Full-size cover image (`http://opds-spec.org/image`).
  bool get isCover => rel.startsWith('http://opds-spec.org/image');

  bool get isNavigation {
    if (rel == 'subsection') return true;
    final value = (type ?? '').toLowerCase();
    if (value.contains('kind=navigation')) return true;
    // OPDS 2.0 navigation links point at other JSON documents.
    if (value.contains('+json')) return true;
    // Many servers (e.g. Flibusta) mark subcatalogs with a plain Atom type
    // and no `rel="subsection"`:
    //   <link href="/opds/authorsindex"
    //         type="application/atom+xml;profile=opds-catalog"/>
    // Book files never use the Atom media type, so this is safe.
    return value.contains('application/atom+xml');
  }
}

class OpdsEntry {
  const OpdsEntry({
    required this.title,
    this.author,
    this.summary,
    this.links = const [],
  });

  final String title;
  final String? author;
  final String? summary;
  final List<OpdsLink> links;

  List<OpdsLink> get navigationLinks =>
      links.where((link) => link.isNavigation).toList(growable: false);

  List<OpdsLink> get acquisitionLinks =>
      links.where((link) => link.isAcquisition).toList(growable: false);

  /// Acquisition links that actually point at a book file.
  ///
  /// HTML pages, such as the author biography card, are not books even though
  /// some catalogs mark them as acquisitions.
  List<OpdsLink> get downloadLinks => links
      .where((link) => link.isAcquisition && !link.isWebPage)
      .toList(growable: false);

  bool get hasNavigation => navigationLinks.isNotEmpty;
  bool get hasAcquisitions => acquisitionLinks.isNotEmpty;
  bool get hasDownloads => downloadLinks.isNotEmpty;

  /// Whether the entry is only a subcatalog.
  ///
  /// A book may also link to its series, so a navigation link alone does not
  /// make it a folder: an entry with a download link is always a book.
  bool get isFolder => hasNavigation && !hasAcquisitions;

  /// Best available cover image: a thumbnail when the feed provides one,
  /// otherwise the full-size image.
  OpdsLink? get coverLink {
    OpdsLink? full;
    for (final link in links) {
      if (link.isThumbnail) return link;
      if (link.isCover) full ??= link;
    }
    return full;
  }
}

/// Parsed Atom/OPDS feed with absolute links.
class OpdsFeed {
  const OpdsFeed({
    required this.url,
    required this.title,
    required this.entries,
    this.nextPage,
    this.previousPage,
    this.searchTemplate,
    this.searchDescription,
  });

  final Uri url;
  final String title;
  final List<OpdsEntry> entries;
  final Uri? nextPage;
  final Uri? previousPage;

  /// OpenSearch URL template declared directly in the feed, with a
  /// `{searchTerms}` placeholder.
  final String? searchTemplate;

  /// OpenSearch description document that should be fetched to obtain the
  /// search template, when the feed only links to it.
  final Uri? searchDescription;

  /// Parses [source] and resolves every relative link against [baseUrl],
  /// which must be the effective (post-redirect) feed URL.
  factory OpdsFeed.parse(String source, Uri baseUrl) {
    final document = XmlDocument.parse(source);
    final root = document.rootElement;

    if (root.localName != 'feed') {
      throw FormatException(l10n.notAtomFeed);
    }

    final title = _firstText(root, 'title') ?? _fallbackTitle(baseUrl);
    final entries = <OpdsEntry>[];
    for (final element in _children(root, 'entry')) {
      final entry = _parseEntry(element, baseUrl);
      if (entry != null) entries.add(entry);
    }

    Uri? nextPage;
    Uri? previousPage;
    String? searchTemplate;
    Uri? searchDescription;
    for (final link in _children(root, 'link')) {
      final rel = link.getAttribute('rel') ?? '';
      final href = link.getAttribute('href');
      if (href == null) continue;
      final uri = _resolve(href, baseUrl);
      if (uri == null) continue;
      if (rel == 'next') {
        nextPage ??= uri;
      } else if (rel == 'previous' || rel == 'prev') {
        previousPage ??= uri;
      } else if (rel == 'search') {
        final type = (link.getAttribute('type') ?? '').toLowerCase();
        if (type.contains('opensearchdescription')) {
          searchDescription ??= uri;
        } else if (isSearchTemplate(href)) {
          searchTemplate ??= absoluteTemplate(href, baseUrl);
        }
      }
    }

    return OpdsFeed(
      url: baseUrl,
      title: title,
      entries: entries,
      nextPage: nextPage,
      previousPage: previousPage,
      searchTemplate: searchTemplate,
      searchDescription: searchDescription,
    );
  }

  static OpdsEntry? _parseEntry(XmlElement element, Uri baseUrl) {
    final title = _firstText(element, 'title');
    final links = <OpdsLink>[];

    for (final link in _children(element, 'link')) {
      final href = link.getAttribute('href');
      if (href == null) continue;
      final uri = _resolve(href, baseUrl);
      if (uri == null) continue;
      if (uri.scheme != 'http' && uri.scheme != 'https') continue;
      links.add(
        OpdsLink(
          href: uri,
          rel: link.getAttribute('rel') ?? '',
          type: link.getAttribute('type'),
          title: link.getAttribute('title'),
        ),
      );
    }

    if ((title == null || title.isEmpty) && links.isEmpty) return null;

    return OpdsEntry(
      title: title == null || title.isEmpty ? l10n.untitled : title,
      author: _parseAuthor(element),
      summary: _parseSummary(element),
      links: links,
    );
  }

  static String? _parseAuthor(XmlElement entry) {
    final names = <String>[];
    for (final author in _children(entry, 'author')) {
      final name = _firstText(author, 'name');
      if (name != null && name.isNotEmpty) names.add(name);
    }
    if (names.isEmpty) {
      // Some catalogs use the Dublin Core creator element.
      for (final element in entry.childElements) {
        if (element.localName != 'creator') continue;
        final name = _normalizeText(element.innerText);
        if (name.isNotEmpty) names.add(name);
      }
    }
    if (names.isEmpty) return null;
    return names.join(', ');
  }

  static String? _parseSummary(XmlElement entry) {
    for (final name in const ['summary', 'content']) {
      for (final element in _children(entry, name)) {
        // Some feeds escape HTML again, so strip the tags before normalising
        // entities. Flibusta's author bio starts with a literal `&nbsp`
        // between two images; without this it shows up on the Kindle page.
        var text = element.innerText;
        if (text.contains('<')) {
          text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
        }
        text = _normalizeText(text);
        if (text.isEmpty) continue;
        return text;
      }
    }
    return null;
  }

  /// Cleans text taken from a feed element.
  ///
  /// Decodes HTML5 named and numeric character references (including nested
  /// escapes such as `&amp;mdash;`) and collapses feed-formatting whitespace.
  ///
  /// Parse as an HTML fragment instead of maintaining a partial entity table;
  /// this supports the full HTML5 entity set. The loop handles feeds that
  /// escaped their HTML content more than once, while remaining bounded for
  /// malformed/adversarial input.
  static String _normalizeText(String text) {
    var value = text;
    for (var i = 0; i < 5; i++) {
      final decoded =
          html_parser
              .parseFragment(value, container: 'textarea')
              .textContent() ??
          '';
      if (decoded == value) break;
      value = decoded;
    }
    return value
        .replaceAll('\u00A0', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? _firstText(XmlElement parent, String localName) {
    for (final element in _children(parent, localName)) {
      final text = _normalizeText(element.innerText);
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  static Iterable<XmlElement> _children(XmlElement parent, String localName) {
    return parent.childElements.where(
      (element) => element.localName == localName,
    );
  }

  static Uri? _resolve(String href, Uri baseUrl) {
    final trimmed = href.trim();
    if (trimmed.isEmpty) return null;
    try {
      return baseUrl.resolve(trimmed);
    } on FormatException {
      try {
        return baseUrl.resolve(Uri.encodeFull(trimmed));
      } on FormatException {
        return null;
      }
    }
  }

  static String _fallbackTitle(Uri url) {
    if (url.pathSegments.isNotEmpty) {
      final last = url.pathSegments.last.trim();
      if (last.isNotEmpty) return last;
    }
    return url.host.isEmpty ? 'OPDS' : url.host;
  }
}
