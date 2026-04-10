import 'package:equatable/equatable.dart';

class CommentEntity extends Equatable {
  final String id;
  final String ticketId;
  final String userId;
  final String userName;
  final String userRole;
  final String message;
  final DateTime createdAt;

  const CommentEntity({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.userRole,
    required this.message,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, ticketId, userId, userName, userRole, message, createdAt];
}
