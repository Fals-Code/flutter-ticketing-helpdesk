import 'package:equatable/equatable.dart';

import 'package:uts/core/constants/enums.dart';

class TicketEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final TicketPriority priority;
  final String category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;
  final String? userName;
  final String? assignedTo;
  final String? assignedToName;
  final List<String> imageUrls;

  const TicketEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.category,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
    this.userName,
    this.assignedTo,
    this.assignedToName,
    this.imageUrls = const [],
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        priority,
        category,
        createdAt,
        updatedAt,
        userId,
        userName,
        assignedTo,
        assignedToName,
        imageUrls,
      ];
}
