import '../entities/notification_entity.dart';
import '../../../../core/error/failures.dart';
import 'package:dartz/dartz.dart';

abstract class NotificationRepository {
  Future<Either<Failure, List<NotificationEntity>>> getNotifications();
  Future<Either<Failure, void>> markAsRead(String notificationId);
  Stream<List<NotificationEntity>> watchNotifications();
  Future<Either<Failure, void>> deleteNotification(String notificationId);
  Future<Either<Failure, void>> deleteNotifications(List<String> notificationIds);
  Future<Either<Failure, void>> deleteAllNotifications();
}
