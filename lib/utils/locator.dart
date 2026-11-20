import 'package:get_it/get_it.dart';

import '../services/i_objectbox_service.dart';
import '../services/objectbox_service.dart';
import '../services/server_service.dart';

/// Service locator used by the BLoCs, mirroring the abook_tome layout.
final locator = GetIt.instance;

/// Opens ObjectBox and registers the services the app needs.
///
/// Settings are loaded before the first frame so the theme and language do
/// not flash the default values on startup.
Future<void> setupLocator() async {
  final objectBox = await ObjectBoxService.create();
  await objectBox.init();
  locator.registerSingleton<IObjectBoxService>(objectBox);
  locator.registerSingleton<ServerService>(
    ServerService(favoritesProvider: objectBox.getFavorites),
  );
}
