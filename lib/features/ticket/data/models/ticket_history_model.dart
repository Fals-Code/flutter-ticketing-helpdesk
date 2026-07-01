import '../../domain/entities/ticket_history_entity.dart';

class TicketHistoryModel extends TicketHistoryEntity {
  const TicketHistoryModel({
    required super.id,
    required super.ticketId,
    super.activityType,
    super.oldStatus,
    super.newStatus,
    required super.changedBy,
    super.changedByName,
    super.description,
    super.metadata,
    required super.createdAt,
  });

  factory TicketHistoryModel.fromJson(Map<String, dynamic> json) {
    // Handle join with profiles if available
    final profile = json['profiles'];
    final changedByName = profile is Map
        ? Map<String, dynamic>.from(profile)['full_name']
        : json['changed_by_name'];

    return TicketHistoryModel(
      id: _requireString(json, 'id'),
      ticketId: _requireString(json, 'ticket_id'),
      activityType: _readNullableString(json['event_type']),
      oldStatus: _readNullableString(json['old_status']),
      newStatus: _readNullableString(json['new_status']),
      changedBy: _requireString(json, 'changed_by'),
      changedByName: changedByName,
      description: _readNullableString(json['reason']) ??
          _readNullableString(json['description']),
      metadata: json['metadata'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
      createdAt: _readRequiredDateTime(json['created_at'], 'created_at'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticket_id': ticketId,
      if (activityType != null) 'event_type': activityType,
      'old_status': oldStatus,
      'new_status': newStatus,
      'changed_by': changedBy,
      if (description != null) 'reason': description,
      if (metadata != null) 'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TicketHistoryEntity toEntity() {
    return TicketHistoryEntity(
      id: id,
      ticketId: ticketId,
      activityType: activityType,
      oldStatus: oldStatus,
      newStatus: newStatus,
      changedBy: changedBy,
      changedByName: changedByName,
      description: description,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = _readNullableString(json[key]);
    if (value == null || value.isEmpty) {
      throw FormatException('Missing required ticket history field: $key');
    }
    return value;
  }

  static String? _readNullableString(dynamic value) {
    if (value == null) {
      return null;
    }
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static DateTime _readRequiredDateTime(dynamic value, String key) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException('Invalid required ticket history field: $key');
  }
}
