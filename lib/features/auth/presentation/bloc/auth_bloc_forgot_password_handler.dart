part of 'auth_bloc.dart';

Future<void> _handleForgotPassword(
  AuthBloc bloc,
  ResetPasswordRequested event,
  Emitter<AuthState> emit,
) async {
  emit(bloc.state.copyWith(status: AuthStatus.loading));
  final result = await bloc.resetPasswordUseCase(event.email);
  result.fold(
    (failure) => emit(bloc.state.copyWith(
      status: AuthStatus.error,
      errorMessage: failure.message,
    )),
    (_) => emit(bloc.state.copyWith(
      status: AuthStatus.success,
      successMessage: 'Jika email terdaftar, instruksi reset telah dikirim.',
      clearError: true,
    )),
  );
}
