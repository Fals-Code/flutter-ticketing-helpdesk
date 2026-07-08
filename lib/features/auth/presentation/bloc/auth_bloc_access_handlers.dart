part of 'auth_bloc.dart';

Future<void> _handleAppStarted(
  AuthBloc bloc,
  AppStarted event,
  Emitter<AuthState> emit,
) async {
  final result = await bloc.getCurrentUserUseCase(const NoParams());
  result.fold(
    (failure) => emit(AuthState(
      status:
          failure.code == 403 ? AuthStatus.error : AuthStatus.unauthenticated,
      errorMessage: failure.code == 403 ? failure.message : null,
    )),
    (user) => emit(AuthState(
      status: AuthStatus.authenticated,
      user: user,
    )),
  );
}

Future<void> _handleLogin(
  AuthBloc bloc,
  LoginSubmitted event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthState(status: AuthStatus.loading));
  final result = await bloc.loginUseCase(LoginParams(
    identifier: event.identifier,
    password: event.password,
  ));
  result.fold(
    (failure) => emit(AuthState(
      status: AuthStatus.error,
      errorMessage: failure.message,
    )),
    (user) => emit(AuthState(
      status: AuthStatus.authenticated,
      user: user,
    )),
  );
}

Future<void> _handleRegister(
  AuthBloc bloc,
  RegisterSubmitted event,
  Emitter<AuthState> emit,
) async {
  emit(const AuthState(status: AuthStatus.loading));
  final result = await bloc.registerUseCase(RegisterParams(
    email: event.email,
    username: event.username,
    password: event.password,
    fullName: event.fullName,
  ));
  result.fold(
    (failure) => emit(AuthState(
      status: AuthStatus.error,
      errorMessage: failure.message,
    )),
    (user) => emit(user.isEmailVerified
        ? AuthState(status: AuthStatus.authenticated, user: user)
        : const AuthState(
            status: AuthStatus.unauthenticated,
            successMessage: 'VERIFY_EMAIL_REQUIRED',
          )),
  );
}

Future<void> _handleLogout(
  AuthBloc bloc,
  LogoutRequested event,
  Emitter<AuthState> emit,
) async {
  emit(bloc.state.copyWith(status: AuthStatus.loading));
  bloc._signOutInProgress = true;
  await _unregisterDeviceTokenIfReady();
  final result = await bloc.logoutUseCase(const NoParams());
  bloc._signOutInProgress = false;
  result.fold(
    (failure) => emit(AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: failure.message,
    )),
    (_) => emit(const AuthState(status: AuthStatus.unauthenticated)),
  );
}

Future<void> _handleSessionExpired(
  AuthBloc bloc,
  SessionExpiredDetected event,
  Emitter<AuthState> emit,
) async {
  bloc._signOutInProgress = true;
  await _unregisterDeviceTokenIfReady();
  await bloc.logoutUseCase(const NoParams());
  bloc._signOutInProgress = false;
  emit(const AuthState(
    status: AuthStatus.sessionExpired,
    errorMessage: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
  ));
}

void _handleClearStatus(AuthBloc bloc, Emitter<AuthState> emit) {
  emit(bloc.state.copyWith(
    status: bloc.state.user.isNotEmpty
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated,
    clearSuccess: true,
    clearError: true,
  ));
}

Future<void> _unregisterDeviceTokenIfReady() async {
  try {
    if (sl.isRegistered<FCMService>()) {
      await sl<FCMService>().unregisterCurrentDeviceToken();
    }
  } catch (_) {
    // Token cleanup must not block logout. The next login will re-register
    // the active device token with the correct user.
  }
}
