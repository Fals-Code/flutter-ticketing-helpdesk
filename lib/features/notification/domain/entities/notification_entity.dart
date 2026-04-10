import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String? ticketId;
  final bool isRead;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.ticketId,
    required this.isRead,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, title, message, ticketId, isRead, createdAt];
}
