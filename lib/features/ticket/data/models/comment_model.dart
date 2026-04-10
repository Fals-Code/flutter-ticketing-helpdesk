import '../../domain/entities/comment_entity.dart';

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
    return CommentModel(
      id: json['id'] ?? '',
      ticketId: json['ticket_id'] ?? '',
      userId: json['user_id'] ?? '',
      userName: json['profiles']?['full_name'] ?? 'Unknown',
      userRole: json['profiles']?['role'] ?? 'user',
      message: json['message'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
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
}
