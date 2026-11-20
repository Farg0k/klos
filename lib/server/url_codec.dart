import 'dart:convert';

import 'file_names.dart';

/// Encodes a target URL into a compact URL-safe token used in local links.
String encodeTarget(Uri uri) {
  return base64Url.encode(utf8.encode(uri.toString())).replaceAll('=', '');
}

Uri? decodeTarget(String raw) {
  if (raw.isEmpty) return null;
  try {
    final normalized = base64Url.normalize(raw);
    final decoded = utf8.decode(base64Url.decode(normalized));
    return Uri.tryParse(decoded);
  } on FormatException {
    return null;
  }
}

String browseHref(Uri uri) => '/browse?u=${encodeTarget(uri)}';

String downloadHref(Uri uri, {String? title, String? type}) {
  return _fileHref('/download', uri, title: title, type: type);
}

/// Link that emails the book to Kindle instead of downloading it.
String mailHref(Uri uri, {String? title, String? type}) {
  return _fileHref('/send', uri, title: title, type: type);
}

/// Link to one folder inside the locally chosen folder, or its root.
String localDirHref(String? documentUri) {
  if (documentUri == null || documentUri.trim().isEmpty) return '/local';
  return '/local?d=${encodeTarget(Uri.parse(documentUri.trim()))}';
}

/// Link that downloads a file from the locally chosen folder.
String localDownloadHref(Uri uri, {String? title, String? type}) {
  return _fileHref('/local/download', uri, title: title, type: type);
}

/// Link that emails a file from the locally chosen folder to Kindle.
String localMailHref(Uri uri, {String? title, String? type}) {
  return _fileHref('/local/send', uri, title: title, type: type);
}

/// Link that runs an OpenSearch query on the catalog.
String searchHref(String template, String query) {
  final params = <String, String>{
    'u': template,
    if (query.trim().isNotEmpty) 'q': query.trim(),
  };
  final encoded = params.entries
      .map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}')
      .join('&');
  return '/search?$encoded';
}

/// Link that proxies a cover image through the local server.
String imageHref(Uri uri, {String? type}) {
  final params = <String, String>{'u': encodeTarget(uri)};
  if (type != null && type.trim().isNotEmpty) {
    params['t'] = type.trim();
  }
  final query = params.entries
      .map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}')
      .join('&');
  return '/image?$query';
}

String _fileHref(String prefix, Uri uri, {String? title, String? type}) {
  final params = <String, String>{'u': encodeTarget(uri)};
  if (title != null && title.trim().isNotEmpty) {
    params['n'] = title.trim();
  }
  if (type != null && type.trim().isNotEmpty) {
    params['t'] = type.trim();
  }
  final query = params.entries
      .map((entry) => '${entry.key}=${Uri.encodeQueryComponent(entry.value)}')
      .join('&');

  // Put the file name (with extension) into the path as well: some Kindle
  // firmware saves the download under the URL basename instead of using
  // the Content-Disposition header.
  final fileName = fileNameFor(
    url: uri,
    title: title,
    mime: type,
    underscores: true,
  );
  return '$prefix/${Uri.encodeComponent(fileName)}?$query';
}
