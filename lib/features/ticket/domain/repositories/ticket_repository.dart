import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/constants/enums.dart';
import '../../../auth/domain/entities/user_entity.dart';
import 'package:uts/features/ticket/domain/entities/ticket_entity.dart';
import 'package:uts/features/ticket/domain/entities/comment_entity.dart';
import 'package:uts/features/ticket/domain/entities/delete_ticket_result.dart';
import 'package:uts/features/ticket/domain/entities/ticket_history_entity.dart';
import 'package:uts/features/ticket/domain/entities/create_ticket_params.dart';
import '../value_objects/paginated_result.dart';
import '../value_objects/ticket_query.dart';

class TicketStats extends Equatable {
  final int total;
  final int open;
  final int pending;
  final int inProgress;
  final int resolved;
  final int closed;
  final int reopened;

  const TicketStats({
    this.total = 0,
    this.open = 0,
    this.pending = 0,
    this.inProgress = 0,
    this.resolved = 0,
    this.closed = 0,
    this.reopened = 0,
  });

  @override
  List<Object?> get props =>
      [total, open, pending, inProgress, resolved, closed, reopened];
}

abstract class TicketRepository {
  /// Mengambil daftar tiket milik user saat ini (Paginated).
  Future<Either<Failure, PaginatedResult<TicketEntity>>> getTickets({
    required TicketQuery query,
  });

  /// Mengambil semua tiket (untuk Admin/Staff).
  Future<Either<Failure, PaginatedResult<TicketEntity>>> getAllTickets({
    required TicketQuery query,
    String? assignedToId,
  });

  /// Mengambil daftar staff (Technician/Admin) untuk penugasan.
  Future<Either<Failure, List<AuthUser>>> getStaffUsers();

  /// Membuat tiket baru.
  Future<Either<Failure, TicketEntity>> createTicket(
    CreateTicketParams params,
  );

  /// Mengambil detail tiket berdasarkan ID.
  Future<Either<Failure, TicketEntity>> getTicketDetail(String ticketId);

  /// Update status tiket (Admin/Staff only).
  Future<Either<Failure, TicketEntity>> updateTicketStatus({
    required String ticketId,
    required TicketStatus status,
  });

  /// Menugaskan tiket ke staff tertentu (Admin/Staff only).
  Future<Either<Failure, TicketEntity>> assignTicket({
    required String ticketId,
    required String technicianId,
  });

  /// Memberikan rating dan feedback untuk tiket yang sudah resolved (User only).
  Future<Either<Failure, TicketEntity>> submitRating({
    required String ticketId,
    required int rating,
    required String feedback,
  });

  /// Mengambil daftar komentar/reply untuk tiket tertentu.
  Future<Either<Failure, List<CommentEntity>>> getTicketComments(
      String ticketId);

  /// Menambahkan komentar/reply ke tiket.
  Future<Either<Failure, CommentEntity>> addComment({
    required String ticketId,
    required String message,
  });

  /// Menghapus tiket secara policy-safe lewat backend.
  Future<Either<Failure, DeleteTicketResult>> deleteTicket({
    required String ticketId,
    required String reason,
  });

  /// Mengambil riwayat status perjalanan tiket (FR-011).
  Future<Either<Failure, List<TicketHistoryEntity>>> getTicketHistory(
      String ticketId);

  /// Mengambil SEMUA riwayat perjalanan tiket di sistem (Admin/Staff only).
  Future<Either<Failure, List<TicketHistoryEntity>>> getAllTicketHistory({
    String? changedBy,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Mengambil statistik tiket (Total, Open, In Progress, Resolved).
  Future<Either<Failure, TicketStats>> getTicketStats({
    String? assignedToId,
    String? category,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Aliran data tiket secara realtime.
  Stream<List<TicketEntity>> watchTickets(
      {String? userId, String? assignedToId});

  /// Aliran detail tiket secara realtime untuk satu ticket ID.
  Stream<TicketEntity?> watchTicketDetail(String ticketId);

  /// Aliran data komentar secara realtime.
  Stream<List<CommentEntity>> watchTicketComments(String ticketId);
}
