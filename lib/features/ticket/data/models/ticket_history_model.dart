import '../../domain/entities/ticket_history_entity.dart';

class TicketHistoryModel extends TicketHistoryEntity {
  const TicketHistoryModel({
    required super.id,
    required super.ticketId,
    super.eventType,
    super.oldStatus,
    required super.newStatus,
    required super.changedBy,
    super.changedByName,
    required super.createdAt,
  });

  factory TicketHistoryModel.fromJson(Map<String, dynamic> json) {
    final dynamic profile = json['profiles'];
    final String? changedByName = profile is Map<String, dynamic>
        ? profile['full_name'] as String?
        : json['changed_by_name'] as String?;

    return TicketHistoryModel(
      id: json['id'] as String? ?? '',
      ticketId: json['ticket_id'] as String? ?? '',
      eventType: json['event_type'] as String? ?? 'status_changed',
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String? ?? '',
      changedBy: json['changed_by'] as String? ?? '',
      changedByName: changedByName,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'ticket_id': ticketId,
      'event_type': eventType,
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
      eventType: eventType,
      oldStatus: oldStatus,
      newStatus: newStatus,
      changedBy: changedBy,
      changedByName: changedByName,
      createdAt: createdAt,
    );
  }
}
