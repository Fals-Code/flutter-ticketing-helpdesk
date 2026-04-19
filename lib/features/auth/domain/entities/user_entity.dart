import 'package:equatable/equatable.dart';
import 'package:uts/core/constants/enums.dart';

/// Entity User yang mewakili data pengguna di Domain Layer.
class AuthUser extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final UserRole role;
  final String? token;
  final String? avatarUrl;
  final bool isEmailVerified;

  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.token,
    this.avatarUrl,
    this.isEmailVerified = false,
  });

  @override
  List<Object?> get props => [id, email, fullName, role, token, avatarUrl, isEmailVerified];

  /// Menghasilkan state "Kosong" saat tidak terautentikasi.
  static const AuthUser empty = AuthUser(
    id: '',
    email: '',
    role: UserRole.user,
    avatarUrl: null,
    isEmailVerified: false,
  );

  AuthUser copyWith({
    String? id,
    String? email,
    String? fullName,
    UserRole? role,
    String? token,
    String? avatarUrl,
    bool? isEmailVerified,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      token: token ?? this.token,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  bool get isEmpty => this == AuthUser.empty;
  bool get isNotEmpty => !isEmpty;
}
