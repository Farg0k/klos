import '../books/ebook_formats.dart';
import '../books/kindle_file.dart';
import '../entity/app_settings.dart';
import '../l10n/l10n.dart';
import '../local/local_files.dart';
import '../local/local_storage.dart';
import '../opds/opds_client.dart';
import '../opds/opds_feed.dart';
import '../server/file_names.dart';

/// Loads a book from its catalog link.
///
/// Replaced in tests so the download can run without a network.
typedef RemoteBookSource = Future<RemoteBook> Function(OpdsLink link);

/// A book written into the folder the Kindle can read.
class SavedBook {
  const SavedBook({required this.name, required this.uri, required this.mime});

  /// Name the provider actually gave the file; it may differ from the
  /// requested one when a file with the same name already exists.
  final String name;

  /// `content://` URI of the written document.
  final String uri;

  final String mime;
}

/// Downloads a catalog book into the chosen local folder.
///
/// The file is prepared by [deliverDownloadedBook], so a download made in the
/// app is exactly the file the Kindle browser would receive: ZIP archives are
/// unpacked and EPUB or FB2 are converted into MOBI.
class FolderDownloader {
  FolderDownloader({
    required this.settings,
    LocalStorage? storage,
    RemoteBookSource? load,
    String? languageCode,
  }) : _storage = storage ?? const SafLocalStorage(),
       // ignore: prefer_initializing_formals
       _load = load,
       // ignore: prefer_initializing_formals
       _languageCode = languageCode;

  final AppSettings settings;
  final LocalStorage _storage;
  final RemoteBookSource? _load;
  final String? _languageCode;

  /// Picks the link that needs the least work on the phone.
  ///
  /// A Kindle-native file is saved untouched, an EPUB or FB2 is converted only
  /// when nothing better is offered, and anything else is kept as a last
  /// resort so an unusual catalog still downloads something.
  static OpdsLink? preferredDownloadLink(Iterable<OpdsLink> links) {
    OpdsLink? direct;
    OpdsLink? convertible;
    OpdsLink? first;
    for (final link in links) {
      if (!link.isAcquisition) continue;
      first ??= link;
      if (EbookFormat.downloadsDirectly(link.type)) {
        direct ??= link;
      } else if (EbookFormat.convertible(link.type)) {
        convertible ??= link;
      }
    }
    return direct ?? convertible ?? first;
  }

  Future<SavedBook> download(OpdsEntry entry) async {
    final folderUri = settings.localFolderUri.trim();
    if (folderUri.isEmpty) {
      throw LocalStorageException(l10n.localFolderNotChosen);
    }
    final link = preferredDownloadLink(entry.downloadLinks);
    if (link == null) throw OpdsException(l10n.downloadLinkMissing);

    final remote = await (_load ?? _loadFromCatalog)(link);
    final book = await deliverDownloadedBook(
      bytes: remote.bytes,
      url: remote.url,
      title: entry.title,
      mime: remote.mime,
      contentEncoding: remote.contentEncoding,
      languageCode: _languageCode ?? L10n.languageCode,
    );
    final name = fileNameFor(
      url: book.url,
      title: entry.title,
      mime: book.mime,
    );
    final saved = await _storage.write(
      folderUri: folderUri,
      name: name,
      mime: book.mime,
      bytes: book.bytes,
    );
    return SavedBook(name: saved.name, uri: saved.uri, mime: book.mime);
  }

  Future<RemoteBook> _loadFromCatalog(OpdsLink link) async {
    final client = OpdsClient(
      username: settings.username,
      password: settings.password,
    );
    try {
      return await readRemoteBook(client: client, link: link);
    } finally {
      client.close();
    }
  }
}
