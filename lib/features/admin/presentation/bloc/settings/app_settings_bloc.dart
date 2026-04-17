import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/usecases/usecase.dart';
import '../../../domain/usecases/app_settings_usecases.dart';
import 'app_settings_event.dart';
import 'app_settings_state.dart';

class AppSettingsBloc extends Bloc<AppSettingsEvent, AppSettingsState> {
  final GetAppSettingsUseCase getAppSettingsUseCase;
  final UpdateAppSettingsUseCase updateAppSettingsUseCase;

  AppSettingsBloc({
    required this.getAppSettingsUseCase,
    required this.updateAppSettingsUseCase,
  }) : super(const AppSettingsState()) {
    on<FetchAppSettingsRequested>(_onFetchSettings);
    on<UpdateAppSettingsRequested>(_onUpdateSettings);
  }

  Future<void> _onFetchSettings(
    FetchAppSettingsRequested event,
    Emitter<AppSettingsState> emit,
  ) async {
    emit(state.copyWith(status: AppSettingsStatus.loading));
    final result = await getAppSettingsUseCase(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(status: AppSettingsStatus.error, errorMessage: failure.message)),
      (settings) => emit(state.copyWith(status: AppSettingsStatus.success, settings: settings)),
    );
  }

  Future<void> _onUpdateSettings(
    UpdateAppSettingsRequested event,
    Emitter<AppSettingsState> emit,
  ) async {
    emit(state.copyWith(status: AppSettingsStatus.loading));
    final result = await updateAppSettingsUseCase(event.settings);
    result.fold(
      (failure) => emit(state.copyWith(status: AppSettingsStatus.error, errorMessage: failure.message)),
      (_) {
        emit(state.copyWith(
          status: AppSettingsStatus.success,
          settings: event.settings,
          successMessage: 'Pengaturan berhasil disimpan',
        ));
      },
    );
  }
}
