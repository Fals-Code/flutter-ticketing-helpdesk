import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Kontrak repositori untuk fitur Autentikasi.
abstract class AuthRepository {
  /// Login menggunakan email dan password.
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  });

  /// Registrasi akun baru (selalu role 'user').
  Future<Either<Failure, AuthUser>> register({
    required String email,
    required String password,
    required String fullName,
  });

  /// Keluar dari sesi dan hapus token lokal.
  Future<Either<Failure, Unit>> logout();

  /// Kirim email reset password.
  Future<Either<Failure, Unit>> resetPassword(String email);

  /// Ambil user yang saat ini tersimpan (cek sesi).
  Future<Either<Failure, AuthUser>> getCurrentUser();

  /// Perbarui kata sandi user yang sedang login.
  Future<Either<Failure, Unit>> updatePassword(String newPassword);
}
