import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uts/core/usecases/usecase.dart';
import 'package:uts/core/constants/enums.dart';
import 'package:uts/features/auth/domain/usecases/auth_usecases.dart';
import 'package:uts/features/auth/presentation/bloc/auth_event.dart';
import 'package:uts/features/auth/presentation/bloc/auth_state.dart';
import 'package:uts/features/auth/domain/usecases/update_password_usecase.dart';

/// AuthBloc mengelola status autentikasi global aplikasi.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final UpdatePasswordUseCase updatePasswordUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.resetPasswordUseCase,
    required this.updatePasswordUseCase,
  }) : super(const AuthState()) {
    on<AppStarted>(_onAppStarted);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RegisterSubmitted>(_onRegisterSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<ResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthPasswordUpdateRequested>(_onAuthPasswordUpdateRequested);
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
      (user) => emit(state.copyWith(status: AuthStatus.authenticated, user: user)),
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
}
