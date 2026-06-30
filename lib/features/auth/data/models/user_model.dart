import 'package:uts/features/auth/domain/entities/user_entity.dart';
import 'package:uts/core/constants/enums.dart';

/// Model user pada data layer.
class UserModel extends AuthUser {
  const UserModel({
    required super.id,
    required super.email,
    super.username,
    super.fullName,
    required super.role,
    super.token,
    super.avatarUrl,
    super.isEmailVerified = false,
    super.isActive = true,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String? token,
    int? roleInt,
    bool? isActive,
  }) {
    final roleData =
        roleInt ?? json['role'] ?? json['user_metadata']?['role'] ?? 'user';

    final UserRole role;
    if (roleData is int) {
      role = UserRole.fromInt(roleData);
    } else {
      role = UserRole.fromString(roleData.toString());
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      username: json['username']?.toString() ??
          json['user_metadata']?['username']?.toString(),
      fullName: json['fullName']?.toString() ??
          json['full_name']?.toString() ??
          json['user_metadata']?['full_name']?.toString(),
      role: role,
      token: token,
      avatarUrl:
          json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      isEmailVerified: (json['email_confirmed_at'] != null &&
              json['email_confirmed_at'].toString().isNotEmpty) ||
          (json['emailConfirmedAt'] != null &&
              json['emailConfirmedAt'].toString().isNotEmpty),
      isActive: isActive ?? json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
      'role': role.name,
      'token': token,
      'avatarUrl': avatarUrl,
      'isEmailVerified': isEmailVerified,
      'isActive': isActive,
    };
  }

  AuthUser toEntity() {
    return AuthUser(
      id: id,
      email: email,
      username: username,
      fullName: fullName,
      role: role,
      token: token,
      avatarUrl: avatarUrl,
      isEmailVerified: isEmailVerified,
      isActive: isActive,
    );
  }
}
