import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import '../models/user_model.dart';

/// Interface untuk Remote Data Source Autentikasi.
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String fullName);
  Future<void> logout();
  Future<void> resetPassword(String email);
  Future<void> updatePassword(String newPassword);
  Future<UserModel?> getCurrentSession();
  
  /// Unggah foto ke storage.
  Future<String> uploadAvatar(File image);
  
  /// Perbarui field avatar_url di tabel profiles.
  Future<void> updateAvatarUrl(String url);

  /// Perbarui nama lengkap di tabel profiles.
  Future<void> updateProfile({required String fullName});

  /// Perbarui email melalui Supabase Auth (memerlukan konfirmasi email baru).
  Future<void> updateEmail(String newEmail);
}

/// Implementasi AuthRemoteDataSource menggunakan Supabase.
class SupabaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final sup.SupabaseClient supabaseClient;

  SupabaseAuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const sup.AuthException('Login gagal: User tidak ditemukan');
      }

      // Fetch role & avatar from profiles table
      final profileResponse = await supabaseClient
          .from('profiles')
          .select('role, avatar_url')
          .eq('id', response.user!.id)
          .single();
      
      final int roleInt = profileResponse['role'] as int;
      final String? avatarUrl = profileResponse['avatar_url'];

      final userJson = response.user!.toJson();
      userJson['avatar_url'] = avatarUrl;

      return UserModel.fromJson(
        userJson,
        token: response.session?.accessToken,
        roleInt: roleInt,
      );
    } on sup.AuthException catch (e) {
      // Handle the specific "Email not confirmed" case as requested by user
      if (e.message.toLowerCase().contains('email not confirmed')) {
        throw const sup.AuthException('Silakan verifikasi email Anda terlebih dahulu');
      }
      rethrow;
    }
  }

  @override
  Future<UserModel> register(String email, String password, String fullName) async {
    final response = await supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': 3, // Role 3 = Customer (Integer based)
      },
    );

    if (response.user == null) {
      throw const sup.AuthException('Registrasi gagal');
    }

    return UserModel.fromJson(
      response.user!.toJson(),
      token: response.session?.accessToken,
    );
  }

  @override
  Future<void> logout() async {
    await supabaseClient.auth.signOut();
  }

  @override
  Future<void> resetPassword(String email) async {
    await supabaseClient.auth.resetPasswordForEmail(email);
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    await supabaseClient.auth.updateUser(
      sup.UserAttributes(password: newPassword),
    );
  }

  @override
  Future<UserModel?> getCurrentSession() async {
    final session = supabaseClient.auth.currentSession;
    final user = supabaseClient.auth.currentUser;

    if (session != null && user != null) {
      // Fetch role & avatar from profiles table
      final profileResponse = await supabaseClient
          .from('profiles')
          .select('role, avatar_url')
          .eq('id', user.id)
          .single();
      
      final int roleInt = profileResponse['role'] as int;
      final String? avatarUrl = profileResponse['avatar_url'];

      final userJson = user.toJson();
      userJson['avatar_url'] = avatarUrl;

      return UserModel.fromJson(
        userJson,
        token: session.accessToken,
        roleInt: roleInt,
      );
    }
    return null;
  }

  @override
  Future<String> uploadAvatar(File image) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) throw Exception('User tidak terautentikasi');

    final fileName = 'profile_image.jpg';
    final path = 'avatars/${user.id}/$fileName';

    print('DEBUG: Memulai upload foto ke Supabase Storage: $path');
    try {
      // Upload with upsert: true
      await supabaseClient.storage.from('avatars').upload(
        path,
        image,
        fileOptions: const sup.FileOptions(upsert: true, contentType: 'image/jpeg'),
      );
      print('DEBUG: Upload berhasil!');
    } catch (e) {
      print('DEBUG: Error saat upload storage: $e');
      rethrow;
    }

    // Get public URL
    final String publicUrl = supabaseClient.storage.from('avatars').getPublicUrl(path);
    
    // Add timestamp to avoid caching issues in the UI
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  Future<void> updateAvatarUrl(String url) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) throw Exception('User tidak terautentikasi');

    print('DEBUG: Memperbarui avatar_url di tabel profiles untuk user: ${user.id}');
    try {
      await supabaseClient
          .from('profiles')
          .update({'avatar_url': url})
          .eq('id', user.id);
      print('DEBUG: Update database berhasil!');
    } catch (e) {
      print('DEBUG: Error saat update database profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateProfile({required String fullName}) async {
    final user = supabaseClient.auth.currentUser;
    if (user == null) throw Exception('User tidak terautentikasi');

    print('DEBUG: Memperbarui full_name di tabel profiles untuk user: ${user.id}');
    try {
      await supabaseClient
          .from('profiles')
          .update({'full_name': fullName})
          .eq('id', user.id);
      print('DEBUG: Update full_name berhasil!');
    } catch (e) {
      print('DEBUG: Error saat update full_name: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateEmail(String newEmail) async {
    print('DEBUG: Memperbarui email melalui Supabase Auth: $newEmail');
    try {
      await supabaseClient.auth.updateUser(
        sup.UserAttributes(email: newEmail),
      );
      print('DEBUG: Permintaan update email berhasil dikirim!');
    } catch (e) {
      print('DEBUG: Error saat update email: $e');
      rethrow;
    }
  }
}
