part of 'update_bloc.dart';

/// Where the check stands.
enum UpdateStatus {
  /// No answer yet.
  idle,

  /// A request to GitHub is in flight.
  checking,

  /// A newer release was found and is waiting to be installed.
  available,

  /// The installed version is the newest one.
  upToDate,

  /// The check or the install failed; [UpdateState.error] says why.
  failed,
}

class UpdateState extends Equatable {
  const UpdateState({
    this.status = UpdateStatus.idle,
    this.update,
    this.error,
    this.downloadPercent,
    this.installing = false,
    this.dismissed = false,
  });

  final UpdateStatus status;

  /// The newer release, set when [status] is [UpdateStatus.available].
  final AppUpdate? update;

  /// Why the check or the install failed, kept as a code for the screens to
  /// translate.
  final UpdateException? error;

  /// Download progress from 0 to 100, or null when nothing is downloading.
  final int? downloadPercent;

  /// The APK is being handed to the Android installer.
  final bool installing;

  /// The user hid the banner; it stays hidden until the next check finds a
  /// newer release or the app restarts.
  final bool dismissed;

  /// Whether the home screen shows the update banner.
  ///
  /// Only a found release is worth a card on the main screen: a failed silent
  /// check stays quiet, and the «About» sheet is where the details belong.
  bool get showsBanner => !dismissed && status == UpdateStatus.available;

  /// Whether a button that starts the flow should be disabled.
  bool get busy =>
      status == UpdateStatus.checking || downloadPercent != null || installing;

  UpdateState copyWith({
    UpdateStatus? status,
    AppUpdate? update,
    UpdateException? error,
    bool clearError = false,
    int? downloadPercent,
    bool clearDownloadPercent = false,
    bool? installing,
    bool? dismissed,
  }) {
    return UpdateState(
      status: status ?? this.status,
      update: update ?? this.update,
      error: clearError ? null : (error ?? this.error),
      downloadPercent: clearDownloadPercent
          ? null
          : (downloadPercent ?? this.downloadPercent),
      installing: installing ?? this.installing,
      dismissed: dismissed ?? this.dismissed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    update?.version,
    error?.problem,
    error?.detail,
    downloadPercent,
    installing,
    dismissed,
  ];
}
