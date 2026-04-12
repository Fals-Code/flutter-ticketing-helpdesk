import '../entities/comment_entity.dart';
import '../repositories/ticket_repository.dart';

class WatchTicketCommentsUseCase {
  final TicketRepository repository;
  WatchTicketCommentsUseCase(this.repository);

  Stream<List<CommentEntity>> call(String ticketId) {
    return repository.watchTicketComments(ticketId);
  }
}
