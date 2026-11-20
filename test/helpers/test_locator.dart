import 'package:klos/entity/app_settings.dart';
import 'package:klos/entity/favorite.dart';
import 'package:klos/local/local_storage.dart';
import 'package:klos/services/i_objectbox_service.dart';
import 'package:klos/services/server_service.dart';
import 'package:klos/utils/locator.dart';

/// In-memory stand-in for [IObjectBoxService].
///
/// The BLoCs and widget tests do not need a real database; they only need a
/// settings value that survives between calls.
class FakeObjectBoxService implements IObjectBoxService {
  FakeObjectBoxService([AppSettings? initial])
    : settings = initial ?? const AppSettings(catalogUrl: null);

  AppSettings settings;

  /// How many times [saveAppSettings] was called.
  int saveCount = 0;

  /// Makes the next saves fail, to test the error state.
  bool failOnSave = false;

  @override
  Future<void> init() async {}

  @override
  void dispose() {}

  @override
  AppSettings getAppSettings() => settings;

  @override
  void saveAppSettings(AppSettings settings) {
    if (failOnSave) throw StateError('storage is read-only');
    this.settings = settings;
    saveCount++;
  }

  final List<Favorite> _favorites = [];

  @override
  List<Favorite> getFavorites() {
    return List<Favorite>.of(_favorites)
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
  }

  @override
  void saveFavorite(Favorite favorite) {
    _favorites.removeWhere((item) => item.key == favorite.key);
    _favorites.add(favorite);
  }

  @override
  void removeFavorite(String key) {
    _favorites.removeWhere((item) => item.key == key);
  }
}

/// Registers the fake storage and a fresh [ServerService] in the locator.
///
/// Call it before pumping [KlosApp] or creating a BLoC; tests that need the
/// fake instance keep the returned value. [localStorage] lets a test answer
/// folder questions without Android.
Future<FakeObjectBoxService> setUpTestLocator({
  AppSettings? settings,
  LocalStorage? localStorage,
}) async {
  await locator.reset();
  final fake = FakeObjectBoxService(settings);
  locator.registerSingleton<IObjectBoxService>(fake);
  locator.registerSingleton<ServerService>(
    ServerService(
      localStorage: localStorage,
      addressLoader: () async => const [],
      favoritesProvider: fake.getFavorites,
    ),
  );
  return fake;
}

/// Releases the services registered by [setUpTestLocator].
Future<void> tearDownTestLocator() async {
  if (locator.isRegistered<ServerService>()) {
    locator<ServerService>().dispose();
  }
  await locator.reset();
}
