import '../../domain/entities/ticket_attachment_entity.dart';

class TicketAttachmentModel extends TicketAttachmentEntity {
  const TicketAttachmentModel({
    required super.id,
    required super.ticketId,
    required super.storagePath,
    required super.fileName,
    required super.mimeType,
    required super.extension,
    required super.sizeBytes,
    required super.uploadedBy,
    required super.createdAt,
    super.kind = TicketAttachmentKind.unknown,
    super.accessUrl,
    super.isLegacyImage = false,
  });

  factory TicketAttachmentModel.fromJson(Map<String, dynamic> json) {
    final id = _requireString(json, 'id');
    final ticketId = _requireString(json, 'ticket_id');
    final fileName = _requireString(json, 'file_name');
    final mimeType = _requireString(json, 'mime_type');
    final uploadedBy = _requireString(json, 'uploaded_by');
    final storagePath = _readNullableString(json['storage_path']);
    final accessUrl = _readNullableString(
      json['access_url'] ??
          json['signed_url'] ??
          json['public_url'] ??
          json['url'],
    );
    final extension = _resolveExtension(
      _readNullableString(json['extension']) ?? fileName,
    );
    final sizeBytes = _readRequiredInt(json['size_bytes'], 'size_bytes');
    final createdAt = _readRequiredDateTime(json['created_at'], 'created_at');

    return TicketAttachmentModel(
      id: id,
      ticketId: ticketId,
      storagePath: storagePath,
      fileName: fileName,
      mimeType: mimeType,
      extension: extension,
      sizeBytes: sizeBytes,
      uploadedBy: uploadedBy,
      createdAt: createdAt,
      kind: TicketAttachmentKind.fromMimeType(mimeType),
      accessUrl: accessUrl,
      isLegacyImage: false,
    );
  }

  factory TicketAttachmentModel.fromEntity(TicketAttachmentEntity entity) {
    return TicketAttachmentModel(
      id: entity.id,
      ticketId: entity.ticketId,
      storagePath: entity.storagePath,
      fileName: entity.fileName,
      mimeType: entity.mimeType,
      extension: entity.extension,
      sizeBytes: entity.sizeBytes,
      uploadedBy: entity.uploadedBy,
      createdAt: entity.createdAt,
      kind: entity.kind,
      accessUrl: entity.accessUrl,
      isLegacyImage: entity.isLegacyImage,
    );
  }

  factory TicketAttachmentModel.fromLegacyImageUrl({
    required String ticketId,
    required String imageUrl,
    required String uploadedBy,
  }) {
    final fileName = _fileNameFromReference(imageUrl);
    final extension = _resolveExtension(fileName);
    final mimeType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      _ => 'application/octet-stream',
    };

    return TicketAttachmentModel(
      id: 'legacy:$ticketId:$imageUrl',
      ticketId: ticketId,
      storagePath: null,
      fileName: fileName,
      mimeType: mimeType,
      extension: extension,
      sizeBytes: 0,
      uploadedBy: uploadedBy,
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      kind: TicketAttachmentKind.fromMimeType(mimeType),
      accessUrl: imageUrl,
      isLegacyImage: true,
    );
  }

  Map<String, dynamic> toJson({bool includeAccessUrl = true}) {
    return {
      'id': id,
      'ticket_id': ticketId,
      'storage_path': storagePath,
      'file_name': fileName,
      'mime_type': mimeType,
      'size_bytes': sizeBytes,
      'uploaded_by': uploadedBy,
      'created_at': createdAt.toIso8601String(),
      if (extension.isNotEmpty) 'extension': extension,
      if (includeAccessUrl && accessUrl != null) 'access_url': accessUrl,
    };
  }

  TicketAttachmentEntity toEntity() => TicketAttachmentEntity(
        id: id,
        ticketId: ticketId,
        storagePath: storagePath,
        fileName: fileName,
        mimeType: mimeType,
        extension: extension,
        sizeBytes: sizeBytes,
        uploadedBy: uploadedBy,
        createdAt: createdAt,
        kind: kind,
        accessUrl: accessUrl,
        isLegacyImage: isLegacyImage,
      );

  static String _requireString(Map<String, dynamic> json, String key) {
    final value = _readNullableString(json[key]);
    if (value == null || value.isEmpty) {
      throw FormatException('Missing required attachment field: $key');
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

  static int _readRequiredInt(dynamic value, String key) {
    final parsed = switch (value) {
      int intValue => intValue,
      num numValue => numValue.toInt(),
      String stringValue => int.tryParse(stringValue),
      _ => null,
    };

    if (parsed == null) {
      throw FormatException('Invalid required attachment field: $key');
    }
    return parsed;
  }

  static DateTime _readRequiredDateTime(dynamic value, String key) {
    if (value is DateTime) {
      return value.toUtc();
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException('Invalid required attachment field: $key');
  }

  static String _resolveExtension(String value) {
    final dotIndex = value.lastIndexOf('.');
    if (dotIndex <= 0 || dotIndex == value.length - 1) {
      return '';
    }
    return value.substring(dotIndex + 1).trim().toLowerCase();
  }

  static String _fileNameFromReference(String reference) {
    final normalized = reference.split('?').first.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isNotEmpty ? segments.last : reference;
  }
}
