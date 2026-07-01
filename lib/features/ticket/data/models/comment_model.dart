import '../../domain/entities/comment_entity.dart';
import 'package:uts/core/constants/enums.dart';

class CommentModel extends CommentEntity {
  const CommentModel({
    required super.id,
    required super.ticketId,
    required super.userId,
    required super.userName,
    required super.userRole,
    required super.message,
    required super.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final profile = switch (json['profiles']) {
      Map mapValue => Map<String, dynamic>.from(mapValue),
      List<dynamic> listValue
          when listValue.isNotEmpty && listValue.first is Map =>
        Map<String, dynamic>.from(listValue.first as Map),
      _ => null,
    };

    return CommentModel(
      id: _requireString(json, 'id'),
      ticketId: _requireString(json, 'ticket_id'),
      userId: _requireString(json, 'user_id'),
      userName: _readNullableString(profile?['full_name']) ?? 'Unknown',
      userRole: (profile?['role'] is int)
          ? UserRole.fromInt(profile!['role']).name
          : _readNullableString(profile?['role']) ?? 'user',
      message: _requireString(json, 'message'),
      createdAt: _readRequiredDateTime(json['created_at'], 'created_at'),
    );
  }

  CommentModel copyWith({
    String? userName,
    String? userRole,
    String? message,
  }) {
    return CommentModel(
      id: id,
      ticketId: ticketId,
      userId: userId,
      userName: userName ?? this.userName,
      userRole: userRole ?? this.userRole,
      message: message ?? this.message,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticket_id': ticketId,
      'user_id': userId,
      'message': message,
    };
  }

  CommentEntity toEntity() {
    return CommentEntity(
      id: id,
      ticketId: ticketId,
      userId: userId,
      userName: userName,
      userRole: userRole,
      message: message,
      createdAt: createdAt,
    );
  }

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = _readNullableString(json[key]);
    if (value == null || value.isEmpty) {
      throw FormatException('Missing required comment field: $key');
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
    throw FormatException('Invalid required comment field: $key');
  }
}
