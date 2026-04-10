import 'package:equatable/equatable.dart';

class TicketActivityEntity extends Equatable {
  final String id;
  final String ticketId;
  final String userId;
  final String userName;
  final String activityType; // created, status_updated, assigned, comment_added
  final String description;
  final DateTime createdAt;

  const TicketActivityEntity({
    required this.id,
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.activityType,
    required this.description,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, ticketId, userId, userName, activityType, description, createdAt];
}
