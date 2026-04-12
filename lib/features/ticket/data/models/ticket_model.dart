import '../../domain/entities/ticket_entity.dart';
import 'package:uts/core/constants/enums.dart';

class TicketModel extends TicketEntity {
  const TicketModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.priority,
    required super.category,
    required super.createdAt,
    super.updatedAt,
    required super.userId,
    super.userName,
    super.assignedTo,
    super.assignedToName,
    super.imageUrls,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    // Handle join results for assigned_to_name
    final assignedProfile = json['assigned_profiles'] ?? json['profiles']; 
    final assignedToName = assignedProfile != null ? assignedProfile['full_name'] : json['assigned_to_name'];

    // Handle join results for creator name (userName)
    final creatorProfile = json['creator_profiles'];
    final userName = creatorProfile != null ? creatorProfile['full_name'] : json['user_name'];

    return TicketModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: TicketStatus.fromString(json['status'] ?? 'open'),
      priority: TicketPriority.fromString(json['priority'] ?? 'medium'),
      category: json['category'] ?? 'General',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      userId: json['user_id'] ?? '',
      userName: userName,
      assignedTo: json['assigned_to'],
      assignedToName: assignedToName,
      imageUrls: List<String>.from(json['images'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'category': category,
      'user_id': userId,
      'assigned_to': assignedTo,
      'images': super.imageUrls,
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  TicketEntity toEntity() {
    return TicketEntity(
      id: id,
      title: title,
      description: description,
      status: status,
      priority: priority,
      category: category,
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: userId,
      userName: userName,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      imageUrls: imageUrls,
    );
  }
}
