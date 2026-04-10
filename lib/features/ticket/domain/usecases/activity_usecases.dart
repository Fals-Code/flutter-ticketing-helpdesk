import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/ticket_activity_entity.dart';
import '../repositories/ticket_repository.dart';

class GetTicketActivitiesUseCase {
  final TicketRepository repository;

  GetTicketActivitiesUseCase(this.repository);

  Future<Either<Failure, List<TicketActivityEntity>>> call(String ticketId) {
    return repository.getTicketActivities(ticketId);
  }
}

class GetAllActivitiesUseCase {
  final TicketRepository repository;

  GetAllActivitiesUseCase(this.repository);

  Future<Either<Failure, List<TicketActivityEntity>>> call() {
    return repository.getAllActivities();
  }
}
