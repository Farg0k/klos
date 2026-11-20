/// Maps common ebook MIME types to a file extension.
String? extensionForMime(String? mime) {
  if (mime == null) return null;
  final clean = mime.split(';').first.trim().toLowerCase();
  const known = {
    'application/epub+zip': '.epub',
    'application/x-mobipocket-ebook': '.mobi',
    'application/vnd.amazon.ebook': '.azw',
    'application/x-mobi8-ebook': '.azw3',
    'application/pdf': '.pdf',
    'application/x-cbz': '.cbz',
    'application/vnd.comicbook+zip': '.cbz',
    'application/x-fictionbook+xml': '.fb2',
    'application/fb2+xml': '.fb2',
    'text/plain': '.txt',
    'application/zip': '.zip',
  };
  final direct = known[clean];
  if (direct != null) return direct;
  if (clean.contains('mobi8')) return '.azw3';
  if (clean.contains('mobipocket')) return '.mobi';
  if (clean.contains('epub')) return '.epub';
  return null;
}

/// Cyrillic letters transliterated for file names.
///
/// Kindle browsers save a download under the ASCII `filename` value or the
/// URL basename and often cannot handle Cyrillic, which turns a Ukrainian or
/// Russian title into a row of underscores. A readable Latin name is more
/// useful. This is a practical scheme (the Cyrillic "г" becomes "g") rather
/// than a strict standard, so Ukrainian and Russian titles both stay
/// recognizable.
const Map<String, String> _cyrillicToLatin = {
  'а': 'a',
  'б': 'b',
  'в': 'v',
  'г': 'g',
  'ґ': 'g',
  'д': 'd',
  'е': 'e',
  'ё': 'yo',
  'є': 'ye',
  'ж': 'zh',
  'з': 'z',
  'и': 'i',
  'і': 'i',
  'ї': 'yi',
  'й': 'y',
  'к': 'k',
  'л': 'l',
  'м': 'm',
  'н': 'n',
  'о': 'o',
  'п': 'p',
  'р': 'r',
  'с': 's',
  'т': 't',
  'у': 'u',
  'ў': 'u',
  'ф': 'f',
  'х': 'kh',
  'ц': 'ts',
  'ч': 'ch',
  'ш': 'sh',
  'щ': 'shch',
  'ъ': '',
  'ы': 'y',
  'ь': '',
  'э': 'e',
  'ю': 'yu',
  'я': 'ya',
  'А': 'A',
  'Б': 'B',
  'В': 'V',
  'Г': 'G',
  'Ґ': 'G',
  'Д': 'D',
  'Е': 'E',
  'Ё': 'Yo',
  'Є': 'Ye',
  'Ж': 'Zh',
  'З': 'Z',
  'И': 'I',
  'І': 'I',
  'Ї': 'Yi',
  'Й': 'Y',
  'К': 'K',
  'Л': 'L',
  'М': 'M',
  'Н': 'N',
  'О': 'O',
  'П': 'P',
  'Р': 'R',
  'С': 'S',
  'Т': 'T',
  'У': 'U',
  'Ў': 'U',
  'Ф': 'F',
  'Х': 'Kh',
  'Ц': 'Ts',
  'Ч': 'Ch',
  'Ш': 'Sh',
  'Щ': 'Shch',
  'Ъ': '',
  'Ы': 'Y',
  'Ь': '',
  'Э': 'E',
  'Ю': 'Yu',
  'Я': 'Ya',
};

/// Writes Cyrillic text in Latin letters for a download file name.
///
/// Typographic punctuation is simplified too: quotes become spaces, dashes
/// become a hyphen, and apostrophes are dropped.
String transliterateFileName(String input) {
  final out = StringBuffer();
  for (final rune in input.runes) {
    final character = String.fromCharCode(rune);
    final latin = _cyrillicToLatin[character];
    if (latin != null) {
      out.write(latin);
      continue;
    }
    switch (rune) {
      case 0x00A0 || 0x00AB || 0x00BB:
      case 0x201C || 0x201D || 0x201E || 0x201F:
        out.write(' ');
      case 0x2013 || 0x2014 || 0x2015:
        out.write('-');
      case 0x2018 || 0x2019 || 0x02BC || 0x0060 || 0x00B4:
        // Apostrophes only separate letters and are not needed in a name.
        break;
      case 0x2116:
        out.write('No.');
      case 0x2026:
        out.write('...');
      default:
        out.write(character);
    }
  }
  return out.toString();
}

/// Builds a usable file name from an entry title and a MIME type.
///
/// Cyrillic titles are transliterated, because Kindle browsers handle Latin
/// download names much better. The remote URL is only used when the entry
/// has no title.
String fileNameFor({
  required Uri url,
  String? title,
  String? mime,
  bool underscores = false,
}) {
  var name = (title != null && title.trim().isNotEmpty)
      ? title.trim()
      : (_fileNameFromUrl(url) ?? 'book');
  name = transliterateFileName(name);

  name = name
      .replaceAll(RegExp(r'[\\/:*?"<>|\x00-\x1f]'), ' ')
      .replaceAll(RegExp(r'\s+'), underscores ? '_' : ' ')
      .trim();
  name = name.replaceAll(RegExp(r'^\.+'), '').trim();
  if (underscores) {
    name = name.replaceAll(RegExp(r'_+'), '_');
    name = name.replaceAll(RegExp(r'^_+|_+$'), '');
  }
  if (name.isEmpty) name = 'book';

  final extension = extensionForMime(mime);
  if (extension != null) {
    name = name
        .replaceFirst(
          RegExp(
            r'\.(epub|mobi|azw3?|pdf|cbz|fb2|txt|zip)$',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
    if (name.isEmpty) name = 'book';
  }

  const maxLength = 120;
  var ext = extension ?? '';
  if (name.runes.length > maxLength) {
    final base = String.fromCharCodes(
      name.runes.take(maxLength - ext.runes.length),
    ).trim();
    name = base.isEmpty ? 'book' : base;
  }

  return '$name$ext';
}

String contentDispositionFor({
  required Uri url,
  required String mime,
  String? title,
}) {
  final name = fileNameFor(url: url, title: title, mime: mime);
  final ascii = name.runes
      .map(
        (rune) => rune >= 0x20 && rune < 0x7f ? String.fromCharCode(rune) : '_',
      )
      .join()
      .replaceAll('"', "'");
  final encoded = Uri.encodeComponent(name).replaceAll("'", '%27');
  return 'attachment; filename="$ascii"; filename*=UTF-8\'\'$encoded';
}

String? _fileNameFromUrl(Uri url) {
  if (url.pathSegments.isEmpty) return null;
  final last = url.pathSegments.last.trim();
  if (last.isEmpty) return null;
  try {
    return Uri.decodeComponent(last);
  } on ArgumentError {
    return last;
  }
}
