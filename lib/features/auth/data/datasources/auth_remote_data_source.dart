import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import '../models/user_model.dart';

/// Interface untuk Remote Data Source Autentikasi.
abstract class AuthRemoteDataSource {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String email, String password, String fullName);
  Future<void> logout();
  Future<void> resetPassword(String email);
  Future<UserModel?> getCurrentSession();
}

/// Implementasi AuthRemoteDataSource menggunakan Supabase.
class SupabaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final sup.SupabaseClient supabaseClient;

  SupabaseAuthRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw const sup.AuthException('Login gagal: User tidak ditemukan');
    }

    return UserModel.fromJson(
      response.user!.toJson(),
      token: response.session?.accessToken,
    );
  }

  @override
  Future<UserModel> register(String email, String password, String fullName) async {
    final response = await supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': 'user', // Selalu role user untuk pendaftaran publik
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
  Future<UserModel?> getCurrentSession() async {
    final session = supabaseClient.auth.currentSession;
    final user = supabaseClient.auth.currentUser;

    if (session != null && user != null) {
      return UserModel.fromJson(
        user.toJson(),
        token: session.accessToken,
      );
    }
    return null;
  }
}
