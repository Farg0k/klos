import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../entity/app_settings.dart';
import '../../../services/i_objectbox_service.dart';
import '../../../services/server_service.dart';
import '../../../utils/locator.dart';

part 'home_event.dart';
part 'home_state.dart';

/// Wraps [ServerService] in BLoC state for the home screen.
///
/// The service keeps logging while the server runs, so the bloc listens to it
/// and mirrors every change into a new state.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc()
    : _server = locator<ServerService>(),
      _objectbox = locator<IObjectBoxService>(),
      super(HomeState.initial()) {
    _server.addListener(_onServerChanged);
    on<HomeStarted>(_onStarted);
    on<HomeAutoStartRequested>(_onAutoStart);
    on<HomeSettingsChanged>(_onSettingsChanged);
    on<HomeStartRequested>(_onStart);
    on<HomeStopRequested>(_onStop);
    on<HomeRefreshRequested>(_onRefresh);
    on<HomeClearLogsRequested>(_onClearLogs);
    on<HomePinRefreshRequested>(_onPinRefresh);
    on<HomeResumedChanged>(_onResumedChanged);
    on<HomeServerChanged>(_onServerNotified);
  }

  final ServerService _server;
  final IObjectBoxService _objectbox;

  void _onServerChanged() {
    if (!isClosed) add(const HomeServerChanged());
  }

  Future<void> _onStarted(HomeStarted event, Emitter<HomeState> emit) async {
    await _server.init(_objectbox.getAppSettings());
    emit(_snapshot(state.copyWith(loaded: true)));
    add(const HomeAutoStartRequested());
  }

  Future<void> _onAutoStart(
    HomeAutoStartRequested event,
    Emitter<HomeState> emit,
  ) async {
    await _server.maybeAutoStart();
    emit(_snapshot(state));
  }

  Future<void> _onSettingsChanged(
    HomeSettingsChanged event,
    Emitter<HomeState> emit,
  ) async {
    await _server.applySettings(event.settings);
    emit(_snapshot(state));
  }

  Future<void> _onStart(
    HomeStartRequested event,
    Emitter<HomeState> emit,
  ) async {
    await _server.startServer();
    emit(_snapshot(state));
  }

  Future<void> _onStop(HomeStopRequested event, Emitter<HomeState> emit) async {
    await _server.stopServer();
    emit(_snapshot(state));
  }

  Future<void> _onRefresh(
    HomeRefreshRequested event,
    Emitter<HomeState> emit,
  ) async {
    await _server.refreshAddresses();
    emit(_snapshot(state));
  }

  void _onClearLogs(HomeClearLogsRequested event, Emitter<HomeState> emit) {
    _server.clearLogs();
    emit(_snapshot(state));
  }

  void _onPinRefresh(HomePinRefreshRequested event, Emitter<HomeState> emit) {
    _server.refreshPin();
    emit(_snapshot(state));
  }

  Future<void> _onResumedChanged(
    HomeResumedChanged event,
    Emitter<HomeState> emit,
  ) async {
    _server.setResumed(event.resumed);
    if (event.resumed) await _server.refreshAddresses();
    emit(_snapshot(state));
  }

  void _onServerNotified(HomeServerChanged event, Emitter<HomeState> emit) {
    emit(_snapshot(state));
  }

  /// Stops the server before the app leaves, used by the exit dialog.
  ///
  /// The service notifies its listeners, so the resulting state update still
  /// reaches the screen while the app is closing.
  Future<void> shutdown() => _server.stopServer();

  HomeState _snapshot(HomeState current) {
    return current.copyWith(
      settings: _server.settings,
      addresses: _server.addresses,
      logs: _server.logs,
      running: _server.isRunning,
      busy: _server.busy,
      configured: _server.canServe,
      lastError: _server.lastError,
      clearLastError: _server.lastError == null,
      pin: _server.currentPin,
      clearPin: _server.currentPin == null,
    );
  }

  @override
  Future<void> close() {
    _server.removeListener(_onServerChanged);
    return super.close();
  }
}
