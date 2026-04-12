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
    // 1. Parse Creator/Reporter Profile (join via profiles:user_id)
    final profilesData = json['profiles'];
    Map<String, dynamic>? creatorProfile;
    if (profilesData is Map<String, dynamic>) {
      creatorProfile = profilesData;
    } else if (profilesData is List && profilesData.isNotEmpty) {
      creatorProfile = profilesData.first;
    }
    final userName = creatorProfile != null ? creatorProfile['full_name'] : 'Pengguna';

    // 2. Parse Technician Profile (join via technician:assigned_to)
    final technicianData = json['technician'];
    Map<String, dynamic>? staffProfile;
    if (technicianData is Map<String, dynamic>) {
      staffProfile = technicianData;
    } else if (technicianData is List && technicianData.isNotEmpty) {
      staffProfile = technicianData.first;
    }
    final assignedToName = staffProfile != null ? staffProfile['full_name'] : 'Belum ditugaskan';

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

  factory TicketModel.fromEntity(TicketEntity entity) {
    return TicketModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      priority: entity.priority,
      category: entity.category,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      userId: entity.userId,
      userName: entity.userName,
      assignedTo: entity.assignedTo,
      assignedToName: entity.assignedToName,
      imageUrls: entity.imageUrls,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'status': status.name == 'inProgress' ? 'in_progress' : status.name,
      'priority': priority.name,
      'category': category,
      'user_id': userId,
      'assigned_to': (assignedTo == null || assignedTo!.isEmpty) ? null : assignedTo,
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
