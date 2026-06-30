import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStarted extends AuthEvent {
  const AppStarted();
}

class LoginSubmitted extends AuthEvent {
  final String identifier;
  final String password;

  const LoginSubmitted({
    required this.identifier,
    required this.password,
  });

  @override
  List<Object?> get props => [identifier, password];
}

class RegisterSubmitted extends AuthEvent {
  final String email;
  final String username;
  final String password;
  final String fullName;

  const RegisterSubmitted({
    required this.email,
    required this.username,
    required this.password,
    required this.fullName,
  });

  @override
  List<Object?> get props => [email, username, password, fullName];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class ResetPasswordRequested extends AuthEvent {
  final String email;

  const ResetPasswordRequested(this.email);

  @override
  List<Object?> get props => [email];
}

class PasswordRecoveryDetected extends AuthEvent {
  const PasswordRecoveryDetected();
}

class AuthPasswordUpdateRequested extends AuthEvent {
  final String newPassword;

  const AuthPasswordUpdateRequested(this.newPassword);

  @override
  List<Object?> get props => [newPassword];
}

class ClearAuthStatus extends AuthEvent {
  const ClearAuthStatus();
}

class SessionExpiredDetected extends AuthEvent {
  const SessionExpiredDetected();
}

class UpdateAvatarRequested extends AuthEvent {
  final File image;

  const UpdateAvatarRequested(this.image);

  @override
  List<Object?> get props => [image];
}

class UpdateProfileRequested extends AuthEvent {
  final String fullName;
  final String? email;

  const UpdateProfileRequested({
    required this.fullName,
    this.email,
  });

  @override
  List<Object?> get props => [fullName, email];
}
