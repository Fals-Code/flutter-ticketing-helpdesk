import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uts/core/constants/env_constants.dart';
import 'package:uts/features/auth/domain/value_objects/auth_identifier.dart';
import '../models/user_model.dart';

class InactiveAccountException implements Exception {
  const InactiveAccountException();
}

class UsernameAlreadyUsedException implements Exception {
  const UsernameAlreadyUsedException();
}

abstract class AuthRemoteDataSource {
  Future<UserModel> login(String identifier, String password);

  Future<UserModel> register(
    String email,
    String username,
    String password,
    String fullName,
  );

  Future<void> logout();
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String newPassword);
  Future<UserModel?> getCurrentSession();
  Future<String> uploadAvatar(File image);
  Future<void> updateAvatarUrl(String url);
  Future<void> updateProfile({required String fullName});
  Future<void> updateEmail(String newEmail);
}

class SupabaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final sup.SupabaseClient supabaseClient;

  SupabaseAuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<UserModel> login(String identifier, String password) async {
    final normalized = AuthIdentifier.normalize(identifier);
    final email = AuthIdentifier.isEmail(normalized)
        ? normalized
        : await _resolveEmailFromUsername(normalized);

    if (email == null || email.isEmpty) {
      throw const sup.AuthException('INVALID_CREDENTIALS');
    }

    final response = await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw const sup.AuthException('INVALID_CREDENTIALS');
    }

    return _buildActiveUser(
      user: user,
      token: response.session?.accessToken,
    );
  }

  @override
  Future<UserModel> register(
    String email,
    String username,
    String password,
    String fullName,
  ) async {
    final normalizedUsername = AuthIdentifier.normalize(username);
    final existingEmail = await _resolveEmailFromUsername(normalizedUsername);
    if (existingEmail != null) {
      throw const UsernameAlreadyUsedException();
    }

    final response = await supabaseClient.auth.signUp(
      email: email.trim().toLowerCase(),
      password: password,
      data: {
        'full_name': fullName.trim(),
        'username': normalizedUsername,
      },
      emailRedirectTo: EnvConstants.passwordRecoveryRedirect,
    );

    final user = response.user;
    if (user == null) {
      throw const sup.AuthException('Registrasi gagal');
    }

    return UserModel.fromJson(
      user.toJson(),
      token: response.session?.accessToken,
      roleInt: 3,
      isActive: true,
    );
  }

  @override
  Future<void> logout() => supabaseClient.auth.signOut();

  @override
  Future<void> resetPassword(String email) {
    return supabaseClient.auth.resetPasswordForEmail(
      email.trim().toLowerCase(),
      redirectTo: EnvConstants.passwordRecoveryRedirect,
    );
  }

  @override
  Future<void> updatePassword(String newPassword) {
    return supabaseClient.auth.updateUser(
      sup.UserAttributes(password: newPassword),
    );
  }

  @override
  Future<UserModel?> getCurrentSession() async {
    final session = supabaseClient.auth.currentSession;
    final user = supabaseClient.auth.currentUser;
    if (session == null || user == null) {
      return null;
    }

    return _buildActiveUser(
      user: user,
      token: session.accessToken,
    );
  }

  Future<String?> _resolveEmailFromUsername(String username) async {
    final result = await supabaseClient.rpc(
      'resolve_login_email',
      params: {'p_identifier': username},
    );
    return result?.toString();
  }

  Future<UserModel> _buildActiveUser({
    required sup.User user,
    required String? token,
  }) async {
    final activeResult = await supabaseClient.rpc('is_active_user');
    final isActive = activeResult == true;
    if (!isActive) {
      await supabaseClient.auth.signOut();
      throw const InactiveAccountException();
    }

    final profile = await supabaseClient
        .from('profiles')
        .select('role, avatar_url, full_name, is_active')
        .eq('id', user.id)
        .single();

    final userJson = user.toJson();
    userJson['avatar_url'] = profile['avatar_url'];
    userJson['full_name'] = profile['full_name'];
    userJson['is_active'] = profile['is_active'];

    return UserModel.fromJson(
      userJson,
      token: token,
      roleInt: profile['role'] as int,
      isActive: profile['is_active'] as bool? ?? false,
    );
  }

  @override
  Future<String> uploadAvatar(File image) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('User tidak terautentikasi');
    }

    final path = 'avatars/${user.id}/profile_image.jpg';
    await supabaseClient.storage.from('avatars').upload(
          path,
          image,
          fileOptions: const sup.FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    final publicUrl = supabaseClient.storage.from('avatars').getPublicUrl(path);
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> updateAvatarUrl(String url) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('User tidak terautentikasi');
    }
    await supabaseClient
        .from('profiles')
        .update({'avatar_url': url}).eq('id', user.id);
  }

  @override
  Future<void> updateProfile({required String fullName}) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) {
      throw Exception('User tidak terautentikasi');
    }
    await supabaseClient
        .from('profiles')
        .update({'full_name': fullName.trim()}).eq('id', user.id);
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    debugPrint('Requesting authenticated email change');
    await supabaseClient.auth.updateUser(
      sup.UserAttributes(email: newEmail.trim().toLowerCase()),
    );
  }
}
