import 'dart:convert';

import '../l10n/l10n.dart';
import 'opds_feed.dart';
import 'opensearch.dart';

/// Parser for OPDS 2.0 (`application/opds+json`).
///
/// OPDS 2.0 is JSON-based but conceptually mirrors OPDS 1.x: a feed has
/// `navigation` links and `publications`, while a single publication is a
/// document with its own `metadata` and `links`. Everything is converted into
/// the same [OpdsFeed]/[OpdsEntry] model the HTML renderer already uses.
const String _jsonFeedType = 'application/opds+json';

/// Parses an OPDS 2.0 document, resolving relative links against [baseUrl].
///
/// Throws [FormatException] when [source] is not a JSON object.
OpdsFeed parseOpds2(String source, Uri baseUrl) {
  final document = _decode(source);
  final metadata = _asMap(document['metadata']);

  final entries = <OpdsEntry>[];
  _collectEntries(document, baseUrl, entries);

  // A single-publication document has no navigation/publications members; it
  // has its own metadata and links directly at the top level.
  if (entries.isEmpty && metadata != null && document['links'] != null) {
    final publication = _publicationEntry(document, baseUrl);
    if (publication != null) entries.add(publication);
  }

  Uri? nextPage;
  Uri? previousPage;
  String? searchTemplate;
  for (final item in _asList(document['links'])) {
    final link = _asMap(item);
    if (link == null) continue;
    final rel = _text(link['rel']) ?? '';
    final href = _text(link['href']);
    if (href == null) continue;

    if (rel == 'next') {
      nextPage ??= resolveLink(href, baseUrl);
    } else if (rel == 'previous' || rel == 'prev') {
      previousPage ??= resolveLink(href, baseUrl);
    } else if (rel == 'search') {
      final template = _searchTemplate(link, baseUrl);
      if (template != null) searchTemplate ??= template;
    }
  }

  final title = _text(metadata?['title'])?.trim();
  return OpdsFeed(
    url: baseUrl,
    title: title == null || title.isEmpty ? _fallbackTitle(baseUrl) : title,
    entries: entries,
    nextPage: nextPage,
    previousPage: previousPage,
    searchTemplate: searchTemplate,
  );
}

/// Adds navigation, publication and grouped entries of [node] to [out].
void _collectEntries(
  Map<String, dynamic> node,
  Uri baseUrl,
  List<OpdsEntry> out,
) {
  for (final item in _asList(node['navigation'])) {
    final link = _asMap(item);
    if (link == null) continue;
    final href = _text(link['href']);
    final uri = href == null ? null : resolveLink(href, baseUrl);
    if (uri == null) continue;
    final title = _text(link['title'])?.trim();
    out.add(
      OpdsEntry(
        title: title == null || title.isEmpty ? l10n.untitled : title,
        links: [
          OpdsLink(
            href: uri,
            rel: 'subsection',
            type: _text(link['type']) ?? _jsonFeedType,
            title: title,
          ),
        ],
      ),
    );
  }

  for (final item in _asList(node['publications'])) {
    final publication = _asMap(item);
    if (publication == null) continue;
    final entry = _publicationEntry(publication, baseUrl);
    if (entry != null) out.add(entry);
  }

  for (final item in _asList(node['groups'])) {
    final group = _asMap(item);
    if (group == null) continue;
    _collectEntries(group, baseUrl, out);
  }
}

/// Builds an [OpdsEntry] from an OPDS 2.0 publication object.
OpdsEntry? _publicationEntry(Map<String, dynamic> publication, Uri baseUrl) {
  final metadata = _asMap(publication['metadata']);
  final rawTitle = _text(metadata?['title'])?.trim();
  if (rawTitle == null || rawTitle.isEmpty) return null;

  final links = <OpdsLink>[];
  for (final item in _asList(publication['links'])) {
    final link = _asMap(item);
    if (link == null) continue;
    final rel = _text(link['rel']) ?? '';
    final href = _text(link['href']);
    final uri = href == null ? null : resolveLink(href, baseUrl);
    if (uri == null) continue;

    if (_isAcquisition(rel)) {
      links.add(
        OpdsLink(
          href: uri,
          rel: rel,
          type: _text(link['type']),
          title: _text(link['title']),
        ),
      );
    } else if (_isCoverRel(rel)) {
      final type = _text(link['type']);
      links.add(OpdsLink(href: uri, rel: _coverRel(rel), type: type));
    }
  }

  // OPDS 2.0 keeps cover images in a dedicated `images` array. The first
  // image is the cover.
  for (final item in _asList(publication['images'])) {
    final image = _asMap(item);
    if (image == null) continue;
    final href = _text(image['href']);
    final uri = href == null ? null : resolveLink(href, baseUrl);
    if (uri == null) continue;
    links.add(
      OpdsLink(
        href: uri,
        rel: 'http://opds-spec.org/image',
        type: _text(image['type']),
      ),
    );
  }

  return OpdsEntry(
    title: rawTitle,
    author: _author(metadata?['author']),
    summary: _summary(metadata?['description']),
    links: links,
  );
}

bool _isAcquisition(String rel) =>
    rel == 'enclosure' || rel.startsWith('http://opds-spec.org/acquisition');

bool _isCoverRel(String rel) =>
    rel == 'cover' ||
    rel.startsWith('http://opds-spec.org/image') ||
    rel == 'http://opds-spec.org/thumbnail';

String _coverRel(String rel) {
  if (rel.contains('thumbnail')) return 'http://opds-spec.org/image/thumbnail';
  return 'http://opds-spec.org/image';
}

/// A search link is usable only when it contains a fillable placeholder.
String? _searchTemplate(Map<String, dynamic> link, Uri baseUrl) {
  final href = _text(link['href']);
  if (href == null) return null;
  final resolved = absoluteTemplate(href, baseUrl);
  if (resolved == null) return null;
  return isSearchTemplate(resolved) ? resolved : null;
}

String? _author(Object? value) {
  final names = <String>[];
  void add(Object? item) {
    if (item is String) {
      final name = item.trim();
      if (name.isNotEmpty) names.add(name);
    } else if (item is Map) {
      final name = _text(item['name'])?.trim();
      if (name != null && name.isNotEmpty) names.add(name);
    }
  }

  if (value is List) {
    for (final item in value) {
      add(item);
    }
  } else {
    add(value);
  }
  return names.isEmpty ? null : names.join(', ');
}

String? _summary(Object? value) {
  var text = value is String ? value : '';
  // Be defensive: some feeds put escaped HTML into descriptions.
  if (text.contains('<')) {
    text = text.replaceAll(RegExp(r'<[^>]*>'), ' ');
  }
  text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) return null;
  if (text.length > 240) {
    text = '${text.substring(0, 237).trimRight()}...';
  }
  return text;
}

Map<String, dynamic> _decode(String source) {
  final cleaned = source.replaceFirst(RegExp(r'^\uFEFF'), '');
  Object? decoded;
  try {
    decoded = jsonDecode(cleaned);
  } on FormatException {
    throw FormatException(l10n.invalidJson);
  }
  if (decoded is! Map<String, dynamic>) {
    throw FormatException(l10n.notOpds2Feed);
  }
  return decoded;
}

Map<String, dynamic>? _asMap(Object? value) =>
    value is Map<String, dynamic> ? value : null;

List<Object?> _asList(Object? value) => value is List ? value : const [];

String? _text(Object? value) => value is String ? value : null;

String _fallbackTitle(Uri url) {
  if (url.pathSegments.isNotEmpty) {
    final last = url.pathSegments.last.trim();
    if (last.isNotEmpty) return last;
  }
  return url.host.isEmpty ? 'OPDS' : url.host;
}
