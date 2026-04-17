import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/notification_entity.dart';
import '../repositories/notification_repository.dart';

class GetNotifications {
  final NotificationRepository repository;

  GetNotifications(this.repository);

  Future<Either<Failure, List<NotificationEntity>>> call() {
    return repository.getNotifications();
  }
}

class MarkNotificationAsRead {
  final NotificationRepository repository;

  MarkNotificationAsRead(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.markAsRead(id);
  }
}

class DeleteNotifications {
  final NotificationRepository repository;

  DeleteNotifications(this.repository);

  Future<Either<Failure, void>> call(List<String> ids) {
    return repository.deleteNotifications(ids);
  }
}

class WatchNotifications {
  final NotificationRepository repository;

  WatchNotifications(this.repository);

  Stream<List<NotificationEntity>> call() {
    return repository.watchNotifications();
  }
}
