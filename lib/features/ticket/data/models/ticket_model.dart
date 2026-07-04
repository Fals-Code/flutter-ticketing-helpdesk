import '../../domain/entities/ticket_entity.dart';
import '../../domain/entities/ticket_attachment_entity.dart';
import 'package:uts/core/constants/enums.dart';

import 'ticket_attachment_model.dart';

class TicketModel extends TicketEntity {
  const TicketModel({
    required super.id,
    required super.title,
    required super.description,
    required super.status,
    required super.category,
    super.priority,
    required super.createdAt,
    super.updatedAt,
    required super.userId,
    super.userName,
    super.assignedTo,
    super.assignedToName,
    super.attachments,
    super.imageUrls,
    super.rating,
    super.ratingFeedback,
  });

  factory TicketModel.fromEntity(TicketEntity entity) {
    return TicketModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      status: entity.status,
      category: entity.category,
      priority: entity.priority,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      userId: entity.userId,
      userName: entity.userName,
      assignedTo: entity.assignedTo,
      assignedToName: entity.assignedToName,
      attachments: entity.attachments,
      imageUrls: entity.imageUrls,
      rating: entity.rating,
      ratingFeedback: entity.ratingFeedback,
    );
  }

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final profilesData = json['profiles'];
    Map<String, dynamic>? creatorProfile;
    if (profilesData is Map<String, dynamic>) {
      creatorProfile = profilesData;
    } else if (profilesData is List && profilesData.isNotEmpty) {
      creatorProfile = profilesData.first;
    }
    final userName = _readNullableString(
          creatorProfile?['full_name'] ?? json['user_name'],
        ) ??
        'Pengguna';

    final technicianData = json['technician'];
    Map<String, dynamic>? staffProfile;
    if (technicianData is Map<String, dynamic>) {
      staffProfile = technicianData;
    } else if (technicianData is List && technicianData.isNotEmpty) {
      staffProfile = technicianData.first;
    }
    final assignedToName = _readNullableString(
      staffProfile?['full_name'] ?? json['assigned_to_name'],
    );

    final ticketId = _readRequiredString(json, 'id');
    final createdAt = _readRequiredDateTime(
      json['created_at'] ?? json['createdAt'],
      'created_at',
    );
    final legacyImages = _readLegacyImageUrls(json['images']);
    final attachments = _readAttachments(
      json: json,
      ticketId: ticketId,
      uploadedBy: _readNullableString(json['user_id']) ?? '',
      legacyImages: legacyImages,
    );

    return TicketModel(
      id: ticketId,
      title: _readRequiredString(json, 'title'),
      description: _readRequiredString(json, 'description'),
      status: TicketStatus.fromString(
        _readNullableString(json['status']) ?? 'open',
      ),
      category: _readNullableString(json['category']) ?? 'General',
      priority: _readNullableString(json['priority']) != null
          ? TicketPriority.fromString(_readNullableString(json['priority']))
          : null,
      createdAt: createdAt,
      updatedAt: json['updated_at'] != null
          ? _readRequiredDateTime(json['updated_at'], 'updated_at')
          : null,
      userId: _readRequiredString(json, 'user_id'),
      userName: userName,
      assignedTo: json['assigned_to'],
      assignedToName: assignedToName,
      attachments: attachments,
      imageUrls: legacyImages,
      rating: json['rating'],
      ratingFeedback: json['rating_feedback'],
    );
  }

  Map<String, dynamic> toJson({bool includeAttachmentAccessUrls = true}) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.dbValue,
      'category': category,
      if (priority != null) 'priority': priority!.dbValue,
      'user_id': userId,
      'assigned_to':
          (assignedTo == null || assignedTo!.isEmpty) ? null : assignedTo,
      'images': super.imageUrls,
      'created_at': createdAt.toIso8601String(),
      if (attachments.isNotEmpty)
        'ticket_attachments': attachments
            .map(
              (attachment) => TicketAttachmentModel.fromEntity(attachment)
                  .toJson(includeAccessUrl: includeAttachmentAccessUrls),
            )
            .toList(growable: false),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      if (rating != null) 'rating': rating,
      if (ratingFeedback != null) 'rating_feedback': ratingFeedback,
    };
  }

  TicketEntity toEntity() {
    return TicketEntity(
      id: id,
      title: title,
      description: description,
      status: status,
      category: category,
      priority: priority,
      createdAt: createdAt,
      updatedAt: updatedAt,
      userId: userId,
      userName: userName,
      assignedTo: assignedTo,
      assignedToName: assignedToName,
      attachments: attachments,
      imageUrls: imageUrls,
      rating: rating,
      ratingFeedback: ratingFeedback,
    );
  }

  static List<TicketAttachmentEntity> _readAttachments({
    required Map<String, dynamic> json,
    required String ticketId,
    required String uploadedBy,
    required List<String> legacyImages,
  }) {
    final rawAttachments = json['ticket_attachments'];
    final parsedAttachments = <TicketAttachmentEntity>[];

    if (rawAttachments is List) {
      for (final item in rawAttachments) {
        if (item is! Map) {
          throw const FormatException('Invalid ticket_attachments payload');
        }
        parsedAttachments.add(
          TicketAttachmentModel.fromJson(
            Map<String, dynamic>.from(item),
          ).toEntity(),
        );
      }
    }

    if (legacyImages.isEmpty) {
      return parsedAttachments;
    }

    final seenAccessUrls = parsedAttachments
        .map((attachment) => attachment.accessUrl)
        .whereType<String>()
        .toSet();

    final legacyAttachments = legacyImages
        .where((url) => !seenAccessUrls.contains(url))
        .map(
          (url) => TicketAttachmentModel.fromLegacyImageUrl(
            ticketId: ticketId,
            imageUrl: url,
            uploadedBy: uploadedBy,
          ).toEntity(),
        )
        .toList(growable: false);

    return [
      ...parsedAttachments,
      ...legacyAttachments,
    ];
  }

  static List<String> _readLegacyImageUrls(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) => item?.toString().trim())
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static String _readRequiredString(Map<String, dynamic> json, String key) {
    final value = _readNullableString(json[key]);
    if (value == null || value.isEmpty) {
      throw FormatException('Missing required ticket field: $key');
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
    throw FormatException('Invalid required ticket field: $key');
  }
}
