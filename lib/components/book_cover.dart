import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../entity/app_settings.dart';
import '../opds/opds_client.dart';
import '../opds/opds_feed.dart';

/// Cover thumbnail for a catalog entry, with a book-shaped placeholder.
///
/// Covers are downloaded once and kept in a small in-memory cache, because the
/// same book is shown again in favorites. A missing or broken cover must not
/// leave a hole in the list, so the placeholder keeps the same size.
class BookCover extends StatefulWidget {
  const BookCover({
    super.key,
    required this.title,
    required this.settings,
    this.link,
    this.icon = Icons.menu_book_outlined,
    this.width = 52,
    this.height = 78,
  });

  final String title;
  final AppSettings settings;

  /// Thumbnail link from the feed, or null when the catalog has no cover.
  final OpdsLink? link;

  /// Icon used by the placeholder — a folder icon for subcatalogs.
  final IconData icon;

  final double width;
  final double height;

  @override
  State<BookCover> createState() => _BookCoverState();
}

class _BookCoverState extends State<BookCover> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(BookCover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.link?.href != widget.link?.href) {
      _bytes = null;
      _load();
    }
  }

  Future<void> _load() async {
    final link = widget.link;
    if (link == null) return;
    final bytes = await _CoverCache.load(link.href, widget.settings);
    if (!mounted || bytes == null) return;
    setState(() => _bytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return _placeholder(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        bytes,
        width: widget.width,
        height: widget.height,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => _placeholder(context),
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.surfaceContainerHighest],
        ),
        border: Border.all(color: scheme.outlineVariant),
      ),
      alignment: Alignment.center,
      child: Icon(widget.icon, size: 22, color: scheme.onPrimaryContainer),
    );
  }
}

/// Small process-wide cache of cover bytes.
///
/// Failures are cached as null too, so a broken cover is not retried on every
/// rebuild. The key includes the user name because catalogs behind a login may
/// serve different covers to different accounts.
class _CoverCache {
  _CoverCache._();

  static const int _maxEntries = 150;

  static final Map<String, Uint8List?> _cache = {};
  static final Map<String, Future<Uint8List?>> _pending = {};

  static Future<Uint8List?> load(Uri url, AppSettings settings) {
    final key = '${settings.username}|$url';
    if (_cache.containsKey(key)) return Future.value(_cache[key]);

    final pending = _pending[key];
    if (pending != null) return pending;

    final future = _fetch(url, settings)
        .then((bytes) {
          if (_cache.length >= _maxEntries) {
            _cache.remove(_cache.keys.first);
          }
          _cache[key] = bytes;
          return bytes;
        })
        .whenComplete(() => _pending.remove(key));

    _pending[key] = future;
    return future;
  }

  static Future<Uint8List?> _fetch(Uri url, AppSettings settings) async {
    final client = OpdsClient(
      username: settings.username,
      password: settings.password,
    );
    try {
      return await client.fetchBytes(url);
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}
