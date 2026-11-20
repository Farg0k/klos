import 'dart:io';
import 'dart:typed_data';

import '../convert/book_converter.dart';
import '../l10n/l10n.dart';
import '../opds/opds_client.dart';
import '../opds/opds_feed.dart';
import '../server/file_names.dart';
import 'ebook_archive.dart';
import 'ebook_formats.dart';

/// The largest book klos downloads in one piece.
const int maxDeliveryBytes = 120 * 1024 * 1024;

/// The largest book klos converts into MOBI on the phone.
const int maxConversionBytes = 80 * 1024 * 1024;

/// MIME type of a MOBI file.
const String mobiMime = 'application/x-mobipocket-ebook';

/// A downloaded book in its original form, before klos resolves it.
class RemoteBook {
  const RemoteBook({
    required this.bytes,
    required this.url,
    required this.mime,
    this.contentEncoding,
  });

  final Uint8List bytes;

  /// Effective URL after redirects; file names are built from it.
  final Uri url;

  final String mime;

  /// Transfer encoding already applied by the server, if any.
  final String? contentEncoding;
}

/// A book prepared for the Kindle.
///
/// Archives are unpacked and EPUB/FB2 are converted into MOBI, exactly as the
/// local server does for a download from the Kindle browser.
class DeliveredBook {
  const DeliveredBook({
    required this.bytes,
    required this.url,
    required this.mime,
    this.contentEncoding,
  });

  final Uint8List bytes;
  final Uri url;
  final String mime;
  final String? contentEncoding;
}

/// Reads the response of a book download and keeps the useful MIME type.
///
/// Providers often answer with `application/octet-stream`, so the type the
/// catalog declared for the link is used as a fallback.
Future<RemoteBook> readRemoteBook({
  required OpdsClient client,
  required OpdsLink link,
}) async {
  final remote = await client.openDownload(link.href);
  final remoteMime = remote.response.headers.contentType?.mimeType;

  // A login page or an error page is not a book. HTML is allowed only when the
  // catalog itself offered it as the file.
  final linkType = link.type?.toLowerCase() ?? '';
  if (remoteMime == 'text/html' && !linkType.contains('html')) {
    await remote.response.drain<void>();
    throw OpdsException(l10n.opdsHtmlInsteadOfFile);
  }

  final mime = downloadMime(
    remoteType: remote.response.headers.contentType,
    linkType: link.type,
  );
  final contentEncoding = remote.response.headers.value(
    HttpHeaders.contentEncodingHeader,
  );

  final builder = BytesBuilder(copy: false);
  await for (final chunk in remote.response) {
    builder.add(chunk);
    if (builder.length > maxDeliveryBytes) {
      throw OpdsException(l10n.downloadTooLarge);
    }
  }
  final bytes = builder.takeBytes();
  if (bytes.isEmpty) throw OpdsException(l10n.opdsEmptyFile);

  return RemoteBook(
    bytes: bytes,
    url: remote.url,
    mime: mime,
    contentEncoding: contentEncoding,
  );
}

/// MIME type of a download: the response wins unless it is a generic one.
String downloadMime({
  required ContentType? remoteType,
  required String? linkType,
}) {
  final remote = remoteType?.mimeType;
  if (remote != null &&
      remote.isNotEmpty &&
      remote != 'application/octet-stream') {
    return remote;
  }
  final declared = linkType?.split(';').first.trim();
  if (declared != null && declared.isNotEmpty) return declared;
  return remote ?? 'application/octet-stream';
}

/// Turns downloaded [bytes] into the file klos would serve the Kindle.
///
/// A ZIP is unpacked, taking a format the Kindle opens. When the archive holds
/// only an EPUB or FB2, the book is converted into MOBI instead. EPUB and FB2
/// that arrived outside an archive are converted too. Everything else is kept
/// as is, including the transfer encoding it came with.
///
/// [log] receives the same messages the server writes to the app log; it is
/// optional because the in-app download does not need them.
Future<DeliveredBook> deliverDownloadedBook({
  required Uint8List bytes,
  required Uri url,
  required String? title,
  required String mime,
  String? contentEncoding,
  String ip = '',
  void Function(String message)? log,
  String languageCode = 'en',
}) async {
  final encoded = contentEncoding != null && contentEncoding.isNotEmpty;

  if (!encoded && looksLikeZip(bytes)) {
    final BookContent resolved;
    try {
      resolved = resolveBook(
        bytes,
        purpose: BookPurpose.download,
        maxBytes: maxDeliveryBytes,
      );
    } on BookArchiveException {
      // An archive with only an EPUB or FB2 has no format the Kindle opens,
      // so it is converted instead of failing.
      final mobi = await _convertArchivedBook(
        bytes,
        title: title,
        ip: ip,
        log: log,
        languageCode: languageCode,
      );
      if (mobi == null) rethrow;
      final mobiName = fileNameFor(url: url, title: title, mime: mobiMime);
      log?.call(l10n.conversionDoneLog(mobiName, ip));
      return DeliveredBook(bytes: mobi, url: url, mime: mobiMime);
    }

    final resolvedMime = resolved.mime ?? mime;
    final fileName = fileNameFor(url: url, title: title, mime: resolvedMime);
    log?.call(
      resolved.extracted
          ? l10n.downloadFromZipLog(fileName, ip)
          : l10n.downloadLog(fileName, ip),
    );
    return _asKindleDownload(
      bytes: resolved.bytes,
      url: url,
      title: title,
      mime: resolvedMime,
      ip: ip,
      log: log,
      languageCode: languageCode,
    );
  }

  log?.call(
    l10n.downloadLog(fileNameFor(url: url, title: title, mime: mime), ip),
  );
  return _asKindleDownload(
    bytes: bytes,
    url: url,
    title: title,
    mime: mime,
    contentEncoding: contentEncoding,
    ip: ip,
    log: log,
    languageCode: languageCode,
  );
}

/// Converts a book the Kindle cannot open into MOBI.
///
/// Only used for EPUB and FB2; every other format is passed through so the
/// Kindle gets exactly the file the catalog offered.
Future<DeliveredBook> _asKindleDownload({
  required Uint8List bytes,
  required Uri url,
  required String? title,
  required String mime,
  required String ip,
  String? contentEncoding,
  void Function(String message)? log,
  required String languageCode,
}) async {
  if ((contentEncoding != null && contentEncoding.isNotEmpty) ||
      !EbookFormat.convertible(mime)) {
    return DeliveredBook(
      bytes: bytes,
      url: url,
      mime: mime,
      contentEncoding: contentEncoding,
    );
  }
  final mobi = await _mobiFor(
    bytes,
    mime: mime,
    title: title,
    ip: ip,
    log: log,
    languageCode: languageCode,
  );
  final fileName = fileNameFor(url: url, title: title, mime: mobiMime);
  log?.call(l10n.conversionDoneLog(fileName, ip));
  return DeliveredBook(bytes: mobi, url: url, mime: mobiMime);
}

/// Takes an EPUB or FB2 out of [bytes] and converts it into MOBI.
///
/// Returns null when the archive has nothing that can be converted, so the
/// caller can show its own "no Kindle format" message.
Future<Uint8List?> _convertArchivedBook(
  Uint8List bytes, {
  required String? title,
  required String ip,
  void Function(String message)? log,
  required String languageCode,
}) async {
  final BookContent book;
  try {
    book = resolveBook(
      bytes,
      purpose: BookPurpose.convert,
      maxBytes: maxConversionBytes,
    );
  } on BookArchiveException {
    return null;
  }
  return _mobiFor(
    book.bytes,
    mime: book.mime,
    title: title,
    ip: ip,
    log: log,
    languageCode: languageCode,
  );
}

Future<Uint8List> _mobiFor(
  Uint8List bytes, {
  required String? mime,
  required String? title,
  required String ip,
  void Function(String message)? log,
  required String languageCode,
}) {
  log?.call(l10n.conversionLog(title ?? l10n.untitled, ip));
  return convertBookToMobi(
    bytes,
    mime: mime,
    fallbackTitle: title,
    languageCode: languageCode,
  );
}
