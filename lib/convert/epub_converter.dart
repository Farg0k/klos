import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Locale;

import '../l10n/l10n.dart';
import 'epub.dart';
import 'mobi_writer.dart';

/// A user-facing conversion problem.
class EpubConversionException implements Exception {
  EpubConversionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Converts EPUB bytes into a basic MOBI 6 file synchronously.
///
/// Kept separate from [convertEpub] so it can be tested without an isolate.
Uint8List convertEpubSync(Uint8List bytes, {String? fallbackTitle}) {
  try {
    final book = EpubParser.parse(bytes, fallbackTitle: fallbackTitle);
    return MobiWriter.build(
      title: book.title,
      author: book.author,
      language: book.language,
      html: book.html,
      images: book.images,
      coverIndex: book.coverIndex,
    );
  } on EpubFormatException catch (error) {
    throw EpubConversionException(error.message);
  } on FormatException catch (error) {
    throw EpubConversionException(l10n.conversionFailed(error.message));
  }
}

/// Converts an EPUB in a background isolate so the app UI and HTTP server
/// stay responsive.
///
/// The isolate has its own copy of the loaded messages, so [languageCode]
/// loads the same translation there.
Future<Uint8List> convertEpub(
  Uint8List bytes, {
  String? fallbackTitle,
  String languageCode = 'en',
}) {
  return Isolate.run(() async {
    await L10n.use(Locale(languageCode));
    return convertEpubSync(bytes, fallbackTitle: fallbackTitle);
  });
}
