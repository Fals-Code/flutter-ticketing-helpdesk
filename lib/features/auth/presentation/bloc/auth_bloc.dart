import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uts/core/constants/enums.dart';
import 'package:uts/core/usecases/usecase.dart';
import 'package:uts/features/auth/domain/entities/user_entity.dart';
import 'package:uts/features/auth/domain/usecases/auth_usecases.dart';
import 'package:uts/features/auth/domain/usecases/update_avatar_usecase.dart';
import 'package:uts/features/auth/domain/usecases/update_password_usecase.dart';
import 'package:uts/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final UpdatePasswordUseCase updatePasswordUseCase;
  final UpdateAvatarUseCase updateAvatarUseCase;
  final UpdateProfileUseCase updateProfileUseCase;
  final sup.SupabaseClient supabaseClient;

  StreamSubscription<dynamic>? _authSubscription;
  bool _signOutInProgress = false;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
    required this.updatePasswordUseCase,
    required this.updateAvatarUseCase,
    required this.updateProfileUseCase,
    required this.supabaseClient,
  }) : super(const AuthState()) {
    on<AppStarted>(_onAppStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<PasswordRecoveryDetected>(_onPasswordRecoveryDetected);
    on<AuthPasswordUpdateRequested>(_onAuthPasswordUpdateRequested);
    on<UpdateAvatarRequested>(_onUpdateAvatarRequested);
    on<UpdateProfileRequested>(_onUpdateProfileRequested);
    on<ClearAuthStatus>(_onClearStatus);
    on<SessionExpiredDetected>(_onSessionExpiredDetected);

    _authSubscription = supabaseClient.auth.onAuthStateChange.listen((data) {
      if (data.event == sup.AuthChangeEvent.passwordRecovery) {
        add(const PasswordRecoveryDetected());
        return;
      }

      if (data.event == sup.AuthChangeEvent.signedOut &&
          !_signOutInProgress &&
          state.user.isNotEmpty &&
          state.status != AuthStatus.unauthenticated) {
        add(const SessionExpiredDetected());
      }
    });
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onAppStarted(
    AppStarted event,
    Emitter<AuthState> emit,
  ) async {
    final result = await getCurrentUserUseCase(const NoParams());
    result.fold(
      (failure) {
        if (failure.code == 403) {
          emit(AuthState(
            status: AuthStatus.error,
            user: AuthUser.empty,
            errorMessage: failure.message,
          ));
          return;
        }
        emit(const AuthState(status: AuthStatus.unauthenticated));
      },
      (user) => emit(AuthState(
        status: AuthStatus.authenticated,
        user: user,
      )),
    );
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState(status: AuthStatus.loading));
    final result = await loginUseCase(LoginParams(
      identifier: event.identifier,
      password: event.password,
    ));

    result.fold(
      (failure) => emit(AuthState(
        status: AuthStatus.error,
        user: AuthUser.empty,
        errorMessage: failure.message,
      )),
      (user) => emit(AuthState(
        status: AuthStatus.authenticated,
        user: user,
      )),
    );
  }

  Future<void> _onRegisterSubmitted(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthState(status: AuthStatus.loading));
    final result = await registerUseCase(RegisterParams(
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
      (user) {
        if (!user.isEmailVerified) {
          emit(const AuthState(
            status: AuthStatus.unauthenticated,
            successMessage: 'VERIFY_EMAIL_REQUIRED',
          ));
          return;
        }
        emit(AuthState(
          status: AuthStatus.authenticated,
          user: user,
        ));
      },
    );
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    _signOutInProgress = true;
    final result = await logoutUseCase(const NoParams());
    _signOutInProgress = false;

    result.fold(
      (failure) => emit(AuthState(
        status: AuthStatus.unauthenticated,
        user: AuthUser.empty,
        errorMessage: failure.message,
      )),
      (_) => emit(const AuthState(status: AuthStatus.unauthenticated)),
    );
  }

  Future<void> _onResetPasswordRequested(
    ResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await resetPasswordUseCase(event.email);
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: AuthStatus.success,
        successMessage: 'Jika email terdaftar, instruksi reset telah dikirim.',
        clearError: true,
      )),
    );
  }

  void _onPasswordRecoveryDetected(
    PasswordRecoveryDetected event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthState(status: AuthStatus.passwordRecovery));
  }

  Future<void> _onAuthPasswordUpdateRequested(
    AuthPasswordUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final isRecovery = state.status == AuthStatus.passwordRecovery;
    final currentUser = state.user;
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await updatePasswordUseCase(event.newPassword);
    await result.fold(
      (failure) async => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (_) async {
        if (isRecovery) {
          _signOutInProgress = true;
          await logoutUseCase(const NoParams());
          _signOutInProgress = false;
          emit(const AuthState(
            status: AuthStatus.success,
            user: AuthUser.empty,
            successMessage: 'Kata sandi berhasil diatur ulang.',
          ));
          return;
        }

        emit(AuthState(
          status: AuthStatus.success,
          user: currentUser,
          successMessage: 'Kata sandi berhasil diperbarui.',
        ));
      },
    );
  }

  Future<void> _onSessionExpiredDetected(
    SessionExpiredDetected event,
    Emitter<AuthState> emit,
  ) async {
    _signOutInProgress = true;
    await logoutUseCase(const NoParams());
    _signOutInProgress = false;
    emit(const AuthState(
      status: AuthStatus.sessionExpired,
      user: AuthUser.empty,
      errorMessage: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
    ));
  }

  Future<void> _onUpdateAvatarRequested(
    UpdateAvatarRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await updateAvatarUseCase(event.image);
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (newUrl) => emit(state.copyWith(
        user: state.user.copyWith(avatarUrl: newUrl),
        status: AuthStatus.authenticated,
        successMessage: 'Foto profil berhasil diperbarui.',
        clearError: true,
      )),
    );
  }

  Future<void> _onUpdateProfileRequested(
    UpdateProfileRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await updateProfileUseCase(
      UpdateProfileParams(fullName: event.fullName, email: event.email),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (_) {
        final emailChanged = event.email != null &&
            event.email!.isNotEmpty &&
            event.email != state.user.email;
        emit(state.copyWith(
          user: state.user.copyWith(fullName: event.fullName),
          status: AuthStatus.authenticated,
          successMessage: emailChanged
              ? 'Profil diperbarui. Konfirmasi alamat email baru Anda.'
              : 'Profil berhasil diperbarui.',
          clearError: true,
        ));
      },
    );
  }

  void _onClearStatus(ClearAuthStatus event, Emitter<AuthState> emit) {
    final fallbackStatus = state.user.isNotEmpty
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    emit(state.copyWith(
      status: fallbackStatus,
      clearSuccess: true,
      clearError: true,
    ));
  }
}
