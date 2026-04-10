import '../../domain/entities/ticket_activity_entity.dart';

class TicketActivityModel extends TicketActivityEntity {
  const TicketActivityModel({
    required super.id,
    required super.ticketId,
    required super.userId,
    required super.userName,
    required super.activityType,
    required super.description,
    required super.createdAt,
  });

  factory TicketActivityModel.fromJson(Map<String, dynamic> json) {
    return TicketActivityModel(
      id: json['id'] as String,
      ticketId: json['ticket_id'] as String,
      userId: json['user_id'] as String,
      userName: json['profiles'] != null ? json['profiles']['full_name'] as String : 'System',
      activityType: json['activity_type'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'user_id': userId,
      'activity_type': activityType,
      'description': description,
    };
  }

  TicketActivityEntity toEntity() {
    return TicketActivityEntity(
      id: id,
      ticketId: ticketId,
      userId: userId,
      userName: userName,
      activityType: activityType,
      description: description,
      createdAt: createdAt,
    );
  }
}
