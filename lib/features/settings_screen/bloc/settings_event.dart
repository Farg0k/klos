part of 'settings_bloc.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class SettingsStarted extends SettingsEvent {
  const SettingsStarted();
}

class SettingsSaved extends SettingsEvent {
  const SettingsSaved(this.settings);

  final AppSettings settings;

  @override
  List<Object?> get props => [settings];
}

class SettingsFolderChanged extends SettingsEvent {
  const SettingsFolderChanged(this.folder);

  final LocalFolder? folder;

  @override
  List<Object?> get props => [folder?.uri, folder?.name];
}
