import 'package:equatable/equatable.dart';

import 'package:uts/core/constants/enums.dart';

import 'ticket_attachment_entity.dart';

class TicketEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;
  final String category;
  final TicketPriority? priority;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;
  final String? userName;
  final String? assignedTo;
  final String? assignedToName;
  final List<TicketAttachmentEntity> attachments;
  final List<String> imageUrls;
  final int? rating;
  final String? ratingFeedback;

  const TicketEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.category,
    this.priority,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
    this.userName,
    this.assignedTo,
    this.assignedToName,
    this.attachments = const [],
    this.imageUrls = const [],
    this.rating,
    this.ratingFeedback,
  });

  List<String> get legacyCompatibleImageUrls {
    if (imageUrls.isNotEmpty) {
      return imageUrls;
    }

    return attachments
        .where((attachment) => attachment.kind == TicketAttachmentKind.image)
        .map((attachment) => attachment.accessUrl)
        .whereType<String>()
        .toList(growable: false);
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,
        category,
        priority,
        createdAt,
        updatedAt,
        userId,
        userName,
        assignedTo,
        assignedToName,
        attachments,
        imageUrls,
        rating,
        ratingFeedback,
      ];
}
