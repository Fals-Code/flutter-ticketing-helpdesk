import 'package:equatable/equatable.dart';

class TicketHistoryEntity extends Equatable {
  final String id;
  final String ticketId;
  final String? oldStatus;
  final String newStatus;
  final String changedBy;
  final String? changedByName;
  final DateTime createdAt;

  const TicketHistoryEntity({
    required this.id,
    required this.ticketId,
    this.oldStatus,
    required this.newStatus,
    required this.changedBy,
    this.changedByName,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, ticketId, oldStatus, newStatus, changedBy, changedByName, createdAt];
}
