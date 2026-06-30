import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sup;
import 'package:uuid/uuid.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/create_ticket_params.dart';
import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/comment_entity.dart';
import '../../domain/entities/ticket_history_entity.dart';
import '../../domain/repositories/ticket_repository.dart';
import '../datasources/ticket_attachment_storage_data_source.dart';
import '../datasources/ticket_create_exceptions.dart';
import '../datasources/ticket_remote_data_source.dart';
import '../models/comment_model.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/data/models/profile_model.dart';
import '../../../../core/constants/enums.dart';

class TicketRepositoryImpl implements TicketRepository {
  final TicketRemoteDataSource remoteDataSource;
  final TicketAttachmentStorageDataSource attachmentStorageDataSource;
  final Uuid uuid;

  TicketRepositoryImpl({
    required this.remoteDataSource,
    required this.attachmentStorageDataSource,
    this.uuid = const Uuid(),
  });

  @override
  Future<Either<Failure, List<TicketEntity>>> getTickets({
    required int page,
    required int limit,
    String? searchQuery,
    String? category,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final tickets = await remoteDataSource.getTickets(
        page,
        limit,
        searchQuery: searchQuery,
        category: category,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(tickets.map((t) => t.toEntity()).toList());
    } on sup.AuthException catch (e) {
      return Left(ServerFailure(message: e.message, code: 401));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TicketEntity>>> getAllTickets({
    required int page,
    required int limit,
    String? status,
    String? searchQuery,
    String? category,
    String? assignedToId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final tickets = await remoteDataSource.getAllTickets(
        page,
        limit,
        status: status,
        searchQuery: searchQuery,
        category: category,
        assignedToId: assignedToId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(tickets.map((t) => t.toEntity()).toList());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<AuthUser>>> getStaffUsers() async {
    try {
      final staffData = await remoteDataSource.getStaffUsers();
      final users = staffData
          .map((json) => ProfileModel.fromJson(json).toEntity())
          .toList();
      return Right(users
          .map((p) => AuthUser(
                id: p.id,
                email: p.email,
                fullName: p.fullName,
                role: p.role,
              ))
          .toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TicketEntity>> createTicket(
    CreateTicketParams params,
  ) async {
    final uploadedAttachments = <UploadedTicketAttachment>[];
    try {
      final actorId = remoteDataSource.getAuthenticatedUserId();
      if (actorId == null || actorId.isEmpty) {
        return const Left(TicketOperationFailure(
          type: TicketFailureType.authentication,
          message: 'Sesi telah berakhir. Silakan login kembali.',
          code: 401,
        ));
      }

      final ticketId = params.clientTicketId ?? uuid.v4();
      final attachments = params.attachments;

      for (var index = 0; index < attachments.length; index++) {
        final candidate = attachments[index];
        params.onProgress?.call(CreateTicketProgress(
          stage: CreateTicketProgressStage.uploading,
          currentFileName: candidate.fileName,
          uploadedCount: uploadedAttachments.length,
          totalCount: attachments.length,
        ));

        final attachment = await attachmentStorageDataSource.upload(
          ticketId: ticketId,
          userId: actorId,
          attachmentId: uuid.v4(),
          candidate: candidate,
        );
        uploadedAttachments.add(attachment);

        final activeActorId = remoteDataSource.getAuthenticatedUserId();
        if (activeActorId != actorId) {
          final failedCleanup = await _cleanupUploaded(uploadedAttachments);
          if (failedCleanup.isNotEmpty) {
            return Left(TicketOperationFailure(
              type: TicketFailureType.compensation,
              message: 'Sesi berubah dan cleanup lampiran gagal.',
              failedStoragePaths: failedCleanup,
            ));
          }
          return const Left(TicketOperationFailure(
            type: TicketFailureType.sessionChanged,
            message: 'Sesi berubah saat mengirim tiket. Silakan coba lagi.',
            code: 401,
          ));
        }
      }

      params.onProgress?.call(CreateTicketProgress(
        stage: CreateTicketProgressStage.creatingTicket,
        uploadedCount: uploadedAttachments.length,
        totalCount: attachments.length,
      ));

      final createdTicket = await remoteDataSource.createTicketWithAttachments(
        ticketId: ticketId,
        title: params.trimmedTitle,
        description: params.trimmedDescription,
        category: params.trimmedCategory,
        attachments: uploadedAttachments,
      );
      return Right(createdTicket.toEntity());
    } on sup.AuthException catch (e) {
      final failedCleanup = await _cleanupUploaded(uploadedAttachments);
      if (failedCleanup.isNotEmpty) {
        return Left(TicketOperationFailure(
          type: TicketFailureType.compensation,
          message: 'Autentikasi gagal dan cleanup lampiran gagal.',
          code: 401,
          failedStoragePaths: failedCleanup,
        ));
      }
      return Left(ServerFailure(message: e.message, code: 401));
    } on TicketCreateException catch (e) {
      if (uploadedAttachments.isNotEmpty &&
          e.type != TicketFailureType.compensation) {
        final failedCleanup = await _cleanupUploaded(uploadedAttachments);
        if (failedCleanup.isNotEmpty) {
          return Left(TicketOperationFailure(
            type: TicketFailureType.compensation,
            message: 'Cleanup lampiran gagal setelah pembuatan tiket gagal.',
            code: e.code,
            failedStoragePaths: failedCleanup,
          ));
        }
      }

      return Left(TicketOperationFailure(
        type: e.type,
        message: e.message,
        code: e.code,
        failedStoragePaths: e.failedStoragePaths,
      ));
    } catch (e) {
      final failedCleanup = await _cleanupUploaded(uploadedAttachments);
      if (failedCleanup.isNotEmpty) {
        return Left(TicketOperationFailure(
          type: TicketFailureType.compensation,
          message: 'Cleanup lampiran gagal setelah pembuatan tiket gagal.',
          failedStoragePaths: failedCleanup,
        ));
      }
      return const Left(TicketOperationFailure(
        type: TicketFailureType.unknown,
        message: 'Gagal membuat tiket.',
      ));
    }
  }

  Future<List<String>> _cleanupUploaded(
    List<UploadedTicketAttachment> uploadedAttachments,
  ) {
    return attachmentStorageDataSource.deleteObjects(
      uploadedAttachments
          .map((attachment) => attachment.storagePath)
          .toList(growable: false),
    );
  }

  @override
  Future<Either<Failure, TicketEntity>> getTicketDetail(String ticketId) async {
    try {
      final ticket = await remoteDataSource.getTicketDetail(ticketId);
      return Right(ticket.toEntity());
    } on sup.AuthException catch (e) {
      return Left(ServerFailure(message: e.message, code: 401));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CommentEntity>>> getTicketComments(
      String ticketId) async {
    try {
      final comments = await remoteDataSource.getTicketComments(ticketId);
      return Right(comments.map((c) => c.toEntity()).toList());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CommentEntity>> addComment({
    required String ticketId,
    required String message,
  }) async {
    try {
      final commentModel = CommentModel(
        id: 'placeholder',
        ticketId: ticketId,
        userId: 'placeholder', // Overwritten by remote data source
        userName: '',
        userRole: '',
        message: message,
        createdAt: DateTime.now(),
      );

      final createdComment = await remoteDataSource.addComment(commentModel);
      return Right(createdComment.toEntity());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TicketEntity>> updateTicketStatus({
    required String ticketId,
    required TicketStatus status,
  }) async {
    try {
      final ticket =
          await remoteDataSource.updateTicketStatus(ticketId, status);
      return Right(ticket.toEntity());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TicketHistoryEntity>>> getTicketHistory(
      String ticketId) async {
    try {
      final activities = await remoteDataSource.getTicketHistory(ticketId);
      return Right(activities.map((a) => a.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TicketHistoryEntity>>> getAllTicketHistory(
      {String? changedBy, DateTime? startDate, DateTime? endDate}) async {
    try {
      final activities = await remoteDataSource.getAllTicketHistory(
        changedBy: changedBy,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(activities.map((a) => a.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TicketEntity>> submitRating({
    required String ticketId,
    required int rating,
    required String feedback,
  }) async {
    try {
      final ticket =
          await remoteDataSource.submitRating(ticketId, rating, feedback);
      return Right(ticket.toEntity());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<TicketEntity>> watchTickets(
      {String? userId, String? assignedToId}) {
    return remoteDataSource
        .watchTickets(userId: userId, assignedToId: assignedToId)
        .map(
          (models) => models.map((m) => m.toEntity()).toList(),
        );
  }

  @override
  Stream<List<CommentEntity>> watchTicketComments(String ticketId) {
    return remoteDataSource.watchTicketComments(ticketId).map(
          (models) => models.map((c) => c.toEntity()).toList(),
        );
  }

  @override
  Future<Either<Failure, TicketEntity>> assignTicket({
    required String ticketId,
    required String technicianId,
  }) async {
    try {
      final ticket =
          await remoteDataSource.assignTicket(ticketId, technicianId);
      return Right(ticket.toEntity());
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, TicketStats>> getTicketStats({
    String? assignedToId,
    String? category,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final statsMap = await remoteDataSource.getTicketStats(
        assignedToId: assignedToId,
        category: category,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(TicketStats(
        total: statsMap['total'] ?? 0,
        open: statsMap['open'] ?? 0,
        pending: statsMap['pending'] ?? 0,
        inProgress: statsMap['in_progress'] ?? 0,
        resolved: statsMap['resolved'] ?? 0,
        closed: statsMap['closed'] ?? 0,
        reopened: statsMap['reopened'] ?? 0,
      ));
    } catch (e) {
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
