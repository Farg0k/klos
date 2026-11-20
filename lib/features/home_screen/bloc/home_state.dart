part of 'home_bloc.dart';

class HomeState extends Equatable {
  const HomeState({
    required this.settings,
    required this.addresses,
    required this.logs,
    required this.running,
    required this.busy,
    required this.configured,
    required this.lastError,
    required this.loaded,
    required this.pin,
  });

  factory HomeState.initial() => const HomeState(
    settings: AppSettings.initial,
    addresses: [],
    logs: [],
    running: false,
    busy: false,
    configured: false,
    lastError: null,
    loaded: false,
    pin: null,
  );

  final AppSettings settings;
  final List<LocalAddress> addresses;
  final List<String> logs;
  final bool running;
  final bool busy;
  final bool configured;
  final String? lastError;
  final bool loaded;

  /// PIN the Kindle has to type, or null when protection is off.
  final String? pin;

  HomeState copyWith({
    AppSettings? settings,
    List<LocalAddress>? addresses,
    List<String>? logs,
    bool? running,
    bool? busy,
    bool? configured,
    String? lastError,
    bool clearLastError = false,
    bool? loaded,
    String? pin,
    bool clearPin = false,
  }) {
    return HomeState(
      settings: settings ?? this.settings,
      addresses: addresses ?? this.addresses,
      logs: logs ?? this.logs,
      running: running ?? this.running,
      busy: busy ?? this.busy,
      configured: configured ?? this.configured,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
      loaded: loaded ?? this.loaded,
      pin: clearPin ? null : (pin ?? this.pin),
    );
  }

  @override
  List<Object?> get props => [
    settings,
    addresses,
    logs,
    running,
    busy,
    configured,
    lastError,
    loaded,
    pin,
  ];
}
