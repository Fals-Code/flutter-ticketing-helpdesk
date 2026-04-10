import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/ticket_entity.dart';
import 'ticket_usecases.dart';
import 'package:uts/core/constants/enums.dart';
import '../repositories/ticket_repository.dart';

/// UseCase untuk mengambil semua tiket di sistem (untuk Admin/Staff).
class GetAllTicketsUseCase implements UseCase<Either<Failure, List<TicketEntity>>, GetTicketsParams> {
  final TicketRepository repository;

  GetAllTicketsUseCase(this.repository);

  @override
  Future<Either<Failure, List<TicketEntity>>> call(GetTicketsParams params) async {
    return await repository.getAllTickets(
      page: params.page,
      limit: params.limit,
      status: params.status,
    );
  }
}



/// UseCase untuk mengambil daftar staff.
class GetStaffUsersUseCase implements UseCase<Either<Failure, List<AuthUser>>, NoParams> {
  final TicketRepository repository;

  GetStaffUsersUseCase(this.repository);

  @override
  Future<Either<Failure, List<AuthUser>>> call(NoParams params) async {
    return await repository.getStaffUsers();
  }
}

/// UseCase untuk update status tiket.
class UpdateTicketStatusUseCase implements UseCase<Either<Failure, TicketEntity>, UpdateStatusParams> {
  final TicketRepository repository;

  UpdateTicketStatusUseCase(this.repository);

  @override
  Future<Either<Failure, TicketEntity>> call(UpdateStatusParams params) async {
    return await repository.updateTicketStatus(
      ticketId: params.ticketId,
      status: params.status,
    );
  }
}

class UpdateStatusParams {
  final String ticketId;
  final TicketStatus status;

  UpdateStatusParams({required this.ticketId, required this.status});
}

/// UseCase untuk menugaskan tiket ke petugas.
class AssignTicketUseCase implements UseCase<Either<Failure, TicketEntity>, AssignTicketParams> {
  final TicketRepository repository;

  AssignTicketUseCase(this.repository);

  @override
  Future<Either<Failure, TicketEntity>> call(AssignTicketParams params) async {
    return await repository.assignTicket(
      ticketId: params.ticketId,
      technicianId: params.technicianId,
    );
  }
}

class AssignTicketParams {
  final String ticketId;
  final String technicianId;

  AssignTicketParams({required this.ticketId, required this.technicianId});
}
