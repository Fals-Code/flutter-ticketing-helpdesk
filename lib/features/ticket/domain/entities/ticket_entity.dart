import 'package:equatable/equatable.dart';

import 'package:uts/core/constants/enums.dart';

class TicketEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final TicketStatus status;

  final String category;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;
  final String? userName;
  final String? assignedTo;
  final String? assignedToName;
  final List<String> imageUrls;
  final int? rating;
  final String? ratingFeedback;

  const TicketEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.status,

    required this.category,
    required this.createdAt,
    this.updatedAt,
    required this.userId,
    this.userName,
    this.assignedTo,
    this.assignedToName,
    this.imageUrls = const [],
    this.rating,
    this.ratingFeedback,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        status,

        category,
        createdAt,
        updatedAt,
        userId,
        userName,
        assignedTo,
        assignedToName,
        imageUrls,
        rating,
        ratingFeedback,
      ];
}
