import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/notification_repository.dart';

class DeleteNotification {
  final NotificationRepository repository;

  DeleteNotification(this.repository);

  Future<Either<Failure, void>> call(String id) {
    return repository.deleteNotification(id);
  }
}

class DeleteMultipleNotifications {
  final NotificationRepository repository;

  DeleteMultipleNotifications(this.repository);

  Future<Either<Failure, void>> call(List<String> ids) {
    return repository.deleteNotifications(ids);
  }
}

class DeleteAllNotifications {
  final NotificationRepository repository;

  DeleteAllNotifications(this.repository);

  Future<Either<Failure, void>> call() {
    return repository.deleteAllNotifications();
  }
}
