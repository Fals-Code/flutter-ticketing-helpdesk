import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

/// Implementasi dari AuthRepository.
/// Menghubungkan Domain Layer dengan Data Source.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await remoteDataSource.login(email, password);
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
        return Right(userModel.toEntity());
      }
      return const Left(CacheFailure(message: 'Sesi tidak ditemukan'));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
