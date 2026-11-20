import '../l10n/l10n.dart';

/// Formats shown in the catalog and used by the "send to Kindle" feature.
class EbookFormat {
  const EbookFormat(
    this.key,
    this.label, {
    this.amazonSupported = false,
    this.kindleSupported = false,
  });

  final String key;
  final String label;

  /// Whether Amazon's Send to Kindle service accepts this format by email.
  final bool amazonSupported;

  /// Whether the Kindle browser can download and open this format directly.
  final bool kindleSupported;

  static const epub = EbookFormat('EPUB', 'EPUB', amazonSupported: true);
  static const pdf = EbookFormat(
    'PDF',
    'PDF',
    amazonSupported: true,
    kindleSupported: true,
  );
  static const txt = EbookFormat(
    'TXT',
    'TXT',
    amazonSupported: true,
    kindleSupported: true,
  );
  static const fb2 = EbookFormat('FB2', 'FB2');
  static const cbz = EbookFormat('CBZ', 'CBZ');
  static const zip = EbookFormat('ZIP', 'ZIP');
  static const mobi = EbookFormat('MOBI', 'MOBI', kindleSupported: true);
  static const azw3 = EbookFormat('AZW3', 'AZW3', kindleSupported: true);
  static const azw = EbookFormat('AZW', 'AZW', kindleSupported: true);

  /// Formats the catalog and local folder can recognise.
  static const selectable = <EbookFormat>[epub, pdf, txt, fb2, cbz, zip];

  static EbookFormat? match(String? mime) {
    final value = (mime ?? '').toLowerCase();
    if (value.isEmpty) return null;
    if (value.contains('epub')) return epub;
    if (value.contains('pdf')) return pdf;
    if (value.contains('fb2') || value.contains('fictionbook')) return fb2;
    if (value.contains('cbz') || value.contains('comicbook')) return cbz;
    if (value.contains('mobi8')) return azw3;
    if (value.contains('mobipocket')) return mobi;
    if (value.contains('vnd.amazon.ebook')) return azw;
    if (value.contains('text/plain')) return txt;
    if (value.contains('zip')) return zip;
    return null;
  }

  static String keyForMime(String? mime) => match(mime)?.key ?? 'OTHER';

  /// Whether the Kindle browser can open a file of this MIME type directly.
  static bool downloadsDirectly(String? mime) =>
      match(mime)?.kindleSupported ?? false;

  /// Whether klos can turn a book of this MIME type into MOBI on the phone.
  ///
  /// EPUB cannot be opened by older Kindles, and no Kindle opens FB2, so klos
  /// converts those before serving a download.
  static bool convertible(String? mime) {
    final key = keyForMime(mime);
    return key == epub.key || key == fb2.key;
  }

  /// Whether Amazon's Send to Kindle accepts this format by email.
  ///
  /// Only these files can actually reach the Kindle by email: Amazon rejects
  /// FB2, CBZ and archives. klos therefore does not offer the «send by email»
  /// button for anything else, so the button never leads to a rejected letter.
  static bool emailable(String? mime) {
    final format = match(mime);
    if (format != null) return format.amazonSupported;
    final value = (mime ?? '').toLowerCase();
    return value.contains('rtf') ||
        value.contains('word') ||
        value.contains('html');
  }

  static String labelForMime(String? mime) {
    final format = match(mime);
    if (format != null) return format.label;
    final raw = (mime ?? '').split(';').first.trim();
    if (raw.isEmpty) return l10n.fileFallback;
    return raw.length > 28 ? '${raw.substring(0, 25)}...' : raw;
  }

  static String? labelForKey(String key) {
    for (final format in selectable) {
      if (format.key == key) return format.label;
    }
    return null;
  }
}
