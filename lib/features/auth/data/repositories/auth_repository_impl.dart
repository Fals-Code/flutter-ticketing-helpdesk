import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uts/core/error/failures.dart';
import 'package:uts/core/services/fcm_service.dart';
import 'package:uts/core/services/session_cleanup_service.dart';
import 'package:uts/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:uts/features/auth/domain/entities/user_entity.dart';
import 'package:uts/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FCMService fcmService;
  final SessionCleanupService sessionCleanupService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.fcmService,
    required this.sessionCleanupService,
  });

  @override
  Future<Either<Failure, AuthUser>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.login(identifier, password);
      await fcmService.syncTokenToSupabase(userModel.id);
      return Right(userModel.toEntity());
    } on InactiveAccountException {
      return const Left(ServerFailure(
        message: 'Akun Anda sedang dinonaktifkan. Hubungi Admin.',
        code: 403,
      ));
    } on sup.AuthException catch (error) {
      if (error.message.toLowerCase().contains('email not confirmed')) {
        return const Left(ServerFailure(
          message: 'Silakan verifikasi email Anda terlebih dahulu.',
          code: 401,
        ));
      }
      return const Left(ServerFailure(
        message: 'Email, username, atau kata sandi tidak valid.',
        code: 401,
      ));
    } catch (_) {
      return const Left(UnknownFailure(
        message: 'Terjadi kesalahan saat masuk. Silakan coba lagi.',
      ));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> register({
    required String email,
    required String username,
    required String password,
    required String fullName,
  }) async {
    try {
      final userModel = await remoteDataSource.register(
        email,
        username,
        password,
        fullName,
      );
      await fcmService.syncTokenToSupabase(userModel.id);
      return Right(userModel.toEntity());
    } on UsernameAlreadyUsedException {
      return const Left(ServerFailure(
        message: 'Username sudah digunakan.',
        code: 409,
      ));
    } on sup.AuthException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('username') || message.contains('duplicate')) {
        return const Left(ServerFailure(
          message: 'Username sudah digunakan.',
          code: 409,
        ));
      }
      if (message.contains('already registered')) {
        return const Left(ServerFailure(
          message: 'Email sudah terdaftar.',
          code: 409,
        ));
      }
      return const Left(ServerFailure(
        message: 'Registrasi gagal. Periksa kembali data Anda.',
        code: 400,
      ));
    } catch (_) {
      return const Left(UnknownFailure(message: 'Gagal melakukan registrasi.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    Object? cleanupError;
    Object? logoutError;

    try {
      await sessionCleanupService.clearBeforeLogout();
    } catch (error) {
      cleanupError = error;
    }

    try {
      await remoteDataSource.logout();
    } catch (error) {
      logoutError = error;
    }

    if (cleanupError != null || logoutError != null) {
      return const Left(CacheFailure(
        message: 'Sesi lokal telah ditutup, tetapi sebagian cleanup gagal.',
      ));
    }
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(unit);
    } on sup.AuthException {
      // Respons sengaja generik untuk mencegah enumerasi akun.
      return const Right(unit);
    } catch (_) {
      return const Left(UnknownFailure(
        message: 'Gagal mengirim instruksi reset password.',
      ));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentSession();
      if (userModel == null) {
        return const Left(CacheFailure(message: 'Sesi tidak ditemukan'));
      }
      await fcmService.syncTokenToSupabase(userModel.id);
      return Right(userModel.toEntity());
    } on InactiveAccountException {
      return const Left(ServerFailure(
        message: 'Akun Anda sedang dinonaktifkan. Hubungi Admin.',
        code: 403,
      ));
    } catch (_) {
      return const Left(CacheFailure(message: 'Sesi tidak dapat dipulihkan'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePassword(String newPassword) async {
    try {
      await remoteDataSource.updatePassword(newPassword);
      return const Right(unit);
    } on sup.AuthException {
      return const Left(ServerFailure(
        message: 'Kata sandi baru tidak memenuhi kebijakan keamanan.',
        code: 400,
      ));
    } catch (_) {
      return const Left(UnknownFailure(
        message: 'Gagal memperbarui kata sandi.',
      ));
    }
  }

  @override
  Future<Either<Failure, String>> updateAvatar(File image) async {
    try {
      final publicUrl = await remoteDataSource.uploadAvatar(image);
      await remoteDataSource.updateAvatarUrl(publicUrl);
      return Right(publicUrl);
    } on sup.StorageException catch (error) {
      return Left(ServerFailure(
        message: 'Gagal mengunggah foto: ${error.message}',
        code: 500,
      ));
    } catch (_) {
      return const Left(UnknownFailure(message: 'Gagal memperbarui avatar.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProfile({
    required String fullName,
    String? email,
  }) async {
    try {
      await remoteDataSource.updateProfile(fullName: fullName);
      if (email != null && email.isNotEmpty) {
        await remoteDataSource.updateEmail(email);
      }
      return const Right(unit);
    } on sup.AuthException {
      return const Left(ServerFailure(
        message: 'Perubahan email tidak dapat diproses.',
        code: 400,
      ));
    } catch (_) {
      return const Left(UnknownFailure(
        message: 'Gagal memperbarui profil.',
      ));
    }
  }
}
