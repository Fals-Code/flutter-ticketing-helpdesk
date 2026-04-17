import 'package:equatable/equatable.dart';
import 'package:uts/core/constants/enums.dart';

/// Entity User yang mewakili data pengguna di Domain Layer.
class AuthUser extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final UserRole role;
  final String? token;

  const AuthUser({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.token,
  });

  @override
  List<Object?> get props => [id, email, fullName, role, token];

  /// Menghasilkan state "Kosong" saat tidak terautentikasi.
  static const AuthUser empty = AuthUser(
    id: '',
    email: '',
    role: UserRole.user,
  );

  bool get isEmpty => this == AuthUser.empty;
  bool get isNotEmpty => !isEmpty;
}
