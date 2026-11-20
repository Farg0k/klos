import 'package:flutter/foundation.dart';
import 'package:objectbox_flutter_libs/objectbox_flutter_libs.dart';

import '../entity/app_settings.dart';
import '../entity/favorite.dart';
import '../entity/favorite_entity.dart';
import '../entity/settings_entity.dart';
import '../objectbox.g.dart';
import 'i_objectbox_service.dart';

/// ObjectBox-backed settings storage.
class ObjectBoxService implements IObjectBoxService {
  ObjectBoxService._(this.store) {
    _settingsBox = store.box<SettingsEntity>();
    _favoriteBox = store.box<FavoriteEntity>();
  }

  /// Opens a service on an already opened store — only for tests.
  @visibleForTesting
  factory ObjectBoxService.forTesting(Store store) => ObjectBoxService._(store);

  final Store store;
  late final Box<SettingsEntity> _settingsBox;
  late final Box<FavoriteEntity> _favoriteBox;

  /// Row that holds the single settings record. Zero until the first save.
  int _settingsId = 0;

  /// Opens the database, recreating it when an older schema cannot be read.
  ///
  /// Losing settings is better than failing on every start: the catalog
  /// address can be entered again.
  static Future<ObjectBoxService> create() async {
    try {
      return ObjectBoxService._(await openStore());
    } catch (error, stack) {
      debugPrint('ObjectBox failed to open, recreating the store: $error');
      debugPrint('$stack');
      await _deleteStoreDirectory();
      return ObjectBoxService._(await openStore());
    }
  }

  static Future<void> _deleteStoreDirectory() async {
    try {
      final directory = await defaultStoreDirectory();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    } catch (error, stack) {
      debugPrint('Failed to delete the ObjectBox directory: $error');
      debugPrint('$stack');
    }
  }

  @override
  Future<void> init() async {
    final stored = _settingsBox.getAll();
    if (stored.isNotEmpty) _settingsId = stored.first.id;
  }

  @override
  AppSettings getAppSettings() {
    final stored = _settingsBox.getAll();
    if (stored.isEmpty) return AppSettings.initial;
    return stored.first.toSettings();
  }

  @override
  void saveAppSettings(AppSettings settings) {
    final entity = SettingsEntity.fromSettings(settings);
    if (_settingsId != 0) entity.id = _settingsId;
    _settingsId = _settingsBox.put(entity);
  }

  @override
  List<Favorite> getFavorites() {
    final favorites = _favoriteBox
        .getAll()
        .map((entity) => entity.toFavorite())
        .toList();
    favorites.sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return favorites;
  }

  @override
  void saveFavorite(Favorite favorite) {
    final entity = FavoriteEntity.fromFavorite(favorite);
    for (final stored in _favoriteBox.getAll()) {
      if (stored.key == favorite.key) {
        entity.id = stored.id;
        break;
      }
    }
    _favoriteBox.put(entity);
  }

  @override
  void removeFavorite(String key) {
    for (final stored in _favoriteBox.getAll()) {
      if (stored.key == key) {
        _favoriteBox.remove(stored.id);
        break;
      }
    }
  }

  @override
  void dispose() {
    try {
      store.close();
    } catch (error, stack) {
      debugPrint('Failed to close the ObjectBox store: $error');
      debugPrint('$stack');
    }
  }
}
