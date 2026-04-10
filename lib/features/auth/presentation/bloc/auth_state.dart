import 'package:equatable/equatable.dart';
import 'package:uts/core/constants/enums.dart';
import '../../domain/entities/user_entity.dart';

class AuthState extends Equatable {
  final AuthUser user;
  final AuthStatus status;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.user = AuthUser.empty,
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.successMessage,
  });

  AuthState copyWith({
    AuthUser? user,
    AuthStatus? status,
    String? errorMessage,
    String? successMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [user, status, errorMessage, successMessage];
}
