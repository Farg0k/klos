import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import 'local_files.dart';

/// Access to the folder the user chose through the Storage Access Framework.
///
/// The implementation lives behind an interface so the HTTP server can be
/// tested without an Android device.
abstract class LocalStorage {
  /// Opens Android's folder picker and remembers the returned permission.
  Future<LocalFolder?> pickFolder();

  /// Whether the persisted permission for [uri] still works.
  Future<bool> checkAccess(String uri);

  /// Display name of the folder [uri] points at, read from the provider.
  ///
  /// Used to repair names saved before the picker started reading the picked
  /// document instead of the tree root.
  Future<String?> folderName(String uri);

  /// Lists one folder level.
  Future<List<LocalEntry>> list(String uri);

  /// Reads a file into memory, refusing files larger than [maxBytes].
  Future<Uint8List> read(String uri, {required int maxBytes});

  /// Writes [bytes] into [folderUri] under [name].
  ///
  /// The provider may adjust the name to keep it unique, so the returned
  /// [LocalSavedFile] is the source of truth for the file that was created.
  Future<LocalSavedFile> write({
    required String folderUri,
    required String name,
    required String mime,
    required Uint8List bytes,
  });

  /// Parent folder of [uri] and the display name of [uri] itself.
  ///
  /// Returns null when [uri] is the root of [treeUri].
  Future<LocalParent?> parentOf({required String treeUri, required String uri});

  /// Whether [candidate] is the tree root or a document below it.
  ///
  /// Every URI that comes from the Kindle browser is checked with this before
  /// it is read, so a crafted link cannot reach documents outside the folder
  /// the user picked.
  static bool isUnder(String treeUri, String candidate) {
    final tree = Uri.tryParse(treeUri.trim());
    final target = Uri.tryParse(candidate.trim());
    if (tree == null || target == null) return false;
    if (tree.scheme != 'content' || target.scheme != 'content') return false;
    if (tree.authority != target.authority) return false;

    final rootId = _treeDocumentId(tree);
    final documentId = _documentId(target);
    if (rootId == null || documentId == null) return false;
    return documentId == rootId || documentId.startsWith('$rootId/');
  }

  static String? _treeDocumentId(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length >= 2 && segments.first == 'tree') return segments[1];
    return _documentId(uri);
  }

  static String? _documentId(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length >= 4 && segments[segments.length - 2] == 'document') {
      return segments.last;
    }
    if (segments.length >= 2 && segments.first == 'tree') return segments[1];
    return null;
  }
}

/// [LocalStorage] backed by a small Android MethodChannel.
class SafLocalStorage implements LocalStorage {
  const SafLocalStorage();

  static const MethodChannel _channel = MethodChannel('klos/files');

  @override
  Future<LocalFolder?> pickFolder() async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'pickFolder',
      );
      if (result == null) return null;
      final uri = (result['uri'] as String? ?? '').trim();
      if (uri.isEmpty) return null;
      final name = (result['name'] as String? ?? '').trim();
      return LocalFolder(
        uri: uri,
        name: name.isEmpty ? l10n.localFolderDefaultName : name,
      );
    } on MissingPluginException {
      throw LocalStorageException(l10n.localFolderAndroidOnly);
    } on PlatformException catch (error) {
      throw LocalStorageException(
        l10n.localFolderPickerFailed(error.message ?? error.code),
      );
    }
  }

  @override
  Future<bool> checkAccess(String uri) async {
    try {
      return await _channel.invokeMethod<bool>('checkAccess', {'uri': uri}) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<String?> folderName(String uri) async {
    try {
      final name = await _channel.invokeMethod<String>('folderName', {
        'uri': uri,
      });
      final trimmed = name?.trim() ?? '';
      return trimmed.isEmpty ? null : trimmed;
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<List<LocalEntry>> list(String uri) async {
    try {
      final result = await _channel.invokeMethod<List<Object?>>('listFolder', {
        'uri': uri,
      });
      if (result == null) return const [];
      return result
          .whereType<Map<Object?, Object?>>()
          .map(LocalEntry.fromMap)
          .where((entry) => entry.name.isNotEmpty && entry.uri.isNotEmpty)
          .toList();
    } on MissingPluginException {
      throw LocalStorageException(l10n.localFolderAndroidOnly);
    } on PlatformException catch (error) {
      throw LocalStorageException(
        l10n.localFolderReadFailed(error.message ?? error.code),
      );
    }
  }

  @override
  Future<Uint8List> read(String uri, {required int maxBytes}) async {
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('readFile', {
        'uri': uri,
        'maxBytes': maxBytes,
      });
      return bytes ?? Uint8List(0);
    } on MissingPluginException {
      throw LocalStorageException(l10n.localFolderAndroidOnly);
    } on PlatformException catch (error) {
      if (error.code == 'file_too_large') {
        throw LocalStorageException(
          l10n.localFileTooLarge((maxBytes / (1024 * 1024)).round()),
        );
      }
      throw LocalStorageException(
        l10n.localFileReadFailed(error.message ?? error.code),
      );
    }
  }

  @override
  Future<LocalSavedFile> write({
    required String folderUri,
    required String name,
    required String mime,
    required Uint8List bytes,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'writeFile',
        {'uri': folderUri, 'name': name, 'mime': mime, 'bytes': bytes},
      );
      if (result == null) {
        throw LocalStorageException(
          l10n.localFolderWriteFailed(l10n.unknownError),
        );
      }
      final uri = (result['uri'] as String? ?? '').trim();
      final savedName = (result['name'] as String? ?? '').trim();
      if (uri.isEmpty) {
        throw LocalStorageException(
          l10n.localFolderWriteFailed(l10n.unknownError),
        );
      }
      return LocalSavedFile(
        name: savedName.isEmpty ? name : savedName,
        uri: uri,
      );
    } on MissingPluginException {
      throw LocalStorageException(l10n.localFolderAndroidOnly);
    } on PlatformException catch (error) {
      if (error.code == 'write_denied') {
        throw LocalStorageException(l10n.localFolderWriteDenied);
      }
      throw LocalStorageException(
        l10n.localFolderWriteFailed(error.message ?? error.code),
      );
    }
  }

  @override
  Future<LocalParent?> parentOf({
    required String treeUri,
    required String uri,
  }) async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('parent', {
        'treeUri': treeUri,
        'uri': uri,
      });
      if (result == null) return null;
      final parentUri = (result['uri'] as String? ?? '').trim();
      if (parentUri.isEmpty) return null;
      return LocalParent(
        uri: parentUri,
        name: (result['name'] as String? ?? '').trim(),
      );
    } on MissingPluginException {
      throw LocalStorageException(l10n.localFolderAndroidOnly);
    } on PlatformException catch (error) {
      throw LocalStorageException(
        l10n.localFolderReadFailed(error.message ?? error.code),
      );
    }
  }
}
