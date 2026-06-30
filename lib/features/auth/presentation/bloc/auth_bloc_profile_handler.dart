part of 'auth_bloc.dart';

Future<void> _handleUpdateProfile(
  AuthBloc bloc,
  UpdateProfileRequested event,
  Emitter<AuthState> emit,
) async {
  emit(bloc.state.copyWith(status: AuthStatus.loading));
  final result = await bloc.updateProfileUseCase(
    UpdateProfileParams(fullName: event.fullName, email: event.email),
  );
  result.fold(
    (failure) => emit(bloc.state.copyWith(
      status: AuthStatus.error,
      errorMessage: failure.message,
    )),
    (_) => emit(bloc.state.copyWith(
      user: bloc.state.user.copyWith(fullName: event.fullName),
      status: AuthStatus.authenticated,
      successMessage: 'Profil berhasil diperbarui.',
      clearError: true,
    )),
  );
}
