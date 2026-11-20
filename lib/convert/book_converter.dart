import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Locale;

import 'fb2_to_mobi.dart' show convertFb2ToMobiSync;
import '../l10n/l10n.dart';
import 'epub_converter.dart';

export 'epub_converter.dart' show EpubConversionException;

/// Converts a book klos can read on the phone into MOBI.
///
/// [mime] is the type reported by `resolveBook`; the archive was already
/// unpacked there, so a `.fb2.zip` arrives as bare FB2 and an EPUB as its
/// own ZIP. Anything else is rejected with a readable message.
Uint8List convertBookToMobiSync(
  Uint8List bytes, {
  String? mime,
  String? fallbackTitle,
}) {
  final kind = (mime ?? '').toLowerCase();
  if (kind.contains('epub')) {
    return convertEpubSync(bytes, fallbackTitle: fallbackTitle);
  }
  if (kind.contains('fictionbook') || kind.contains('fb2')) {
    return _convertFb2(bytes);
  }
  throw EpubConversionException(l10n.convertUnsupportedFormat);
}

Uint8List _convertFb2(Uint8List bytes) {
  try {
    return convertFb2ToMobiSync(bytes);
  } on EpubConversionException {
    rethrow;
  } catch (error) {
    throw EpubConversionException(l10n.conversionFailed('$error'));
  }
}

/// Converts in a background isolate so the app UI and the HTTP server stay
/// responsive.
///
/// The isolate has its own copy of the loaded messages, so [languageCode]
/// loads the same translation there.
Future<Uint8List> convertBookToMobi(
  Uint8List bytes, {
  String? mime,
  String? fallbackTitle,
  String languageCode = 'en',
}) {
  return Isolate.run(() async {
    await L10n.use(Locale(languageCode));
    return convertBookToMobiSync(
      bytes,
      mime: mime,
      fallbackTitle: fallbackTitle,
    );
  });
}
