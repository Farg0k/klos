part of 'update_bloc.dart';

sealed class UpdateEvent extends Equatable {
  const UpdateEvent();

  @override
  List<Object?> get props => [];
}

/// Runs the check once, quietly, when the app opens.
class UpdateStarted extends UpdateEvent {
  const UpdateStarted();
}

/// Asks again from the «About» sheet or the banner.
class UpdateCheckRequested extends UpdateEvent {
  const UpdateCheckRequested();
}

/// Hides the banner until the next launch.
class UpdateDismissed extends UpdateEvent {
  const UpdateDismissed();
}

/// Downloads the APK that was found and opens the Android installer.
class UpdateInstallRequested extends UpdateEvent {
  const UpdateInstallRequested();
}

/// Reports download progress while [UpdateInstallRequested] runs.
class UpdateProgressChanged extends UpdateEvent {
  const UpdateProgressChanged(this.percent);

  final int percent;

  @override
  List<Object?> get props => [percent];
}
