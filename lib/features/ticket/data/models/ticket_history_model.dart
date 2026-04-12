import '../../domain/entities/ticket_history_entity.dart';

class TicketHistoryModel extends TicketHistoryEntity {
  const TicketHistoryModel({
    required super.id,
    required super.ticketId,
    super.oldStatus,
    required super.newStatus,
    required super.changedBy,
    super.changedByName,
    required super.createdAt,
  });

  factory TicketHistoryModel.fromJson(Map<String, dynamic> json) {
    // Handle join with profiles if available
    final profile = json['profiles'];
    final changedByName = profile != null ? profile['full_name'] : json['changed_by_name'];

    return TicketHistoryModel(
      id: json['id'] ?? '',
      ticketId: json['ticket_id'] ?? '',
      oldStatus: json['old_status'],
      newStatus: json['new_status'] ?? '',
      changedBy: json['changed_by'] ?? '',
      changedByName: changedByName,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'old_status': oldStatus,
      'new_status': newStatus,
      'changed_by': changedBy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TicketHistoryEntity toEntity() {
    return TicketHistoryEntity(
      id: id,
      ticketId: ticketId,
      oldStatus: oldStatus,
      newStatus: newStatus,
      changedBy: changedBy,
      changedByName: changedByName,
      createdAt: createdAt,
    );
  }
}
