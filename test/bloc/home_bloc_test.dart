import 'package:flutter_test/flutter_test.dart';
import 'package:klos/entity/app_settings.dart';
import 'package:klos/features/home_screen/bloc/home_bloc.dart';

import '../helpers/test_locator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeObjectBoxService storage;
  late HomeBloc bloc;

  setUp(() async {
    storage = await setUpTestLocator(
      settings: AppSettings(
        catalogUrl: Uri.parse('http://192.168.1.20:8080/opds'),
        port: 8080,
      ),
    );
    bloc = HomeBloc();
  });

  tearDown(() async {
    await bloc.close();
    await tearDownTestLocator();
  });

  test('starts from the stored settings', () async {
    final loaded = bloc.stream.firstWhere((state) => state.loaded);

    bloc.add(const HomeStarted());
    await loaded;

    expect(bloc.state.settings.port, 8080);
    expect(bloc.state.configured, isTrue);
    expect(bloc.state.running, isFalse);
    expect(bloc.state.addresses, isEmpty);
  });

  test('treats a local folder without a catalog as configured', () async {
    storage.settings = const AppSettings(
      catalogUrl: null,
      localFolderUri: 'content://com.android.externalstorage.documents/tree/primary%3ABooks',
      localFolderName: 'Books',
    );

    final loaded = bloc.stream.firstWhere((state) => state.loaded);
    bloc.add(const HomeStarted());
    await loaded;

    expect(bloc.state.configured, isTrue);
  });

  test('applies settings saved on the settings screen', () async {
    bloc.add(const HomeStarted());
    await bloc.stream.firstWhere((state) => state.loaded);

    final changed = bloc.stream.firstWhere(
      (state) => state.settings.port == 9090,
    );
    bloc.add(
      HomeSettingsChanged(
        AppSettings(
          catalogUrl: Uri.parse('http://192.168.1.20:9090/opds'),
          port: 9090,
        ),
      ),
    );
    await changed;

    expect(bloc.state.settings.port, 9090);
    expect(storage.getAppSettings().port, 8080);
  });

  test('clears the log without touching the storage', () async {
    bloc.add(const HomeStarted());
    await bloc.stream.firstWhere((state) => state.loaded);
    expect(bloc.state.logs, isNotEmpty);

    bloc.add(const HomeClearLogsRequested());
    await bloc.stream.firstWhere((state) => state.logs.isEmpty);

    expect(bloc.state.logs, isEmpty);
  });
}
