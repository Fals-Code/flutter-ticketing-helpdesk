import 'package:equatable/equatable.dart';
import 'package:uts/core/constants/enums.dart';

/// Entity user yang dipakai di seluruh domain autentikasi.
class AuthUser extends Equatable {
  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final UserRole role;
  final String? token;
  final String? avatarUrl;
  final bool isEmailVerified;
  final bool isActive;

  const AuthUser({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    required this.role,
    this.token,
    this.avatarUrl,
    this.isEmailVerified = false,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        fullName,
        role,
        token,
        avatarUrl,
        isEmailVerified,
        isActive,
      ];

  static const AuthUser empty = AuthUser(
    id: '',
    email: '',
    role: UserRole.user,
    avatarUrl: null,
    isEmailVerified: false,
    isActive: false,
  );

  AuthUser copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    UserRole? role,
    String? token,
    String? avatarUrl,
    bool? isEmailVerified,
    bool? isActive,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      token: token ?? this.token,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get isEmpty => this == AuthUser.empty;
  bool get isNotEmpty => !isEmpty;
}
