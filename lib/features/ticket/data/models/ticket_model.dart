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
    super.assignedTo,
    super.assignedToName,
    super.imageUrls,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    // Handle join results for assigned_to_name if available (from profiles table)
    final assignedProfile = json['profiles']; 
    final assignedToName = assignedProfile != null ? assignedProfile['full_name'] : json['assigned_to_name'];

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
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      imageUrls: imageUrls,
    );
  }
}
