import 'package:xml/xml.dart';

/// Helpers for the OpenSearch part of OPDS: the search link that a catalog
/// may declare in its feed, the optional OpenSearch description document and
/// the `{searchTerms}` URL templates both use.

const String _searchTerms = '{searchTerms}';
const String _queryMarker = '\u0000';

/// Whether [template] can be used to run a search. OPDS 1.x uses
/// `{searchTerms}`; OPDS 2.0 uses RFC 6570 templates such as `{?query}`.
bool isSearchTemplate(String template) =>
    template.contains(_searchTerms) ||
    template.contains('{?query}') ||
    template.contains('{&query}');

/// Resolves [href] against [baseUrl] and restores the `{`/`}` of OpenSearch
/// placeholders, which `Uri` resolution percent-encodes.
String? absoluteTemplate(String href, Uri baseUrl) {
  final uri = resolveLink(href, baseUrl);
  if (uri == null) return null;
  return uri.toString().replaceAll('%7B', '{').replaceAll('%7D', '}');
}

/// Builds a real URL from an OpenSearch template and a user query.
///
/// Parameters klos cannot supply are dropped: optional ones such as
/// `{startPage?}` and any other unknown placeholder.
Uri? buildSearchUrl(String template, String query) {
  final trimmed = template.trim();
  if (!isSearchTemplate(trimmed)) return null;

  final encoded = Uri.encodeQueryComponent(query);
  var value = trimmed;

  if (value.contains(_searchTerms)) {
    value = value.replaceAllMapped(
      RegExp(r'[?&][^?&=#]+=\{([^{}]*)\}'),
      (match) => match.group(1) == 'searchTerms' ? match.group(0)! : '',
    );
    value = value.replaceAll(_searchTerms, encoded);
  }

  // OPDS 2.0 search links use RFC 6570 templates: `{?query}` adds the
  // parameter, `{&query}` appends it to an existing query string.
  if (value.contains('{?query}') || value.contains('{&query}')) {
    value = value
        .replaceAll('{?query}', _queryMarker)
        .replaceAll('{&query}', _queryMarker);
    final separator = value.contains('?') ? '&' : '?';
    value = value.replaceAll(_queryMarker, '${separator}query=$encoded');
  }

  // If the first parameter was optional, the query string may start with `&`.
  final amp = value.indexOf('&');
  if (amp != -1 && !value.substring(0, amp).contains('?')) {
    value = value.replaceRange(amp, amp + 1, '?');
  }

  return Uri.tryParse(value);
}

/// Reads the first Atom URL template from an OpenSearch description document.
///
/// Returns `null` when the document is malformed or declares no usable
/// template.
String? parseSearchDescription(String source, Uri baseUrl) {
  XmlDocument document;
  try {
    document = XmlDocument.parse(source);
  } on XmlException {
    return null;
  }

  final root = document.rootElement;
  if (root.localName.toLowerCase() != 'opensearchdescription') return null;

  String? fallback;
  for (final element in root.childElements) {
    if (element.localName.toLowerCase() != 'url') continue;
    final template = element.getAttribute('template')?.trim();
    if (template == null || template.isEmpty) continue;
    final resolved = absoluteTemplate(template, baseUrl);
    if (resolved == null) continue;

    final type = (element.getAttribute('type') ?? '').toLowerCase();
    if (type.contains('atom')) return resolved;
    fallback ??= resolved;
  }
  return fallback;
}

/// Resolves a possibly relative [href], tolerating characters that `Uri`
/// refuses to parse as is.
Uri? resolveLink(String href, Uri baseUrl) {
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
