import 'package:equatable/equatable.dart';
import 'package:uts/core/constants/enums.dart';

class ProfileEntity extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final UserRole role;
  final String? avatarUrl;

  const ProfileEntity({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [id, email, fullName, role, avatarUrl];
}
