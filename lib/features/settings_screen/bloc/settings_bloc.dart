import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../entity/app_settings.dart';
import '../../../l10n/l10n.dart';
import '../../../local/local_files.dart';
import '../../../services/i_objectbox_service.dart';
import '../../../services/server_service.dart';
import '../../../utils/locator.dart';

part 'settings_event.dart';
part 'settings_state.dart';

/// Loads and saves app settings.
///
/// ObjectBox is the only storage. The bloc also applies the language for code
/// that has no `BuildContext` (the HTTP server and mail jobs).
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc()
    : this._(locator<IObjectBoxService>(), locator<ServerService>());

  SettingsBloc._(IObjectBoxService objectbox, ServerService server)
    : _objectbox = objectbox,
      _server = server,
      super(
        SettingsState(
          settings: objectbox.getAppSettings(),
          status: SettingsStatus.initial,
        ),
      ) {
    on<SettingsStarted>(_onStarted);
    on<SettingsSaved>(_onSaved);
    on<SettingsFolderChanged>(_onFolderChanged);
  }

  final IObjectBoxService _objectbox;
  final ServerService _server;

  Future<void> _onStarted(
    SettingsStarted event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      await L10n.apply(state.settings.language);
      final settings = await _refreshFolderName(state.settings);
      emit(state.copyWith(settings: settings, status: SettingsStatus.ready));
    } catch (error) {
      emit(state.copyWith(status: SettingsStatus.failure, error: '$error'));
    }
  }

  /// Repairs the stored folder name when it still points at the tree root.
  ///
  /// Older builds read the name from the tree URI, so a subfolder such as
  /// `Download/Books` was shown as «Downloads». The provider now reports the
  /// name of the picked document; it is saved so the app and the Kindle page
  /// use it as well.
  Future<AppSettings> _refreshFolderName(AppSettings settings) async {
    if (!settings.hasLocalFolder) return settings;
    final name =
        (await _server.localFolderName(settings.localFolderUri))?.trim() ?? '';
    if (name.isEmpty || name == settings.localFolderName) return settings;
    final next = settings.withLocalFolder(
      uri: settings.localFolderUri,
      name: name,
    );
    _objectbox.saveAppSettings(next);
    return next;
  }

  Future<void> _onSaved(
    SettingsSaved event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final next = event.settings.normalized();
      final languageChanged = next.language != state.settings.language;
      _objectbox.saveAppSettings(next);
      if (languageChanged) await L10n.apply(next.language);
      emit(
        state.copyWith(
          settings: next,
          status: SettingsStatus.ready,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: SettingsStatus.failure, error: '$error'));
    }
  }

  Future<void> _onFolderChanged(
    SettingsFolderChanged event,
    Emitter<SettingsState> emit,
  ) async {
    try {
      final folder = event.folder;
      final next = state.settings.withLocalFolder(
        uri: folder?.uri ?? '',
        name: folder?.name ?? '',
      );
      _objectbox.saveAppSettings(next);
      emit(
        state.copyWith(
          settings: next,
          status: SettingsStatus.ready,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(status: SettingsStatus.failure, error: '$error'));
    }
  }

  /// Checks the catalog in the settings form without leaving the screen.
  Future<OpdsPreview> preview(AppSettings draft) => _server.preview(draft);

  /// Sends a test letter with the values currently typed in the form.
  Future<void> sendTestEmail(AppSettings draft) => _server.sendTestEmail(draft);

  /// Opens Android's folder picker.
  Future<LocalFolder?> pickLocalFolder() => _server.pickLocalFolder();
}
