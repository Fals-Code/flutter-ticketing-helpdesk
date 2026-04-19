import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import '../../../../core/error/failures.dart';
import '../../../../core/services/fcm_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementasi dari AuthRepository.
/// Menghubungkan Domain Layer dengan Data Source.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FCMService fcmService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.fcmService,
  });

  @override
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.login(email, password);
      
      // Sync FCM Token on login
      await fcmService.syncTokenToSupabase(userModel.id);
      
      return Right(userModel.toEntity());
    } on sup.AuthException catch (e) {
      return Left(ServerFailure(message: e.message, code: 400));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> register({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final userModel = await remoteDataSource.register(email, password, fullName);
      
      // Sync FCM Token on registration
      await fcmService.syncTokenToSupabase(userModel.id);
      
      return Right(userModel.toEntity());
    } on sup.AuthException catch (e) {
      return Left(ServerFailure(message: e.message, code: 400));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await remoteDataSource.logout();
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: 'Gagal membersihkan sesi: $e'));
    }
  }

  @override
  Future<Either<Failure, Unit>> resetPassword(String email) async {
    try {
      await remoteDataSource.resetPassword(email);
      return const Right(unit);
    } on sup.AuthException catch (e) {
      return Left(ServerFailure(message: e.message, code: 400));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> getCurrentUser() async {
    try {
      final userModel = await remoteDataSource.getCurrentSession();
      if (userModel != null) {
        // Sync FCM Token on session recovery
        await fcmService.syncTokenToSupabase(userModel.id);
        
        return Right(userModel.toEntity());
      }
      return const Left(CacheFailure(message: 'Sesi tidak ditemukan'));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePassword(String newPassword) async {
    try {
      await remoteDataSource.updatePassword(newPassword);
      return const Right(unit);
    } on sup.AuthException catch (e) {
      return Left(ServerFailure(message: e.message, code: 400));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> updateAvatar(File image) async {
    try {
      // 1. Upload ke storage
      final String publicUrl = await remoteDataSource.uploadAvatar(image);
      
      // 2. Update database profiles
      await remoteDataSource.updateAvatarUrl(publicUrl);
      
      return Right(publicUrl);
    } on sup.StorageException catch (e) {
      return Left(ServerFailure(message: 'Gagal mengunggah foto: ${e.message}', code: 500));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updateProfile({
    required String fullName,
    String? email,
  }) async {
    try {
      // 1. Update nama di tabel profiles
      await remoteDataSource.updateProfile(fullName: fullName);

      // 2. Update email via Supabase Auth jika berubah
      if (email != null && email.isNotEmpty) {
        await remoteDataSource.updateEmail(email);
      }

      return const Right(unit);
    } on sup.AuthException catch (e) {
      return Left(ServerFailure(message: e.message, code: 400));
    } catch (e) {
      return Left(UnknownFailure(message: 'Gagal memperbarui profil: $e'));
    }
  }
}
