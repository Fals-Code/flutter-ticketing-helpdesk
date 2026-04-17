import 'package:equatable/equatable.dart';
import '../../../domain/entities/app_settings_entity.dart';

enum AppSettingsStatus { initial, loading, success, error }

class AppSettingsState extends Equatable {
  final AppSettingsStatus status;
  final AppSettings settings;
  final String? errorMessage;
  final String? successMessage;

  const AppSettingsState({
    this.status = AppSettingsStatus.initial,
    this.settings = const AppSettings.defaultSettings(),
    this.errorMessage,
    this.successMessage,
  });

  AppSettingsState copyWith({
    AppSettingsStatus? status,
    AppSettings? settings,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AppSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props => [status, settings, errorMessage, successMessage];
}
