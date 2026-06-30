part of 'auth_bloc.dart';

Future<void> _handleUpdatePassword(
  AuthBloc bloc,
  AuthPasswordUpdateRequested event,
  Emitter<AuthState> emit,
) async {
  final recovery = bloc.state.status == AuthStatus.passwordRecovery;
  final currentUser = bloc.state.user;
  emit(bloc.state.copyWith(status: AuthStatus.loading));
  final result = await bloc.updatePasswordUseCase(event.newPassword);
  await result.fold(
    (failure) async => emit(bloc.state.copyWith(
      status: AuthStatus.error,
      errorMessage: failure.message,
    )),
    (_) async {
      if (recovery) {
        bloc._signOutInProgress = true;
        await bloc.logoutUseCase(const NoParams());
        bloc._signOutInProgress = false;
      }
      emit(AuthState(
        status: AuthStatus.success,
        user: recovery ? AuthUser.empty : currentUser,
        successMessage: recovery
            ? 'Kata sandi berhasil diatur ulang.'
            : 'Kata sandi berhasil diperbarui.',
      ));
    },
  );
}
