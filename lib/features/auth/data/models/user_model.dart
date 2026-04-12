import 'package:uts/features/auth/domain/entities/user_entity.dart';
import 'package:uts/core/constants/enums.dart';

/// Model User untuk Data Layer.
/// Menangani serialisasi dari JSON (API/DB) ke Domain Entity.
class UserModel extends AuthUser {
  const UserModel({
    required super.id,
    required super.email,
    super.fullName,
    required super.role,
    super.token,
  });

  /// Factory untuk membuat UserModel dari Map JSON.
  factory UserModel.fromJson(Map<String, dynamic> json, {String? token, int? roleInt}) {
    // Role can come from roleInt override, or metadata
    final roleData = roleInt ?? json['role'] ?? json['user_metadata']?['role'] ?? 'user';
    
    final UserRole role;
    if (roleData is int) {
      role = UserRole.fromInt(roleData);
    } else {
      role = UserRole.fromString(roleData.toString());
    }
    
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? json['user_metadata']?['full_name'],
      role: role,
      token: token,
    );
  }

  /// Konversi ke JSON (untuk local storage).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'role': role.name,
      'token': token,
    };
  }

  AuthUser toEntity() {
    return AuthUser(
      id: id,
      email: email,
      fullName: fullName,
      role: role,
      token: token,
    );
  }
}
