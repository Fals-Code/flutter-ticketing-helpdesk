import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Kontrak repositori autentikasi.
abstract class AuthRepository {
  /// Login menggunakan email atau username.
  Future<Either<Failure, AuthUser>> login({
    required String identifier,
    required String password,
  });

  /// Registrasi publik. Role selalu ditentukan backend sebagai User.
  Future<Either<Failure, AuthUser>> register({
    required String email,
    required String username,
    required String password,
    required String fullName,
  });

  /// Menghapus data sesi lokal, token perangkat, lalu keluar dari Supabase.
  Future<Either<Failure, Unit>> logout();

  Future<Either<Failure, Unit>> resetPassword(String email);

  Future<Either<Failure, AuthUser>> getCurrentUser();

  Future<Either<Failure, Unit>> updatePassword(String newPassword);

  Future<Either<Failure, String>> updateAvatar(File image);

  Future<Either<Failure, Unit>> updateProfile({
    required String fullName,
    String? email,
  });
}
