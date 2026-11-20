// lib/convert/fb2.dart
//
// FB2 parsing and conversion to HTML for MOBI.
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:enough_convert/enough_convert.dart';
import 'package:image/image.dart' as img;
import 'package:xml/xml.dart';

import 'mobi_book.dart';

/// Decodes FB2 bytes using the encoding from the XML declaration
/// (utf-8, windows-1251; koi8-like encodings are unsupported -> latin1).
String decodeFb2Bytes(Uint8List bytes) {
  final head = latin1.decode(bytes.sublist(0, min(200, bytes.length)));
  final m = RegExp(
    r'''encoding\s*=\s*["']([^"']+)["']''',
    caseSensitive: false,
  ).firstMatch(head);
  final enc = (m?.group(1) ?? 'utf-8').toLowerCase();

  String text;
  if (enc == 'windows-1251' || enc == 'cp1251' || enc == '1251') {
    text = const Windows1251Codec(allowInvalid: true).decode(bytes);
  } else if (enc.contains('utf-8') || enc == 'utf8') {
    text = utf8.decode(bytes, allowMalformed: true);
  } else {
    text = latin1.decode(bytes);
  }
  if (text.isNotEmpty && text.codeUnitAt(0) == 0xFEFF) {
    text = text.substring(1);
  }
  return text;
}

class Fb2Converter {
  Fb2Converter(this._doc);

  final XmlDocument _doc;
  final _esc = const HtmlEscape(HtmlEscapeMode.element);

  final Map<String, XmlElement> _binaries = {};
  final List<Uint8List> _images = [];
  final Map<String, int> _imageIndex = {}; // id -> 1-based recindex

  // ---------- helpers ----------
  Iterable<XmlElement> _children(XmlElement? e, String name) =>
      e == null ? const [] : e.childElements.where((c) => c.name.local == name);

  XmlElement? _first(XmlElement? e, String name) {
    for (final c in _children(e, name)) {
      return c;
    }
    return null;
  }

  String _text(XmlElement? e) => e == null ? '' : e.innerText.trim();

  String? _href(XmlElement e) {
    for (final a in e.attributes) {
      if (a.name.local == 'href') return a.value;
    }
    return null;
  }

  /// Registers an image and returns its 1-based recindex, or null.
  int? _registerImage(String? href) {
    if (href == null) return null;
    final id = href.startsWith('#') ? href.substring(1) : href;
    final existing = _imageIndex[id];
    if (existing != null) return existing;

    final bin = _binaries[id];
    if (bin == null) return null;
    try {
      final raw = base64.decode(bin.innerText.replaceAll(RegExp(r'\s+'), ''));
      final data = _prepareImage(raw, bin.getAttribute('content-type'));
      if (data == null) return null;
      _images.add(data);
      return _imageIndex[id] = _images.length;
    } catch (_) {
      return null;
    }
  }

  /// MOBI reliably keeps JPEG/GIF; everything else (PNG and the like) is
  /// re-encoded as JPEG.
  Uint8List? _prepareImage(Uint8List data, String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('jpeg') || t.contains('jpg') || t.contains('gif')) {
      return data;
    }
    final decoded = img.decodeImage(data);
    if (decoded == null) return null;
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));
  }

  // ---------- conversion ----------
  MobiBook convert() {
    final root = _doc.rootElement;

    for (final b in _children(root, 'binary')) {
      final id = b.getAttribute('id');
      if (id != null) _binaries[id] = b;
    }

    final desc = _first(root, 'description');
    final ti = _first(desc, 'title-info');

    final title = _text(_first(ti, 'book-title'));
    final lang = _text(_first(ti, 'lang'));
    final authors = <String>[];
    for (final a in _children(ti, 'author')) {
      final parts = [
        _text(_first(a, 'first-name')),
        _text(_first(a, 'middle-name')),
        _text(_first(a, 'last-name')),
      ].where((s) => s.isNotEmpty);
      final name = parts.join(' ');
      if (name.isNotEmpty) authors.add(name);
    }

    // The cover is registered first => index 0.
    int? coverIndex;
    final coverImg = _first(_first(ti, 'coverpage'), 'image');
    if (coverImg != null) {
      final idx = _registerImage(_href(coverImg));
      if (idx != null) coverIndex = idx - 1;
    }

    final sb = StringBuffer('<html><head><guide></guide></head><body>');
    final bookTitle = title.isEmpty ? 'Без названия' : title;
    sb.write('<h1 align="center">${_esc.convert(bookTitle)}</h1>');
    if (authors.isNotEmpty) {
      sb.write('<p align="center">${_esc.convert(authors.join(', '))}</p>');
    }
    final annotation = _first(ti, 'annotation');
    if (annotation != null) {
      sb.write('<blockquote>');
      for (final c in annotation.childElements) {
        _block(c, 1, sb);
      }
      sb.write('</blockquote>');
    }
    sb.write('<mbp:pagebreak/>');

    for (final body in _children(root, 'body')) {
      final isNotes = body.getAttribute('name') == 'notes';
      if (isNotes) sb.write('<mbp:pagebreak/>');
      for (final c in body.childElements) {
        _block(c, 1, sb);
      }
    }
    sb.write('</body></html>');

    return MobiBook(
      title: bookTitle,
      author: authors.join(' & '),
      language: lang,
      html: sb.toString(),
      images: _images,
      coverIndex: coverIndex,
    );
  }

  // ---------- block elements ----------
  void _block(XmlElement e, int d, StringBuffer sb) {
    switch (e.name.local) {
      case 'section':
        if (d == 1) sb.write('<mbp:pagebreak/>');
        for (final c in e.childElements) {
          _block(c, c.name.local == 'section' ? d + 1 : d, sb);
        }
        break;
      case 'title':
        final h = min(d, 3);
        final lines = e.childElements
            .map((c) => c.name.local == 'empty-line' ? '' : _inline(c))
            .where((s) => s.isNotEmpty)
            .join('<br/>');
        sb.write('<h$h align="center">$lines</h$h>');
        break;
      case 'subtitle':
        sb.write('<p align="center"><b>${_inline(e)}</b></p>');
        break;
      case 'p':
        sb.write('<p>${_inline(e)}</p>');
        break;
      case 'empty-line':
        sb.write('<br/>');
        break;
      case 'text-author':
        sb.write('<p align="right"><i>${_inline(e)}</i></p>');
        break;
      case 'date':
        sb.write('<p align="right">${_inline(e)}</p>');
        break;
      case 'epigraph':
      case 'cite':
        sb.write('<blockquote>');
        for (final c in e.childElements) {
          _block(c, d, sb);
        }
        sb.write('</blockquote>');
        break;
      case 'poem':
        for (final c in e.childElements) {
          if (c.name.local == 'stanza') {
            final lines = _children(c, 'v').map(_inline).join('<br/>');
            sb.write('<p>$lines</p>');
          } else {
            _block(c, d, sb);
          }
        }
        break;
      case 'image':
        final tag = _imageTag(e);
        if (tag.isNotEmpty) sb.write('<div align="center">$tag</div>');
        break;
      case 'table':
        sb.write('<table>');
        for (final tr in _children(e, 'tr')) {
          sb.write('<tr>');
          for (final cell in tr.childElements) {
            sb.write('<td>${_inline(cell)}</td>');
          }
          sb.write('</tr>');
        }
        sb.write('</table>');
        break;
      default:
        break;
    }
  }

  // ---------- inline elements ----------
  String _inline(XmlNode n) => n.children.map(_inlineNode).join();

  String _inlineNode(XmlNode n) {
    if (n is XmlText || n is XmlCDATA) {
      return _esc.convert(n.value ?? '');
    }
    if (n is! XmlElement) return '';
    switch (n.name.local) {
      case 'strong':
        return '<b>${_inline(n)}</b>';
      case 'emphasis':
        return '<i>${_inline(n)}</i>';
      case 'strikethrough':
        return '<s>${_inline(n)}</s>';
      case 'sub':
        return '<sub>${_inline(n)}</sub>';
      case 'sup':
        return '<sup>${_inline(n)}</sup>';
      case 'code':
        return '<tt>${_inline(n)}</tt>';
      case 'image':
        return _imageTag(n);
      case 'a': // internal links/footnotes are rendered as text
      case 'style':
      default:
        return _inline(n);
    }
  }

  String _imageTag(XmlElement e) {
    final idx = _registerImage(_href(e));
    if (idx == null) return '';
    return '<img recindex="${idx.toString().padLeft(5, '0')}"/>';
  }
}
