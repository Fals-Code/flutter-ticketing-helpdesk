part of 'auth_bloc.dart';

Future<void> _handleUpdateAvatar(
  AuthBloc bloc,
  UpdateAvatarRequested event,
  Emitter<AuthState> emit,
) async {
  emit(bloc.state.copyWith(status: AuthStatus.loading));
  final result = await bloc.updateAvatarUseCase(event.image);
  result.fold(
    (failure) => emit(bloc.state.copyWith(
      status: AuthStatus.error,
      errorMessage: failure.message,
    )),
    (url) => emit(bloc.state.copyWith(
      user: bloc.state.user.copyWith(avatarUrl: url),
      status: AuthStatus.authenticated,
      successMessage: 'Foto profil berhasil diperbarui.',
      clearError: true,
    )),
  );
}
