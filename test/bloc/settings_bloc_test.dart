import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:klos/entity/app_settings.dart';
import 'package:klos/features/settings_screen/bloc/settings_bloc.dart';
import 'package:klos/local/local_files.dart';
import 'package:klos/local/local_storage.dart';

import '../helpers/test_locator.dart';

/// [LocalStorage] that only answers the folder name question.
class _FolderNameStorage implements LocalStorage {
  _FolderNameStorage(this.name);

  final String? name;

  @override
  Future<LocalFolder?> pickFolder() async => null;

  @override
  Future<bool> checkAccess(String uri) async => true;

  @override
  Future<String?> folderName(String uri) async => name;

  @override
  Future<List<LocalEntry>> list(String uri) async => const [];

  @override
  Future<Uint8List> read(String uri, {required int maxBytes}) async =>
      Uint8List(0);

  @override
  Future<LocalSavedFile> write({
    required String folderUri,
    required String name,
    required String mime,
    required Uint8List bytes,
  }) async => LocalSavedFile(name: name, uri: '$folderUri/$name');

  @override
  Future<LocalParent?> parentOf({
    required String treeUri,
    required String uri,
  }) async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeObjectBoxService storage;
  late SettingsBloc bloc;

  setUp(() async {
    storage = await setUpTestLocator(
      settings: const AppSettings(
        catalogUrl: null,
        kindleEmail: 'reader@kindle.com',
      ),
    );
    bloc = SettingsBloc();
  });

  tearDown(() async {
    await bloc.close();
    await tearDownTestLocator();
  });

  test('loads the stored settings and becomes ready', () async {
    final ready = bloc.stream.firstWhere(
      (state) => state.status == SettingsStatus.ready,
    );

    bloc.add(const SettingsStarted());
    await ready;

    expect(bloc.state.settings.kindleEmail, 'reader@kindle.com');
  });

  test('replaces a stale folder name with the picked one', () async {
    // A folder chosen before the fix was saved as «Downloads» even when the
    // user picked Download/Books inside it.
    await bloc.close();
    await tearDownTestLocator();
    storage = await setUpTestLocator(
      settings: const AppSettings(
        catalogUrl: null,
        localFolderUri:
            'content://com.android.externalstorage.documents/tree/'
            'primary%3ADownload%2FBooks',
        localFolderName: 'Downloads',
      ),
      localStorage: _FolderNameStorage('Books'),
    );
    bloc = SettingsBloc();

    final ready = bloc.stream.firstWhere(
      (state) => state.status == SettingsStatus.ready,
    );
    bloc.add(const SettingsStarted());
    await ready;

    expect(bloc.state.settings.localFolderName, 'Books');
    expect(storage.settings.localFolderName, 'Books');
  });

  test('saves normalized settings through ObjectBox', () async {
    final saved = bloc.stream.firstWhere(
      (state) => state.settings.port == 9090,
    );

    bloc.add(
      const SettingsSaved(
        AppSettings(
          catalogUrl: null,
          port: 9090,
          kindleEmail: ' reader@kindle.com ',
        ),
      ),
    );
    await saved;

    expect(storage.saveCount, 1);
    expect(storage.settings.port, 9090);
    expect(storage.settings.kindleEmail, 'reader@kindle.com');
    expect(bloc.state.settings, storage.settings);
  });

  test('a folder change keeps the other settings', () async {
    final picked = bloc.stream.firstWhere(
      (state) => state.settings.hasLocalFolder,
    );

    bloc.add(
      const SettingsFolderChanged(
        LocalFolder(
          uri: 'content://example/tree/primary%3ABooks',
          name: 'Books',
        ),
      ),
    );
    await picked;

    expect(storage.settings.hasLocalFolder, isTrue);
    expect(storage.settings.localFolderName, 'Books');
    expect(storage.settings.kindleEmail, 'reader@kindle.com');
  });

  test('resetting the folder clears its URI and name', () async {
    bloc.add(
      const SettingsFolderChanged(
        LocalFolder(
          uri: 'content://example/tree/primary%3ABooks',
          name: 'Books',
        ),
      ),
    );
    await bloc.stream.firstWhere((state) => state.settings.hasLocalFolder);

    final reset = bloc.stream.firstWhere(
      (state) => !state.settings.hasLocalFolder,
    );
    bloc.add(const SettingsFolderChanged(null));
    await reset;

    expect(storage.settings.localFolderUri, '');
    expect(storage.settings.localFolderName, '');
    expect(storage.settings.kindleEmail, 'reader@kindle.com');
  });

  test('reports a failed save without losing the old settings', () async {
    storage.failOnSave = true;
    final failed = bloc.stream.firstWhere(
      (state) => state.status == SettingsStatus.failure,
    );

    bloc.add(const SettingsSaved(AppSettings(catalogUrl: null, port: 9090)));
    await failed;

    expect(bloc.state.error, isNotNull);
    expect(bloc.state.settings.port, AppSettings.defaultPort);
    expect(storage.settings.port, AppSettings.defaultPort);
  });
}
