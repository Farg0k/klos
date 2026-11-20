import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../platform/app_info.dart';
import '../../../platform/app_update.dart';

part 'update_event.dart';
part 'update_state.dart';

/// Checks GitHub Releases for a newer klos and installs it.
///
/// The check runs by itself once per launch, so the home screen can offer an
/// update without the user looking for the button. A failure keeps the message
/// on the home screen but never blocks the app: the local server works without
/// the network.
class UpdateBloc extends Bloc<UpdateEvent, UpdateState> {
  UpdateBloc({AppUpdateService? service, AppInfoLoader? infoLoader})
    : _service = service ?? AppUpdateService(),
      _infoLoader = infoLoader ?? AppInfo.load,
      super(const UpdateState()) {
    on<UpdateStarted>(_onStarted);
    on<UpdateCheckRequested>(_onCheck);
    on<UpdateDismissed>(_onDismissed);
    on<UpdateInstallRequested>(_onInstall);
    on<UpdateProgressChanged>(_onProgress);
  }

  final AppUpdateService _service;
  final AppInfoLoader _infoLoader;

  /// Set by [UpdateStarted], so the automatic check runs only once even when
  /// the screen is rebuilt.
  bool _started = false;

  Future<void> _onStarted(
    UpdateStarted event,
    Emitter<UpdateState> emit,
  ) async {
    if (_started) return;
    _started = true;
    await _check(emit);
  }

  Future<void> _onCheck(
    UpdateCheckRequested event,
    Emitter<UpdateState> emit,
  ) async {
    // A manual request always reports the result, even when the version is
    // current, and reopens the banner the user hid before.
    emit(state.copyWith(dismissed: false, clearError: true));
    await _check(emit, alwaysReport: true);
  }

  void _onDismissed(UpdateDismissed event, Emitter<UpdateState> emit) {
    emit(state.copyWith(dismissed: true));
  }

  void _onProgress(UpdateProgressChanged event, Emitter<UpdateState> emit) {
    emit(state.copyWith(downloadPercent: event.percent));
  }

  Future<void> _onInstall(
    UpdateInstallRequested event,
    Emitter<UpdateState> emit,
  ) async {
    final update = state.update;
    if (update == null || state.busy) return;

    emit(state.copyWith(downloadPercent: 0, clearError: true));
    try {
      final path = await _service.download(
        update,
        onProgress: (percent) => add(UpdateProgressChanged(percent)),
      );
      emit(state.copyWith(clearDownloadPercent: true, installing: true));
      await _service.install(path);
      // The installer is a separate Android activity; the app stays as it is
      // until the user confirms, so nothing else is emitted here.
    } on UpdateException catch (error) {
      emit(
        state.copyWith(
          status: UpdateStatus.failed,
          error: error,
          clearDownloadPercent: true,
          installing: false,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: UpdateStatus.failed,
          error: UpdateException(UpdateProblem.download, '$error'),
          clearDownloadPercent: true,
          installing: false,
        ),
      );
    }
  }

  /// One request to GitHub, shared by the automatic and the manual check.
  Future<void> _check(
    Emitter<UpdateState> emit, {
    bool alwaysReport = false,
  }) async {
    emit(state.copyWith(status: UpdateStatus.checking, clearError: true));
    try {
      final info = await _infoLoader();
      final abis = await _service.deviceAbis();
      final update = await _service.check(
        currentVersion: info.version,
        abis: abis,
      );
      if (update != null) {
        emit(
          state.copyWith(
            status: UpdateStatus.available,
            update: update,
            dismissed: false,
            clearError: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          status: UpdateStatus.upToDate,
          clearError: true,
          // A silent success keeps the home screen clean; the manual check
          // says so explicitly.
          dismissed: !alwaysReport,
        ),
      );
    } on UpdateException catch (error) {
      emit(state.copyWith(status: UpdateStatus.failed, error: error));
    } catch (error) {
      emit(
        state.copyWith(
          status: UpdateStatus.failed,
          error: UpdateException(UpdateProblem.network, '$error'),
        ),
      );
    }
  }
}
