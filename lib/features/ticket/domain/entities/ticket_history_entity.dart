import 'package:equatable/equatable.dart';

class TicketHistoryEntity extends Equatable {
  final String id;
  final String ticketId;
  final String? activityType;
  final String? oldStatus;
  final String? newStatus;
  final String changedBy;
  final String? changedByName;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const TicketHistoryEntity({
    required this.id,
    required this.ticketId,
    this.activityType,
    this.oldStatus,
    this.newStatus,
    required this.changedBy,
    this.changedByName,
    this.description,
    this.metadata,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        ticketId,
        activityType,
        oldStatus,
        newStatus,
        changedBy,
        changedByName,
        description,
        metadata,
        createdAt,
      ];
}
