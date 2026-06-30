part of 'auth_bloc.dart';

void _registerAuthHandlers(AuthBloc bloc) {
  bloc.on<AppStarted>(
    (event, emit) => _handleAppStarted(bloc, event, emit),
  );
  bloc.on<LoginSubmitted>(
    (event, emit) => _handleLogin(bloc, event, emit),
  );
  bloc.on<RegisterSubmitted>(
    (event, emit) => _handleRegister(bloc, event, emit),
  );
  bloc.on<LogoutRequested>(
    (event, emit) => _handleLogout(bloc, event, emit),
  );
  bloc.on<ResetPasswordRequested>(
    (event, emit) => _handleForgotPassword(bloc, event, emit),
  );
  bloc.on<PasswordRecoveryDetected>(
    (_, emit) => emit(const AuthState(status: AuthStatus.passwordRecovery)),
  );
  bloc.on<AuthPasswordUpdateRequested>(
    (event, emit) => _handleUpdatePassword(bloc, event, emit),
  );
  bloc.on<SessionExpiredDetected>(
    (event, emit) => _handleSessionExpired(bloc, event, emit),
  );
  bloc.on<UpdateAvatarRequested>(
    (event, emit) => _handleUpdateAvatar(bloc, event, emit),
  );
  bloc.on<UpdateProfileRequested>(
    (event, emit) => _handleUpdateProfile(bloc, event, emit),
  );
  bloc.on<ClearAuthStatus>(
    (_, emit) => _handleClearStatus(bloc, emit),
  );
}

void _startAuthListener(AuthBloc bloc) {
  bloc._authSubscription = bloc.supabaseClient.auth.onAuthStateChange.listen(
    (data) {
      if (data.event == sup.AuthChangeEvent.passwordRecovery) {
        bloc.add(const PasswordRecoveryDetected());
      } else if (data.event == sup.AuthChangeEvent.signedOut &&
          !bloc._signOutInProgress &&
          bloc.state.user.isNotEmpty) {
        bloc.add(const SessionExpiredDetected());
      }
    },
  );
}
