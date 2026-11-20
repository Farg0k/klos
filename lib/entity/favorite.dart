import '../opds/opds_feed.dart';

/// A book saved from the catalog so it can be opened on the Kindle later.
///
/// Only entries with at least one download link can be saved; navigation
/// entries (subcatalogs) are not books and return null from [fromEntry].
class Favorite {
  const Favorite({
    required this.key,
    required this.title,
    required this.links,
    required this.addedAt,
    this.id = 0,
    this.author,
    this.summary,
    this.catalogUrl = '',
  });

  /// Database row id; 0 until the favorite is saved.
  final int id;

  /// Stable identity of the book, derived from its first download link.
  final String key;

  final String title;
  final String? author;
  final String? summary;

  /// Download links plus the cover link, if the feed had one.
  final List<OpdsLink> links;

  /// Catalog the book came from, kept for reference only.
  final String catalogUrl;

  /// When the book was added, used to show the newest first.
  final DateTime addedAt;

  /// Identity of [entry], or null when it cannot be downloaded.
  static String? keyFor(OpdsEntry entry) {
    final links = entry.downloadLinks;
    if (links.isEmpty) return null;
    return links.first.href.toString();
  }

  /// Creates a favorite from a catalog [entry].
  ///
  /// Returns null for navigation entries and for books without a download
  /// link, because there would be nothing to show on the Kindle.
  static Favorite? fromEntry(OpdsEntry entry, {String catalogUrl = ''}) {
    final key = keyFor(entry);
    if (key == null) return null;
    final cover = entry.coverLink;
    return Favorite(
      key: key,
      title: entry.title,
      author: entry.author,
      summary: entry.summary,
      links: [...entry.downloadLinks, ?cover],
      catalogUrl: catalogUrl,
      addedAt: DateTime.now(),
    );
  }

  /// Entry that the server renders with the usual download and mail buttons.
  OpdsEntry toEntry() {
    return OpdsEntry(
      title: title,
      author: author,
      summary: summary,
      links: links,
    );
  }
}
