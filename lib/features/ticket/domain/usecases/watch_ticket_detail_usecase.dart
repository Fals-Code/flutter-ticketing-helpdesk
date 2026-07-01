import '../entities/ticket_entity.dart';
import '../repositories/ticket_repository.dart';

class WatchTicketDetailUseCase {
  final TicketRepository repository;

  WatchTicketDetailUseCase(this.repository);

  Stream<TicketEntity?> call(String ticketId) {
    return repository.watchTicketDetail(ticketId);
  }
}
