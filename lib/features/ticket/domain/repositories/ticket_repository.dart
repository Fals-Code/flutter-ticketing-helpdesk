import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ticket_entity.dart';
import '../entities/comment_entity.dart';
import '../entities/ticket_activity_entity.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../../core/constants/enums.dart';

abstract class TicketRepository {
  /// Mengambil daftar tiket milik user saat ini (Paginated).
  Future<Either<Failure, List<TicketEntity>>> getTickets({
    required int page,
    required int limit,
  });

  /// Mengambil SEMUA daftar tiket di sistem (Paginated - untuk Admin/Staff).
  Future<Either<Failure, List<TicketEntity>>> getAllTickets({
    required int page,
    required int limit,
    String? status,
  });

  /// Mengambil daftar staff (Technician/Admin) untuk penugasan.
  Future<Either<Failure, List<AuthUser>>> getStaffUsers();

  /// Membuat tiket baru.
  Future<Either<Failure, TicketEntity>> createTicket({
    required String title,
    required String description,
    required String category,
    required String priority,
    required List<String> imagePaths,
  });

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

  /// Mengambil daftar komentar/reply untuk tiket tertentu.
  Future<Either<Failure, List<CommentEntity>>> getTicketComments(String ticketId);

  /// Menambahkan komentar/reply ke tiket.
  Future<Either<Failure, CommentEntity>> addComment({
    required String ticketId,
    required String message,
  });

  /// Mengambil riwayat aktivitas untuk tiket tertentu.
  Future<Either<Failure, List<TicketActivityEntity>>> getTicketActivities(String ticketId);

  /// Mengambil semua riwayat aktivitas (Admin/Staff only).
  Future<Either<Failure, List<TicketActivityEntity>>> getAllActivities();
}
