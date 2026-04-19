import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup show AuthChangeEvent, SupabaseClient;
import 'package:uts/core/usecases/usecase.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/auth/domain/usecases/auth_usecases.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/auth/domain/usecases/update_password_usecase.dart';
import 'package:uts/features/auth/domain/usecases/update_avatar_usecase.dart';

/// AuthBloc mengelola status autentikasi global aplikasi.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final UpdatePasswordUseCase updatePasswordUseCase;
  final UpdateAvatarUseCase updateAvatarUseCase;
  final sup.SupabaseClient supabaseClient;
  StreamSubscription<dynamic>? _authSubscription;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
    required this.updatePasswordUseCase,
    required this.updateAvatarUseCase,
    required this.supabaseClient,
  }) : super(const AuthState()) {
    on<AppStarted>(_onAppStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthPasswordUpdateRequested>(_onAuthPasswordUpdateRequested);
    on<UpdateAvatarRequested>(_onUpdateAvatarRequested);
    on<ClearAuthStatus>(_onClearStatus);
    on<SessionExpiredDetected>(_onSessionExpiredDetected);

    // Listen to Supabase auth state changes
    _authSubscription = supabaseClient.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      if (event == sup.AuthChangeEvent.signedOut) {
        if (state.status == AuthStatus.authenticated) {
          add(SessionExpiredDetected());
        }
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  void _onSessionExpiredDetected(SessionExpiredDetected event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      status: AuthStatus.sessionExpired,
      errorMessage: 'Sesi Anda telah berakhir. Silakan masuk kembali.',
    ));
  }

  Future<void> _onAppStarted(AppStarted event, Emitter<AuthState> emit) async {
    final result = await getCurrentUserUseCase(const NoParams());
    result.fold(
      (_) => emit(state.copyWith(status: AuthStatus.unauthenticated)),
      (user) => emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> _onLoginSubmitted(LoginSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await loginUseCase(LoginParams(
      email: event.email,
      password: event.password,
    ));
    result.fold(
      (failure) => emit(state.copyWith(status: AuthStatus.error, errorMessage: failure.message)),
      (user) => emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
    );
  }

  Future<void> _onRegisterSubmitted(RegisterSubmitted event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await registerUseCase(RegisterParams(
      email: event.email,
      password: event.password,
      fullName: event.fullName,
    ));
    result.fold(
      (failure) => emit(state.copyWith(status: AuthStatus.error, errorMessage: failure.message)),
      (user) {
        if (!user.isEmailVerified) {
          emit(state.copyWith(
            status: AuthStatus.unauthenticated,
            successMessage: 'VERIFY_EMAIL_REQUIRED',
          ));
        } else {
          emit(state.copyWith(status: AuthStatus.authenticated, user: user));
        }
      },
    );
  }

  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    await logoutUseCase(const NoParams());
    emit(const AuthState(status: AuthStatus.unauthenticated));
  }

  Future<void> _onResetPasswordRequested(ResetPasswordRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await resetPasswordUseCase(event.email);
    result.fold(
      (failure) => emit(state.copyWith(status: AuthStatus.error, errorMessage: failure.message)),
      (_) => emit(state.copyWith(
        status: AuthStatus.success,
        successMessage: 'Instruksi reset password telah dikirim ke email Anda.',
      )),
    );
  }

  Future<void> _onAuthPasswordUpdateRequested(
    AuthPasswordUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final result = await updatePasswordUseCase(event.newPassword);
    result.fold(
      (failure) => emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        status: AuthStatus.success,
        successMessage: 'Kata sandi berhasil diperbarui!',
      )),
    );
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
        errorMessage: failure.message
      )),
      (newUrl) {
        final updatedUser = state.user.copyWith(avatarUrl: newUrl);
        emit(state.copyWith(
          user: updatedUser,
          status: AuthStatus.authenticated,
          successMessage: 'Foto profil berhasil diperbarui!',
        ));
      },
    );
  }

  void _onClearStatus(ClearAuthStatus event, Emitter<AuthState> emit) {
    emit(state.copyWith(clearSuccess: true, clearError: true));
  }
}
