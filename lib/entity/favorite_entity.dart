import 'dart:convert';

import 'package:objectbox/objectbox.dart';

import '../opds/opds_feed.dart';
import 'favorite.dart';

/// ObjectBox representation of [Favorite].
///
/// Links are stored as a small JSON array: ObjectBox cannot persist the
/// [OpdsLink] class directly, and the cover has to survive too.
@Entity()
class FavoriteEntity {
  FavoriteEntity({
    this.id = 0,
    this.key = '',
    this.title = '',
    this.author = '',
    this.summary = '',
    this.links = '',
    this.catalogUrl = '',
    this.addedAt = 0,
  });

  @Id()
  int id;

  /// [Favorite.key]: the first download link of the book.
  String key;

  String title;
  String author;
  String summary;

  /// JSON array of `{h, r, t, n}` link objects.
  String links;

  String catalogUrl;

  /// [Favorite.addedAt] as milliseconds since the epoch.
  int addedAt;

  factory FavoriteEntity.fromFavorite(Favorite favorite) {
    return FavoriteEntity(
      id: favorite.id,
      key: favorite.key,
      title: favorite.title,
      author: favorite.author ?? '',
      summary: favorite.summary ?? '',
      links: _encodeLinks(favorite.links),
      catalogUrl: favorite.catalogUrl,
      addedAt: favorite.addedAt.millisecondsSinceEpoch,
    );
  }

  Favorite toFavorite() {
    return Favorite(
      id: id,
      key: key,
      title: title,
      author: author.trim().isEmpty ? null : author,
      summary: summary.trim().isEmpty ? null : summary,
      links: _decodeLinks(links),
      catalogUrl: catalogUrl,
      addedAt: DateTime.fromMillisecondsSinceEpoch(addedAt),
    );
  }

  static String _encodeLinks(List<OpdsLink> links) {
    return jsonEncode([
      for (final link in links)
        {
          'h': link.href.toString(),
          'r': link.rel,
          if (link.type != null && link.type!.isNotEmpty) 't': link.type,
          if (link.title != null && link.title!.isNotEmpty) 'n': link.title,
        },
    ]);
  }

  static List<OpdsLink> _decodeLinks(String raw) {
    if (raw.trim().isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final links = <OpdsLink>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final href = item['h'];
        if (href is! String) continue;
        final uri = Uri.tryParse(href);
        if (uri == null) continue;
        links.add(
          OpdsLink(
            href: uri,
            rel: item['r'] is String ? item['r'] as String : '',
            type: item['t'] is String ? item['t'] as String : null,
            title: item['n'] is String ? item['n'] as String : null,
          ),
        );
      }
      return links;
    } on FormatException {
      return const [];
    }
  }
}
