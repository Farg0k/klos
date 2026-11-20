part of 'home_bloc.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class HomeStarted extends HomeEvent {
  const HomeStarted();
}

class HomeAutoStartRequested extends HomeEvent {
  const HomeAutoStartRequested();
}

class HomeSettingsChanged extends HomeEvent {
  const HomeSettingsChanged(this.settings);

  final AppSettings settings;

  @override
  List<Object?> get props => [settings];
}

class HomeStartRequested extends HomeEvent {
  const HomeStartRequested();
}

class HomeStopRequested extends HomeEvent {
  const HomeStopRequested();
}

class HomeRefreshRequested extends HomeEvent {
  const HomeRefreshRequested();
}

class HomeClearLogsRequested extends HomeEvent {
  const HomeClearLogsRequested();
}

class HomePinRefreshRequested extends HomeEvent {
  const HomePinRefreshRequested();
}

class HomeResumedChanged extends HomeEvent {
  const HomeResumedChanged(this.resumed);

  final bool resumed;

  @override
  List<Object?> get props => [resumed];
}

class HomeServerChanged extends HomeEvent {
  const HomeServerChanged();
}
