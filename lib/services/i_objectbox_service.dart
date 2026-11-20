import '../entity/app_settings.dart';
import '../entity/favorite.dart';

/// Storage used by the settings and favorites flows.
///
/// The interface keeps the BLoCs independent of ObjectBox so tests can supply
/// an in-memory implementation.
abstract class IObjectBoxService {
  /// Reads the stored settings row after the database is opened.
  Future<void> init();

  /// Closes the database.
  void dispose();

  /// Current settings, or the defaults when nothing was saved yet.
  AppSettings getAppSettings();

  /// Stores [settings], replacing the previous values.
  void saveAppSettings(AppSettings settings);

  /// Books saved from the catalog, newest first.
  List<Favorite> getFavorites();

  /// Adds [favorite] or replaces the saved row with the same key.
  void saveFavorite(Favorite favorite);

  /// Removes the saved book with [key], if any.
  void removeFavorite(String key);
}
