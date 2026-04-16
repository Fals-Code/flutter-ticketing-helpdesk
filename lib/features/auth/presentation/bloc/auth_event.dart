import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

/// Event saat aplikasi pertama kali dijalankan untuk cek sesi.
class AppStarted extends AuthEvent {}

/// Event untuk Login.
class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted({required this.email, required this.password});
  @override
  List<Object?> get props => [email, password];
}

/// Event untuk Registrasi.
class RegisterSubmitted extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  const RegisterSubmitted({
    required this.email,
    required this.password,
    required this.fullName,
  });
  @override
  List<Object?> get props => [email, password, fullName];
}

/// Event untuk Logout.
class LogoutRequested extends AuthEvent {}

/// Event untuk Reset Password.
class ResetPasswordRequested extends AuthEvent {
  final String email;
  const ResetPasswordRequested(this.email);
  @override
  List<Object?> get props => [email];
}

/// Event untuk Ubah Kata Sandi (Saat Logged In).
class AuthPasswordUpdateRequested extends AuthEvent {
  final String newPassword;
  const AuthPasswordUpdateRequested(this.newPassword);
  @override
  List<Object?> get props => [newPassword];
}

/// Event untuk membersihkan status pesan (setelah sukses/error).
class ClearAuthStatus extends AuthEvent {}
