part of 'settings_bloc.dart';

enum SettingsStatus { initial, ready, failure }

class SettingsState extends Equatable {
  const SettingsState({
    required this.settings,
    required this.status,
    this.error,
  });

  final AppSettings settings;
  final SettingsStatus status;

  /// Message of the failed write, shown once as a snackbar.
  final String? error;

  SettingsState copyWith({
    AppSettings? settings,
    SettingsStatus? status,
    String? error,
    bool clearError = false,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [settings, status, error];
}
